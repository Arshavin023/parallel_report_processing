from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.providers.postgres.operators.postgres import PostgresOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook
from airflow.utils.task_group import TaskGroup
import datetime
from lamisplus_funcs.airflow_api import trigger_dag
from airflow.operators.python import PythonOperator


def trigger_dag_function(**kwargs):
    trigger_dag(dag_id='ACE2_client_radet_generation')

default_args = {
    "owner": "airflow",
    "email_on_failure": False,
    "email_on_retry": False,
    "email": "admin@localhost.com",
    "retries": 2,
    "retry_delay": datetime.timedelta(minutes=5)
}

# Function to fetch datim_ids from the database
def fetch_datim_ids(**kwargs):
    hook = PostgresHook(postgres_conn_id="lamisplus_conn")
    sql = """"SELECT datim_id FROM central_partner_mapping 
            WHERE ip_name='ACE-1'
            """
    records = hook.get_records(sql)
    datim_ids = [record[0] for record in records]  # Extract datim_id from the records
    return datim_ids

def create_task_groups(datim_id):
    """
    Dynamically creates task groups for each datim_id.
    """
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
            postgres_conn_id=f"lamisplus_conn",
            sql=f"call expanded_radet_client.proc_dsd1('{datim_id}')",
            autocommit=True
        )

        cte_dsd2 = PostgresOperator(
            task_id=f"cte_dsd2_{datim_id}",
            postgres_conn_id=f"lamisplus_conn",
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

        radet_joined = PostgresOperator(
           task_id="radet_joined",
           postgres_conn_id="lamisplus_conn",
           sql= f"call expanded_radet_client.proc_radet_joined('{datim_id}')",
           autocommit=True
       )
        
        [cte_bio_data,cte_biometric,cte_carecardcd4,cte_case_manager,cte_cervical_cancer,
         cte_client_verification,cte_crytococal_antigen,cte_current_clinical,cte_current_regimen,
         cte_current_status,cte_current_tb_result,cte_current_vl_result,cte_dsd1,cte_dsd2,
         cte_eac,cte_ipt,cte_ipt_s,cte_iptnew,cte_labcd4,cte_naive_vl_data,cte_ovc,cte_patient_lga,
         cte_pharmacy_details_regimen,cte_sample_collection_date,cte_tb_sample_collection,cte_tblam,
         cte_tbstatus,cte_tbtreatment,cte_tbtreatmentnew,cte_vacauseofdeath] >> radet_joined

    return datim_tasks

# Define the DAG
with DAG("ACE1_client_radet_generation",
         start_date=datetime.datetime(2024, 7, 1),
         schedule_interval=None,
         default_args=default_args,
         catchup=True,
         max_active_runs=1) as dag:

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

    # List of datim_ids
    datim_ids = fetch_datim_ids()

    # Dynamically create tasks for each datim_id
    task_group_endpoints = [create_task_groups(datim_id) for datim_id in datim_ids]
    
    #expanded_radet_weekly = PostgresOperator(
     #   task_id="expanded_radet_weekly",
      #  postgres_conn_id="lamisplus_conn",
      #  sql="call expanded_radet_client.proc_expanded_radet_weekly()",
    #    autocommit=True
    #)

    end = BashOperator(
        task_id="end",
        bash_command="echo end"
    )

    trigger_ace2_dag = PythonOperator(
        task_id='trigger_ace2_dag',
        python_callable=trigger_dag_function,
        provide_context=True,
    )

    # Define task dependencies
    start >> update_period_table >> task_group_endpoints >> end >> trigger_ace2_dag
