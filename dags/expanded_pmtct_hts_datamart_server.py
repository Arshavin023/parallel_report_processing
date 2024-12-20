from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from airflow.providers.postgres.operators.postgres import PostgresOperator
from airflow.models import Variable
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



with DAG("lamisplus_pmtct_hts_datamart_server", start_date=datetime.datetime(2024, 7, 15), schedule_interval=None,
 default_args=default_args, catchup=True, max_active_runs=1) as dag:

    start = BashOperator(
        task_id="start",
        bash_command="echo start"
    )
    
    update_pmtct_hts_period_table = PostgresOperator(
            task_id="update_pmtct_hts_period_table",
            postgres_conn_id="pmtct_conn",
            sql = 'call pmtct_hts.proc_update_pmtct_hts_period_table()',
            autocommit = True
        )
    with TaskGroup(group_id='upstream_tasks') as upstream_tasks:        
        cte_hts_client = PostgresOperator(
            task_id="cte_hts_client",
            postgres_conn_id="pmtct_conn",
            sql = 'call pmtct_hts.proc_hts_client()',
            autocommit = True
        )

        cte_pmtct_anc = PostgresOperator(
            task_id="cte_pmtct_anc",
            postgres_conn_id="pmtct_conn",
            sql = 'call pmtct_hts.proc_pmtct_anc()',
            autocommit = True
        )

        cte_pmtct_delivery = PostgresOperator(
            task_id="cte_pmtct_delivery",
            postgres_conn_id="pmtct_conn",
            sql = 'call pmtct_hts.proc_pmtct_delivery()',
            autocommit = True
        )

        cte_result = PostgresOperator(
            task_id="cte_result",
            postgres_conn_id="pmtct_conn",
            sql = 'call pmtct_hts.proc_result()',
            autocommit = True
        )
    
    cte_pmtct_hts_joined = PostgresOperator(
        task_id="cte_pmtct_hts_joined",
        postgres_conn_id="pmtct_conn",
        sql = 'call pmtct_hts.proc_pmtct_hts_joined()',
        autocommit = True
    )
    
    pmtct_hts = PostgresOperator(
        task_id="pmtct_hts",
        postgres_conn_id="pmtct_conn",
        sql = 'call pmtct_hts.proc_pmtct_hts()',
        autocommit = True
    )

    end = BashOperator(
        task_id="end",
        bash_command="echo end"
    )

    start >> update_pmtct_hts_period_table >> upstream_tasks >> cte_pmtct_hts_joined >> pmtct_hts >> end
