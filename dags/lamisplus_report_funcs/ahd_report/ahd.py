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

def update_ahd_period_table(periodcode):
    try:
        with connect_to_db.connect('lamisplus_ods_dwh')[0] as conn:
            with conn.cursor() as cur:
                cur.execute("CALL expanded_radet.proc_update_expanded_radet_period_table(%s)",(periodcode,))
                conn.commit()
    except Exception as e:
        print(f"Error occurred while updating period {periodcode}: {e}")

def truncate_table(table_name):
    try:
        with connect_to_db.connect('lamisplus_ods_dwh')[0] as conn:
            with conn.cursor() as cur:
                cur.execute(f"TRUNCATE ahd.{table_name}")
                conn.commit()
    except Exception as e:
        print(f"Error occurred while truncating {table_name}: {e}")

def run_truncate_for_ctes(table_names):
    with concurrent.futures.ThreadPoolExecutor() as executor:
       executor.map(truncate_table, table_names)


def run_single_procedure(procedure, datim):
    try:
        with connect_to_db.connect('lamisplus_ods_dwh')[0] as conn:
            with conn.cursor() as cur:
                # cur.execute("CALL %s(%s)", (procedure, datim))
                cur.execute(f"CALL ahd.{procedure}('{datim}')")
                conn.commit()
    except Exception as e:
        print(f"Error occurred while processing {datim} for procedure {procedure}: {e}")

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
def run_proc_lastcd4(datim):
    try:
        with connect_to_db.connect('lamisplus_ods_dwh')[0] as conn:
            with conn.cursor() as cur:
                cur.execute("CALL ahd.proc_lastcd4(%s)",(datim,))
                conn.commit()
    except Exception as e:
        print(f"Error occurred while running proc_ahd_joined_insert for {datim}: {e}")
        
# Function to run `proc_radet_joined_insert` for a single `datim_id`
def run_proc_ahd_joined_insert(datim):
    try:
        with connect_to_db.connect('lamisplus_ods_dwh')[0] as conn:
            with conn.cursor() as cur:
                cur.execute("CALL ahd.proc_ahd_joined_insert(%s)",(datim,))
                conn.commit()
    except Exception as e:
        print(f"Error occurred while running proc_ahd_joined_insert for {datim}: {e}")

#  Function to generate CTE concurrently
def generate_cte_concurrently(datim_ids:list, procedures:list):
    #Run the initial procedures for all `datim_id`s concurrently
    [run_procedures_for_datim(datim_id, procedures) for datim_id in datim_ids] 
    
    # After all initial procedures are completed, run `proc_radet_joined_insert` for each `datim_id`
    with concurrent.futures.ThreadPoolExecutor() as executor:
       executor.map(run_proc_lastcd4, datim_ids)
       
    # After all initial procedures are completed, run `proc_radet_joined_insert` for each `datim_id`
    with concurrent.futures.ThreadPoolExecutor() as executor:
       executor.map(run_proc_ahd_joined_insert, datim_ids)

def schedule_jobs(ip_names:list,procedures:list):
    group_ip_datims = [fetch_datim_ids(ip) for ip in ip_names]

    threads=[]
    for ip_datims in group_ip_datims:
        thread = threading.Thread(target=generate_cte_concurrently, args=(ip_datims,procedures))
        thread.daemon = True
        thread.start()
        threads.append(thread)
        time.sleep(10)  # Delay to avoid overloading resources

    for thread in threads:
        thread.join()
    
def run_final_ahd(ip_name:str):
    try:
        with connect_to_db.connect('lamisplus_ods_dwh')[0] as conn:
            with conn.cursor() as cur:
                cur.execute(f"CALL ahd.proc_final_ahd('{ip_name}')")
    except Exception as e:
        print(f"Error occurred while processing radet for procedure {ip_name}: {e}")

def run_final_ahd_for_ips(ip_names:list):
    [run_final_ahd(ip_name) for ip_name in ip_names]

if __name__ == '__main__':
    table_names = [
        "cte_ahd","cte_carecardcd4","cte_labcd4","cte_lastcrytococalantigen",
        "cte_lastcsfcrag","cte_lastlflam","cte_lastserumcrag","cte_lastvisitect",
        "cte_sample_collection_date","cte_current_status","cte_cd4type","cte_eac",
        "cte_lastoneyear_vl_result","cte_current_vl_result","cte_lastcd4",
        "ahd_monitoring","ahd_joined"
        #,"cte_previous"
        
    ]
    periods = [
        '2025Q1'
        #,'2025W4'
        ]
    procedures = [
        "proc_ahd","proc_carecardcd4","proc_labcd4","proc_lastcrytococalantigen",
        "proc_lastcsfcrag","proc_lastlflam","proc_lastserumcrag","proc_lastvisitect",
        "proc_sample_collection_date","proc_current_status","proc_cd4type","proc_eac",
        "proc_lastoneyear_vl_result","proc_current_vl_result"
        #,"proc_previous"
        
    ]
    ip_names = [
        'ACE-1','ACE-2','ACE-3',
        'ACE-4','ACE-5',
        'CARE 1'
        'CARE 2'
                ]
    for periodcode in periods:
        run_truncate_for_ctes(table_names)
        update_ahd_period_table(periodcode)
        schedule_jobs(ip_names,procedures)
        run_final_ahd_for_ips(ip_names)

