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

with DAG("nomis_migrate_old_to_new_ods",start_date=datetime(2024, 11, 1),schedule_interval=None,
            default_args=default_args,catchup=True,max_active_runs=1,) as dag:

    start = BashOperator(
        task_id="start",
        bash_command="echo start"
    ) 
    
    with TaskGroup(group_id='upstream_tasks') as upstream_tasks:
    
        person = PostgresOperator(
            task_id="person",
            postgres_conn_id="nomis_ods_conn",
            sql="call public.proc_migrate_old_to_new_ods('ods_person')",
            autocommit=True)
        
        status = PostgresOperator(
            task_id="status",
            postgres_conn_id="nomis_ods_conn",
            sql="call public.proc_migrate_old_to_new_ods('ods_status')",
            autocommit=True)
            
        linelist = PostgresOperator(
            task_id="linelist",
            postgres_conn_id="nomis_ods_conn",
            sql="call public.proc_migrate_old_to_new_ods('ods_linelist')",
            autocommit=True)
        
        household = PostgresOperator(
            task_id="household",
            postgres_conn_id="nomis_ods_conn",
            sql="call public.proc_migrate_old_to_new_ods('ods_household')",
            autocommit=True)
        
       
    end = BashOperator(
        task_id="end",
        bash_command="echo end")

    # Define the task dependencies
    start >> upstream_tasks >> end
