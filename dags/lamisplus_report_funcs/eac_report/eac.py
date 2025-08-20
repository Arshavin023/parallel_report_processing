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
    except psycopg2.OperationalError as e:
        logger.error(f"Operational error occurred while updating period {periodcode}: {e}")

def truncate_table(table_name):
    try:
        with connect_to_db.connect('lamisplus_ods_dwh')[0] as conn:
            with conn.cursor() as cur:
                cur.execute(f"TRUNCATE eac.{table_name}")
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
                cur.execute(f"CALL eac.{procedure}('{datim}')")
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
def run_proc_current_eac(datim):
    try:
        with connect_to_db.connect('lamisplus_ods_dwh')[0] as conn:
            with conn.cursor() as cur:
                cur.execute("CALL eac.proc_current_eac(%s)",(datim,))
                conn.commit()
                logger.info(f"Successfully executed current_eac for {datim}")
    except Exception as e:
        logger.error(f"Error occurred executing current_eac for {datim}: {e}")

# Function to run `proc_radet_joined_insert` for a single `datim_id`
def run_proc_vlunsuppressed(datim):
    try:
        with connect_to_db.connect('lamisplus_ods_dwh')[0] as conn:
            with conn.cursor() as cur:
                cur.execute("CALL eac.proc_vlunsuppressed(%s)",(datim,))
                conn.commit()
                logger.info(f"Successfully executed vlunsuppressed for {datim}")
    except Exception as e:
        logger.error(f"Error occurred executing vlunsuppressed for {datim}: {e}")
    
# Function to run `proc_radet_joined_insert` for a single `datim_id`
def run_proc_eac_joined(datim):
    try:
        with connect_to_db.connect('lamisplus_ods_dwh')[0] as conn:
            with conn.cursor() as cur:
                cur.execute("CALL eac.proc_eac_joined(%s)",(datim,))
                conn.commit()
                logger.info(f"Successfully executed eac_joined for {datim}")
    except Exception as e:
        logger.error(f"Error occurred executing eac_joined for {datim}: {e}")

def generate_cte_concurrently(datim_ids: list, procedures: list, batch_size:int):

    for i in range(0, len(datim_ids), batch_size):
        batch = datim_ids[i:i + batch_size]
        with concurrent.futures.ThreadPoolExecutor() as executor:
            executor.map(run_proc_current_eac, batch)
        logger.info(f"Batch of {len(batch)} procedures executed successfully for datim_ids: {batch}")

    def process_datim(datim_id):
        # Run all 32 procedures for a single facility
        run_procedures_for_datim(datim_id, procedures)
    # Split datim_ids into batches of size batch_size
    batches = [datim_ids[i:i + batch_size] for i in range(0, len(datim_ids), batch_size)]

    # Process each batch sequentially
    for batch in batches:
        # process_batch(batch)
        with ThreadPoolExecutor(max_workers=batch_size) as executor:
            executor.map(process_datim, batch)
        logger.info(f"Batch of {len(batch)} procedures executed successfully for datim_ids: {batch}")

    for i in range(0, len(datim_ids), batch_size):
        batch = datim_ids[i:i + batch_size]
        with concurrent.futures.ThreadPoolExecutor(max_workers=batch_size) as executor:
            executor.map(run_proc_vlunsuppressed, batch)
        logger.info(f"Batch of {len(batch)} procedures executed successfully for datim_ids: {batch}")

    for i in range(0, len(datim_ids), batch_size):
        batch = datim_ids[i:i + batch_size]
        with concurrent.futures.ThreadPoolExecutor(max_workers=batch_size) as executor:
            executor.map(run_proc_eac_joined, batch)
        logger.info(f"Batch of {len(batch)} procedures executed successfully for datim_ids: {batch}")
    
def run_final_eac(ip_name:str, periodcode:str):
    try:
        with connect_to_db.connect('lamisplus_ods_dwh')[0] as conn:
            with conn.cursor() as cur:
                cur.execute(f"CALL eac.proc_final_eac('{ip_name}')")
                logger.info(f"Successfully executed final_eac for {periodcode} for {ip_name}")
    except Exception as e:
        logger.error(f"Error occurred executing final_eac for {ip_name}: {e}")

def run_final_eac_for_ips(ip_names:list, periodcode:str):
    [run_final_eac(ip_name,periodcode) for ip_name in ip_names]


def generate_eac_report(**kwargs):
    periods = kwargs.get('periods', [])
    if not periods:
        raise ValueError("No periods provided for the report generation.")
    
    table_names = [
        "cte_bio_data","cte_current_eac","cte_eac_count",
        "cte_eight_eac","cte_fifth_eac","cte_first_eac",
        "cte_fourth_eac","cte_lastpick","cte_nine_eac",
        "cte_posteacvl1","cte_posteacvl2","cte_regimenatstart",
        "cte_second_eac","cte_seven_eac","cte_sixth_eac",
        "cte_third_eac","cte_vlunsuppressed","eac_joined",
        "eac_monitoring"
        ]
    
    procedures = [
        "proc_bio_data","proc_eac_count","proc_first_eac","proc_second_eac","proc_third_eac",
        "proc_fourth_eac","proc_fifth_eac","proc_sixth_eac","proc_seven_eac","proc_eight_eac",
        "proc_nine_eac","proc_posteacvl1","proc_posteacvl2","proc_regimenastart","proc_lastpick"
                  ]

    ip_names = [
        'ACE-1','ACE-2','ACE-3','ACE-4','ACE-5',
        'CARE 1', 'CARE 2'
                ]
    
    group_ip_datims = [fetch_datim_ids(ip) for ip in ip_names]

    for periodcode in periods:
        run_truncate_for_ctes(table_names)
        for datim_ids in group_ip_datims:
            generate_cte_concurrently(datim_ids, procedures, batch_size=5)
        run_final_eac_for_ips(ip_names,periodcode)

if __name__ == '__main__':
    generate_eac_report()
