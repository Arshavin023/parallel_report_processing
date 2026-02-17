import json
import psycopg2
import pandas as pd
import numpy as np
import sqlalchemy
from sqlalchemy import create_engine, JSON, text
import datetime
from sqlalchemy.dialects.postgresql import JSONB, BYTEA
import configparser
import uuid
import concurrent.futures
from concurrent.futures import ThreadPoolExecutor
import time
import threading
import schedule
from database_connection.db_connect import connect_to_db
from database_connection.db_pool import engine  # Assumes this module exists and works
from src import logger
from functools import partial

pd.set_option('display.max_columns', None)

# Function to fetch datim_ids from the database
def fetch_datim_ids(ip_name):
    """Fetches datim IDs for a given IP name using a new, local connection."""
    try:
        with connect_to_db.connect('lamisplus_ods_dwh')[0] as conn:
            with conn.cursor() as cur:
                fetch_datims_query = """SELECT datim_id FROM central_partner_mapping
                                        WHERE ip_name=%s"""
                cur.execute(fetch_datims_query, (ip_name,))
                datims = cur.fetchall()
                datim_ids = [record[0] for record in datims]
                logger.info(f"Found {len(datim_ids)} datim_ids for IP: {ip_name}")
                return datim_ids
    except Exception as e:
        logger.error(f"Error fetching DATIM IDs for {ip_name}: {e}")
        return []

def update_expanded_radet_period_table(periodcode):
    try:
        with connect_to_db.connect('lamisplus_ods_dwh')[0] as conn:
            with conn.cursor() as cur:
                cur.execute("CALL expanded_radet.proc_update_expanded_radet_period_table(%s)",(periodcode,))
                conn.commit()
                logger.info(f"Period {periodcode} updated successfully.")
    except Exception as e:
        logger.error(f"Operational error occurred while updating period {periodcode}: {e}")

# Corrected function to truncate tables
def truncate_table(table_name, periodcode):
    try:
        with connect_to_db.connect('lamisplus_ods_dwh')[0] as conn:
            with conn.cursor() as cur:
                cur.execute(f"TRUNCATE expanded_radet_client.{table_name}")
                conn.commit()
                logger.info(f"Table expanded_radet_client.{table_name} truncated successfully. for period:{periodcode}")
    except Exception as e:
        logger.error(f"Operational error occurred while truncating {table_name}: {e}")

def truncate_generic_table(table_name):
    try:
        with connect_to_db.connect('lamisplus_ods_dwh')[0] as conn:
            with conn.cursor() as cur:
                cur.execute(f"TRUNCATE {table_name}")
                conn.commit()
                logger.info(f"Table {table_name} truncated successfully.")
    except Exception as e:
        logger.error(f"Operational error occurred while truncating {table_name}: {e}")

# Corrected function to run truncates concurrently
def run_truncate_for_ctes(table_names, periodcode):
    with concurrent.futures.ThreadPoolExecutor() as executor:
        truncate_func = partial(truncate_table, periodcode=periodcode)
        executor.map(truncate_func, table_names)

# Assumes 'engine' is an SQLAlchemy engine object
def run_single_procedure(procedure, datim, periodcode):
    try:
        with engine.connect() as conn:
            conn = conn.execution_options(isolation_level="AUTOCOMMIT")
            conn.execute(text(f"CALL expanded_radet_client.{procedure}(:datim_id)"), {"datim_id": datim})
        logger.info(f"Successfully executed {procedure} for {datim} for period:{periodcode}")
    except Exception as e:
        logger.error(f"Error executing {procedure} for {datim}: {e}")

def run_procedures_for_datim(datim, procedures, periodcode):
    with concurrent.futures.ThreadPoolExecutor() as executor:
        futures = [
            executor.submit(run_single_procedure, procedure, datim, periodcode)
            for procedure in procedures
        ]
        for future in concurrent.futures.as_completed(futures):
            future.result()

# Function to run `proc_radet_joined_insert` for a single `datim_id`
def run_proc_radet_joined_insert(datim, periodcode):
    try:
        with engine.connect() as conn:
            conn = conn.execution_options(isolation_level="AUTOCOMMIT")
            conn.execute(text("CALL expanded_radet_client.proc_radet_joined_insert(:datim_id)"), {"datim_id": datim})
            logger.info(f"Successfully executed radet_joined_insert for {datim} for {periodcode}")
    except Exception as e:
        logger.error(f"Error occurred executing radet_joined_insert for {datim} for {periodcode}: {e}")

