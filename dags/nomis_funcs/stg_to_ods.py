#!/home/nomis/nomis_venv/bin/python
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
from sqlalchemy.exc import SQLAlchemyError
from psycopg2.extras import execute_values

import warnings
warnings.filterwarnings("ignore", category=UserWarning, message=".*pandas only supports SQLAlchemy.*")

def read_db_config(filename='/home/lamisplus/database_credentials/nomis_config.ini', section='database'):
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

dwh_connect = f"postgresql://{ods_username}:{ods_password}@{ods_host}:{ods_port}/{ods_database_name}"

dwh_engine = create_engine(dwh_connect)

def convert_value(x):
    """Convert numpy and unsupported types to native Python types."""
    if isinstance(x, (np.integer, np.int64, np.int32)):
        return int(x)
    elif isinstance(x, (np.floating, np.float64, np.float32)):
        return float(x)
    elif isinstance(x, (np.bool_)):
        return bool(x)
    elif isinstance(x, (np.ndarray, list, dict)):
        return json.dumps(x)
    elif pd.isna(x):
        return None
    return x

def store_ods_df(df, table_name, constraints, dtype=None):
    ods_table = 'ods_' + table_name
    temp_table = 'temp_' + ods_table
    #print('Storing on temp table started')

    try:
        cur2.execute(f"DROP TABLE IF EXISTS {temp_table}")
        cur2.execute(f"CREATE TABLE {temp_table} (LIKE {ods_table} INCLUDING ALL)")

        if dtype is not None:
            for col in dtype.keys():
                if col in df.columns:
                    df[col] = df[col].apply(lambda x: json.dumps(x) if isinstance(x, (dict, list)) else x)

        values = [tuple(map(convert_value, row)) for row in df.itertuples(index=False)]
        cols = list(df.columns)
        insert_query = f"INSERT INTO {temp_table} ({', '.join(cols)}) VALUES %s"
        execute_values(cur2, insert_query, values)
        #print(f'Inserted {len(values)} rows into temp table.')

        update_cols = ', '.join([f"{col} = excluded.{col}" for col in cols])

        # Cast timestamp columns here
        timestamp_cols = ['ods_load_time']  # add any other timestamp cols here
        select_cols = []
        for col in cols:
            if col in timestamp_cols:
                select_cols.append(f"{col}::timestamp without time zone AS {col}")
            else:
                select_cols.append(col)
        select_expr = ', '.join(select_cols)

        upsert_query = f"""
            INSERT INTO {ods_table} ({', '.join(cols)})
            SELECT {select_expr} FROM {temp_table}
            ON CONFLICT ({constraints})
            DO UPDATE SET {update_cols}
        """
        cur2.execute(upsert_query)
        dwh_conn.commit()
        print(f'Upsert to {ods_table} complete. Rows affected: {cur2.rowcount}')

    except Exception as e:
        dwh_conn.rollback()
        print(f'❌ Error during upsert: {e}')
        raise



dtype_mapping = {
    'bigint': 'int64',
    'integer': 'int64',
    'timestamp without time zone': 'datetime64[ns]',
    'date': 'datetime64[ns]',
    'boolean': 'bool',
    'double precision': 'float64',
    'timestamp with time zone': 'datetime64[ns]',
    'smallint': 'int64',
    'bytea': 'object',
    'text': 'str',
    'uuid': 'uuid.UUID'

}


def transform_ods_df(df, table_name,  dtype=None):  
    if dtype is not None:
        cols = list(dtype.keys())
        for col in cols:
            df[col] = df[col].apply(lambda x: dict(x).get('value') if x!= None else None)
            df[col] = df[col].apply(lambda x: json.loads(x) if x!= None else None)
            
    df = df.replace(r'^\s*$', np.nan, regex=True)
         
    ## Fix data types
    df_cols = df.columns
    
    # df_data_types = pd.read_sql_query(data_type_query, staging_conn) ## query database
    df_data_types = pd.read_csv('/home/lamisplus/airflow/dags/files/nomis-datatypes.csv') 
    df_dtype_table = df_data_types[df_data_types['table_name']==table_name][['column_name', 'data_type']]
    arr_dtype_cols = df_dtype_table[(df_dtype_table['data_type']!= 'jsonb') & (df_dtype_table['data_type']!= 'character varying')].values
    dict_dtypes = {}
    for item in arr_dtype_cols:
        col_name, col_dtype = item[0], item[1]
        if col_name in df_cols:
            dict_dtypes[col_name] = dtype_mapping[col_dtype]
        
    # Pick date columns
    date_cols = [col for (col,val) in dict_dtypes.items() if val == 'datetime64[ns]']
    int_cols = [col for (col,val) in dict_dtypes.items() if val == 'int64']
    bool_cols = [col for (col,val) in dict_dtypes.items() if val == 'bool']
    float_cols = [col for (col,val) in dict_dtypes.items() if val == 'float64']
        
    for col in date_cols:
        #if df[col].dtype == 'object':
        df[col] = pd.to_datetime(df[col], errors='coerce')
        
    for col in int_cols:
        #if df[col].dtype == 'object':
        df[col] = pd.to_numeric(df[col], errors='coerce')

    for col in bool_cols:
        #if df[col].dtype == 'object':
        df[col] = df[col].astype('bool', errors='raise')

    for col in float_cols:
        #if df[col].dtype == 'object':
        df[col] = pd.to_numeric(df[col], errors='coerce')
    
    return df    
    #df = df.astype(dict_dtypes)

