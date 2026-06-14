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
from contextlib import contextmanager

import warnings
warnings.filterwarnings("ignore", category=UserWarning, message=".*pandas only supports SQLAlchemy.*")


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


@contextmanager
def get_connections():
    """
    Opens one staging connection and one ODS/DWH connection for the duration
    of a processing run, then closes both on exit (normal or exception).

    Usage:
        with get_connections() as (staging_conn, dwh_conn):
            ...
    """
    db_config = read_db_config()
    staging_conn = psycopg2.connect(
        host=db_config['stg_host'],
        port=db_config['stg_port'],
        database=db_config['stg_database_name'],
        user=db_config['stg_username'],
        password=db_config['stg_password'],
    )
    dwh_conn = psycopg2.connect(
        host=db_config['ods_host'],
        port=db_config['ods_port'],
        database=db_config['ods_database_name'],
        user=db_config['ods_username'],
        password=db_config['ods_password'],
    )
    try:
        yield staging_conn, dwh_conn
    except Exception:
        staging_conn.rollback()
        dwh_conn.rollback()
        raise
    finally:
        staging_conn.close()
        dwh_conn.close()


pd.set_option('display.max_columns', None)


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
    'uuid': 'uuid.UUID',
}


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


def store_ods_df(dwh_conn, df, table_name, constraints, dtype=None):
    """
    Upsert df into ods_<table_name> via a temp table.
    Requires an active DWH connection passed explicitly by the caller.
    """
    ods_table = 'ods_' + table_name
    temp_table = 'temp_' + ods_table

    try:
        with dwh_conn.cursor() as cur:
            cur.execute(f"DROP TABLE IF EXISTS {temp_table}")
            cur.execute(f"CREATE TABLE {temp_table} (LIKE {ods_table} INCLUDING ALL)")

            if dtype is not None:
                for col in dtype.keys():
                    if col in df.columns:
                        df[col] = df[col].apply(
                            lambda x: json.dumps(x) if isinstance(x, (dict, list)) else x
                        )

            values = [tuple(map(convert_value, row)) for row in df.itertuples(index=False)]
            cols = list(df.columns)
            insert_query = f"INSERT INTO {temp_table} ({', '.join(cols)}) VALUES %s"
            execute_values(cur, insert_query, values)

            update_cols = ', '.join([f"{col} = excluded.{col}" for col in cols])

            timestamp_cols = ['ods_load_time']
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
            cur.execute(upsert_query)
            dwh_conn.commit()
            print(f'Upsert to {ods_table} complete. Rows affected: {cur.rowcount}')

    except Exception as e:
        dwh_conn.rollback()
        print(f'Error during upsert: {e}')
        raise


def transform_ods_df(df, table_name, dtype=None):
    """Applies type coercions and JSON unwrapping to df."""
    if dtype is not None:
        cols = list(dtype.keys())
        for col in cols:
            df[col] = df[col].apply(lambda x: dict(x).get('value') if x is not None else None)
            df[col] = df[col].apply(lambda x: json.loads(x) if x is not None else None)

    df = df.replace(r'^\s*$', np.nan, regex=True)

    df_cols = df.columns
    df_data_types = pd.read_csv('/home/lamisplus/airflow/dags/files/datatypes.csv')
    df_dtype_table = df_data_types[df_data_types['table_name'] == table_name][['column_name', 'data_type']]
    arr_dtype_cols = df_dtype_table[
        (df_dtype_table['data_type'] != 'jsonb') &
        (df_dtype_table['data_type'] != 'character varying')
    ].values

    dict_dtypes = {}
    for item in arr_dtype_cols:
        col_name, col_dtype = item[0], item[1]
        if col_name in df_cols:
            dict_dtypes[col_name] = dtype_mapping[col_dtype]

    date_cols  = [col for col, val in dict_dtypes.items() if val == 'datetime64[ns]']
    int_cols   = [col for col, val in dict_dtypes.items() if val == 'int64']
    bool_cols  = [col for col, val in dict_dtypes.items() if val == 'bool']
    float_cols = [col for col, val in dict_dtypes.items() if val == 'float64']

    for col in date_cols:
        df[col] = pd.to_datetime(df[col], errors='coerce')
    for col in int_cols:
        df[col] = pd.to_numeric(df[col], errors='coerce')
    for col in bool_cols:
        df[col] = df[col].astype('bool', errors='raise')
    for col in float_cols:
        df[col] = pd.to_numeric(df[col], errors='coerce')

    return df


