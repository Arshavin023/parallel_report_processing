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



with DAG("patients_laboratory_vl", start_date=datetime.datetime(2024, 6, 19), schedule_interval=None,
 default_args=default_args, catchup=True, max_active_runs=1) as dag:

    start = BashOperator(
        task_id="start",
        bash_command="echo start"
    )
    
    cte_ods_patient_person = PostgresOperator(
        task_id="cte_ods_patient_person",
        postgres_conn_id="lamisplus_conn",
        sql = 'call hackathon.proc_ods_patient_person()',
        autocommit = True
    )
    
    cte_ods_laboratory_test = PostgresOperator(
        task_id="cte_ods_laboratory_test",
        postgres_conn_id="lamisplus_conn",
        sql = 'call hackathon.proc_ods_laboratory_test()',
        autocommit = True
    )

    cte_ods_laboratory_result = PostgresOperator(
        task_id="cte_ods_laboratory_result",
        postgres_conn_id="lamisplus_conn",
        sql = 'call hackathon.proc_ods_laboratory_result()',
        autocommit = True
    )
    
    cte_ods_laboratory_sample = PostgresOperator(
        task_id="cte_ods_laboratory_sample",
        postgres_conn_id="lamisplus_conn",
        sql = 'call hackathon.proc_ods_laboratory_sample()',
        autocommit = True
    )
    
    
    cte_ods_laboratory_labtest = PostgresOperator(
        task_id="cte_ods_laboratory_labtest",
        postgres_conn_id="lamisplus_conn",
        sql = 'call hackathon.proc_ods_laboratory_labtest()',
        autocommit = True
    )
    
    cte_laboratory_tests = PostgresOperator(
        task_id="cte_laboratory_tests",
        postgres_conn_id="lamisplus_conn",
        sql = 'call hackathon.proc_laboratory_tests()',
        autocommit = True
    )
    
    cte_laboratory_viral_load = PostgresOperator(
        task_id="cte_laboratory_viral_load",
        postgres_conn_id="lamisplus_conn",
        sql = 'call hackathon.proc_laboratory_viral_load()',
        autocommit = True
    )

    end = BashOperator(
        task_id="end",
        bash_command="echo end"
    )

    start >> [cte_ods_laboratory_test, cte_ods_laboratory_result, cte_ods_laboratory_sample,
              cte_ods_patient_person, cte_ods_laboratory_labtest] >> cte_laboratory_tests >> cte_laboratory_viral_load >> end
