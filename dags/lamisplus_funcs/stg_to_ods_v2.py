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
from io import StringIO
import warnings

warnings.filterwarnings("ignore", category=UserWarning, message=".*pandas only supports SQLAlchemy.*")

# --- Configuration and Connection Setup ---

def read_db_config(filename='/home/lamisplus/database_credentials/config.ini', section='database'):
    parser = configparser.ConfigParser()
    parser.read(filename)
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

# Setup PostgreSQL connections and engines
staging_conn = psycopg2.connect(
    host=stg_host,
    database=stg_database_name,
    user=stg_username,
    password=stg_password
)
staging_conn.autocommit = False
cur = staging_conn.cursor()

dwh_conn = psycopg2.connect(
    host=ods_host,
    database=ods_database_name,
    user=ods_username,
    password=ods_password
)
dwh_conn.autocommit = False
cur2 = dwh_conn.cursor()

stg_engine = create_engine(f"postgresql+psycopg2://{stg_username}:{stg_password}@{stg_host}:{stg_port}/{stg_database_name}")
dwh_engine = create_engine(f"postgresql://{ods_username}:{ods_password}@{ods_host}:{ods_port}/{ods_database_name}")


# Load data types once at the start of the script
try:
    df_data_types_csv = pd.read_csv('/home/lamisplus/airflow/dags/files/datatypes.csv')
except FileNotFoundError:
    raise FileNotFoundError("datatypes.csv not found. Please ensure the file exists at /home/lamisplus/airflow/dags/files/")

dtype_mapping = {
    'bigint': 'Int64', # Using Int64 for nullable integer
    'integer': 'Int64',
    'timestamp without time zone': 'datetime64[ns]',
    'date': 'datetime64[ns]',
    'boolean': 'bool',
    'double precision': 'float64',
    'timestamp with time zone': 'datetime64[ns]',
    'smallint': 'Int64',
    'bytea': 'object',
    'text': 'str',
    'uuid': 'object' # uuid not directly a pandas dtype, handle separately
}

# --- Utility Functions ---

def convert_value(x):
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

    try:
        # Pre-process JSONB columns to ensure they are valid JSON strings
        if dtype:
            jsonb_columns = [
                col for col, sql_dtype in dtype.items()
                if isinstance(sql_dtype, JSON) or isinstance(sql_dtype, JSONB)
            ]

            for col in jsonb_columns:
                if col in df.columns:
                    def clean_jsonb(x):
                        if pd.isna(x) or x is None:
                            return None
                        try:
                            # Unwrap if structured like {'type': 'jsonb', 'value': '{...}'}
                            if isinstance(x, dict) and 'value' in x:
                                inner = x['value']
                                if isinstance(inner, str):
                                    return json.dumps(json.loads(inner))
                                return json.dumps(inner)
                            # If already dict or list
                            if isinstance(x, (dict, list)):
                                return json.dumps(x)
                            # If string containing JSON
                            if isinstance(x, str):
                                return json.dumps(json.loads(x))
                        except Exception:
                            return None  # fallback if parsing fails
                        return None

                    df[col] = df[col].apply(clean_jsonb)

        # Drop and recreate temp table
        cur2.execute(f"DROP TABLE IF EXISTS {temp_table}")
        cur2.execute(f"CREATE TABLE {temp_table} (LIKE {ods_table} INCLUDING ALL)")

        # Use StringIO to create a buffer and copy in bulk
        buffer = StringIO()
        df.to_csv(buffer, sep='\t', header=False, index=False, na_rep='\\N')
        buffer.seek(0)

        with dwh_conn.cursor() as temp_cur:
            temp_cur.copy_from(buffer, temp_table, sep='\t', null='\\N', columns=df.columns)
        dwh_conn.commit()
        print(f'Inserted {len(df)} rows into temp table using COPY FROM.')

        # Build UPSERT query
        update_cols = ', '.join([f"{col} = excluded.{col}" for col in df.columns])
        select_expr = ', '.join([
            f"{col}::timestamp without time zone AS {col}" if col == 'ods_load_time' else col
            for col in df.columns
        ])

        upsert_query = f"""
            INSERT INTO {ods_table} ({', '.join(df.columns)})
            SELECT {select_expr} FROM {temp_table}
            ON CONFLICT ({constraints})
            DO UPDATE SET {update_cols}
        """
        cur2.execute(upsert_query)
        dwh_conn.commit()
        print(f'Upsert to {ods_table} complete. Rows affected: {cur2.rowcount}')

    except Exception as e:
        dwh_conn.rollback()
        print(f'❌ Error during upsert for {ods_table}: {e}')
        raise


