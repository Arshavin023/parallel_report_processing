from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.providers.postgres.operators.postgres import PostgresOperator
from airflow.operators.empty import EmptyOperator
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

with DAG("lamisplus_client_radet_dwh_server",start_date=datetime.datetime(2024, 7, 1),schedule_interval=None,
            default_args=default_args,catchup=True,max_active_runs=1,) as dag:

    start = BashOperator(
        task_id="start",
        bash_command="echo start"
    )
    
    update_period_table = PostgresOperator(
        task_id="update_period_table",
        postgres_conn_id="lamisplus_conn",
        sql="call expanded_radet.proc_update_expanded_radet_period_table()",
        autocommit=True
        )
        
    previous_datim_group = None

    for datim_id in ['fVcjpsyeO4q','xCya42gPOnU','TCJpqmlk9sK','f0J277xHATh',
                    'cmkm8UQpvWk','iPViA45Cl3G','th3IMCg3lQ1','R3rzxyzlNgM',
                    'cYdxH1tF7Di','E1PW0PYkvDx']:
		
        with TaskGroup(group_id=f"tasks_for_{datim_id}") as datim_tasks:
        
            cte_ovc = PostgresOperator(
                task_id=f"cte_ovc_{datim_id}",
                postgres_conn_id="lamisplus_conn",
                sql=f"call expanded_radet_client.proc_ovc('{datim_id}')",
                autocommit=True
            )

            cte_biometric = PostgresOperator(
                task_id=f"cte_biometric_{datim_id}",
                postgres_conn_id="lamisplus_conn",
                sql=f"call expanded_radet_client.proc_biometric('{datim_id}')",
                autocommit=True
            )

            cte_bio_data = PostgresOperator(
                task_id=f"cte_bio_data_{datim_id}",
                postgres_conn_id="lamisplus_conn",
                sql=f"call expanded_radet_client.proc_bio_data('{datim_id}')",
                autocommit=True
            )

            cte_case_manager = PostgresOperator(
                task_id=f"cte_case_manager_{datim_id}",
                postgres_conn_id="lamisplus_conn",
                sql=f"call expanded_radet_client.proc_case_manager('{datim_id}')",
                autocommit=True
            )

            cte_sample_collection_date = PostgresOperator(
                task_id=f"cte_sample_collection_date_{datim_id}",
                postgres_conn_id="lamisplus_conn",
                sql=f"call expanded_radet_client.proc_sample_collection_date('{datim_id}')",
                autocommit=True
            )

            cte_patient_lga = PostgresOperator(
                task_id=f"cte_patient_lga_{datim_id}",
                postgres_conn_id="lamisplus_conn",
                sql=f"call expanded_radet_client.proc_patient_lga('{datim_id}')",
                autocommit=True
            )

            cte_tblam = PostgresOperator(
                task_id=f"cte_tblam_{datim_id}",
                postgres_conn_id="lamisplus_conn",
                sql=f"call expanded_radet_client.proc_tblam('{datim_id}')",
                autocommit=True
            )

            cte_carecardcd4 = PostgresOperator(
                task_id=f"cte_carecardcd4_{datim_id}",
                postgres_conn_id="lamisplus_conn",
                sql=f"call expanded_radet_client.proc_carecardcd4('{datim_id}')",
                autocommit=True
            )

            cte_labcd4 = PostgresOperator(
                task_id=f"cte_labcd4_{datim_id}",
                postgres_conn_id="lamisplus_conn",
                sql=f"call expanded_radet_client.proc_labcd4('{datim_id}')",
                autocommit=True
            )

            cte_tb_sample_collection = PostgresOperator(
                task_id=f"cte_tb_sample_collection_{datim_id}",
                postgres_conn_id="lamisplus_conn",
                sql=f"call expanded_radet_client.proc_tb_sample_collection('{datim_id}')",
                autocommit=True
            )

            cte_current_tb_result = PostgresOperator(
                task_id=f"cte_current_tb_result_{datim_id}",
                postgres_conn_id="lamisplus_conn",
                sql=f"call expanded_radet_client.proc_current_tb_result('{datim_id}')",
                autocommit=True
            )
            
            cte_pharmacy_details_regimen = PostgresOperator(
                task_id=f"cte_pharmacy_details_regimen_{datim_id}",
                postgres_conn_id="lamisplus_conn",
                sql=f"call expanded_radet_client.proc_pharmacy_details_regimen('{datim_id}')",
                autocommit=True
            )

            
            cte_cervical_cancer = PostgresOperator(
                task_id=f"cte_cervical_cancer_{datim_id}",
                postgres_conn_id="lamisplus_conn",
                sql=f"call expanded_radet_client.proc_cervical_cancer('{datim_id}')",
                autocommit=True
            )
            
            cte_current_status = PostgresOperator(
                task_id=f"cte_current_status_{datim_id}",
                postgres_conn_id="lamisplus_conn",
                sql=f"call expanded_radet_client.proc_current_status('{datim_id}')",
                autocommit=True
            )

            cte_crytococal_antigen = PostgresOperator(
                task_id=f"cte_crytococal_antigen_{datim_id}",
                postgres_conn_id="lamisplus_conn",
                sql=f"call expanded_radet_client.proc_crytococal_antigen('{datim_id}')",
                autocommit=True
            )

            cte_client_verification = PostgresOperator(
                task_id=f"cte_client_verification_{datim_id}",
                postgres_conn_id="lamisplus_conn",
                sql=f"call expanded_radet_client.proc_client_verification('{datim_id}')",
                autocommit=True
            )

            cte_dsd1 = PostgresOperator(
                task_id=f"cte_dsd1_{datim_id}",
                postgres_conn_id="lamisplus_conn",
                sql=f"call expanded_radet_client.proc_dsd1('{datim_id}')",
                autocommit=True
            )

            cte_dsd2 = PostgresOperator(
                task_id=f"cte_dsd2_{datim_id}",
                postgres_conn_id="lamisplus_conn",
                sql=f"call expanded_radet_client.proc_dsd2('{datim_id}')",
                autocommit=True
            )
            
            cte_current_vl_result = PostgresOperator(
                task_id=f"cte_current_vl_result_{datim_id}",
                postgres_conn_id="lamisplus_conn",
                sql=f"call expanded_radet_client.proc_current_vl_result('{datim_id}')",
                autocommit=True
            )
            
            cte_naive_vl_data = PostgresOperator(
                task_id=f"cte_naive_vl_data_{datim_id}",
                postgres_conn_id="lamisplus_conn",
                sql=f"call expanded_radet_client.proc_naive_vl_data('{datim_id}')",
                autocommit=True
            )

            cte_current_regimen = PostgresOperator(
                task_id=f"cte_current_regimen_{datim_id}",
                postgres_conn_id="lamisplus_conn",
                sql=f"call expanded_radet_client.proc_current_regimen('{datim_id}')",
                autocommit=True
            )


            cte_current_clinical = PostgresOperator(
                task_id=f"cte_current_clinical_{datim_id}",
                postgres_conn_id="lamisplus_conn",
                sql=f"call expanded_radet_client.proc_current_clinical('{datim_id}')",
                autocommit=True
            )

            cte_tbstatus = PostgresOperator(
                task_id=f"cte_tbstatus_{datim_id}",
                postgres_conn_id="lamisplus_conn",
                sql=f"call expanded_radet_client.proc_tbstatus('{datim_id}')",
                autocommit=True
            )

            cte_ipt = PostgresOperator(
                task_id=f"cte_ipt_{datim_id}",
                postgres_conn_id="lamisplus_conn",
                sql=f"call expanded_radet_client.proc_ipt('{datim_id}')",
                autocommit=True
            )
            
            cte_ipt_s = PostgresOperator(
                task_id=f"cte_ipt_s_{datim_id}",
                postgres_conn_id="lamisplus_conn",
                sql=f"call expanded_radet_client.proc_ipt_s('{datim_id}')",
                autocommit=True
            )

            cte_iptnew = PostgresOperator(
                task_id=f"cte_iptnew_{datim_id}",
                postgres_conn_id="lamisplus_conn",
                sql=f"call expanded_radet_client.proc_iptnew('{datim_id}')",
                autocommit=True
            )
            
            cte_tbtreatment = PostgresOperator(
                task_id=f"cte_tbtreatment_{datim_id}",
                postgres_conn_id="lamisplus_conn",
                sql=f"call expanded_radet_client.proc_tbtreatment('{datim_id}')",
                autocommit=True
            )

            cte_tbtreatmentnew = PostgresOperator(
                task_id=f"cte_tbtreatmentnew_{datim_id}",
                postgres_conn_id="lamisplus_conn",
                sql=f"call expanded_radet_client.proc_tbtreatmentnew('{datim_id}')",
                autocommit=True
            )

            cte_vacauseofdeath = PostgresOperator(
                task_id=f"cte_vacauseofdeath_{datim_id}",
                postgres_conn_id="lamisplus_conn",
                sql=f"call expanded_radet_client.proc_vacauseofdeath('{datim_id}')",
                autocommit=True
            )
            
            cte_eac = PostgresOperator(
                task_id=f"cte_eac_{datim_id}",
                postgres_conn_id="lamisplus_conn",
                sql=f"call expanded_radet_client.proc_eac('{datim_id}')",
                autocommit=True
            )

            [cte_bio_data,cte_biometric,cte_carecardcd4,cte_case_manager,cte_cervical_cancer,
            cte_client_verification,cte_crytococal_antigen,cte_current_clinical,cte_current_regimen,
            cte_current_status,cte_current_tb_result,cte_current_vl_result,cte_dsd1,cte_dsd2,
            cte_eac,cte_ipt,cte_ipt_s,cte_iptnew,cte_labcd4,cte_naive_vl_data,cte_ovc,cte_patient_lga,
            cte_pharmacy_details_regimen,cte_sample_collection_date,cte_tb_sample_collection,cte_tblam,
            cte_tbstatus,cte_tbtreatment,cte_tbtreatmentnew,cte_vacauseofdeath]

        # Synchronization task for current datim_id
        sync_point = EmptyOperator(
            task_id=f"sync_point_{datim_id}"
        )

        # Define dependencies within the current group
        datim_tasks >> sync_point

        # Define dependencies between groups
        if previous_datim_group:
            previous_datim_group >> datim_tasks
        
        # Update previous group for the next iteration
        previous_datim_group = sync_point

    radet_joined = PostgresOperator(
            task_id="radet_joined",
            postgres_conn_id="lamisplus_conn",
            sql= "call expanded_radet_client.proc_radet_joined()",
            autocommit=True
        )

    expanded_radet_weekly = PostgresOperator(
        task_id="expanded_radet_weekly",
        postgres_conn_id="lamisplus_conn",
        sql="call expanded_radet_client.proc_expanded_radet_weekly()",
        autocommit=True
    )

    end = BashOperator(
    task_id="end",
    bash_command="echo end"
    )

    # Global task dependencies
    start >> update_period_table >> previous_datim_group >> radet_joined >> expanded_radet_weekly >> end
