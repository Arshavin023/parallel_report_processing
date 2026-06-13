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

with DAG("lamisplus_refresh_reports_v2",start_date=datetime.datetime(2026, 3, 7),schedule_interval=None,
            default_args=default_args,catchup=True,max_active_runs=1,tags=["refresh_tables", "lamisplus","daily"]) as dag:

    start = BashOperator(
        task_id="start",
        bash_command="echo start"
    ) 
    
    with TaskGroup(group_id='upstream_tasks') as upstream_tasks:
        
        upsert_pharmacy_details_regimen_v3 = PostgresOperator(
            task_id="upsert_pharmacy_details_regimen_v4",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_upsert_pharmacy_details_regimen_v4()',
            autocommit=True
        )

        upsert_patient_bio_data = PostgresOperator(
            task_id="upsert_patient_bio_data_v2",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_upsert_patient_bio_data_v2()',
            autocommit=True
        )
        
        upsert_client_verification_v2 = PostgresOperator(
            task_id="upsert_client_verification_v3",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_upsert_client_verification_v3()',
            autocommit=True
        )
        
        upsert_clinic_data = PostgresOperator(
            task_id="upsert_clinic_data_v2",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_upsert_clinic_data_v2()',
            autocommit=True
        )
        
        upsert_baseappcodeset_radetdb = PostgresOperator(
            task_id="upsert_baseappcodeset_radetdb",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_upsert_baseappcodeset()',
            autocommit=True
        )

        upsert_temp_laboratorytestresults = PostgresOperator(
            task_id="upsert_temp_laboratorytestresults",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_upsert_temp_laboratorytestresults()',
            autocommit=True
        )

    with TaskGroup(group_id='midstream_tasks') as midstream_tasks:
        upsert_laboratorytestresults_v2 = PostgresOperator(
            task_id="upsert_laboratorytestresults_v2",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_upsert_laboratorytestresults_v2()',
            autocommit=True
        )
        
        upsert_client_verification = PostgresOperator(
            task_id="upsert_client_verification",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_upsert_client_verification()',
            autocommit=True
        )
        
    with TaskGroup(group_id='downstream_tasks') as downstream_tasks:
        upsert_tblongitudinal_v3 = PostgresOperator(
            task_id="upsert_tblongitudinal_v3",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_upsert_tblongitudinal_v3()',
            autocommit=True
        )

    end = BashOperator(
        task_id="end",
        bash_command="echo end"
    )
    # Define the task dependencies
    start >> upstream_tasks >> midstream_tasks >> downstream_tasks >> end