def process_stg_to_ods(table_name, constraints, dtype=None):
    staging_table = 'stg_' + table_name
    ods_table = 'ods_' + table_name
    record_count = 0
    stg_conn=stg_engine.connect()
    cur.execute("""SELECT cbo_project_id, batch_id, file_name 
                from stg_monitoring 
                where table_name = '{}' 
                --AND json_rec_count > 0 
                AND processed = 'N' 
                AND load_time >= '2024-06-01' 
                ORDER BY load_time ASC LIMIT 5000""".format(staging_table))
    ls_to_process = cur.fetchall()
    load_time = datetime.datetime.now()
    ls_to_process.sort(key=lambda i: i[1])

    print(f'Processing {table_name} data...')

    for cbo_project_id, batch_id, file_name in ls_to_process:
        df = pd.read_sql(f"""SELECT * FROM {staging_table} 
                            WHERE stg_cbo_project_id = '{cbo_project_id}' 
                            AND stg_batch_id = '{batch_id}' 
                            AND stg_file_name = '{file_name}'""", con=staging_conn)
        df = df.drop(['stg_batch_id', 'stg_load_time', 'stg_file_name'], axis=1)
        df = df.rename(columns={'stg_cbo_project_id': 'cbo_project_id'})
        df['ods_load_time'] = load_time
        df_count = len(df)
        record_count += int(df_count)
        print(f'Loading staging data for {cbo_project_id}: {batch_id}: {file_name}...')
        

        if not df.empty:
            ls_cons = constraints.replace(" ", "").split(',')
            print(ls_cons)
            df = df.drop_duplicates(subset=ls_cons)
            print(f'Transforming data for {cbo_project_id}: {batch_id}: {file_name}...')
            try:
                df_transformed = transform_ods_df(df, table_name, dtype=dtype)
                print(f'Storing ods data on {staging_table} for {cbo_project_id}: {file_name}...')
                store_ods_df(df_transformed, table_name, constraints, dtype=dtype)
                print(f'Successfully stored ods data for {cbo_project_id}: {batch_id}: {file_name}...')
                # Use connection for updates
                update_query_success = """
                UPDATE stg_monitoring 
                SET processed='Y', stg_deleted='N', error_message='No errors'
                WHERE table_name = %s AND cbo_project_id = %s 
                AND batch_id = %s AND file_name = %s
                """
                cur.execute(update_query_success,(staging_table,cbo_project_id,batch_id,file_name))
                staging_conn.commit()
                print(f'Updated stg_monitoring table for {staging_table} for successfully data migration')
                    
            except Exception as e:
                error_message=str(e)
                # Handle errors and log them in the staging database
                update_query_failed = """
                UPDATE stg_monitoring 
                SET processed='F', stg_deleted='N', error_message=%s
                WHERE table_name = %s AND cbo_project_id = %s 
                AND batch_id = %s AND file_name = %s
                """
                cur.execute(update_query_failed,(error_message, staging_table,cbo_project_id,batch_id,file_name))
                staging_conn.commit()
                print(f'Updated stg_monitoring table for {staging_table} for failed data migration')

        else:
            print(f'Successfully stored ods data for {cbo_project_id}: {batch_id}: {file_name}...')
            # Use connection for updates
            update_query_success = """
            UPDATE stg_monitoring 
            SET processed='Y', stg_deleted='N', error_message='No errors'
            WHERE table_name = %s AND cbo_project_id = %s 
            AND batch_id = %s AND file_name = %s
            """
            cur.execute(update_query_success,(staging_table,cbo_project_id,batch_id,file_name))
            # print(f'Rows affected: {cur.rowcount}')
            staging_conn.commit()
            print(f'Updated stg_monitoring table for {staging_table} for successfully data migration')

     
def process_person():  
    table_name = 'person'
    constraints = 'personUuid, cbo_project_id'
    #ods_setup_new(table_name, constraints)
    process_stg_to_ods(table_name, constraints)

    
def process_status():
    table_name = 'status'
    constraints = 'personUuid, cbo_project_id, hivStatus'
    #ods_setup_new(table_name, constraints)
    process_stg_to_ods(table_name, constraints)

def process_household():
    table_name = 'household'
    constraints = 'personUuid,householdUniqueId, cbo_project_id'
    #ods_setup_new(table_name, constraints)
    process_stg_to_ods(table_name, constraints)

def process_encounter():
    table_name  = 'encounter'
    constraints = 'uuid,cbo_project_id'
    #ods_setup_new(table_name, constraints)
    dtype ={'Observation': JSON().with_variant(JSONB, 'postgresql')}
    process_stg_to_ods(table_name, constraints, dtype=dtype)

def process_linelist():
    table_name = 'linelist'
    constraints = 'uuid, encounter_date, personUuid,cbo_project_id'
    #ods_setup_new(table_name, constraints)
    process_stg_to_ods(table_name, constraints)
    
    

if __name__ == '__main__':
    process_person()
    process_status()
    process_household()
    process_encounter()
    process_linelist()
