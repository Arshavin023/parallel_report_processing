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

with DAG("lamisplus_previous_and_prepre_status",start_date=datetime.datetime(2024, 7, 1),schedule_interval=None,
            default_args=default_args,catchup=True,max_active_runs=1,) as dag:

    start = BashOperator(
        task_id="start",
        bash_command="echo start"
    ) 
    
    with TaskGroup(group_id='upstream_tasks') as upstream_tasks:
    
        pharmacy_previous_status = PostgresOperator(
            task_id="pharmacy_previous_status",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_pharmacy_previous_status()',
            autocommit=True
        )
        pharmacy_previous_previous_status = PostgresOperator(
            task_id="pharmacy_previous_previous_status",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_pharmacy_previous_previous_status()',
            autocommit=True
        )
        sub2_stat_previous_status = PostgresOperator(
            task_id="sub2_stat_previous_status",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_sub2_stat_previous_status()',
            autocommit=True
        )
        sub2_stat_previous_previous_status = PostgresOperator(
            task_id="sub2_stat_previous_previous_status",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_sub2_stat_previous_previous_status()',
            autocommit=True)
        
    with TaskGroup(group_id='midstream_tasks') as midstream_tasks:
    
        previous_previous_status = PostgresOperator(
            task_id="previous_previous_status",
            postgres_conn_id="radet_conn",
            sql="call expanded_radet.proc_previous_prep_status('2024Q3')",
            autocommit=True
        )
        
        previous_status = PostgresOperator(
            task_id="previous_status",
            postgres_conn_id="radet_conn",
            sql="call expanded_radet.proc_previous_prep_status('2024Q4')",
            autocommit=True
        )
		
    end = BashOperator(
        task_id="end",
        bash_command="echo end")

    # Define the task dependencies
    start >> upstream_tasks >> midstream_tasks >> end
