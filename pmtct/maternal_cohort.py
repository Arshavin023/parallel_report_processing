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



with DAG("maternal_cohort_quartely", start_date=datetime.datetime(2024, 7, 15), schedule_interval=None,
 default_args=default_args, catchup=True, max_active_runs=1) as dag:

    start = BashOperator(
        task_id="start",
        bash_command="echo start"
    )
    
    cte_target_pharmacies = PostgresOperator(
        task_id="cte_target_pharmacies",
        postgres_conn_id="lamisplus_conn",
        sql = 'call maternal_cohort.proc_target_pharmacies()',
        autocommit = True
    )

    cte_target_statuses = PostgresOperator(
        task_id="cte_target_statuses",
        postgres_conn_id="lamisplus_conn",
        sql = 'call maternal_cohort.proc_target_statuses()',
        autocommit = True
    )
    
    cte_hiv_observation = PostgresOperator(
        task_id="cte_hiv_observation",
        postgres_conn_id="lamisplus_conn",
        sql = 'call maternal_cohort.proc_hiv_observation()',
        autocommit = True
    )

    cte_result = PostgresOperator(
        task_id="cte_result",
        postgres_conn_id="lamisplus_conn",
        sql = 'call maternal_cohort.proc_result()',
        autocommit = True
    )


    cte_pmtct_anc = PostgresOperator(
        task_id="cte_pmtct_anc",
        postgres_conn_id="lamisplus_conn",
        sql = 'call maternal_cohort.proc_pmtct_anc()',
        autocommit = True
    )

    cte_pmtct_delivery = PostgresOperator(
        task_id="cte_pmtct_delivery",
        postgres_conn_id="lamisplus_conn",
        sql = 'call maternal_cohort.proc_pmtct_delivery()',
        autocommit = True
    )

    cte_pmtct_mother_visitation = PostgresOperator(
        task_id="cte_pmtct_mother_visitation",
        postgres_conn_id="lamisplus_conn",
        sql = 'call maternal_cohort.proc_pmtct_mother_visitation()',
        autocommit = True
    )

    cte_first = PostgresOperator(
        task_id="cte_first",
        postgres_conn_id="lamisplus_conn",
        sql = 'call maternal_cohort.proc_first()',
        autocommit = True
    )

    cte_second = PostgresOperator(
        task_id="cte_second",
        postgres_conn_id="lamisplus_conn",
        sql = 'call maternal_cohort.proc_second()',
        autocommit = True
    )

    cte_confirm = PostgresOperator(
        task_id="cte_confirm",
        postgres_conn_id="lamisplus_conn",
        sql = 'call maternal_cohort.proc_confirm()',
        autocommit = True
    )
    
    cte_pmtct_maternal_cohort_joined = PostgresOperator(
        task_id="cte_pmtct_maternal_cohort_joined",
        postgres_conn_id="lamisplus_conn",
        sql = 'call maternal_cohort.proc_pmtct_maternal_cohort_joined()',
        autocommit = True
    )
    
    pmtct_maternal_cohort = PostgresOperator(
        task_id="pmtct_maternal_cohort",
        postgres_conn_id="lamisplus_conn",
        sql = 'call maternal_cohort.proc_pmtct_maternal_cohort()',
        autocommit = True
    )

    end = BashOperator(
        task_id="end",
        bash_command="echo end"
    )

    start >> [cte_target_statuses, cte_target_pharmacies,cte_hiv_observation,cte_result,cte_pmtct_anc, cte_pmtct_delivery,
              cte_pmtct_mother_visitation,cte_first,cte_second,
              cte_confirm] >> cte_pmtct_maternal_cohort_joined >> pmtct_maternal_cohort >> end