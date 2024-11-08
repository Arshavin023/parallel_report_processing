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

with DAG("migrate_old_to_new_ods_v2",start_date=datetime(2024, 11, 1),schedule_interval=None,
            default_args=default_args,catchup=True,max_active_runs=1,) as dag:

    start = BashOperator(
        task_id="start",
        bash_command="echo start"
    ) 
    
    with TaskGroup(group_id='upstream_tasks') as upstream_tasks:
    
        ods_case_manager = PostgresOperator(
            task_id="ods_case_manager",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_migrate_old_to_new_ods('ods_case_manager')",
            autocommit=True)
        
        ods_dsd_devolvement = PostgresOperator(
            task_id="ods_dsd_devolvement",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_migrate_old_to_new_ods('ods_dsd_devolvement')",
            autocommit=True)
            
        ods_case_manager_patients = PostgresOperator(
            task_id="ods_case_manager_patients",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_migrate_old_to_new_ods('ods_case_manager_patients')",
            autocommit=True)
            
        ods_hiv_eac = PostgresOperator(
            task_id="ods_hiv_eac",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_migrate_old_to_new_ods('ods_hiv_eac')",
            autocommit=True)
        
        ods_hiv_eac_out_come = PostgresOperator(
            task_id="ods_hiv_eac_out_come",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_migrate_old_to_new_ods('ods_hiv_eac_out_come')",
            autocommit=True)
            
        ods_hiv_eac_session = PostgresOperator(
            task_id="ods_hiv_eac_session",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_migrate_old_to_new_ods('ods_hiv_eac_session')",
            autocommit=True)
        
        ods_hiv_regimen = PostgresOperator(
            task_id="ods_hiv_regimen",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_migrate_old_to_new_ods('ods_hiv_regimen')",
            autocommit=True)
        
        ods_hiv_regimen_resolver = PostgresOperator(
            task_id="ods_hiv_regimen_resolver",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_migrate_old_to_new_ods('ods_hiv_regimen_resolver')",
            autocommit=True)
            
        ods_hiv_regimen_type = PostgresOperator(
            task_id="ods_hiv_regimen_type",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_migrate_old_to_new_ods('ods_hiv_regimen_type')",
            autocommit=True)
        
        ods_hts_index_elicitation = PostgresOperator(
            task_id="ods_hts_index_elicitation",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_migrate_old_to_new_ods('ods_hts_index_elicitation')",
            autocommit=True)
        
        ods_hts_risk_stratification = PostgresOperator(
            task_id="ods_hts_risk_stratification",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_migrate_old_to_new_ods('ods_hts_risk_stratification')",
            autocommit=True)
            
        ods_laboratory_order = PostgresOperator(
            task_id="ods_laboratory_order",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_migrate_old_to_new_ods('ods_laboratory_order')",
            autocommit=True)
        
        ods_patient_encounter = PostgresOperator(
            task_id="ods_patient_encounter",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_migrate_old_to_new_ods('ods_patient_encounter')",
            autocommit=True)
        
        ods_pmtct_anc = PostgresOperator(
            task_id="ods_pmtct_anc",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_migrate_old_to_new_ods('ods_pmtct_anc')",
            autocommit=True)
            
        ods_pmtct_delivery = PostgresOperator(
            task_id="ods_pmtct_delivery",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_migrate_old_to_new_ods('ods_pmtct_delivery')",
            autocommit=True)
        
        ods_pmtct_enrollment = PostgresOperator(
            task_id="ods_pmtct_enrollment",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_migrate_old_to_new_ods('ods_pmtct_enrollment')",
            autocommit=True)
        
        ods_pmtct_infant_arv = PostgresOperator(
            task_id="ods_pmtct_infant_arv",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_migrate_old_to_new_ods('ods_pmtct_infant_arv')",
            autocommit=True)
            
        ods_pmtct_infant_information = PostgresOperator(
            task_id="ods_pmtct_infant_information",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_migrate_old_to_new_ods('ods_pmtct_infant_information')",
            autocommit=True)
            
        ods_pmtct_infant_mother_art = PostgresOperator(
            task_id="ods_pmtct_infant_mother_art",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_migrate_old_to_new_ods('ods_pmtct_infant_mother_art')",
            autocommit=True)
        
        ods_pmtct_infant_pcr = PostgresOperator(
            task_id="ods_pmtct_infant_pcr",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_migrate_old_to_new_ods('ods_pmtct_infant_pcr')",
            autocommit=True)
            
        ods_pmtct_infant_rapid_antibody = PostgresOperator(
            task_id="ods_pmtct_infant_rapid_antibody",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_migrate_old_to_new_ods('ods_pmtct_infant_rapid_antibody')",
            autocommit=True)
        
        ods_pmtct_infant_visit = PostgresOperator(
            task_id="ods_pmtct_infant_visit",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_migrate_old_to_new_ods('ods_pmtct_infant_visit')",
            autocommit=True)
        
        ods_pmtct_mother_visitation = PostgresOperator(
            task_id="ods_pmtct_mother_visitation",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_migrate_old_to_new_ods('ods_pmtct_mother_visitation')",
            autocommit=True)
            
        ods_prep_clinic = PostgresOperator(
            task_id="ods_prep_clinic",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_migrate_old_to_new_ods('ods_prep_clinic')",
            autocommit=True)
        
        ods_prep_eligibility = PostgresOperator(
            task_id="ods_prep_eligibility",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_migrate_old_to_new_ods('ods_prep_eligibility')",
            autocommit=True)
        
        ods_prep_enrollment = PostgresOperator(
            task_id="ods_prep_enrollment",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_migrate_old_to_new_ods('ods_prep_enrollment')",
            autocommit=True)
            
        ods_prep_interruption = PostgresOperator(
            task_id="ods_prep_interruption",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_migrate_old_to_new_ods('ods_prep_interruption')",
            autocommit=True)
        
        ods_prep_regimen = PostgresOperator(
            task_id="ods_prep_regimen",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_migrate_old_to_new_ods('ods_prep_regimen')",
            autocommit=True)
        
       
    end = BashOperator(
        task_id="end",
        bash_command="echo end")

    # Define the task dependencies
    start >> upstream_tasks >> end
