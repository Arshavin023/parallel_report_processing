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
                cur.execute(f"TRUNCATE biometric.{table_name}")
                conn.commit()
                logger.info(f"Table {table_name} truncated successfully.")
    except Exception as e:
        logger.error(f"Operational error occurred while truncating {table_name}: {e}")

def run_truncate_for_ctes(table_names):
    with concurrent.futures.ThreadPoolExecutor() as executor:
       executor.map(truncate_table, table_names)

def run_biometric(datim):
    try:
        with connect_to_db.connect('lamisplus_ods_dwh')[0] as conn:
            with conn.cursor() as cur:
                cur.execute(f"CALL biometric.proc_biometric('{datim}')")
                conn.commit()
                logger.info(f"Procedure biometric for {datim} executed successfully.")
    except psycopg2.OperationalError as e:
        logger.error(f"Operational error occurred while processing {datim} for procedure: {e}")

#  Function to generate CTE concurrently
def generate_cte_concurrently(datim_ids:list, batch_size=25):
    for i in range(0, len(datim_ids), batch_size):
        batch = datim_ids[i:i + batch_size]
        with concurrent.futures.ThreadPoolExecutor() as executor:
            executor.map(run_biometric, batch)
        logger.info(f"Batch of {len(batch)} procedures executed successfully for datim_ids: {batch}")

def run_final_biometric(ip_name, period):
    try:
        with connect_to_db.connect('lamisplus_ods_dwh')[0] as conn:
            with conn.cursor() as cur:
                cur.execute(f"CALL biometric.proc_final_biometric('{ip_name}')")
                conn.commit()
                logger.info(f"Procedure proc_final_biometric for {period} for {ip_name} executed successfully.")
    except psycopg2.OperationalError as e:
        logger.error(f"Operational error occurred while processing {ip_name} for {period}: {e}")

def generate_biometric_report(**kwargs):
    periods = kwargs.get('periods', [])
    if not periods:
        raise ValueError("No periods provided for the report generation.")
    
    table_names = [
        "biometric_joined"
        ]
    
    procedures = [
        # "proc_biometric"
                  ]

    ip_names = [
        'ACE-1','ACE-2','ACE-3','ACE-4','ACE-5',
        'CARE 1', 'CARE 2'
                ]
    
    group_ip_datims = [fetch_datim_ids(ip) for ip in ip_names]

    for periodcode in periods:
        run_truncate_for_ctes(table_names)
        for datim_ids in group_ip_datims:
            generate_cte_concurrently(datim_ids, batch_size=50)
        for ip_name in ip_names:
            run_final_biometric(ip_name, periodcode)

if __name__ == '__main__':
    generate_biometric_report()