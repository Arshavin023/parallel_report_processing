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

with DAG("sub_prep_currentprevious_pc",start_date=datetime(2024, 10, 25),schedule_interval=None,
            default_args=default_args,catchup=True,max_active_runs=1,) as dag:

    start = BashOperator(
        task_id="start",
        bash_command="echo start"
    ) 
    
    with TaskGroup(group_id='upstream_tasks') as upstream_tasks:
    
        sub_prep_currentprevious_pc = PostgresOperator(
            task_id="sub_prep_currentprevious_pc",
            postgres_conn_id="hts_prep_conn",
            sql="call expanded_hts_prep.proc_sub_prep_currentprevious_pc()",
            autocommit=True)
    
    with TaskGroup(group_id='upstream_tasks') as upstream_tasks:
    
        prep_previous_pc = PostgresOperator(
            task_id="prep_previous_pc",
            postgres_conn_id="hts_prep_conn",
            sql="call expanded_hts_prep.proc_prep_previous_pc()",
            autocommit=True)

        prep_current_pc = PostgresOperator(
            task_id="prep_current_pc",
            postgres_conn_id="hts_prep_conn",
            sql="call expanded_hts_prep.proc_prep_current_pc()",
            autocommit=True)
        
        
       
    end = BashOperator(
        task_id="end",
        bash_command="echo end")

    # Define the task dependencies
    start >> upstream_tasks >> end
