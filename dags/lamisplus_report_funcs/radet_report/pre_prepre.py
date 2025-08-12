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
from functools import partial

# Create a connection and engine once for global use, but be cautious with multithreading
# It's better to create connections within each function/thread
# as done in the corrected code. The original global connection setup is problematic.
dwh_conn, dwh_engine = connect_to_db.connect('lamisplus_ods_dwh')
cur2 = dwh_conn.cursor()
print(dwh_conn)
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
                cur.execute(f"TRUNCATE expanded_radet_client.{table_name}")
                conn.commit()
                logger.info(f"Table expanded_radet_client.{table_name} truncated successfully.")
    except Exception as e:
        logger.error(f"Operational error occurred while truncating {table_name}: {e}")

# Corrected function to run truncates concurrently
def run_truncate_for_ctes(table_names, periodcode):
    with concurrent.futures.ThreadPoolExecutor() as executor:
        # Use functools.partial to fix the periodcode argument
        truncate_func = partial(truncate_table, periodcode=periodcode)
        executor.map(truncate_func, table_names)

def run_single_procedure(procedure, datim, periodcode):
    try:
        with connect_to_db.connect('lamisplus_ods_dwh')[0] as conn:
            with conn.cursor() as cur:
                if 'W' in periodcode:
                    cur.execute(f"CALL expanded_radet.{procedure}('{datim}')")
                    conn.commit()
                    logger.info(f"Successfully executed expanded_radet.{procedure} for {datim} for period {periodcode}.")
                
                cur.execute(f"CALL expanded_radet_client.{procedure}('{datim}')")
                conn.commit()
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

def generate_cte_concurrently(datim_ids: list, procedures: list, periodcode: str, batch_size=5):
    # This function now correctly passes the periodcode
    def process_datim(datim_id):
        run_procedures_for_datim(datim_id, procedures, periodcode)

    batches = [datim_ids[i:i + batch_size] for i in range(0, len(datim_ids), batch_size)]

    for batch in batches:
        with ThreadPoolExecutor() as executor:
            executor.map(process_datim, batch)
        logger.info(f"Batch of {len(batch)} procedures executed successfully for datim_ids: {batch}")

def process_pre_prepre_status(**kwargs):
    periods = kwargs.get('periods', [])
    if not periods:
        raise ValueError("No periods provided for the report generation.")
    
    table_names = ["cte_previous", "cte_previous_previous", "expanded_radet_monitoring"]
    procedures = ["proc_previous", "proc_previous_previous"]
    ip_names = [
                'ACE-1', 
                'ACE-2', 
                'ACE-3', 
                'ACE-4', 
                'ACE-5', 
                'CARE 1', 
                'CARE 2'
                ]
    group_ip_datims = [fetch_datim_ids(ip) for ip in ip_names]
    
    for periodcode in periods:
        run_truncate_for_ctes(table_names, periodcode)
        for datim_ids in group_ip_datims:
            # Correctly pass periodcode to the function
            generate_cte_concurrently(datim_ids, procedures, periodcode, 40)

if __name__ == '__main__':
    # You need to provide a period list to the function call.
    # Example: process_pre_prepre_status(periods=['2023W1', '2023W2'])
    # Or, for a single period:
    process_pre_prepre_status()
