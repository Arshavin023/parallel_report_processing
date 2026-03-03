from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from airflow.providers.postgres.operators.postgres import PostgresOperator
import datetime
from datetime import datetime, timedelta
from airflow.utils.task_group import TaskGroup
import sys
import os
from lamisplus_funcs import stg_to_ods as lamisplus_funcs
from lamisplus_funcs.airflow_api import trigger_dag
# sys.path.append('/home/lamisplus/airflow/lamisplus_funcs')


default_args = {
    "owner": "airflow",
    "email_on_failure": False,
    "email_on_retry": False,
    "email": "admin@localhost.com",
    "retries": 3,
    "retry_delay": timedelta(minutes=5)
}

with DAG("stream_layer3_reports", start_date=datetime(2026, 2, 18),
         schedule_interval=None,
         default_args=default_args,catchup=False,
         params={"periods": None},
         max_active_runs=1,
         tags=["Layer3", "LamisPlus", "Reports", "Periodic"]
         ) as dag:

    start = BashOperator(
        task_id="start",
        bash_command="echo start"
    )


    with TaskGroup(group_id='generate_first_report_batch') as generate_first_report_batch:
        stream_hts_layer3 = PostgresOperator(
            task_id="stream_hts_layer3",
            postgres_conn_id = "hts_prep_conn",
            sql = 'call public.proc_stream_hts_layer3({{ params.periods }});',
            autocommit = True)

        stream_radet_layer3 = PostgresOperator(
            task_id="stream_radet_layer3",
            postgres_conn_id="radet_conn",
            sql = 'call public.proc_stream_radet_layer3({{ params.periods }});',
            autocommit = True)

    with TaskGroup(group_id='generate_second_report_batch') as generate_second_report_batch:
        combined_htsradet_task = PostgresOperator(
            task_id="combined_htsradet",
            postgres_conn_id = "hts_prep_conn_layer3",
            sql='call public.proc_populate_combined_htsradet({{ params.periods }});',
            autocommit = True)

    end = BashOperator(
        task_id="end",
        bash_command="echo end")

    # Define the task dependencies
    start >> generate_first_report_batch >> generate_second_report_batch >> end