def process_stg_to_ods(staging_conn, dwh_conn, table_name, constraints, dtype=None):
    """
    Moves unprocessed batches from stg_<table_name> into ods_<table_name>.
    Requires active staging and DWH connections passed explicitly by the caller.
    """
    staging_table = 'stg_' + table_name
    load_time = datetime.datetime.now()

    with staging_conn.cursor() as cur:
        cur.execute(
            """SELECT datim_id, batch_id, file_name
               FROM stg_monitoring
               WHERE table_name = %s
               AND processed = 'N'
               LIMIT 10000""",
            (staging_table,),
        )
        ls_to_process = cur.fetchall()

    ls_to_process.sort(key=lambda i: i[1])
    print(f'Processing {table_name} data...')

    for datim_id, batch_id, file_name in ls_to_process:
        df = pd.read_sql(
            f"""SELECT * FROM {staging_table}
               WHERE stg_datim_id = %s
               AND stg_batch_id = %s
               AND stg_file_name = %s""",
            con=staging_conn,
            params=(datim_id, batch_id, file_name),
        )
        df = df.drop(['stg_batch_id', 'stg_load_time', 'stg_file_name'], axis=1)
        df = df.rename(columns={'stg_datim_id': 'ods_datim_id'})
        df['ods_load_time'] = load_time

        ls_cons = constraints.replace(' ', '').split(',')
        df = df.drop_duplicates(subset=ls_cons)

        print(f'Loading staging data for {datim_id}: {batch_id}: {file_name}...')

        if not df.empty:
            print(f'Transforming data for {datim_id}: {batch_id}: {file_name}...')
            try:
                df_transformed = transform_ods_df(df, table_name, dtype=dtype)
                print(f'Storing stg data on {staging_table} for {datim_id}: {file_name}...')
                store_ods_df(dwh_conn, df_transformed, table_name, constraints, dtype=dtype)
                print(f'Successfully stored ods data for {datim_id}: {batch_id}: {file_name}...')

                with staging_conn.cursor() as cur:
                    cur.execute(
                        """UPDATE stg_monitoring
                           SET processed='Y', stg_deleted='N', error_message='No errors'
                           WHERE table_name = %s AND datim_id = %s
                           AND batch_id = %s AND file_name = %s""",
                        (staging_table, datim_id, batch_id, file_name),
                    )
                    staging_conn.commit()
                print(f'Updated stg_monitoring table for {staging_table} for successfully data migration')

            except Exception as e:
                error_message = str(e)
                with staging_conn.cursor() as cur:
                    cur.execute(
                        """UPDATE stg_monitoring
                           SET processed='F', stg_deleted='N', error_message=%s
                           WHERE table_name = %s AND datim_id = %s
                           AND batch_id = %s AND file_name = %s""",
                        (error_message, staging_table, datim_id, batch_id, file_name),
                    )
                    staging_conn.commit()
                print(f'Updated stg_monitoring table for {staging_table} for failed data migration')

        else:
            print(f'Empty df after dedup for {datim_id}: {batch_id}: {file_name}. Marking as processed.')
            with staging_conn.cursor() as cur:
                cur.execute(
                    """UPDATE stg_monitoring
                       SET processed='Y', stg_deleted='N', error_message='No errors'
                       WHERE table_name = %s AND datim_id = %s
                       AND batch_id = %s AND file_name = %s""",
                    (staging_table, datim_id, batch_id, file_name),
                )
                staging_conn.commit()
            print(f'Updated stg_monitoring table for {staging_table} for successfully data migration')


# ---------------------------------------------------------------------------
# Per-table process functions
# All accept (staging_conn, dwh_conn) and forward them to process_stg_to_ods.
# No module-level connection state.
# ---------------------------------------------------------------------------

