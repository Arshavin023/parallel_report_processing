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


def store_ods_df(df, table_name, constraints, dtype=None):
    ods_table = 'ods_' + table_name
    temp_table = 'temp_' + ods_table
    df.to_sql(temp_table, con=dwh_engine, index=False, if_exists='replace', dtype=dtype)
    cols = ','.join(df.columns.tolist())
    update_cols = ','.join([col + ' = excluded.' + col for col in cols.split(',')])
    ods_conn=dwh_engine.connect()
    upsert_query = f""" 
        INSERT INTO {ods_table}({cols})
        SELECT * FROM {temp_table}
        ON CONFLICT ({constraints})
        --DO NOTHING
        DO UPDATE SET {update_cols}
        """
    cur2.execute(upsert_query)
    dwh_conn.commit()
    print(f'Rows affected: {cur2.rowcount}')
    # Using a connection to execute the query
    # with dwh_engine.connect() as ods_conn:
        #dwh_engine.execute(upsert_query)
        #dwh_conn.commit()


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
    df_data_types = pd.read_csv('/home/lamisplus/airflow/dags/files/datatypes.csv') 
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
    cur.execute("""SELECT datim_id, batch_id, file_name 
                from stg_monitoring 
                where table_name = '{}'
                AND json_rec_count > 0 
                AND processed = 'N' 
                AND load_time >= '2024-07-15' 
                ORDER BY load_time ASC""".format(staging_table))
    ls_to_process = cur.fetchall()
    load_time = datetime.datetime.now()
    ls_to_process.sort(key=lambda i: i[1])

    print(f'Processing {table_name} data...')

    for datim_id, batch_id, file_name in ls_to_process:
        df = pd.read_sql(f"SELECT * FROM {staging_table} WHERE stg_datim_id = '{datim_id}' AND stg_batch_id = '{batch_id}' AND stg_file_name = '{file_name}'", con=stg_engine)
        df = df.drop(['stg_batch_id', 'stg_load_time', 'stg_file_name'], axis=1)
        df['template'] = None
        df = df.rename(columns={'stg_datim_id': 'ods_datim_id'})
        df['ods_load_time'] = load_time
        df_count = len(df)
        record_count += int(df_count)
        stg_conn=stg_engine.connect()
        print(f'Loading staging data for {datim_id}: {batch_id}: {file_name}...')
        

        if not df.empty:
            ls_cons = constraints.replace(" ", "").split(',')
            print(ls_cons)
            df = df.drop_duplicates(subset=ls_cons)
            print(f'Transforming data for {datim_id}: {batch_id}: {file_name}...')
            try:
                df_transformed = transform_ods_df(df, table_name, dtype=dtype)
                print(f'Storing ods data on {staging_table} for {datim_id}: {file_name}...')
                store_ods_df(df_transformed, table_name, constraints, dtype=dtype)
                print(f'Successfully stored ods data for {datim_id}: {batch_id}: {file_name}...')
                # Use connection for updates
                update_query_success = """
                UPDATE stg_monitoring 
                SET processed='P', stg_deleted='N'
                WHERE table_name = %s AND datim_id = %s 
                AND batch_id = %s AND file_name = %s
                """
                cur.execute(update_query_success,(staging_table,datim_id,batch_id,file_name))
                # print(f'Rows affected: {cur.rowcount}')
                staging_conn.commit()
                print(f'Updated stg_monitoring table for {staging_table} for successfully data migration')
                    
            except Exception as e:
                error_message=str(e)
                # Handle errors and log them in the staging database
                update_query_failed = """
                UPDATE stg_monitoring 
                SET processed='F', stg_deleted='N', error_message=%s
                WHERE table_name = %s AND datim_id = %s 
                AND batch_id = %s AND file_name = %s
                """
                cur.execute(update_query_failed,(error_message, staging_table,datim_id,batch_id,file_name))
                staging_conn.commit()
                print(f'Updated stg_monitoring table for {staging_table} for failed data migration')

        else:
            print(f'Successfully stored ods data for {datim_id}: {batch_id}: {file_name}...')
            # Use connection for updates
            update_query_success = """
            UPDATE stg_monitoring 
            SET processed='Y', stg_deleted='N', error_message='No errors'
            WHERE table_name = %s AND datim_id = %s 
            AND batch_id = %s AND file_name = %s
            """
            cur.execute(update_query_success,(staging_table,datim_id,batch_id,file_name))
            # print(f'Rows affected: {cur.rowcount}')
            staging_conn.commit()
            print(f'Updated stg_monitoring table for {staging_table} for successfully data migration')

    try:
        delete_archived_query = f"""DELETE FROM {ods_table} WHERE archived=1"""
        # delete_archived_params = (ods_table)
        cur2.execute(delete_archived_query)
        print(f'archived records deleted from {ods_table} on data warehouse')
    
    except Exception as e:
        print(f'deletion of archived records from {ods_table} failed')
     

def process_biometric():
    table_name = 'biometric'
    constraints = 'ods_datim_id, id'
    #ods_setup_new(table_name, constraints)
    dtype = {'extra': JSON().with_variant(JSONB, 'postgresql')
                                         }
    process_stg_to_ods(table_name, constraints, dtype=dtype)  


if __name__ == '__main__':
    process_biometric()