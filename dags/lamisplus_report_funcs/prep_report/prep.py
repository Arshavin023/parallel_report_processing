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
import time
import threading
from concurrent.futures import ThreadPoolExecutor
import schedule
from database_connection.db_connect import connect_to_db
from src import logger

pd.set_option('display.max_columns', None)

dwh_conn = connect_to_db.connect('lamisplus_ods_dwh')[0]
cur2 = dwh_conn.cursor()
dwh_engine = connect_to_db.connect('lamisplus_ods_dwh')[1]

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
                cur.execute(f"TRUNCATE {table_name}")
                conn.commit()
                logger.info(f"Table {table_name} truncated successfully.")
    except psycopg2.OperationalError as e:
        logger.error(f"Operational error occurred while truncating {table_name}: {e}")

def run_truncate_for_ctes(table_names):
    with concurrent.futures.ThreadPoolExecutor() as executor:
       executor.map(truncate_table, table_names)


def run_single_procedure(procedure, datim):
    try:
        with connect_to_db.connect('lamisplus_ods_dwh')[0] as conn:
            with conn.cursor() as cur:
                # cur.execute("CALL %s(%s)", (procedure, datim))
                cur.execute(f"CALL prep.{procedure}('{datim}')")
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
def run_proc_prep_joined_insert(datim):
    try:
        with connect_to_db.connect('lamisplus_ods_dwh')[0] as conn:
            with conn.cursor() as cur:
                cur.execute("CALL prep.proc_prep_joined(%s)",(datim,))
                conn.commit()
                logger.info(f"Successfully executed prep_joined_insert for {datim}")
    except Exception as e:
        logger.error(f"Error occurred executing prep_joined_insert for {datim}: {e}")

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
            executor.map(run_proc_prep_joined_insert, batch)
        logger.info(f"Batch of {len(batch)} procedures executed successfully for datim_ids: {batch}")

def run_final_prep(ip_name, periodcode:str):
    try:
        with connect_to_db.connect('lamisplus_ods_dwh')[0] as conn:
            with conn.cursor() as cur:
                cur.execute(f"CALL prep.proc_final_prep('{ip_name}')")
                conn.commit()
                logger.info(f"Procedure {periodcode} proc_final_prep for {ip_name} executed successfully.")
    except psycopg2.OperationalError as e:
        logger.error(f"Operational error occurred while processing {ip_name} for procedure: {e}")

def generate_prep_report(**kwargs):
    periods = kwargs.get('periods', [])
    if not periods:
        raise ValueError("No periods provided for the report generation.")
    
    table_names = ["prep.prep_joined","prep.cte_baselineclinic",
                   "prep.cte_current_pc","prep.cte_prepbiodata",
                   "prep.prep_monitoring"]
    
    ip_names = [
        'ACE-1','ACE-2','ACE-3','ACE-4','ACE-5',
        'CARE 1','CARE 2'
                ]
    
    procedures = ["proc_currentpc","proc_baselineclinic","proc_prepbiodata"]
    
    group_datim_ids = [fetch_datim_ids(ip_name) for ip_name in ip_names]
    
    # Update period table
    for periodcode in periods:
        update_prep_period_table(periodcode)
        run_truncate_for_ctes(table_names)
        for datim_ids in group_datim_ids:
            generate_cte_concurrently(datim_ids, procedures, batch_size=25)
        for ip_name in ip_names:
            run_final_prep(ip_name, periodcode)

if __name__ == '__main__':
    generate_prep_report()