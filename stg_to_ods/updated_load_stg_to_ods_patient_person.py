from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from airflow.providers.postgres.operators.postgres import PostgresOperator
import datetime
from datetime import datetime, timedelta
import sys
import os
from lamisplus_funcs import stg_to_ods as lamisplus_funcs
from lamisplus_funcs.airflow_api import trigger_dag
# sys.path.append('/home/lamisplus/airflow/lamisplus_funcs')

def trigger_dag_function(**kwargs):
    trigger_dag(dag_id='upsert_streaming_for_refresh_tables')  

default_args = {
    "owner": "airflow",
    "email_on_failure": False,
    "email_on_retry": False,
    "email": "admin@localhost.com",
    "retries": 3,
    "retry_delay": timedelta(minutes=5)
}


with DAG("patient_person_stg_to_ods", start_date=datetime(2024, 9, 30), schedule_interval=None,
 default_args=default_args, catchup=False, max_active_runs=1) as dag:

    start = BashOperator(
        task_id="start",
        bash_command="echo start"
    )


    custom_patient_person = PythonOperator(
        task_id="custom_patient_person",
        python_callable=lamisplus_funcs.process_patient_person
    )

    start >> patient_person >> end 
