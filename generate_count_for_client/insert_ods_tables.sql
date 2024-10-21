--
-- PostgreSQL database dump
--

-- Dumped from database version 16.1
-- Dumped by pg_dump version 16.1

-- Started on 2024-10-18 10:35:18

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
-- TOC entry 5570 (class 0 OID 889701)
-- Dependencies: 455
-- Data for Name: ods_tables; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.ods_tables VALUES ('base_organisation_unit', '(t1.id)', 'base_organisation_unit-(t1.id)');
INSERT INTO public.ods_tables VALUES ('base_application_codeset', '(t1.id)', 'base_application_codeset-(t1.id)');
INSERT INTO public.ods_tables VALUES ('base_organisation_unit_identifier', '(t1.id)', 'base_organisation_unit_identifier-(t1.id)');
INSERT INTO public.ods_tables VALUES ('biometric', '(t1.id)', 'biometric-(t1.id)');
INSERT INTO public.ods_tables VALUES ('case_manager', '(t1.id)', 'case_manager-(t1.id)');
INSERT INTO public.ods_tables VALUES ('case_manager_patients', '(t1.id)', 'case_manager_patients-(t1.id)');
INSERT INTO public.ods_tables VALUES ('dsd_devolvement', '(t1.id)', 'dsd_devolvement-(t1.id)');
INSERT INTO public.ods_tables VALUES ('hiv_art_clinical', '(t1.id)', 'hiv_art_clinical-(t1.id)');
INSERT INTO public.ods_tables VALUES ('hiv_art_pharmacy', '(t1.id)', 'hiv_art_pharmacy-(t1.id)');
INSERT INTO public.ods_tables VALUES ('hiv_art_pharmacy_regimens', '(t1.id)', 'hiv_art_pharmacy_regimens-(t1.id)');
INSERT INTO public.ods_tables VALUES ('hiv_eac', '(t1.id)', 'hiv_eac-(t1.id)');
INSERT INTO public.ods_tables VALUES ('hiv_eac_session', '(t1.id)', 'hiv_eac_session-(t1.id)');
INSERT INTO public.ods_tables VALUES ('hiv_enrollment', '(t1.id)', 'hiv_enrollment-(t1.id)');
INSERT INTO public.ods_tables VALUES ('hiv_observation', '(t1.id)', 'hiv_observation-(t1.id)');
INSERT INTO public.ods_tables VALUES ('hiv_regimen', '(t1.id)', 'hiv_regimen-(t1.id)');
INSERT INTO public.ods_tables VALUES ('hiv_regimen_type', '(t1.id)', 'hiv_regimen_type-(t1.id)');
INSERT INTO public.ods_tables VALUES ('hiv_regimen_resolver', '(t1.id)', 'hiv_regimen_resolver-(t1.id)');
INSERT INTO public.ods_tables VALUES ('hiv_status_tracker', '(t1.id)', 'hiv_status_tracker-(t1.id)');
INSERT INTO public.ods_tables VALUES ('hts_client', '(t1.id)', 'hts_client-(t1.id)');
INSERT INTO public.ods_tables VALUES ('hts_index_elicitation', '(t1.id)', 'hts_index_elicitation-(t1.id)');
INSERT INTO public.ods_tables VALUES ('hts_risk_stratification', '(t1.id)', 'hts_risk_stratification-(t1.id)');
INSERT INTO public.ods_tables VALUES ('laboratory_labtest', '(t1.id)', 'laboratory_labtest-(t1.id)');
INSERT INTO public.ods_tables VALUES ('laboratory_test', '(t1.id)', 'laboratory_test-(t1.id)');
INSERT INTO public.ods_tables VALUES ('laboratory_order', '(t1.id)', 'laboratory_order-(t1.id)');
INSERT INTO public.ods_tables VALUES ('laboratory_result', '(t1.id)', 'laboratory_result-(t1.id)');
INSERT INTO public.ods_tables VALUES ('laboratory_sample', '(t1.id)', 'laboratory_sample-(t1.id)');
INSERT INTO public.ods_tables VALUES ('patient_encounter', '(t1.id)', 'patient_encounter-(t1.id)');
INSERT INTO public.ods_tables VALUES ('patient_person', '(t1.id)', 'patient_person-(t1.id)');
INSERT INTO public.ods_tables VALUES ('patient_visit', '(t1.id)', 'patient_visit-(t1.id)');
INSERT INTO public.ods_tables VALUES ('pmtct_anc', '(t1.id)', 'pmtct_anc-(t1.id)');
INSERT INTO public.ods_tables VALUES ('pmtct_delivery', '(t1.id)', 'pmtct_delivery-(t1.id)');
INSERT INTO public.ods_tables VALUES ('pmtct_enrollment', '(t1.id)', 'pmtct_enrollment-(t1.id)');
INSERT INTO public.ods_tables VALUES ('pmtct_infant_arv', '(t1.id)', 'pmtct_infant_arv-(t1.id)');
INSERT INTO public.ods_tables VALUES ('pmtct_infant_information', '(t1.id)', 'pmtct_infant_information-(t1.id)');
INSERT INTO public.ods_tables VALUES ('pmtct_infant_mother_art', '(t1.id)', 'pmtct_infant_mother_art-(t1.id)');
INSERT INTO public.ods_tables VALUES ('pmtct_infant_pcr', '(t1.id)', 'pmtct_infant_pcr-(t1.id)');
INSERT INTO public.ods_tables VALUES ('pmtct_infant_rapid_antibody', '(t1.id)', 'pmtct_infant_rapid_antibody-(t1.id)');
INSERT INTO public.ods_tables VALUES ('pmtct_infant_visit', '(t1.id)', 'pmtct_infant_visit-(t1.id)');
INSERT INTO public.ods_tables VALUES ('pmtct_mother_visitation', '(t1.id)', 'pmtct_mother_visitation-(t1.id)');
INSERT INTO public.ods_tables VALUES ('prep_clinic', '(t1.id)', 'prep_clinic-(t1.id)');
INSERT INTO public.ods_tables VALUES ('prep_eligibility', '(t1.id)', 'prep_eligibility-(t1.id)');
INSERT INTO public.ods_tables VALUES ('prep_enrollment', '(t1.id)', 'prep_enrollment-(t1.id)');
INSERT INTO public.ods_tables VALUES ('prep_interruption', '(t1.id)', 'prep_interruption-(t1.id)');
INSERT INTO public.ods_tables VALUES ('triage_vital_sign', '(t1.id)', 'triage_vital_sign-(t1.id)');


-- Completed on 2024-10-18 10:35:19

--
-- PostgreSQL database dump complete
--