def transform_ods_df(df, table_name, dtype=None):
    df = df.replace(r'^\s*$', np.nan, regex=True)
    
    # Get column data types from the pre-loaded CSV
    df_dtype_table = df_data_types_csv[df_data_types_csv['table_name']==table_name][['column_name', 'data_type']]
    
    dict_dtypes = {}
    for _, row in df_dtype_table.iterrows():
        col_name, col_dtype = row['column_name'], row['data_type']
        if col_name in df.columns:
            if col_dtype in dtype_mapping:
                dict_dtypes[col_name] = dtype_mapping[col_dtype]
    
    # --- UPDATED JSONB PROCESSING LOGIC ---
    # Convert JSONB string data into Python objects, handling nested structures
    if dtype is not None:
        jsonb_columns = [
            col for col, sql_dtype in dtype.items() 
            if isinstance(sql_dtype, JSON) or isinstance(sql_dtype, JSONB)
        ]
        for col in jsonb_columns:
            if col in df.columns:
                def parse_json(x):
                    if isinstance(x, str) and x.strip():
                        try:
                            # First, try to load the outer object
                            outer_obj = json.loads(x)
                            
                            # Check for the nested structure we identified
                            if isinstance(outer_obj, dict) and 'value' in outer_obj and isinstance(outer_obj['value'], str):
                                # If present, parse the inner value as the actual JSON
                                # We replace escaped double quotes with single quotes for proper parsing
                                inner_str = outer_obj['value'].replace('""', '"')
                                return json.loads(inner_str)
                            
                            # If it's a simple JSON, return the parsed object
                            return outer_obj
                        except (json.JSONDecodeError, TypeError):
                            # If any parsing fails, return the original value
                            return x
                    return x
                
                df[col] = df[col].apply(parse_json)

    # Convert types in a vectorized way
    for col, target_dtype in dict_dtypes.items():
        if target_dtype == 'datetime64[ns]':
            df[col] = pd.to_datetime(df[col], errors='coerce')
        elif target_dtype in ['Int64', 'float64']:
            df[col] = pd.to_numeric(df[col], errors='coerce').astype(target_dtype)
        else:
            df[col] = df[col].astype(target_dtype, errors='ignore')
    
    return df

# --- Main Processing Function (Refactored) ---

def process_stg_to_ods(table_name, constraints, dtype=None):
    staging_table = 'stg_' + table_name
    ls_to_process = []
    
    try:
        # Get all batches to process in one go
        query_monitoring = text(f"""
            SELECT datim_id, batch_id, file_name
            FROM stg_monitoring
            WHERE table_name = :staging_table
            AND processed = 'N'
            AND load_time >= '2025-04-01'
            ORDER BY load_time ASC
            LIMIT 5
        """)
        
        with stg_engine.connect() as conn:
            ls_to_process = conn.execute(query_monitoring, {'staging_table': staging_table}).fetchall()
        
        if not ls_to_process:
            print(f"No unprocessed batches found for {table_name}. Skipping...")
            return

        print(f"Found {len(ls_to_process)} batches to process for {table_name}. Reading all data...")
        
        # Build the WHERE clause dynamically for bulk read
        conditions = []
        params = {}
        for i, (datim_id, batch_id, file_name) in enumerate(ls_to_process):
            conditions.append(
                f"(stg_datim_id = :datim_id_{i} AND stg_batch_id = :batch_id_{i} AND stg_file_name = :file_name_{i})"
            )
            params[f'datim_id_{i}'] = datim_id
            params[f'batch_id_{i}'] = batch_id
            params[f'file_name_{i}'] = file_name
        
        where_clause = " OR ".join(conditions)
        
        # --- FIX IS HERE ---
        # Instead of passing the TextClause to pd.read_sql, we execute it directly
        # and then create the DataFrame from the result.
        with stg_engine.connect() as conn:
            read_query = text(f"SELECT * FROM {staging_table} WHERE {where_clause}")
            result = conn.execute(read_query, params)
            
            # Fetch all results and column names to create the DataFrame
            columns = result.keys()
            df = pd.DataFrame(result.fetchall(), columns=columns)
            
            print(f'Successfully read {len(df)} rows for {table_name}. Starting transformation and upsert...')

        if df.empty:
            print(f"No data to process in {staging_table} despite having batches. Skipping...")
            return

        df = df.drop(['stg_batch_id', 'stg_load_time', 'stg_file_name'], axis=1, errors='ignore')
        df = df.rename(columns={'stg_datim_id': 'ods_datim_id'})
        df['ods_load_time'] = datetime.datetime.now()
        
        ls_cons = constraints.replace(" ", "").split(',')
        df = df.drop_duplicates(subset=ls_cons, keep='last')
        
        df_transformed = transform_ods_df(df, table_name, dtype=dtype)
        
        store_ods_df(df_transformed, table_name, constraints, dtype=dtype)
        
        # Update stg_monitoring table in a single transaction
        with staging_conn.cursor() as update_cur:
            for datim_id, batch_id, file_name in ls_to_process:
                update_query_success = """
                UPDATE stg_monitoring SET processed='Y', stg_deleted='N', error_message='No errors'
                WHERE table_name = %s AND datim_id = %s AND batch_id = %s AND file_name = %s
                """
                update_cur.execute(update_query_success, (staging_table, datim_id, batch_id, file_name))
            staging_conn.commit()
            print(f'Updated stg_monitoring for all batches of {staging_table} successfully.')
            
    except Exception as e:
        staging_conn.rollback()
        error_message = str(e)
        print(f'❌ Error processing {table_name}: {error_message}')
        if ls_to_process:
            with staging_conn.cursor() as update_cur:
                for datim_id, batch_id, file_name in ls_to_process:
                    update_query_failed = """
                    UPDATE stg_monitoring SET processed='F', stg_deleted='N', error_message=%s
                    WHERE table_name = %s AND datim_id = %s AND batch_id = %s AND file_name = %s
                    """
                    update_cur.execute(update_query_failed, (error_message, staging_table, datim_id, batch_id, file_name))
                staging_conn.commit()
                print(f'Updated stg_monitoring for all failed batches of {staging_table}.')
        raise


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

