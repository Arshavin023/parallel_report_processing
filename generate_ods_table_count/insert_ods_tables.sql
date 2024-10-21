--
-- PostgreSQL database dump
--

-- Dumped from database version 14.13 (Ubuntu 14.13-0ubuntu0.22.04.1)
-- Dumped by pg_dump version 16.1

-- Started on 2024-10-16 08:46:38

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 4897 (class 0 OID 62367)
-- Dependencies: 577
-- Data for Name: ods_tables; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.ods_tables VALUES ('ods_base_organisation_unit', '(t1.ods_datim_id, t1.id)', 'ods_base_organisation_unit-(t1.ods_datim_id, t1.id)');
INSERT INTO public.ods_tables VALUES ('ods_base_application_codeset', '(t1.ods_datim_id, code)', 'ods_base_application_codeset-(t1.ods_datim_id, code)');
INSERT INTO public.ods_tables VALUES ('ods_base_organisation_unit_identifier', '(t1.ods_datim_id, t1.id)', 'ods_base_organisation_unit_identifier-(t1.ods_datim_id, t1.id)');
INSERT INTO public.ods_tables VALUES ('ods_biometric', '(t1.ods_datim_id, t1.id)', 'ods_biometric-(t1.ods_datim_id, t1.id)');
INSERT INTO public.ods_tables VALUES ('ods_case_manager', '(t1.ods_datim_id, t1.uuid)', 'ods_case_manager-(t1.ods_datim_id, t1.uuid)');
INSERT INTO public.ods_tables VALUES ('ods_case_manager_patients', '(t1.ods_datim_id, t1.id)', 'ods_case_manager_patients-(t1.ods_datim_id, t1.id)');
INSERT INTO public.ods_tables VALUES ('ods_dsd_devolvement', '(t1.ods_datim_id, t1.person_uuid, t1.uuid)', 'ods_dsd_devolvement-(t1.ods_datim_id, t1.person_uuid, t1.uuid)');
INSERT INTO public.ods_tables VALUES ('ods_hiv_art_clinical', '(t1.ods_datim_id, t1.uuid)', 'ods_hiv_art_clinical-(t1.ods_datim_id, t1.uuid)');
INSERT INTO public.ods_tables VALUES ('ods_hiv_art_pharmacy', '(t1.ods_datim_id, t1.uuid)', 'ods_hiv_art_pharmacy-(t1.ods_datim_id, t1.uuid)');
INSERT INTO public.ods_tables VALUES ('ods_hiv_art_pharmacy_regimens', '(t1.art_pharmacy_id, t1.regimens_id, t1.ods_datim_id)', 'ods_hiv_art_pharmacy_regimens-(t1.art_pharmacy_id, t1.regimens_id, t1.ods_datim_id)');
INSERT INTO public.ods_tables VALUES ('ods_hiv_eac', '(t1.ods_datim_id, t1.uuid)', 'ods_hiv_eac-(t1.ods_datim_id, t1.uuid)');
INSERT INTO public.ods_tables VALUES ('ods_hiv_eac_session', '(t1.ods_datim_id, t1.uuid)', 'ods_hiv_eac_session-(t1.ods_datim_id, t1.uuid)');
INSERT INTO public.ods_tables VALUES ('ods_hiv_enrollment', '(t1.ods_datim_id, t1.uuid)', 'ods_hiv_enrollment-(t1.ods_datim_id, t1.uuid)');
INSERT INTO public.ods_tables VALUES ('ods_hiv_observation', '(t1.ods_datim_id, t1.uuid)', 'ods_hiv_observation-(t1.ods_datim_id, t1.uuid)');
INSERT INTO public.ods_tables VALUES ('ods_hiv_regimen', '(t1.ods_datim_id, t1.id)', 'ods_hiv_regimen-(t1.ods_datim_id, t1.id)');
INSERT INTO public.ods_tables VALUES ('ods_hiv_regimen_resolver', '(t1.ods_datim_id,t1.regimensys, t1.regimen)', 'ods_hiv_regimen_resolver-(t1.ods_datim_id,t1.regimensys, t1.regimen)');
INSERT INTO public.ods_tables VALUES ('ods_hiv_regimen_type', '(t1.ods_datim_id, t1.id)', 'ods_hiv_regimen_type-(t1.ods_datim_id, t1.id)');
INSERT INTO public.ods_tables VALUES ('ods_hiv_status_tracker', '(t1.ods_datim_id, t1.uuid)', 'ods_hiv_status_tracker-(t1.ods_datim_id, t1.uuid)');
INSERT INTO public.ods_tables VALUES ('ods_hts_client', '(t1.ods_datim_id, t1.uuid)', 'ods_hts_client-(t1.ods_datim_id, t1.uuid)');
INSERT INTO public.ods_tables VALUES ('ods_hts_index_elicitation', '(t1.ods_datim_id, t1.id)', 'ods_hts_index_elicitation-(t1.ods_datim_id, t1.id)');
INSERT INTO public.ods_tables VALUES ('ods_hts_risk_stratification', '(t1.ods_datim_id, t1.code)', 'ods_hts_risk_stratification-(t1.ods_datim_id, t1.code)');
INSERT INTO public.ods_tables VALUES ('ods_laboratory_labtest', '(t1.ods_datim_id, t1.id)', 'ods_laboratory_labtest-(t1.ods_datim_id, t1.id)');
INSERT INTO public.ods_tables VALUES ('ods_laboratory_test', '(t1.ods_datim_id, t1.id)', 'ods_laboratory_test-(t1.ods_datim_id, t1.id)');
INSERT INTO public.ods_tables VALUES ('ods_laboratory_order', '(t1.ods_datim_id, t1.uuid, t1.patient_id)', 'ods_laboratory_order-(t1.ods_datim_id, t1.uuid, t1.patient_id)');
INSERT INTO public.ods_tables VALUES ('ods_laboratory_result', '(t1.ods_datim_id, t1.id)', 'ods_laboratory_result-(t1.ods_datim_id, t1.id)');
INSERT INTO public.ods_tables VALUES ('ods_laboratory_sample', '(t1.ods_datim_id, t1.id)', 'ods_laboratory_sample-(t1.ods_datim_id, t1.id)');
INSERT INTO public.ods_tables VALUES ('ods_patient_encounter', '(t1.ods_datim_id, t1.uuid)', 'ods_patient_encounter-(t1.ods_datim_id, t1.uuid)');
INSERT INTO public.ods_tables VALUES ('ods_patient_person', '(t1.ods_datim_id,uuid)', 'ods_patient_person-(t1.ods_datim_id,uuid)');
INSERT INTO public.ods_tables VALUES ('ods_patient_visit', '(t1.ods_datim_id, t1.id)', 'ods_patient_visit-(t1.ods_datim_id, t1.id)');
INSERT INTO public.ods_tables VALUES ('ods_pmtct_anc', '(t1.ods_datim_id, t1.person_uuid, t1.id)', 'ods_pmtct_anc-(t1.ods_datim_id, t1.person_uuid, t1.id)');
INSERT INTO public.ods_tables VALUES ('ods_pmtct_delivery', '(t1.id, t1.uuid, t1.person_uuid, t1.ods_datim_id)', 'ods_pmtct_delivery-(t1.id, t1.uuid, t1.person_uuid, t1.ods_datim_id)');
INSERT INTO public.ods_tables VALUES ('ods_pmtct_enrollment', '(t1.id, t1.uuid, t1.person_uuid, t1.ods_datim_id)', 'ods_pmtct_enrollment-(t1.id, t1.uuid, t1.person_uuid, t1.ods_datim_id)');
INSERT INTO public.ods_tables VALUES ('ods_pmtct_infant_arv', '(t1.id, t1.uuid, t1.ods_datim_id)', 'ods_pmtct_infant_arv-(t1.id, t1.uuid, t1.ods_datim_id)');
INSERT INTO public.ods_tables VALUES ('ods_pmtct_infant_information', '(t1.id, t1.uuid, t1.mother_person_uuid, t1.ods_datim_id)', 'ods_pmtct_infant_information-(t1.id, t1.uuid, t1.mother_person_uuid, t1.ods_datim_id)');
INSERT INTO public.ods_tables VALUES ('ods_pmtct_infant_mother_art', '(t1.id, t1.uuid, t1.ods_datim_id)', 'ods_pmtct_infant_mother_art-(t1.id, t1.uuid, t1.ods_datim_id)');
INSERT INTO public.ods_tables VALUES ('ods_pmtct_infant_pcr', '(t1.id, t1.uuid, t1.ods_datim_id)', 'ods_pmtct_infant_pcr-(t1.id, t1.uuid, t1.ods_datim_id)');
INSERT INTO public.ods_tables VALUES ('ods_pmtct_infant_rapid_antibody', '(t1.id, t1.uuid, t1.ods_datim_id,t1.unique_uuid)', 'ods_pmtct_infant_rapid_antibody-(t1.id, t1.uuid, t1.ods_datim_id,t1.unique_uuid)');
INSERT INTO public.ods_tables VALUES ('ods_pmtct_infant_visit', '(t1.id, t1.uuid, t1.ods_datim_id)', 'ods_pmtct_infant_visit-(t1.id, t1.uuid, t1.ods_datim_id)');
INSERT INTO public.ods_tables VALUES ('ods_pmtct_mother_visitation', '(t1.id, t1.person_uuid, uuid, t1.ods_datim_id)', 'ods_pmtct_mother_visitation-(t1.id, t1.person_uuid, uuid, t1.ods_datim_id)');
INSERT INTO public.ods_tables VALUES ('ods_prep_clinic', '(t1.ods_datim_id, t1.uuid)', 'ods_prep_clinic-(t1.ods_datim_id, t1.uuid)');
INSERT INTO public.ods_tables VALUES ('ods_prep_eligibility', '(t1.ods_datim_id, t1.uuid)', 'ods_prep_eligibility-(t1.ods_datim_id, t1.uuid)');
INSERT INTO public.ods_tables VALUES ('ods_prep_enrollment', '(t1.ods_datim_id, t1.uuid)', 'ods_prep_enrollment-(t1.ods_datim_id, t1.uuid)');
INSERT INTO public.ods_tables VALUES ('ods_prep_interruption', '(t1.ods_datim_id, t1.uuid)', 'ods_prep_interruption-(t1.ods_datim_id, t1.uuid)');
INSERT INTO public.ods_tables VALUES ('ods_triage_vital_sign', '(t1.ods_datim_id, t1.uuid)', 'ods_triage_vital_sign-(t1.ods_datim_id, t1.uuid)');


-- Completed on 2024-10-16 08:46:55

--
-- PostgreSQL database dump complete
--

