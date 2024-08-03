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

with DAG("remaining_final_radet_quartely", start_date=datetime.datetime(2024, 7, 1), schedule_interval=None,
            default_args=default_args, catchup=True, max_active_runs=1) as dag:

    start = BashOperator(
        task_id="start",
        bash_command="echo start"
    )
    
    cte_bio_data = PostgresOperator(
        task_id="cte_bio_data",
        postgres_conn_id="lamisplus_conn",
        sql = 'call expanded_radet.proc_bio_data()',
        autocommit = True
    )

    sub_cte_current_vl_result = PostgresOperator(
        task_id="sub_cte_current_vl_result",
        postgres_conn_id="lamisplus_conn",
        sql = 'call expanded_radet.proc_sub_current_vl_result()',
        autocommit = True
    ) 
    
    cte_previous_previous = PostgresOperator(
        task_id="cte_previous_previous",
        postgres_conn_id="lamisplus_conn",
        sql = 'call expanded_radet.proc_previous_previous()',
        autocommit = True
    )

    cte_previous = PostgresOperator(
        task_id="cte_previous",
        postgres_conn_id="lamisplus_conn",
        sql = 'call expanded_radet.proc_previous()',
        autocommit = True
    )

    cte_current_status = PostgresOperator(
        task_id="cte_current_status",
        postgres_conn_id="lamisplus_conn",
        sql = 'call expanded_radet.proc_current_status()',
        autocommit = True
    )
    
    cte_tbstatus_tbscreening_cs = PostgresOperator(
        task_id="cte_tbstatus_tbscreening_cs",
        postgres_conn_id="lamisplus_conn",
        sql = 'call expanded_radet.proc_tbstatus_tbscreening_cs()',
        autocommit = True
    )
       
    cte_current_vl_result = PostgresOperator(
        task_id="cte_current_vl_result",
        postgres_conn_id="lamisplus_conn",
        sql = 'call expanded_radet.proc_current_vl_result()',
        autocommit = True
    )
    
    
    cte_naive_vl_data = PostgresOperator(
        task_id="cte_naive_vl_data",
        postgres_conn_id="lamisplus_conn",
        sql = 'call expanded_radet.proc_naive_vl_data()',
        autocommit = True
    )
    
    cte_current_clinical = PostgresOperator(
        task_id="cte_current_clinical",
        postgres_conn_id="lamisplus_conn",
        sql = 'call expanded_radet.proc_current_clinical()',
        autocommit = True
    )    

    cte_tbstatus = PostgresOperator(
        task_id="cte_tbstatus",
        postgres_conn_id="lamisplus_conn",
        sql = 'call expanded_radet.proc_tbstatus()',
        autocommit = True
    )
    
    cte_ipt = PostgresOperator(
        task_id="cte_ipt",
        postgres_conn_id="lamisplus_conn",
        sql = 'call expanded_radet.proc_ipt()',
        autocommit = True
    )

    radet_joined = PostgresOperator(
        task_id="radet_joined",
        postgres_conn_id="lamisplus_conn",
        sql = 'call expanded_radet.proc_radet_joined()',
        autocommit = True
    )

    final_radet_quartely = PostgresOperator(
        task_id="final_radet_quartely",
        postgres_conn_id="lamisplus_conn",
        sql = 'call public.proc_final_radet_quartely()',
        autocommit = True
    )

    end = BashOperator(
        task_id="end",
        bash_command="echo end"
    )

    start >> [cte_bio_data,sub_cte_current_vl_result,cte_previous_previous,cte_previous,cte_current_status,
             cte_tbstatus_tbscreening_cs] >> cte_current_vl_result >> cte_naive_vl_data >> cte_current_clinical >> cte_tbstatus >> cte_ipt >> radet_joined >> final_radet_quartely >> end


