from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.providers.postgres.operators.postgres import PostgresOperator
from airflow.utils.task_group import TaskGroup
from datetime import datetime, timedelta
from airflow.utils.task_group import TaskGroup

default_args = {
    "owner": "airflow",
    "email_on_failure": False,
    "email_on_retry": False,
    "email": "admin@localhost.com",
    "retries": 2,
    "retry_delay": timedelta(minutes=5)
}

with DAG("lamisplus_delete_stg_tables",start_date=datetime(2024, 11, 1),schedule_interval=None,
            default_args=default_args,catchup=True,max_active_runs=1,) as dag:

    start = BashOperator(
        task_id="start",
        bash_command="echo start"
    ) 
    
    with TaskGroup(group_id='upstream_tasks') as upstream_tasks:
        
        stg_base_application_codeset = PostgresOperator(
            task_id="base_application_codeset",
            postgres_conn_id="lamisplus_stg_conn",
            sql="call public.proc_delete_stg_tables('stg_base_application_codeset')",
            autocommit=True)
        
        stg_base_organisation_unit_identifier = PostgresOperator(
            task_id="base_organisation_unit_identifier",
            postgres_conn_id="lamisplus_stg_conn",
            sql="call public.proc_delete_stg_tables('stg_base_organisation_unit_identifier')",
            autocommit=True)
            
        stg_base_organisation_unit = PostgresOperator(
            task_id="base_organisation_unit",
            postgres_conn_id="lamisplus_stg_conn",
            sql="call public.proc_delete_stg_tables('stg_base_organisation_unit')",
            autocommit=True)
            
        stg_case_manager = PostgresOperator(
            task_id="stg_case_manager",
            postgres_conn_id="lamisplus_stg_conn",
            sql="call public.proc_delete_stg_tables('stg_case_manager')",
            autocommit=True)
        
        stg_dsd_devolvement = PostgresOperator(
            task_id="stg_dsd_devolvement",
            postgres_conn_id="lamisplus_stg_conn",
            sql="call public.proc_delete_stg_tables('stg_dsd_devolvement')",
            autocommit=True)
            
        stg_case_manager_patients = PostgresOperator(
            task_id="stg_case_manager_patients",
            postgres_conn_id="lamisplus_stg_conn",
            sql="call public.proc_delete_stg_tables('stg_case_manager_patients')",
            autocommit=True)
            
        stg_hiv_eac = PostgresOperator(
            task_id="stg_hiv_eac",
            postgres_conn_id="lamisplus_stg_conn",
            sql="call public.proc_delete_stg_tables('stg_hiv_eac')",
            autocommit=True)
        
        stg_hiv_eac_out_come = PostgresOperator(
            task_id="stg_hiv_eac_out_come",
            postgres_conn_id="lamisplus_stg_conn",
            sql="call public.proc_delete_stg_tables('stg_hiv_eac_out_come')",
            autocommit=True)
            
        stg_hiv_eac_session = PostgresOperator(
            task_id="stg_hiv_eac_session",
            postgres_conn_id="lamisplus_stg_conn",
            sql="call public.proc_delete_stg_tables('stg_hiv_eac_session')",
            autocommit=True)
        
        stg_hiv_regimen = PostgresOperator(
            task_id="stg_hiv_regimen",
            postgres_conn_id="lamisplus_stg_conn",
            sql="call public.proc_delete_stg_tables('stg_hiv_regimen')",
            autocommit=True)
        
        stg_hiv_regimen_resolver = PostgresOperator(
            task_id="stg_hiv_regimen_resolver",
            postgres_conn_id="lamisplus_stg_conn",
            sql="call public.proc_delete_stg_tables('stg_hiv_regimen_resolver')",
            autocommit=True)
            
        stg_hiv_regimen_type = PostgresOperator(
            task_id="stg_hiv_regimen_type",
            postgres_conn_id="lamisplus_stg_conn",
            sql="call public.proc_delete_stg_tables('stg_hiv_regimen_type')",
            autocommit=True)
        
        stg_hts_index_elicitation = PostgresOperator(
            task_id="stg_hts_index_elicitation",
            postgres_conn_id="lamisplus_stg_conn",
            sql="call public.proc_delete_stg_tables('stg_hts_index_elicitation')",
            autocommit=True)
        
        stg_hts_risk_stratification = PostgresOperator(
            task_id="stg_hts_risk_stratification",
            postgres_conn_id="lamisplus_stg_conn",
            sql="call public.proc_delete_stg_tables('stg_hts_risk_stratification')",
            autocommit=True)
            
        stg_laboratory_order = PostgresOperator(
            task_id="stg_laboratory_order",
            postgres_conn_id="lamisplus_stg_conn",
            sql="call public.proc_delete_stg_tables('stg_laboratory_order')",
            autocommit=True)
        
        stg_patient_encounter = PostgresOperator(
            task_id="stg_patient_encounter",
            postgres_conn_id="lamisplus_stg_conn",
            sql="call public.proc_delete_stg_tables('stg_patient_encounter')",
            autocommit=True)
        
        stg_pmtct_anc = PostgresOperator(
            task_id="stg_pmtct_anc",
            postgres_conn_id="lamisplus_stg_conn",
            sql="call public.proc_delete_stg_tables('stg_pmtct_anc')",
            autocommit=True)
            
        stg_pmtct_delivery = PostgresOperator(
            task_id="stg_pmtct_delivery",
            postgres_conn_id="lamisplus_stg_conn",
            sql="call public.proc_delete_stg_tables('stg_pmtct_delivery')",
            autocommit=True)
        
        stg_pmtct_enrollment = PostgresOperator(
            task_id="stg_pmtct_enrollment",
            postgres_conn_id="lamisplus_stg_conn",
            sql="call public.proc_delete_stg_tables('stg_pmtct_enrollment')",
            autocommit=True)
        
        stg_pmtct_infant_arv = PostgresOperator(
            task_id="stg_pmtct_infant_arv",
            postgres_conn_id="lamisplus_stg_conn",
            sql="call public.proc_delete_stg_tables('stg_pmtct_infant_arv')",
            autocommit=True)
            
        stg_pmtct_infant_information = PostgresOperator(
            task_id="stg_pmtct_infant_information",
            postgres_conn_id="lamisplus_stg_conn",
            sql="call public.proc_delete_stg_tables('stg_pmtct_infant_information')",
            autocommit=True)
            
        stg_pmtct_infant_mother_art = PostgresOperator(
            task_id="stg_pmtct_infant_mother_art",
            postgres_conn_id="lamisplus_stg_conn",
            sql="call public.proc_delete_stg_tables('stg_pmtct_infant_mother_art')",
            autocommit=True)
        
        stg_pmtct_infant_pcr = PostgresOperator(
            task_id="stg_pmtct_infant_pcr",
            postgres_conn_id="lamisplus_stg_conn",
            sql="call public.proc_delete_stg_tables('stg_pmtct_infant_pcr')",
            autocommit=True)
            
        stg_pmtct_infant_rapid_antibody = PostgresOperator(
            task_id="stg_pmtct_infant_rapid_antibody",
            postgres_conn_id="lamisplus_stg_conn",
            sql="call public.proc_delete_stg_tables('stg_pmtct_infant_rapid_antibody')",
            autocommit=True)
        
        stg_pmtct_infant_visit = PostgresOperator(
            task_id="stg_pmtct_infant_visit",
            postgres_conn_id="lamisplus_stg_conn",
            sql="call public.proc_delete_stg_tables('stg_pmtct_infant_visit')",
            autocommit=True)
        
        stg_pmtct_mother_visitation = PostgresOperator(
            task_id="stg_pmtct_mother_visitation",
            postgres_conn_id="lamisplus_stg_conn",
            sql="call public.proc_delete_stg_tables('stg_pmtct_mother_visitation')",
            autocommit=True)
            
        stg_prep_clinic = PostgresOperator(
            task_id="stg_prep_clinic",
            postgres_conn_id="lamisplus_stg_conn",
            sql="call public.proc_delete_stg_tables('stg_prep_clinic')",
            autocommit=True)
        
        stg_prep_eligibility = PostgresOperator(
            task_id="stg_prep_eligibility",
            postgres_conn_id="lamisplus_stg_conn",
            sql="call public.proc_delete_stg_tables('stg_prep_eligibility')",
            autocommit=True)
        
        stg_prep_enrollment = PostgresOperator(
            task_id="stg_prep_enrollment",
            postgres_conn_id="lamisplus_stg_conn",
            sql="call public.proc_delete_stg_tables('stg_prep_enrollment')",
            autocommit=True)
            
        stg_prep_interruption = PostgresOperator(
            task_id="stg_prep_interruption",
            postgres_conn_id="lamisplus_stg_conn",
            sql="call public.proc_delete_stg_tables('stg_prep_interruption')",
            autocommit=True)
        
        stg_prep_regimen = PostgresOperator(
            task_id="stg_prep_regimen",
            postgres_conn_id="lamisplus_stg_conn",
            sql="call public.proc_delete_stg_tables('stg_prep_regimen')",
            autocommit=True)
        
        stg_hiv_observation = PostgresOperator(
            task_id="stg_hiv_observation",
            postgres_conn_id="lamisplus_stg_conn",
            sql="call public.proc_delete_stg_tables('stg_hiv_observation')",
            autocommit=True)
        
        stg_hts_client = PostgresOperator(
            task_id="stg_hts_client",
            postgres_conn_id="lamisplus_stg_conn",
            sql="call public.proc_delete_stg_tables('stg_hts_client')",
            autocommit=True)
            
        stg_laboratory_labtest = PostgresOperator(
            task_id="stg_laboratory_labtest",
            postgres_conn_id="lamisplus_stg_conn",
            sql="call public.proc_delete_stg_tables('stg_laboratory_labtest')",
            autocommit=True)
            
        stg_patient_visit = PostgresOperator(
            task_id="stg_patient_visit",
            postgres_conn_id="lamisplus_stg_conn",
            sql="call public.proc_delete_stg_tables('stg_patient_visit')",
            autocommit=True)
        
        stg_hiv_art_pharmacy_regimens = PostgresOperator(
            task_id="stg_hiv_art_pharmacy_regimens",
            postgres_conn_id="lamisplus_stg_conn",
            sql="call public.proc_delete_stg_tables('stg_hiv_art_pharmacy_regimens')",
            autocommit=True)
        
        stg_hiv_art_clinical = PostgresOperator(
            task_id="stg_hiv_art_clinical",
            postgres_conn_id="lamisplus_stg_conn",
            sql="call public.proc_delete_stg_tables('stg_hiv_art_clinical')",
            autocommit=True)
            
        stg_hiv_art_pharmacy = PostgresOperator(
            task_id="stg_hiv_art_pharmacy",
            postgres_conn_id="lamisplus_stg_conn",
            sql="call public.proc_delete_stg_tables('stg_hiv_art_pharmacy')",
            autocommit=True)
            
        stg_hiv_enrollment = PostgresOperator(
            task_id="stg_hiv_enrollment",
            postgres_conn_id="lamisplus_stg_conn",
            sql="call public.proc_delete_stg_tables('stg_hiv_enrollment')",
            autocommit=True)
            
        stg_hiv_status_tracker = PostgresOperator(
            task_id="stg_hiv_status_tracker",
            postgres_conn_id="lamisplus_stg_conn",
            sql="call public.proc_delete_stg_tables('stg_hiv_status_tracker')",
            autocommit=True)
        
        stg_patient_person = PostgresOperator(
            task_id="stg_patient_person",
            postgres_conn_id="lamisplus_stg_conn",
            sql="call public.proc_delete_stg_tables('stg_patient_person')",
            autocommit=True)
            
        stg_triage_vital_sign = PostgresOperator(
            task_id="stg_triage_vital_sign",
            postgres_conn_id="lamisplus_stg_conn",
            sql="call public.proc_delete_stg_tables('stg_triage_vital_sign')",
            autocommit=True)
            
        stg_laboratory_test = PostgresOperator(
            task_id="stg_laboratory_test",
            postgres_conn_id="lamisplus_stg_conn",
            sql="call public.proc_delete_stg_tables('stg_laboratory_test')",
            autocommit=True)
        
        stg_laboratory_sample = PostgresOperator(
            task_id="stg_laboratory_sample",
            postgres_conn_id="lamisplus_stg_conn",
            sql="call public.proc_delete_stg_tables('stg_laboratory_sample')",
            autocommit=True)
            
        stg_laboratory_result = PostgresOperator(
            task_id="stg_laboratory_result",
            postgres_conn_id="lamisplus_stg_conn",
            sql="call public.proc_delete_stg_tables('stg_laboratory_result')",
            autocommit=True)
        
        stg_deduplication = PostgresOperator(
            task_id="stg_deduplication",
            postgres_conn_id="lamisplus_stg_conn",
            sql="call public.proc_delete_stg_tables('stg_deduplication')",
            autocommit=True)
        
        stg_hiv_regimen_drug = PostgresOperator(
            task_id="stg_hiv_regimen_drug",
            postgres_conn_id="lamisplus_stg_conn",
            sql="call public.proc_delete_stg_tables('stg_hiv_regimen_drug')",
            autocommit=True)
            
        stg_laboratory_number = PostgresOperator(
            task_id="stg_laboratory_number",
            postgres_conn_id="lamisplus_stg_conn",
            sql="call public.proc_delete_stg_tables('stg_laboratory_number')",
            autocommit=True)
        
        stg_biometric = PostgresOperator(
            task_id="stg_biometric",
            postgres_conn_id="lamisplus_stg_conn",
            sql="call public.proc_delete_stg_tables('stg_biometric')",
            autocommit=True)
        
       
    end = BashOperator(
        task_id="end",
        bash_command="echo end")

    # Define the task dependencies
    start >> upstream_tasks >> end
