import json
import psycopg2
import pandas as pd
import numpy as np
import datetime
import concurrent.futures
from concurrent.futures import ThreadPoolExecutor
import threading
from database_connection.db_connect import connect_to_db
from src import logger

pd.set_option('display.max_columns', None)


def fetch_datim_ids(conn, ip_name):
    """
    Fetches datim IDs for a given IP name.
    Accepts an active connection passed by the caller.
    """
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT datim_id FROM central_partner_mapping WHERE ip_name = %s",
                (ip_name,)
            )
            datims = cur.fetchall()
            datim_ids = [record[0] for record in datims]
            logger.info(f"Found {len(datim_ids)} datim_ids for IP: {ip_name}")
            return datim_ids
    except Exception as e:
        logger.error(f"Error fetching DATIM IDs for {ip_name}: {e}")
        return []


def update_prep_period_table(conn, periodcode):
    """
    Updates the PrEP period table.
    Accepts an active connection passed by the caller.
    """
    try:
        with conn.cursor() as cur:
            cur.execute("CALL prep.proc_update_prep_period_table(%s)", (periodcode,))
            conn.commit()
            logger.info(f"Period {periodcode} updated successfully.")
    except Exception as e:
        logger.error(f"Operational error occurred while updating period {periodcode}: {e}")


def truncate_table(conn, table_name, periodcode):
    """
    Truncates a single table by full qualified name.
    Accepts an active connection passed by the caller.
    """
    try:
        with conn.cursor() as cur:
            cur.execute(f"TRUNCATE {table_name}")
            conn.commit()
            logger.info(f"Table {table_name} truncated successfully for {periodcode}.")
    except Exception as e:
        logger.error(f"Operational error occurred while truncating {table_name} for {periodcode}: {e}")


def run_truncate_for_ctes(table_names, periodcode):
    def _run(table_name):
        with connect_to_db.connect('lamisplus_ods_dwh')[0] as conn:
            truncate_table(conn, table_name, periodcode)
    
    with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
        executor.map(_run, table_names)
    logger.info(f"Batch of {len(table_names)} TRUNCATE executed for {periodcode}")


def run_single_procedure(datim):
    """
    Executes proc_preplongitudinal_joined for a given datim_id.
    Opens its own short-lived connection — safe for concurrent use
    since each thread gets an independent connection.
    """
    try:
        with connect_to_db.connect('lamisplus_ods_dwh')[0] as conn:
            conn.autocommit = True
            with conn.cursor() as cur:
                cur.execute("CALL preplongitudinal.proc_preplongitudinal_joined(%s)", (datim,))
        logger.info(f"Procedure proc_preplongitudinal_joined for {datim} executed successfully.")
    except Exception as e:
        logger.error(f"Operational error occurred while processing {datim} for procedure: {e}")


def generate_cte_concurrently(datim_ids, max_workers):
    """
    Runs proc_preplongitudinal_joined concurrently across facilities.
    Each worker opens its own connection internally.
    """
    logger.info(f"Starting final joined insert for {len(datim_ids)} facilities.")
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        executor.map(run_single_procedure, datim_ids)
    logger.info(f"All procedures for CTE generation and preplongitudinal_joined completed for {datim_ids}")


def run_final_preplongitudinal(conn, ip_name, periodcode):
    """
    Executes the final preplongitudinal procedure for an IP.
    Accepts an active connection passed by the caller.
    """
    try:
        with conn.cursor() as cur:
            cur.execute("CALL preplongitudinal.proc_final_preplongitudinal(%s)", (ip_name,))
            conn.commit()
            logger.info(f"Procedure proc_final_preplongitudinal for {periodcode} for {ip_name} executed successfully.")
    except Exception as e:
        logger.error(f"Operational error occurred while processing for {periodcode} for {ip_name} procedure: {e}")

def run_final_preplongitudinal_for_ips(ip_names, periodcode):
    def _run(ip_name):
        with connect_to_db.connect('lamisplus_ods_dwh')[0] as conn:
            run_final_preplongitudinal(conn, ip_name, periodcode)
    
    with concurrent.futures.ThreadPoolExecutor(max_workers=1) as executor:
        executor.map(_run, ip_names)
    logger.info(f"Batch of {len(ip_names)} final_preplongitudinal procedures executed for {periodcode}")
    
def generate_preplongitudinal_report(**kwargs):
    """
    Main orchestrator. Opens ONE connection for all sequential/administrative
    operations (truncates, final procedures).
    Concurrent per-facility procedures open their own short-lived connections internally.
    """
    periods = kwargs.get('periods', [])
    if not periods:
        raise ValueError("No periods provided for the report generation.")

    table_names = [
        "preplongitudinal.preplongitudinal_joined",
        "preplongitudinal.preplongitudinal_monitoring"
    ]

    ip_names = [
        'ACE-1', 'ACE-2', 'ACE-3', 'ACE-4', 'ACE-5', 'CARE 1',
        'CARE 2'
    ]

    # One connection for all orchestration-level operations
    for periodcode in periods:
        with connect_to_db.connect('lamisplus_ods_dwh')[0] as conn:
            # 1. Truncate all CTE tables
            run_truncate_for_ctes(table_names, periodcode)

            # 2. Per-IP: fetch facilities, generate CTEs concurrently
            #    (each worker opens its own connection internally)
            for ip in ip_names:
                datim_ids = fetch_datim_ids(conn, ip)
                if datim_ids:
                    logger.info(f"Processing IP: {ip} with {len(datim_ids)} facilities.")
                    generate_cte_concurrently(datim_ids, max_workers=20)

        # 4. Final rollup
        run_final_preplongitudinal_for_ips(ip_names, periodcode)


if __name__ == '__main__':
    generate_preplongitudinal_report()
