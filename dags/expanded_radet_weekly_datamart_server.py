from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.providers.postgres.operators.postgres import PostgresOperator
from airflow.operators.python import PythonOperator
from airflow.utils.task_group import TaskGroup
import datetime
from airflow_api import trigger_dag

def trigger_dag_function(**kwargs):
    trigger_dag(dag_id='expanded_hts_prep_weekly') 
    
default_args = {
    "owner": "airflow",
    "email_on_failure": False,
    "email_on_retry": False,
    "email": "admin@localhost.com",
    "retries": 2,
    "retry_delay": datetime.timedelta(minutes=5)
}

with DAG("lamisplus_expanded_radet_weekly_datamart_server",start_date=datetime.datetime(2024, 7, 1),schedule_interval=None,
            default_args=default_args,catchup=True,max_active_runs=1,) as dag:

    start = BashOperator(
        task_id="start",
        bash_command="echo start"
    )
    
    update_period_table = PostgresOperator(
        task_id="update_period_table",
        postgres_conn_id="radet_conn",
        sql='call expanded_radet.proc_update_expanded_radet_period_table()',
        autocommit=True
        )
    
    with TaskGroup(group_id='upstream_tasks') as upstream_tasks:
    
        cte_ovc = PostgresOperator(
            task_id="cte_ovc",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_ovc()',
            autocommit=True
        )

        cte_biometric = PostgresOperator(
            task_id="cte_biometric",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_biometric()',
            autocommit=True
        )

        cte_bio_data = PostgresOperator(
            task_id="cte_bio_data",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_bio_data()',
            autocommit=True
        )

        cte_case_manager = PostgresOperator(
            task_id="cte_case_manager",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_case_manager()',
            autocommit=True
        )

        cte_sample_collection_date = PostgresOperator(
            task_id="cte_sample_collection_date",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_sample_collection_date()',
            autocommit=True
        )

        cte_patient_lga = PostgresOperator(
            task_id="cte_patient_lga",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_patient_lga()',
            autocommit=True
        )

        cte_tblam = PostgresOperator(
            task_id="cte_tblam",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_tblam()',
            autocommit=True
        )
        
        sub_tbstatus_tbscreening_cs = PostgresOperator(
            task_id="sub_tbstatus_tbscreening_cs",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_sub_tbstatus_tbscreening_cs()',
            autocommit=True
        )
        
        sub_triage_current_clinical = PostgresOperator(
            task_id="sub_triage_current_clinical",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_sub_triage_current_clinical()',
            autocommit=True
        )

        sub_date_current_clinical = PostgresOperator(
            task_id="sub_date_current_clinical",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_sub_date_current_clinical()',
            autocommit=True
        )
        
        cte_carecardcd4 = PostgresOperator(
            task_id="cte_carecardcd4",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_carecardcd4()',
            autocommit=True
        )

        cte_labcd4 = PostgresOperator(
            task_id="cte_labcd4",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_labcd4()',
            autocommit=True
        )

        cte_tb_sample_collection = PostgresOperator(
            task_id="cte_tb_sample_collection",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_tb_sample_collection()',
            autocommit=True
        )

        cte_current_tb_result = PostgresOperator(
            task_id="cte_current_tb_result",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_current_tb_result()',
            autocommit=True
        )

        cte_tbtreatment = PostgresOperator(
            task_id="cte_tbtreatment",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_tbtreatment()',
            autocommit=True
        )
        
        sub_cte_ipt_c = PostgresOperator(
            task_id="sub_cte_ipt_c",
            postgres_conn_id="radet_conn",
            sql = 'call expanded_radet.proc_sub_ipt_c()',
            autocommit = True
        )

        sub_cte_ipt_s = PostgresOperator(
            task_id="sub_cte_ipt_s",
            postgres_conn_id="radet_conn",
            sql = 'call expanded_radet.proc_sub_ipt_s()',
            autocommit = True
        )

        sub_cte_ipt_c_cs = PostgresOperator(
            task_id="sub_cte_ipt_c_cs",
            postgres_conn_id="radet_conn",
            sql = 'call expanded_radet.proc_sub_ipt_c_cs()',
            autocommit = True
        )
        
        sub_sub_current_vl_temp_lab_sample = PostgresOperator(
            task_id="sub_sub_current_vl_temp_lab_sample",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_create_temp_lab_sample()',
            autocommit=True
        )
        
        sub_sub_current_vl_temp_lab_test = PostgresOperator(
            task_id="sub_sub_current_vl_temp_lab_test",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_create_temp_lab_test()',
            autocommit=True
        )
        
        sub_sub_current_vl_temp_lab_result = PostgresOperator(
            task_id="sub_sub_current_vl_temp_lab_result",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_create_temp_lab_result()',
            autocommit=True
        )
        
        cte_previous_previous = PostgresOperator(
            task_id="cte_previous_previous",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_previous_previous()',
            autocommit=True
        )
        
        cte_previous = PostgresOperator(
            task_id="cte_previous",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_previous()',
            autocommit=True
        )
        
        
        cte_current_status = PostgresOperator(
            task_id="cte_current_status",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_current_status()',
            autocommit=True
        )

        cte_sub_naive_vl_data = PostgresOperator(
            task_id="cte_sub_naive_vl_data",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_sub_naive_vl_data()',
            autocommit=True
        )

        cte_sub2_naive_vl_data = PostgresOperator(
            task_id="cte_sub2_naive_vl_data",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_sub2_naive_vl_data()',
            autocommit=True
        )

        cte_dsd1 = PostgresOperator(
            task_id="cte_dsd1",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_dsd1()',
            autocommit=True
        )

        cte_dsd2 = PostgresOperator(
            task_id="cte_dsd2",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_dsd2()',
            autocommit=True
        )

        cte_tbstatus_tbscreening_hac = PostgresOperator(
            task_id="cte_tbstatus_tbscreening_hac",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_tbstatus_tbscreening_hac()',
            autocommit=True
        )
        
        sub_arv_pharmacy = PostgresOperator(
            task_id="sub_arv_pharmacy",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_sub_arv_pharmacy()',
            autocommit=True
        )
        
        sub_cervical_cancer = PostgresOperator(
            task_id="sub_cervical_cancer",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_sub_cervical_cancer()',
            autocommit=True
        )
        
        sub_client_verification = PostgresOperator(
            task_id="sub_client_verification",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_sub_client_verification()',
            autocommit=True
        )
        
        sub_cryptocol_antigen = PostgresOperator(
            task_id="sub_cryptocol_antigen",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_sub_cryptocol_antigen()',
            autocommit=True
        )
        
        sub1_eac = PostgresOperator(
            task_id="sub1_eac",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_sub1_eac()',
            autocommit=True
        )
        
        sub2_eac = PostgresOperator(
            task_id="sub2_eac",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_sub2_eac()',
            autocommit=True
        )

    with TaskGroup(group_id='midstream_tasks') as midstream_tasks:
        
        cte_tbstatus_tbscreening_cs = PostgresOperator(
            task_id="cte_tbstatus_tbscreening_cs",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_tbstatus_tbscreening_cs()',
            autocommit=True
        )
        
        cte_current_clinical = PostgresOperator(
            task_id="cte_current_clinical",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_current_clinical()',
            autocommit=True
        )
            
        cte_client_verification = PostgresOperator(
            task_id="cte_client_verification",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_client_verification()',
            autocommit=True
        )
        
        cte_cervical_cancer = PostgresOperator(
            task_id="cte_cervical_cancer",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_cervical_cancer()',
            autocommit=True
        )
        
        cte_current_vl_result = PostgresOperator(
            task_id="cte_current_vl_result",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_current_vl_result()',
            autocommit=True
        )
        
        cte_naive_vl_data = PostgresOperator(
            task_id="cte_naive_vl_data",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_naive_vl_data()',
            autocommit=True
        )

        cte_ipt = PostgresOperator(
            task_id="cte_ipt",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_ipt()',
            autocommit=True
        )
        
        cte_cryptocol_antigen = PostgresOperator(
            task_id="cte_cryptocol_antigen",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_cryptocol_antigen()',
            autocommit=True
        )
        
        cte_pharmacy_details_regimen = PostgresOperator(
            task_id="cte_pharmacy_details_regimen",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_pharmacy_details_regimen()',
            autocommit=True
        )
        
        cte_eac = PostgresOperator(
            task_id="cte_eac",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_eac()',
            autocommit=True
        )
        
    with TaskGroup(group_id='downstream_tasks') as downstream_tasks:
        
        cte_tbstatus = PostgresOperator(
            task_id="cte_tbstatus",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_tbstatus()',
            autocommit=True
        )
        
    radet_joined = PostgresOperator(
        task_id="radet_joined",
        postgres_conn_id="radet_conn",
        sql='call expanded_radet.proc_radet_joined()',
        autocommit=True
    )

    expanded_radet_weekly = PostgresOperator(
        task_id="expanded_radet_weekly",
        postgres_conn_id="radet_conn",
        sql='call expanded_radet.proc_expanded_radet_weekly()',
        autocommit=True
    )

    end = BashOperator(
        task_id="end",
        bash_command="echo end"
    )
    
    trigger_hts_prep_weekly = PythonOperator(
        task_id='trigger_hts_prep_weekly',
        python_callable=trigger_dag_function,
        provide_context=True,
    )

    # Define the task dependencies
    start >> update_period_table >> upstream_tasks >> midstream_tasks >> downstream_tasks >> radet_joined >> expanded_radet_weekly >> end >> trigger_hts_prep_weekly
