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

with DAG("regenerate_sub_cte_current_vl_result",start_date=datetime.datetime(2024, 7, 1),schedule_interval=None,
            default_args=default_args,catchup=True,max_active_runs=1,) as dag:

    start = BashOperator(
        task_id="start",
        bash_command="echo start"
    )
    
    sub_cte_current_vl_result = PostgresOperator(
            task_id="sub_cte_current_vl_result",
            postgres_conn_id="lamisplus_conn",
            sql='call expanded_radet.proc_sub_current_vl_result()',
            autocommit=True)
		
	end = BashOperator(
        task_id="end",
        bash_command="echo end"
    )

    # Define the task dependencies
    start >> sub_cte_current_vl_result >> end
