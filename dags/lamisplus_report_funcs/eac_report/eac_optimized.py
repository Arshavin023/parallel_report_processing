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


def update_expanded_radet_period_table(conn, periodcode):
    """
    Updates the expanded radet period table.
    Accepts an active connection passed by the caller.
    """
    try:
        with conn.cursor() as cur:
            cur.execute(
                "CALL expanded_radet.proc_update_expanded_radet_period_table(%s)",
                (periodcode,)
            )
            conn.commit()
            logger.info(f"Period {periodcode} updated successfully.")
    except Exception as e:
        logger.error(f"Operational error occurred while updating period {periodcode}: {e}")


def truncate_table(conn, table_name, periodcode):
    """
    Truncates a single CTE table.
    Accepts an active connection passed by the caller.
    """
    try:
        with conn.cursor() as cur:
            cur.execute(f"TRUNCATE eac.{table_name}")
            conn.commit()
            logger.info(f"Table {table_name} truncated successfully for {periodcode}.")
    except Exception as e:
        logger.error(f"Operational error occurred while truncating {table_name} for {periodcode}: {e}")


def truncate_generic_table(conn, table_name):
    """
    Truncates a table by full qualified name.
    Accepts an active connection passed by the caller.
    """
    try:
        with conn.cursor() as cur:
            cur.execute(f"TRUNCATE {table_name}")
            conn.commit()
            logger.info(f"Table {table_name} truncated successfully.")
    except Exception as e:
        logger.error(f"Operational error occurred while truncating {table_name}: {e}")


def run_truncate_for_ctes(table_names, periodcode):
    def _run(table_name):
        with connect_to_db.connect('lamisplus_ods_dwh')[0] as conn:
            truncate_table(conn, table_name, periodcode)
    
    with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
        executor.map(_run, table_names)
    logger.info(f"Batch of {len(table_names)} TRUNCATE executed for {periodcode}")


def run_single_procedure(procedure, datim):
    """
    Executes a single stored procedure for a given datim_id.
    Opens its own short-lived connection — safe for concurrent use
    since each thread gets an independent connection.
    """
    try:
        with connect_to_db.connect('lamisplus_ods_dwh')[0] as conn:
            conn.autocommit = True
            with conn.cursor() as cur:
                cur.execute(f"CALL eac.{procedure}(%s)", (datim,))
        logger.info(f"Successfully executed {procedure} for {datim}")
    except Exception as e:
        logger.error(f"Error occurred executing {procedure} for {datim}: {e}")


def run_procedures_for_datim(datim, procedures):
    """
    Runs procedures concurrently for a single datim_id.
    Each procedure gets its own connection via run_single_procedure.
    """
    with ThreadPoolExecutor() as executor:
        futures = [
            executor.submit(run_single_procedure, procedure, datim)
            for procedure in procedures
        ]
        for future in concurrent.futures.as_completed(futures):
            future.result()


def run_proc_eac_joined(datim):
    """
    Executes proc_eac_joined for a datim_id.
    Opens its own short-lived connection — safe for concurrent use.
    """
    try:
        with connect_to_db.connect('lamisplus_ods_dwh')[0] as conn:
            conn.autocommit = True
            with conn.cursor() as cur:
                cur.execute("CALL eac.proc_eac_joined(%s)", (datim,))
        logger.info(f"Successfully executed eac_joined for {datim}")
    except Exception as e:
        logger.error(f"Error occurred executing eac_joined for {datim}: {e}")


def generate_cte_concurrently(datim_ids, firststage_procedures, secondstage_procedures, max_workers):
    """
    Step 1: Run firststage_procedures concurrently across facilities.
    Step 2: Run secondstage_procedures concurrently across facilities.
    Step 3: Run the final joined insert concurrently across facilities.
    Each worker opens its own connection internally.
    """
    logger.info(f"Starting to run firststage_procedures for {len(datim_ids)} facilities.")
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        tasks_cte = [(datim_id, firststage_procedures) for datim_id in datim_ids]
        executor.map(lambda args: run_procedures_for_datim(*args), tasks_cte)

    logger.info(f"Starting to run secondstage_procedures for {len(datim_ids)} facilities.")
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        tasks_cte = [(datim_id, secondstage_procedures) for datim_id in datim_ids]
        executor.map(lambda args: run_procedures_for_datim(*args), tasks_cte)

    logger.info(f"Starting final joined insert for {len(datim_ids)} facilities.")
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        executor.map(run_proc_eac_joined, datim_ids)


def run_final_eac(conn, ip_name, periodcode):
    """
    Executes the final EAC procedure for an IP.
    Accepts an active connection passed by the caller.
    """
    try:
        with conn.cursor() as cur:
            cur.execute("CALL eac.proc_final_eac(%s)", (ip_name,))
            conn.commit()
            logger.info(f"Successfully executed final_eac for {periodcode} for {ip_name}")
    except Exception as e:
        logger.error(f"Error occurred executing final_eac for {ip_name}: {e}")

def run_final_eac_for_ips(ip_names, periodcode):
    def _run(ip_name):
        with connect_to_db.connect('lamisplus_ods_dwh')[0] as conn:
            run_final_eac(conn, ip_name, periodcode)
    
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as executor:
        executor.map(_run, ip_names)
    logger.info(f"Batch of {len(ip_names)} final_eac procedures executed for {periodcode}")

def generate_eac_report(**kwargs):
    """
    Main orchestrator. Opens ONE connection for all sequential/administrative
    operations (truncates, period updates, final procedures).
    Concurrent per-facility procedures open their own short-lived connections internally.
    """
    periods = kwargs.get('periods', [])
    if not periods:
        raise ValueError("No periods provided for the report generation.")

    table_names = [
        "cte_bio_data", "cte_current_eac", "cte_eac_count",
        "cte_eight_eac", "cte_fifth_eac", "cte_first_eac",
        "cte_fourth_eac", "cte_lastpick", "cte_nine_eac",
        "cte_posteacvl1", "cte_posteacvl2", "cte_regimenatstart",
        "cte_second_eac", "cte_seven_eac", "cte_sixth_eac",
        "cte_third_eac", "cte_vlunsuppressed", "eac_joined",
        "eac_monitoring"
    ]

    firststage_procedures = [
        "proc_bio_data", "proc_current_eac", "proc_regimen", "proc_vlunsuppressed"
    ]
    secondstage_procedures = ["proc_posteacvl2", "proc_regimenastart", "proc_lastpick"]

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
                    generate_cte_concurrently(datim_ids, firststage_procedures, secondstage_procedures, max_workers=10)

        # 4. Final rollup — sequential, shared connection
        run_final_eac_for_ips(ip_names, periodcode)


if __name__ == '__main__':
    generate_eac_report()
