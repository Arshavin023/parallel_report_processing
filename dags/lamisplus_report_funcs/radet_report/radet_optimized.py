import json
import psycopg2
import pandas as pd
import numpy as np
import datetime
import concurrent.futures
from concurrent.futures import ThreadPoolExecutor
import threading
from functools import partial
from sqlalchemy import text

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
        logger.error(f"Error updating period {periodcode}: {e}")


def truncate_table(conn, table_name, periodcode):
    """
    Truncates a single CTE table.
    Accepts an active connection passed by the caller.
    """
    try:
        with conn.cursor() as cur:
            cur.execute(f"TRUNCATE expanded_radet_client.{table_name}")
            conn.commit()
            logger.info(f"Truncated expanded_radet_client.{table_name} for period: {periodcode}")
    except Exception as e:
        logger.error(f"Error truncating {table_name}: {e}")


def truncate_generic_table(conn, table_name):
    """
    Truncates a table by full qualified name.
    Accepts an active connection passed by the caller.
    """
    try:
        with conn.cursor() as cur:
            cur.execute(f"TRUNCATE {table_name}")
            conn.commit()
            logger.info(f"Truncated {table_name} successfully.")
    except Exception as e:
        logger.error(f"Error truncating {table_name}: {e}")


def run_truncate_for_ctes(conn, table_names, periodcode):
    """
    Truncates all CTE tables sequentially using a single connection.
    ThreadPoolExecutor removed — truncates on the same connection
    cannot safely run concurrently.
    """
    for table_name in table_names:
        truncate_table(conn, table_name, periodcode)


def run_single_procedure(datim, procedure, periodcode):
    """
    Executes a single stored procedure for a given datim_id.
    Opens its own short-lived connection — safe for concurrent use
    since each thread gets an independent connection.
    """
    try:
        with connect_to_db.connect('lamisplus_ods_dwh')[0] as conn:
            conn.autocommit = True
            with conn.cursor() as cur:
                cur.execute(
                    f"CALL expanded_radet_client.{procedure}(%s)",
                    (datim,)
                )
        logger.info(f"Executed {procedure} for {datim} [{periodcode}]")
    except Exception as e:
        logger.error(f"Error executing {procedure} for {datim} [{periodcode}]: {e}")


def run_procedures_for_datim(datim, procedures, periodcode):
    """
    Runs all CTE procedures concurrently for a single datim_id.
    Each procedure gets its own connection via run_single_procedure.
    """
    with ThreadPoolExecutor() as executor:
        futures = [
            executor.submit(run_single_procedure, datim, procedure, periodcode)
            for procedure in procedures
        ]
        for future in concurrent.futures.as_completed(futures):
            future.result()


def run_proc_radet_joined_insert(datim, periodcode):
    """
    Executes the final joined insert procedure for a datim_id.
    Opens its own short-lived connection — safe for concurrent use.
    """
    try:
        with connect_to_db.connect('lamisplus_ods_dwh')[0] as conn:
            conn.autocommit = True
            with conn.cursor() as cur:
                cur.execute(
                    "CALL expanded_radet_client.proc_radet_joined_insert_v2(%s)",
                    (datim,)
                )
        logger.info(f"Executed radet_joined_insert for {datim} [{periodcode}]")
    except Exception as e:
        logger.error(f"Error executing radet_joined_insert for {datim} [{periodcode}]: {e}")


def generate_cte_concurrently(datim_ids, procedures, periodcode, max_workers):
    """
    Step 1: Generate all CTEs concurrently across facilities.
    Step 2: Run the final joined insert concurrently across facilities.
    Each worker opens its own connection internally.
    """
    logger.info(f"Generating CTEs for {len(datim_ids)} facilities.")
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        executor.map(
            lambda datim: run_procedures_for_datim(datim, procedures, periodcode),
            datim_ids
        )

    logger.info(f"Running final joined insert for {len(datim_ids)} facilities.")
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        executor.map(
            lambda datim: run_proc_radet_joined_insert(datim, periodcode),
            datim_ids
        )