def process_hiv_patient_tracker():
    table_name = 'hiv_patient_tracker'
    constraints = 'uuid, person_uuid, ods_datim_id'
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

def process_prep_regimen():
    table_name = 'prep_regimen'
    constraints = 'ods_datim_id, id'
    #ods_setup_new(table_name, constraints)
    process_stg_to_ods(table_name, constraints)

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
    dtype={'details': JSON().with_variant(JSONB, 'postgresql'),}
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

def process_laboratory_sample_type():
    table_name = 'laboratory_sample_type'
    constraints = 'uuid, ods_datim_id'
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

def process_laboratory_labtestgroup():
    table_name = 'laboratory_labtestgroup'
    constraints = 'id, uuid, group_name, ods_datim_id'
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
    constraints = 'id, ods_datim_id'
    #ods_setup_new(table_name, constraints)
    process_stg_to_ods(table_name, constraints)
    
def process_pmtct_infant_pcr():
    table_name = 'pmtct_infant_pcr'
    constraints = 'id, ods_datim_id'
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

def process_hts_family_index_testing_tracker():
    table_name = 'hts_family_index_testing_tracker'
    constraints = 'uuid, ods_datim_id'
    #ods_setup_new(table_name, constraints)
    process_stg_to_ods(table_name, constraints)

def process_hts_client_referral():
    table_name = 'hts_client_referral'
    constraints = 'uuid, ods_datim_id'
    dtype = {'receiving_organization': JSON().with_variant(JSONB, 'postgresql'),
            'service_needed': JSON().with_variant(JSONB, 'postgresql'),}
    process_stg_to_ods(table_name, constraints, dtype=dtype)

def process_hivst():
    table_name = 'hivst'
    constraints = 'id, ods_datim_id'
    dtype = {'other_test_kit_user_details': JSON().with_variant(JSONB, 'postgresql'),
            'part_b': JSON().with_variant(JSONB, 'postgresql'),
            'referral_information': JSON().with_variant(JSONB, 'postgresql'),
            'test_kit_users': JSON().with_variant(JSONB, 'postgresql')}
    process_stg_to_ods(table_name, constraints, dtype=dtype)

def process_mhpss_screening():
    table_name = 'mhpss_screening'
    constraints = 'ods_datim_id, person_uuid, id'
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
    process_hiv_patient_tracker()
    process_hts_index_elicitation()
    process_hts_risk_stratification()
    process_hts_family_index()
    process_hts_family_index_testing()
    process_hts_pns_index_client_partner()
    process_patient_encounter()
    process_prep_clinic()
    process_prep_regimen()
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
    process_laboratory_sample_type()
    process_laboratory_test()
    process_laboratory_result()
    process_hiv_art_pharmacy()
    process_laboratory_labtest()
    process_laboratory_labtestgroup()
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
    process_hts_family_index_testing_tracker()
    process_hts_client_referral()
    process_hivst()
    process_mhpss_screening()