def process_patient_person():
    with get_connections() as (staging_conn, dwh_conn):
        dtype = {
            'contact_point': JSON().with_variant(JSONB, 'postgresql'),
            'address': JSON().with_variant(JSONB, 'postgresql'),
            'gender': JSON().with_variant(JSONB, 'postgresql'),
            'identifier': JSON().with_variant(JSONB, 'postgresql'),
            'marital_status': JSON().with_variant(JSONB, 'postgresql'),
            'employment_status': JSON().with_variant(JSONB, 'postgresql'),
            'organization': JSON().with_variant(JSONB, 'postgresql'),
            'contact': JSON().with_variant(JSONB, 'postgresql'),
            'education': JSON().with_variant(JSONB, 'postgresql'),
        }
        process_stg_to_ods(staging_conn, dwh_conn, 'patient_person', 'ods_datim_id,uuid', dtype=dtype)

def process_case_manager():
    with get_connections() as (staging_conn, dwh_conn):
        process_stg_to_ods(staging_conn, dwh_conn, 'case_manager', 'ods_datim_id, uuid')

def process_case_manager_patients():
    with get_connections() as (staging_conn, dwh_conn):
        process_stg_to_ods(staging_conn, dwh_conn, 'case_manager_patients', 'ods_datim_id, id')

def process_patient_visit():
    with get_connections() as (staging_conn, dwh_conn):
        process_stg_to_ods(staging_conn, dwh_conn, 'patient_visit', 'ods_datim_id, id')

def process_hiv_regimen_resolver():
    with get_connections() as (staging_conn, dwh_conn):
        process_stg_to_ods(staging_conn, dwh_conn, 'hiv_regimen_resolver', 'ods_datim_id,regimensys, regimen')

def process_base_application_codeset():
    with get_connections() as (staging_conn, dwh_conn):
        process_stg_to_ods(staging_conn, dwh_conn, 'base_application_codeset', 'ods_datim_id, code')

def process_hiv_art_clinical():
    with get_connections() as (staging_conn, dwh_conn):
        dtype = {
            'adverse_drug_reactions': JSON().with_variant(JSONB, 'postgresql'),
            'adheres': JSON().with_variant(JSONB, 'postgresql'),
            'tb_screen': JSON().with_variant(JSONB, 'postgresql'),
            'opportunistic_infections': JSON().with_variant(JSONB, 'postgresql'),
            'arvdrugs_regimen': JSON().with_variant(JSONB, 'postgresql'),
            'viral_load_order': JSON().with_variant(JSONB, 'postgresql'),
            'extra': JSON().with_variant(JSONB, 'postgresql'),
        }
        process_stg_to_ods(staging_conn, dwh_conn, 'hiv_art_clinical', 'uuid, person_uuid, ods_datim_id', dtype=dtype)

def process_hiv_enrollment():
    with get_connections() as (staging_conn, dwh_conn):
        process_stg_to_ods(staging_conn, dwh_conn, 'hiv_enrollment', 'uuid, person_uuid, ods_datim_id')

def process_hiv_observation():
    with get_connections() as (staging_conn, dwh_conn):
        dtype = {'data': JSON().with_variant(JSONB, 'postgresql')}
        process_stg_to_ods(staging_conn, dwh_conn, 'hiv_observation', 'uuid, person_uuid, ods_datim_id', dtype=dtype)

def process_hiv_status_tracker():
    with get_connections() as (staging_conn, dwh_conn):
        process_stg_to_ods(staging_conn, dwh_conn, 'hiv_status_tracker', 'ods_datim_id, uuid')

def process_hiv_patient_tracker():
    with get_connections() as (staging_conn, dwh_conn):
        process_stg_to_ods(staging_conn, dwh_conn, 'hiv_patient_tracker', 'uuid, person_uuid, ods_datim_id')

def process_hts_index_elicitation():
    with get_connections() as (staging_conn, dwh_conn):
        dtype = {'extra': JSON().with_variant(JSONB, 'postgresql')}
        process_stg_to_ods(staging_conn, dwh_conn, 'hts_index_elicitation', 'ods_datim_id, id', dtype=dtype)

