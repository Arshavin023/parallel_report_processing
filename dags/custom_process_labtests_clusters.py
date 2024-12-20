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

with DAG("lamisplus_custom_process_labtests_clusters",start_date=datetime.datetime(2024, 7, 1),schedule_interval=None,
            default_args=default_args,catchup=True,max_active_runs=1,) as dag:

    start = BashOperator(
        task_id="start",
        bash_command="echo start"
    ) 
    
    with TaskGroup(group_id='upstream_tasks') as upstream_tasks:
    
        loop_through_labresults1 = PostgresOperator(
            task_id="loop_through_labresults1",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_loop_through_labresults1()',
            autocommit=True)
        
        loop_through_labresults9 = PostgresOperator(
            task_id="loop_through_labresults9",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_loop_through_labresults9()',
            autocommit=True)
        
        loop_through_labresults10 = PostgresOperator(
            task_id="loop_through_labresults10",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_loop_through_labresults10()',
            autocommit=True)
        
        loop_through_labresults11 = PostgresOperator(
            task_id="loop_through_labresults11",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_loop_through_labresults11()',
            autocommit=True)
        
        loop_through_labresults12 = PostgresOperator(
            task_id="loop_through_labresults12",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_loop_through_labresults12()',
            autocommit=True)
        
        loop_through_labresults13 = PostgresOperator(
            task_id="loop_through_labresults13",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_loop_through_labresults13()',
            autocommit=True)
        
        loop_through_labresults14 = PostgresOperator(
            task_id="loop_through_labresults14",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_loop_through_labresults14()',
            autocommit=True)
        
        loop_through_labresults15 = PostgresOperator(
            task_id="loop_through_labresults15",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_loop_through_labresults15()',
            autocommit=True)
        
       
    end = BashOperator(
        task_id="end",
        bash_command="echo end")

    # Define the task dependencies
    start >> upstream_tasks >> end
