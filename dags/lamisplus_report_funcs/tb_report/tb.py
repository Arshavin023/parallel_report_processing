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

def update_prep_period_table(periodcode):
    try:
        with connect_to_db.connect('lamisplus_ods_dwh')[0] as conn:
            with conn.cursor() as cur:
                cur.execute("CALL prep.proc_update_prep_period_table(%s)",(periodcode,))
                conn.commit()
                logger.info(f"Period {periodcode} updated successfully.")
    except psycopg2.OperationalError as e:
        logger.error(f"Operational error occurred while updating period {periodcode}: {e}")

def truncate_table(table_name):
    try:
        with connect_to_db.connect('lamisplus_ods_dwh')[0] as conn:
            with conn.cursor() as cur:
                cur.execute(f"TRUNCATE tb.{table_name}")
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
                cur.execute(f"CALL tb.{procedure}('{datim}')")
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
def run_proc_tb_joined(datim):
    try:
        with connect_to_db.connect('lamisplus_ods_dwh')[0] as conn:
            with conn.cursor() as cur:
                cur.execute("CALL tb.proc_tb_joined(%s)",(datim,))
                conn.commit()
                logger.info(f"Successfully executed tb_joined for {datim}")
    except Exception as e:
        logger.error(f"Error occurred executing tb_joined for {datim}: {e}")

#def generate_cte_concurrently(datim_ids: list, procedures: list, batch_size=10):
#    def process_datim(datim_id):
        # Run all 32 procedures for a single facility
#        run_procedures_for_datim(datim_id, procedures)
    # Split datim_ids into batches of size batch_size
#    batches = [datim_ids[i:i + batch_size] for i in range(0, len(datim_ids), batch_size)]

    # Process each batch sequentially
#    for batch in batches:
#        # process_batch(batch)
#        with ThreadPoolExecutor(max_workers=batch_size) as executor:
#            executor.map(process_datim, batch)
#        logger.info(f"Batch of {len(batch)} procedures executed successfully for datim_ids: {batch}")

#    for i in range(0, len(datim_ids), batch_size):
#        batch = datim_ids[i:i + batch_size]
#        with concurrent.futures.ThreadPoolExecutor(max_workers=batch_size) as executor:
#            executor.map(run_proc_tb_joined, batch)
#        logger.info(f"Batch of {len(batch)} procedures executed successfully for datim_ids: {batch}")

def generate_cte_concurrently(datim_ids: list, procedures: list, max_workers=15):
    with ThreadPoolExecutor(max_workers=max_workers) as executor:  # Use a single thread pool for all tasks
        # Step 1: Run procedures for each DATIM ID
        logger.info(f"Starting to generate CTEs for {len(datim_ids)} facilities.")
        tasks_cte = [(datim_id, procedures) for datim_id in datim_ids]
        executor.map(lambda args: run_procedures_for_datim(*args), tasks_cte)
        
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        # Step 2: Run the final insert procedures
        logger.info(f"Starting final joined insert for {len(datim_ids)} facilities.")
        executor.map(run_proc_tb_joined, datim_ids)

def run_final_tb(ip_name:str, periodcode:str):
    try:
        with connect_to_db.connect('lamisplus_ods_dwh')[0] as conn:
            with conn.cursor() as cur:
                cur.execute(f"CALL tb.proc_final_tb('{ip_name}')")
                logger.info(f"Successfully executed final_tb for {periodcode} for {ip_name}")
    except Exception as e:
        logger.error(f"Error occurred executing final_tb for {ip_name}: {e}")

def run_final_tb_for_ips(ip_names:list, periodcode:str):
    [run_final_tb(ip_name,periodcode) for ip_name in ip_names]

def generate_tb_report(**kwargs):
    periods = kwargs.get('periods', [])
    if not periods:
        raise ValueError("No periods provided for the report generation.")
    
    table_names = [
        "bio_data","current_tb_result","ipt_ca","ipt_start",
        "iptnew","tb_sample_collection","tb_status","tb_treatement_completion",
        "tb_treatement_start","tbtreatmentnew","weight","negativetbdiagnosticresults",
        "tb_joined","tb_monitoring"
        ]
    
    procedures = [
        "proc_bio_data","proc_current_tb_result","proc_ipt_ca",
        "proc_ipt_start","proc_iptnew","proc_tb_sample_collection",
        "proc_tb_status","proc_tb_treatement_completion","proc_negativeTbDiagnosticResults",
        "proc_tb_treatement_start","proc_tbtreatmentnew","proc_weight"
                  ]

    ip_names = [
        'ACE-1','ACE-2','ACE-3','ACE-4','ACE-5',
        'CARE 1', 'CARE 2'
                ]
    
    group_ip_datims = [fetch_datim_ids(ip) for ip in ip_names]

    for periodcode in periods:
        run_truncate_for_ctes(table_names)
        for datim_ids in group_ip_datims:
            generate_cte_concurrently(datim_ids, procedures, batch_size=15)
        run_final_tb_for_ips(ip_names,periodcode)

if __name__ == '__main__':
    generate_tb_report()
