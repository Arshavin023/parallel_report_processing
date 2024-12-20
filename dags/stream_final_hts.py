from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.providers.postgres.operators.postgres import PostgresOperator
from airflow.utils.task_group import TaskGroup
import datetime
from airflow.utils.task_group import TaskGroup

default_args = {
    "owner": "airflow",
    "email_on_failure": False,
    "email_on_retry": False,
    "email": "admin@localhost.com",
    "retries": 3,
    "retry_delay": datetime.timedelta(minutes=5)
}

with DAG("stream_final_hts_to_demo_lamisplus_dwh",start_date=datetime.datetime(2024, 7, 1),schedule_interval=None,
            default_args=default_args,catchup=True,max_active_runs=1,) as dag:

    start = BashOperator(
        task_id="start",
        bash_command="echo start"
    ) 
    
    with TaskGroup(group_id='upstream_tasks') as upstream_tasks:
    
        stream_final_hts = PostgresOperator(
            task_id="stream_final_hts",
            postgres_conn_id="lamisplus_demo_dwh_conn",
            sql="call public.proc_stream_final_hts()",
            autocommit=True)
        
       
    end = BashOperator(
        task_id="end",
        bash_command="echo end")

    # Define the task dependencies
    start >> upstream_tasks >> end
