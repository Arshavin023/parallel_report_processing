from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from airflow.providers.postgres.operators.postgres import PostgresOperator
import datetime
from datetime import datetime, timedelta
import sys
import os
from nomis_funcs import stg_to_ods as nomis_funcs
# from nomis_funcs.airflow_api import trigger_dag
# sys.path.append('/home/lamisplus/airflow/nomis_funcs')

default_args = {
    "owner": "airflow",
    "email_on_failure": False,
    "email_on_retry": False,
    "email": "admin@localhost.com",
    "retries": 0,
    "retry_delay": timedelta(minutes=5)
}


with DAG("nomis_stg_to_ods", start_date=datetime(2024, 10, 7), schedule_interval=timedelta(hours=4),
 default_args=default_args, catchup=False, max_active_runs=1) as dag:

    start = BashOperator(
        task_id="start",
        bash_command="echo start"
    )


    person = PythonOperator(
        task_id="person",
        python_callable=nomis_funcs.process_person
    )

    status = PythonOperator(
        task_id="status",
        python_callable=nomis_funcs.process_status
    )

    household = PythonOperator(
        task_id="household",
        python_callable=nomis_funcs.process_household
    )

    linelist = PythonOperator(
        task_id="linelist",
        python_callable=nomis_funcs.process_linelist
    )
    
    end = BashOperator(
        task_id="end",
        bash_command="echo end"
    )


    start >> [person,status,household,linelist] >> end
