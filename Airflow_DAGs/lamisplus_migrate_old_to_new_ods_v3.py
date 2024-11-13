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

with DAG("migrate_old_to_new_ods_v3",start_date=datetime(2024, 11, 1),schedule_interval=None,
            default_args=default_args,catchup=True,max_active_runs=1,) as dag:

    start = BashOperator(
        task_id="start",
        bash_command="echo start"
    ) 
    
    with TaskGroup(group_id='upstream_tasks') as upstream_tasks:
    
        ods_hiv_observation = PostgresOperator(
            task_id="ods_hiv_observation",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_migrate_old_to_new_ods('ods_hiv_observation')",
            autocommit=True)
        
        ods_hts_client = PostgresOperator(
            task_id="ods_hts_client",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_migrate_old_to_new_ods('ods_hts_client')",
            autocommit=True)
            
        ods_laboratory_labtest = PostgresOperator(
            task_id="ods_laboratory_labtest",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_migrate_old_to_new_ods('ods_laboratory_labtest')",
            autocommit=True)
            
        ods_patient_visit = PostgresOperator(
            task_id="ods_patient_visit",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_migrate_old_to_new_ods('ods_patient_visit')",
            autocommit=True)
        
       
    end = BashOperator(
        task_id="end",
        bash_command="echo end")

    # Define the task dependencies
    start >> upstream_tasks >> end
