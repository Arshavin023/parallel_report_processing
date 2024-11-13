from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.providers.postgres.operators.postgres import PostgresOperator
from airflow.utils.task_group import TaskGroup
from datetime import datetime, timedelta

default_args = {
    "owner": "airflow",
    "email_on_failure": False,
    "email_on_retry": False,
    "email": "admin@localhost.com",
    "retries": 2,
    "retry_delay": timedelta(minutes=5)
}

with DAG("create_iptnew",start_date=datetime(2024, 10, 28),schedule_interval=None,
            default_args=default_args,catchup=True,max_active_runs=1,) as dag:

    start = BashOperator(
        task_id="start",
        bash_command="echo start"
    )
	
    with TaskGroup(group_id='upstream_tasks') as upstream_tasks:
    
        sub2_iptnew_tptc = PostgresOperator(
            task_id="sub2_iptnew_tptc",
            postgres_conn_id="lamisplus_conn",
            sql='call expanded_radet.proc_sub_iptnew_tptc()',
            autocommit=True
        )

        sub_iptnew_pts = PostgresOperator(
            task_id="sub_iptnew_pts",
            postgres_conn_id="lamisplus_conn",
            sql='call expanded_radet.proc_sub_iptnew_pts()',
            autocommit=True
        )

    with TaskGroup(group_id='midstream_tasks') as midstream_tasks:
        
        cte_iptnew = PostgresOperator(
            task_id="cte_iptnew",
            postgres_conn_id="lamisplus_conn",
            sql='call expanded_radet.proc_iptnew()',
            autocommit=True
        )

    end = BashOperator(
        task_id="end",
        bash_command="echo end"
    )

    # Define the task dependencies
    start >> upstream_tasks >> midstream_tasks >> end
