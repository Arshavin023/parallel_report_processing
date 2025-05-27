from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from airflow.providers.postgres.operators.postgres import PostgresOperator
import datetime
from datetime import datetime, timedelta
from airflow.utils.task_group import TaskGroup
import sys
import os
from lamisplus_funcs import stg_to_ods as lamisplus_funcs
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


with DAG("lamis_ods_to_ods_v2", start_date=datetime(2024, 1, 26), 
         schedule_interval=timedelta(hours=1), default_args=default_args, 
         catchup=False, max_active_runs=1) as dag:

    start = BashOperator(
        task_id="start",
        bash_command="echo start"
    ) 
    
    with TaskGroup(group_id='migrate_and_persist_ods_data') as migrate_and_persist_ods_data:
        case_manager = PythonOperator(
        task_id="case_manager",
        python_callable=lamisplus_funcs.process_case_manager)
        
        case_manager_patients = PythonOperator(
        task_id="case_manager_patients",
        python_callable=lamisplus_funcs.process_case_manager_patients)
        
        patient_visit = PythonOperator(
        task_id="patient_visit",
        python_callable=lamisplus_funcs.process_patient_visit)
        
        hiv_regimen_resolver = PythonOperator(
        task_id="hiv_regimen_resolver",
        python_callable=lamisplus_funcs.process_hiv_regimen_resolver)
        
        base_application_codeset = PythonOperator(
        task_id="base_application_codeset",
        python_callable=lamisplus_funcs.process_base_application_codeset)
        
        hiv_art_clinical = PythonOperator(
        task_id="hiv_art_clinical",
        python_callable=lamisplus_funcs.process_hiv_art_clinical)
        
        hiv_enrollment = PythonOperator(
        task_id="hiv_enrollment",
        python_callable=lamisplus_funcs.process_hiv_enrollment)
        
        hiv_observation = PythonOperator(
        task_id="hiv_observation",
        python_callable=lamisplus_funcs.process_hiv_observation)
        
        hiv_status_tracker = PythonOperator(
        task_id="hiv_status_tracker",
        python_callable=lamisplus_funcs.process_hiv_status_tracker)
        
        hts_index_elicitation = PythonOperator(
        task_id="hts_index_elicitation",
        python_callable=lamisplus_funcs.process_hts_index_elicitation)
        
        hts_risk_stratification = PythonOperator(
        task_id="hts_risk_stratification",
        python_callable=lamisplus_funcs.process_hts_risk_stratification)
        
        hts_family_index_testing = PythonOperator(
        task_id="hts_family_index_testing",
        python_callable=lamisplus_funcs.process_hts_family_index_testing)
        
        hts_family_index = PythonOperator(
        task_id="hts_family_index",
        python_callable=lamisplus_funcs.process_hts_family_index)
        
        hts_pns_index_client_partner = PythonOperator(
        task_id="hts_pns_index_client_partner",
        python_callable=lamisplus_funcs.process_hts_pns_index_client_partner)
        
        patient_encounter = PythonOperator(
        task_id="patient_encounter",
        python_callable=lamisplus_funcs.process_patient_encounter)
        
        prep_enrollment = PythonOperator(
        task_id="prep_enrollment",
        python_callable=lamisplus_funcs.process_prep_enrollment)
        
        prep_interruption = PythonOperator(
        task_id="prep_interruption",
        python_callable=lamisplus_funcs.process_prep_interruption)

        triage_vital_sign = PythonOperator(
        task_id="triage_vital_sign",
        python_callable=lamisplus_funcs.process_triage_vital_sign)

        hts_client = PythonOperator(
            task_id="hts_client",
            python_callable=lamisplus_funcs.process_hts_client)

        base_organisation_unit = PythonOperator(
            task_id="base_organisation_unit",
            python_callable=lamisplus_funcs.process_base_organisation_unit)

        base_organisation_unit_identifier = PythonOperator(
            task_id="base_organisation_unit_identifier",
            python_callable=lamisplus_funcs.process_base_organisation_unit_identifier)

        hiv_regimen = PythonOperator(
            task_id="hiv_regimen",
            python_callable=lamisplus_funcs.process_hiv_regimen)

        hiv_regimen_type = PythonOperator(
            task_id="hiv_regimen_type",
            python_callable=lamisplus_funcs.process_hiv_regimen_type)

        laboratory_sample = PythonOperator(
            task_id="laboratory_sample",
            python_callable=lamisplus_funcs.process_laboratory_sample)

        laboratory_test = PythonOperator(
            task_id="laboratory_test",
            python_callable=lamisplus_funcs.process_laboratory_test)

        laboratory_result = PythonOperator(
            task_id="laboratory_result",
            python_callable=lamisplus_funcs.process_laboratory_result)

        hiv_art_pharmacy = PythonOperator(
            task_id="hiv_art_pharmacy",
            python_callable=lamisplus_funcs.process_hiv_art_pharmacy)

        laboratory_labtest = PythonOperator(
            task_id="laboratory_labtest",
            python_callable=lamisplus_funcs.process_laboratory_labtest)

        hiv_art_pharmacy_regimens = PythonOperator(
            task_id="hiv_art_pharmacy_regimens",
            python_callable=lamisplus_funcs.process_hiv_art_pharmacy_regimens)

        hiv_eac_session = PythonOperator(
            task_id="hiv_eac_session",
            python_callable=lamisplus_funcs.process_hiv_eac_session)

        hiv_eac = PythonOperator(
            task_id="hiv_eac",
            python_callable=lamisplus_funcs.process_hiv_eac)

        dsd_devolvement = PythonOperator(
            task_id="dsd_devolvement",
            python_callable=lamisplus_funcs.process_dsd_devolvement)

        laboratory_order = PythonOperator(
            task_id="laboratory_order",
            python_callable=lamisplus_funcs.process_laboratory_order)

        pmtct_anc = PythonOperator(
            task_id="pmtct_anc",
            python_callable=lamisplus_funcs.process_pmtct_anc)

        pmtct_delivery = PythonOperator(
            task_id="pmtct_delivery",
            python_callable=lamisplus_funcs.process_pmtct_delivery)

        pmtct_enrollment = PythonOperator(
            task_id="pmtct_enrollment",
            python_callable=lamisplus_funcs.process_pmtct_enrollment)

        pmtct_infant_arv = PythonOperator(
            task_id="pmtct_infant_arv",
            python_callable=lamisplus_funcs.process_pmtct_infant_arv)

        pmtct_infant_pcr = PythonOperator(
            task_id="pmtct_infant_pcr",
            python_callable=lamisplus_funcs.process_pmtct_infant_pcr)

        pmtct_infant_visit = PythonOperator(
            task_id="pmtct_infant_visit",
            python_callable=lamisplus_funcs.process_pmtct_infant_visit)

        pmtct_mother_visitation = PythonOperator(
            task_id="pmtct_mother_visitation",
            python_callable=lamisplus_funcs.process_pmtct_mother_visitation)

        pmtct_infant_information = PythonOperator(
            task_id="pmtct_infant_information",
            python_callable=lamisplus_funcs.process_pmtct_infant_information)

        pmtct_infant_mother_art = PythonOperator(
            task_id="pmtct_infant_mother_art",
            python_callable=lamisplus_funcs.process_pmtct_infant_mother_art)

        pmtct_infant_rapid_antibody = PythonOperator(
            task_id="pmtct_infant_rapid_antibody",
            python_callable=lamisplus_funcs.process_pmtct_infant_rapid_antibody)

        sync_table_count = PythonOperator(
            task_id="sync_table_count",
            python_callable=lamisplus_funcs.process_sync_table_count)

        hiv_regimen_drug = PythonOperator(
            task_id="hiv_regimen_drug",
            python_callable=lamisplus_funcs.process_hiv_regimen_drug)
    
    end = BashOperator(
        task_id="end",
        bash_command="echo end")

    # Define the task dependencies
    start >> migrate_and_persist_ods_data >> end
