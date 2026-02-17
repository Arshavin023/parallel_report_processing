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
    "retries": 3,
    "retry_delay": timedelta(minutes=5)
}

with DAG("lamis_stg_to_ods_biometric",start_date=datetime(2024, 10, 24),schedule_interval=timedelta(minutes=5),
            default_args=default_args,catchup=True,max_active_runs=1,) as dag:

    start = BashOperator(
        task_id="start",
        bash_command="echo start"
    )

    with TaskGroup(group_id='upstream_tasks') as upstream_tasks:

        biometric = PostgresOperator(
            task_id="biometric",
            postgres_conn_id="lamisplus_conn",
            sql="call public.proc_stream_biometric_v2('stg_biometric')",
            autocommit=True)


    end = BashOperator(
        task_id="end",
        bash_command="echo end")

    # Define the task dependencies
    start >> upstream_tasks >> end
