from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from airflow.providers.postgres.operators.postgres import PostgresOperator
from airflow.models import Variable
from airflow.sensors.external_task import ExternalTaskSensor
import datetime


default_args = {
    "owner": "airflow",
    "email_on_failure": False,
    "email_on_retry": False,
    "email": "admin@localhost.com",
    "retries": 2,
    "retry_delay": datetime.timedelta(minutes=5)
}

with DAG("hts_prep_quartely", start_date=datetime.datetime(2024, 7, 1), schedule_interval=None,
         default_args=default_args,
         catchup=False, max_active_runs=1) as dag:

    start = BashOperator(
        task_id="start",
        bash_command="echo start"
    )
    
    update_period_table = PostgresOperator(
        task_id="update_period_table",
        postgres_conn_id="lamisplus_conn",
        sql = 'call expanded_hts_prep.proc_update_expanded_hts_prep_period_table()',
        autocommit = True
    )
    

    prep_current_pc = PostgresOperator(
        task_id="prep_current_pc",
        postgres_conn_id="lamisplus_conn",
        sql = 'call expanded_hts_prep.proc_prep_current_pc()',
        autocommit = True
    )

    prep_baseline_pc = PostgresOperator(
        task_id="prep_baseline_pc",
        postgres_conn_id="lamisplus_conn",
        sql = 'call expanded_hts_prep.proc_prep_baseline_pc()',
        autocommit = True
    )

    prep_baseline_bp = PostgresOperator(
        task_id="prep_baseline_bp",
        postgres_conn_id="lamisplus_conn",
        sql = 'call expanded_hts_prep.proc_prep_baseline_bp()',
        autocommit = True
    )

    prep_baseline_hbpcv = PostgresOperator(
        task_id="prep_baseline_hbpcv",
        postgres_conn_id="lamisplus_conn",
        sql = 'call expanded_hts_prep.proc_prep_baseline_hbpcv()',
        autocommit = True
    )

    prep_baseline_urinalysis = PostgresOperator(
        task_id="prep_baseline_urinalysis",
        postgres_conn_id="lamisplus_conn",
        sql = 'call expanded_hts_prep.proc_prep_baseline_urinalysis()',
        autocommit = True
    )

    prep_baseline_creatinine = PostgresOperator(
        task_id="prep_baseline_creatinine",
        postgres_conn_id="lamisplus_conn",
        sql = 'call expanded_hts_prep.proc_prep_baseline_creatinine()',
        autocommit = True
    )

    prep_baseline_alt = PostgresOperator(
        task_id="prep_baseline_alt",
        postgres_conn_id="lamisplus_conn",
        sql = 'call expanded_hts_prep.proc_prep_baseline_alt()',
        autocommit = True
    )

    prep_baseline_hbsag = PostgresOperator(
        task_id="prep_baseline_hbsag",
        postgres_conn_id="lamisplus_conn",
        sql = 'call expanded_hts_prep.proc_prep_baseline_hbsag()',
        autocommit = True
    )

    prep_baseline_wbc = PostgresOperator(
        task_id="prep_baseline_wbc",
        postgres_conn_id="lamisplus_conn",
        sql = 'call expanded_hts_prep.proc_prep_baseline_wbc()',
        autocommit = True
    )

    prep_current_hbsag = PostgresOperator(
        task_id="prep_current_hbsag",
        postgres_conn_id="lamisplus_conn",
        sql = 'call expanded_hts_prep.proc_prep_current_hbsag()',
        autocommit = True
    )

    prep_current_hbpcv = PostgresOperator(
        task_id="prep_current_hbpcv",
        postgres_conn_id="lamisplus_conn",
        sql = 'call expanded_hts_prep.proc_prep_current_hbpcv()',
        autocommit = True
    )

    prep_current_wbc = PostgresOperator(
        task_id="prep_current_wbc",
        postgres_conn_id="lamisplus_conn",
        sql = 'call expanded_hts_prep.proc_prep_current_wbc()',
        autocommit = True
    )

    prep_prepi = PostgresOperator(
        task_id="prep_prepi",
        postgres_conn_id="lamisplus_conn",
        sql = 'call expanded_hts_prep.proc_prep_prepi()',
        autocommit = True
    )

    prep_prepc = PostgresOperator(
        task_id="prep_prepc",
        postgres_conn_id="lamisplus_conn",
        sql = 'call expanded_hts_prep.proc_prep_prepc()',
        autocommit = True
    )

    prep_eli_test = PostgresOperator(
        task_id="prep_eli_test",
        postgres_conn_id="lamisplus_conn",
        sql = 'call expanded_hts_prep.proc_prep_eli_test()',
        autocommit = True
    )

    prep_base_eli_test = PostgresOperator(
        task_id="prep_base_eli_test",
        postgres_conn_id="lamisplus_conn",
        sql = 'call expanded_hts_prep.proc_prep_base_eli_test()',
        autocommit = True
    )

    prep_bio = PostgresOperator(
        task_id="prep_bio",
        postgres_conn_id="lamisplus_conn",
        sql = 'call expanded_hts_prep.proc_prep_bio()',
        autocommit = True
    )

    prep_e_target = PostgresOperator(
        task_id="prep_e_target",
        postgres_conn_id="lamisplus_conn",
        sql = 'call expanded_hts_prep.proc_prep_e_target()',
        autocommit = True
    )

    prep_penrol = PostgresOperator(
        task_id="prep_penrol",
        postgres_conn_id="lamisplus_conn",
        sql = 'call expanded_hts_prep.proc_prep_penrol()',
        autocommit = True
    )

    prep_current_alt = PostgresOperator(
        task_id="prep_current_alt",
        postgres_conn_id="lamisplus_conn",
        sql = 'call expanded_hts_prep.proc_prep_current_alt()',
        autocommit = True
    )
    
    hts_joined = PostgresOperator(
        task_id="hts_joined",
        postgres_conn_id="lamisplus_conn",
        sql = 'call expanded_hts_prep.proc_expanded_hts_joined()',
        autocommit = True
    )

    final_hts = PostgresOperator(
        task_id="final_hts",
        postgres_conn_id="lamisplus_conn",
        sql = 'call hts_prep.proc_final_hts()',
        autocommit = True
    )
    
    final_prep = PostgresOperator(
        task_id="final_prep",
        postgres_conn_id="lamisplus_conn",
        sql = 'call hts_prep.proc_final_prep()',
        autocommit = True
    )

    

    end = BashOperator(
        task_id="end",
        bash_command="echo end"
    )


    start >> update_period_table >> [prep_current_pc,prep_baseline_pc,prep_baseline_bp,prep_baseline_urinalysis, 
                                  prep_baseline_creatinine,prep_baseline_alt,prep_baseline_hbsag,prep_baseline_hbpcv,
                                  prep_baseline_wbc,prep_current_hbsag,prep_current_hbpcv,prep_current_wbc,prep_prepi, 
                                  prep_prepc,prep_eli_test, prep_base_eli_test, prep_bio,prep_e_target,prep_penrol, 
                                  prep_current_alt] >> hts_joined >> final_hts >> final_prep >> end