def process_hts_risk_stratification():
    with get_connections() as (staging_conn, dwh_conn):
        dtype = {'risk_assessment': JSON().with_variant(JSONB, 'postgresql')}
        process_stg_to_ods(staging_conn, dwh_conn, 'hts_risk_stratification', 'ods_datim_id, code', dtype=dtype)

def process_hts_family_index():
    with get_connections() as (staging_conn, dwh_conn):
        process_stg_to_ods(staging_conn, dwh_conn, 'hts_family_index', 'ods_datim_id, uuid')

def process_hts_family_index_testing():
    with get_connections() as (staging_conn, dwh_conn):
        dtype = {'extra': JSON().with_variant(JSONB, 'postgresql')}
        process_stg_to_ods(staging_conn, dwh_conn, 'hts_family_index_testing', 'ods_datim_id, uuid', dtype=dtype)

def process_hts_pns_index_client_partner():
    with get_connections() as (staging_conn, dwh_conn):
        dtype = {
            'intermediate_partner_violence': JSON().with_variant(JSONB, 'postgresql'),
            'hts_client_information': JSON().with_variant(JSONB, 'postgresql'),
            'contact_tracing': JSON().with_variant(JSONB, 'postgresql'),
        }
        process_stg_to_ods(staging_conn, dwh_conn, 'hts_pns_index_client_partner', 'ods_datim_id, uuid', dtype=dtype)

def process_patient_encounter():
    with get_connections() as (staging_conn, dwh_conn):
        process_stg_to_ods(staging_conn, dwh_conn, 'patient_encounter', 'ods_datim_id, uuid')

def process_prep_clinic():
    with get_connections() as (staging_conn, dwh_conn):
        dtype = {
            'hepatitis': JSON().with_variant(JSONB, 'postgresql'),
            'syphilis': JSON().with_variant(JSONB, 'postgresql'),
            'syndromic_sti_screening': JSON().with_variant(JSONB, 'postgresql'),
            'other_tests_done': JSON().with_variant(JSONB, 'postgresql'),
            'extra': JSON().with_variant(JSONB, 'postgresql'),
            'urinalysis': JSON().with_variant(JSONB, 'postgresql'),
        }
        process_stg_to_ods(staging_conn, dwh_conn, 'prep_clinic', 'uuid, person_uuid, ods_datim_id', dtype=dtype)

def process_prep_regimen():
    with get_connections() as (staging_conn, dwh_conn):
        process_stg_to_ods(staging_conn, dwh_conn, 'prep_regimen', 'ods_datim_id, id')

def process_prep_enrollment():
    with get_connections() as (staging_conn, dwh_conn):
        dtype = {'extra': JSON().with_variant(JSONB, 'postgresql')}
        process_stg_to_ods(staging_conn, dwh_conn, 'prep_enrollment', 'ods_datim_id, uuid', dtype=dtype)

def process_prep_interruption():
    with get_connections() as (staging_conn, dwh_conn):
        dtype = {'extra': JSON().with_variant(JSONB, 'postgresql')}
        process_stg_to_ods(staging_conn, dwh_conn, 'prep_interruption', 'ods_datim_id, uuid', dtype=dtype)

def process_prep_eligibility():
    with get_connections() as (staging_conn, dwh_conn):
        dtype = {
            'extra': JSON().with_variant(JSONB, 'postgresql'),
            'hiv_risk': JSON().with_variant(JSONB, 'postgresql'),
            'sti_screening': JSON().with_variant(JSONB, 'postgresql'),
            'drug_use_history': JSON().with_variant(JSONB, 'postgresql'),
            'personal_hiv_risk_assessment': JSON().with_variant(JSONB, 'postgresql'),
            'sex_partner_risk': JSON().with_variant(JSONB, 'postgresql'),
            'services_received_by_client': JSON().with_variant(JSONB, 'postgresql'),
            'assessment_for_pep_indication': JSON().with_variant(JSONB, 'postgresql'),
            'assessment_for_prep_eligibility': JSON().with_variant(JSONB, 'postgresql'),
            'assessment_for_acute_hiv_infection': JSON().with_variant(JSONB, 'postgresql'),
        }
        process_stg_to_ods(staging_conn, dwh_conn, 'prep_eligibility', 'ods_datim_id, uuid', dtype=dtype)

