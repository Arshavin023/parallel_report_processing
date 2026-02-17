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

# Create a connection and engine once for global use, but be cautious with multithreading
# It's better to create connections within each function/thread
# as done in the corrected code. The original global connection setup is problematic.
pd.set_option('display.max_columns', None)

# Function to fetch datim_ids from the database
def fetch_datim_ids(ip_name):
    with connect_to_db.connect('lamisplus_ods_dwh')[0] as conn:
        with conn.cursor() as cur:
            fetch_datims_query = """SELECT datim_id FROM central_partner_mapping 
                                    WHERE ip_name=%s"""
            cur.execute(fetch_datims_query,(ip_name,))
            datims = cur.fetchall()
            datim_ids = [record[0] for record in datims]
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

# Corrected function to truncate tables
def truncate_table(table_name, periodcode):
    try:
        with connect_to_db.connect('lamisplus_ods_dwh')[0] as conn:
            with conn.cursor() as cur:
                if 'W' in periodcode:
                    cur.execute(f"TRUNCATE expanded_radet.{table_name} RESTART IDENTITY")
                    conn.commit()
                    logger.info(f"Table expanded_radet.{table_name} truncated successfully.")
                
                # Truncate expanded_radet_client table
                else:
                    cur.execute(f"TRUNCATE expanded_radet_client.{table_name}")
                    conn.commit()
                    logger.info(f"Table expanded_radet_client.{table_name} truncated successfully.")
    except Exception as e:
        logger.error(f"Operational error occurred while truncating {table_name}: {e}")

# Corrected function to run truncates concurrently
def run_truncate_for_ctes(table_names, periodcode):
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as executor:
        # Use functools.partial to fix the periodcode argument
        truncate_func = partial(truncate_table, periodcode=periodcode)
        executor.map(truncate_func, table_names)

def run_single_procedure(procedure, datim, periodcode):
    try:
        with engine.connect() as conn:
            conn = conn.execution_options(isolation_level="AUTOCOMMIT")
            if 'W' in periodcode:
                conn.execute(f"CALL expanded_radet.{procedure}('{datim}')")
                logger.info(f"Successfully executed expanded_radet.{procedure} for {datim} for period {periodcode}.")
            else:
                conn.execute(f"CALL expanded_radet_client.{procedure}('{datim}')")
                logger.info(f"Successfully executed expanded_radet_client.{procedure} for {datim} for period {periodcode}.")
    except Exception as e:
        logger.error(f"Error occurred executing {procedure} for {datim}: {e}")

def run_procedures_for_datim(datim, procedures, periodcode):
    with concurrent.futures.ThreadPoolExecutor() as executor:
        futures = [
            executor.submit(run_single_procedure, procedure, datim, periodcode)
            for procedure in procedures
        ]
        for future in concurrent.futures.as_completed(futures):
            future.result()

def generate_cte_concurrently(datim_ids: list, procedures: list, periodcode: str, max_workers:int):
        
    with ThreadPoolExecutor(max_workers=max_workers) as executor:  # Use a single thread pool for all tasks
        # Step 1: Run procedures for each DATIM ID
        logger.info(f"Starting to generate previous and previous-previous CTEs for {len(datim_ids)} facilities.")
        tasks_cte = [(datim_id, procedures, periodcode) for datim_id in datim_ids]
        executor.map(lambda args: run_procedures_for_datim(*args), tasks_cte)
        #logger.info(f"Completed generation of previous and previous-previous CTEs for {len(datim_ids)} facilities.")

def process_pre_prepre_status(**kwargs):
    periods = kwargs.get('periods', [])
    if not periods:
        raise ValueError("No periods provided for the report generation.")
    
    table_names = ["cte_previous", "cte_previous_previous", "expanded_radet_monitoring"]
    procedures = ["proc_previous", "proc_previous_previous"]
    ip_names = [
                'ACE-1' #,
                #'ACE-2', 
                #'ACE-3', 
                #'ACE-4',  
                #'CARE 1', 
                #'CARE 2',
                #'ACE-5'
                ]
    group_ip_datims = [fetch_datim_ids(ip) for ip in ip_names]
    
    for periodcode in periods:
        #run_truncate_for_ctes(table_names, periodcode)
        for datim_ids in group_ip_datims:
            # Correctly pass periodcode to the function
            generate_cte_concurrently(datim_ids, procedures, periodcode, 50)

if __name__ == '__main__':
    process_pre_prepre_status()
