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

with DAG("migrate_old_to_new_ods",start_date=datetime(2024, 11, 1),schedule_interval=None,
            default_args=default_args,catchup=True,max_active_runs=1,) as dag:

    start = BashOperator(
        task_id="start",
        bash_command="echo start"
    ) 
    
    with TaskGroup(group_id='upstream_tasks') as upstream_tasks:
    
        base_application_codeset = PostgresOperator(
            task_id="base_application_codeset",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_migrate_old_to_new_ods('ods_base_application_codeset')",
            autocommit=True)
        
        base_organisation_unit_identifier = PostgresOperator(
            task_id="base_organisation_unit_identifier",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_migrate_old_to_new_ods('ods_base_organisation_unit_identifier')",
            autocommit=True)
            
        base_organisation_unit = PostgresOperator(
            task_id="base_organisation_unit",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_migrate_old_to_new_ods('ods_base_organisation_unit')",
            autocommit=True)
        
       
    end = BashOperator(
        task_id="end",
        bash_command="echo end")

    # Define the task dependencies
    start >> upstream_tasks >> end