def process_triage_vital_sign():
    with get_connections() as (staging_conn, dwh_conn):
        process_stg_to_ods(staging_conn, dwh_conn, 'triage_vital_sign', 'ods_datim_id, uuid')

def process_hts_client():
    with get_connections() as (staging_conn, dwh_conn):
        dtype = {
            'extra': JSON().with_variant(JSONB, 'postgresql'),
            'test1': JSON().with_variant(JSONB, 'postgresql'),
            'test2': JSON().with_variant(JSONB, 'postgresql'),
            'confirmatory_test': JSON().with_variant(JSONB, 'postgresql'),
            'confirmatory_test2': JSON().with_variant(JSONB, 'postgresql'),
            'tie_breaker_test': JSON().with_variant(JSONB, 'postgresql'),
            'tie_breaker_test2': JSON().with_variant(JSONB, 'postgresql'),
            'knowledge_assessment': JSON().with_variant(JSONB, 'postgresql'),
            'risk_assessment': JSON().with_variant(JSONB, 'postgresql'),
            'tb_screening': JSON().with_variant(JSONB, 'postgresql'),
            'sti_screening': JSON().with_variant(JSONB, 'postgresql'),
            'hepatitis_testing': JSON().with_variant(JSONB, 'postgresql'),
            'recency': JSON().with_variant(JSONB, 'postgresql'),
            'syphilis_testing': JSON().with_variant(JSONB, 'postgresql'),
            'index_notification_services_elicitation': JSON().with_variant(JSONB, 'postgresql'),
            'post_test_counseling': JSON().with_variant(JSONB, 'postgresql'),
            'sex_partner_risk_assessment': JSON().with_variant(JSONB, 'postgresql'),
            'others': JSON().with_variant(JSONB, 'postgresql'),
            'cd4': JSON().with_variant(JSONB, 'postgresql'),
        }
        process_stg_to_ods(staging_conn, dwh_conn, 'hts_client', 'ods_datim_id, uuid', dtype=dtype)

def process_base_organisation_unit():
    with get_connections() as (staging_conn, dwh_conn):
        dtype = {'details': JSON().with_variant(JSONB, 'postgresql')}
        process_stg_to_ods(staging_conn, dwh_conn, 'base_organisation_unit', 'ods_datim_id, id', dtype=dtype)

def process_base_organisation_unit_identifier():
    with get_connections() as (staging_conn, dwh_conn):
        process_stg_to_ods(staging_conn, dwh_conn, 'base_organisation_unit_identifier', 'ods_datim_id, id')

def process_hiv_regimen():
    with get_connections() as (staging_conn, dwh_conn):
        process_stg_to_ods(staging_conn, dwh_conn, 'hiv_regimen', 'ods_datim_id, id')

def process_hiv_regimen_type():
    with get_connections() as (staging_conn, dwh_conn):
        process_stg_to_ods(staging_conn, dwh_conn, 'hiv_regimen_type', 'ods_datim_id, id')

def process_laboratory_sample():
    with get_connections() as (staging_conn, dwh_conn):
        process_stg_to_ods(staging_conn, dwh_conn, 'laboratory_sample', 'id, uuid, patient_uuid, ods_datim_id')

def process_laboratory_sample_type():
    with get_connections() as (staging_conn, dwh_conn):
        process_stg_to_ods(staging_conn, dwh_conn, 'laboratory_sample_type', 'uuid, ods_datim_id')

def process_laboratory_test():
    with get_connections() as (staging_conn, dwh_conn):
        process_stg_to_ods(staging_conn, dwh_conn, 'laboratory_test', 'id, uuid, patient_uuid, ods_datim_id')

