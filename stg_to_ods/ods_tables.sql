DROP TABLE IF EXISTS public.ods_tables;
CREATE TABLE public.ods_tables AS
select DISTINCT regexp_replace(table_name, '_[0-9]+$', '', 'g') ods_table_name
from information_schema.columns
where table_name ILIKE 'ods_%' 
AND table_name IN
('ods_patient_person','ods_case_manager','ods_case_manager_patients',
'ods_patient_visit','ods_hiv_regimen_resolver','ods_base_application_codeset',
'ods_hiv_art_clinical','ods_hiv_enrollment','ods_hiv_observation',
'ods_hiv_status_tracker','ods_hts_index_elicitation',
'ods_hts_risk_stratification','ods_patient_encounter',
'ods_prep_clinic','ods_prep_enrollment','ods_prep_interruption',
'ods_prep_eligibility','ods_triage_vital_sign','ods_hts_client',
'ods_base_organisation_unit','ods_base_organisation_unit_identifier',
'ods_hiv_regimen','ods_hiv_regimen_type','ods_laboratory_sample',
'ods_laborat
ory_test','ods_laboratory_result','ods_hiv_art_pharmacy',
'ods_laboratory_labtest','ods_hiv_art_pharmacy_regimens','ods_hiv_eac_session',
'ods_biometric','ods_hiv_eac','ods_dsd_devolvement','ods_laboratory_order',
'ods_pmtct_anc','ods_pmtct_delivery','ods_pmtct_enrollment','ods_pmtct_infant_arv',
'ods_pmtct_infant_pcr','ods_pmtct_infant_visit','ods_pmtct_mother_visitation',
'ods_pmtct_infant_information','ods_pmtct_infant_mother_art','ods_pmtct_infant_rapid_antibody')
and table_schema ilike 'public';


CREATE TABLE public.ods_count_monitoring(ip_name character varying,ods_datim_id character varying,
								   table_name character varying,
								   load_time timestamp, current_total_records bigint);