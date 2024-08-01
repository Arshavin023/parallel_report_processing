from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from airflow.providers.postgres.operators.postgres import PostgresOperator
from airflow.models import Variable

import datetime

default_args = {
    "owner": "airflow",
    "email_on_failure": False,
    "email_on_retry": False,
    "email": "admin@localhost.com",
    "retries": 2,
    "retry_delay": datetime.timedelta(minutes=5)
}


with DAG("patient_clinic_results", start_date=datetime.datetime(2024, 6, 19), schedule_interval=None,
 default_args=default_args, catchup=True, max_active_runs=1) as dag:

    start = BashOperator(
        task_id="start",
        bash_command="echo start"
    )
    
    cte_ods_patient_person = PostgresOperator(
        task_id="cte_ods_patient_person",
        postgres_conn_id="lamisplus_conn",
        sql = 'call clinic.proc_ods_patient_person()',
        autocommit = True
    )
    
    cte_ods_base_application_codeset = PostgresOperator(
        task_id="cte_ods_base_application_codeset",
        postgres_conn_id="lamisplus_conn",
        sql = 'call clinic.proc_ods_base_application_codeset()',
        autocommit = True
    )

    cte_ods_triage_vital_sign = PostgresOperator(
        task_id="cte_ods_triage_vital_sign",
        postgres_conn_id="lamisplus_conn",
        sql = 'call clinic.proc_ods_triage_vital_sign()',
        autocommit = True
    )
    
    cte_ods_hiv_art_clinical = PostgresOperator(
        task_id="cte_ods_hiv_art_clinical",
        postgres_conn_id="lamisplus_conn",
        sql = 'call clinic.proc_ods_hiv_art_clinical()',
        autocommit = True
    )
    
    cte_clinic_query = PostgresOperator(
        task_id="cte_clinic_query",
        postgres_conn_id="lamisplus_conn",
        sql = 'call clinic.proc_clinic_query()',
        autocommit = True
    )
    
    end = BashOperator(
        task_id="end",
        bash_command="echo end"
    )

    start >> [cte_ods_patient_person,cte_ods_base_application_codeset,cte_ods_triage_vital_sign, cte_ods_hiv_art_clinical] >> cte_clinic_query >> end
