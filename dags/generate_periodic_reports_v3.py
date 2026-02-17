from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from airflow.providers.postgres.operators.postgres import PostgresOperator
import datetime
from datetime import datetime, timedelta
from airflow.utils.task_group import TaskGroup
import sys
import os
from lamisplus_funcs import stg_to_ods as lamisplus_funcs
from lamisplus_funcs.airflow_api import trigger_dag
# sys.path.append('/home/lamisplus/airflow/lamisplus_funcs')
from lamisplus_report_funcs.maternalcohort_report import maternalcohort
from lamisplus_report_funcs.pmtcthts_report import pmtcthts
from lamisplus_report_funcs.preplongitudinal_report import preplongitudinal
from lamisplus_report_funcs.radet_report import pre_prepre, radet_v2
from lamisplus_report_funcs.prep_report import prep_v2
from lamisplus_report_funcs.hts_report import hts
from lamisplus_report_funcs.tb_report import tb
from lamisplus_report_funcs.familypartnerindex_report  import familypartnerindex
from lamisplus_report_funcs.ahd_report import ahd_v2
from lamisplus_report_funcs.biometric_report import biometric
from lamisplus_report_funcs.eac_report import eac


def run_maternalcohort_report(**kwargs):
    periods = kwargs.get('params', {}).get('periods')
    if not periods:
        raise ValueError("No 'periods' provided in DAG params.")
    if isinstance(periods, str):
        periods = [periods]
    maternalcohort.generate_maternalcohort_report(periods=periods)

def run_pmtcthts_report(**kwargs):
    periods = kwargs.get('params', {}).get('periods')
    if not periods:
        raise ValueError("No 'periods' provided in DAG params.")
    if isinstance(periods, str):
        periods = [periods]
    pmtcthts.generate_pmtcthts_report(periods=periods)

def run_preplongitudinal_report(**kwargs):
    periods = kwargs.get('params', {}).get('periods')
    if not periods:
        raise ValueError("No 'periods' provided in DAG params.")
    if isinstance(periods, str):
        periods = [periods]
    preplongitudinal.generate_preplongitudinal_report(periods=periods)

def run_hts_report(**kwargs):
    periods = kwargs.get('params', {}).get('periods')
    if not periods:
        raise ValueError("No 'periods' provided in DAG params.")
    if isinstance(periods, str):
        periods = [periods]
    hts.generate_hts_report(periods=periods)

def run_prep_report(**kwargs):
    periods = kwargs.get('params', {}).get('periods')
    if not periods:
        raise ValueError("No 'periods' provided in DAG params.")
    if isinstance(periods, str):
        periods = [periods]
    prep_v2.generate_prep_report(periods=periods)

def run_familypartnerindex_report(**kwargs):
    periods = kwargs.get('params', {}).get('periods')
    if not periods:
        raise ValueError("No 'periods' provided in DAG params.")
    if isinstance(periods, str):
        periods = [periods]
    familypartnerindex.generate_familypartnerindex_report(periods=periods)

def run_radet_report(**kwargs):
    periods = kwargs.get('params', {}).get('periods')
    if not periods:
        raise ValueError("No 'periods' provided in DAG params.")
    if isinstance(periods, str):
        periods = [periods]
    radet_v2.generate_radet_report(periods=periods)

def run_prepre_report(**kwargs):
    periods = kwargs.get('params', {}).get('periods')
    if not periods:
        raise ValueError("No 'periods' provided in DAG params.")
    if isinstance(periods, str):
        periods = [periods]
    pre_prepre.generate_pre_prepre_report(periods=periods)

def run_tb_report(**kwargs):
    periods = kwargs.get('params', {}).get('periods')
    if not periods:
        raise ValueError("No 'periods' provided in DAG params.")
    if isinstance(periods, str):
        periods = [periods]
    tb.generate_tb_report(periods=periods)

def run_eac_report(**kwargs):
    periods = kwargs.get('params', {}).get('periods')
    if not periods:
        raise ValueError("No 'periods' provided in DAG params.")
    if isinstance(periods, str):
        periods = [periods]
    eac.generate_eac_report(periods=periods)

