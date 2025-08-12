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
from src import logger

dwh_conn = connect_to_db.connect('lamisplus_ods_dwh')[0]
cur2 = dwh_conn.cursor()
dwh_engine = connect_to_db.connect('lamisplus_ods_dwh')[1]
print(dwh_conn)
pd.set_option('display.max_columns', None)

# Function to fetch datim_ids from the database
def fetch_datim_ids(ip_name):
    fetch_datims_query = """SELECT datim_id FROM central_partner_mapping 
                            WHERE ip_name=%s"""
    cur2.execute(fetch_datims_query,(ip_name,))
    datims = cur2.fetchall()
    datim_ids = [record[0] for record in datims]  # Extract datim_id from the records
    return datim_ids

def update_expanded_radet_period_table(periodcode):
    try:
        with connect_to_db.connect('lamisplus_ods_dwh')[0] as conn:
            with conn.cursor() as cur:
                cur.execute("CALL expanded_radet.proc_update_expanded_radet_period_table(%s)",(periodcode,))
                conn.commit()
                logger.info(f"Period {periodcode} updated successfully.")
    except Exception as e:
        logger.error(f"Operational error occurred while updating period {periodcode}: {e}")

def truncate_table(table_name):
    try:
        with connect_to_db.connect('lamisplus_ods_dwh')[0] as conn:
            with conn.cursor() as cur:
                cur.execute(f"TRUNCATE expanded_radet_client.{table_name}")
                conn.commit()
                logger.info(f"Table {table_name} truncated successfully.")
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

def run_truncate_for_ctes(table_names):
    with concurrent.futures.ThreadPoolExecutor() as executor:
       executor.map(truncate_table, table_names)


def run_single_procedure(procedure, datim):
    try:
        with connect_to_db.connect('lamisplus_ods_dwh')[0] as conn:
            with conn.cursor() as cur:
                # cur.execute("CALL %s(%s)", (procedure, datim))
                cur.execute(f"CALL expanded_radet_client.{procedure}('{datim}')")
                conn.commit()
                logger.info(f"Successfully executed {procedure} for {datim}")
    except Exception as e:
        logger.error(f"Error occurred executing {procedure} for {datim}: {e}")

def run_procedures_for_datim(datim, procedures):
    with concurrent.futures.ThreadPoolExecutor() as executor:
        futures = [
            executor.submit(run_single_procedure, procedure, datim)
            for procedure in procedures
        ]
        
        # Wait for all futures to complete and handle exceptions if necessary
        for future in concurrent.futures.as_completed(futures):
            future.result()  # This will raise any exceptions that were caught during the procedure execution

# Function to run `proc_radet_joined_insert` for a single `datim_id`
def run_proc_radet_joined_insert(datim):
    try:
        with connect_to_db.connect('lamisplus_ods_dwh')[0] as conn:
            with conn.cursor() as cur:
                cur.execute("CALL expanded_radet_client.proc_radet_joined_insert_v2(%s)",(datim,))
                conn.commit()
                logger.info(f"Successfully executed radet_joined_insert for {datim}")
    except Exception as e:
        logger.error(f"Error occurred executing radet_joined_insert for {datim}: {e}")

def generate_cte_concurrently(datim_ids: list, procedures: list, batch_size=5):
    def process_datim(datim_id):
        # Run all 32 procedures for a single facility
        run_procedures_for_datim(datim_id, procedures)
    # Split datim_ids into batches of size batch_size
    batches = [datim_ids[i:i + batch_size] for i in range(0, len(datim_ids), batch_size)]

    # Process each batch sequentially
    for batch in batches:
        # process_batch(batch)
        with ThreadPoolExecutor() as executor:
            executor.map(process_datim, batch)
        logger.info(f"Batch of {len(batch)} procedures executed successfully for datim_ids: {batch}")

    for i in range(0, len(datim_ids), 25):
        batch = datim_ids[i:i + 25]
        with concurrent.futures.ThreadPoolExecutor() as executor:
            executor.map(run_proc_radet_joined_insert, batch)
        logger.info(f"Batch of {len(batch)} procedures executed successfully for datim_ids: {batch}")
    
def run_expanded_radet_weekly(ip_name:str, periodcode:str):
    try:
        with connect_to_db.connect('lamisplus_ods_dwh')[0] as conn:
            with conn.cursor() as cur:
                cur.execute(f"CALL expanded_radet.proc_expanded_radet_weekly('{ip_name}')")
                logger.info(f"Successfully executed {periodcode} expanded_radet_weekly for {ip_name}")
    except Exception as e:
        logger.error(f"Error occurred executing expanded_radet_weekly for {ip_name}: {e}")

def run_expanded_radet_weekly_for_ips(ip_names:list, periodcode:str):
    with concurrent.futures.ThreadPoolExecutor() as executor:
        executor.map(lambda args: run_expanded_radet_weekly(*args), [(ip, periodcode) for ip in ip_names])
    logger.info(f"Batch of {len(ip_names)} procedures executed successfully for datim_ids: {ip_names}")
        
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
        'ACE-1',
        'ACE-2','ACE-3','ACE-4','ACE-5',
        'CARE 1', 'CARE 2'
                ]
                
    group_ip_datims = [fetch_datim_ids(ip) for ip in ip_names]
    
    for periodcode in periods:
        #update_expanded_radet_period_table(periodcode)
        run_truncate_for_ctes(table_names)
        truncate_generic_table('expanded_radet.obt_radet')
        for datim_ids in group_ip_datims:
            generate_cte_concurrently(datim_ids, procedures, 50)
        run_expanded_radet_weekly_for_ips(ip_names,periodcode)

if __name__ == '__main__':
    generate_radet_report()