def process_laboratory_result():
    with get_connections() as (staging_conn, dwh_conn):
        process_stg_to_ods(staging_conn, dwh_conn, 'laboratory_result', 'id, uuid, patient_uuid, ods_datim_id')

def process_hiv_art_pharmacy():
    with get_connections() as (staging_conn, dwh_conn):
        dtype = {
            'extra': JSON().with_variant(JSONB, 'postgresql'),
            'adverse_drug_reactions': JSON().with_variant(JSONB, 'postgresql'),
            'ipt': JSON().with_variant(JSONB, 'postgresql'),
        }
        process_stg_to_ods(staging_conn, dwh_conn, 'hiv_art_pharmacy', 'ods_datim_id, uuid', dtype=dtype)

def process_laboratory_labtest():
    with get_connections() as (staging_conn, dwh_conn):
        process_stg_to_ods(staging_conn, dwh_conn, 'laboratory_labtest', 'ods_datim_id, id')

def process_laboratory_labtestgroup():
    with get_connections() as (staging_conn, dwh_conn):
        process_stg_to_ods(staging_conn, dwh_conn, 'laboratory_labtestgroup', 'id, uuid, group_name, ods_datim_id')

def process_hiv_art_pharmacy_regimens():
    with get_connections() as (staging_conn, dwh_conn):
        process_stg_to_ods(staging_conn, dwh_conn, 'hiv_art_pharmacy_regimens', 'art_pharmacy_id, regimens_id, ods_datim_id')

def process_hiv_regimen_drug():
    with get_connections() as (staging_conn, dwh_conn):
        process_stg_to_ods(staging_conn, dwh_conn, 'hiv_regimen_drug', 'regimen_id, drug_id, ods_datim_id')

def process_hiv_eac_session():
    with get_connections() as (staging_conn, dwh_conn):
        dtype = {
            'barriers': JSON().with_variant(JSONB, 'postgresql'),
            'intervention': JSON().with_variant(JSONB, 'postgresql'),
        }
        process_stg_to_ods(staging_conn, dwh_conn, 'hiv_eac_session', 'ods_datim_id, uuid', dtype=dtype)

def process_biometric():
    with get_connections() as (staging_conn, dwh_conn):
        dtype = {'extra': JSON().with_variant(JSONB, 'postgresql')}
        process_stg_to_ods(staging_conn, dwh_conn, 'biometric', 'ods_datim_id, id', dtype=dtype)

def process_hiv_eac():
    with get_connections() as (staging_conn, dwh_conn):
        process_stg_to_ods(staging_conn, dwh_conn, 'hiv_eac', 'ods_datim_id, uuid')

def process_hiv_eac_out_come():
    with get_connections() as (staging_conn, dwh_conn):
        process_stg_to_ods(staging_conn, dwh_conn, 'hiv_eac_out_come', 'ods_datim_id, uuid')

def process_dsd_devolvement():
    with get_connections() as (staging_conn, dwh_conn):
        process_stg_to_ods(staging_conn, dwh_conn, 'dsd_devolvement', 'ods_datim_id, person_uuid, uuid')

def process_laboratory_order():
    with get_connections() as (staging_conn, dwh_conn):
        process_stg_to_ods(staging_conn, dwh_conn, 'laboratory_order', 'ods_datim_id, uuid, patient_id')

def process_pmtct_anc():
    with get_connections() as (staging_conn, dwh_conn):
        dtype = {
            'pmtct_hts_info': JSON().with_variant(JSONB, 'postgresql'),
            'partner_notification': JSON().with_variant(JSONB, 'postgresql'),
            'partner_information': JSON().with_variant(JSONB, 'postgresql'),
        }
        process_stg_to_ods(staging_conn, dwh_conn, 'pmtct_anc', 'ods_datim_id, person_uuid, id', dtype=dtype)

def process_pmtct_delivery():
    with get_connections() as (staging_conn, dwh_conn):
        process_stg_to_ods(staging_conn, dwh_conn, 'pmtct_delivery', 'id, uuid, person_uuid, ods_datim_id')