def run_ahd_report(**kwargs):
    periods = kwargs.get('params', {}).get('periods')
    if not periods:
        raise ValueError("No 'periods' provided in DAG params.")
    if isinstance(periods, str):
        periods = [periods]
    ahd_v2.generate_ahd_report(periods=periods)

def run_biometric_report(**kwargs):
    periods = kwargs.get('params', {}).get('periods')
    if not periods:
        raise ValueError("No 'periods' provided in DAG params.")
    if isinstance(periods, str):
        periods = [periods]
    biometric.generate_biometric_report(periods=periods)

default_args = {
    "owner": "airflow",
    "email_on_failure": False,
    "email_on_retry": False,
    "email": "admin@localhost.com",
    "retries": 3,
    "retry_delay": timedelta(minutes=5)
}

with DAG("generate_periodic_reports_v3", start_date=datetime(2025, 5, 18),
         schedule_interval=None,
         default_args=default_args,catchup=False,
         params={"periods": None},
         max_active_runs=1,
         tags=["reports", "periodic", "lamisplus"]
         ) as dag:

    start = BashOperator(
        task_id="start",
        bash_command="echo start"
    ) 

    update_prep_period = PostgresOperator(
        task_id="update_prep_period",
        postgres_conn_id="lamisplus_conn",
        sql = 'call prep.proc_update_prep_period_table({{ params.periods }});',
        autocommit = True
    )

    update_radet_period = PostgresOperator(
        task_id="update_radet_period",
        postgres_conn_id="lamisplus_conn",
        sql = 'call expanded_radet.proc_update_expanded_radet_period_table({{ params.periods }});',
        autocommit = True
    )

    #prep_task = PythonOperator(
    #    task_id="prep",
    #    python_callable=run_prep_report,
    #    provide_context=True,
    #)
    
    with TaskGroup(group_id='generate_first_report_batch') as generate_first_report_batch:
        #maternalcohort_task = PythonOperator(
        #    task_id="maternalcohort",
        #    python_callable=run_maternalcohort_report,
        #    provide_context=True,
        #)
        ahd_v2_task = PythonOperator(
            task_id="ahd_v2",
            python_callable=run_ahd_report,
            provide_context=True,
        )
        #preplongitudinal_task = PythonOperator(
        #    task_id="preplongitudinal",
        #    python_callable=run_preplongitudinal_report,
        #    provide_context=True,
        #)
    
    #with TaskGroup(group_id='generate_second_report_batch') as generate_second_report_batch:
    #    familypartnerindex_task = PythonOperator(
    #        task_id="familypartnerindex",
    #        python_callable=run_familypartnerindex_report,
    #        provide_context=True,
    #    )
    #    hts_task = PythonOperator(
    #        task_id="hts",
    #        python_callable=run_hts_report,
    #        provide_context=True,
    #    )
    #    eac_task = PythonOperator(
    #        task_id="eac",
    #        python_callable=run_eac_report,
    #        provide_context=True,
    #    )
    
    #with TaskGroup(group_id='generate_third_report_batch') as generate_third_report_batch:
    #    prep_task = PythonOperator(
    #        task_id="prep",
    #        python_callable=run_prep_report,
    #        provide_context=True,
    #    )
    #    eac_task = PythonOperator(
    #        task_id="eac",
    #        python_callable=run_eac_report,
    #        provide_context=True,
    #    )
    #    biometric_task = PythonOperator(
    #        task_id="biometric",
    #        python_callable=run_biometric_report,
    #        provide_context=True,
    #    )

    #with TaskGroup(group_id='generate_fourth_report_batch') as generate_fourth_report_batch:
    #    tb_task = PythonOperator(
    #        task_id="tb",
    #        python_callable=run_tb_report,
    #        provide_context=True,
    #    )
    
    end = BashOperator(
        task_id="end",
        bash_command="echo end")

    # Define the task dependencies
    start >> update_radet_period >> update_prep_period >> generate_first_report_batch >> end
