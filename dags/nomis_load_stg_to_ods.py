from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from airflow.providers.postgres.operators.postgres import PostgresOperator
import datetime
from datetime import datetime, timedelta
from airflow.utils.task_group import TaskGroup
import sys
import os
from nomis_funcs import stg_to_ods as nomis_funcs
# sys.path.append('/home/lamisplus/airflow/nomis_funcs')


default_args = {
    "owner": "airflow",
    "email_on_failure": False,
    "email_on_retry": False,
    "email": "admin@localhost.com",
    "retries": 3,
    "retry_delay": timedelta(minutes=5)
}


with DAG("nomis_stg_to_ods", start_date=datetime(2025, 7, 15), 
         schedule_interval=timedelta(hours=12), default_args=default_args, 
         catchup=False, max_active_runs=1) as dag:

    start = BashOperator(
        task_id="start",
        bash_command="echo start"
    ) 
    
    with TaskGroup(group_id='migrate_and_persist_ods_data') as migrate_and_persist_ods_data:
        person = PythonOperator(
        task_id="person",
        python_callable=nomis_funcs.process_person)
        
        status = PythonOperator(
        task_id="status",
        python_callable=nomis_funcs.process_status)
        
        encounter = PythonOperator(
        task_id="encounter",
        python_callable=nomis_funcs.process_encounter)
        
        linelist = PythonOperator(
        task_id="linelist",
        python_callable=nomis_funcs.process_linelist)
        
        household = PythonOperator(
        task_id="household",
        python_callable=nomis_funcs.process_household)
    
    end = BashOperator(
        task_id="end",
        bash_command="echo end")

    # Define the task dependencies
    start >> migrate_and_persist_ods_data >> end 