def process_pmtct_enrollment():
    with get_connections() as (staging_conn, dwh_conn):
        process_stg_to_ods(staging_conn, dwh_conn, 'pmtct_enrollment', 'id, uuid, person_uuid, ods_datim_id')

def process_pmtct_infant_arv():
    with get_connections() as (staging_conn, dwh_conn):
        process_stg_to_ods(staging_conn, dwh_conn, 'pmtct_infant_arv', 'id, ods_datim_id')

def process_pmtct_infant_pcr():
    with get_connections() as (staging_conn, dwh_conn):
        process_stg_to_ods(staging_conn, dwh_conn, 'pmtct_infant_pcr', 'id, ods_datim_id')

def process_pmtct_infant_visit():
    with get_connections() as (staging_conn, dwh_conn):
        process_stg_to_ods(staging_conn, dwh_conn, 'pmtct_infant_visit', 'id, uuid, ods_datim_id')

def process_pmtct_mother_visitation():
    with get_connections() as (staging_conn, dwh_conn):
        process_stg_to_ods(staging_conn, dwh_conn, 'pmtct_mother_visitation', 'id, person_uuid, uuid, ods_datim_id')

def process_pmtct_infant_information():
    with get_connections() as (staging_conn, dwh_conn):
        process_stg_to_ods(staging_conn, dwh_conn, 'pmtct_infant_information', 'id, uuid, mother_person_uuid, ods_datim_id')

def process_pmtct_infant_mother_art():
    with get_connections() as (staging_conn, dwh_conn):
        process_stg_to_ods(staging_conn, dwh_conn, 'pmtct_infant_mother_art', 'id, uuid, ods_datim_id')

def process_pmtct_infant_rapid_antibody():
    with get_connections() as (staging_conn, dwh_conn):
        process_stg_to_ods(staging_conn, dwh_conn, 'pmtct_infant_rapid_antibody', 'id, uuid, ods_datim_id,unique_uuid')

def process_sync_table_count():
    with get_connections() as (staging_conn, dwh_conn):
        process_stg_to_ods(staging_conn, dwh_conn, 'sync_table_count', 'id, facility_id, ods_datim_id')

def process_hts_family_index_testing_tracker():
    with get_connections() as (staging_conn, dwh_conn):
        process_stg_to_ods(staging_conn, dwh_conn, 'hts_family_index_testing_tracker', 'uuid, ods_datim_id')

def process_hts_client_referral():
    with get_connections() as (staging_conn, dwh_conn):
        dtype = {
            'receiving_organization': JSON().with_variant(JSONB, 'postgresql'),
            'service_needed': JSON().with_variant(JSONB, 'postgresql'),
        }
        process_stg_to_ods(staging_conn, dwh_conn, 'hts_client_referral', 'uuid, ods_datim_id', dtype=dtype)

def process_hivst():
    with get_connections() as (staging_conn, dwh_conn):
        dtype = {
            'other_test_kit_user_details': JSON().with_variant(JSONB, 'postgresql'),
            'part_b': JSON().with_variant(JSONB, 'postgresql'),
            'referral_information': JSON().with_variant(JSONB, 'postgresql'),
            'test_kit_users': JSON().with_variant(JSONB, 'postgresql'),
        }
        process_stg_to_ods(staging_conn, dwh_conn, 'hivst', 'id, ods_datim_id', dtype=dtype)

def process_mhpss_screening():
    with get_connections() as (staging_conn, dwh_conn):
        process_stg_to_ods(staging_conn, dwh_conn, 'mhpss_screening', 'ods_datim_id, person_uuid, id')

def process_pmtct_hts():
    with get_connections() as (staging_conn, dwh_conn):
        process_stg_to_ods(staging_conn, dwh_conn, 'pmtct_hts', 'id, uuid, ods_datim_id')

def process_pmtct_pregnancy_cycle():
    with get_connections() as (staging_conn, dwh_conn):
        process_stg_to_ods(staging_conn, dwh_conn, 'pmtct_pregnancy_cycle', 'id, uuid, person_uuid, ods_datim_id')


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
    process_pmtct_hts()
    process_pmtct_pregnancy_cycle()
