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
from database_connection.db_connect_v2 import connect_to_db
from src import logger

# Initialize connection pool
connect_to_db.init_pool('lamisplus_ods_dwh', minconn=10, maxconn=500)
dwh_engine = connect_to_db.get_engine()

pd.set_option('display.max_columns', None)

# Function to fetch datim_ids from the database
def fetch_datim_ids(ip_name):
    conn = connect_to_db.get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute("""SELECT datim_id FROM central_partner_mapping WHERE ip_name=%s""", (ip_name,))
            datims = cur.fetchall()
            return [record[0] for record in datims]
    finally:
        connect_to_db.put_conn(conn)

def update_expanded_radet_period_table(periodcode):
    conn = connect_to_db.get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute("CALL expanded_radet.proc_update_expanded_radet_period_table(%s)", (periodcode,))
            conn.commit()
            logger.info(f"Period {periodcode} updated successfully.")
    except Exception as e:
        logger.error(f"Error updating period {periodcode}: {e}")
    finally:
        connect_to_db.put_conn(conn)

def truncate_table(table_name):
    conn = connect_to_db.get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(f"TRUNCATE expanded_radet_client.{table_name}")
            conn.commit()
            logger.info(f"Table {table_name} truncated successfully.")
    except Exception as e:
        logger.error(f"Error truncating {table_name}: {e}")
    finally:
        connect_to_db.put_conn(conn)

def truncate_generic_table(table_name):
    conn = connect_to_db.get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(f"TRUNCATE {table_name}")
            conn.commit()
            logger.info(f"Table {table_name} truncated successfully.")
    except Exception as e:
        logger.error(f"Error truncating {table_name}: {e}")
    finally:
        connect_to_db.put_conn(conn)

def run_truncate_for_ctes(table_names):
    with concurrent.futures.ThreadPoolExecutor() as executor:
        executor.map(truncate_table, table_names)

def run_single_procedure(procedure, datim):
    conn = connect_to_db.get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(f"CALL expanded_radet_client.{procedure}(%s)", (datim,))
            conn.commit()
            logger.info(f"Executed {procedure} for {datim}")
    except Exception as e:
        logger.error(f"Error executing {procedure} for {datim}: {e}")
    finally:
        connect_to_db.put_conn(conn)

def run_procedures_for_datim(datim, procedures):
    with concurrent.futures.ThreadPoolExecutor() as executor:
        futures = [executor.submit(run_single_procedure, procedure, datim) for procedure in procedures]
        for future in concurrent.futures.as_completed(futures):
            future.result()

def run_proc_radet_joined_insert(datim):
    conn = connect_to_db.get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute("CALL expanded_radet_client.proc_radet_joined_insert_v2(%s)", (datim,))
            conn.commit()
            logger.info(f"Joined insert executed for {datim}")
    except Exception as e:
        logger.error(f"Error executing joined insert for {datim}: {e}")
    finally:
        connect_to_db.put_conn(conn)

def generate_cte_concurrently(datim_ids, procedures, batch_size=50):
    for i in range(0, len(datim_ids), batch_size):
        batch = datim_ids[i:i + batch_size]
        with concurrent.futures.ThreadPoolExecutor(max_workers=20) as executor:
            futures = [executor.submit(run_procedures_for_datim, datim, procedures) for datim in batch]
            for future in concurrent.futures.as_completed(futures):
                future.result()

    # for i in range(0, len(datim_ids), batch_size):
    #     batch = datim_ids[i:i + batch_size]
    #     with concurrent.futures.ThreadPoolExecutor(max_workers=50) as executor:
    #         executor.map(run_proc_radet_joined_insert, batch)

def run_expanded_radet_weekly(ip_name):
    conn = connect_to_db.get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute("CALL expanded_radet.proc_expanded_radet_weekly(%s)", (ip_name,))
            logger.info(f"Weekly RADet executed for {ip_name}")
    except Exception as e:
        logger.error(f"Error executing expanded_radet_weekly for {ip_name}: {e}")
    finally:
        connect_to_db.put_conn(conn)

def run_expanded_radet_weekly_for_ips(ip_names):
    [run_expanded_radet_weekly(ip_name) for ip_name in ip_names]

if __name__ == '__main__':
    table_names = [
        "cte_bio_data", "cte_biometric", "cte_carecardcd4", "cte_case_manager",
        "cte_cervical_cancer", "cte_client_verification", "cte_crytococal_antigen","cte_tbstatus", 
        "cte_current_clinical", "cte_current_regimen", "cte_current_status","cte_eac", 
        "cte_current_tb_result", "cte_current_vl_result","cte_dsd1", "cte_dsd2",
        "cte_ipt", "cte_ipt_s", "cte_iptnew", "cte_labcd4",
        "cte_previous","cte_previous_previous",
        "cte_naive_vl_data", "cte_ovc", "cte_patient_lga", "cte_pharmacy_details_regimen",
        "cte_sample_collection_date", "cte_tb_sample_collection", "cte_tblam", "cte_tbtreatment",
        "cte_tbtreatmentnew", "cte_vacauseofdeath",
        "expanded_radet_monitoring"
    ]

    procedures = [
         "proc_bio_data","proc_biometric","proc_carecardcd4", 
        "proc_case_manager","proc_cervical_cancer","proc_client_verification",
        "proc_crytococal_antigen","proc_tbstatus","proc_current_clinical",
        "proc_current_regimen", "proc_current_status","proc_eac", 
        "proc_current_tb_result", "proc_current_vl_result","proc_dsd1",
        "proc_dsd2","proc_ipt", "proc_ipt_s", "proc_iptnew", "proc_labcd4",
        # "proc_previous", "proc_previous_previous"
         "proc_naive_vl_data", "proc_ovc", "proc_patient_lga",
        "proc_pharmacy_details_regimen","proc_sample_collection_date", "proc_tb_sample_collection",
        "proc_tblam", "proc_tbtreatment","proc_tbtreatmentnew", "proc_vacauseofdeath"
    ]

    ip_names = [
        # 'ACE-1','ACE-2','ACE-3','ACE-4','ACE-5','ACE-6','CARE 1',
        'CARE 2'
    ]

    group_ip_datims = [fetch_datim_ids(ip) for ip in ip_names]
    # run_truncate_for_ctes(table_names)
    # truncate_generic_table('expanded_radet.obt_radet')
    for datim_ids in group_ip_datims:
        generate_cte_concurrently(datim_ids, procedures)
