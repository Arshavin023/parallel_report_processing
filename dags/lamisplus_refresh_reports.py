from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.providers.postgres.operators.postgres import PostgresOperator
from airflow.utils.task_group import TaskGroup
import datetime
from airflow.utils.task_group import TaskGroup

default_args = {
    "owner": "airflow",
    "email_on_failure": False,
    "email_on_retry": False,
    "email": "admin@localhost.com",
    "retries": 2,
    "retry_delay": datetime.timedelta(minutes=5)
}

with DAG("lamisplus_refresh_reports",start_date=datetime.datetime(2024, 7, 1),schedule_interval=None,
            default_args=default_args,catchup=True,max_active_runs=1,tags=["refresh_tables", "lamisplus","daily"]) as dag:

    start = BashOperator(
        task_id="start",
        bash_command="echo start"
    ) 
    
    with TaskGroup(group_id='upstream_tasks') as upstream_tasks:
        
        upsert_tbstatus_tbscreening = PostgresOperator(
            task_id="upsert_tbstatus_tbscreening",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_upsert_tbstatus_tbscreening()',
            autocommit=True
        )
        
        upsert_pharmacy_details_regimen = PostgresOperator(
            task_id="upsert_pharmacy_details_regimen",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_upsert_pharmacy_details_regimen()',
            autocommit=True
        )
        
        upsert_base_biometric = PostgresOperator(
            task_id="upsert_base_biometric",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_upsert_base_biometric()',
            autocommit=True
        )

        upsert_recapture_biometric = PostgresOperator(
            task_id="upsert_recapture_biometric",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_upsert_recapture_biometric()',
            autocommit=True
        )

        upsert_patient_bio_data = PostgresOperator(
            task_id="upsert_patient_bio_data",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_upsert_patient_bio_data()',
            autocommit=True
        )

        upsert_carecardcd4 = PostgresOperator(
            task_id="upsert_carecardcd4",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_upsert_carecardcd4()',
            autocommit=True
        )

        upsert_cervical_cancer = PostgresOperator(
            task_id="upsert_cervical_cancer",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_upsert_cervical_cancer()',
            autocommit=True
        )
        
        upsert_client_verification_v3 = PostgresOperator(
            task_id="upsert_client_verification_v3",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_upsert_client_verification_v3()',
            autocommit=True
        )

        upsert_cryptocol_antigen = PostgresOperator(
            task_id="upsert_cryptocol_antigen",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_upsert_cryptocol_antigen()',
            autocommit=True
        )
        
        upsert_art_commencement_vitals = PostgresOperator(
            task_id="upsert_art_commencement_vitals",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_upsert_art_commencement_vitals()',
            autocommit=True
        )
        
        upsert_hiv_status_tracker = PostgresOperator(
            task_id="upsert_hiv_status_tracker",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_upsert_hiv_status_tracker()',
            autocommit=True
        )
        
        upsert_clinic_data = PostgresOperator(
            task_id="upsert_clinic_data",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_upsert_clinic_data()',
            autocommit=True
        )
        
        upsert_hiv_clinical_enrollment = PostgresOperator(
            task_id="upsert_hiv_clinical_enrollment",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_upsert_hiv_clinical_enrollment()',
            autocommit=True
        )
        
        upsert_baseappcodeset_radetdb = PostgresOperator(
            task_id="upsert_baseappcodeset_radetdb",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_upsert_baseappcodeset()',
            autocommit=True
        )
        
        upsert_baseappcodeset_dwh = PostgresOperator(
            task_id="upsert_baseappcodese_dwh",
            postgres_conn_id="lamisplus_conn",
            sql='call expanded_radet.proc_upsert_baseappcodeset()',
            autocommit=True
        )
        
        upsert_laboratoryorder_hivenrollment = PostgresOperator(
            task_id="upsert_laboratoryorder_hivenrollment",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_upsert_laboratoryorder_hivenrollment()',
            autocommit=True
        )
        
        temp_laboratorytestresults = PostgresOperator(
            task_id="temp_laboratorytestresults",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_upsert_temp_laboratorytestresults()',
            autocommit=True
        )
        
        upsert_regimenatstart = PostgresOperator(
            task_id="upsert_regimenatstart",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_upsert_regimenatstart()',
            autocommit=True
        )
        
        upsert_lastpickup = PostgresOperator(
            task_id="upsert_lastpickup",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_upsert_lastpickup()',
            autocommit=True
        )
        
        upsert_eac_sessions = PostgresOperator(
            task_id="upsert_eac_sessions",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_upsert_eac_sessions()',
            autocommit=True
        )
        
        upsert_sub_current_clinical = PostgresOperator(
            task_id="upsert_sub_current_clinical",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_upsert_sub_current_clinical_updated()',
            autocommit=True
        )
        
        upsert_hiv_observation = PostgresOperator(
            task_id="upsert_hiv_observation",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_upsert_hiv_observation()',
            autocommit=True
        )
        
        upsert_hivregimentype = PostgresOperator(
            task_id="upsert_hivregimentype",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_upsert_hivregimentype()',
            autocommit=True
        )
        
        upsert_statelgaresidence = PostgresOperator(
            task_id="upsert_statelgaresidence",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_upsert_statelgaresidence()',
            autocommit=True
        )
        
    with TaskGroup(group_id='midstream_tasks') as midstream_tasks:
        upsert_arv_pharmacy = PostgresOperator(
            task_id="upsert_arv_pharmacy",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_upsert_arv_pharmacy()',
            autocommit=True
        )
        
        upsert_hivclinicalenrollment_baseappcode = PostgresOperator(
            task_id="upsert_hivclinicalenrollment_baseappcode",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_upsert_hivclinicalenrollment_baseappcode()',
            autocommit=True
        )
        
        laboratorytestresults = PostgresOperator(
            task_id="laboratorytestresults",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_upsert_laboratorytestresults()',
            autocommit=True
        )
        
        upsert_eac_client = PostgresOperator(
            task_id="upsert_eac_client",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_upsert_eac_client()',
            autocommit=True
        )
        
        upsert_client_verification = PostgresOperator(
            task_id="upsert_client_verification",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_upsert_client_verification()',
            autocommit=True
        )
        
    with TaskGroup(group_id='downstream_tasks') as downstream_tasks:
        upsert_sub_tvs_current_clinical = PostgresOperator(
            task_id="upsert_sub_tvs_current_clinical",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_upsert_sub_tvs_current_clinical()',
            autocommit=True
        )
        
        upsert_sub_laboratory_details = PostgresOperator(
            task_id="upsert_sub_laboratory_details",
            postgres_conn_id="radet_conn",
            sql='call expanded_radet.proc_upsert_sub_laboratory_details()',
            autocommit=True
        )

    upsert_laboratory_details = PostgresOperator(
        task_id="upsert_laboratory_details",
        postgres_conn_id="radet_conn",
        sql='call expanded_radet.proc_upsert_laboratory_details()',
        autocommit=True
    )
        
		
    end = BashOperator(
        task_id="end",
        bash_command="echo end"
    )
    # Define the task dependencies
    start >> upstream_tasks >> midstream_tasks >> downstream_tasks >> upsert_laboratory_details >> end
