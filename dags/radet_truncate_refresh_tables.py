from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.providers.postgres.operators.postgres import PostgresOperator
from airflow.utils.task_group import TaskGroup
from datetime import datetime, timedelta
from airflow.utils.task_group import TaskGroup

default_args = {
    "owner": "airflow",
    "email_on_failure": False,
    "email_on_retry": False,
    "email": "admin@localhost.com",
    "retries": 2,
    "retry_delay": timedelta(minutes=5)
}

with DAG("truncate_refresh_tables",start_date=datetime(2024, 11, 1),schedule_interval=None,
            default_args=default_args,catchup=True,max_active_runs=1,) as dag:

    start = BashOperator(
        task_id="start",
        bash_command="echo start"
    ) 
    
    with TaskGroup(group_id='upstream_tasks') as upstream_tasks:
        
        familyindex_refresh = PostgresOperator(
            task_id="familyindex_refresh",
            postgres_conn_id="hts_prep_conn",
            sql="call public.proc_truncate_refresh_tables('expanded_hts_prep.familyindex_refresh')",
            autocommit=True)
        
        hts_client_codeset_refresh = PostgresOperator(
            task_id="hts_client_codeset_refresh",
            postgres_conn_id="hts_prep_conn",
            sql="call public.proc_truncate_refresh_tables('expanded_hts_prep.hts_client_codeset_refresh')",
            autocommit=True)
            
        hts_client_refresh = PostgresOperator(
            task_id="hts_client_refresh",
            postgres_conn_id="hts_prep_conn",
            sql="call public.proc_truncate_refresh_tables('expanded_hts_prep.hts_client_refresh')",
            autocommit=True)
            
        risk_stratification_refresh = PostgresOperator(
            task_id="risk_stratification_refresh",
            postgres_conn_id="hts_prep_conn",
            sql="call public.proc_truncate_refresh_tables('risk_stratification_refresh')",
            autocommit=True)
        
        partnerindex_refresh = PostgresOperator(
            task_id="partnerindex_refresh",
            postgres_conn_id="hts_prep_conn",
            sql="call public.proc_truncate_refresh_tables('expanded_hts_prep.partnerindex_refresh')",
            autocommit=True)
            
        art_commencement_vitals_refresh = PostgresOperator(
            task_id="art_commencement_vitals_refresh",
            postgres_conn_id="radet_conn",
            sql="call public.proc_truncate_refresh_tables('expanded_radet.art_commencement_vitals_refresh')",
            autocommit=True)
            
        base_biometric_refresh = PostgresOperator(
            task_id="base_biometric_refresh",
            postgres_conn_id="radet_conn",
            sql="call public.proc_truncate_refresh_tables('expanded_radet.base_biometric_refresh')",
            autocommit=True)
        
        baseappcodeset_refresh = PostgresOperator(
            task_id="baseappcodeset_refresh",
            postgres_conn_id="radet_conn",
            sql="call public.proc_truncate_refresh_tables('expanded_radet.baseappcodeset_refresh')",
            autocommit=True)
            
        carecardcd4_refresh = PostgresOperator(
            task_id="carecardcd4_refresh",
            postgres_conn_id="radet_conn",
            sql="call public.proc_truncate_refresh_tables('expanded_radet.carecardcd4_refresh')",
            autocommit=True)
        
        cervical_cancer_refresh = PostgresOperator(
            task_id="cervical_cancer_refresh",
            postgres_conn_id="radet_conn",
            sql="call public.proc_truncate_refresh_tables('expanded_radet.cervical_cancer_refresh')",
            autocommit=True)
        
        client_verification_refresh = PostgresOperator(
            task_id="client_verification_refresh",
            postgres_conn_id="radet_conn",
            sql="call public.proc_truncate_refresh_tables('expanded_radet.client_verification_refresh')",
            autocommit=True)
            
        ods_hiv_regimen_type = PostgresOperator(
            task_id="ods_hiv_regimen_type",
            postgres_conn_id="radet_conn",
            sql="call public.proc_truncate_refresh_tables('ods_hiv_regimen_type')",
            autocommit=True)
        
        clinic_data_refresh = PostgresOperator(
            task_id="clinic_data_refresh",
            postgres_conn_id="radet_conn",
            sql="call public.proc_truncate_refresh_tables('expanded_radet.clinic_data_refresh')",
            autocommit=True)
        
        cryptocol_antigen_refresh = PostgresOperator(
            task_id="cryptocol_antigen_refresh",
            postgres_conn_id="radet_conn",
            sql="call public.proc_truncate_refresh_tables('expanded_radet.cryptocol_antigen_refresh')",
            autocommit=True)
            
        cte_bio_data_refresh = PostgresOperator(
            task_id="cte_bio_data_refresh",
            postgres_conn_id="radet_conn",
            sql="call public.proc_truncate_refresh_tables('expanded_radet.cte_bio_data_refresh')",
            autocommit=True)
        
        cte_client_verification_refresh = PostgresOperator(
            task_id="cte_client_verification_refresh",
            postgres_conn_id="radet_conn",
            sql="call public.proc_truncate_refresh_tables('expanded_radet.cte_client_verification_refresh')",
            autocommit=True)
        
        eac_client_refresh = PostgresOperator(
            task_id="eac_client_refresh",
            postgres_conn_id="radet_conn",
            sql="call public.proc_truncate_refresh_tables('expanded_radet.eac_client_refresh')",
            autocommit=True)
            
        eac_sessions_refresh = PostgresOperator(
            task_id="eac_sessions_refresh",
            postgres_conn_id="radet_conn",
            sql="call public.proc_truncate_refresh_tables('expanded_radet.eac_sessions_refresh')",
            autocommit=True)
        
        hiv_clinical_enrollment_refresh = PostgresOperator(
            task_id="hiv_clinical_enrollment_refresh",
            postgres_conn_id="radet_conn",
            sql="call public.proc_truncate_refresh_tables('expanded_radet.hiv_clinical_enrollment_refresh')",
            autocommit=True)
        
        hiv_observation_refresh = PostgresOperator(
            task_id="hiv_observation_refresh",
            postgres_conn_id="radet_conn",
            sql="call public.proc_truncate_refresh_tables('expanded_radet.hiv_observation_refresh')",
            autocommit=True)
            
        hiv_status_tracker_refresh = PostgresOperator(
            task_id="hiv_status_tracker_refresh",
            postgres_conn_id="radet_conn",
            sql="call public.proc_truncate_refresh_tables('expanded_radet.hiv_status_tracker_refresh')",
            autocommit=True)
            
        hivclinicalenrollment_baseappcode_refresh = PostgresOperator(
            task_id="hivclinicalenrollment_baseappcode_refresh",
            postgres_conn_id="radet_conn",
            sql="call public.proc_truncate_refresh_tables('expanded_radet.hivclinicalenrollment_baseappcode_refresh')",
            autocommit=True)
        
        hivregimentype_refresh = PostgresOperator(
            task_id="hivregimentype_refresh",
            postgres_conn_id="radet_conn",
            sql="call public.proc_truncate_refresh_tables('expanded_radet.hivregimentype_refresh')",
            autocommit=True)
            
        ods_pmtct_infant_rapid_antibody = PostgresOperator(
            task_id="ods_pmtct_infant_rapid_antibody",
            postgres_conn_id="radet_conn",
            sql="call public.proc_truncate_refresh_tables('ods_pmtct_infant_rapid_antibody')",
            autocommit=True)
        
        ods_pmtct_infant_visit = PostgresOperator(
            task_id="ods_pmtct_infant_visit",
            postgres_conn_id="radet_conn",
            sql="call public.proc_truncate_refresh_tables('ods_pmtct_infant_visit')",
            autocommit=True)
        
        laboratory_details_refresh = PostgresOperator(
            task_id="laboratory_details_refresh",
            postgres_conn_id="radet_conn",
            sql="call public.proc_truncate_refresh_tables('expanded_radet.laboratory_details_refresh')",
            autocommit=True)
            
        laboratoryorder_hivenrollment_refresh = PostgresOperator(
            task_id="laboratoryorder_hivenrollment_refresh",
            postgres_conn_id="radet_conn",
            sql="call public.proc_truncate_refresh_tables('expanded_radet.laboratoryorder_hivenrollment_refresh')",
            autocommit=True)
        
        laboratorytest_labtest_sample_results_refresh = PostgresOperator(
            task_id="laboratorytest_labtest_sample_results_refresh",
            postgres_conn_id="radet_conn",
            sql="call public.proc_truncate_refresh_tables('expanded_radet.laboratorytest_labtest_sample_results_refresh')",
            autocommit=True)
        
        lastpickup_refresh = PostgresOperator(
            task_id="lastpickup_refresh",
            postgres_conn_id="radet_conn",
            sql="call public.proc_truncate_refresh_tables('expanded_radet.lastpickup_refresh')",
            autocommit=True)
            
        pharmacy_details_regimen_refresh = PostgresOperator(
            task_id="pharmacy_details_regimen_refresh",
            postgres_conn_id="radet_conn",
            sql="call public.proc_truncate_refresh_tables('expanded_radet.pharmacy_details_regimen_refresh')",
            autocommit=True)
        
        recapture_biometric_refresh = PostgresOperator(
            task_id="recapture_biometric_refresh",
            postgres_conn_id="radet_conn",
            sql="call public.proc_truncate_refresh_tables('expanded_radet.recapture_biometric_refresh')",
            autocommit=True)
        
        regimenatstart_refresh = PostgresOperator(
            task_id="regimenatstart_refresh",
            postgres_conn_id="radet_conn",
            sql="call public.proc_truncate_refresh_tables('expanded_radet.regimenatstart_refresh')",
            autocommit=True)
        
        statelgaresidence_refresh = PostgresOperator(
            task_id="statelgaresidence_refresh",
            postgres_conn_id="radet_conn",
            sql="call public.proc_truncate_refresh_tables('expanded_radet.statelgaresidence_refresh')",
            autocommit=True)
            
        sub_current_clinical_refresh = PostgresOperator(
            task_id="sub_current_clinical_refresh",
            postgres_conn_id="radet_conn",
            sql="call public.proc_truncate_refresh_tables('expanded_radet.sub_current_clinical_refresh')",
            autocommit=True)
            
        sub_laboratory_details_refresh = PostgresOperator(
            task_id="sub_laboratory_details_refresh",
            postgres_conn_id="radet_conn",
            sql="call public.proc_truncate_refresh_tables('expanded_radet.sub_laboratory_details_refresh')",
            autocommit=True)
        
        sub_tvs_current_clinical_refresh = PostgresOperator(
            task_id="sub_tvs_current_clinical_refresh",
            postgres_conn_id="radet_conn",
            sql="call public.proc_truncate_refresh_tables('expanded_radet.sub_tvs_current_clinical_refresh')",
            autocommit=True)
        
        tbstatus_tbscreening_refresh = PostgresOperator(
            task_id="tbstatus_tbscreening_refresh",
            postgres_conn_id="radet_conn",
            sql="call public.proc_truncate_refresh_tables('expanded_radet.tbstatus_tbscreening_refresh')",
            autocommit=True)
            
        temp_sub_current_clinical_refresh = PostgresOperator(
            task_id="temp_sub_current_clinical_refresh",
            postgres_conn_id="radet_conn",
            sql="call public.proc_truncate_refresh_tables('expanded_radet.temp_sub_current_clinical_refresh')",
            autocommit=True)
       
    end = BashOperator(
        task_id="end",
        bash_command="echo end")

    # Define the task dependencies
    start >> upstream_tasks >> end
