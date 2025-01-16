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
                --AND datim_id NOT IN (SELECT datim_id FROM central_partner_mapping WHERE is_run)
                AND json_rec_count > 0 
                AND processed = 'N' 
                AND load_time >= '2024-12-01' 
                ORDER BY load_time ASC LIMIT 3000""".format(staging_table))
    ls_to_process = cur.fetchall()
    load_time = datetime.datetime.now()
    ls_to_process.sort(key=lambda i: i[1])

    print(f'Processing {table_name} data...')

    for datim_id, batch_id, file_name in ls_to_process:
        df = pd.read_sql(f"SELECT * FROM {staging_table} WHERE stg_datim_id = '{datim_id}' AND stg_batch_id = '{batch_id}' AND stg_file_name = '{file_name}'", con=stg_engine)
        df = df.drop(['stg_batch_id', 'stg_load_time', 'stg_file_name'], axis=1)
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
                SET processed='Y', stg_deleted='N', error_message='No errors'
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
        delete_archived_query = f"""CALL public.proc_delete_archived_records('{ods_table}')"""
        #delete_archived_query = f"""DELETE FROM {ods_table} WHERE archived=1"""
        # delete_archived_params = (ods_table)
        cur2.execute(delete_archived_query)
        print(f'archived records deleted from {ods_table} on data warehouse')
    
    except Exception as e:
        print(f'deletion of archived records from {ods_table} failed')
     
def process_patient_person():  
    table_name = 'patient_person'
    constraints = 'ods_datim_id,uuid'
    #ods_setup_new(table_name, constraints)
    dtype = {'contact_point': JSON().with_variant(JSONB, 'postgresql'), 'address': JSON().with_variant(JSONB, 'postgresql'),
                                  'gender': JSON().with_variant(JSONB, 'postgresql'), 'identifier': JSON().with_variant(JSONB, 'postgresql'),
                                  'marital_status': JSON().with_variant(JSONB, 'postgresql'), 'employment_status': JSON().with_variant(JSONB, 'postgresql'),
                                  'organization': JSON().with_variant(JSONB, 'postgresql'), 'contact': JSON().with_variant(JSONB, 'postgresql'),
                                  'education': JSON().with_variant(JSONB, 'postgresql')}
    process_stg_to_ods(table_name, constraints, dtype=dtype)

    
def process_case_manager():
    table_name = 'case_manager'
    constraints = 'ods_datim_id, uuid'
    #ods_setup_new(table_name, constraints)
    process_stg_to_ods(table_name, constraints)

def process_case_manager_patients():
    table_name = 'case_manager_patients'
    constraints = 'ods_datim_id, id'
    #ods_setup_new(table_name, constraints)
    process_stg_to_ods(table_name, constraints)

def process_patient_visit():
    table_name = 'patient_visit'
    constraints = 'ods_datim_id, id'
    #ods_setup_new(table_name, constraints)
    process_stg_to_ods(table_name, constraints)

def process_hiv_regimen_resolver():
    table_name  = 'hiv_regimen_resolver'
    constraints = 'ods_datim_id,regimensys, regimen'
    #ods_setup_new(table_name, constraints)
    process_stg_to_ods(table_name, constraints)

def process_base_application_codeset():
    table_name = 'base_application_codeset'
    constraints = 'ods_datim_id, code'
    #ods_setup_new(table_name, constraints)
    process_stg_to_ods(table_name, constraints)

def process_hiv_art_clinical():
    table_name = 'hiv_art_clinical'
    dtype = {'adverse_drug_reactions': JSON().with_variant(JSONB, 'postgresql'), 'adheres': JSON().with_variant(JSONB, 'postgresql'),
                                  'tb_screen': JSON().with_variant(JSONB, 'postgresql'), 'opportunistic_infections': JSON().with_variant(JSONB, 'postgresql'),
                                  'arvdrugs_regimen': JSON().with_variant(JSONB, 'postgresql'), 'viral_load_order': JSON().with_variant(JSONB, 'postgresql'),
                                  'extra': JSON().with_variant(JSONB, 'postgresql'),}
    constraints = 'ods_datim_id, uuid'
    #ods_setup_new(table_name, constraints)
    process_stg_to_ods(table_name, constraints, dtype=dtype)

def process_hiv_enrollment():
    table_name = 'hiv_enrollment'
    constraints = 'ods_datim_id, uuid'
    #ods_setup_new(table_name, constraints)
    process_stg_to_ods(table_name, constraints)

def process_hiv_observation():
    table_name = 'hiv_observation'
    constraints = 'ods_datim_id, uuid'
    #ods_setup_new(table_name, constraints)
    dtype ={'data': JSON().with_variant(JSONB, 'postgresql')}
    process_stg_to_ods(table_name, constraints, dtype=dtype)

def process_hiv_status_tracker():
    table_name = 'hiv_status_tracker'
    constraints = 'ods_datim_id, uuid'
    #ods_setup_new(table_name, constraints)
    process_stg_to_ods(table_name, constraints)

def process_hts_index_elicitation():
    table_name = 'hts_index_elicitation'
    constraints = 'ods_datim_id, id'
    #ods_setup_new(table_name, constraints)
    dtype = {'extra': JSON().with_variant(JSONB, 'postgresql')}
    process_stg_to_ods(table_name, constraints, dtype=dtype)

def process_hts_risk_stratification():
    table_name = 'hts_risk_stratification'
    constraints = 'ods_datim_id, code'
    #ods_setup_new(table_name, constraints)
    dtype = {'risk_assessment': JSON().with_variant(JSONB, 'postgresql')}
    process_stg_to_ods(table_name, constraints, dtype=dtype)

def process_hts_family_index():
    table_name = 'hts_family_index'
    constraints = 'ods_datim_id, uuid'
    #ods_setup_new(table_name, constraints)
    process_stg_to_ods(table_name, constraints)
    
def process_hts_family_index_testing():
    table_name = 'hts_family_index_testing'
    constraints = 'ods_datim_id, uuid'
    #ods_setup_new(table_name, constraints)
    dtype = {'extra': JSON().with_variant(JSONB, 'postgresql')}
    process_stg_to_ods(table_name, constraints, dtype=dtype)
    
def process_hts_pns_index_client_partner():
    table_name = 'hts_pns_index_client_partner'
    constraints = 'ods_datim_id, uuid'
    #ods_setup_new(table_name, constraints)
    dtype = {'intermediate_partner_violence': JSON().with_variant(JSONB, 'postgresql'), 
             'hts_client_information': JSON().with_variant(JSONB, 'postgresql'),
             'contact_tracing': JSON().with_variant(JSONB, 'postgresql'),}
    process_stg_to_ods(table_name, constraints, dtype=dtype)
    
def process_patient_encounter():
    table_name = 'patient_encounter'
    constraints = 'ods_datim_id, uuid'
    #ods_setup_new(table_name, constraints)
    process_stg_to_ods(table_name, constraints)

def process_prep_clinic():
    table_name = 'prep_clinic'
    constraints = 'ods_datim_id, uuid'
    #ods_setup_new(table_name, constraints)
    dtype = {'hepatitis': JSON().with_variant(JSONB, 'postgresql'), 'syphilis': JSON().with_variant(JSONB, 'postgresql'),
                                         'syndromic_sti_screening': JSON().with_variant(JSONB, 'postgresql'), 'other_tests_done': JSON().with_variant(JSONB, 'postgresql'),
                                         'extra': JSON().with_variant(JSONB, 'postgresql'), 'urinalysis': JSON().with_variant(JSONB, 'postgresql'),}
    process_stg_to_ods(table_name, constraints, dtype=dtype)

def process_prep_enrollment():
    table_name = 'prep_enrollment'
    constraints = 'ods_datim_id, uuid'
    #ods_setup_new(table_name, constraints)
    dtype = {'extra': JSON().with_variant(JSONB, 'postgresql'),}
    process_stg_to_ods(table_name, constraints, dtype=dtype)

def process_prep_interruption():
    table_name = 'prep_interruption'
    constraints = 'ods_datim_id, uuid'
    #ods_setup_new(table_name, constraints)
    dtype = {'extra': JSON().with_variant(JSONB, 'postgresql'),}
    process_stg_to_ods(table_name, constraints, dtype=dtype)

def process_prep_eligibility():
    table_name = 'prep_eligibility'
    constraints = 'ods_datim_id, uuid'
    #ods_setup_new(table_name, constraints)
    dtype = {'extra': JSON().with_variant(JSONB, 'postgresql'),
             'hiv_risk': JSON().with_variant(JSONB, 'postgresql'),
             'sti_screening': JSON().with_variant(JSONB, 'postgresql'),
             'drug_use_history': JSON().with_variant(JSONB, 'postgresql'),
             'personal_hiv_risk_assessment': JSON().with_variant(JSONB, 'postgresql'),
             'sex_partner_risk': JSON().with_variant(JSONB, 'postgresql'),
             'services_received_by_client': JSON().with_variant(JSONB, 'postgresql'),
             'assessment_for_pep_indication': JSON().with_variant(JSONB, 'postgresql'),
             'assessment_for_prep_eligibility': JSON().with_variant(JSONB, 'postgresql'),
             'assessment_for_acute_hiv_infection': JSON().with_variant(JSONB, 'postgresql'),}
    process_stg_to_ods(table_name, constraints, dtype=dtype)

def process_triage_vital_sign():
    table_name = 'triage_vital_sign'
    constraints = 'ods_datim_id, uuid'
    #ods_setup_new(table_name, constraints)
    process_stg_to_ods(table_name, constraints)

def process_hts_client():
    table_name = 'hts_client'
    constraints = 'ods_datim_id, uuid'
    #ods_setup_new(table_name, constraints)
    dtype={'extra': JSON().with_variant(JSONB, 'postgresql'), 'test1': JSON().with_variant(JSONB, 'postgresql'),
                                  'test2': JSON().with_variant(JSONB, 'postgresql'), 'confirmatory_test': JSON().with_variant(JSONB, 'postgresql'),
                                  'confirmatory_test2': JSON().with_variant(JSONB, 'postgresql'),
                                  'tie_breaker_test': JSON().with_variant(JSONB, 'postgresql'), 'tie_breaker_test2': JSON().with_variant(JSONB, 'postgresql'),
                                  'knowledge_assessment': JSON().with_variant(JSONB, 'postgresql'), 'risk_assessment': JSON().with_variant(JSONB, 'postgresql'),
                                  'tb_screening': JSON().with_variant(JSONB, 'postgresql'), 'sti_screening': JSON().with_variant(JSONB, 'postgresql'),
                                  'hepatitis_testing': JSON().with_variant(JSONB, 'postgresql'), 'recency': JSON().with_variant(JSONB, 'postgresql'),
                                  'syphilis_testing': JSON().with_variant(JSONB, 'postgresql'), 'index_notification_services_elicitation': JSON().with_variant(JSONB, 'postgresql'),
                                  'post_test_counseling': JSON().with_variant(JSONB, 'postgresql'), 'sex_partner_risk_assessment': JSON().with_variant(JSONB, 'postgresql'),
                                  'others': JSON().with_variant(JSONB, 'postgresql'), 'cd4': JSON().with_variant(JSONB, 'postgresql'),}
    process_stg_to_ods(table_name, constraints, dtype=dtype)

def process_base_organisation_unit():
    table_name = 'base_organisation_unit'
    constraints = 'ods_datim_id, id'
    #ods_setup_new(table_name, constraints)
    dtype={'details': JSON().with_variant(JSONB, 'postgresql')}
    process_stg_to_ods(table_name, constraints, dtype=dtype)

def process_base_organisation_unit_identifier():
    table_name = 'base_organisation_unit_identifier'
    constraints = 'ods_datim_id, id'
    #ods_setup_new(table_name, constraints)
    process_stg_to_ods(table_name, constraints)

def process_hiv_regimen():
    table_name = 'hiv_regimen'
    constraints = 'ods_datim_id, id'
    #ods_setup_new(table_name, constraints)
    process_stg_to_ods(table_name, constraints)

def process_hiv_regimen_type():
    table_name = 'hiv_regimen_type'
    constraints = 'ods_datim_id, id'
    #ods_setup_new(table_name, constraints)
    process_stg_to_ods(table_name, constraints)

def process_laboratory_sample():
    table_name = 'laboratory_sample'
    constraints = 'ods_datim_id, id'
    #ods_setup_new(table_name, constraints)
    process_stg_to_ods(table_name, constraints)

def process_laboratory_test():
    table_name = 'laboratory_test'
    constraints = 'ods_datim_id, id'
    #ods_setup_new(table_name, constraints)
    process_stg_to_ods(table_name, constraints)

def process_laboratory_result():
    table_name = 'laboratory_result'
    constraints = 'ods_datim_id, id'
    #ods_setup_new(table_name, constraints)
    process_stg_to_ods(table_name, constraints)

def process_hiv_art_pharmacy():
    table_name = 'hiv_art_pharmacy'
    constraints = 'ods_datim_id, uuid'
    #ods_setup_new(table_name, constraints)
    dtype = {'extra': JSON().with_variant(JSONB, 'postgresql'), 'adverse_drug_reactions': JSON().with_variant(JSONB, 'postgresql'),
                                         'ipt': JSON().with_variant(JSONB, 'postgresql')}
    process_stg_to_ods(table_name, constraints, dtype=dtype)

def process_laboratory_labtest():
    table_name = 'laboratory_labtest'
    constraints = 'ods_datim_id, id'
    #ods_setup_new(table_name, constraints)
    process_stg_to_ods(table_name, constraints)

def process_hiv_art_pharmacy_regimens():
    table_name = 'hiv_art_pharmacy_regimens'
    constraints = 'art_pharmacy_id, regimens_id, ods_datim_id'
    #ods_setup_new(table_name, constraints)
    process_stg_to_ods(table_name, constraints)

def process_hiv_regimen_drug():
    table_name = 'hiv_regimen_drug'
    constraints = 'regimen_id, drug_id, ods_datim_id'
    #ods_setup_new(table_name, constraints)
    process_stg_to_ods(table_name, constraints)
    

def process_hiv_eac_session():
    table_name = 'hiv_eac_session'
    constraints = 'ods_datim_id, uuid'
    #ods_setup_new(table_name, constraints)
    dtype = {'barriers': JSON().with_variant(JSONB, 'postgresql'), 'intervention': JSON().with_variant(JSONB, 'postgresql'),
                                         }
    process_stg_to_ods(table_name, constraints, dtype=dtype)

def process_biometric():
    table_name = 'biometric'
    constraints = 'ods_datim_id, id'
    #ods_setup_new(table_name, constraints)
    dtype = {'extra': JSON().with_variant(JSONB, 'postgresql')}
    process_stg_to_ods(table_name, constraints, dtype=dtype)  

def process_hiv_eac():
    table_name = 'hiv_eac'
    constraints = 'ods_datim_id, uuid'
    #ods_setup_new(table_name, constraints)
    process_stg_to_ods(table_name, constraints) 

def process_hiv_eac_out_come():
    table_name = 'hiv_eac_out_come'
    constraints = 'ods_datim_id, uuid'
    #ods_setup_new(table_name, constraints)
    dtype = {'plan_action': JSON().with_variant(JSONB, 'postgresql')}
    process_stg_to_ods(table_name, constraints)    
    
def process_dsd_devolvement():
    table_name = 'dsd_devolvement'
    constraints = 'ods_datim_id, person_uuid, uuid'
    #ods_setup_new(table_name, constraints)
    process_stg_to_ods(table_name, constraints)  
    
def process_laboratory_order():
    table_name = 'laboratory_order'
    constraints = 'ods_datim_id, uuid, patient_id'
    #ods_setup_new(table_name, constraints)
    process_stg_to_ods(table_name, constraints)
    
def process_pmtct_anc():
    table_name = 'pmtct_anc'
    constraints = 'ods_datim_id, person_uuid, id'
    #ods_setup_new(table_name, constraints)
    dtype = {'pmtct_hts_info': JSON().with_variant(JSONB, 'postgresql'),
            'partner_notification': JSON().with_variant(JSONB, 'postgresql'),
            'partner_information': JSON().with_variant(JSONB, 'postgresql'),}
    process_stg_to_ods(table_name, constraints, dtype=dtype) 

def process_pmtct_delivery():
    table_name = 'pmtct_delivery'
    constraints = 'id, uuid, person_uuid, ods_datim_id'
    #ods_setup_new(table_name, constraints)
    process_stg_to_ods(table_name, constraints)

def process_pmtct_enrollment():
    table_name = 'pmtct_enrollment'
    constraints = 'id, uuid, person_uuid, ods_datim_id'
    #ods_setup_new(table_name, constraints)
    process_stg_to_ods(table_name, constraints)

def process_pmtct_infant_arv():
    table_name = 'pmtct_infant_arv'
    constraints = 'id, uuid, ods_datim_id'
    #ods_setup_new(table_name, constraints)
    process_stg_to_ods(table_name, constraints)

def process_pmtct_infant_pcr():
    table_name = 'pmtct_infant_pcr'
    constraints = 'id, uuid, ods_datim_id'
    #ods_setup_new(table_name, constraints)
    process_stg_to_ods(table_name, constraints)

def process_pmtct_infant_visit():
    table_name = 'pmtct_infant_visit'
    constraints = 'id, uuid, ods_datim_id'
    #ods_setup_new(table_name, constraints)
    process_stg_to_ods(table_name, constraints)

def process_pmtct_mother_visitation():
    table_name = 'pmtct_mother_visitation'
    constraints = 'id, person_uuid, uuid, ods_datim_id'
    #ods_setup_new(table_name, constraints)
    process_stg_to_ods(table_name, constraints)

def process_pmtct_infant_information():
    table_name = 'pmtct_infant_information'
    constraints = 'id, uuid, mother_person_uuid, ods_datim_id'
    #ods_setup_new(table_name, constraints)
    process_stg_to_ods(table_name, constraints)

def process_pmtct_infant_mother_art():
    table_name = 'pmtct_infant_mother_art'
    constraints = 'id, uuid, ods_datim_id'
    #ods_setup_new(table_name, constraints)
    process_stg_to_ods(table_name, constraints)
    
def process_pmtct_infant_rapid_antibody():
    table_name = 'pmtct_infant_rapid_antibody'
    constraints = 'id, uuid, ods_datim_id,unique_uuid'
    #ods_setup_new(table_name, constraints)
    process_stg_to_ods(table_name, constraints)

def process_sync_table_count():
    table_name = 'sync_table_count'
    constraints = 'id, facility_id, ods_datim_id'
    #ods_setup_new(table_name, constraints)
    process_stg_to_ods(table_name, constraints)

if __name__ == '__main__':
    process_patient_person()
    process_case_manager()
    process_case_manager_patients()
    process_patient_visit()
    process_hiv_regimen_resolver()
    process_base_application_codeset()
    process_hiv_art_clinical()
    process_hiv_enrollment()
    process_hiv_observation()
    process_hiv_status_tracker()
    process_hts_index_elicitation()
    process_hts_risk_stratification()
    process_hts_family_index()
    process_hts_family_index_testing()
    process_hts_pns_index_client_partner()
    process_patient_encounter()
    process_prep_clinic()
    process_prep_enrollment()
    process_prep_interruption()
    process_prep_eligibility()
    process_triage_vital_sign()
    process_hts_client()
    process_base_organisation_unit()
    process_base_organisation_unit_identifier()
    process_hiv_regimen()
    process_hiv_regimen_type()
    process_laboratory_sample()
    process_laboratory_test()
    process_laboratory_result()
    process_hiv_art_pharmacy()
    process_laboratory_labtest()
    process_hiv_art_pharmacy_regimens()
    process_hiv_eac_session()
    process_biometric()
    process_hiv_eac() 
    process_hiv_eac_out_come()
    process_dsd_devolvement()
    process_laboratory_order()
    process_pmtct_anc()
    process_pmtct_delivery()
    process_pmtct_enrollment()
    process_pmtct_infant_arv()
    process_pmtct_infant_pcr()
    process_pmtct_infant_visit()
    process_pmtct_mother_visitation()
    process_pmtct_infant_information()
    process_pmtct_infant_mother_art()
    process_pmtct_infant_rapid_antibody()
    process_sync_table_count()
    process_hiv_regimen_drug()
