from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from airflow.providers.postgres.operators.postgres import PostgresOperator
from airflow.models import Variable
from airflow.sensors.external_task import ExternalTaskSensor
from airflow.utils.task_group import TaskGroup
import datetime


default_args = {
    "owner": "airflow",
    "email_on_failure": False,
    "email_on_retry": False,
    "email": "admin@localhost.com",
    "retries": 2,
    "retry_delay": datetime.timedelta(minutes=5)
}

with DAG("remaining_final_hts_prep_quartely", start_date=datetime.datetime(2024, 7, 1), schedule_interval=None,
         default_args=default_args,
         catchup=False, max_active_runs=1) as dag:

    start = BashOperator(
        task_id="start",
        bash_command="echo start"
    )
        
    with TaskGroup(group_id='upstream_tasks') as upstream_tasks:
	
        expanded_hts_joined_bio = PostgresOperator(
            task_id="expanded_hts_joined_bio",
            postgres_conn_id="lamisplus_conn",
            sql = 'call expanded_hts_prep.proc_sub_expanded_hts_joined_bio()',
            autocommit = True
        )
        
        expanded_hts_joined_codeset = PostgresOperator(
            task_id="expanded_hts_joined_codeset",
            postgres_conn_id="lamisplus_conn",
            sql = 'call expanded_hts_prep.proc_sub_expanded_hts_joined_codeset()',
            autocommit = True
        )
        
    expanded_hts_joined = PostgresOperator(
        task_id="expanded_hts_joined",
        postgres_conn_id="lamisplus_conn",
        sql = 'call expanded_hts_prep.proc_expanded_hts_joined()',
        autocommit = True
        )
           
    with TaskGroup(group_id='downstream_tasks') as downstream_tasks:
        final_htsquery_datamart = PostgresOperator(
            task_id="final_htsquery_datamart",
            postgres_conn_id="lamisplus_conn",
            sql = 'call hts_prep_datamart.proc_final_htsquery_datamart()',
            autocommit = True
        )
        
        final_prepquery_datamart = PostgresOperator(
            task_id="final_prepquery_datamart",
            postgres_conn_id="lamisplus_conn",
            sql = 'call hts_prep_datamart.proc_final_prepquery_datamart()',
            autocommit = True
        )

    end = BashOperator(
        task_id="end",
        bash_command="echo end"
        )


    start >> update_period_table >> upstream_tasks >> expanded_hts_joined >> downstream_tasks
