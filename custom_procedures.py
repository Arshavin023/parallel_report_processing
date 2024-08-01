from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from airflow.providers.postgres.operators.postgres import PostgresOperator
from airflow.models import Variable

import datetime

default_args = {
    "owner": "airflow",
    "email_on_failure": False,
    "email_on_retry": False,
    "email": "admin@localhost.com",
    "retries": 2,
    "retry_delay": datetime.timedelta(minutes=5)
}



with DAG("custom_procedures", start_date=datetime.datetime(2024, 6, 11), schedule_interval=None,
 default_args=default_args, catchup=True, max_active_runs=1) as dag:

    start = BashOperator(
        task_id="start",
        bash_command="echo start"
    )

    cte_clinic_query = PostgresOperator(
        task_id="cte_clinic_query",
        postgres_conn_id="lamisplus_conn",
        sql = 'call proc_clinic_query()',
        autocommit = True
    )

    cte_laboratory_viral_load_query = PostgresOperator(
        task_id="cte_laboratory_viral_load_query",
        postgres_conn_id="lamisplus_conn",
        sql = 'call proc_laboratory_viral_load_query()',
        autocommit = True
    )

    end = BashOperator(
        task_id="end",
        bash_command="echo end"
    )

    start >> [cte_clinic_query, cte_laboratory_viral_load_query] >> end