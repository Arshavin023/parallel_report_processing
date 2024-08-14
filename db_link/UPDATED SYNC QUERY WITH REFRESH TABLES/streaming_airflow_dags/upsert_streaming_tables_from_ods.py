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

with DAG("upsert_streaming_for_radet",start_date=datetime.datetime(2024, 7, 1),schedule_interval=None,
            default_args=default_args,catchup=True,max_active_runs=1,) as dag:

    start = BashOperator(
        task_id="start",
        bash_command="echo start"
    ) 
    
    with TaskGroup(group_id='upstream_tasks') as upstream_tasks:
        
        upsert_tbstatus_tbscreening = PostgresOperator(
            task_id="upsert_tbstatus_tbscreening",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_upsert_tbstatus_tbscreening()',
            autocommit=True
        )
        
        upsert_pharmacy_details_regimen = PostgresOperator(
            task_id="upsert_pharmacy_details_regimen",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_upsert_pharmacy_details_regimen()',
            autocommit=True
        )
        
        upsert_base_biometric = PostgresOperator(
            task_id="upsert_base_biometric",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_upsert_base_biometric()',
            autocommit=True
        )

        upsert_recapture_biometric = PostgresOperator(
            task_id="upsert_recapture_biometric",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_upsert_recapture_biometric()',
            autocommit=True
        )

        upsert_patient_bio_data = PostgresOperator(
            task_id="upsert_patient_bio_data",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_upsert_patient_bio_data()',
            autocommit=True
        )

        upsert_carecardcd4 = PostgresOperator(
            task_id="upsert_carecardcd4",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_upsert_carecardcd4()',
            autocommit=True
        )

        upsert_cervical_cancer = PostgresOperator(
            task_id="upsert_cervical_cancer",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_upsert_cervical_cancer()',
            autocommit=True
        )

        upsert_client_verification = PostgresOperator(
            task_id="upsert_client_verification",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_upsert_client_verification()',
            autocommit=True
        )

        upsert_cryptocol_antigen = PostgresOperator(
            task_id="upsert_cryptocol_antigen",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_upsert_cryptocol_antigen()',
            autocommit=True
        )
		
    end = BashOperator(
        task_id="end",
        bash_command="echo end"
    )

    # Define the task dependencies
    start >> upstream_tasks >> end