from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from airflow.providers.postgres.operators.postgres import PostgresOperator
from airflow.models import Variable
from airflow.sensors.external_task import ExternalTaskSensor
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

with DAG("lamisplus_hts_prep_datamart_server", start_date=datetime.datetime(2024, 7, 1), schedule_interval=None,
         default_args=default_args,
         catchup=False, max_active_runs=1) as dag:

    start = BashOperator(
        task_id="start",
        bash_command="echo start"
    )
    
    update_period_table = PostgresOperator(
        task_id="update_period_table",
        postgres_conn_id="hts_prep_conn",
        sql = 'call expanded_hts_prep.proc_update_expanded_hts_prep_period_table()',
        autocommit = True
    )
    
    with TaskGroup(group_id='upstream_tasks') as upstream_tasks:

        prep_current_pc = PostgresOperator(
            task_id="prep_current_pc",
            postgres_conn_id="hts_prep_conn",
            sql = 'call expanded_hts_prep.proc_prep_current_pc()',
            autocommit = True
        )

        prep_baseline_pc = PostgresOperator(
            task_id="prep_baseline_pc",
            postgres_conn_id="hts_prep_conn",
            sql = 'call expanded_hts_prep.proc_prep_baseline_pc()',
            autocommit = True
        )

        prep_baseline_bp = PostgresOperator(
            task_id="prep_baseline_bp",
            postgres_conn_id="hts_prep_conn",
            sql = 'call expanded_hts_prep.proc_prep_baseline_bp()',
            autocommit = True
        )

        prep_baseline_hbpcv = PostgresOperator(
            task_id="prep_baseline_hbpcv",
            postgres_conn_id="hts_prep_conn",
            sql = 'call expanded_hts_prep.proc_prep_baseline_hbpcv()',
            autocommit = True
        )

        prep_baseline_urinalysis = PostgresOperator(
            task_id="prep_baseline_urinalysis",
            postgres_conn_id="hts_prep_conn",
            sql = 'call expanded_hts_prep.proc_prep_baseline_urinalysis()',
            autocommit = True
        )

        prep_baseline_creatinine = PostgresOperator(
            task_id="prep_baseline_creatinine",
            postgres_conn_id="hts_prep_conn",
            sql = 'call expanded_hts_prep.proc_prep_baseline_creatinine()',
            autocommit = True
        )

        prep_baseline_alt = PostgresOperator(
            task_id="prep_baseline_alt",
            postgres_conn_id="hts_prep_conn",
            sql = 'call expanded_hts_prep.proc_prep_baseline_alt()',
            autocommit = True
        )

        prep_baseline_hbsag = PostgresOperator(
            task_id="prep_baseline_hbsag",
            postgres_conn_id="hts_prep_conn",
            sql = 'call expanded_hts_prep.proc_prep_baseline_hbsag()',
            autocommit = True
        )

        prep_baseline_wbc = PostgresOperator(
            task_id="prep_baseline_wbc",
            postgres_conn_id="hts_prep_conn",
            sql = 'call expanded_hts_prep.proc_prep_baseline_wbc()',
            autocommit = True
        )

        prep_current_hbsag = PostgresOperator(
            task_id="prep_current_hbsag",
            postgres_conn_id="hts_prep_conn",
            sql = 'call expanded_hts_prep.proc_prep_current_hbsag()',
            autocommit = True
        )

        prep_current_hbpcv = PostgresOperator(
            task_id="prep_current_hbpcv",
            postgres_conn_id="hts_prep_conn",
            sql = 'call expanded_hts_prep.proc_prep_current_hbpcv()',
            autocommit = True
        )

        prep_current_wbc = PostgresOperator(
            task_id="prep_current_wbc",
            postgres_conn_id="hts_prep_conn",
            sql = 'call expanded_hts_prep.proc_prep_current_wbc()',
            autocommit = True
        )

        prep_prepi = PostgresOperator(
            task_id="prep_prepi",
            postgres_conn_id="hts_prep_conn",
            sql = 'call expanded_hts_prep.proc_prep_prepi()',
            autocommit = True
        )

        prep_prepc = PostgresOperator(
            task_id="prep_prepc",
            postgres_conn_id="hts_prep_conn",
            sql = 'call expanded_hts_prep.proc_prep_prepc()',
            autocommit = True
        )

        prep_eli_test = PostgresOperator(
            task_id="prep_eli_test",
            postgres_conn_id="hts_prep_conn",
            sql = 'call expanded_hts_prep.proc_prep_eli_test()',
            autocommit = True
        )

        prep_base_eli_test = PostgresOperator(
            task_id="prep_base_eli_test",
            postgres_conn_id="hts_prep_conn",
            sql = 'call expanded_hts_prep.proc_prep_base_eli_test()',
            autocommit = True
        )

        prep_bio = PostgresOperator(
            task_id="prep_bio",
            postgres_conn_id="hts_prep_conn",
            sql = 'call expanded_hts_prep.proc_prep_bio()',
            autocommit = True
        )

        prep_e_target = PostgresOperator(
            task_id="prep_e_target",
            postgres_conn_id="hts_prep_conn",
            sql = 'call expanded_hts_prep.proc_prep_e_target()',
            autocommit = True
        )

        prep_penrol = PostgresOperator(
            task_id="prep_penrol",
            postgres_conn_id="hts_prep_conn",
            sql = 'call expanded_hts_prep.proc_prep_penrol()',
            autocommit = True
        )

        prep_current_alt = PostgresOperator(
            task_id="prep_current_alt",
            postgres_conn_id="hts_prep_conn",
            sql = 'call expanded_hts_prep.proc_prep_current_alt()',
            autocommit = True
        )
        
        hts_mapping = PostgresOperator(
            task_id="hts_mapping",
            postgres_conn_id="hts_prep_conn",
            sql = 'call expanded_hts_prep.proc_hts_mapping()',
            autocommit = True
        )
        
        hts_max = PostgresOperator(
            task_id="hts_max",
            postgres_conn_id="hts_prep_conn",
            sql = 'call expanded_hts_prep.proc_hts_max()',
            autocommit = True
        )
        
        statelgaresidence = PostgresOperator(
            task_id="statelgaresidence",
            postgres_conn_id="hts_prep_conn",
            sql = 'call expanded_hts_prep.proc_statelgaresidence()',
            autocommit = True
        )

        sub_sub_expanded_hts_joined_bio = PostgresOperator(
            task_id="sub_sub_expanded_hts_joined_bio",
            postgres_conn_id="hts_prep_conn",
            sql = 'call expanded_hts_prep.proc_sub_sub_expanded_hts_joined_bio()',
            autocommit = True
        )
        
        sub1_expanded_prep_joined = PostgresOperator(
            task_id="sub1_expanded_prep_joined",
            postgres_conn_id="hts_prep_conn",
            sql = 'call expanded_hts_prep.proc_sub1_expanded_prep_joined()',
            autocommit = True
        )
        
        sub2_expanded_prep_joined = PostgresOperator(
            task_id="sub2_expanded_prep_joined",
            postgres_conn_id="hts_prep_conn",
            sql = 'call expanded_hts_prep.proc_sub2_expanded_prep_joined()',
            autocommit = True
        )
        
        sub3_expanded_prep_joined = PostgresOperator(
            task_id="sub3_expanded_prep_joined",
            postgres_conn_id="hts_prep_conn",
            sql = 'call expanded_hts_prep.proc_sub3_expanded_prep_joined()',
            autocommit = True
        )
        
        sub4_expanded_prep_joined = PostgresOperator(
            task_id="sub4_expanded_prep_joined",
            postgres_conn_id="hts_prep_conn",
            sql = 'call expanded_hts_prep.proc_sub4_expanded_prep_joined()',
            autocommit = True
        )
        
        sub5_expanded_prep_joined = PostgresOperator(
            task_id="sub5_expanded_prep_joined",
            postgres_conn_id="hts_prep_conn",
            sql = 'call expanded_hts_prep.proc_sub5_expanded_prep_joined()',
            autocommit = True
        )
        
        sub6_expanded_prep_joined = PostgresOperator(
            task_id="sub6_expanded_prep_joined",
            postgres_conn_id="hts_prep_conn",
            sql = 'call expanded_hts_prep.proc_sub6_expanded_prep_joined()',
            autocommit = True
        )
        
    with TaskGroup(group_id='midstream_tasks') as midstream_tasks:
        
        expanded_hts_joined_bio = PostgresOperator(
            task_id="expanded_hts_joined_bio",
            postgres_conn_id="hts_prep_conn",
            sql = 'call expanded_hts_prep.proc_sub_expanded_hts_joined_bio_updated()',
            autocommit = True
        )
        
        expanded_hts_joined_codeset = PostgresOperator(
            task_id="expanded_hts_joined_codeset",
            postgres_conn_id="hts_prep_conn",
            sql = 'call expanded_hts_prep.proc_sub_expanded_hts_joined_codeset()',
            autocommit = True
        )
    
    
    with TaskGroup(group_id='downstream_tasks') as downstream_tasks:
        
        expanded_prep_joined = PostgresOperator(
            task_id="expanded_prep_joined",
            postgres_conn_id="hts_prep_conn",
            sql = 'call expanded_hts_prep.proc_expanded_prep_joined_updated()',
            autocommit = True
            )
            
        expanded_hts_joined = PostgresOperator(
            task_id="expanded_hts_joined",
            postgres_conn_id="hts_prep_conn",
            sql = 'call expanded_hts_prep.proc_expanded_hts_joined()',
            autocommit = True
            )
           
           
    with TaskGroup(group_id='final_stream_tasks') as final_stream_tasks:
        
        expanded_hts_weekly = PostgresOperator(
            task_id="expanded_hts_weekly",
            postgres_conn_id="hts_prep_conn",
            sql = 'call expanded_hts_prep.proc_expanded_hts()',
            autocommit = True
        )
        
        expanded_prep_weekly = PostgresOperator(
            task_id="expanded_prep_weekly",
            postgres_conn_id="hts_prep_conn",
            sql = 'call expanded_hts_prep.proc_expanded_prep()',
            autocommit = True
        )

    end = BashOperator(
        task_id="end",
        bash_command="echo end"
        )


    start >> update_period_table >> upstream_tasks >> midstream_tasks >> downstream_tasks >> final_stream_tasks