def generate_cte_concurrently(datim_ids: list, procedures: list, periodcode: str, max_workers:int):
    with ThreadPoolExecutor(max_workers=max_workers) as executor:  # Use a single thread pool for all tasks
        # Step 1: Run procedures for each DATIM ID
        logger.info(f"Starting to generate CTEs for {len(datim_ids)} facilities.")
        tasks_cte = [(datim_id, procedures, periodcode) for datim_id in datim_ids]
        executor.map(lambda args: run_procedures_for_datim(*args), tasks_cte)
    
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        # Step 2: Run the final insert procedures
        logger.info(f"Starting final joined insert for {len(datim_ids)} facilities.")
        tasks_cte = [(datim_id, periodcode) for datim_id in datim_ids]
        executor.map(lambda args: run_proc_radet_joined_insert(*args), tasks_cte)

def run_expanded_radet_weekly(ip_name: str, periodcode: str):
    try:
        with connect_to_db.connect('lamisplus_ods_dwh')[0] as conn:
            with conn.cursor() as cur:
                cur.execute(f"CALL expanded_radet.proc_expanded_radet_weekly('{ip_name}')")
                conn.commit()
                logger.info(f"Successfully executed expanded_radet_weekly for {ip_name} for {periodcode}")
    except Exception as e:
        logger.error(f"Error occurred executing expanded_radet_weekly for {ip_name}: {e}")

def run_expanded_radet_weekly_for_ips(ip_names: list, periodcode: str):
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as executor:
        executor.map(lambda args: run_expanded_radet_weekly(*args), [(ip, periodcode) for ip in ip_names])
    logger.info(f"Batch of {len(ip_names)} expanded_radet_weekly procedures executed successfully for {periodcode}")
        
def generate_radet_report(**kwargs):
    periods = kwargs.get('periods', [])
    if not periods:
        raise ValueError("No periods provided for the report generation.")
    
    table_names = [
        "cte_bio_data", "cte_biometric", "cte_carecardcd4", "cte_case_manager",
        "cte_cervical_cancer", "cte_client_verification", "cte_crytococal_antigen","cte_tbstatus",
        "cte_current_clinical", "cte_current_regimen", "cte_current_status","cte_eac",
        "cte_current_tb_result", "cte_current_vl_result","cte_dsd1", "cte_dsd2",
        "cte_ipt", "cte_ipt_s", "cte_iptnew", "cte_labcd4","cte_negativetbdiagnosticresults",
        "cte_naive_vl_data", "cte_ovc", "cte_patient_lga", "cte_pharmacy_details_regimen",
        "cte_sample_collection_date", "cte_tb_sample_collection", "cte_tblam", "cte_tbtreatment",
        "cte_tbtreatmentnew", "cte_vacauseofdeath","expanded_radet_monitoring"
    ]

    procedures = [
        "proc_bio_data","proc_biometric","proc_carecardcd4",
        "proc_case_manager","proc_cervical_cancer","proc_client_verification",
        "proc_crytococal_antigen","proc_tbstatus","proc_current_clinical",
        "proc_current_regimen", "proc_current_status","proc_eac",
        "proc_current_tb_result", "proc_current_vl_result","proc_dsd1",
        "proc_dsd2","proc_ipt", "proc_ipt_s", "proc_iptnew", "proc_labcd4",
        "proc_naive_vl_data", "proc_ovc", "proc_patient_lga","proc_negativetbdiagnosticresults",
        "proc_pharmacy_details_regimen","proc_sample_collection_date", "proc_tb_sample_collection",
        "proc_tblam", "proc_tbtreatment","proc_tbtreatmentnew", "proc_vacauseofdeath"
        ]

    ip_names = [
        'ACE-1','ACE-2','ACE-3', 'ACE-4',
        'CARE 1', 'CARE 2', 'ACE-5'
    ]
        
    for periodcode in periods:
        run_truncate_for_ctes(table_names, periodcode) # Added missing periodcode
        truncate_generic_table('expanded_radet.obt_radet')
        
        # Process each IP sequentially to ensure all its facilities are handled
        # before moving to the next IP, which is good for logical reporting.
        for ip in ip_names:
            datim_ids = fetch_datim_ids(ip)
            if datim_ids:
                logger.info(f"Processing IP: {ip} with {len(datim_ids)} facilities.")
                generate_cte_concurrently(datim_ids, procedures, periodcode, 10) # Fixed arguments
        run_expanded_radet_weekly_for_ips(ip_names, periodcode)

if __name__ == '__main__':
    generate_radet_report()
