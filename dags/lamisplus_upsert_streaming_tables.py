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
    "retries": 2,
    "retry_delay": datetime.timedelta(minutes=5)
}

with DAG("lamisplus_upsert_streaming_for_refresh_tables",start_date=datetime.datetime(2024, 7, 1),schedule_interval=None,
            default_args=default_args,catchup=True,max_active_runs=1,) as dag:

    start = BashOperator(
        task_id="start",
        bash_command="echo start"
    ) 
    
    with TaskGroup(group_id='upstream_tasks') as upstream_tasks:
        
        upsert_cte_bio_data = PostgresOperator(
            task_id="upsert_cte_bio_data",
            postgres_conn_id="lamisplus_conn",
            sql='call expanded_radet.proc_upsert_cte_bio_data_updated()',
            autocommit=True
        )
        
        upsert_sub_current_clinical = PostgresOperator(
            task_id="upsert_sub_current_clinical",
            postgres_conn_id="lamisplus_conn",
            sql='call expanded_radet.proc_upsert_sub_current_clinical()',
            autocommit=True
        )
        
        upsert_carecardcd4 = PostgresOperator(
            task_id="upsert_carecardcd4",
            postgres_conn_id="lamisplus_conn",
            sql='call expanded_radet.proc_upsert_carecardcd4()',
            autocommit=True
        )
        
        upsert_hiv_observation_refresh = PostgresOperator(
            task_id="upsert_hiv_observation_refresh",
            postgres_conn_id="lamisplus_conn",
            sql='call expanded_radet.proc_upsert_hiv_observation_refresh()',
            autocommit=True
        )
        
        upsert_hivregimentype_refresh = PostgresOperator(
            task_id="upsert_hivregimentype_refresh",
            postgres_conn_id="lamisplus_conn",
            sql='call expanded_radet.proc_upsert_hivregimentype_refresh()',
            autocommit=True
        )
        
		
    end = BashOperator(
        task_id="end",
        bash_command="echo end"
    )
    # Define the task dependencies
    start >> upstream_tasks >> end