def run_expanded_radet_weekly(conn, ip_name, periodcode):
    """
    Executes the weekly expanded radet procedure for a single IP.
    Accepts an active connection passed by the caller.
    """
    try:
        with conn.cursor() as cur:
            cur.execute(
                "CALL expanded_radet.proc_expanded_radet_weekly(%s)",
                (ip_name,)
            )
            conn.commit()
            logger.info(f"Executed expanded_radet_weekly for {ip_name} [{periodcode}]")
    except Exception as e:
        logger.error(f"Error executing expanded_radet_weekly for {ip_name}: {e}")


def run_expanded_radet_weekly_for_ips(conn, ip_names, periodcode):
    """
    Runs weekly expanded radet for all IPs sequentially on a single connection.
    Sequential here is intentional — these write to shared period-level partitions
    and concurrent execution would risk conflicts.
    """
    for ip_name in ip_names:
        run_expanded_radet_weekly(conn, ip_name, periodcode)


def generate_radet_report(**kwargs):
    """
    Main orchestrator. Opens ONE connection for all sequential/administrative
    operations (truncates, period updates, weekly rollup).
    Concurrent per-facility procedures open their own short-lived connections internally.
    """
    periods = kwargs.get('periods', [])
    if not periods:
        raise ValueError("No periods provided for the report generation.")

    table_names = [
        "cte_bio_data", "cte_biometric", "cte_carecardcd4", "cte_case_manager",
        "cte_cervical_cancer", "cte_client_verification", "cte_crytococal_antigen", "cte_tbstatus",
        "cte_current_clinical", "cte_current_regimen", "cte_current_status", "cte_eac",
        "cte_current_tb_result", "cte_current_vl_result", "cte_dsd1", "cte_dsd2",
        "cte_ipt", "cte_ipt_s", "cte_iptnew", "cte_labcd4", "cte_negativetbdiagnosticresults",
        "cte_naive_vl_data", "cte_ovc", "cte_patient_lga", "cte_pharmacy_details_regimen",
        "cte_sample_collection_date", "cte_tb_sample_collection", "cte_tblam", "cte_tbtreatment",
        "cte_tbtreatmentnew", "cte_vacauseofdeath", "expanded_radet_monitoring"
    ]

    procedures = [
        "proc_bio_data", "proc_biometric", "proc_carecardcd4",
        "proc_case_manager", "proc_cervical_cancer", "proc_client_verification",
        "proc_crytococal_antigen", "proc_tbstatus", "proc_current_clinical",
        "proc_current_regimen", "proc_current_status", "proc_eac", "proc_previous_v2",
        "proc_current_tb_result", "proc_current_vl_result", "proc_dsd1", "proc_previous_previous_v2",
        "proc_dsd2", "proc_ipt", "proc_ipt_s", "proc_iptnew", "proc_labcd4",
        "proc_naive_vl_data", "proc_ovc", "proc_patient_lga", "proc_negativetbdiagnosticresults",
        "proc_pharmacy_details_regimen", "proc_sample_collection_date", "proc_tb_sample_collection",
        "proc_tblam", "proc_tbtreatment", "proc_tbtreatmentnew", "proc_vacauseofdeath"
    ]

    ip_names = [
        'ACE-1', 'ACE-2', 'ACE-3', 'ACE-4',
        'CARE 1', 'CARE 2', 'ACE-5'
    ]

    # One connection for all orchestration-level operations
    with connect_to_db.connect('lamisplus_ods_dwh')[0] as conn:
        for periodcode in periods:

            # 1. Update period table
            # update_expanded_radet_period_table(conn, periodcode)

            # 2. Truncate all CTE tables and the output table
            run_truncate_for_ctes(conn, table_names, periodcode)
            truncate_generic_table(conn, 'expanded_radet.obt_radet')

            # 3. Per-IP: fetch facilities, generate CTEs concurrently
            #    (each worker opens its own connection internally)
            for ip in ip_names:
                datim_ids = fetch_datim_ids(conn, ip)
                if datim_ids:
                    logger.info(f"Processing IP: {ip} with {len(datim_ids)} facilities.")
                    generate_cte_concurrently(datim_ids, procedures, periodcode, max_workers=10)

            # 4. Weekly rollup — sequential, shared connection
            run_expanded_radet_weekly_for_ips(conn, ip_names, periodcode)


if __name__ == '__main__':
    generate_radet_report()
