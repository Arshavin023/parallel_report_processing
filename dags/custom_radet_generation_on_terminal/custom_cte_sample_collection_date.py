import json
import uuid
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


def read_db_config(filename='/home/lamisplus/database_credentials/config.ini', section='database'):
    # Create a parser
    parser = configparser.ConfigParser()
    # Read the configuration file
    parser.read(filename)
    # Get section, default to database
    db = {}
    if parser.has_section(section):
        params = parser.items(section)
        for param in params:
            db[param[0]] = param[1]
    else:
        raise Exception(f'Section {section} not found in the {filename} file')
    return db


db_config = read_db_config()
ods_host = db_config['ods_host']
ods_port = db_config['ods_port']
ods_username = db_config['ods_username']
ods_password = db_config['ods_password']
ods_database_name = db_config['ods_database_name']
stg_host = db_config['stg_host']
stg_port = db_config['stg_port']
stg_username = db_config['stg_username']
stg_password = db_config['stg_password']
stg_database_name = db_config['stg_database_name']

pd.set_option('display.max_columns', None)

dwh_conn = psycopg2.connect(
    host=ods_host,
    database=ods_database_name,
    user=ods_username,
    password=ods_password)

cur2 = dwh_conn.cursor()

staging_conn = psycopg2.connect(
    host=stg_host,
    database=stg_database_name,
    user=stg_username,
    password=stg_password)

cur = staging_conn.cursor()

stg_connect = f"postgresql+psycopg2://{stg_username}:{stg_password}@{stg_host}:{stg_port}/{stg_database_name}"

stg_engine = create_engine(stg_connect)

dwh_connect = f"postgresql+psycopg2://{ods_username}:{ods_password}@{ods_host}:{ods_port}/{ods_database_name}"

dwh_engine = create_engine(dwh_connect)

# Function to fetch datim_ids from the database
def fetch_datim_ids():
    fetch_datims_query = "SELECT datim_id FROM central_partner_mapping"
    cur2.execute(fetch_datims_query)
    datims = cur2.fetchall()
    datim_ids = [record[0] for record in datims]  # Extract datim_id from the records
    return datim_ids


# Function to run all procedures for a single datim_id
def run_procedures_for_datim(datim):
    procedures = ["proc_sample_collection_date"]

    try:
        for procedure in procedures:
            cur2.execute(f"CALL expanded_radet_client.{procedure}('{datim}')")
            dwh_conn.commit()
    except Exception as e:
        print(f"Error occurred while processing {datim}: {e}")

# Function to generate CTE concurrently
def generate_cte_concurrently(datim_ids: list):
    # Run the initial procedures for all `datim_id`s concurrently
    with concurrent.futures.ThreadPoolExecutor() as executor:
        executor.map(run_procedures_for_datim, datim_ids)

if __name__ == '__main__':
    datim_ids=fetch_datim_ids()
    generate_cte_concurrently(datim_ids)