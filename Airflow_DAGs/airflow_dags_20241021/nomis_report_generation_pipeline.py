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

with DAG("nomis_report_generation",start_date=datetime.datetime(2024, 10, 15),schedule_interval=None,
            default_args=default_args,catchup=True,max_active_runs=1,) as dag:

    start = BashOperator(
        task_id="start",
        bash_command="echo start"
    ) 
    
    with TaskGroup(group_id='upstream_tasks') as upstream_tasks:
        
        household_info = PostgresOperator(
            task_id="household_info",
            postgres_conn_id="nomis_datamart_conn",
            sql='call public.proc_household_info()',
            autocommit=True
        )
        
        sub_bio_data = PostgresOperator(
            task_id="sub_bio_data",
            postgres_conn_id="nomis_datamart_conn",
            sql='call public.proc_sub_bio_data()',
            autocommit=True
        )
        
        household_summary = PostgresOperator(
            task_id="household_summary",
            postgres_conn_id="nomis_datamart_conn",
            sql='call public.proc_household_summary()',
            autocommit=True
        )
        
        caregiver_info = PostgresOperator(
            task_id="caregiver_info",
            postgres_conn_id="nomis_datamart_conn",
            sql='call public.proc_caregiver_info()',
            autocommit=True
        )
        
        vc_enrollment = PostgresOperator(
            task_id="vc_enrollment",
            postgres_conn_id="nomis_datamart_conn",
            sql='call public.proc_vc_enrollment()',
            autocommit=True
        )
        
        vl_result = PostgresOperator(
            task_id="vl_result",
            postgres_conn_id="nomis_datamart_conn",
            sql='call public.proc_vl_result()',
            autocommit=True
        )
        
        hiv_summary = PostgresOperator(
            task_id="hiv_summary",
            postgres_conn_id="nomis_datamart_conn",
            sql='call public.proc_hiv_summary()',
            autocommit=True
        )
        
    with TaskGroup(group_id='midstream_tasks') as midstream_tasks:
        
        bio_data = PostgresOperator(
            task_id="bio_data",
            postgres_conn_id="nomis_datamart_conn",
            sql='call public.proc_bio_data()',
            autocommit=True
        )
		
    end = BashOperator(
        task_id="end",
        bash_command="echo end"
    )
    # Define the task dependencies
    start >> upstream_tasks >> midstream_tasks >> end
