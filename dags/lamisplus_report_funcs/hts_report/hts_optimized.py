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


def run_hts_joined(datim):
    """
    Executes proc_hts_joined_v2 for a given datim_id.
    Opens its own short-lived connection — safe for concurrent use
    since each thread gets an independent connection.
    """
    try:
        with connect_to_db.connect('lamisplus_ods_dwh')[0] as conn:
            conn.autocommit = True
            with conn.cursor() as cur:
                cur.execute("CALL hts.proc_hts_joined_v2(%s)", (datim,))
        logger.info(f"Procedure proc_hts_joined_v2 for {datim} executed successfully.")
    except Exception as e:
        logger.error(f"Operational error occurred while processing {datim} for proc_hts_joined_v2 procedure: {e}")


def generate_cte_concurrently(datim_ids, max_workers):
    """
    Runs proc_hts_joined_v2 concurrently across facilities.
    Each worker opens its own connection internally.
    """
    logger.info(f"Starting final joined insert for {len(datim_ids)} facilities.")
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        executor.map(run_hts_joined, datim_ids)
    logger.info(f"All procedures for CTE generation and final insert completed for {datim_ids}")


def run_final_hts(conn, ip_name, periodcode):
    """
    Executes the final HTS procedure for an IP.
    Accepts an active connection passed by the caller.
    """
    try:
        with conn.cursor() as cur:
            cur.execute("CALL hts.proc_final_hts(%s)", (ip_name,))
            conn.commit()
            logger.info(f"Procedure proc_final_hts for {ip_name} {periodcode} executed successfully.")
    except Exception as e:
        logger.error(f"Operational error occurred while processing {ip_name} for procedure: {e}")

def run_final_hts_for_ips(ip_names, periodcode):
    def _run(ip_name):
        with connect_to_db.connect('lamisplus_ods_dwh')[0] as conn:
            run_final_hts(conn, ip_name, periodcode)
    
    with concurrent.futures.ThreadPoolExecutor(max_workers=1) as executor:
        executor.map(_run, ip_names)
    logger.info(f"Batch of {len(ip_names)} final_hts procedures executed for {periodcode}")
    
def generate_hts_report(**kwargs):
    """
    Main orchestrator. Opens ONE connection for all sequential/administrative
    operations (truncates, final procedures).
    Concurrent per-facility procedures open their own short-lived connections internally.
    """
    periods = kwargs.get('periods', [])
    if not periods:
        raise ValueError("No periods provided for the report generation.")

    table_names = ["hts.hts_joined", "hts.hts_monitoring", "hts.hts_mapping"]

    ip_names = [
         'ACE-1', 'ACE-2', 'ACE-3', 'ACE-4', 'ACE-5', 'CARE 1', 
        'CARE 2'
    ]

    # One connection for all orchestration-level operations
    for periodcode in periods:
        with connect_to_db.connect('lamisplus_ods_dwh')[0] as conn:
            # 1. Truncate all tables
            run_truncate_for_ctes(table_names, periodcode)

            # 2. Per-IP: fetch facilities, run procedures concurrently
            #    (each worker opens its own connection internally)
            for ip in ip_names:
                datim_ids = fetch_datim_ids(conn, ip)
                if datim_ids:
                    logger.info(f"Processing IP: {ip} with {len(datim_ids)} facilities.")
                    generate_cte_concurrently(datim_ids, max_workers=30)

        # 3. Final rollup 
        run_final_hts_for_ips(ip_names, periodcode)


if __name__ == '__main__':
    generate_hts_report()
