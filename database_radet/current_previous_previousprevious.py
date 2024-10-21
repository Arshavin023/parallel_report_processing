from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.providers.postgres.operators.postgres import PostgresOperator
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

with DAG("current_previous_previousprevious",start_date=datetime.datetime(2024, 7, 1),schedule_interval=None,
            default_args=default_args,catchup=True,max_active_runs=1,) as dag:

    start = BashOperator(
        task_id="start",
        bash_command="echo start"
    )
    
    with TaskGroup(group_id='upstream_tasks') as upstream_tasks:
    
        cte_previous_previous = PostgresOperator(
            task_id="cte_previous_previous",
            postgres_conn_id="lamisplus_conn",
            sql='call expanded_radet.proc_previous_previous()',
            autocommit=True
        )

        cte_previous = PostgresOperator(
            task_id="cte_previous",
            postgres_conn_id="lamisplus_conn",
            sql='call expanded_radet.proc_previous()',
            autocommit=True
        )
       
        cte_current_status = PostgresOperator(
            task_id="cte_current_status",
            postgres_conn_id="lamisplus_conn",
            sql='call expanded_radet.proc_current_status()',
            autocommit=True
        )

    end = BashOperator(
        task_id="end",
        bash_command="echo end"
    )

    # Define the task dependencies
    start >> upstream_tasks >> end
