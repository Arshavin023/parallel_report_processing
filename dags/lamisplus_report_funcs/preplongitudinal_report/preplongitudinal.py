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


def run_single_procedure(datim):
    try:
        with connect_to_db.connect('lamisplus_ods_dwh')[0] as conn:
            with conn.cursor() as cur:
                cur.execute(f"CALL preplongitudinal.proc_preplongitudinal_joined('{datim}')")
                conn.commit()
                logger.info(f"Procedure proc_preplongitudinal_joined for {datim} executed successfully.")
    except psycopg2.OperationalError as e:
        logger.error(f"Operational error occurred while processing {datim} for procedure: {e}")

def run_final_preplongitudinal(ip_name, periodcode):
    try:
        with connect_to_db.connect('lamisplus_ods_dwh')[0] as conn:
            with conn.cursor() as cur:
                cur.execute(f"CALL preplongitudinal.proc_final_preplongitudinal('{ip_name}')")
                conn.commit()
                logger.info(f"Procedure proc_final_preplongitudinal for {periodcode} for {ip_name} executed successfully.")
    except psycopg2.OperationalError as e:
        logger.error(f"Operational error occurred while processing for {periodcode} for {ip_name} procedure: {e}")

#  Function to generate CTE concurrently
#def generate_cte_concurrently(datim_ids:list, batch_size:int):
    # After all initial procedures are completed, run `proc_radet_joined_insert` for each `datim_id`
#    for i in range(0, len(datim_ids), batch_size):
#        batch = datim_ids[i:i + batch_size]
#        with concurrent.futures.ThreadPoolExecutor(max_workers=batch_size) as executor:
#            executor.map(run_single_procedure, batch)
#        logger.info(f"Batch of {len(batch)} procedures executed successfully for datim_ids: {batch}")

#  Function to generate CTE concurrently
#  Function to generate CTE concurrently
def generate_cte_concurrently(datim_ids:list, max_workers:int):
    logger.info(f"Starting final joined insert for {len(datim_ids)} facilities.")
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        # Step 2: Run the final insert procedures
        executor.map(run_single_procedure, datim_ids)
    logger.info(f"All procedures for CTE generation and preplongitudinal_joined completed for {datim_ids}")

def generate_preplongitudinal_report(**kwargs):
    periods = kwargs.get('periods', [])
    if not periods:
        raise ValueError("No periods provided for the report generation.")
    
    table_names = ["preplongitudinal.preplongitudinal_joined",
                   "preplongitudinal.preplongitudinal_monitoring"]
    
    ip_names = [
        'ACE-1','ACE-2','ACE-3','ACE-4','ACE-5',
        'CARE 1','CARE 2'
                ]
    group_datim_ids = [fetch_datim_ids(ip_name) for ip_name in ip_names]
    
    # Update period table
    for periodcode in periods:
        run_truncate_for_ctes(table_names)
        for datim_ids in group_datim_ids:
            generate_cte_concurrently(datim_ids, 30)
        for ip_name in ip_names:
            run_final_preplongitudinal(ip_name, periodcode)

if __name__ == '__main__':
    generate_preplongitudinal_report()
