from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from airflow.providers.postgres.operators.postgres import PostgresOperator
import datetime
from datetime import datetime, timedelta
from airflow.utils.task_group import TaskGroup
import sys
import os
from lamisplus_funcs import ods_to_ods as lamisplus_funcs
from lamisplus_funcs.airflow_api import trigger_dag
# sys.path.append('/home/lamisplus/airflow/lamisplus_funcs')

def trigger_dag_function(**kwargs):
    trigger_dag(dag_id='lamisplus_upsert_streaming_for_datamart_server')  

default_args = {
    "owner": "airflow",
    "email_on_failure": False,
    "email_on_retry": False,
    "email": "admin@localhost.com",
    "retries": 3,
    "retry_delay": timedelta(minutes=5)
}


with DAG("lamis_delete_archived_records", start_date=datetime(2024, 1, 26), 
         schedule_interval=timedelta(hours=1), default_args=default_args, 
         catchup=False, max_active_runs=1) as dag:

    start = BashOperator(
        task_id="start",
        bash_command="echo start"
    )
    
    with TaskGroup(group_id='delete_archived_records') as delete_archived_records:
        
        ods_base_application_codeset = PostgresOperator(
            task_id="base_application_codeset",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_delete_archived_records('ods_base_application_codeset')",
            autocommit=True)
        
        ods_base_organisation_unit_identifier = PostgresOperator(
            task_id="base_organisation_unit_identifier",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_delete_archived_records('ods_base_organisation_unit_identifier')",
            autocommit=True)
            
        ods_base_organisation_unit = PostgresOperator(
            task_id="base_organisation_unit",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_delete_archived_records('ods_base_organisation_unit')",
            autocommit=True)
            
        ods_case_manager = PostgresOperator(
            task_id="ods_case_manager",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_delete_archived_records('ods_case_manager')",
            autocommit=True)
        
        ods_dsd_devolvement = PostgresOperator(
            task_id="ods_dsd_devolvement",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_delete_archived_records('ods_dsd_devolvement')",
            autocommit=True)
            
        ods_case_manager_patients = PostgresOperator(
            task_id="ods_case_manager_patients",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_delete_archived_records('ods_case_manager_patients')",
            autocommit=True)
            
        ods_hiv_eac = PostgresOperator(
            task_id="ods_hiv_eac",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_delete_archived_records('ods_hiv_eac')",
            autocommit=True)
        
        ods_hiv_eac_out_come = PostgresOperator(
            task_id="ods_hiv_eac_out_come",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_delete_archived_records('ods_hiv_eac_out_come')",
            autocommit=True)
            
        ods_hiv_eac_session = PostgresOperator(
            task_id="ods_hiv_eac_session",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_delete_archived_records('ods_hiv_eac_session')",
            autocommit=True)
        
        ods_hiv_regimen = PostgresOperator(
            task_id="ods_hiv_regimen",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_delete_archived_records('ods_hiv_regimen')",
            autocommit=True)
        
        ods_hiv_regimen_resolver = PostgresOperator(
            task_id="ods_hiv_regimen_resolver",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_delete_archived_records('ods_hiv_regimen_resolver')",
            autocommit=True)
            
        ods_hiv_regimen_type = PostgresOperator(
            task_id="ods_hiv_regimen_type",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_delete_archived_records('ods_hiv_regimen_type')",
            autocommit=True)
        
        ods_hts_index_elicitation = PostgresOperator(
            task_id="ods_hts_index_elicitation",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_delete_archived_records('ods_hts_index_elicitation')",
            autocommit=True)
        
        ods_hts_risk_stratification = PostgresOperator(
            task_id="ods_hts_risk_stratification",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_delete_archived_records('ods_hts_risk_stratification')",
            autocommit=True)
            
        ods_laboratory_order = PostgresOperator(
            task_id="ods_laboratory_order",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_delete_archived_records('ods_laboratory_order')",
            autocommit=True)
        
        ods_patient_encounter = PostgresOperator(
            task_id="ods_patient_encounter",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_delete_archived_records('ods_patient_encounter')",
            autocommit=True)
        
        ods_pmtct_anc = PostgresOperator(
            task_id="ods_pmtct_anc",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_delete_archived_records('ods_pmtct_anc')",
            autocommit=True)
            
        ods_pmtct_delivery = PostgresOperator(
            task_id="ods_pmtct_delivery",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_delete_archived_records('ods_pmtct_delivery')",
            autocommit=True)
        
        ods_pmtct_enrollment = PostgresOperator(
            task_id="ods_pmtct_enrollment",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_delete_archived_records('ods_pmtct_enrollment')",
            autocommit=True)
        
        ods_pmtct_infant_arv = PostgresOperator(
            task_id="ods_pmtct_infant_arv",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_delete_archived_records('ods_pmtct_infant_arv')",
            autocommit=True)
            
        ods_pmtct_infant_information = PostgresOperator(
            task_id="ods_pmtct_infant_information",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_delete_archived_records('ods_pmtct_infant_information')",
            autocommit=True)
            
        ods_pmtct_infant_mother_art = PostgresOperator(
            task_id="ods_pmtct_infant_mother_art",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_delete_archived_records('ods_pmtct_infant_mother_art')",
            autocommit=True)
        
        ods_pmtct_infant_pcr = PostgresOperator(
            task_id="ods_pmtct_infant_pcr",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_delete_archived_records('ods_pmtct_infant_pcr')",
            autocommit=True)
            
        ods_pmtct_infant_rapid_antibody = PostgresOperator(
            task_id="ods_pmtct_infant_rapid_antibody",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_delete_archived_records('ods_pmtct_infant_rapid_antibody')",
            autocommit=True)
        
        ods_pmtct_infant_visit = PostgresOperator(
            task_id="ods_pmtct_infant_visit",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_delete_archived_records('ods_pmtct_infant_visit')",
            autocommit=True)
        
        ods_pmtct_mother_visitation = PostgresOperator(
            task_id="ods_pmtct_mother_visitation",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_delete_archived_records('ods_pmtct_mother_visitation')",
            autocommit=True)
            
        ods_prep_clinic = PostgresOperator(
            task_id="ods_prep_clinic",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_delete_archived_records('ods_prep_clinic')",
            autocommit=True)
        
        ods_prep_eligibility = PostgresOperator(
            task_id="ods_prep_eligibility",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_delete_archived_records('ods_prep_eligibility')",
            autocommit=True)
        
        ods_prep_enrollment = PostgresOperator(
            task_id="ods_prep_enrollment",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_delete_archived_records('ods_prep_enrollment')",
            autocommit=True)
            
        ods_prep_interruption = PostgresOperator(
            task_id="ods_prep_interruption",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_delete_archived_records('ods_prep_interruption')",
            autocommit=True)
        
        ods_prep_regimen = PostgresOperator(
            task_id="ods_prep_regimen",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_delete_archived_records('ods_prep_regimen')",
            autocommit=True)
        
        ods_hiv_observation = PostgresOperator(
            task_id="ods_hiv_observation",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_delete_archived_records('ods_hiv_observation')",
            autocommit=True)
        
        ods_hts_client = PostgresOperator(
            task_id="ods_hts_client",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_delete_archived_records('ods_hts_client')",
            autocommit=True)
            
        ods_laboratory_labtest = PostgresOperator(
            task_id="ods_laboratory_labtest",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_delete_archived_records('ods_laboratory_labtest')",
            autocommit=True)
            
        ods_patient_visit = PostgresOperator(
            task_id="ods_patient_visit",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_delete_archived_records('ods_patient_visit')",
            autocommit=True)
        
        ods_hiv_art_pharmacy_regimens = PostgresOperator(
            task_id="ods_hiv_art_pharmacy_regimens",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_delete_archived_records('ods_hiv_art_pharmacy_regimens')",
            autocommit=True)
        
        ods_hiv_art_clinical = PostgresOperator(
            task_id="ods_hiv_art_clinical",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_delete_archived_records('ods_hiv_art_clinical')",
            autocommit=True)
            
        ods_hiv_art_pharmacy = PostgresOperator(
            task_id="ods_hiv_art_pharmacy",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_delete_archived_records('ods_hiv_art_pharmacy')",
            autocommit=True)
            
        ods_hiv_enrollment = PostgresOperator(
            task_id="ods_hiv_enrollment",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_delete_archived_records('ods_hiv_enrollment')",
            autocommit=True)
            
        ods_hiv_status_tracker = PostgresOperator(
            task_id="ods_hiv_status_tracker",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_delete_archived_records('ods_hiv_status_tracker')",
            autocommit=True)
        
        ods_patient_person = PostgresOperator(
            task_id="ods_patient_person",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_delete_archived_records('ods_patient_person')",
            autocommit=True)
            
        ods_triage_vital_sign = PostgresOperator(
            task_id="ods_triage_vital_sign",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_delete_archived_records('ods_triage_vital_sign')",
            autocommit=True)
            
        ods_laboratory_test = PostgresOperator(
            task_id="ods_laboratory_test",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_delete_archived_records('ods_laboratory_test')",
            autocommit=True)
        
        ods_laboratory_sample = PostgresOperator(
            task_id="ods_laboratory_sample",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_delete_archived_records('ods_laboratory_sample')",
            autocommit=True)
            
        ods_laboratory_result = PostgresOperator(
            task_id="ods_laboratory_result",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_delete_archived_records('ods_laboratory_result')",
            autocommit=True)
        
        ods_deduplication = PostgresOperator(
            task_id="ods_deduplication",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_delete_archived_records('ods_deduplication')",
            autocommit=True)
        
        ods_hiv_regimen_drug = PostgresOperator(
            task_id="ods_hiv_regimen_drug",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_delete_archived_records('ods_hiv_regimen_drug')",
            autocommit=True)
            
        ods_laboratory_number = PostgresOperator(
            task_id="ods_laboratory_number",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_delete_archived_records('ods_laboratory_number')",
            autocommit=True)
        
        ods_biometric = PostgresOperator(
            task_id="ods_biometric",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_delete_archived_records('ods_biometric')",
            autocommit=True)
    
    encrypt_hts_tables = PostgresOperator(
        task_id="encrypt_hts_tables",
        postgres_conn_id="lamisplus_conn",
        sql='call public.proc_encrypt_hts_tables()',
        autocommit=True)
    
    upsert_hts_client = PostgresOperator(
        task_id="upsert_hts_client",
        postgres_conn_id="hts_prep_conn",
        sql='call expanded_hts_prep.proc_upsert_hts_client()',
        autocommit=True)
    
    end = BashOperator(
        task_id="end",
        bash_command="echo end")
    
    trigger_refresh_streaming_dag = PythonOperator(
        task_id='trigger_refresh_streaming_dag',
        python_callable=trigger_dag_function,
        provide_context=True,)

    # Define the task dependencies
    start >> delete_archived_records >> encrypt_hts_tables >> upsert_hts_client_refresh >> end >> trigger_refresh_streaming_dag
