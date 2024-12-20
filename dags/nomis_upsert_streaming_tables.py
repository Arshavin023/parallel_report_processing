from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.providers.postgres.operators.postgres import PostgresOperator
from airflow.utils.task_group import TaskGroup
import datetime
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

with DAG("nomis_upsert_streaming_for_refresh_tables",start_date=datetime(2024, 10, 16),schedule_interval=timedelta(hours=12),
            default_args=default_args,catchup=True,max_active_runs=1,) as dag:

    start = BashOperator(
        task_id="start",
        bash_command="echo start"
    ) 
    
    with TaskGroup(group_id='upstream_tasks') as upstream_tasks:
        
        upsert_person_household = PostgresOperator(
            task_id="upsert_person_household",
            postgres_conn_id="nomis_datamart_conn",
            sql='call public.proc_upsert_person_household_refresh()',
            autocommit=True
        )
        
        upsert_status_refresh = PostgresOperator(
            task_id="upsert_status_refresh",
            postgres_conn_id="nomis_datamart_conn",
            sql='call public.proc_upsert_status_refresh()',
            autocommit=True
        )
        
        upsert_linelist = PostgresOperator(
            task_id="upsert_linelist",
            postgres_conn_id="nomis_datamart_conn",
            sql='call public.proc_upsert_linelist_refresh()',
            autocommit=True
        )
    
    with TaskGroup(group_id='midstream_tasks') as midstream_tasks:
        
        latest_status = PostgresOperator(
            task_id="latest_status",
            postgres_conn_id="nomis_datamart_conn",
            sql='call public.proc_latest_status()',
            autocommit=True
        )

		
    end = BashOperator(
        task_id="end",
        bash_command="echo end"
    )
    # Define the task dependencies
    start >> upstream_tasks >> midstream_tasks >> end
