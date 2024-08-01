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


with DAG("patients_pharmacy_results", start_date=datetime.datetime(2024, 6, 19), schedule_interval=None,
 default_args=default_args, catchup=True, max_active_runs=1) as dag:

    start = BashOperator(
        task_id="start",
        bash_command="echo start"
    )
    
    cte_ods_patient_person = PostgresOperator(
        task_id="cte_ods_patient_person",
        postgres_conn_id="lamisplus_conn",
        sql = 'call pharmacy.proc_ods_patient_person()',
        autocommit = True
    )
    
    cte_ods_dsd_devolvement = PostgresOperator(
        task_id="cte_ods_dsd_devolvement",
        postgres_conn_id="lamisplus_conn",
        sql = 'call pharmacy.proc_ods_dsd_devolvement()',
        autocommit = True
    )

    cte_ods_hiv_regimen = PostgresOperator(
        task_id="cte_ods_hiv_regimen",
        postgres_conn_id="lamisplus_conn",
        sql = 'call pharmacy.proc_ods_hiv_regimen()',
        autocommit = True
    )
    
    cte_ods_hiv_regimen_type = PostgresOperator(
        task_id="cte_ods_hiv_regimen_type",
        postgres_conn_id="lamisplus_conn",
        sql = 'call pharmacy.proc_ods_hiv_regimen_type()',
        autocommit = True
    )
    
    cte_pharmacy_result = PostgresOperator(
        task_id="cte_pharmacy_result",
        postgres_conn_id="lamisplus_conn",
        sql = 'call pharmacy.proc_pharmacy_result()',
        autocommit = True
    )
    
    cte_pharmacy_query = PostgresOperator(
        task_id="cte_pharmacy_query",
        postgres_conn_id="lamisplus_conn",
        sql = 'call pharmacy.proc_pharmacy_query()',
        autocommit = True
    )

    end = BashOperator(
        task_id="end",
        bash_command="echo end"
    )

    start >> [cte_ods_patient_person,cte_ods_dsd_devolvement,cte_ods_hiv_regimen, cte_ods_hiv_regimen_type,
             cte_pharmacy_result] >> cte_pharmacy_query >> end
