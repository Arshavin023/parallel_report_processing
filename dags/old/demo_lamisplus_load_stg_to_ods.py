from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from airflow.providers.postgres.operators.postgres import PostgresOperator
import datetime
from datetime import datetime, timedelta
from airflow.utils.task_group import TaskGroup
import sys
import os
from lamisplus_funcs import stg_to_ods_demo as lamisplus_funcs
from lamisplus_funcs.airflow_api import trigger_dag
# sys.path.append('/home/lamisplus/airflow/lamisplus_funcs')

default_args = {
    "owner": "airflow",
    "email_on_failure": False,
    "email_on_retry": False,
    "email": "admin@localhost.com",
    "retries": 3,
    "retry_delay": timedelta(minutes=5)
}


with DAG("demo_lamisplus_stg_to_ods", start_date=datetime(2025, 5, 26), 
         schedule_interval=timedelta(hours=1), default_args=default_args, 
         catchup=False, max_active_runs=1) as dag:

    start = BashOperator(
        task_id="start",
        bash_command="echo start"
    ) 
    
    with TaskGroup(group_id='migrate_and_persist_ods_data') as migrate_and_persist_ods_data:
        patient_person = PythonOperator(
        task_id="patient_person",
        python_callable=lamisplus_funcs.process_patient_person)
        
        hiv_eac_out_come = PythonOperator(
        task_id="hiv_eac_out_come",
        python_callable=lamisplus_funcs.process_hiv_eac_out_come)
        
        prep_regimen = PythonOperator(
        task_id="prep_regimen",
        python_callable=lamisplus_funcs.process_prep_regimen)
        
        prep_eligibility = PythonOperator(
        task_id="prep_eligibility",
        python_callable=lamisplus_funcs.process_prep_eligibility)
        
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
        
        hiv_patient_tracker = PythonOperator(
        task_id="hiv_patient_tracker",
        python_callable=lamisplus_funcs.process_hiv_patient_tracker)
        
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
        
        laboratory_sample_type = PythonOperator(
            task_id="laboratory_sample_type",
            python_callable=lamisplus_funcs.process_laboratory_sample_type)
            
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
        
        laboratory_labtestgroup = PythonOperator(
            task_id="laboratory_labtestgroup",
            python_callable=lamisplus_funcs.process_laboratory_labtestgroup)
            
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

        hts_family_index_testing_tracker = PythonOperator(
            task_id="hts_family_index_testing_tracker",
            python_callable=lamisplus_funcs.process_hts_family_index_testing_tracker)
        
        hts_client_referral = PythonOperator(
            task_id="hts_client_referral",
            python_callable=lamisplus_funcs.process_hts_client_referral)

        hivst = PythonOperator(
            task_id="hivst",
            python_callable=lamisplus_funcs.process_hivst)
        
        mhpss_screening = PythonOperator(
            task_id="mhpss_screening",
            python_callable=lamisplus_funcs.process_mhpss_screening)
        
    with TaskGroup(group_id='delete_archived_records') as delete_archived_records:
            
        ods_base_organisation_unit = PostgresOperator(
            task_id="ods_base_organisation_unit",
            postgres_conn_id="demo_lamisplus_conn",
            sql="call public.proc_delete_archived_records_updated('base_organisation_unit')",
            autocommit=True)
            
        ods_case_manager = PostgresOperator(
            task_id="ods_case_manager",
            postgres_conn_id="demo_lamisplus_conn",
            sql="call public.proc_delete_archived_records_updated('case_manager')",
            autocommit=True)
        
        ods_dsd_devolvement = PostgresOperator(
            task_id="ods_dsd_devolvement",
            postgres_conn_id="demo_lamisplus_conn",
            sql="call public.proc_delete_archived_records_updated('dsd_devolvement')",
            autocommit=True)
            
        ods_case_manager_patients = PostgresOperator(
            task_id="ods_case_manager_patients",
            postgres_conn_id="demo_lamisplus_conn",
            sql="call public.proc_delete_archived_records_updated('case_manager_patients')",
            autocommit=True)
            
        ods_hiv_eac = PostgresOperator(
            task_id="ods_hiv_eac",
            postgres_conn_id="demo_lamisplus_conn",
            sql="call public.proc_delete_archived_records_updated('hiv_eac')",
            autocommit=True)
        
        ods_hiv_eac_out_come = PostgresOperator(
            task_id="ods_hiv_eac_out_come",
            postgres_conn_id="demo_lamisplus_conn",
            sql="call public.proc_delete_archived_records_updated('hiv_eac_out_come')",
            autocommit=True)
            
        ods_hiv_eac_session = PostgresOperator(
            task_id="ods_hiv_eac_session",
            postgres_conn_id="demo_lamisplus_conn",
            sql="call public.proc_delete_archived_records_updated('hiv_eac_session')",
            autocommit=True)
        
        ods_hts_index_elicitation = PostgresOperator(
            task_id="ods_hts_index_elicitation",
            postgres_conn_id="demo_lamisplus_conn",
            sql="call public.proc_delete_archived_records_updated('hts_index_elicitation')",
            autocommit=True)
        
        ods_hts_risk_stratification = PostgresOperator(
            task_id="ods_hts_risk_stratification",
            postgres_conn_id="demo_lamisplus_conn",
            sql="call public.proc_delete_archived_records_updated('hts_risk_stratification')",
            autocommit=True)
            
        ods_laboratory_order = PostgresOperator(
            task_id="ods_laboratory_order",
            postgres_conn_id="demo_lamisplus_conn",
            sql="call public.proc_delete_archived_records_updated('laboratory_order')",
            autocommit=True)
        
        ods_patient_encounter = PostgresOperator(
            task_id="ods_patient_encounter",
            postgres_conn_id="demo_lamisplus_conn",
            sql="call public.proc_delete_archived_records_updated('patient_encounter')",
            autocommit=True)
        
        ods_pmtct_anc = PostgresOperator(
            task_id="ods_pmtct_anc",
            postgres_conn_id="demo_lamisplus_conn",
            sql="call public.proc_delete_archived_records_updated('pmtct_anc')",
            autocommit=True)

        ods_pmtct_enrollment = PostgresOperator(
            task_id="ods_pmtct_enrollment",
            postgres_conn_id="demo_lamisplus_conn",
            sql="call public.proc_delete_archived_records_updated('pmtct_enrollment')",
            autocommit=True)

        ods_prep_clinic = PostgresOperator(
            task_id="ods_prep_clinic",
            postgres_conn_id="demo_lamisplus_conn",
            sql="call public.proc_delete_archived_records_updated('prep_clinic')",
            autocommit=True)
        
        ods_prep_eligibility = PostgresOperator(
            task_id="ods_prep_eligibility",
            postgres_conn_id="demo_lamisplus_conn",
            sql="call public.proc_delete_archived_records_updated('prep_eligibility')",
            autocommit=True)
        
        ods_prep_enrollment = PostgresOperator(
            task_id="ods_prep_enrollment",
            postgres_conn_id="demo_lamisplus_conn",
            sql="call public.proc_delete_archived_records_updated('prep_enrollment')",
            autocommit=True)
            
        ods_prep_interruption = PostgresOperator(
            task_id="ods_prep_interruption",
            postgres_conn_id="demo_lamisplus_conn",
            sql="call public.proc_delete_archived_records_updated('prep_interruption')",
            autocommit=True)
        
        ods_prep_regimen = PostgresOperator(
            task_id="ods_prep_regimen",
            postgres_conn_id="demo_lamisplus_conn",
            sql="call public.proc_delete_archived_records_updated('prep_regimen')",
            autocommit=True)
        
        ods_hiv_observation = PostgresOperator(
            task_id="ods_hiv_observation",
            postgres_conn_id="demo_lamisplus_conn",
            sql="call public.proc_delete_archived_records_updated('hiv_observation')",
            autocommit=True)
        
        ods_hts_client = PostgresOperator(
            task_id="ods_hts_client",
            postgres_conn_id="demo_lamisplus_conn",
            sql="call public.proc_delete_archived_records_updated('hts_client')",
            autocommit=True)
            
        ods_laboratory_labtest = PostgresOperator(
            task_id="ods_laboratory_labtest",
            postgres_conn_id="demo_lamisplus_conn",
            sql="call public.proc_delete_archived_records_updated('laboratory_labtest')",
            autocommit=True)
            
        ods_patient_visit = PostgresOperator(
            task_id="ods_patient_visit",
            postgres_conn_id="demo_lamisplus_conn",
            sql="call public.proc_delete_archived_records_updated('patient_visit')",
            autocommit=True)
        
        ods_hiv_art_clinical = PostgresOperator(
            task_id="ods_hiv_art_clinical",
            postgres_conn_id="demo_lamisplus_conn",
            sql="call public.proc_delete_archived_records_updated('hiv_art_clinical')",
            autocommit=True)
            
        ods_hiv_art_pharmacy = PostgresOperator(
            task_id="ods_hiv_art_pharmacy",
            postgres_conn_id="demo_lamisplus_conn",
            sql="call public.proc_delete_archived_records_updated('hiv_art_pharmacy')",
            autocommit=True)
            
        ods_hiv_enrollment = PostgresOperator(
            task_id="ods_hiv_enrollment",
            postgres_conn_id="demo_lamisplus_conn",
            sql="call public.proc_delete_archived_records_updated('hiv_enrollment')",
            autocommit=True)
            
        ods_hiv_status_tracker = PostgresOperator(
            task_id="ods_hiv_status_tracker",
            postgres_conn_id="demo_lamisplus_conn",
            sql="call public.proc_delete_archived_records_updated('hiv_status_tracker')",
            autocommit=True)
        
        ods_patient_person = PostgresOperator(
            task_id="ods_patient_person",
            postgres_conn_id="demo_lamisplus_conn",
            sql="call public.proc_delete_archived_records_updated('patient_person')",
            autocommit=True)
            
        ods_triage_vital_sign = PostgresOperator(
            task_id="ods_triage_vital_sign",
            postgres_conn_id="demo_lamisplus_conn",
            sql="call public.proc_delete_archived_records_updated('triage_vital_sign')",
            autocommit=True)
            
        ods_laboratory_test = PostgresOperator(
            task_id="ods_laboratory_test",
            postgres_conn_id="demo_lamisplus_conn",
            sql="call public.proc_delete_archived_records_updated('laboratory_test')",
            autocommit=True)
        
        ods_laboratory_sample = PostgresOperator(
            task_id="ods_laboratory_sample",
            postgres_conn_id="demo_lamisplus_conn",
            sql="call public.proc_delete_archived_records_updated('laboratory_sample')",
            autocommit=True)
            
        ods_laboratory_result = PostgresOperator(
            task_id="ods_laboratory_result",
            postgres_conn_id="demo_lamisplus_conn",
            sql="call public.proc_delete_archived_records_updated('laboratory_result')",
            autocommit=True)
            
        ods_laboratory_number = PostgresOperator(
            task_id="ods_laboratory_number",
            postgres_conn_id="demo_lamisplus_conn",
            sql="call public.proc_delete_archived_records_updated('laboratory_number')",
            autocommit=True)
        
        ods_biometric = PostgresOperator(
            task_id="ods_biometric",
            postgres_conn_id="demo_lamisplus_conn",
            sql="call public.proc_delete_archived_records_updated('biometric')",
            autocommit=True)

        ods_hts_family_index_testing_tracker = PostgresOperator(
            task_id="ods_hts_family_index_testing_tracker",
            postgres_conn_id="demo_lamisplus_conn",
            sql="call public.proc_delete_archived_records_updated('hts_family_index_testing_tracker')",
            autocommit=True)
        
        ods_hts_client_referral = PostgresOperator(
            task_id="ods_hts_client_referral",
            postgres_conn_id="demo_lamisplus_conn",
            sql="call public.proc_delete_archived_records_updated('hts_client_referral')",
            autocommit=True)
        
        ods_hivst = PostgresOperator(
            task_id="ods_hivst",
            postgres_conn_id="demo_lamisplus_conn",
            sql="call public.proc_delete_archived_records_updated('hivst')",
            autocommit=True)
        
        ods_hiv_patient_tracker = PostgresOperator(
            task_id="ods_hiv_patient_tracker",
            postgres_conn_id="demo_lamisplus_conn",
            sql="call public.proc_delete_archived_records_updated('hiv_patient_tracker')",
            autocommit=True)
            
        ods_laboratory_sample_type = PostgresOperator(
            task_id="ods_laboratory_sample_type",
            postgres_conn_id="demo_lamisplus_conn",
            sql="call public.proc_delete_archived_records_updated('laboratory_sample_type')",
            autocommit=True)
            
        ods_laboratory_labtestgroup = PostgresOperator(
            task_id="ods_laboratory_labtestgroup",
            postgres_conn_id="demo_lamisplus_conn",
            sql="call public.proc_delete_archived_records_updated('laboratory_labtestgroup')",
            autocommit=True)
        
    
    encrypt_hts_tables = PostgresOperator(
        task_id="encrypt_hts_tables",
        postgres_conn_id="demo_lamisplus_conn",
        sql='call public.proc_encrypt_hts_tables()',
        autocommit=True)
    
    end = BashOperator(
        task_id="end",
        bash_command="echo end")

    # Define the task dependencies
    start >> migrate_and_persist_ods_data >> delete_archived_records >> encrypt_hts_tables >> end 
