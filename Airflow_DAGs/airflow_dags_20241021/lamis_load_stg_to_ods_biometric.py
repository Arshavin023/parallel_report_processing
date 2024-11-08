from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from airflow.providers.postgres.operators.postgres import PostgresOperator
import datetime
from datetime import datetime, timedelta
import sys
import os
from lamisplus_funcs import stg_to_ods_biometric as lamisplus_funcs
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


with DAG("lamis_stg_to_ods_biometric", start_date=datetime(2024, 9, 30), schedule_interval=timedelta(hours=1),
 default_args=default_args, catchup=False, max_active_runs=1) as dag:

    start = BashOperator(
        task_id="start",
        bash_command="echo start"
    )


    custom_biometric = PythonOperator(
        task_id="custom_biometric",
        python_callable=lamisplus_funcs.process_biometric
    )

    start >> custom_biometric
