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

with DAG("migrate_old_to_new_ods_v4",start_date=datetime(2024, 11, 1),schedule_interval=None,
            default_args=default_args,catchup=True,max_active_runs=1,) as dag:

    start = BashOperator(
        task_id="start",
        bash_command="echo start"
    ) 
    
    with TaskGroup(group_id='upstream_tasks') as upstream_tasks:
    
        ods_hiv_art_pharmacy_regimens = PostgresOperator(
            task_id="ods_hiv_art_pharmacy_regimens",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_migrate_old_to_new_ods('ods_hiv_art_pharmacy_regimens')",
            autocommit=True)
        
        ods_hiv_art_clinical = PostgresOperator(
            task_id="ods_hiv_art_clinical",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_migrate_old_to_new_ods('ods_hiv_art_clinical')",
            autocommit=True)
            
        ods_hiv_art_pharmacy = PostgresOperator(
            task_id="ods_hiv_art_pharmacy",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_migrate_old_to_new_ods('ods_hiv_art_pharmacy')",
            autocommit=True)
            
        ods_hiv_enrollment = PostgresOperator(
            task_id="ods_hiv_enrollment",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_migrate_old_to_new_ods('ods_hiv_enrollment')",
            autocommit=True)
            
        ods_hiv_status_tracker = PostgresOperator(
            task_id="ods_hiv_status_tracker",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_migrate_old_to_new_ods('ods_hiv_status_tracker')",
            autocommit=True)
        
        ods_patient_person = PostgresOperator(
            task_id="ods_patient_person",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_migrate_old_to_new_ods('ods_patient_person')",
            autocommit=True)
            
        ods_triage_vital_sign = PostgresOperator(
            task_id="ods_triage_vital_sign",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_migrate_old_to_new_ods('ods_triage_vital_sign')",
            autocommit=True)
            
        ods_laboratory_test = PostgresOperator(
            task_id="ods_laboratory_test",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_migrate_old_to_new_ods('ods_laboratory_test')",
            autocommit=True)
        
        ods_laboratory_sample = PostgresOperator(
            task_id="ods_laboratory_sample",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_migrate_old_to_new_ods('ods_laboratory_sample')",
            autocommit=True)
            
        ods_laboratory_result = PostgresOperator(
            task_id="ods_laboratory_result",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_migrate_old_to_new_ods('ods_laboratory_result')",
            autocommit=True)
       
    end = BashOperator(
        task_id="end",
        bash_command="echo end")

    # Define the task dependencies
    start >> upstream_tasks >> end
