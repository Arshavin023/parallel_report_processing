--
-- PostgreSQL database dump
--

-- Dumped from database version 14.13 (Ubuntu 14.13-0ubuntu0.22.04.1)
-- Dumped by pg_dump version 14.13 (Ubuntu 14.13-0ubuntu0.22.04.1)

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
-- Name: maternal_cohort; Type: SCHEMA; Schema: -; Owner: lamisplus_etl
--

CREATE SCHEMA maternal_cohort;


ALTER SCHEMA maternal_cohort OWNER TO lamisplus_etl;

--
-- Name: pmtct_hts; Type: SCHEMA; Schema: -; Owner: lamisplus_etl
--

CREATE SCHEMA pmtct_hts;


ALTER SCHEMA pmtct_hts OWNER TO lamisplus_etl;

--
-- Name: dblink; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS dblink WITH SCHEMA public;


--
-- Name: EXTENSION dblink; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION dblink IS 'connect to other PostgreSQL databases from within a database';


--
-- Name: proc_confirm(); Type: PROCEDURE; Schema: maternal_cohort; Owner: lamisplus_etl
--

CREATE PROCEDURE maternal_cohort.proc_confirm()
    LANGUAGE plpgsql
    AS $$

DECLARE start_time TIMESTAMP;
DECLARE end_time TIMESTAMP;
BEGIN
	SELECT TIMEOFDAY() INTO start_time;

DROP TABLE if exists maternal_cohort.confirm_new;

CREATE TABLE maternal_cohort.confirm_new AS 
SELECT * FROM dblink('db_link_ods',
'select uuid,ods_datim_id,date_sample_collected,results,date_result_received_at_facility
FROM public.ods_pmtct_infant_pcr  
where test_type ilike ''%%onfirm%%''
') AS sm(uuid character varying,ods_datim_id character varying,date_sample_collected date,
		 results character varying,date_result_received_at_facility date);

drop table if exists maternal_cohort.confirm;
alter table maternal_cohort.confirm_new rename to confirm;

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO maternal_cohort.maternal_cohort_monitoring (table_name, start_time,end_time) VALUES ('confirm', start_time,end_time);

END
$$;


ALTER PROCEDURE maternal_cohort.proc_confirm() OWNER TO lamisplus_etl;

--
-- Name: proc_first(); Type: PROCEDURE; Schema: maternal_cohort; Owner: lamisplus_etl
--

CREATE PROCEDURE maternal_cohort.proc_first()
    LANGUAGE plpgsql
    AS $$

DECLARE start_time TIMESTAMP;
DECLARE end_time TIMESTAMP;
BEGIN
	SELECT TIMEOFDAY() INTO start_time;

DROP TABLE if exists maternal_cohort.first_new;

CREATE TABLE maternal_cohort.first_new AS 
SELECT * FROM dblink('db_link_ods',
'select uuid,ods_datim_id,date_sample_collected,results,date_result_received_at_facility
FROM public.ods_pmtct_infant_pcr  
where test_type ilike ''%%First%%''
') AS sm(uuid character varying,ods_datim_id character varying,date_sample_collected date,
		 results character varying,date_result_received_at_facility date);

drop table if exists maternal_cohort.first;
alter table maternal_cohort.first_new rename to first;

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO maternal_cohort.maternal_cohort_monitoring (table_name, start_time,end_time) 
VALUES ('first', start_time,end_time);

END
$$;


ALTER PROCEDURE maternal_cohort.proc_first() OWNER TO lamisplus_etl;

--
-- Name: proc_hiv_observation(); Type: PROCEDURE; Schema: maternal_cohort; Owner: lamisplus_etl
--

CREATE PROCEDURE maternal_cohort.proc_hiv_observation()
    LANGUAGE plpgsql
    AS $$

DECLARE start_time TIMESTAMP;
DECLARE end_time TIMESTAMP;
BEGIN
	SELECT TIMEOFDAY() INTO start_time;

DROP TABLE if exists maternal_cohort.hiv_observation_new;

CREATE TABLE maternal_cohort.hiv_observation_new AS 
SELECT * FROM dblink('db_link_ods',
'select distinct on (person_uuid,ods_datim_id) person_uuid,ods_datim_id,
date_of_observation,ho.data->''tbIptScreening''->>''outcome'' AS tb_screening_status
from public.ods_hiv_observation ho
WHERE archived=0 AND ho.data->''tbIptScreening''->>''outcome'' IS NOT NULL 
AND ho.data->''tbIptScreening''->>''outcome'' != ''''
')
AS sm(person_uuid character varying,ods_datim_id character varying,
	 date_of_observation date, tb_screening_status character varying);

drop table if exists maternal_cohort.hiv_observation;
alter table maternal_cohort.hiv_observation_new rename to hiv_observation;

DROP INDEX IF EXISTS idx_tbIptScreening_outcome;
CREATE INDEX idx_tbIptScreening_outcome ON maternal_cohort.hiv_observation (tb_screening_status);
	
SELECT TIMEOFDAY() INTO end_time;
INSERT INTO maternal_cohort.maternal_cohort_monitoring (table_name, start_time,end_time) 
VALUES ('hiv_observation', start_time,end_time);

END
$$;


ALTER PROCEDURE maternal_cohort.proc_hiv_observation() OWNER TO lamisplus_etl;

--
-- Name: proc_pmtct_anc(); Type: PROCEDURE; Schema: maternal_cohort; Owner: lamisplus_etl
--

CREATE PROCEDURE maternal_cohort.proc_pmtct_anc()
    LANGUAGE plpgsql
    AS $$

DECLARE start_time TIMESTAMP;
DECLARE end_time TIMESTAMP;
BEGIN
	SELECT TIMEOFDAY() INTO start_time;

DROP TABLE if exists maternal_cohort.pmtct_anc_new;

CREATE TABLE maternal_cohort.pmtct_anc_new AS 
SELECT * FROM dblink('db_link_ods',
'SELECT person_uuid AS person_uuid_anc,ods_datim_id,anc_setting AS anc_setting_anc,
first_anc_date AS first_anc_date,lmp,gaweeks AS gaweeks_anc,
gravida AS gravida_anc,parity As parity_anc,tested_syphilis AS tested_syphilis_anc,
test_result_syphilis AS test_result_syphilis_anc,treated_syphilis,
partner_information->>''age'' AS age,partner_information->>''syphillisStatus'' AS syphillisStatus,
partner_information->>''acceptHivTest'' AS acceptHivTest,
partner_information->>''referredTo'' AS referredTo,pmtct_hts_info->>''hivRestested'' AS hivRestested,
pmtct_hts_info->>''hivTestResult'' AS hivTestResult,
pmtct_hts_info->>''acceptedHIVTesting'' AS acceptedHIVTesting,
pmtct_hts_info->>''dateTestedHivPositive'' AS dateTestedHivPositive,
pmtct_hts_info->>''receivedHivRetestedResult'' AS receivedHivRetestedResult,
pmtct_hts_info->>''previouslyKnownHIVPositive'' AS previouslyKnownHIVPositive,anc_no AS anc_no,
static_hiv_status 
FROM public.ods_pmtct_anc')
AS sm(person_uuid_anc character varying(255),ods_datim_id character varying(50),
    anc_setting_anc character varying(255),first_anc_date date,lmp date,gaweeks_anc integer,
    gravida_anc integer,parity_anc integer,tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),treated_syphilis character varying(255),
    age text,syphillisstatus text,accepthivtest text,referredto text,hivrestested text,
    hivtestresult text,acceptedhivtesting text,datetestedhivpositive text,
    receivedhivretestedresult text,previouslyknownhivpositive text,anc_no character varying(255),
    static_hiv_status character varying(255));

drop table if exists maternal_cohort.pmtct_anc;
alter table maternal_cohort.pmtct_anc_new rename to pmtct_anc;

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO maternal_cohort.maternal_cohort_monitoring(table_name, start_time,end_time) 
VALUES ('pmtct_anc', start_time,end_time);

END
$$;


ALTER PROCEDURE maternal_cohort.proc_pmtct_anc() OWNER TO lamisplus_etl;

--
-- Name: proc_pmtct_delivery(); Type: PROCEDURE; Schema: maternal_cohort; Owner: lamisplus_etl
--

CREATE PROCEDURE maternal_cohort.proc_pmtct_delivery()
    LANGUAGE plpgsql
    AS $$

DECLARE start_time TIMESTAMP;
DECLARE end_time TIMESTAMP;
BEGIN
	SELECT TIMEOFDAY() INTO start_time;

DROP TABLE if exists maternal_cohort.pmtct_delivery_new;

CREATE TABLE maternal_cohort.pmtct_delivery_new AS 
SELECT * FROM dblink('db_link_ods',
'SELECT distinct on (person_uuid,ods_datim_id) person_uuid, ods_datim_id,anc_no, 
facility_id, hospital_number,uuid, date_of_delivery, booking_status, 
gaweeks, rom_delivery_interval,mode_of_delivery, episiotomy, vaginal_tear, feeding_decision, 
maternal_outcome, child_status, hiv_exposed_infant_given_hb_within24hrs,child_given_arv_within72,
delivery_time, on_art, art_started_ld_ward, hbstatus, hcstatus, referal_source,
number_of_infants_alive, number_of_infants_dead, place_of_delivery, 
non_hbv_exposed_infant_given_hb_within_24hrs
from public.ods_pmtct_delivery')
AS sm(person_uuid character varying,ods_datim_id character varying(50),anc_no character varying(255),
    facility_id bigint,hospital_number character varying(255),uuid character varying(255),
    date_of_delivery date,booking_status character varying(255), gaweeks bigint,
    rom_delivery_interval character varying(255),mode_of_delivery character varying(255),
    episiotomy character varying(255),vaginal_tear character varying(255),feeding_decision character varying(255),
    maternal_outcome character varying(255),child_status character varying(255),
    hiv_exposed_infant_given_hb_within24hrs character varying(255),
    child_given_arv_within72 character varying(255),delivery_time character varying(255),
    on_art character varying(255),art_started_ld_ward character varying(255),
    hbstatus character varying(255),hcstatus character varying(255),referal_source character varying(255),
    number_of_infants_alive bigint,number_of_infants_dead bigint,place_of_delivery character varying(255),
    non_hbv_exposed_infant_given_hb_within_24hrs character varying);

drop table if exists maternal_cohort.pmtct_delivery;
alter table maternal_cohort.pmtct_delivery_new rename to pmtct_delivery;

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO maternal_cohort.maternal_cohort_monitoring (table_name, start_time,end_time) VALUES ('pmtct_delivery', start_time,end_time);

END
$$;


ALTER PROCEDURE maternal_cohort.proc_pmtct_delivery() OWNER TO lamisplus_etl;

--
-- Name: proc_pmtct_maternal_cohort(); Type: PROCEDURE; Schema: maternal_cohort; Owner: lamisplus_etl
--

CREATE PROCEDURE maternal_cohort.proc_pmtct_maternal_cohort()
    LANGUAGE plpgsql
    AS $$
DECLARE start_time TIMESTAMP;
DECLARE end_time TIMESTAMP;
DECLARE partition_name TEXT;
DECLARE period_date DATE;
DECLARE period_text TEXT;
DECLARE period_start DATE;
DECLARE period_end DATE;

BEGIN

SELECT TIMEOFDAY() INTO start_time;

SELECT start_date INTO period_start
FROM pmtct_hts.period WHERE is_active;

SELECT date INTO period_end
FROM pmtct_hts.period WHERE is_active;

SELECT CONCAT('maternalcohort_',periodcode) 
INTO partition_name
from pmtct_hts.period where is_active;

SELECT periodid 
INTO period_text
from pmtct_hts.period where is_active;

SELECT date INTO period_date 
FROM pmtct_hts.period where is_active;

EXECUTE format('TRUNCATE public.%I',partition_name);

-- EXECUTE format('CREATE TABLE maternal_cohort.%I 
-- 			   PARTITION OF maternal_cohort.pmtct_maternal_cohort_weekly
-- FOR VALUES IN (%L)', partition_name, period_text);

--EXECUTE format('ALTER TABLE maternal_cohort.%I
--			   ADD CONSTRAINT %I_check CHECK (period_start_date >= %L 
--			   and period_end_date <= %L)', partition_name,partition_name,period_start,period_end);

EXECUTE format('INSERT INTO public.%I
select %L as period,
"Patient ID",
    "State",
    "LGA",
    "Datim ID",
    "Facility",
    "Mother Hospital Number",
    "Mother Unique ID",
    "Mother Date of Birth",
    "Age" numeric,
    "Marital Status",
    "ANC Setting",
    "Modality",
    "Point of Entry",
    "Date of Index ANC Registration",
    "LMP Date",
    "Gestational Age (Weeks) @ First ANC visit",
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration",
    "Hepatitis B Test Result",
    "Treated for Hepatitis B",
    "Syphilis Test Result",
    "TB screening Status",
    "Date tested for HIV",
    "Type of HIV test",
    "Mother ART Start Date",
    "Timing of ART initiation in mother",
    "Current Pregnancy Status",
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status",
    "Visit Status",
    "Mother DSD Status",
    "Due Date for VL Sample collection @ 32 weeks",
    "Date for VL sample collection @ 32 weeks",
    "VL result at 32-36 weeks GA",
    "Current Viral load Result",
    "Date of Current VL" date,
    "Expected Date of Delivery",
    "Place of Delivery",
    "Mode of Delivery",
    "Fetal outcome (Child status)",
    "Child hospital ID number",
    "Sex - Child",
    "Birth Weight",
    "Date of ARV Prophylaxis Commencemment",
    "Type of Prophylaxis (ePNP or regular)",
    "Date of CTX (Cotrimoxazole)",
    "Current infant fedding options",
    "Date of First DNA PCR Sample collection",
    "Result of first DNA PCR test",
    "Date of Second DNA PCR test sample collection",
    "Result of second DNA PCR test",
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection",
    "Result of confirmatory DNA PCR test",
    "Date confirmatory DNA PCT result was received",
    "Sample collection date for Confirmatory DBS (if DBS positive)",
    "Result of Confirmatory DBS",
    "Date of Child Final Outcome test",
    "Result (Child Final Outcome)",
    "Child ART Start Date",
    "Child Unique ID",
%L as period_start_date,
%L as period_end_date
FROM maternal_cohort.pmtct_maternal_cohort_joined', 
partition_name, period_text, period_start, period_end);

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO maternal_cohort.maternal_cohort_monitoring (table_name, start_time,end_time) 
VALUES ('pmtct_maternal_cohort', start_time,end_time);

END
$$;


ALTER PROCEDURE maternal_cohort.proc_pmtct_maternal_cohort() OWNER TO lamisplus_etl;

--
-- Name: proc_pmtct_maternal_cohort_joined(); Type: PROCEDURE; Schema: maternal_cohort; Owner: lamisplus_etl
--

CREATE PROCEDURE maternal_cohort.proc_pmtct_maternal_cohort_joined()
    LANGUAGE plpgsql
    AS $$

DECLARE start_time TIMESTAMP;
DECLARE end_time TIMESTAMP;
BEGIN
SELECT TIMEOFDAY() INTO start_time;

DROP TABLE IF EXISTS maternal_cohort.temp_pmtct_mother_visitation;
CREATE TABLE maternal_cohort.temp_pmtct_mother_visitation AS 
SELECT * FROM dblink('db_link_ods',
'SELECT DISTINCT ON (person_uuid,ods_datim_id) person_uuid,ods_datim_id,
date_of_viral_load,result_of_viral_load
from public.ods_pmtct_mother_visitation
where ga_of_viral_load > 32
ORDER BY person_uuid,ods_datim_id,date_of_viral_load ASC')
AS sm(person_uuid character varying, ods_datim_id character varying,
	  date_of_viral_load date,result_of_viral_load smallint);

CREATE INDEX personuuiddatim_pmtctmothervisitation
ON maternal_cohort.temp_pmtct_mother_visitation(person_uuid,ods_datim_id);

DROP TABLE if exists maternal_cohort.pmtct_maternal_cohort_joined_new;
CREATE TABLE maternal_cohort.pmtct_maternal_cohort_joined_new AS 
SELECT DISTINCT ON (p.uuid, p.ods_datim_id)p.uuid AS "Patient ID",
cpm.facility_state as "State", 
cpm.facility_lga as "LGA", 
cpm.ip_name AS "IP Name",
p.ods_datim_id as "Datim ID", 
cpm.facility_name as "Facility",
'XXXXXX' as "Mother Hospital Number", 
p.unique_id as "Mother Unique ID",p.date_of_birth as "Mother Date of Birth", 
EXTRACT(YEAR from AGE(NOW(),  p.date_of_birth))"Age",
p.maritalstatus as "Marital Status", 
(case when anc_setting_anc is null then null 
when anc_setting_anc ilike '%acility%' then 'Facility' else 'Community' end) as "ANC Setting", 
anc.anc_setting_anc as "Modality",p.pmtctenroll_entrypoint as "Point of Entry",anc.first_anc_date 
as "Date of Index ANC Registration", 
(case when anc.anc_no is not null then anc.lmp else p.pmtctenroll_lmp end) AS "LMP Date", 
anc.gaweeks_anc as "Gestational Age (Weeks) @ First ANC visit", 
(case when anc.anc_no is not null then anc.gravida_anc else p.pmtctenroll_gravida end) as "Gravida", anc.parity_anc  as "Parity", 
'' as "PCV @ANC registration", p.pmtctenroll_hepatitisb as "Hepatitis B Test Result",anc.treated_syphilis  as "Treated for Hepatitis B", 
anc.test_result_syphilis_anc as "Syphilis Test Result", ho.tb_screening_status as "TB screening Status",
'' as "Date tested for HIV",'' as "Type of HIV test",p.pmtctenroll_art_start_date as "Mother ART Start Date",
p.pmtctenroll_art_start_time as "Timing of ART initiation in mother",
p.pregnancystatus as "Current Pregnancy Status",
pmv.ga_of_viral_load as "GA at last viisit (weeks)",
p.currentstatus as "Mother Current ART Status",
pmv.visit_status as "Visit Status",pmv.dsd_option as "Mother DSD Status",
anc.lmp + interval '32 weeks' as "Due Date for VL Sample collection @ 32 weeks",
mv.date_of_viral_load "Date for VL sample collection @ 32 weeks",
mv.result_of_viral_load "VL result at 32-36 weeks GA", 
cvl.currentviralload as "Current Viral load Result",
cvl.dateofcurrentviralload as "Date of Current VL",
delivery.date_of_delivery as "Expected Date of Delivery",
delivery.place_of_delivery as "Place of Delivery",delivery.mode_of_delivery as "Mode of Delivery",
delivery.child_status as "Fetal outcome (Child status)",'XXXXXX' as "Child hospital ID number",
p.pmtctinfantinfo_sex as "Sex - Child",p.pmtctinfantinfo_body_weight as "Birth Weight",
p.pmtctinfantarv_infant_art_time as "Date of ARV Prophylaxis Commencemment",
p.pmtctinfantarv_infant_art_type as "Type of Prophylaxis (ePNP or regular)",
p.pmtctinfantarv_age_at_ctx as "Date of CTX (Cotrimoxazole)",delivery.feeding_decision as "Current infant fedding options",
first.date_result_received_at_facility as "Date of First DNA PCR Sample collection",
first.results as "Result of first DNA PCR test",second.date_sample_collected as "Date of Second DNA PCR test sample collection",
second.results as "Result of second DNA PCR test",second.date_result_received_at_facility as "Date second DNA PCR result was received",
confirm.date_sample_collected as "Date of confirmatory DNA PCR test sample collection",confirm.results as "Result of confirmatory DNA PCR test",
confirm.date_result_received_at_facility as "Date confirmatory DNA PCT result was received",'' as "Sample collection date for Confirmatory DBS (if DBS positive)",
'' as "Result of Confirmatory DBS",'' as "Date of Child Final Outcome test",'' as "Result (Child Final Outcome)",
'' as "Child ART Start Date",'XXXXXX' as "Child Unique ID"
FROM (SELECT * FROM dblink('db_link_radet',
'SELECT PersonUuid uuid,bio_ods_datim_id ods_datim_id,p.hospitalnumber hospital_number,p.gender,
p.dateofbirth date_of_birth,maritalstatus,p.dateofregistration,p.facilityname,p.state,p.lga,
p.uniqueid unique_id,dateOfConfirmedHiv date_confirmed_hiv,p.dateofenrollment date_of_registration, 
datestartedhivenrollment date_started,
pmtctenroll_entrypoint,pmtctenroll_lmp,pmtctenroll_gravida,pmtctenroll_hepatitisb,
pmtctenroll_art_start_date,pmtctenroll_art_start_time,
pmtctinfantinfo_sex,pmtctinfantinfo_body_weight,pmtctinfantarv_infant_art_time,pmtctinfantarv_infant_art_type,
pmtctinfantarv_age_at_ctx,ast.currentstatus,ast.pregnancystatus
FROM expanded_radet.patient_bio_data p
LEFT JOIN public.final_radet ast on p.PersonUuid = ast.uniquepersonuuid and p.bio_ods_datim_id=ast.datim_id
WHERE p.gender=''Female''
')
AS sm(uuid character varying,ods_datim_id character varying,
	  hospital_number character varying,gender text,date_of_birth date,maritalstatus text,
	  dateofregistration date,facilityname character varying,state character varying,
	 lga character varying,unique_id character varying,date_confirmed_hiv date,
	 date_of_registration date, date_started date,pmtctenroll_entrypoint character varying, 
	 pmtctenroll_lmp date, pmtctenroll_gravida integer, 
	pmtctenroll_hepatitisb character varying, pmtctenroll_art_start_date date, 
	pmtctenroll_art_start_time character varying, pmtctinfantinfo_sex character varying,
	pmtctinfantinfo_body_weight double precision, pmtctinfantarv_infant_art_time character varying,
	pmtctinfantarv_infant_art_type character varying, pmtctinfantarv_age_at_ctx character varying,
	 currentstatus character varying, pregnancystatus character varying)) p
LEFT JOIN central_partner_mapping cpm ON p.ods_datim_id=cpm.datim_id
left JOIN maternal_cohort.hiv_observation ho on ho.person_uuid = p.uuid and ho.ods_datim_id=p.ods_datim_id
LEFT JOIN pmtct_hts.result r ON r.uuid=p.uuid and r.ods_datim_id=p.ods_datim_id
LEFT JOIN maternal_cohort.pmtct_anc anc ON p.uuid = anc.person_uuid_anc and p.ods_datim_id=anc.ods_datim_id
LEFT JOIN maternal_cohort.pmtct_delivery delivery ON p.uuid = delivery.person_uuid and p.ods_datim_id=delivery.ods_datim_id
left join maternal_cohort.pmtct_mother_visitation pmv on pmv.person_uuid = p.uuid and pmv.ods_datim_id=p.ods_datim_id
left join maternal_cohort.first first on first.uuid = p.uuid and first.ods_datim_id=p.ods_datim_id
left join maternal_cohort.second second on second.uuid = p.uuid and second.ods_datim_id=p.ods_datim_id
LEFT JOIN maternal_cohort.temp_pmtct_mother_visitation mv ON mv.person_uuid=p.uuid AND mv.ods_datim_id=p.ods_datim_id
left join maternal_cohort.confirm confirm on confirm.uuid = p.uuid and confirm.ods_datim_id=p.ods_datim_id
left join (SELECT * FROM dblink('db_link_radet',
'SELECT DISTINCT ON (patient_uuid, ods_datim_id) patient_uuid,ods_datim_id,
result currentviralload,date_result_reported dateofcurrentviralload
FROM expanded_radet."lab_test_results_refresh_Viral_Load"
WHERE date_result_reported IS NOT NULL
ORDER BY patient_uuid, ods_datim_id, date_result_reported DESC')
AS sm(patient_uuid character varying,ods_datim_id character varying,
	 currentviralload character varying, dateofcurrentviralload date)) cvl on cvl.patient_uuid = p.uuid and cvl.ods_datim_id=p.ods_datim_id
WHERE anc.anc_no is not null or p.pmtctenroll_entrypoint ilike '%PMTCT_ENTRY%'
and p.dateofregistration BETWEEN CAST('1980-01-01' AS DATE) 
AND (SELECT date FROM pmtct_hts.period WHERE is_active);

drop table if exists maternal_cohort.pmtct_maternal_cohort_joined;
alter table maternal_cohort.pmtct_maternal_cohort_joined_new rename to pmtct_maternal_cohort_joined;

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO maternal_cohort.maternal_cohort_monitoring(table_name, start_time,end_time) VALUES ('pmtct_maternal_cohort_joined', start_time,end_time);

END
$$;


ALTER PROCEDURE maternal_cohort.proc_pmtct_maternal_cohort_joined() OWNER TO lamisplus_etl;

--
-- Name: proc_pmtct_mother_visitation(); Type: PROCEDURE; Schema: maternal_cohort; Owner: lamisplus_etl
--

CREATE PROCEDURE maternal_cohort.proc_pmtct_mother_visitation()
    LANGUAGE plpgsql
    AS $$

DECLARE start_time TIMESTAMP;
DECLARE end_time TIMESTAMP;
BEGIN
	SELECT TIMEOFDAY() INTO start_time;

DROP TABLE if exists maternal_cohort.pmtct_mother_visitation_new;

CREATE TABLE maternal_cohort.pmtct_mother_visitation_new AS 
SELECT * FROM dblink('db_link_ods',
'select distinct on (person_uuid,ods_datim_id) person_uuid,ods_datim_id,date_of_visit,
dsd_option,visit_status,ga_of_viral_load 
FROM public.ods_pmtct_mother_visitation')
AS sm(person_uuid character varying,ods_datim_id character varying,date_of_visit date,
	 dsd_option character varying, visit_status character varying,ga_of_viral_load smallint);

drop table if exists maternal_cohort.pmtct_mother_visitation;
alter table maternal_cohort.pmtct_mother_visitation_new rename to pmtct_mother_visitation;

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO maternal_cohort.maternal_cohort_monitoring (table_name, start_time,end_time) VALUES ('pmtct_mother_visitation', start_time,end_time);
END
$$;


ALTER PROCEDURE maternal_cohort.proc_pmtct_mother_visitation() OWNER TO lamisplus_etl;

--
-- Name: proc_second(); Type: PROCEDURE; Schema: maternal_cohort; Owner: lamisplus_etl
--

CREATE PROCEDURE maternal_cohort.proc_second()
    LANGUAGE plpgsql
    AS $$

DECLARE start_time TIMESTAMP;
DECLARE end_time TIMESTAMP;
BEGIN
	SELECT TIMEOFDAY() INTO start_time;

DROP TABLE if exists maternal_cohort.second_new;

CREATE TABLE maternal_cohort.second_new AS 
SELECT * FROM dblink('db_link_ods',
'select uuid,ods_datim_id,date_sample_collected,results,date_result_received_at_facility
FROM public.ods_pmtct_infant_pcr  
where test_type ilike ''%%Second%%''
') AS sm(uuid character varying,ods_datim_id character varying,date_sample_collected date,
		 results character varying,date_result_received_at_facility date);

drop table if exists maternal_cohort.second;
alter table maternal_cohort.second_new rename to second;
SELECT TIMEOFDAY() INTO end_time;
INSERT INTO maternal_cohort.maternal_cohort_monitoring (table_name, start_time,end_time) 
VALUES ('second', start_time,end_time);

END
$$;


ALTER PROCEDURE maternal_cohort.proc_second() OWNER TO lamisplus_etl;

--
-- Name: proc_stream_maternal_cohort(); Type: PROCEDURE; Schema: maternal_cohort; Owner: lamisplus_etl
--

CREATE PROCEDURE maternal_cohort.proc_stream_maternal_cohort()
    LANGUAGE plpgsql
    AS $$
DECLARE start_time TIMESTAMP;
DECLARE end_time TIMESTAMP;

BEGIN

SELECT TIMEOFDAY() INTO start_time;

INSERT INTO public.maternal_cohort
SELECT * FROM maternal_cohort.pmtct_maternal_cohort_weekly;

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO maternal_cohort.cte_monitoring(table_name, start_time,end_time) 
VALUES ('maternal_cohort', start_time,end_time);
		 
END 
$$;


ALTER PROCEDURE maternal_cohort.proc_stream_maternal_cohort() OWNER TO lamisplus_etl;

--
-- Name: proc_hts_client(); Type: PROCEDURE; Schema: pmtct_hts; Owner: lamisplus_etl
--

CREATE PROCEDURE pmtct_hts.proc_hts_client()
    LANGUAGE plpgsql
    AS $$

DECLARE start_time TIMESTAMP;
DECLARE end_time TIMESTAMP;

BEGIN
	SELECT TIMEOFDAY() INTO start_time;

DROP TABLE if exists pmtct_hts.hts_client_new;

CREATE TABLE pmtct_hts.hts_client_new AS 
SELECT * FROM dblink('db_link_ods',
'SELECT hts_client.*,hts_rst.entry_point,pmtctenroll.pmtct_enrollment_date,
pmtctdov.date_of_viral_load,bac.display
FROM (SELECT person_uuid as person_uuid_hts_client,ods_datim_id,
hiv_test_result2 as hiv_test_result2_hts_client,
risk_stratification_code as risk_stratification_code_hts_client,
hepatitis_testing->>''hepatitisBTestResult'' AS hepatitisBTestResult,
hepatitis_testing->>''hepatitisCTestResult'' AS hepatitisCTestResult,
recency->>''optOutRTRI'' AS optOutRTRI,
CASE WHEN recency->>''optOutRTRI'' = ''false'' THEN ''No''
WHEN recency->>''optOutRTRI'' = ''true'' THEN ''Yes'' ELSE ''False'' END AS optOutRTRI_status,
recency->>''rencencyId'' AS rencencyId, recency->>''sampleType'' AS sampleType,
recency->>''optOutRTRITestDate'' AS rencencyTestDate, 
recency->>''rencencyInterpretation'' AS rencencyInterpretation,
recency->>''finalRecencyResult'' AS finalRecencyResult,
date_created as date_created_hts_client, MAX(date_created) AS max_date_created_hts_client, date_visit 
FROM ods_hts_client 
GROUP BY person_uuid,ods_datim_id, date_visit, hiv_test_result2,risk_stratification_code,
hepatitis_testing,date_created,recency,optOutRTRI
HAVING COUNT(person_uuid) > 1) hts_client
LEFT JOIN public.ods_hts_risk_stratification hts_rst ON  hts_rst.code = hts_client.risk_stratification_code_hts_client and hts_rst.ods_datim_id=hts_client.ods_datim_id
LEFT JOIN public.ods_pmtct_enrollment pmtctenroll ON hts_client.person_uuid_hts_client = pmtctenroll.person_uuid and hts_client.ods_datim_id=pmtctenroll.ods_datim_id
LEFT JOIN public.ods_pmtct_mother_visitation pmtctdov ON hts_client.person_uuid_hts_client = pmtctdov.person_uuid and hts_client.ods_datim_id=pmtctdov.ods_datim_id
LEFT JOIN public.ods_base_application_codeset bac ON hts_rst.modality = bac.code and hts_rst.ods_datim_id=bac.ods_datim_id
')
AS sm(person_uuid_hts_client character varying,ods_datim_id character varying(255),
    hiv_test_result2_hts_client character varying,risk_stratification_code_hts_client character varying,
    hepatitisbtestresult text,hepatitisctestresult text,optoutrtri text,
    optoutrtri_status text,rencencyid text,sampletype text,rencencytestdate text,
    rencencyinterpretation text,finalrecencyresult text,date_created_hts_client timestamp without time zone,
    max_date_created_hts_client timestamp without time zone,date_visit date,
	entry_point character varying,pmtct_enrollment_date date,date_of_viral_load date,
	display character varying);

drop table if exists pmtct_hts.hts_client;
alter table pmtct_hts.hts_client_new rename to hts_client;

drop index if exists idx_htsclient_uuidodsdatimid;
create index idx_htsclient_uuidodsdatimid 
on pmtct_hts.hts_client(person_uuid_hts_client,ods_datim_id);

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO pmtct_hts.pmtct_hts_monitoring (table_name, start_time,end_time) 
VALUES ('hts_client', start_time, end_time);

END
$$;


ALTER PROCEDURE pmtct_hts.proc_hts_client() OWNER TO lamisplus_etl;

--
-- Name: proc_loop_through_lists(); Type: PROCEDURE; Schema: pmtct_hts; Owner: lamisplus_etl
--

CREATE PROCEDURE pmtct_hts.proc_loop_through_lists()
    LANGUAGE plpgsql
    AS $$
DECLARE
    inputs text[];
    input text;
    partition_name text;
BEGIN
    -- Populate the array with values from the existing table
    SELECT array_agg(periodid) 
    INTO inputs
    FROM pmtct_hts.period;

    -- Loop through each input value and execute the dynamic query
    FOREACH input IN ARRAY inputs
    LOOP
        partition_name := CONCAT('pmtct_hts_', input);
        
		EXECUTE format('
            DROP TABLE IF EXISTS pmtct_hts.%I 
           ', partition_name);
			
        -- Loop through and create partitions
        EXECUTE format('
            CREATE TABLE IF NOT EXISTS pmtct_hts.%I 
            PARTITION OF pmtct_hts.pmtct_hts_weekly
            FOR VALUES IN (%L)', partition_name, input);
    END LOOP;
END;
$$;


ALTER PROCEDURE pmtct_hts.proc_loop_through_lists() OWNER TO lamisplus_etl;

--
-- Name: proc_pmtct_anc(); Type: PROCEDURE; Schema: pmtct_hts; Owner: lamisplus_etl
--

CREATE PROCEDURE pmtct_hts.proc_pmtct_anc()
    LANGUAGE plpgsql
    AS $$

DECLARE start_time TIMESTAMP;
DECLARE end_time TIMESTAMP;
BEGIN
	SELECT TIMEOFDAY() INTO start_time;

DROP TABLE if exists pmtct_hts.pmtct_anc_new;

CREATE TABLE pmtct_hts.pmtct_anc_new AS 
SELECT * FROM dblink('db_link_ods',
'SELECT person_uuid AS person_uuid_anc,ods_datim_id,
anc_setting AS anc_setting_anc,
previously_known_hiv_status,
first_anc_date AS first_anc_date,
gaweeks AS gaweeks_anc,
gravida AS gravida_anc,
parity As parity_anc,
tested_syphilis AS tested_syphilis_anc,
test_result_syphilis AS test_result_syphilis_anc,
CASE
WHEN treated_syphilis = ''Yes'' THEN ''Treated''
WHEN referred_syphilis_treatment = ''Yes'' THEN ''Referred for Treatment''
ELSE ''No treatment''
END as syphilis_treatment_status,
partner_information->>''age'' AS age,
partner_information->>''syphillisStatus'' AS syphillisStatus,
partner_information->>''acceptHivTest'' AS acceptHivTest,
partner_information->>''referredTo'' AS referredTo,
pmtct_hts_info->>''hivRestested'' AS hivRestested,
pmtct_hts_info->>''hivTestResult'' AS hivTestResult,
pmtct_hts_info->>''acceptedHIVTesting'' AS acceptedHIVTesting,
pmtct_hts_info->>''dateTestedHivPositive'' AS dateTestedHivPositive,
pmtct_hts_info->>''receivedHivRetestedResult'' AS receivedHivRetestedResult,
pmtct_hts_info->>''previouslyKnownHIVPositive'' AS previouslyKnownHIVPositive,
anc_no AS anc_no,
static_hiv_status,
MAX(created_date) AS max_created_date_anc
FROM ods_pmtct_anc
GROUP BY person_uuid,ods_datim_id, anc_setting, first_anc_date, gaweeks, gravida, 
parity, tested_syphilis, test_result_syphilis, partner_information, anc_no, static_hiv_status, 
pmtct_hts_info,syphilis_treatment_status,previously_known_hiv_status')
AS sm(person_uuid_anc character varying(255),ods_datim_id character varying(50),
    anc_setting_anc character varying(255),previously_known_hiv_status character varying,
    first_anc_date date,gaweeks_anc integer,gravida_anc integer,parity_anc integer,
    tested_syphilis_anc character varying(255),test_result_syphilis_anc character varying(255),
    syphilis_treatment_status text,age text,syphillisstatus text,accepthivtest text,
    referredto text,hivrestested text,hivtestresult text,acceptedhivtesting text,
    datetestedhivpositive text,receivedhivretestedresult text,previouslyknownhivpositive text,
    anc_no character varying(255),static_hiv_status character varying(255),
    max_created_date_anc timestamp without time zone);

drop table if exists pmtct_hts.pmtct_anc;
alter table pmtct_hts.pmtct_anc_new rename to pmtct_anc;

drop index if exists idx_pmtctanc_uuidodsdatimid;
create index idx_pmtctanc_uuidodsdatimid 
on pmtct_hts.pmtct_anc(person_uuid_anc,ods_datim_id);

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO pmtct_hts.pmtct_hts_monitoring  (table_name, start_time,end_time) VALUES ('pmtct_anc', start_time,end_time);

END
$$;


ALTER PROCEDURE pmtct_hts.proc_pmtct_anc() OWNER TO lamisplus_etl;

--
-- Name: proc_pmtct_delivery(); Type: PROCEDURE; Schema: pmtct_hts; Owner: lamisplus_etl
--

CREATE PROCEDURE pmtct_hts.proc_pmtct_delivery()
    LANGUAGE plpgsql
    AS $$

DECLARE start_time TIMESTAMP;
DECLARE end_time TIMESTAMP;
BEGIN
	SELECT TIMEOFDAY() INTO start_time;

DROP TABLE if exists pmtct_hts.sub_pmtct_delivery;
CREATE TABLE pmtct_hts.sub_pmtct_delivery AS 
SELECT * FROM dblink('db_link_ods',
'SELECT person_uuid AS person_uuid_delivery,ods_datim_id,
hbstatus AS hbstatus_delivery,created_date,
ROW_NUMBER() OVER (PARTITION BY person_uuid,ods_datim_id ORDER BY created_date DESC)
FROM ods_pmtct_delivery')
AS sm(person_uuid_delivery character varying,
    ods_datim_id character varying(50),
    hbstatus_delivery character varying(255),
	created_date timestamp,row_number integer);

DROP TABLE if exists pmtct_hts.pmtct_delivery_new;
CREATE TABLE pmtct_hts.pmtct_delivery_new AS
SELECT * FROM pmtct_hts.sub_pmtct_delivery 
WHERE row_number=1;

drop table if exists pmtct_hts.pmtct_delivery;
alter table pmtct_hts.pmtct_delivery_new rename to pmtct_delivery;

drop index if exists idx_pmtctdelivery_uuidodsdatimid;
create index idx_pmtctdelivery_uuidodsdatimid 
on pmtct_hts.pmtct_delivery(person_uuid_delivery,ods_datim_id);

DROP TABLE if exists pmtct_hts.sub_pmtct_delivery;

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO pmtct_hts.pmtct_hts_monitoring  (table_name, start_time,end_time) VALUES ('pmtct_delivery', start_time,end_time);

END
$$;


ALTER PROCEDURE pmtct_hts.proc_pmtct_delivery() OWNER TO lamisplus_etl;

--
-- Name: proc_pmtct_hts(); Type: PROCEDURE; Schema: pmtct_hts; Owner: lamisplus_etl
--

CREATE PROCEDURE pmtct_hts.proc_pmtct_hts()
    LANGUAGE plpgsql
    AS $$
DECLARE start_time TIMESTAMP;
DECLARE end_time TIMESTAMP;
DECLARE partition_name TEXT;
DECLARE period_date DATE;
DECLARE period_text TEXT;
DECLARE period_start DATE;
DECLARE period_end DATE;

BEGIN

SELECT TIMEOFDAY() INTO start_time;

SELECT start_date 
INTO period_start
FROM pmtct_hts.period WHERE is_active;

SELECT date INTO period_end
FROM pmtct_hts.period WHERE is_active;

SELECT CONCAT('pmtcthts_',periodcode) 
INTO partition_name
from pmtct_hts.period where is_active;

SELECT periodid INTO period_text
from pmtct_hts.period where is_active;

SELECT date INTO period_date 
FROM pmtct_hts.period where is_active;

EXECUTE format('TRUNCATE public.%I',partition_name);

-- EXECUTE format('CREATE TABLE pmtct_hts.%I PARTITION OF pmtct_hts.pmtct_hts_weekly
-- FOR VALUES IN (%L)', partition_name, period_text);

--EXECUTE format('ALTER TABLE pmtct_hts.%I
--			   ADD CONSTRAINT %I_check CHECK (period_start_date >= %L 
--			   and period_end_date <= %L)', partition_name,partition_name,period_start,period_end);

EXECUTE format('INSERT INTO public.%I
select %L as period,
PersonUuid,
"State",
"LGA",
"Datim ID",
"Facility",
"Patient ID",
id,
"ANC Number",
"Mother Hospital Num",
"Mother Date  of Birth",
"Age",
"Marital Status",
"ANC Setting",
first_anc_date,
"Gestational Age (Weeks) @ First ANC visit",
"Garvida",
"Parity",
hbstatus_delivery,
tested_syphilis_anc,
test_result_syphilis_anc ,
Partner_syphilis_status,
dateOfRegistration,
hivEnrollmentDate,
Partner_acceptHivTest,
--anc.referredTo AS Partner_syphilis_status,
Partner_age,
dateOfRegistrationOnHiv,
date_confirmed_hiv,
"Mother ART Start Date",
"Previously Known Hiv Status",
"Date Tested for Hepatitis B",
"Hepatitis B Test Result",
"Date Tested for Hepatitis C",
"Hepatitis C Test Result",
hivRestested,
"Date tested for Syphillis",
"HIV Test Result",
acceptedHIVTesting,
"Date Tested for HIV",
receivedHivRetestedResult,
previouslyKnownHIVPositive,
"Point of Entry",
"Modality",
"Date of registration in index pregnancy",
"Mother Unique ID",
"Date Of Maternal Retesting",
"Maternal Retesting Result",
"Linked to Syphilis Treatment",
"If Recency Testing Opt In",
"Recency ID",
"Recency Test Type",
"Recency Test Date (yyyy_mm_dd)",
"Recency Interpretation",
"Viral Load Sample Collection Date",
"Final Recency Result",
"Viral Load Confirmation Result",
"Viral Load Confirmation Date (yyyyy-mm-dd)",
%L as period_start_date,
%L as period_end_date
FROM pmtct_hts.pmtct_hts_joined', partition_name, period_text, period_start, period_end);

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO pmtct_hts.pmtct_hts_monitoring  (table_name, start_time,end_time) 
VALUES ('pmtct_hts_weekly', start_time,end_time);

END
$$;


ALTER PROCEDURE pmtct_hts.proc_pmtct_hts() OWNER TO lamisplus_etl;

--
-- Name: proc_pmtct_hts_joined(); Type: PROCEDURE; Schema: pmtct_hts; Owner: lamisplus_etl
--

CREATE PROCEDURE pmtct_hts.proc_pmtct_hts_joined()
    LANGUAGE plpgsql
    AS $$

DECLARE start_time TIMESTAMP;
DECLARE end_time TIMESTAMP;
BEGIN
SELECT TIMEOFDAY() INTO start_time;

DROP TABLE if exists pmtct_hts.pmtct_hts_joined_new;

CREATE TABLE pmtct_hts.pmtct_hts_joined_new AS 
SELECT DISTINCT ON (p.uuid)p.uuid AS PersonUuid,
p.state as "State",
p.lga as "LGA", 
p.ods_datim_id as "Datim ID",
p.facilityname as "Facility",
p.uuid as "Patient ID",
CAST (NULL AS bigint) id,
anc.anc_no as "ANC Number",
p.hospital_number as "Mother Hospital Num",
p.date_of_birth AS "Mother Date  of Birth",
EXTRACT(YEAR from AGE(NOW(),  date_of_birth)) as "Age",
p.maritalstatus "Marital Status",
anc.anc_setting_anc as "ANC Setting",
anc.first_anc_date,
anc.gaweeks_anc as "Gestational Age (Weeks) @ First ANC visit",
anc.gravida_anc as "Garvida",
anc.parity_anc as "Parity",
delivery.hbstatus_delivery,
anc.tested_syphilis_anc,
anc.test_result_syphilis_anc,
anc.syphillisStatus AS Partner_syphilis_status,
p.dateofregistration,
p.date_started AS hivEnrollmentDate,
anc.acceptHivTest AS Partner_acceptHivTest,
--anc.referredTo AS Partner_syphilis_status,
anc.age AS Partner_age,
p.date_of_registration as dateOfRegistrationOnHiv,
p.date_confirmed_hiv,
p.date_started as "Mother ART Start Date",
anc.previously_known_hiv_status as "Previously Known Hiv Status",
hts_client.date_created_hts_client as "Date Tested for Hepatitis B",
hts_client.hepatitisBTestResult as "Hepatitis B Test Result",
hts_client.date_created_hts_client as "Date Tested for Hepatitis C",
hts_client.hepatitisCTestResult as "Hepatitis C Test Result",
anc.hivRestested AS hivRestested,
anc.max_created_date_anc as "Date tested for Syphillis",
anc.hivTestResult AS "HIV Test Result",
anc.acceptedHIVTesting AS acceptedHIVTesting,
anc.dateTestedHivPositive AS "Date Tested for HIV",
anc.receivedHivRetestedResult AS receivedHivRetestedResult,
anc.previouslyKnownHIVPositive AS previouslyKnownHIVPositive,
hts_client.entry_point AS "Point of Entry",
hts_client.display AS "Modality",
hts_client.pmtct_enrollment_date AS "Date of registration in index pregnancy",
p.unique_id AS "Mother Unique ID",
hts_client.max_date_created_hts_client as "Date Of Maternal Retesting",
hts_client.hiv_test_result2_hts_client as "Maternal Retesting Result",
anc.syphilis_treatment_status as "Linked to Syphilis Treatment",
hts_client.optOutRTRI_status as "If Recency Testing Opt In",
hts_client.rencencyId as "Recency ID",
hts_client.sampleType as "Recency Test Type",
hts_client.rencencyTestDate as "Recency Test Date (yyyy_mm_dd)",
hts_client.rencencyInterpretation as "Recency Interpretation",
hts_client.date_of_viral_load as "Viral Load Sample Collection Date",
hts_client.finalRecencyResult as "Final Recency Result",
labResult.result as "Viral Load Confirmation Result",
labResult.date_result_reported as "Viral Load Confirmation Date (yyyyy-mm-dd)"
FROM (SELECT * FROM dblink('db_link_radet',
'SELECT PersonUuid uuid,bio_ods_datim_id ods_datim_id,hospitalnumber hospital_number,
dateofbirth date_of_birth,maritalstatus,dateofregistration,facilityname,state,lga,
uniqueid unique_id,dateOfConfirmedHiv date_confirmed_hiv,dateofenrollment date_of_registration, 
datestartedhivenrollment date_started
FROM expanded_radet.patient_bio_data
WHERE gender=''Female''
')
AS sm(uuid character varying,ods_datim_id character varying,
	  hospital_number character varying,date_of_birth date,maritalstatus text,
	  dateofregistration date,facilityname character varying,state character varying,
	 lga character varying,unique_id character varying,date_confirmed_hiv date,
	 date_of_registration date, date_started date)) p
LEFT JOIN (SELECT * FROM dblink('db_link_radet',
'SELECT patient_uuid, ods_datim_id, result, date_result_reported
FROM expanded_radet."lab_test_results_refresh_Viral_Load"
') AS sm(patient_uuid character varying, ods_datim_id character varying,
		 result character varying,date_result_reported date)) labResult ON p.uuid = labResult.patient_uuid and labResult.ods_datim_id=p.ods_datim_id
--LEFT JOIN pmtct_hts.result r ON r.uuid=p.uuid and r.ods_datim_id=p.ods_datim_id
LEFT JOIN pmtct_hts.pmtct_anc anc ON p.uuid = anc.person_uuid_anc and p.ods_datim_id=anc.ods_datim_id
LEFT JOIN pmtct_hts.pmtct_delivery delivery ON p.uuid = delivery.person_uuid_delivery and p.ods_datim_id=delivery.ods_datim_id
LEFT JOIN pmtct_hts.hts_client hts_client ON p.uuid = hts_client.person_uuid_hts_client and p.ods_datim_id=hts_client.ods_datim_id
WHERE hts_client.date_visit BETWEEN CAST('1980-01-01' AS DATE) AND (SELECT date FROM pmtct_hts.period WHERE is_active)
;

drop table if exists pmtct_hts.pmtct_hts_joined;
alter table pmtct_hts.pmtct_hts_joined_new rename to pmtct_hts_joined;

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO pmtct_hts.pmtct_hts_monitoring(table_name, start_time,end_time) VALUES ('pmtct_hts_joined', start_time,end_time);

END
$$;


ALTER PROCEDURE pmtct_hts.proc_pmtct_hts_joined() OWNER TO lamisplus_etl;

--
-- Name: proc_result(); Type: PROCEDURE; Schema: pmtct_hts; Owner: lamisplus_etl
--

CREATE PROCEDURE pmtct_hts.proc_result()
    LANGUAGE plpgsql
    AS $$

DECLARE start_time TIMESTAMP;
DECLARE end_time TIMESTAMP;
BEGIN
	SELECT TIMEOFDAY() INTO start_time;

DROP TABLE if exists pmtct_hts.result_new;

CREATE TABLE pmtct_hts.result_new AS 
SELECT * FROM dblink('db_link_ods',
'SELECT p.id,p.uuid,ods_datim_id, '''' AS address,''''AS stateId,''''  AS lgaId
FROM ods_patient_person p 
WHERE sex=''Female'' and archived=0')
AS sm(id bigint,uuid character varying,ods_datim_id character varying(255),
    address text,stateid text,lgaid text);

drop table if exists pmtct_hts.result;
alter table pmtct_hts.result_new rename to result;

drop index if exists idx_pmtctresult_uuidodsdatimid;
create index idx_pmtctresult_uuidodsdatimid 
on pmtct_hts.result(uuid,ods_datim_id);

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO pmtct_hts.pmtct_hts_monitoring (table_name, start_time,end_time) VALUES ('result', start_time,end_time);

END
$$;


ALTER PROCEDURE pmtct_hts.proc_result() OWNER TO lamisplus_etl;

--
-- Name: proc_stream_pmtct_hts(); Type: PROCEDURE; Schema: pmtct_hts; Owner: lamisplus_etl
--

CREATE PROCEDURE pmtct_hts.proc_stream_pmtct_hts()
    LANGUAGE plpgsql
    AS $$
DECLARE start_time TIMESTAMP;
DECLARE end_time TIMESTAMP;

BEGIN

SELECT TIMEOFDAY() INTO start_time;

INSERT INTO public.pmtct_hts
SELECT * FROM pmtct_hts.pmtct_hts_weekly;

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO maternal_cohort.cte_monitoring(table_name, start_time,end_time) 
VALUES ('pmtct_hts', start_time,end_time);
		 
END 
$$;


ALTER PROCEDURE pmtct_hts.proc_stream_pmtct_hts() OWNER TO lamisplus_etl;

--
-- Name: proc_update_pmtct_hts_period_table(); Type: PROCEDURE; Schema: pmtct_hts; Owner: lamisplus_etl
--

CREATE PROCEDURE pmtct_hts.proc_update_pmtct_hts_period_table()
    LANGUAGE plpgsql
    AS $$
DECLARE start_time TIMESTAMP;
DECLARE end_time TIMESTAMP;
BEGIN
SELECT TIMEOFDAY() INTO start_time;

PERFORM dblink('db_link_ods',
      format('update pmtct_hts.period 
              set is_active = false'));

PERFORM dblink('db_link_ods',
      format('update pmtct_hts.period 
              set is_active = true 
              where periodid in (''2024W42'')
              --date = current_date-7
			 '));
			  
update pmtct_hts.period 
set is_active = false;

update pmtct_hts.period 
set is_active = true 
where periodid in ('2024W42');

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO pmtct_hts.pmtct_hts_monitoring (table_name, start_time,end_time) 
VALUES ('period', start_time,end_time);
END
$$;


ALTER PROCEDURE pmtct_hts.proc_update_pmtct_hts_period_table() OWNER TO lamisplus_etl;

--
-- Name: proc_create_index_final_pmtct_maternal(); Type: PROCEDURE; Schema: public; Owner: lamisplus_etl
--

CREATE PROCEDURE public.proc_create_index_final_pmtct_maternal()
    LANGUAGE plpgsql
    AS $$

BEGIN

CREATE INDEX datimidperiodenddate_maternalcohort
ON public.maternal_cohort(datimid,period_end_date);
CREATE INDEX datimidperiodenddate_pmtcthts
ON public.pmtct_hts(datimid,period_end_date);
CREATE INDEX datimiddate_aggregateflatfilepmtctmaternal
ON public.aggregate_flatfile(datim_id,date);

END 
$$;


ALTER PROCEDURE public.proc_create_index_final_pmtct_maternal() OWNER TO lamisplus_etl;

--
-- Name: proc_loop_through_lists(); Type: PROCEDURE; Schema: public; Owner: lamisplus_etl
--

CREATE PROCEDURE public.proc_loop_through_lists()
    LANGUAGE plpgsql
    AS $$
DECLARE
    inputs text[];
    input text;
    partition_name text;
BEGIN
    -- Populate the array with values from the existing table
    SELECT array_agg(periodcode) 
    INTO inputs
    FROM public.period;

    -- Loop through each input value and execute the dynamic query
    FOREACH input IN ARRAY inputs
    LOOP
        partition_name := CONCAT('maternalcohort_', input);
        
		EXECUTE format('
            DROP TABLE IF EXISTS public.%I 
           ', partition_name);
			
        -- Loop through and create partitions
        EXECUTE format('
            CREATE TABLE IF NOT EXISTS public.%I 
            PARTITION OF public.maternal_cohort
            FOR VALUES IN (%L)', partition_name, input);
    END LOOP;
END;
$$;


ALTER PROCEDURE public.proc_loop_through_lists() OWNER TO lamisplus_etl;

--
-- Name: lamisplus_etl; Type: FOREIGN DATA WRAPPER; Schema: -; Owner: lamisplus_etl
--

CREATE FOREIGN DATA WRAPPER lamisplus_etl VALIDATOR postgresql_fdw_validator;


ALTER FOREIGN DATA WRAPPER lamisplus_etl OWNER TO lamisplus_etl;

--
-- Name: db_link_ods; Type: SERVER; Schema: -; Owner: lamisplus_etl
--

CREATE SERVER db_link_ods FOREIGN DATA WRAPPER lamisplus_etl OPTIONS (
    dbname 'lamisplus_ods_dwh',
    hostaddr '10.10.10.9'
);


ALTER SERVER db_link_ods OWNER TO lamisplus_etl;

--
-- Name: USER MAPPING lamisplus_etl SERVER db_link_ods; Type: USER MAPPING; Schema: -; Owner: lamisplus_etl
--

CREATE USER MAPPING FOR lamisplus_etl SERVER db_link_ods OPTIONS (
    password 'QUWeIQvD27BYei1',
    "user" 'lamisplus_etl'
);


--
-- Name: db_link_radet; Type: SERVER; Schema: -; Owner: lamisplus_etl
--

CREATE SERVER db_link_radet FOREIGN DATA WRAPPER lamisplus_etl OPTIONS (
    dbname 'radet',
    hostaddr '127.0.0.1'
);


ALTER SERVER db_link_radet OWNER TO lamisplus_etl;

--
-- Name: USER MAPPING lamisplus_etl SERVER db_link_radet; Type: USER MAPPING; Schema: -; Owner: lamisplus_etl
--

CREATE USER MAPPING FOR lamisplus_etl SERVER db_link_radet OPTIONS (
    password 'QUWeIQvD27BYei1',
    "user" 'lamisplus_etl'
);


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: confirm; Type: TABLE; Schema: maternal_cohort; Owner: lamisplus_etl
--

CREATE TABLE maternal_cohort.confirm (
    uuid character varying,
    ods_datim_id character varying,
    date_sample_collected date,
    results character varying,
    date_result_received_at_facility date
);


ALTER TABLE maternal_cohort.confirm OWNER TO lamisplus_etl;

--
-- Name: cte_monitoring; Type: TABLE; Schema: maternal_cohort; Owner: lamisplus_etl
--

CREATE TABLE maternal_cohort.cte_monitoring (
    table_name character varying(100),
    start_time timestamp without time zone,
    end_time timestamp without time zone
);


ALTER TABLE maternal_cohort.cte_monitoring OWNER TO lamisplus_etl;

--
-- Name: first; Type: TABLE; Schema: maternal_cohort; Owner: lamisplus_etl
--

CREATE TABLE maternal_cohort.first (
    uuid character varying,
    ods_datim_id character varying,
    date_sample_collected date,
    results character varying,
    date_result_received_at_facility date
);


ALTER TABLE maternal_cohort.first OWNER TO lamisplus_etl;

--
-- Name: hiv_observation; Type: TABLE; Schema: maternal_cohort; Owner: lamisplus_etl
--

CREATE TABLE maternal_cohort.hiv_observation (
    person_uuid character varying,
    ods_datim_id character varying,
    date_of_observation date,
    tb_screening_status character varying
);


ALTER TABLE maternal_cohort.hiv_observation OWNER TO lamisplus_etl;

--
-- Name: maternal_cohort_monitoring; Type: TABLE; Schema: maternal_cohort; Owner: lamisplus_etl
--

CREATE TABLE maternal_cohort.maternal_cohort_monitoring (
    table_name character varying(100),
    start_time timestamp without time zone,
    end_time timestamp without time zone
);


ALTER TABLE maternal_cohort.maternal_cohort_monitoring OWNER TO lamisplus_etl;

--
-- Name: pmtct_anc; Type: TABLE; Schema: maternal_cohort; Owner: lamisplus_etl
--

CREATE TABLE maternal_cohort.pmtct_anc (
    person_uuid_anc character varying(255),
    ods_datim_id character varying(50),
    anc_setting_anc character varying(255),
    first_anc_date date,
    lmp date,
    gaweeks_anc integer,
    gravida_anc integer,
    parity_anc integer,
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    treated_syphilis character varying(255),
    age text,
    syphillisstatus text,
    accepthivtest text,
    referredto text,
    hivrestested text,
    hivtestresult text,
    acceptedhivtesting text,
    datetestedhivpositive text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    anc_no character varying(255),
    static_hiv_status character varying(255)
);


ALTER TABLE maternal_cohort.pmtct_anc OWNER TO lamisplus_etl;

--
-- Name: pmtct_delivery; Type: TABLE; Schema: maternal_cohort; Owner: lamisplus_etl
--

CREATE TABLE maternal_cohort.pmtct_delivery (
    person_uuid character varying,
    ods_datim_id character varying(50),
    anc_no character varying(255),
    facility_id bigint,
    hospital_number character varying(255),
    uuid character varying(255),
    date_of_delivery date,
    booking_status character varying(255),
    gaweeks bigint,
    rom_delivery_interval character varying(255),
    mode_of_delivery character varying(255),
    episiotomy character varying(255),
    vaginal_tear character varying(255),
    feeding_decision character varying(255),
    maternal_outcome character varying(255),
    child_status character varying(255),
    hiv_exposed_infant_given_hb_within24hrs character varying(255),
    child_given_arv_within72 character varying(255),
    delivery_time character varying(255),
    on_art character varying(255),
    art_started_ld_ward character varying(255),
    hbstatus character varying(255),
    hcstatus character varying(255),
    referal_source character varying(255),
    number_of_infants_alive bigint,
    number_of_infants_dead bigint,
    place_of_delivery character varying(255),
    non_hbv_exposed_infant_given_hb_within_24hrs character varying
);


ALTER TABLE maternal_cohort.pmtct_delivery OWNER TO lamisplus_etl;

--
-- Name: pmtct_maternal_cohort_joined; Type: TABLE; Schema: maternal_cohort; Owner: lamisplus_etl
--

CREATE TABLE maternal_cohort.pmtct_maternal_cohort_joined (
    "Patient ID" character varying,
    "State" character varying(255),
    "LGA" character varying(255),
    "IP Name" character varying(255),
    "Datim ID" character varying,
    "Facility" character varying(255),
    "Mother Hospital Number" text,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying,
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" character varying,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying,
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" character varying,
    "Visit Status" character varying,
    "Mother DSD Status" character varying,
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" text,
    "Sex - Child" character varying,
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" text
);


ALTER TABLE maternal_cohort.pmtct_maternal_cohort_joined OWNER TO lamisplus_etl;

--
-- Name: pmtct_mother_visitation; Type: TABLE; Schema: maternal_cohort; Owner: lamisplus_etl
--

CREATE TABLE maternal_cohort.pmtct_mother_visitation (
    person_uuid character varying,
    ods_datim_id character varying,
    date_of_visit date,
    dsd_option character varying,
    visit_status character varying,
    ga_of_viral_load smallint
);


ALTER TABLE maternal_cohort.pmtct_mother_visitation OWNER TO lamisplus_etl;

--
-- Name: second; Type: TABLE; Schema: maternal_cohort; Owner: lamisplus_etl
--

CREATE TABLE maternal_cohort.second (
    uuid character varying,
    ods_datim_id character varying,
    date_sample_collected date,
    results character varying,
    date_result_received_at_facility date
);


ALTER TABLE maternal_cohort.second OWNER TO lamisplus_etl;

--
-- Name: temp_pmtct_mother_visitation; Type: TABLE; Schema: maternal_cohort; Owner: lamisplus_etl
--

CREATE TABLE maternal_cohort.temp_pmtct_mother_visitation (
    person_uuid character varying,
    ods_datim_id character varying,
    date_of_viral_load date,
    result_of_viral_load smallint
);


ALTER TABLE maternal_cohort.temp_pmtct_mother_visitation OWNER TO lamisplus_etl;

--
-- Name: central_data_element_pmtct; Type: TABLE; Schema: pmtct_hts; Owner: lamisplus_etl
--

CREATE TABLE pmtct_hts.central_data_element_pmtct (
    id integer NOT NULL,
    data_element character varying(100) NOT NULL,
    data_element_uid character varying(100) NOT NULL,
    file_name character varying(100) NOT NULL,
    frequency character varying(20) NOT NULL,
    ip_category integer NOT NULL
);


ALTER TABLE pmtct_hts.central_data_element_pmtct OWNER TO lamisplus_etl;

--
-- Name: hts_client; Type: TABLE; Schema: pmtct_hts; Owner: lamisplus_etl
--

CREATE TABLE pmtct_hts.hts_client (
    person_uuid_hts_client character varying,
    ods_datim_id character varying(255),
    hiv_test_result2_hts_client character varying,
    risk_stratification_code_hts_client character varying,
    hepatitisbtestresult text,
    hepatitisctestresult text,
    optoutrtri text,
    optoutrtri_status text,
    rencencyid text,
    sampletype text,
    rencencytestdate text,
    rencencyinterpretation text,
    finalrecencyresult text,
    date_created_hts_client timestamp without time zone,
    max_date_created_hts_client timestamp without time zone,
    date_visit date,
    entry_point character varying,
    pmtct_enrollment_date date,
    date_of_viral_load date,
    display character varying
);


ALTER TABLE pmtct_hts.hts_client OWNER TO lamisplus_etl;

--
-- Name: period; Type: TABLE; Schema: pmtct_hts; Owner: lamisplus_etl
--

CREATE TABLE pmtct_hts.period (
    periodid character varying,
    periodcode character varying,
    table_name_pmtct_hts character varying,
    is_active boolean,
    start_date date,
    date date,
    table_name_maternal_cohort character varying,
    is_current boolean DEFAULT false
);


ALTER TABLE pmtct_hts.period OWNER TO lamisplus_etl;

--
-- Name: pmtct_anc; Type: TABLE; Schema: pmtct_hts; Owner: lamisplus_etl
--

CREATE TABLE pmtct_hts.pmtct_anc (
    person_uuid_anc character varying(255),
    ods_datim_id character varying(50),
    anc_setting_anc character varying(255),
    previously_known_hiv_status character varying,
    first_anc_date date,
    gaweeks_anc integer,
    gravida_anc integer,
    parity_anc integer,
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    syphilis_treatment_status text,
    age text,
    syphillisstatus text,
    accepthivtest text,
    referredto text,
    hivrestested text,
    hivtestresult text,
    acceptedhivtesting text,
    datetestedhivpositive text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    anc_no character varying(255),
    static_hiv_status character varying(255),
    max_created_date_anc timestamp without time zone
);


ALTER TABLE pmtct_hts.pmtct_anc OWNER TO lamisplus_etl;

--
-- Name: pmtct_delivery; Type: TABLE; Schema: pmtct_hts; Owner: lamisplus_etl
--

CREATE TABLE pmtct_hts.pmtct_delivery (
    person_uuid_delivery character varying,
    ods_datim_id character varying(50),
    hbstatus_delivery character varying(255),
    created_date timestamp without time zone,
    row_number integer
);


ALTER TABLE pmtct_hts.pmtct_delivery OWNER TO lamisplus_etl;

--
-- Name: pmtct_hts_joined; Type: TABLE; Schema: pmtct_hts; Owner: lamisplus_etl
--

CREATE TABLE pmtct_hts.pmtct_hts_joined (
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    "Datim ID" character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying,
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" date
);


ALTER TABLE pmtct_hts.pmtct_hts_joined OWNER TO lamisplus_etl;

--
-- Name: pmtct_hts_monitoring; Type: TABLE; Schema: pmtct_hts; Owner: lamisplus_etl
--

CREATE TABLE pmtct_hts.pmtct_hts_monitoring (
    table_name character varying(100),
    start_time timestamp without time zone,
    end_time timestamp without time zone
);


ALTER TABLE pmtct_hts.pmtct_hts_monitoring OWNER TO lamisplus_etl;

--
-- Name: result; Type: TABLE; Schema: pmtct_hts; Owner: lamisplus_etl
--

CREATE TABLE pmtct_hts.result (
    id bigint,
    uuid character varying,
    ods_datim_id character varying(255),
    address text,
    stateid text,
    lgaid text
);


ALTER TABLE pmtct_hts.result OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile; Type: TABLE; Schema: public; Owner: emeka
--

CREATE TABLE public.aggregate_flatfile (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
)
PARTITION BY LIST (period);


ALTER TABLE public.aggregate_flatfile OWNER TO emeka;

--
-- Name: aggregate_flatfile_2024Q2; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024Q2" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024Q2" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024Q3; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024Q3" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024Q3" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024Q4; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024Q4" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024Q4" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024W1; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024W1" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024W1" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024W10; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024W10" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024W10" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024W11; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024W11" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024W11" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024W12; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024W12" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024W12" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024W13; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024W13" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024W13" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024W14; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024W14" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024W14" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024W15; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024W15" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024W15" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024W16; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024W16" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024W16" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024W17; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024W17" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024W17" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024W18; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024W18" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024W18" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024W19; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024W19" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024W19" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024W2; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024W2" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024W2" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024W20; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024W20" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024W20" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024W21; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024W21" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024W21" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024W22; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024W22" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024W22" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024W23; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024W23" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024W23" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024W24; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024W24" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024W24" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024W25; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024W25" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024W25" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024W26; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024W26" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024W26" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024W27; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024W27" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024W27" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024W28; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024W28" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024W28" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024W29; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024W29" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024W29" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024W3; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024W3" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024W3" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024W30; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024W30" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024W30" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024W31; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024W31" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024W31" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024W32; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024W32" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024W32" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024W33; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024W33" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024W33" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024W34; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024W34" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024W34" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024W35; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024W35" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024W35" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024W36; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024W36" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024W36" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024W37; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024W37" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024W37" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024W38; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024W38" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024W38" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024W39; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024W39" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024W39" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024W4; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024W4" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024W4" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024W40; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024W40" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024W40" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024W41; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024W41" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024W41" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024W42; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024W42" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024W42" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024W43; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024W43" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024W43" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024W44; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024W44" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024W44" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024W45; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024W45" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024W45" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024W46; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024W46" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024W46" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024W47; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024W47" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024W47" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024W48; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024W48" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024W48" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024W49; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024W49" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024W49" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024W5; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024W5" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024W5" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024W50; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024W50" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024W50" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024W51; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024W51" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024W51" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024W52; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024W52" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024W52" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024W6; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024W6" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024W6" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024W7; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024W7" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024W7" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024W8; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024W8" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024W8" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024W9; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."aggregate_flatfile_2024W9" (
    id bigint NOT NULL,
    datim_id character varying,
    period character varying NOT NULL,
    data_element character varying,
    data_element_name character varying,
    category_option_combo character varying,
    category_option_combo_name character varying,
    attribute_option_combo character varying,
    value integer,
    date date,
    ip_name character varying,
    facility_name character varying,
    facility_state character varying,
    facility_lga character varying
);


ALTER TABLE public."aggregate_flatfile_2024W9" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_id_seq; Type: SEQUENCE; Schema: public; Owner: emeka
--

ALTER TABLE public.aggregate_flatfile ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.aggregate_flatfile_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: central_category_option_combo; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public.central_category_option_combo (
    id integer NOT NULL,
    category_option_combo character varying(400) NOT NULL,
    category_option_combo_uid character varying(11) NOT NULL,
    data_element_id integer NOT NULL,
    min numeric(4,1),
    max numeric(10,1),
    sex character varying(100),
    status character varying(500),
    min2 integer,
    max2 integer
);


ALTER TABLE public.central_category_option_combo OWNER TO lamisplus_etl;

--
-- Name: central_data_element; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public.central_data_element (
    id integer NOT NULL,
    data_element character varying(80) NOT NULL,
    data_element_uid character varying(11) NOT NULL,
    file_name character varying(100) NOT NULL,
    ip_category bigint DEFAULT 1 NOT NULL,
    run boolean DEFAULT true
);


ALTER TABLE public.central_data_element OWNER TO lamisplus_etl;

--
-- Name: central_partner_mapping; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public.central_partner_mapping (
    id bigint NOT NULL,
    facility_id bigint NOT NULL,
    datim_id character varying(255) NOT NULL,
    facility_name character varying(255) NOT NULL,
    facility_state character varying(255) NOT NULL,
    facility_lga character varying(255) NOT NULL,
    ip_code bigint NOT NULL,
    ip_name character varying(255) NOT NULL,
    patient_count integer,
    archived integer DEFAULT 0,
    lga_id character varying
);


ALTER TABLE public.central_partner_mapping OWNER TO lamisplus_etl;

--
-- Name: maternal_cohort; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public.maternal_cohort (
    period text,
    "Patient ID" character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Mother Hospital Number" character varying,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying(255),
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" text,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying(255),
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" text,
    "Visit Status" character varying(255),
    "Mother DSD Status" character varying(255),
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" character varying(255),
    "Sex - Child" character varying(255),
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" character varying(255),
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
)
PARTITION BY LIST (period);


ALTER TABLE public.maternal_cohort OWNER TO lamisplus_etl;

--
-- Name: maternalcohort_2024Q3; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."maternalcohort_2024Q3" (
    period text,
    "Patient ID" character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Mother Hospital Number" character varying,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying(255),
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" text,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying(255),
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" text,
    "Visit Status" character varying(255),
    "Mother DSD Status" character varying(255),
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" character varying(255),
    "Sex - Child" character varying(255),
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" character varying(255),
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."maternalcohort_2024Q3" OWNER TO lamisplus_etl;

--
-- Name: maternalcohort_2024Q4; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."maternalcohort_2024Q4" (
    period text,
    "Patient ID" character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Mother Hospital Number" character varying,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying(255),
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" text,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying(255),
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" text,
    "Visit Status" character varying(255),
    "Mother DSD Status" character varying(255),
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" character varying(255),
    "Sex - Child" character varying(255),
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" character varying(255),
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."maternalcohort_2024Q4" OWNER TO lamisplus_etl;

--
-- Name: maternalcohort_2024W10; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."maternalcohort_2024W10" (
    period text,
    "Patient ID" character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Mother Hospital Number" character varying,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying(255),
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" text,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying(255),
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" text,
    "Visit Status" character varying(255),
    "Mother DSD Status" character varying(255),
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" character varying(255),
    "Sex - Child" character varying(255),
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" character varying(255),
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."maternalcohort_2024W10" OWNER TO lamisplus_etl;

--
-- Name: maternalcohort_2024W11; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."maternalcohort_2024W11" (
    period text,
    "Patient ID" character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Mother Hospital Number" character varying,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying(255),
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" text,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying(255),
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" text,
    "Visit Status" character varying(255),
    "Mother DSD Status" character varying(255),
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" character varying(255),
    "Sex - Child" character varying(255),
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" character varying(255),
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."maternalcohort_2024W11" OWNER TO lamisplus_etl;

--
-- Name: maternalcohort_2024W12; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."maternalcohort_2024W12" (
    period text,
    "Patient ID" character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Mother Hospital Number" character varying,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying(255),
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" text,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying(255),
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" text,
    "Visit Status" character varying(255),
    "Mother DSD Status" character varying(255),
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" character varying(255),
    "Sex - Child" character varying(255),
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" character varying(255),
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."maternalcohort_2024W12" OWNER TO lamisplus_etl;

--
-- Name: maternalcohort_2024W13; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."maternalcohort_2024W13" (
    period text,
    "Patient ID" character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Mother Hospital Number" character varying,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying(255),
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" text,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying(255),
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" text,
    "Visit Status" character varying(255),
    "Mother DSD Status" character varying(255),
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" character varying(255),
    "Sex - Child" character varying(255),
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" character varying(255),
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."maternalcohort_2024W13" OWNER TO lamisplus_etl;

--
-- Name: maternalcohort_2024W14; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."maternalcohort_2024W14" (
    period text,
    "Patient ID" character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Mother Hospital Number" character varying,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying(255),
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" text,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying(255),
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" text,
    "Visit Status" character varying(255),
    "Mother DSD Status" character varying(255),
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" character varying(255),
    "Sex - Child" character varying(255),
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" character varying(255),
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."maternalcohort_2024W14" OWNER TO lamisplus_etl;

--
-- Name: maternalcohort_2024W15; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."maternalcohort_2024W15" (
    period text,
    "Patient ID" character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Mother Hospital Number" character varying,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying(255),
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" text,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying(255),
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" text,
    "Visit Status" character varying(255),
    "Mother DSD Status" character varying(255),
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" character varying(255),
    "Sex - Child" character varying(255),
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" character varying(255),
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."maternalcohort_2024W15" OWNER TO lamisplus_etl;

--
-- Name: maternalcohort_2024W16; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."maternalcohort_2024W16" (
    period text,
    "Patient ID" character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Mother Hospital Number" character varying,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying(255),
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" text,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying(255),
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" text,
    "Visit Status" character varying(255),
    "Mother DSD Status" character varying(255),
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" character varying(255),
    "Sex - Child" character varying(255),
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" character varying(255),
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."maternalcohort_2024W16" OWNER TO lamisplus_etl;

--
-- Name: maternalcohort_2024W17; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."maternalcohort_2024W17" (
    period text,
    "Patient ID" character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Mother Hospital Number" character varying,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying(255),
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" text,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying(255),
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" text,
    "Visit Status" character varying(255),
    "Mother DSD Status" character varying(255),
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" character varying(255),
    "Sex - Child" character varying(255),
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" character varying(255),
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."maternalcohort_2024W17" OWNER TO lamisplus_etl;

--
-- Name: maternalcohort_2024W18; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."maternalcohort_2024W18" (
    period text,
    "Patient ID" character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Mother Hospital Number" character varying,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying(255),
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" text,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying(255),
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" text,
    "Visit Status" character varying(255),
    "Mother DSD Status" character varying(255),
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" character varying(255),
    "Sex - Child" character varying(255),
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" character varying(255),
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."maternalcohort_2024W18" OWNER TO lamisplus_etl;

--
-- Name: maternalcohort_2024W19; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."maternalcohort_2024W19" (
    period text,
    "Patient ID" character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Mother Hospital Number" character varying,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying(255),
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" text,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying(255),
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" text,
    "Visit Status" character varying(255),
    "Mother DSD Status" character varying(255),
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" character varying(255),
    "Sex - Child" character varying(255),
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" character varying(255),
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."maternalcohort_2024W19" OWNER TO lamisplus_etl;

--
-- Name: maternalcohort_2024W2; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."maternalcohort_2024W2" (
    period text,
    "Patient ID" character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Mother Hospital Number" character varying,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying(255),
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" text,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying(255),
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" text,
    "Visit Status" character varying(255),
    "Mother DSD Status" character varying(255),
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" character varying(255),
    "Sex - Child" character varying(255),
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" character varying(255),
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."maternalcohort_2024W2" OWNER TO lamisplus_etl;

--
-- Name: maternalcohort_2024W20; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."maternalcohort_2024W20" (
    period text,
    "Patient ID" character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Mother Hospital Number" character varying,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying(255),
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" text,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying(255),
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" text,
    "Visit Status" character varying(255),
    "Mother DSD Status" character varying(255),
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" character varying(255),
    "Sex - Child" character varying(255),
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" character varying(255),
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."maternalcohort_2024W20" OWNER TO lamisplus_etl;

--
-- Name: maternalcohort_2024W21; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."maternalcohort_2024W21" (
    period text,
    "Patient ID" character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Mother Hospital Number" character varying,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying(255),
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" text,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying(255),
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" text,
    "Visit Status" character varying(255),
    "Mother DSD Status" character varying(255),
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" character varying(255),
    "Sex - Child" character varying(255),
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" character varying(255),
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."maternalcohort_2024W21" OWNER TO lamisplus_etl;

--
-- Name: maternalcohort_2024W22; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."maternalcohort_2024W22" (
    period text,
    "Patient ID" character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Mother Hospital Number" character varying,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying(255),
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" text,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying(255),
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" text,
    "Visit Status" character varying(255),
    "Mother DSD Status" character varying(255),
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" character varying(255),
    "Sex - Child" character varying(255),
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" character varying(255),
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."maternalcohort_2024W22" OWNER TO lamisplus_etl;

--
-- Name: maternalcohort_2024W23; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."maternalcohort_2024W23" (
    period text,
    "Patient ID" character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Mother Hospital Number" character varying,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying(255),
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" text,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying(255),
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" text,
    "Visit Status" character varying(255),
    "Mother DSD Status" character varying(255),
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" character varying(255),
    "Sex - Child" character varying(255),
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" character varying(255),
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."maternalcohort_2024W23" OWNER TO lamisplus_etl;

--
-- Name: maternalcohort_2024W24; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."maternalcohort_2024W24" (
    period text,
    "Patient ID" character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Mother Hospital Number" character varying,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying(255),
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" text,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying(255),
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" text,
    "Visit Status" character varying(255),
    "Mother DSD Status" character varying(255),
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" character varying(255),
    "Sex - Child" character varying(255),
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" character varying(255),
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."maternalcohort_2024W24" OWNER TO lamisplus_etl;

--
-- Name: maternalcohort_2024W25; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."maternalcohort_2024W25" (
    period text,
    "Patient ID" character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Mother Hospital Number" character varying,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying(255),
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" text,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying(255),
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" text,
    "Visit Status" character varying(255),
    "Mother DSD Status" character varying(255),
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" character varying(255),
    "Sex - Child" character varying(255),
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" character varying(255),
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."maternalcohort_2024W25" OWNER TO lamisplus_etl;

--
-- Name: maternalcohort_2024W26; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."maternalcohort_2024W26" (
    period text,
    "Patient ID" character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Mother Hospital Number" character varying,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying(255),
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" text,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying(255),
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" text,
    "Visit Status" character varying(255),
    "Mother DSD Status" character varying(255),
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" character varying(255),
    "Sex - Child" character varying(255),
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" character varying(255),
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."maternalcohort_2024W26" OWNER TO lamisplus_etl;

--
-- Name: maternalcohort_2024W27; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."maternalcohort_2024W27" (
    period text,
    "Patient ID" character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Mother Hospital Number" character varying,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying(255),
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" text,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying(255),
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" text,
    "Visit Status" character varying(255),
    "Mother DSD Status" character varying(255),
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" character varying(255),
    "Sex - Child" character varying(255),
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" character varying(255),
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."maternalcohort_2024W27" OWNER TO lamisplus_etl;

--
-- Name: maternalcohort_2024W28; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."maternalcohort_2024W28" (
    period text,
    "Patient ID" character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Mother Hospital Number" character varying,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying(255),
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" text,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying(255),
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" text,
    "Visit Status" character varying(255),
    "Mother DSD Status" character varying(255),
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" character varying(255),
    "Sex - Child" character varying(255),
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" character varying(255),
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."maternalcohort_2024W28" OWNER TO lamisplus_etl;

--
-- Name: maternalcohort_2024W29; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."maternalcohort_2024W29" (
    period text,
    "Patient ID" character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Mother Hospital Number" character varying,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying(255),
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" text,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying(255),
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" text,
    "Visit Status" character varying(255),
    "Mother DSD Status" character varying(255),
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" character varying(255),
    "Sex - Child" character varying(255),
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" character varying(255),
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."maternalcohort_2024W29" OWNER TO lamisplus_etl;

--
-- Name: maternalcohort_2024W3; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."maternalcohort_2024W3" (
    period text,
    "Patient ID" character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Mother Hospital Number" character varying,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying(255),
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" text,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying(255),
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" text,
    "Visit Status" character varying(255),
    "Mother DSD Status" character varying(255),
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" character varying(255),
    "Sex - Child" character varying(255),
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" character varying(255),
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."maternalcohort_2024W3" OWNER TO lamisplus_etl;

--
-- Name: maternalcohort_2024W30; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."maternalcohort_2024W30" (
    period text,
    "Patient ID" character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Mother Hospital Number" character varying,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying(255),
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" text,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying(255),
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" text,
    "Visit Status" character varying(255),
    "Mother DSD Status" character varying(255),
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" character varying(255),
    "Sex - Child" character varying(255),
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" character varying(255),
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."maternalcohort_2024W30" OWNER TO lamisplus_etl;

--
-- Name: maternalcohort_2024W31; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."maternalcohort_2024W31" (
    period text,
    "Patient ID" character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Mother Hospital Number" character varying,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying(255),
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" text,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying(255),
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" text,
    "Visit Status" character varying(255),
    "Mother DSD Status" character varying(255),
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" character varying(255),
    "Sex - Child" character varying(255),
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" character varying(255),
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."maternalcohort_2024W31" OWNER TO lamisplus_etl;

--
-- Name: maternalcohort_2024W32; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."maternalcohort_2024W32" (
    period text,
    "Patient ID" character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Mother Hospital Number" character varying,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying(255),
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" text,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying(255),
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" text,
    "Visit Status" character varying(255),
    "Mother DSD Status" character varying(255),
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" character varying(255),
    "Sex - Child" character varying(255),
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" character varying(255),
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."maternalcohort_2024W32" OWNER TO lamisplus_etl;

--
-- Name: maternalcohort_2024W33; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."maternalcohort_2024W33" (
    period text,
    "Patient ID" character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Mother Hospital Number" character varying,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying(255),
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" text,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying(255),
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" text,
    "Visit Status" character varying(255),
    "Mother DSD Status" character varying(255),
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" character varying(255),
    "Sex - Child" character varying(255),
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" character varying(255),
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."maternalcohort_2024W33" OWNER TO lamisplus_etl;

--
-- Name: maternalcohort_2024W34; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."maternalcohort_2024W34" (
    period text,
    "Patient ID" character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Mother Hospital Number" character varying,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying(255),
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" text,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying(255),
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" text,
    "Visit Status" character varying(255),
    "Mother DSD Status" character varying(255),
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" character varying(255),
    "Sex - Child" character varying(255),
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" character varying(255),
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."maternalcohort_2024W34" OWNER TO lamisplus_etl;

--
-- Name: maternalcohort_2024W35; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."maternalcohort_2024W35" (
    period text,
    "Patient ID" character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Mother Hospital Number" character varying,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying(255),
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" text,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying(255),
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" text,
    "Visit Status" character varying(255),
    "Mother DSD Status" character varying(255),
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" character varying(255),
    "Sex - Child" character varying(255),
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" character varying(255),
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."maternalcohort_2024W35" OWNER TO lamisplus_etl;

--
-- Name: maternalcohort_2024W36; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."maternalcohort_2024W36" (
    period text,
    "Patient ID" character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Mother Hospital Number" character varying,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying(255),
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" text,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying(255),
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" text,
    "Visit Status" character varying(255),
    "Mother DSD Status" character varying(255),
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" character varying(255),
    "Sex - Child" character varying(255),
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" character varying(255),
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."maternalcohort_2024W36" OWNER TO lamisplus_etl;

--
-- Name: maternalcohort_2024W37; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."maternalcohort_2024W37" (
    period text,
    "Patient ID" character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Mother Hospital Number" character varying,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying(255),
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" text,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying(255),
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" text,
    "Visit Status" character varying(255),
    "Mother DSD Status" character varying(255),
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" character varying(255),
    "Sex - Child" character varying(255),
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" character varying(255),
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."maternalcohort_2024W37" OWNER TO lamisplus_etl;

--
-- Name: maternalcohort_2024W38; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."maternalcohort_2024W38" (
    period text,
    "Patient ID" character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Mother Hospital Number" character varying,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying(255),
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" text,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying(255),
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" text,
    "Visit Status" character varying(255),
    "Mother DSD Status" character varying(255),
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" character varying(255),
    "Sex - Child" character varying(255),
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" character varying(255),
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."maternalcohort_2024W38" OWNER TO lamisplus_etl;

--
-- Name: maternalcohort_2024W39; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."maternalcohort_2024W39" (
    period text,
    "Patient ID" character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Mother Hospital Number" character varying,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying(255),
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" text,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying(255),
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" text,
    "Visit Status" character varying(255),
    "Mother DSD Status" character varying(255),
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" character varying(255),
    "Sex - Child" character varying(255),
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" character varying(255),
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."maternalcohort_2024W39" OWNER TO lamisplus_etl;

--
-- Name: maternalcohort_2024W4; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."maternalcohort_2024W4" (
    period text,
    "Patient ID" character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Mother Hospital Number" character varying,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying(255),
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" text,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying(255),
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" text,
    "Visit Status" character varying(255),
    "Mother DSD Status" character varying(255),
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" character varying(255),
    "Sex - Child" character varying(255),
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" character varying(255),
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."maternalcohort_2024W4" OWNER TO lamisplus_etl;

--
-- Name: maternalcohort_2024W40; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."maternalcohort_2024W40" (
    period text,
    "Patient ID" character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Mother Hospital Number" character varying,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying(255),
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" text,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying(255),
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" text,
    "Visit Status" character varying(255),
    "Mother DSD Status" character varying(255),
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" character varying(255),
    "Sex - Child" character varying(255),
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" character varying(255),
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."maternalcohort_2024W40" OWNER TO lamisplus_etl;

--
-- Name: maternalcohort_2024W41; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."maternalcohort_2024W41" (
    period text,
    "Patient ID" character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Mother Hospital Number" character varying,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying(255),
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" text,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying(255),
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" text,
    "Visit Status" character varying(255),
    "Mother DSD Status" character varying(255),
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" character varying(255),
    "Sex - Child" character varying(255),
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" character varying(255),
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."maternalcohort_2024W41" OWNER TO lamisplus_etl;

--
-- Name: maternalcohort_2024W42; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."maternalcohort_2024W42" (
    period text,
    "Patient ID" character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Mother Hospital Number" character varying,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying(255),
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" text,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying(255),
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" text,
    "Visit Status" character varying(255),
    "Mother DSD Status" character varying(255),
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" character varying(255),
    "Sex - Child" character varying(255),
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" character varying(255),
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."maternalcohort_2024W42" OWNER TO lamisplus_etl;

--
-- Name: maternalcohort_2024W43; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."maternalcohort_2024W43" (
    period text,
    "Patient ID" character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Mother Hospital Number" character varying,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying(255),
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" text,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying(255),
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" text,
    "Visit Status" character varying(255),
    "Mother DSD Status" character varying(255),
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" character varying(255),
    "Sex - Child" character varying(255),
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" character varying(255),
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."maternalcohort_2024W43" OWNER TO lamisplus_etl;

--
-- Name: maternalcohort_2024W44; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."maternalcohort_2024W44" (
    period text,
    "Patient ID" character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Mother Hospital Number" character varying,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying(255),
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" text,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying(255),
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" text,
    "Visit Status" character varying(255),
    "Mother DSD Status" character varying(255),
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" character varying(255),
    "Sex - Child" character varying(255),
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" character varying(255),
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."maternalcohort_2024W44" OWNER TO lamisplus_etl;

--
-- Name: maternalcohort_2024W45; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."maternalcohort_2024W45" (
    period text,
    "Patient ID" character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Mother Hospital Number" character varying,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying(255),
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" text,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying(255),
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" text,
    "Visit Status" character varying(255),
    "Mother DSD Status" character varying(255),
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" character varying(255),
    "Sex - Child" character varying(255),
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" character varying(255),
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."maternalcohort_2024W45" OWNER TO lamisplus_etl;

--
-- Name: maternalcohort_2024W46; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."maternalcohort_2024W46" (
    period text,
    "Patient ID" character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Mother Hospital Number" character varying,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying(255),
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" text,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying(255),
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" text,
    "Visit Status" character varying(255),
    "Mother DSD Status" character varying(255),
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" character varying(255),
    "Sex - Child" character varying(255),
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" character varying(255),
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."maternalcohort_2024W46" OWNER TO lamisplus_etl;

--
-- Name: maternalcohort_2024W47; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."maternalcohort_2024W47" (
    period text,
    "Patient ID" character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Mother Hospital Number" character varying,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying(255),
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" text,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying(255),
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" text,
    "Visit Status" character varying(255),
    "Mother DSD Status" character varying(255),
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" character varying(255),
    "Sex - Child" character varying(255),
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" character varying(255),
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."maternalcohort_2024W47" OWNER TO lamisplus_etl;

--
-- Name: maternalcohort_2024W48; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."maternalcohort_2024W48" (
    period text,
    "Patient ID" character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Mother Hospital Number" character varying,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying(255),
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" text,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying(255),
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" text,
    "Visit Status" character varying(255),
    "Mother DSD Status" character varying(255),
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" character varying(255),
    "Sex - Child" character varying(255),
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" character varying(255),
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."maternalcohort_2024W48" OWNER TO lamisplus_etl;

--
-- Name: maternalcohort_2024W49; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."maternalcohort_2024W49" (
    period text,
    "Patient ID" character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Mother Hospital Number" character varying,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying(255),
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" text,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying(255),
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" text,
    "Visit Status" character varying(255),
    "Mother DSD Status" character varying(255),
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" character varying(255),
    "Sex - Child" character varying(255),
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" character varying(255),
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."maternalcohort_2024W49" OWNER TO lamisplus_etl;

--
-- Name: maternalcohort_2024W5; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."maternalcohort_2024W5" (
    period text,
    "Patient ID" character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Mother Hospital Number" character varying,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying(255),
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" text,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying(255),
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" text,
    "Visit Status" character varying(255),
    "Mother DSD Status" character varying(255),
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" character varying(255),
    "Sex - Child" character varying(255),
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" character varying(255),
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."maternalcohort_2024W5" OWNER TO lamisplus_etl;

--
-- Name: maternalcohort_2024W50; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."maternalcohort_2024W50" (
    period text,
    "Patient ID" character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Mother Hospital Number" character varying,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying(255),
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" text,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying(255),
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" text,
    "Visit Status" character varying(255),
    "Mother DSD Status" character varying(255),
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" character varying(255),
    "Sex - Child" character varying(255),
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" character varying(255),
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."maternalcohort_2024W50" OWNER TO lamisplus_etl;

--
-- Name: maternalcohort_2024W51; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."maternalcohort_2024W51" (
    period text,
    "Patient ID" character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Mother Hospital Number" character varying,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying(255),
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" text,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying(255),
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" text,
    "Visit Status" character varying(255),
    "Mother DSD Status" character varying(255),
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" character varying(255),
    "Sex - Child" character varying(255),
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" character varying(255),
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."maternalcohort_2024W51" OWNER TO lamisplus_etl;

--
-- Name: maternalcohort_2024W52; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."maternalcohort_2024W52" (
    period text,
    "Patient ID" character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Mother Hospital Number" character varying,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying(255),
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" text,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying(255),
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" text,
    "Visit Status" character varying(255),
    "Mother DSD Status" character varying(255),
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" character varying(255),
    "Sex - Child" character varying(255),
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" character varying(255),
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."maternalcohort_2024W52" OWNER TO lamisplus_etl;

--
-- Name: maternalcohort_2024W6; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."maternalcohort_2024W6" (
    period text,
    "Patient ID" character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Mother Hospital Number" character varying,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying(255),
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" text,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying(255),
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" text,
    "Visit Status" character varying(255),
    "Mother DSD Status" character varying(255),
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" character varying(255),
    "Sex - Child" character varying(255),
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" character varying(255),
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."maternalcohort_2024W6" OWNER TO lamisplus_etl;

--
-- Name: maternalcohort_2024W7; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."maternalcohort_2024W7" (
    period text,
    "Patient ID" character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Mother Hospital Number" character varying,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying(255),
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" text,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying(255),
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" text,
    "Visit Status" character varying(255),
    "Mother DSD Status" character varying(255),
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" character varying(255),
    "Sex - Child" character varying(255),
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" character varying(255),
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."maternalcohort_2024W7" OWNER TO lamisplus_etl;

--
-- Name: maternalcohort_2024W8; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."maternalcohort_2024W8" (
    period text,
    "Patient ID" character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Mother Hospital Number" character varying,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying(255),
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" text,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying(255),
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" text,
    "Visit Status" character varying(255),
    "Mother DSD Status" character varying(255),
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" character varying(255),
    "Sex - Child" character varying(255),
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" character varying(255),
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."maternalcohort_2024W8" OWNER TO lamisplus_etl;

--
-- Name: maternalcohort_2024W9; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."maternalcohort_2024W9" (
    period text,
    "Patient ID" character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Mother Hospital Number" character varying,
    "Mother Unique ID" character varying,
    "Mother Date of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" text,
    "Modality" character varying(255),
    "Point of Entry" character varying,
    "Date of Index ANC Registration" date,
    "LMP Date" date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Gravida" integer,
    "Parity" integer,
    "PCV @ANC registration" text,
    "Hepatitis B Test Result" character varying(255),
    "Treated for Hepatitis B" character varying(255),
    "Syphilis Test Result" character varying(255),
    "TB screening Status" text,
    "Date tested for HIV" text,
    "Type of HIV test" text,
    "Mother ART Start Date" date,
    "Timing of ART initiation in mother" character varying(255),
    "Current Pregnancy Status" character varying,
    "GA at last viisit (weeks)" smallint,
    "Mother Current ART Status" text,
    "Visit Status" character varying(255),
    "Mother DSD Status" character varying(255),
    "Due Date for VL Sample collection @ 32 weeks" timestamp without time zone,
    "Date for VL sample collection @ 32 weeks" date,
    "VL result at 32-36 weeks GA" smallint,
    "Current Viral load Result" character varying,
    "Date of Current VL" date,
    "Expected Date of Delivery" date,
    "Place of Delivery" character varying(255),
    "Mode of Delivery" character varying(255),
    "Fetal outcome (Child status)" character varying(255),
    "Child hospital ID number" character varying(255),
    "Sex - Child" character varying(255),
    "Birth Weight" double precision,
    "Date of ARV Prophylaxis Commencemment" character varying,
    "Type of Prophylaxis (ePNP or regular)" character varying,
    "Date of CTX (Cotrimoxazole)" character varying,
    "Current infant fedding options" character varying(255),
    "Date of First DNA PCR Sample collection" date,
    "Result of first DNA PCR test" character varying,
    "Date of Second DNA PCR test sample collection" date,
    "Result of second DNA PCR test" character varying,
    "Date second DNA PCR result was received" date,
    "Date of confirmatory DNA PCR test sample collection" date,
    "Result of confirmatory DNA PCR test" character varying,
    "Date confirmatory DNA PCT result was received" date,
    "Sample collection date for Confirmatory DBS (if DBS positive)" text,
    "Result of Confirmatory DBS" text,
    "Date of Child Final Outcome test" text,
    "Result (Child Final Outcome)" text,
    "Child ART Start Date" text,
    "Child Unique ID" character varying(255),
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."maternalcohort_2024W9" OWNER TO lamisplus_etl;

--
-- Name: partition_name; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public.partition_name (
    concat text
);


ALTER TABLE public.partition_name OWNER TO lamisplus_etl;

--
-- Name: partner_attribute_combo; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public.partner_attribute_combo (
    id bigint,
    partner_code character varying(255),
    attribute_combo character varying(255),
    period character varying
);


ALTER TABLE public.partner_attribute_combo OWNER TO lamisplus_etl;

--
-- Name: period; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public.period (
    periodid character varying,
    periodcode character varying,
    table_name_pmtct_hts character varying,
    is_active boolean,
    start_date date,
    date date,
    table_name_maternal_cohort character varying,
    is_current boolean,
    is_radet_available boolean DEFAULT false,
    table_name character varying
);


ALTER TABLE public.period OWNER TO lamisplus_etl;

--
-- Name: pmtct_hts; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public.pmtct_hts (
    period text,
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying(255),
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" timestamp without time zone,
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
)
PARTITION BY LIST (period);


ALTER TABLE public.pmtct_hts OWNER TO lamisplus_etl;

--
-- Name: pmtcthts_2024Q3; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."pmtcthts_2024Q3" (
    period text,
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying(255),
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" timestamp without time zone,
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."pmtcthts_2024Q3" OWNER TO lamisplus_etl;

--
-- Name: pmtcthts_2024Q4; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."pmtcthts_2024Q4" (
    period text,
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying(255),
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" timestamp without time zone,
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."pmtcthts_2024Q4" OWNER TO lamisplus_etl;

--
-- Name: pmtcthts_2024W10; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."pmtcthts_2024W10" (
    period text,
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying(255),
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" timestamp without time zone,
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."pmtcthts_2024W10" OWNER TO lamisplus_etl;

--
-- Name: pmtcthts_2024W11; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."pmtcthts_2024W11" (
    period text,
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying(255),
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" timestamp without time zone,
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."pmtcthts_2024W11" OWNER TO lamisplus_etl;

--
-- Name: pmtcthts_2024W12; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."pmtcthts_2024W12" (
    period text,
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying(255),
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" timestamp without time zone,
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."pmtcthts_2024W12" OWNER TO lamisplus_etl;

--
-- Name: pmtcthts_2024W13; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."pmtcthts_2024W13" (
    period text,
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying(255),
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" timestamp without time zone,
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."pmtcthts_2024W13" OWNER TO lamisplus_etl;

--
-- Name: pmtcthts_2024W14; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."pmtcthts_2024W14" (
    period text,
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying(255),
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" timestamp without time zone,
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."pmtcthts_2024W14" OWNER TO lamisplus_etl;

--
-- Name: pmtcthts_2024W15; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."pmtcthts_2024W15" (
    period text,
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying(255),
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" timestamp without time zone,
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."pmtcthts_2024W15" OWNER TO lamisplus_etl;

--
-- Name: pmtcthts_2024W16; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."pmtcthts_2024W16" (
    period text,
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying(255),
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" timestamp without time zone,
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."pmtcthts_2024W16" OWNER TO lamisplus_etl;

--
-- Name: pmtcthts_2024W17; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."pmtcthts_2024W17" (
    period text,
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying(255),
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" timestamp without time zone,
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."pmtcthts_2024W17" OWNER TO lamisplus_etl;

--
-- Name: pmtcthts_2024W18; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."pmtcthts_2024W18" (
    period text,
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying(255),
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" timestamp without time zone,
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."pmtcthts_2024W18" OWNER TO lamisplus_etl;

--
-- Name: pmtcthts_2024W19; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."pmtcthts_2024W19" (
    period text,
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying(255),
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" timestamp without time zone,
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."pmtcthts_2024W19" OWNER TO lamisplus_etl;

--
-- Name: pmtcthts_2024W2; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."pmtcthts_2024W2" (
    period text,
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying(255),
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" timestamp without time zone,
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."pmtcthts_2024W2" OWNER TO lamisplus_etl;

--
-- Name: pmtcthts_2024W20; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."pmtcthts_2024W20" (
    period text,
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying(255),
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" timestamp without time zone,
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."pmtcthts_2024W20" OWNER TO lamisplus_etl;

--
-- Name: pmtcthts_2024W21; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."pmtcthts_2024W21" (
    period text,
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying(255),
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" timestamp without time zone,
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."pmtcthts_2024W21" OWNER TO lamisplus_etl;

--
-- Name: pmtcthts_2024W22; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."pmtcthts_2024W22" (
    period text,
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying(255),
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" timestamp without time zone,
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."pmtcthts_2024W22" OWNER TO lamisplus_etl;

--
-- Name: pmtcthts_2024W23; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."pmtcthts_2024W23" (
    period text,
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying(255),
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" timestamp without time zone,
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."pmtcthts_2024W23" OWNER TO lamisplus_etl;

--
-- Name: pmtcthts_2024W24; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."pmtcthts_2024W24" (
    period text,
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying(255),
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" timestamp without time zone,
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."pmtcthts_2024W24" OWNER TO lamisplus_etl;

--
-- Name: pmtcthts_2024W25; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."pmtcthts_2024W25" (
    period text,
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying(255),
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" timestamp without time zone,
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."pmtcthts_2024W25" OWNER TO lamisplus_etl;

--
-- Name: pmtcthts_2024W26; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."pmtcthts_2024W26" (
    period text,
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying(255),
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" timestamp without time zone,
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."pmtcthts_2024W26" OWNER TO lamisplus_etl;

--
-- Name: pmtcthts_2024W27; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."pmtcthts_2024W27" (
    period text,
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying(255),
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" timestamp without time zone,
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."pmtcthts_2024W27" OWNER TO lamisplus_etl;

--
-- Name: pmtcthts_2024W28; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."pmtcthts_2024W28" (
    period text,
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying(255),
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" timestamp without time zone,
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."pmtcthts_2024W28" OWNER TO lamisplus_etl;

--
-- Name: pmtcthts_2024W29; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."pmtcthts_2024W29" (
    period text,
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying(255),
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" timestamp without time zone,
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."pmtcthts_2024W29" OWNER TO lamisplus_etl;

--
-- Name: pmtcthts_2024W3; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."pmtcthts_2024W3" (
    period text,
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying(255),
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" timestamp without time zone,
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."pmtcthts_2024W3" OWNER TO lamisplus_etl;

--
-- Name: pmtcthts_2024W30; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."pmtcthts_2024W30" (
    period text,
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying(255),
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" timestamp without time zone,
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."pmtcthts_2024W30" OWNER TO lamisplus_etl;

--
-- Name: pmtcthts_2024W31; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."pmtcthts_2024W31" (
    period text,
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying(255),
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" timestamp without time zone,
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."pmtcthts_2024W31" OWNER TO lamisplus_etl;

--
-- Name: pmtcthts_2024W32; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."pmtcthts_2024W32" (
    period text,
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying(255),
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" timestamp without time zone,
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."pmtcthts_2024W32" OWNER TO lamisplus_etl;

--
-- Name: pmtcthts_2024W33; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."pmtcthts_2024W33" (
    period text,
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying(255),
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" timestamp without time zone,
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."pmtcthts_2024W33" OWNER TO lamisplus_etl;

--
-- Name: pmtcthts_2024W34; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."pmtcthts_2024W34" (
    period text,
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying(255),
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" timestamp without time zone,
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."pmtcthts_2024W34" OWNER TO lamisplus_etl;

--
-- Name: pmtcthts_2024W35; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."pmtcthts_2024W35" (
    period text,
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying(255),
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" timestamp without time zone,
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."pmtcthts_2024W35" OWNER TO lamisplus_etl;

--
-- Name: pmtcthts_2024W36; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."pmtcthts_2024W36" (
    period text,
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying(255),
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" timestamp without time zone,
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."pmtcthts_2024W36" OWNER TO lamisplus_etl;

--
-- Name: pmtcthts_2024W37; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."pmtcthts_2024W37" (
    period text,
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying(255),
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" timestamp without time zone,
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."pmtcthts_2024W37" OWNER TO lamisplus_etl;

--
-- Name: pmtcthts_2024W38; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."pmtcthts_2024W38" (
    period text,
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying(255),
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" timestamp without time zone,
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."pmtcthts_2024W38" OWNER TO lamisplus_etl;

--
-- Name: pmtcthts_2024W39; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."pmtcthts_2024W39" (
    period text,
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying(255),
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" timestamp without time zone,
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."pmtcthts_2024W39" OWNER TO lamisplus_etl;

--
-- Name: pmtcthts_2024W4; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."pmtcthts_2024W4" (
    period text,
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying(255),
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" timestamp without time zone,
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."pmtcthts_2024W4" OWNER TO lamisplus_etl;

--
-- Name: pmtcthts_2024W40; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."pmtcthts_2024W40" (
    period text,
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying(255),
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" timestamp without time zone,
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."pmtcthts_2024W40" OWNER TO lamisplus_etl;

--
-- Name: pmtcthts_2024W41; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."pmtcthts_2024W41" (
    period text,
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying(255),
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" timestamp without time zone,
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."pmtcthts_2024W41" OWNER TO lamisplus_etl;

--
-- Name: pmtcthts_2024W42; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."pmtcthts_2024W42" (
    period text,
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying(255),
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" timestamp without time zone,
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."pmtcthts_2024W42" OWNER TO lamisplus_etl;

--
-- Name: pmtcthts_2024W43; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."pmtcthts_2024W43" (
    period text,
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying(255),
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" timestamp without time zone,
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."pmtcthts_2024W43" OWNER TO lamisplus_etl;

--
-- Name: pmtcthts_2024W44; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."pmtcthts_2024W44" (
    period text,
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying(255),
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" timestamp without time zone,
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."pmtcthts_2024W44" OWNER TO lamisplus_etl;

--
-- Name: pmtcthts_2024W45; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."pmtcthts_2024W45" (
    period text,
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying(255),
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" timestamp without time zone,
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."pmtcthts_2024W45" OWNER TO lamisplus_etl;

--
-- Name: pmtcthts_2024W46; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."pmtcthts_2024W46" (
    period text,
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying(255),
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" timestamp without time zone,
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."pmtcthts_2024W46" OWNER TO lamisplus_etl;

--
-- Name: pmtcthts_2024W47; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."pmtcthts_2024W47" (
    period text,
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying(255),
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" timestamp without time zone,
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."pmtcthts_2024W47" OWNER TO lamisplus_etl;

--
-- Name: pmtcthts_2024W48; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."pmtcthts_2024W48" (
    period text,
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying(255),
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" timestamp without time zone,
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."pmtcthts_2024W48" OWNER TO lamisplus_etl;

--
-- Name: pmtcthts_2024W49; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."pmtcthts_2024W49" (
    period text,
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying(255),
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" timestamp without time zone,
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."pmtcthts_2024W49" OWNER TO lamisplus_etl;

--
-- Name: pmtcthts_2024W5; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."pmtcthts_2024W5" (
    period text,
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying(255),
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" timestamp without time zone,
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."pmtcthts_2024W5" OWNER TO lamisplus_etl;

--
-- Name: pmtcthts_2024W50; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."pmtcthts_2024W50" (
    period text,
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying(255),
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" timestamp without time zone,
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."pmtcthts_2024W50" OWNER TO lamisplus_etl;

--
-- Name: pmtcthts_2024W51; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."pmtcthts_2024W51" (
    period text,
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying(255),
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" timestamp without time zone,
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."pmtcthts_2024W51" OWNER TO lamisplus_etl;

--
-- Name: pmtcthts_2024W52; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."pmtcthts_2024W52" (
    period text,
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying(255),
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" timestamp without time zone,
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."pmtcthts_2024W52" OWNER TO lamisplus_etl;

--
-- Name: pmtcthts_2024W6; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."pmtcthts_2024W6" (
    period text,
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying(255),
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" timestamp without time zone,
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."pmtcthts_2024W6" OWNER TO lamisplus_etl;

--
-- Name: pmtcthts_2024W7; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."pmtcthts_2024W7" (
    period text,
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying(255),
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" timestamp without time zone,
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."pmtcthts_2024W7" OWNER TO lamisplus_etl;

--
-- Name: pmtcthts_2024W8; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."pmtcthts_2024W8" (
    period text,
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying(255),
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" timestamp without time zone,
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."pmtcthts_2024W8" OWNER TO lamisplus_etl;

--
-- Name: pmtcthts_2024W9; Type: TABLE; Schema: public; Owner: lamisplus_etl
--

CREATE TABLE public."pmtcthts_2024W9" (
    period text,
    personuuid character varying,
    "State" character varying,
    "LGA" character varying,
    datimid character varying,
    "Facility" character varying,
    "Patient ID" character varying,
    id bigint,
    "ANC Number" character varying(255),
    "Mother Hospital Num" character varying,
    "Mother Date  of Birth" date,
    "Age" numeric,
    "Marital Status" text,
    "ANC Setting" character varying(255),
    first_anc_date date,
    "Gestational Age (Weeks) @ First ANC visit" integer,
    "Garvida" integer,
    "Parity" integer,
    hbstatus_delivery character varying(255),
    tested_syphilis_anc character varying(255),
    test_result_syphilis_anc character varying(255),
    partner_syphilis_status text,
    dateofregistration date,
    hivenrollmentdate date,
    partner_accepthivtest text,
    partner_age text,
    dateofregistrationonhiv date,
    date_confirmed_hiv date,
    "Mother ART Start Date" date,
    "Previously Known Hiv Status" character varying(255),
    "Date Tested for Hepatitis B" timestamp without time zone,
    "Hepatitis B Test Result" text,
    "Date Tested for Hepatitis C" timestamp without time zone,
    "Hepatitis C Test Result" text,
    hivrestested text,
    "Date tested for Syphillis" timestamp without time zone,
    "HIV Test Result" text,
    acceptedhivtesting text,
    "Date Tested for HIV" text,
    receivedhivretestedresult text,
    previouslyknownhivpositive text,
    "Point of Entry" character varying,
    "Modality" character varying,
    "Date of registration in index pregnancy" date,
    "Mother Unique ID" character varying,
    "Date Of Maternal Retesting" timestamp without time zone,
    "Maternal Retesting Result" character varying,
    "Linked to Syphilis Treatment" text,
    "If Recency Testing Opt In" text,
    "Recency ID" text,
    "Recency Test Type" text,
    "Recency Test Date (yyyy_mm_dd)" text,
    "Recency Interpretation" text,
    "Viral Load Sample Collection Date" date,
    "Final Recency Result" text,
    "Viral Load Confirmation Result" character varying,
    "Viral Load Confirmation Date (yyyyy-mm-dd)" timestamp without time zone,
    period_start_date date,
    period_end_date date,
    "Datim ID" character varying
);


ALTER TABLE public."pmtcthts_2024W9" OWNER TO lamisplus_etl;

--
-- Name: aggregate_flatfile_2024Q2; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024Q2" FOR VALUES IN ('2024Q2');


--
-- Name: aggregate_flatfile_2024Q3; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024Q3" FOR VALUES IN ('2024Q3');


--
-- Name: aggregate_flatfile_2024Q4; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024Q4" FOR VALUES IN ('2024Q4');


--
-- Name: aggregate_flatfile_2024W1; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024W1" FOR VALUES IN ('2024W1');


--
-- Name: aggregate_flatfile_2024W10; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024W10" FOR VALUES IN ('2024W10');


--
-- Name: aggregate_flatfile_2024W11; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024W11" FOR VALUES IN ('2024W11');


--
-- Name: aggregate_flatfile_2024W12; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024W12" FOR VALUES IN ('2024W12');


--
-- Name: aggregate_flatfile_2024W13; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024W13" FOR VALUES IN ('2024W13');


--
-- Name: aggregate_flatfile_2024W14; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024W14" FOR VALUES IN ('2024W14');


--
-- Name: aggregate_flatfile_2024W15; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024W15" FOR VALUES IN ('2024W15');


--
-- Name: aggregate_flatfile_2024W16; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024W16" FOR VALUES IN ('2024W16');


--
-- Name: aggregate_flatfile_2024W17; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024W17" FOR VALUES IN ('2024W17');


--
-- Name: aggregate_flatfile_2024W18; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024W18" FOR VALUES IN ('2024W18');


--
-- Name: aggregate_flatfile_2024W19; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024W19" FOR VALUES IN ('2024W19');


--
-- Name: aggregate_flatfile_2024W2; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024W2" FOR VALUES IN ('2024W2');


--
-- Name: aggregate_flatfile_2024W20; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024W20" FOR VALUES IN ('2024W20');


--
-- Name: aggregate_flatfile_2024W21; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024W21" FOR VALUES IN ('2024W21');


--
-- Name: aggregate_flatfile_2024W22; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024W22" FOR VALUES IN ('2024W22');


--
-- Name: aggregate_flatfile_2024W23; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024W23" FOR VALUES IN ('2024W23');


--
-- Name: aggregate_flatfile_2024W24; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024W24" FOR VALUES IN ('2024W24');


--
-- Name: aggregate_flatfile_2024W25; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024W25" FOR VALUES IN ('2024W25');


--
-- Name: aggregate_flatfile_2024W26; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024W26" FOR VALUES IN ('2024W26');


--
-- Name: aggregate_flatfile_2024W27; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024W27" FOR VALUES IN ('2024W27');


--
-- Name: aggregate_flatfile_2024W28; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024W28" FOR VALUES IN ('2024W28');


--
-- Name: aggregate_flatfile_2024W29; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024W29" FOR VALUES IN ('2024W29');


--
-- Name: aggregate_flatfile_2024W3; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024W3" FOR VALUES IN ('2024W3');


--
-- Name: aggregate_flatfile_2024W30; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024W30" FOR VALUES IN ('2024W30');


--
-- Name: aggregate_flatfile_2024W31; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024W31" FOR VALUES IN ('2024W31');


--
-- Name: aggregate_flatfile_2024W32; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024W32" FOR VALUES IN ('2024W32');


--
-- Name: aggregate_flatfile_2024W33; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024W33" FOR VALUES IN ('2024W33');


--
-- Name: aggregate_flatfile_2024W34; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024W34" FOR VALUES IN ('2024W34');


--
-- Name: aggregate_flatfile_2024W35; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024W35" FOR VALUES IN ('2024W35');


--
-- Name: aggregate_flatfile_2024W36; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024W36" FOR VALUES IN ('2024W36');


--
-- Name: aggregate_flatfile_2024W37; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024W37" FOR VALUES IN ('2024W37');


--
-- Name: aggregate_flatfile_2024W38; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024W38" FOR VALUES IN ('2024W38');


--
-- Name: aggregate_flatfile_2024W39; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024W39" FOR VALUES IN ('2024W39');


--
-- Name: aggregate_flatfile_2024W4; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024W4" FOR VALUES IN ('2024W4');


--
-- Name: aggregate_flatfile_2024W40; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024W40" FOR VALUES IN ('2024W40');


--
-- Name: aggregate_flatfile_2024W41; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024W41" FOR VALUES IN ('2024W41');


--
-- Name: aggregate_flatfile_2024W42; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024W42" FOR VALUES IN ('2024W42');


--
-- Name: aggregate_flatfile_2024W43; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024W43" FOR VALUES IN ('2024W43');


--
-- Name: aggregate_flatfile_2024W44; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024W44" FOR VALUES IN ('2024W44');


--
-- Name: aggregate_flatfile_2024W45; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024W45" FOR VALUES IN ('2024W45');


--
-- Name: aggregate_flatfile_2024W46; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024W46" FOR VALUES IN ('2024W46');


--
-- Name: aggregate_flatfile_2024W47; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024W47" FOR VALUES IN ('2024W47');


--
-- Name: aggregate_flatfile_2024W48; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024W48" FOR VALUES IN ('2024W48');


--
-- Name: aggregate_flatfile_2024W49; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024W49" FOR VALUES IN ('2024W49');


--
-- Name: aggregate_flatfile_2024W5; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024W5" FOR VALUES IN ('2024W5');


--
-- Name: aggregate_flatfile_2024W50; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024W50" FOR VALUES IN ('2024W50');


--
-- Name: aggregate_flatfile_2024W51; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024W51" FOR VALUES IN ('2024W51');


--
-- Name: aggregate_flatfile_2024W52; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024W52" FOR VALUES IN ('2024W52');


--
-- Name: aggregate_flatfile_2024W6; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024W6" FOR VALUES IN ('2024W6');


--
-- Name: aggregate_flatfile_2024W7; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024W7" FOR VALUES IN ('2024W7');


--
-- Name: aggregate_flatfile_2024W8; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024W8" FOR VALUES IN ('2024W8');


--
-- Name: aggregate_flatfile_2024W9; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.aggregate_flatfile ATTACH PARTITION public."aggregate_flatfile_2024W9" FOR VALUES IN ('2024W9');


--
-- Name: maternalcohort_2024Q3; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.maternal_cohort ATTACH PARTITION public."maternalcohort_2024Q3" FOR VALUES IN ('2024Q3');


--
-- Name: maternalcohort_2024Q4; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.maternal_cohort ATTACH PARTITION public."maternalcohort_2024Q4" FOR VALUES IN ('2024Q4');


--
-- Name: maternalcohort_2024W10; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.maternal_cohort ATTACH PARTITION public."maternalcohort_2024W10" FOR VALUES IN ('2024W10');


--
-- Name: maternalcohort_2024W11; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.maternal_cohort ATTACH PARTITION public."maternalcohort_2024W11" FOR VALUES IN ('2024W11');


--
-- Name: maternalcohort_2024W12; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.maternal_cohort ATTACH PARTITION public."maternalcohort_2024W12" FOR VALUES IN ('2024W12');


--
-- Name: maternalcohort_2024W13; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.maternal_cohort ATTACH PARTITION public."maternalcohort_2024W13" FOR VALUES IN ('2024W13');


--
-- Name: maternalcohort_2024W14; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.maternal_cohort ATTACH PARTITION public."maternalcohort_2024W14" FOR VALUES IN ('2024W14');


--
-- Name: maternalcohort_2024W15; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.maternal_cohort ATTACH PARTITION public."maternalcohort_2024W15" FOR VALUES IN ('2024W15');


--
-- Name: maternalcohort_2024W16; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.maternal_cohort ATTACH PARTITION public."maternalcohort_2024W16" FOR VALUES IN ('2024W16');


--
-- Name: maternalcohort_2024W17; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.maternal_cohort ATTACH PARTITION public."maternalcohort_2024W17" FOR VALUES IN ('2024W17');


--
-- Name: maternalcohort_2024W18; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.maternal_cohort ATTACH PARTITION public."maternalcohort_2024W18" FOR VALUES IN ('2024W18');


--
-- Name: maternalcohort_2024W19; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.maternal_cohort ATTACH PARTITION public."maternalcohort_2024W19" FOR VALUES IN ('2024W19');


--
-- Name: maternalcohort_2024W2; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.maternal_cohort ATTACH PARTITION public."maternalcohort_2024W2" FOR VALUES IN ('2024W2');


--
-- Name: maternalcohort_2024W20; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.maternal_cohort ATTACH PARTITION public."maternalcohort_2024W20" FOR VALUES IN ('2024W20');


--
-- Name: maternalcohort_2024W21; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.maternal_cohort ATTACH PARTITION public."maternalcohort_2024W21" FOR VALUES IN ('2024W21');


--
-- Name: maternalcohort_2024W22; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.maternal_cohort ATTACH PARTITION public."maternalcohort_2024W22" FOR VALUES IN ('2024W22');


--
-- Name: maternalcohort_2024W23; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.maternal_cohort ATTACH PARTITION public."maternalcohort_2024W23" FOR VALUES IN ('2024W23');


--
-- Name: maternalcohort_2024W24; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.maternal_cohort ATTACH PARTITION public."maternalcohort_2024W24" FOR VALUES IN ('2024W24');


--
-- Name: maternalcohort_2024W25; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.maternal_cohort ATTACH PARTITION public."maternalcohort_2024W25" FOR VALUES IN ('2024W25');


--
-- Name: maternalcohort_2024W26; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.maternal_cohort ATTACH PARTITION public."maternalcohort_2024W26" FOR VALUES IN ('2024W26');


--
-- Name: maternalcohort_2024W27; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.maternal_cohort ATTACH PARTITION public."maternalcohort_2024W27" FOR VALUES IN ('2024W27');


--
-- Name: maternalcohort_2024W28; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.maternal_cohort ATTACH PARTITION public."maternalcohort_2024W28" FOR VALUES IN ('2024W28');


--
-- Name: maternalcohort_2024W29; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.maternal_cohort ATTACH PARTITION public."maternalcohort_2024W29" FOR VALUES IN ('2024W29');


--
-- Name: maternalcohort_2024W3; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.maternal_cohort ATTACH PARTITION public."maternalcohort_2024W3" FOR VALUES IN ('2024W3');


--
-- Name: maternalcohort_2024W30; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.maternal_cohort ATTACH PARTITION public."maternalcohort_2024W30" FOR VALUES IN ('2024W30');


--
-- Name: maternalcohort_2024W31; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.maternal_cohort ATTACH PARTITION public."maternalcohort_2024W31" FOR VALUES IN ('2024W31');


--
-- Name: maternalcohort_2024W32; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.maternal_cohort ATTACH PARTITION public."maternalcohort_2024W32" FOR VALUES IN ('2024W32');


--
-- Name: maternalcohort_2024W33; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.maternal_cohort ATTACH PARTITION public."maternalcohort_2024W33" FOR VALUES IN ('2024W33');


--
-- Name: maternalcohort_2024W34; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.maternal_cohort ATTACH PARTITION public."maternalcohort_2024W34" FOR VALUES IN ('2024W34');


--
-- Name: maternalcohort_2024W35; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.maternal_cohort ATTACH PARTITION public."maternalcohort_2024W35" FOR VALUES IN ('2024W35');


--
-- Name: maternalcohort_2024W36; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.maternal_cohort ATTACH PARTITION public."maternalcohort_2024W36" FOR VALUES IN ('2024W36');


--
-- Name: maternalcohort_2024W37; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.maternal_cohort ATTACH PARTITION public."maternalcohort_2024W37" FOR VALUES IN ('2024W37');


--
-- Name: maternalcohort_2024W38; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.maternal_cohort ATTACH PARTITION public."maternalcohort_2024W38" FOR VALUES IN ('2024W38');


--
-- Name: maternalcohort_2024W39; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.maternal_cohort ATTACH PARTITION public."maternalcohort_2024W39" FOR VALUES IN ('2024W39');


--
-- Name: maternalcohort_2024W4; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.maternal_cohort ATTACH PARTITION public."maternalcohort_2024W4" FOR VALUES IN ('2024W4');


--
-- Name: maternalcohort_2024W40; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.maternal_cohort ATTACH PARTITION public."maternalcohort_2024W40" FOR VALUES IN ('2024W40');


--
-- Name: maternalcohort_2024W41; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.maternal_cohort ATTACH PARTITION public."maternalcohort_2024W41" FOR VALUES IN ('2024W41');


--
-- Name: maternalcohort_2024W42; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.maternal_cohort ATTACH PARTITION public."maternalcohort_2024W42" FOR VALUES IN ('2024W42');


--
-- Name: maternalcohort_2024W43; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.maternal_cohort ATTACH PARTITION public."maternalcohort_2024W43" FOR VALUES IN ('2024W43');


--
-- Name: maternalcohort_2024W44; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.maternal_cohort ATTACH PARTITION public."maternalcohort_2024W44" FOR VALUES IN ('2024W44');


--
-- Name: maternalcohort_2024W45; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.maternal_cohort ATTACH PARTITION public."maternalcohort_2024W45" FOR VALUES IN ('2024W45');


--
-- Name: maternalcohort_2024W46; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.maternal_cohort ATTACH PARTITION public."maternalcohort_2024W46" FOR VALUES IN ('2024W46');


--
-- Name: maternalcohort_2024W47; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.maternal_cohort ATTACH PARTITION public."maternalcohort_2024W47" FOR VALUES IN ('2024W47');


--
-- Name: maternalcohort_2024W48; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.maternal_cohort ATTACH PARTITION public."maternalcohort_2024W48" FOR VALUES IN ('2024W48');


--
-- Name: maternalcohort_2024W49; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.maternal_cohort ATTACH PARTITION public."maternalcohort_2024W49" FOR VALUES IN ('2024W49');


--
-- Name: maternalcohort_2024W5; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.maternal_cohort ATTACH PARTITION public."maternalcohort_2024W5" FOR VALUES IN ('2024W5');


--
-- Name: maternalcohort_2024W50; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.maternal_cohort ATTACH PARTITION public."maternalcohort_2024W50" FOR VALUES IN ('2024W50');


--
-- Name: maternalcohort_2024W51; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.maternal_cohort ATTACH PARTITION public."maternalcohort_2024W51" FOR VALUES IN ('2024W51');


--
-- Name: maternalcohort_2024W52; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.maternal_cohort ATTACH PARTITION public."maternalcohort_2024W52" FOR VALUES IN ('2024W52');


--
-- Name: maternalcohort_2024W6; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.maternal_cohort ATTACH PARTITION public."maternalcohort_2024W6" FOR VALUES IN ('2024W6');


--
-- Name: maternalcohort_2024W7; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.maternal_cohort ATTACH PARTITION public."maternalcohort_2024W7" FOR VALUES IN ('2024W7');


--
-- Name: maternalcohort_2024W8; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.maternal_cohort ATTACH PARTITION public."maternalcohort_2024W8" FOR VALUES IN ('2024W8');


--
-- Name: maternalcohort_2024W9; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.maternal_cohort ATTACH PARTITION public."maternalcohort_2024W9" FOR VALUES IN ('2024W9');


--
-- Name: pmtcthts_2024Q3; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.pmtct_hts ATTACH PARTITION public."pmtcthts_2024Q3" FOR VALUES IN ('2024Q3');


--
-- Name: pmtcthts_2024Q4; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.pmtct_hts ATTACH PARTITION public."pmtcthts_2024Q4" FOR VALUES IN ('2024Q4');


--
-- Name: pmtcthts_2024W10; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.pmtct_hts ATTACH PARTITION public."pmtcthts_2024W10" FOR VALUES IN ('2024W10');


--
-- Name: pmtcthts_2024W11; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.pmtct_hts ATTACH PARTITION public."pmtcthts_2024W11" FOR VALUES IN ('2024W11');


--
-- Name: pmtcthts_2024W12; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.pmtct_hts ATTACH PARTITION public."pmtcthts_2024W12" FOR VALUES IN ('2024W12');


--
-- Name: pmtcthts_2024W13; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.pmtct_hts ATTACH PARTITION public."pmtcthts_2024W13" FOR VALUES IN ('2024W13');


--
-- Name: pmtcthts_2024W14; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.pmtct_hts ATTACH PARTITION public."pmtcthts_2024W14" FOR VALUES IN ('2024W14');


--
-- Name: pmtcthts_2024W15; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.pmtct_hts ATTACH PARTITION public."pmtcthts_2024W15" FOR VALUES IN ('2024W15');


--
-- Name: pmtcthts_2024W16; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.pmtct_hts ATTACH PARTITION public."pmtcthts_2024W16" FOR VALUES IN ('2024W16');


--
-- Name: pmtcthts_2024W17; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.pmtct_hts ATTACH PARTITION public."pmtcthts_2024W17" FOR VALUES IN ('2024W17');


--
-- Name: pmtcthts_2024W18; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.pmtct_hts ATTACH PARTITION public."pmtcthts_2024W18" FOR VALUES IN ('2024W18');


--
-- Name: pmtcthts_2024W19; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.pmtct_hts ATTACH PARTITION public."pmtcthts_2024W19" FOR VALUES IN ('2024W19');


--
-- Name: pmtcthts_2024W2; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.pmtct_hts ATTACH PARTITION public."pmtcthts_2024W2" FOR VALUES IN ('2024W2');


--
-- Name: pmtcthts_2024W20; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.pmtct_hts ATTACH PARTITION public."pmtcthts_2024W20" FOR VALUES IN ('2024W20');


--
-- Name: pmtcthts_2024W21; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.pmtct_hts ATTACH PARTITION public."pmtcthts_2024W21" FOR VALUES IN ('2024W21');


--
-- Name: pmtcthts_2024W22; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.pmtct_hts ATTACH PARTITION public."pmtcthts_2024W22" FOR VALUES IN ('2024W22');


--
-- Name: pmtcthts_2024W23; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.pmtct_hts ATTACH PARTITION public."pmtcthts_2024W23" FOR VALUES IN ('2024W23');


--
-- Name: pmtcthts_2024W24; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.pmtct_hts ATTACH PARTITION public."pmtcthts_2024W24" FOR VALUES IN ('2024W24');


--
-- Name: pmtcthts_2024W25; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.pmtct_hts ATTACH PARTITION public."pmtcthts_2024W25" FOR VALUES IN ('2024W25');


--
-- Name: pmtcthts_2024W26; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.pmtct_hts ATTACH PARTITION public."pmtcthts_2024W26" FOR VALUES IN ('2024W26');


--
-- Name: pmtcthts_2024W27; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.pmtct_hts ATTACH PARTITION public."pmtcthts_2024W27" FOR VALUES IN ('2024W27');


--
-- Name: pmtcthts_2024W28; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.pmtct_hts ATTACH PARTITION public."pmtcthts_2024W28" FOR VALUES IN ('2024W28');


--
-- Name: pmtcthts_2024W29; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.pmtct_hts ATTACH PARTITION public."pmtcthts_2024W29" FOR VALUES IN ('2024W29');


--
-- Name: pmtcthts_2024W3; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.pmtct_hts ATTACH PARTITION public."pmtcthts_2024W3" FOR VALUES IN ('2024W3');


--
-- Name: pmtcthts_2024W30; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.pmtct_hts ATTACH PARTITION public."pmtcthts_2024W30" FOR VALUES IN ('2024W30');


--
-- Name: pmtcthts_2024W31; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.pmtct_hts ATTACH PARTITION public."pmtcthts_2024W31" FOR VALUES IN ('2024W31');


--
-- Name: pmtcthts_2024W32; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.pmtct_hts ATTACH PARTITION public."pmtcthts_2024W32" FOR VALUES IN ('2024W32');


--
-- Name: pmtcthts_2024W33; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.pmtct_hts ATTACH PARTITION public."pmtcthts_2024W33" FOR VALUES IN ('2024W33');


--
-- Name: pmtcthts_2024W34; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.pmtct_hts ATTACH PARTITION public."pmtcthts_2024W34" FOR VALUES IN ('2024W34');


--
-- Name: pmtcthts_2024W35; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.pmtct_hts ATTACH PARTITION public."pmtcthts_2024W35" FOR VALUES IN ('2024W35');


--
-- Name: pmtcthts_2024W36; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.pmtct_hts ATTACH PARTITION public."pmtcthts_2024W36" FOR VALUES IN ('2024W36');


--
-- Name: pmtcthts_2024W37; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.pmtct_hts ATTACH PARTITION public."pmtcthts_2024W37" FOR VALUES IN ('2024W37');


--
-- Name: pmtcthts_2024W38; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.pmtct_hts ATTACH PARTITION public."pmtcthts_2024W38" FOR VALUES IN ('2024W38');


--
-- Name: pmtcthts_2024W39; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.pmtct_hts ATTACH PARTITION public."pmtcthts_2024W39" FOR VALUES IN ('2024W39');


--
-- Name: pmtcthts_2024W4; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.pmtct_hts ATTACH PARTITION public."pmtcthts_2024W4" FOR VALUES IN ('2024W4');


--
-- Name: pmtcthts_2024W40; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.pmtct_hts ATTACH PARTITION public."pmtcthts_2024W40" FOR VALUES IN ('2024W40');


--
-- Name: pmtcthts_2024W41; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.pmtct_hts ATTACH PARTITION public."pmtcthts_2024W41" FOR VALUES IN ('2024W41');


--
-- Name: pmtcthts_2024W42; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.pmtct_hts ATTACH PARTITION public."pmtcthts_2024W42" FOR VALUES IN ('2024W42');


--
-- Name: pmtcthts_2024W43; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.pmtct_hts ATTACH PARTITION public."pmtcthts_2024W43" FOR VALUES IN ('2024W43');


--
-- Name: pmtcthts_2024W44; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.pmtct_hts ATTACH PARTITION public."pmtcthts_2024W44" FOR VALUES IN ('2024W44');


--
-- Name: pmtcthts_2024W45; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.pmtct_hts ATTACH PARTITION public."pmtcthts_2024W45" FOR VALUES IN ('2024W45');


--
-- Name: pmtcthts_2024W46; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.pmtct_hts ATTACH PARTITION public."pmtcthts_2024W46" FOR VALUES IN ('2024W46');


--
-- Name: pmtcthts_2024W47; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.pmtct_hts ATTACH PARTITION public."pmtcthts_2024W47" FOR VALUES IN ('2024W47');


--
-- Name: pmtcthts_2024W48; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.pmtct_hts ATTACH PARTITION public."pmtcthts_2024W48" FOR VALUES IN ('2024W48');


--
-- Name: pmtcthts_2024W49; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.pmtct_hts ATTACH PARTITION public."pmtcthts_2024W49" FOR VALUES IN ('2024W49');


--
-- Name: pmtcthts_2024W5; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.pmtct_hts ATTACH PARTITION public."pmtcthts_2024W5" FOR VALUES IN ('2024W5');


--
-- Name: pmtcthts_2024W50; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.pmtct_hts ATTACH PARTITION public."pmtcthts_2024W50" FOR VALUES IN ('2024W50');


--
-- Name: pmtcthts_2024W51; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.pmtct_hts ATTACH PARTITION public."pmtcthts_2024W51" FOR VALUES IN ('2024W51');


--
-- Name: pmtcthts_2024W52; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.pmtct_hts ATTACH PARTITION public."pmtcthts_2024W52" FOR VALUES IN ('2024W52');


--
-- Name: pmtcthts_2024W6; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.pmtct_hts ATTACH PARTITION public."pmtcthts_2024W6" FOR VALUES IN ('2024W6');


--
-- Name: pmtcthts_2024W7; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.pmtct_hts ATTACH PARTITION public."pmtcthts_2024W7" FOR VALUES IN ('2024W7');


--
-- Name: pmtcthts_2024W8; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.pmtct_hts ATTACH PARTITION public."pmtcthts_2024W8" FOR VALUES IN ('2024W8');


--
-- Name: pmtcthts_2024W9; Type: TABLE ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.pmtct_hts ATTACH PARTITION public."pmtcthts_2024W9" FOR VALUES IN ('2024W9');


--
-- Name: central_data_element_pmtct central_data_element_pmtct_pkey; Type: CONSTRAINT; Schema: pmtct_hts; Owner: lamisplus_etl
--

ALTER TABLE ONLY pmtct_hts.central_data_element_pmtct
    ADD CONSTRAINT central_data_element_pmtct_pkey PRIMARY KEY (id);


--
-- Name: aggregate_flatfile aggregate_flatfile_backup_pkey3; Type: CONSTRAINT; Schema: public; Owner: emeka
--

ALTER TABLE ONLY public.aggregate_flatfile
    ADD CONSTRAINT aggregate_flatfile_backup_pkey3 PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024Q2 aggregate_flatfile_2024Q2_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024Q2"
    ADD CONSTRAINT "aggregate_flatfile_2024Q2_pkey" PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024Q3 aggregate_flatfile_2024Q3_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024Q3"
    ADD CONSTRAINT "aggregate_flatfile_2024Q3_pkey" PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024Q4 aggregate_flatfile_2024Q4_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024Q4"
    ADD CONSTRAINT "aggregate_flatfile_2024Q4_pkey" PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024W10 aggregate_flatfile_2024W10_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024W10"
    ADD CONSTRAINT "aggregate_flatfile_2024W10_pkey" PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024W11 aggregate_flatfile_2024W11_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024W11"
    ADD CONSTRAINT "aggregate_flatfile_2024W11_pkey" PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024W12 aggregate_flatfile_2024W12_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024W12"
    ADD CONSTRAINT "aggregate_flatfile_2024W12_pkey" PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024W13 aggregate_flatfile_2024W13_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024W13"
    ADD CONSTRAINT "aggregate_flatfile_2024W13_pkey" PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024W14 aggregate_flatfile_2024W14_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024W14"
    ADD CONSTRAINT "aggregate_flatfile_2024W14_pkey" PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024W15 aggregate_flatfile_2024W15_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024W15"
    ADD CONSTRAINT "aggregate_flatfile_2024W15_pkey" PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024W16 aggregate_flatfile_2024W16_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024W16"
    ADD CONSTRAINT "aggregate_flatfile_2024W16_pkey" PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024W17 aggregate_flatfile_2024W17_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024W17"
    ADD CONSTRAINT "aggregate_flatfile_2024W17_pkey" PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024W18 aggregate_flatfile_2024W18_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024W18"
    ADD CONSTRAINT "aggregate_flatfile_2024W18_pkey" PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024W19 aggregate_flatfile_2024W19_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024W19"
    ADD CONSTRAINT "aggregate_flatfile_2024W19_pkey" PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024W1 aggregate_flatfile_2024W1_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024W1"
    ADD CONSTRAINT "aggregate_flatfile_2024W1_pkey" PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024W20 aggregate_flatfile_2024W20_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024W20"
    ADD CONSTRAINT "aggregate_flatfile_2024W20_pkey" PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024W21 aggregate_flatfile_2024W21_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024W21"
    ADD CONSTRAINT "aggregate_flatfile_2024W21_pkey" PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024W22 aggregate_flatfile_2024W22_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024W22"
    ADD CONSTRAINT "aggregate_flatfile_2024W22_pkey" PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024W23 aggregate_flatfile_2024W23_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024W23"
    ADD CONSTRAINT "aggregate_flatfile_2024W23_pkey" PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024W24 aggregate_flatfile_2024W24_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024W24"
    ADD CONSTRAINT "aggregate_flatfile_2024W24_pkey" PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024W25 aggregate_flatfile_2024W25_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024W25"
    ADD CONSTRAINT "aggregate_flatfile_2024W25_pkey" PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024W26 aggregate_flatfile_2024W26_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024W26"
    ADD CONSTRAINT "aggregate_flatfile_2024W26_pkey" PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024W27 aggregate_flatfile_2024W27_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024W27"
    ADD CONSTRAINT "aggregate_flatfile_2024W27_pkey" PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024W28 aggregate_flatfile_2024W28_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024W28"
    ADD CONSTRAINT "aggregate_flatfile_2024W28_pkey" PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024W29 aggregate_flatfile_2024W29_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024W29"
    ADD CONSTRAINT "aggregate_flatfile_2024W29_pkey" PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024W2 aggregate_flatfile_2024W2_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024W2"
    ADD CONSTRAINT "aggregate_flatfile_2024W2_pkey" PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024W30 aggregate_flatfile_2024W30_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024W30"
    ADD CONSTRAINT "aggregate_flatfile_2024W30_pkey" PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024W31 aggregate_flatfile_2024W31_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024W31"
    ADD CONSTRAINT "aggregate_flatfile_2024W31_pkey" PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024W32 aggregate_flatfile_2024W32_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024W32"
    ADD CONSTRAINT "aggregate_flatfile_2024W32_pkey" PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024W33 aggregate_flatfile_2024W33_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024W33"
    ADD CONSTRAINT "aggregate_flatfile_2024W33_pkey" PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024W34 aggregate_flatfile_2024W34_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024W34"
    ADD CONSTRAINT "aggregate_flatfile_2024W34_pkey" PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024W35 aggregate_flatfile_2024W35_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024W35"
    ADD CONSTRAINT "aggregate_flatfile_2024W35_pkey" PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024W36 aggregate_flatfile_2024W36_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024W36"
    ADD CONSTRAINT "aggregate_flatfile_2024W36_pkey" PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024W37 aggregate_flatfile_2024W37_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024W37"
    ADD CONSTRAINT "aggregate_flatfile_2024W37_pkey" PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024W38 aggregate_flatfile_2024W38_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024W38"
    ADD CONSTRAINT "aggregate_flatfile_2024W38_pkey" PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024W39 aggregate_flatfile_2024W39_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024W39"
    ADD CONSTRAINT "aggregate_flatfile_2024W39_pkey" PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024W3 aggregate_flatfile_2024W3_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024W3"
    ADD CONSTRAINT "aggregate_flatfile_2024W3_pkey" PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024W40 aggregate_flatfile_2024W40_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024W40"
    ADD CONSTRAINT "aggregate_flatfile_2024W40_pkey" PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024W41 aggregate_flatfile_2024W41_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024W41"
    ADD CONSTRAINT "aggregate_flatfile_2024W41_pkey" PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024W42 aggregate_flatfile_2024W42_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024W42"
    ADD CONSTRAINT "aggregate_flatfile_2024W42_pkey" PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024W43 aggregate_flatfile_2024W43_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024W43"
    ADD CONSTRAINT "aggregate_flatfile_2024W43_pkey" PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024W44 aggregate_flatfile_2024W44_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024W44"
    ADD CONSTRAINT "aggregate_flatfile_2024W44_pkey" PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024W45 aggregate_flatfile_2024W45_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024W45"
    ADD CONSTRAINT "aggregate_flatfile_2024W45_pkey" PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024W46 aggregate_flatfile_2024W46_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024W46"
    ADD CONSTRAINT "aggregate_flatfile_2024W46_pkey" PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024W47 aggregate_flatfile_2024W47_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024W47"
    ADD CONSTRAINT "aggregate_flatfile_2024W47_pkey" PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024W48 aggregate_flatfile_2024W48_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024W48"
    ADD CONSTRAINT "aggregate_flatfile_2024W48_pkey" PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024W49 aggregate_flatfile_2024W49_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024W49"
    ADD CONSTRAINT "aggregate_flatfile_2024W49_pkey" PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024W4 aggregate_flatfile_2024W4_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024W4"
    ADD CONSTRAINT "aggregate_flatfile_2024W4_pkey" PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024W50 aggregate_flatfile_2024W50_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024W50"
    ADD CONSTRAINT "aggregate_flatfile_2024W50_pkey" PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024W51 aggregate_flatfile_2024W51_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024W51"
    ADD CONSTRAINT "aggregate_flatfile_2024W51_pkey" PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024W52 aggregate_flatfile_2024W52_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024W52"
    ADD CONSTRAINT "aggregate_flatfile_2024W52_pkey" PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024W5 aggregate_flatfile_2024W5_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024W5"
    ADD CONSTRAINT "aggregate_flatfile_2024W5_pkey" PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024W6 aggregate_flatfile_2024W6_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024W6"
    ADD CONSTRAINT "aggregate_flatfile_2024W6_pkey" PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024W7 aggregate_flatfile_2024W7_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024W7"
    ADD CONSTRAINT "aggregate_flatfile_2024W7_pkey" PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024W8 aggregate_flatfile_2024W8_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024W8"
    ADD CONSTRAINT "aggregate_flatfile_2024W8_pkey" PRIMARY KEY (id, period);


--
-- Name: aggregate_flatfile_2024W9 aggregate_flatfile_2024W9_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public."aggregate_flatfile_2024W9"
    ADD CONSTRAINT "aggregate_flatfile_2024W9_pkey" PRIMARY KEY (id, period);


--
-- Name: central_category_option_combo central_category_option_combo_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.central_category_option_combo
    ADD CONSTRAINT central_category_option_combo_pkey PRIMARY KEY (id);


--
-- Name: central_data_element central_data_element_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.central_data_element
    ADD CONSTRAINT central_data_element_pkey PRIMARY KEY (id);


--
-- Name: central_partner_mapping central_partner_mapping_pkey; Type: CONSTRAINT; Schema: public; Owner: lamisplus_etl
--

ALTER TABLE ONLY public.central_partner_mapping
    ADD CONSTRAINT central_partner_mapping_pkey PRIMARY KEY (id);


--
-- Name: idx_tbiptscreening_outcome; Type: INDEX; Schema: maternal_cohort; Owner: lamisplus_etl
--

CREATE INDEX idx_tbiptscreening_outcome ON maternal_cohort.hiv_observation USING btree (tb_screening_status);


--
-- Name: personuuiddatim_pmtctmothervisitation; Type: INDEX; Schema: maternal_cohort; Owner: lamisplus_etl
--

CREATE INDEX personuuiddatim_pmtctmothervisitation ON maternal_cohort.temp_pmtct_mother_visitation USING btree (person_uuid, ods_datim_id);


--
-- Name: idx_htsclient_uuidodsdatimid; Type: INDEX; Schema: pmtct_hts; Owner: lamisplus_etl
--

CREATE INDEX idx_htsclient_uuidodsdatimid ON pmtct_hts.hts_client USING btree (person_uuid_hts_client, ods_datim_id);


--
-- Name: idx_pmtctanc_uuidodsdatimid; Type: INDEX; Schema: pmtct_hts; Owner: lamisplus_etl
--

CREATE INDEX idx_pmtctanc_uuidodsdatimid ON pmtct_hts.pmtct_anc USING btree (person_uuid_anc, ods_datim_id);


--
-- Name: idx_pmtctdelivery_uuidodsdatimid; Type: INDEX; Schema: pmtct_hts; Owner: lamisplus_etl
--

CREATE INDEX idx_pmtctdelivery_uuidodsdatimid ON pmtct_hts.pmtct_delivery USING btree (person_uuid_delivery, ods_datim_id);


--
-- Name: idx_pmtctresult_uuidodsdatimid; Type: INDEX; Schema: pmtct_hts; Owner: lamisplus_etl
--

CREATE INDEX idx_pmtctresult_uuidodsdatimid ON pmtct_hts.result USING btree (uuid, ods_datim_id);


--
-- Name: datimiddate_aggregateflatfilepmtctmaternal; Type: INDEX; Schema: public; Owner: emeka
--

CREATE INDEX datimiddate_aggregateflatfilepmtctmaternal ON ONLY public.aggregate_flatfile USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024Q2_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024Q2_datim_id_date_idx" ON public."aggregate_flatfile_2024Q2" USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024Q3_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024Q3_datim_id_date_idx" ON public."aggregate_flatfile_2024Q3" USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024Q4_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024Q4_datim_id_date_idx" ON public."aggregate_flatfile_2024Q4" USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024W10_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024W10_datim_id_date_idx" ON public."aggregate_flatfile_2024W10" USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024W11_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024W11_datim_id_date_idx" ON public."aggregate_flatfile_2024W11" USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024W12_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024W12_datim_id_date_idx" ON public."aggregate_flatfile_2024W12" USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024W13_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024W13_datim_id_date_idx" ON public."aggregate_flatfile_2024W13" USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024W14_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024W14_datim_id_date_idx" ON public."aggregate_flatfile_2024W14" USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024W15_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024W15_datim_id_date_idx" ON public."aggregate_flatfile_2024W15" USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024W16_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024W16_datim_id_date_idx" ON public."aggregate_flatfile_2024W16" USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024W17_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024W17_datim_id_date_idx" ON public."aggregate_flatfile_2024W17" USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024W18_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024W18_datim_id_date_idx" ON public."aggregate_flatfile_2024W18" USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024W19_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024W19_datim_id_date_idx" ON public."aggregate_flatfile_2024W19" USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024W1_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024W1_datim_id_date_idx" ON public."aggregate_flatfile_2024W1" USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024W20_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024W20_datim_id_date_idx" ON public."aggregate_flatfile_2024W20" USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024W21_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024W21_datim_id_date_idx" ON public."aggregate_flatfile_2024W21" USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024W22_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024W22_datim_id_date_idx" ON public."aggregate_flatfile_2024W22" USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024W23_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024W23_datim_id_date_idx" ON public."aggregate_flatfile_2024W23" USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024W24_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024W24_datim_id_date_idx" ON public."aggregate_flatfile_2024W24" USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024W25_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024W25_datim_id_date_idx" ON public."aggregate_flatfile_2024W25" USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024W26_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024W26_datim_id_date_idx" ON public."aggregate_flatfile_2024W26" USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024W27_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024W27_datim_id_date_idx" ON public."aggregate_flatfile_2024W27" USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024W28_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024W28_datim_id_date_idx" ON public."aggregate_flatfile_2024W28" USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024W29_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024W29_datim_id_date_idx" ON public."aggregate_flatfile_2024W29" USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024W2_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024W2_datim_id_date_idx" ON public."aggregate_flatfile_2024W2" USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024W30_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024W30_datim_id_date_idx" ON public."aggregate_flatfile_2024W30" USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024W31_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024W31_datim_id_date_idx" ON public."aggregate_flatfile_2024W31" USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024W32_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024W32_datim_id_date_idx" ON public."aggregate_flatfile_2024W32" USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024W33_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024W33_datim_id_date_idx" ON public."aggregate_flatfile_2024W33" USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024W34_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024W34_datim_id_date_idx" ON public."aggregate_flatfile_2024W34" USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024W35_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024W35_datim_id_date_idx" ON public."aggregate_flatfile_2024W35" USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024W36_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024W36_datim_id_date_idx" ON public."aggregate_flatfile_2024W36" USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024W37_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024W37_datim_id_date_idx" ON public."aggregate_flatfile_2024W37" USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024W38_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024W38_datim_id_date_idx" ON public."aggregate_flatfile_2024W38" USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024W39_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024W39_datim_id_date_idx" ON public."aggregate_flatfile_2024W39" USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024W3_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024W3_datim_id_date_idx" ON public."aggregate_flatfile_2024W3" USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024W40_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024W40_datim_id_date_idx" ON public."aggregate_flatfile_2024W40" USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024W41_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024W41_datim_id_date_idx" ON public."aggregate_flatfile_2024W41" USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024W42_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024W42_datim_id_date_idx" ON public."aggregate_flatfile_2024W42" USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024W43_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024W43_datim_id_date_idx" ON public."aggregate_flatfile_2024W43" USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024W44_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024W44_datim_id_date_idx" ON public."aggregate_flatfile_2024W44" USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024W45_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024W45_datim_id_date_idx" ON public."aggregate_flatfile_2024W45" USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024W46_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024W46_datim_id_date_idx" ON public."aggregate_flatfile_2024W46" USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024W47_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024W47_datim_id_date_idx" ON public."aggregate_flatfile_2024W47" USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024W48_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024W48_datim_id_date_idx" ON public."aggregate_flatfile_2024W48" USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024W49_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024W49_datim_id_date_idx" ON public."aggregate_flatfile_2024W49" USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024W4_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024W4_datim_id_date_idx" ON public."aggregate_flatfile_2024W4" USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024W50_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024W50_datim_id_date_idx" ON public."aggregate_flatfile_2024W50" USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024W51_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024W51_datim_id_date_idx" ON public."aggregate_flatfile_2024W51" USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024W52_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024W52_datim_id_date_idx" ON public."aggregate_flatfile_2024W52" USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024W5_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024W5_datim_id_date_idx" ON public."aggregate_flatfile_2024W5" USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024W6_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024W6_datim_id_date_idx" ON public."aggregate_flatfile_2024W6" USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024W7_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024W7_datim_id_date_idx" ON public."aggregate_flatfile_2024W7" USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024W8_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024W8_datim_id_date_idx" ON public."aggregate_flatfile_2024W8" USING btree (datim_id, date);


--
-- Name: aggregate_flatfile_2024W9_datim_id_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "aggregate_flatfile_2024W9_datim_id_date_idx" ON public."aggregate_flatfile_2024W9" USING btree (datim_id, date);


--
-- Name: datimidperiodenddate_maternalcohort; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX datimidperiodenddate_maternalcohort ON ONLY public.maternal_cohort USING btree (datimid, period_end_date);


--
-- Name: datimidperiodenddate_pmtcthts; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX datimidperiodenddate_pmtcthts ON ONLY public.pmtct_hts USING btree (datimid, period_end_date);


--
-- Name: idx_datim_pmtct_maternal_cohort; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX idx_datim_pmtct_maternal_cohort ON ONLY public.maternal_cohort USING btree (datimid);


--
-- Name: idx_datim_pmtcthts_weekly; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX idx_datim_pmtcthts_weekly ON ONLY public.pmtct_hts USING btree (datimid);


--
-- Name: idx_period_pmtct_hts; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX idx_period_pmtct_hts ON ONLY public.pmtct_hts USING btree (period);


--
-- Name: idx_period_pmtct_maternal_cohort; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX idx_period_pmtct_maternal_cohort ON ONLY public.maternal_cohort USING btree (period);


--
-- Name: idx_periodstartend_pmtct_maternal_cohort; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX idx_periodstartend_pmtct_maternal_cohort ON ONLY public.maternal_cohort USING btree (period_start_date, period_end_date);


--
-- Name: idx_startdateenddate_pmtct_hts; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX idx_startdateenddate_pmtct_hts ON ONLY public.pmtct_hts USING btree (period_start_date, period_end_date);


--
-- Name: maternalcohort_2024Q3_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024Q3_Datim ID_idx" ON public."maternalcohort_2024Q3" USING btree (datimid);


--
-- Name: maternalcohort_2024Q3_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024Q3_datimid_period_end_date_idx" ON public."maternalcohort_2024Q3" USING btree (datimid, period_end_date);


--
-- Name: maternalcohort_2024Q3_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024Q3_period_idx" ON public."maternalcohort_2024Q3" USING btree (period);


--
-- Name: maternalcohort_2024Q3_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024Q3_period_start_date_period_end_date_idx" ON public."maternalcohort_2024Q3" USING btree (period_start_date, period_end_date);


--
-- Name: maternalcohort_2024Q4_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024Q4_Datim ID_idx" ON public."maternalcohort_2024Q4" USING btree (datimid);


--
-- Name: maternalcohort_2024Q4_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024Q4_datimid_period_end_date_idx" ON public."maternalcohort_2024Q4" USING btree (datimid, period_end_date);


--
-- Name: maternalcohort_2024Q4_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024Q4_period_idx" ON public."maternalcohort_2024Q4" USING btree (period);


--
-- Name: maternalcohort_2024Q4_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024Q4_period_start_date_period_end_date_idx" ON public."maternalcohort_2024Q4" USING btree (period_start_date, period_end_date);


--
-- Name: maternalcohort_2024W10_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W10_Datim ID_idx" ON public."maternalcohort_2024W10" USING btree (datimid);


--
-- Name: maternalcohort_2024W10_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W10_datimid_period_end_date_idx" ON public."maternalcohort_2024W10" USING btree (datimid, period_end_date);


--
-- Name: maternalcohort_2024W10_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W10_period_idx" ON public."maternalcohort_2024W10" USING btree (period);


--
-- Name: maternalcohort_2024W10_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W10_period_start_date_period_end_date_idx" ON public."maternalcohort_2024W10" USING btree (period_start_date, period_end_date);


--
-- Name: maternalcohort_2024W11_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W11_Datim ID_idx" ON public."maternalcohort_2024W11" USING btree (datimid);


--
-- Name: maternalcohort_2024W11_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W11_datimid_period_end_date_idx" ON public."maternalcohort_2024W11" USING btree (datimid, period_end_date);


--
-- Name: maternalcohort_2024W11_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W11_period_idx" ON public."maternalcohort_2024W11" USING btree (period);


--
-- Name: maternalcohort_2024W11_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W11_period_start_date_period_end_date_idx" ON public."maternalcohort_2024W11" USING btree (period_start_date, period_end_date);


--
-- Name: maternalcohort_2024W12_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W12_Datim ID_idx" ON public."maternalcohort_2024W12" USING btree (datimid);


--
-- Name: maternalcohort_2024W12_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W12_datimid_period_end_date_idx" ON public."maternalcohort_2024W12" USING btree (datimid, period_end_date);


--
-- Name: maternalcohort_2024W12_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W12_period_idx" ON public."maternalcohort_2024W12" USING btree (period);


--
-- Name: maternalcohort_2024W12_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W12_period_start_date_period_end_date_idx" ON public."maternalcohort_2024W12" USING btree (period_start_date, period_end_date);


--
-- Name: maternalcohort_2024W13_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W13_Datim ID_idx" ON public."maternalcohort_2024W13" USING btree (datimid);


--
-- Name: maternalcohort_2024W13_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W13_datimid_period_end_date_idx" ON public."maternalcohort_2024W13" USING btree (datimid, period_end_date);


--
-- Name: maternalcohort_2024W13_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W13_period_idx" ON public."maternalcohort_2024W13" USING btree (period);


--
-- Name: maternalcohort_2024W13_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W13_period_start_date_period_end_date_idx" ON public."maternalcohort_2024W13" USING btree (period_start_date, period_end_date);


--
-- Name: maternalcohort_2024W14_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W14_Datim ID_idx" ON public."maternalcohort_2024W14" USING btree (datimid);


--
-- Name: maternalcohort_2024W14_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W14_datimid_period_end_date_idx" ON public."maternalcohort_2024W14" USING btree (datimid, period_end_date);


--
-- Name: maternalcohort_2024W14_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W14_period_idx" ON public."maternalcohort_2024W14" USING btree (period);


--
-- Name: maternalcohort_2024W14_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W14_period_start_date_period_end_date_idx" ON public."maternalcohort_2024W14" USING btree (period_start_date, period_end_date);


--
-- Name: maternalcohort_2024W15_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W15_Datim ID_idx" ON public."maternalcohort_2024W15" USING btree (datimid);


--
-- Name: maternalcohort_2024W15_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W15_datimid_period_end_date_idx" ON public."maternalcohort_2024W15" USING btree (datimid, period_end_date);


--
-- Name: maternalcohort_2024W15_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W15_period_idx" ON public."maternalcohort_2024W15" USING btree (period);


--
-- Name: maternalcohort_2024W15_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W15_period_start_date_period_end_date_idx" ON public."maternalcohort_2024W15" USING btree (period_start_date, period_end_date);


--
-- Name: maternalcohort_2024W16_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W16_Datim ID_idx" ON public."maternalcohort_2024W16" USING btree (datimid);


--
-- Name: maternalcohort_2024W16_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W16_datimid_period_end_date_idx" ON public."maternalcohort_2024W16" USING btree (datimid, period_end_date);


--
-- Name: maternalcohort_2024W16_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W16_period_idx" ON public."maternalcohort_2024W16" USING btree (period);


--
-- Name: maternalcohort_2024W16_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W16_period_start_date_period_end_date_idx" ON public."maternalcohort_2024W16" USING btree (period_start_date, period_end_date);


--
-- Name: maternalcohort_2024W17_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W17_Datim ID_idx" ON public."maternalcohort_2024W17" USING btree (datimid);


--
-- Name: maternalcohort_2024W17_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W17_datimid_period_end_date_idx" ON public."maternalcohort_2024W17" USING btree (datimid, period_end_date);


--
-- Name: maternalcohort_2024W17_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W17_period_idx" ON public."maternalcohort_2024W17" USING btree (period);


--
-- Name: maternalcohort_2024W17_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W17_period_start_date_period_end_date_idx" ON public."maternalcohort_2024W17" USING btree (period_start_date, period_end_date);


--
-- Name: maternalcohort_2024W18_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W18_Datim ID_idx" ON public."maternalcohort_2024W18" USING btree (datimid);


--
-- Name: maternalcohort_2024W18_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W18_datimid_period_end_date_idx" ON public."maternalcohort_2024W18" USING btree (datimid, period_end_date);


--
-- Name: maternalcohort_2024W18_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W18_period_idx" ON public."maternalcohort_2024W18" USING btree (period);


--
-- Name: maternalcohort_2024W18_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W18_period_start_date_period_end_date_idx" ON public."maternalcohort_2024W18" USING btree (period_start_date, period_end_date);


--
-- Name: maternalcohort_2024W19_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W19_Datim ID_idx" ON public."maternalcohort_2024W19" USING btree (datimid);


--
-- Name: maternalcohort_2024W19_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W19_datimid_period_end_date_idx" ON public."maternalcohort_2024W19" USING btree (datimid, period_end_date);


--
-- Name: maternalcohort_2024W19_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W19_period_idx" ON public."maternalcohort_2024W19" USING btree (period);


--
-- Name: maternalcohort_2024W19_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W19_period_start_date_period_end_date_idx" ON public."maternalcohort_2024W19" USING btree (period_start_date, period_end_date);


--
-- Name: maternalcohort_2024W20_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W20_Datim ID_idx" ON public."maternalcohort_2024W20" USING btree (datimid);


--
-- Name: maternalcohort_2024W20_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W20_datimid_period_end_date_idx" ON public."maternalcohort_2024W20" USING btree (datimid, period_end_date);


--
-- Name: maternalcohort_2024W20_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W20_period_idx" ON public."maternalcohort_2024W20" USING btree (period);


--
-- Name: maternalcohort_2024W20_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W20_period_start_date_period_end_date_idx" ON public."maternalcohort_2024W20" USING btree (period_start_date, period_end_date);


--
-- Name: maternalcohort_2024W21_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W21_Datim ID_idx" ON public."maternalcohort_2024W21" USING btree (datimid);


--
-- Name: maternalcohort_2024W21_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W21_datimid_period_end_date_idx" ON public."maternalcohort_2024W21" USING btree (datimid, period_end_date);


--
-- Name: maternalcohort_2024W21_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W21_period_idx" ON public."maternalcohort_2024W21" USING btree (period);


--
-- Name: maternalcohort_2024W21_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W21_period_start_date_period_end_date_idx" ON public."maternalcohort_2024W21" USING btree (period_start_date, period_end_date);


--
-- Name: maternalcohort_2024W22_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W22_Datim ID_idx" ON public."maternalcohort_2024W22" USING btree (datimid);


--
-- Name: maternalcohort_2024W22_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W22_datimid_period_end_date_idx" ON public."maternalcohort_2024W22" USING btree (datimid, period_end_date);


--
-- Name: maternalcohort_2024W22_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W22_period_idx" ON public."maternalcohort_2024W22" USING btree (period);


--
-- Name: maternalcohort_2024W22_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W22_period_start_date_period_end_date_idx" ON public."maternalcohort_2024W22" USING btree (period_start_date, period_end_date);


--
-- Name: maternalcohort_2024W23_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W23_Datim ID_idx" ON public."maternalcohort_2024W23" USING btree (datimid);


--
-- Name: maternalcohort_2024W23_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W23_datimid_period_end_date_idx" ON public."maternalcohort_2024W23" USING btree (datimid, period_end_date);


--
-- Name: maternalcohort_2024W23_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W23_period_idx" ON public."maternalcohort_2024W23" USING btree (period);


--
-- Name: maternalcohort_2024W23_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W23_period_start_date_period_end_date_idx" ON public."maternalcohort_2024W23" USING btree (period_start_date, period_end_date);


--
-- Name: maternalcohort_2024W24_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W24_Datim ID_idx" ON public."maternalcohort_2024W24" USING btree (datimid);


--
-- Name: maternalcohort_2024W24_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W24_datimid_period_end_date_idx" ON public."maternalcohort_2024W24" USING btree (datimid, period_end_date);


--
-- Name: maternalcohort_2024W24_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W24_period_idx" ON public."maternalcohort_2024W24" USING btree (period);


--
-- Name: maternalcohort_2024W24_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W24_period_start_date_period_end_date_idx" ON public."maternalcohort_2024W24" USING btree (period_start_date, period_end_date);


--
-- Name: maternalcohort_2024W25_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W25_Datim ID_idx" ON public."maternalcohort_2024W25" USING btree (datimid);


--
-- Name: maternalcohort_2024W25_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W25_datimid_period_end_date_idx" ON public."maternalcohort_2024W25" USING btree (datimid, period_end_date);


--
-- Name: maternalcohort_2024W25_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W25_period_idx" ON public."maternalcohort_2024W25" USING btree (period);


--
-- Name: maternalcohort_2024W25_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W25_period_start_date_period_end_date_idx" ON public."maternalcohort_2024W25" USING btree (period_start_date, period_end_date);


--
-- Name: maternalcohort_2024W26_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W26_Datim ID_idx" ON public."maternalcohort_2024W26" USING btree (datimid);


--
-- Name: maternalcohort_2024W26_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W26_datimid_period_end_date_idx" ON public."maternalcohort_2024W26" USING btree (datimid, period_end_date);


--
-- Name: maternalcohort_2024W26_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W26_period_idx" ON public."maternalcohort_2024W26" USING btree (period);


--
-- Name: maternalcohort_2024W26_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W26_period_start_date_period_end_date_idx" ON public."maternalcohort_2024W26" USING btree (period_start_date, period_end_date);


--
-- Name: maternalcohort_2024W27_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W27_Datim ID_idx" ON public."maternalcohort_2024W27" USING btree (datimid);


--
-- Name: maternalcohort_2024W27_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W27_datimid_period_end_date_idx" ON public."maternalcohort_2024W27" USING btree (datimid, period_end_date);


--
-- Name: maternalcohort_2024W27_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W27_period_idx" ON public."maternalcohort_2024W27" USING btree (period);


--
-- Name: maternalcohort_2024W27_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W27_period_start_date_period_end_date_idx" ON public."maternalcohort_2024W27" USING btree (period_start_date, period_end_date);


--
-- Name: maternalcohort_2024W28_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W28_Datim ID_idx" ON public."maternalcohort_2024W28" USING btree (datimid);


--
-- Name: maternalcohort_2024W28_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W28_datimid_period_end_date_idx" ON public."maternalcohort_2024W28" USING btree (datimid, period_end_date);


--
-- Name: maternalcohort_2024W28_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W28_period_idx" ON public."maternalcohort_2024W28" USING btree (period);


--
-- Name: maternalcohort_2024W28_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W28_period_start_date_period_end_date_idx" ON public."maternalcohort_2024W28" USING btree (period_start_date, period_end_date);


--
-- Name: maternalcohort_2024W29_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W29_Datim ID_idx" ON public."maternalcohort_2024W29" USING btree (datimid);


--
-- Name: maternalcohort_2024W29_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W29_datimid_period_end_date_idx" ON public."maternalcohort_2024W29" USING btree (datimid, period_end_date);


--
-- Name: maternalcohort_2024W29_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W29_period_idx" ON public."maternalcohort_2024W29" USING btree (period);


--
-- Name: maternalcohort_2024W29_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W29_period_start_date_period_end_date_idx" ON public."maternalcohort_2024W29" USING btree (period_start_date, period_end_date);


--
-- Name: maternalcohort_2024W2_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W2_Datim ID_idx" ON public."maternalcohort_2024W2" USING btree (datimid);


--
-- Name: maternalcohort_2024W2_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W2_datimid_period_end_date_idx" ON public."maternalcohort_2024W2" USING btree (datimid, period_end_date);


--
-- Name: maternalcohort_2024W2_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W2_period_idx" ON public."maternalcohort_2024W2" USING btree (period);


--
-- Name: maternalcohort_2024W2_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W2_period_start_date_period_end_date_idx" ON public."maternalcohort_2024W2" USING btree (period_start_date, period_end_date);


--
-- Name: maternalcohort_2024W30_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W30_Datim ID_idx" ON public."maternalcohort_2024W30" USING btree (datimid);


--
-- Name: maternalcohort_2024W30_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W30_datimid_period_end_date_idx" ON public."maternalcohort_2024W30" USING btree (datimid, period_end_date);


--
-- Name: maternalcohort_2024W30_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W30_period_idx" ON public."maternalcohort_2024W30" USING btree (period);


--
-- Name: maternalcohort_2024W30_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W30_period_start_date_period_end_date_idx" ON public."maternalcohort_2024W30" USING btree (period_start_date, period_end_date);


--
-- Name: maternalcohort_2024W31_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W31_Datim ID_idx" ON public."maternalcohort_2024W31" USING btree (datimid);


--
-- Name: maternalcohort_2024W31_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W31_datimid_period_end_date_idx" ON public."maternalcohort_2024W31" USING btree (datimid, period_end_date);


--
-- Name: maternalcohort_2024W31_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W31_period_idx" ON public."maternalcohort_2024W31" USING btree (period);


--
-- Name: maternalcohort_2024W31_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W31_period_start_date_period_end_date_idx" ON public."maternalcohort_2024W31" USING btree (period_start_date, period_end_date);


--
-- Name: maternalcohort_2024W32_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W32_Datim ID_idx" ON public."maternalcohort_2024W32" USING btree (datimid);


--
-- Name: maternalcohort_2024W32_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W32_datimid_period_end_date_idx" ON public."maternalcohort_2024W32" USING btree (datimid, period_end_date);


--
-- Name: maternalcohort_2024W32_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W32_period_idx" ON public."maternalcohort_2024W32" USING btree (period);


--
-- Name: maternalcohort_2024W32_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W32_period_start_date_period_end_date_idx" ON public."maternalcohort_2024W32" USING btree (period_start_date, period_end_date);


--
-- Name: maternalcohort_2024W33_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W33_Datim ID_idx" ON public."maternalcohort_2024W33" USING btree (datimid);


--
-- Name: maternalcohort_2024W33_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W33_datimid_period_end_date_idx" ON public."maternalcohort_2024W33" USING btree (datimid, period_end_date);


--
-- Name: maternalcohort_2024W33_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W33_period_idx" ON public."maternalcohort_2024W33" USING btree (period);


--
-- Name: maternalcohort_2024W33_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W33_period_start_date_period_end_date_idx" ON public."maternalcohort_2024W33" USING btree (period_start_date, period_end_date);


--
-- Name: maternalcohort_2024W34_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W34_Datim ID_idx" ON public."maternalcohort_2024W34" USING btree (datimid);


--
-- Name: maternalcohort_2024W34_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W34_datimid_period_end_date_idx" ON public."maternalcohort_2024W34" USING btree (datimid, period_end_date);


--
-- Name: maternalcohort_2024W34_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W34_period_idx" ON public."maternalcohort_2024W34" USING btree (period);


--
-- Name: maternalcohort_2024W34_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W34_period_start_date_period_end_date_idx" ON public."maternalcohort_2024W34" USING btree (period_start_date, period_end_date);


--
-- Name: maternalcohort_2024W35_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W35_Datim ID_idx" ON public."maternalcohort_2024W35" USING btree (datimid);


--
-- Name: maternalcohort_2024W35_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W35_datimid_period_end_date_idx" ON public."maternalcohort_2024W35" USING btree (datimid, period_end_date);


--
-- Name: maternalcohort_2024W35_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W35_period_idx" ON public."maternalcohort_2024W35" USING btree (period);


--
-- Name: maternalcohort_2024W35_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W35_period_start_date_period_end_date_idx" ON public."maternalcohort_2024W35" USING btree (period_start_date, period_end_date);


--
-- Name: maternalcohort_2024W36_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W36_Datim ID_idx" ON public."maternalcohort_2024W36" USING btree (datimid);


--
-- Name: maternalcohort_2024W36_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W36_datimid_period_end_date_idx" ON public."maternalcohort_2024W36" USING btree (datimid, period_end_date);


--
-- Name: maternalcohort_2024W36_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W36_period_idx" ON public."maternalcohort_2024W36" USING btree (period);


--
-- Name: maternalcohort_2024W36_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W36_period_start_date_period_end_date_idx" ON public."maternalcohort_2024W36" USING btree (period_start_date, period_end_date);


--
-- Name: maternalcohort_2024W37_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W37_Datim ID_idx" ON public."maternalcohort_2024W37" USING btree (datimid);


--
-- Name: maternalcohort_2024W37_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W37_datimid_period_end_date_idx" ON public."maternalcohort_2024W37" USING btree (datimid, period_end_date);


--
-- Name: maternalcohort_2024W37_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W37_period_idx" ON public."maternalcohort_2024W37" USING btree (period);


--
-- Name: maternalcohort_2024W37_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W37_period_start_date_period_end_date_idx" ON public."maternalcohort_2024W37" USING btree (period_start_date, period_end_date);


--
-- Name: maternalcohort_2024W38_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W38_Datim ID_idx" ON public."maternalcohort_2024W38" USING btree (datimid);


--
-- Name: maternalcohort_2024W38_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W38_datimid_period_end_date_idx" ON public."maternalcohort_2024W38" USING btree (datimid, period_end_date);


--
-- Name: maternalcohort_2024W38_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W38_period_idx" ON public."maternalcohort_2024W38" USING btree (period);


--
-- Name: maternalcohort_2024W38_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W38_period_start_date_period_end_date_idx" ON public."maternalcohort_2024W38" USING btree (period_start_date, period_end_date);


--
-- Name: maternalcohort_2024W39_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W39_Datim ID_idx" ON public."maternalcohort_2024W39" USING btree (datimid);


--
-- Name: maternalcohort_2024W39_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W39_datimid_period_end_date_idx" ON public."maternalcohort_2024W39" USING btree (datimid, period_end_date);


--
-- Name: maternalcohort_2024W39_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W39_period_idx" ON public."maternalcohort_2024W39" USING btree (period);


--
-- Name: maternalcohort_2024W39_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W39_period_start_date_period_end_date_idx" ON public."maternalcohort_2024W39" USING btree (period_start_date, period_end_date);


--
-- Name: maternalcohort_2024W3_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W3_Datim ID_idx" ON public."maternalcohort_2024W3" USING btree (datimid);


--
-- Name: maternalcohort_2024W3_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W3_datimid_period_end_date_idx" ON public."maternalcohort_2024W3" USING btree (datimid, period_end_date);


--
-- Name: maternalcohort_2024W3_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W3_period_idx" ON public."maternalcohort_2024W3" USING btree (period);


--
-- Name: maternalcohort_2024W3_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W3_period_start_date_period_end_date_idx" ON public."maternalcohort_2024W3" USING btree (period_start_date, period_end_date);


--
-- Name: maternalcohort_2024W40_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W40_Datim ID_idx" ON public."maternalcohort_2024W40" USING btree (datimid);


--
-- Name: maternalcohort_2024W40_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W40_datimid_period_end_date_idx" ON public."maternalcohort_2024W40" USING btree (datimid, period_end_date);


--
-- Name: maternalcohort_2024W40_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W40_period_idx" ON public."maternalcohort_2024W40" USING btree (period);


--
-- Name: maternalcohort_2024W40_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W40_period_start_date_period_end_date_idx" ON public."maternalcohort_2024W40" USING btree (period_start_date, period_end_date);


--
-- Name: maternalcohort_2024W41_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W41_Datim ID_idx" ON public."maternalcohort_2024W41" USING btree (datimid);


--
-- Name: maternalcohort_2024W41_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W41_datimid_period_end_date_idx" ON public."maternalcohort_2024W41" USING btree (datimid, period_end_date);


--
-- Name: maternalcohort_2024W41_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W41_period_idx" ON public."maternalcohort_2024W41" USING btree (period);


--
-- Name: maternalcohort_2024W41_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W41_period_start_date_period_end_date_idx" ON public."maternalcohort_2024W41" USING btree (period_start_date, period_end_date);


--
-- Name: maternalcohort_2024W42_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W42_Datim ID_idx" ON public."maternalcohort_2024W42" USING btree (datimid);


--
-- Name: maternalcohort_2024W42_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W42_datimid_period_end_date_idx" ON public."maternalcohort_2024W42" USING btree (datimid, period_end_date);


--
-- Name: maternalcohort_2024W42_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W42_period_idx" ON public."maternalcohort_2024W42" USING btree (period);


--
-- Name: maternalcohort_2024W42_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W42_period_start_date_period_end_date_idx" ON public."maternalcohort_2024W42" USING btree (period_start_date, period_end_date);


--
-- Name: maternalcohort_2024W43_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W43_Datim ID_idx" ON public."maternalcohort_2024W43" USING btree (datimid);


--
-- Name: maternalcohort_2024W43_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W43_datimid_period_end_date_idx" ON public."maternalcohort_2024W43" USING btree (datimid, period_end_date);


--
-- Name: maternalcohort_2024W43_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W43_period_idx" ON public."maternalcohort_2024W43" USING btree (period);


--
-- Name: maternalcohort_2024W43_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W43_period_start_date_period_end_date_idx" ON public."maternalcohort_2024W43" USING btree (period_start_date, period_end_date);


--
-- Name: maternalcohort_2024W44_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W44_Datim ID_idx" ON public."maternalcohort_2024W44" USING btree (datimid);


--
-- Name: maternalcohort_2024W44_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W44_datimid_period_end_date_idx" ON public."maternalcohort_2024W44" USING btree (datimid, period_end_date);


--
-- Name: maternalcohort_2024W44_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W44_period_idx" ON public."maternalcohort_2024W44" USING btree (period);


--
-- Name: maternalcohort_2024W44_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W44_period_start_date_period_end_date_idx" ON public."maternalcohort_2024W44" USING btree (period_start_date, period_end_date);


--
-- Name: maternalcohort_2024W45_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W45_Datim ID_idx" ON public."maternalcohort_2024W45" USING btree (datimid);


--
-- Name: maternalcohort_2024W45_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W45_datimid_period_end_date_idx" ON public."maternalcohort_2024W45" USING btree (datimid, period_end_date);


--
-- Name: maternalcohort_2024W45_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W45_period_idx" ON public."maternalcohort_2024W45" USING btree (period);


--
-- Name: maternalcohort_2024W45_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W45_period_start_date_period_end_date_idx" ON public."maternalcohort_2024W45" USING btree (period_start_date, period_end_date);


--
-- Name: maternalcohort_2024W46_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W46_Datim ID_idx" ON public."maternalcohort_2024W46" USING btree (datimid);


--
-- Name: maternalcohort_2024W46_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W46_datimid_period_end_date_idx" ON public."maternalcohort_2024W46" USING btree (datimid, period_end_date);


--
-- Name: maternalcohort_2024W46_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W46_period_idx" ON public."maternalcohort_2024W46" USING btree (period);


--
-- Name: maternalcohort_2024W46_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W46_period_start_date_period_end_date_idx" ON public."maternalcohort_2024W46" USING btree (period_start_date, period_end_date);


--
-- Name: maternalcohort_2024W47_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W47_Datim ID_idx" ON public."maternalcohort_2024W47" USING btree (datimid);


--
-- Name: maternalcohort_2024W47_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W47_datimid_period_end_date_idx" ON public."maternalcohort_2024W47" USING btree (datimid, period_end_date);


--
-- Name: maternalcohort_2024W47_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W47_period_idx" ON public."maternalcohort_2024W47" USING btree (period);


--
-- Name: maternalcohort_2024W47_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W47_period_start_date_period_end_date_idx" ON public."maternalcohort_2024W47" USING btree (period_start_date, period_end_date);


--
-- Name: maternalcohort_2024W48_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W48_Datim ID_idx" ON public."maternalcohort_2024W48" USING btree (datimid);


--
-- Name: maternalcohort_2024W48_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W48_datimid_period_end_date_idx" ON public."maternalcohort_2024W48" USING btree (datimid, period_end_date);


--
-- Name: maternalcohort_2024W48_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W48_period_idx" ON public."maternalcohort_2024W48" USING btree (period);


--
-- Name: maternalcohort_2024W48_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W48_period_start_date_period_end_date_idx" ON public."maternalcohort_2024W48" USING btree (period_start_date, period_end_date);


--
-- Name: maternalcohort_2024W49_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W49_Datim ID_idx" ON public."maternalcohort_2024W49" USING btree (datimid);


--
-- Name: maternalcohort_2024W49_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W49_datimid_period_end_date_idx" ON public."maternalcohort_2024W49" USING btree (datimid, period_end_date);


--
-- Name: maternalcohort_2024W49_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W49_period_idx" ON public."maternalcohort_2024W49" USING btree (period);


--
-- Name: maternalcohort_2024W49_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W49_period_start_date_period_end_date_idx" ON public."maternalcohort_2024W49" USING btree (period_start_date, period_end_date);


--
-- Name: maternalcohort_2024W4_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W4_Datim ID_idx" ON public."maternalcohort_2024W4" USING btree (datimid);


--
-- Name: maternalcohort_2024W4_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W4_datimid_period_end_date_idx" ON public."maternalcohort_2024W4" USING btree (datimid, period_end_date);


--
-- Name: maternalcohort_2024W4_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W4_period_idx" ON public."maternalcohort_2024W4" USING btree (period);


--
-- Name: maternalcohort_2024W4_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W4_period_start_date_period_end_date_idx" ON public."maternalcohort_2024W4" USING btree (period_start_date, period_end_date);


--
-- Name: maternalcohort_2024W50_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W50_Datim ID_idx" ON public."maternalcohort_2024W50" USING btree (datimid);


--
-- Name: maternalcohort_2024W50_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W50_datimid_period_end_date_idx" ON public."maternalcohort_2024W50" USING btree (datimid, period_end_date);


--
-- Name: maternalcohort_2024W50_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W50_period_idx" ON public."maternalcohort_2024W50" USING btree (period);


--
-- Name: maternalcohort_2024W50_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W50_period_start_date_period_end_date_idx" ON public."maternalcohort_2024W50" USING btree (period_start_date, period_end_date);


--
-- Name: maternalcohort_2024W51_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W51_Datim ID_idx" ON public."maternalcohort_2024W51" USING btree (datimid);


--
-- Name: maternalcohort_2024W51_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W51_datimid_period_end_date_idx" ON public."maternalcohort_2024W51" USING btree (datimid, period_end_date);


--
-- Name: maternalcohort_2024W51_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W51_period_idx" ON public."maternalcohort_2024W51" USING btree (period);


--
-- Name: maternalcohort_2024W51_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W51_period_start_date_period_end_date_idx" ON public."maternalcohort_2024W51" USING btree (period_start_date, period_end_date);


--
-- Name: maternalcohort_2024W52_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W52_Datim ID_idx" ON public."maternalcohort_2024W52" USING btree (datimid);


--
-- Name: maternalcohort_2024W52_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W52_datimid_period_end_date_idx" ON public."maternalcohort_2024W52" USING btree (datimid, period_end_date);


--
-- Name: maternalcohort_2024W52_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W52_period_idx" ON public."maternalcohort_2024W52" USING btree (period);


--
-- Name: maternalcohort_2024W52_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W52_period_start_date_period_end_date_idx" ON public."maternalcohort_2024W52" USING btree (period_start_date, period_end_date);


--
-- Name: maternalcohort_2024W5_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W5_Datim ID_idx" ON public."maternalcohort_2024W5" USING btree (datimid);


--
-- Name: maternalcohort_2024W5_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W5_datimid_period_end_date_idx" ON public."maternalcohort_2024W5" USING btree (datimid, period_end_date);


--
-- Name: maternalcohort_2024W5_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W5_period_idx" ON public."maternalcohort_2024W5" USING btree (period);


--
-- Name: maternalcohort_2024W5_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W5_period_start_date_period_end_date_idx" ON public."maternalcohort_2024W5" USING btree (period_start_date, period_end_date);


--
-- Name: maternalcohort_2024W6_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W6_Datim ID_idx" ON public."maternalcohort_2024W6" USING btree (datimid);


--
-- Name: maternalcohort_2024W6_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W6_datimid_period_end_date_idx" ON public."maternalcohort_2024W6" USING btree (datimid, period_end_date);


--
-- Name: maternalcohort_2024W6_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W6_period_idx" ON public."maternalcohort_2024W6" USING btree (period);


--
-- Name: maternalcohort_2024W6_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W6_period_start_date_period_end_date_idx" ON public."maternalcohort_2024W6" USING btree (period_start_date, period_end_date);


--
-- Name: maternalcohort_2024W7_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W7_Datim ID_idx" ON public."maternalcohort_2024W7" USING btree (datimid);


--
-- Name: maternalcohort_2024W7_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W7_datimid_period_end_date_idx" ON public."maternalcohort_2024W7" USING btree (datimid, period_end_date);


--
-- Name: maternalcohort_2024W7_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W7_period_idx" ON public."maternalcohort_2024W7" USING btree (period);


--
-- Name: maternalcohort_2024W7_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W7_period_start_date_period_end_date_idx" ON public."maternalcohort_2024W7" USING btree (period_start_date, period_end_date);


--
-- Name: maternalcohort_2024W8_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W8_Datim ID_idx" ON public."maternalcohort_2024W8" USING btree (datimid);


--
-- Name: maternalcohort_2024W8_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W8_datimid_period_end_date_idx" ON public."maternalcohort_2024W8" USING btree (datimid, period_end_date);


--
-- Name: maternalcohort_2024W8_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W8_period_idx" ON public."maternalcohort_2024W8" USING btree (period);


--
-- Name: maternalcohort_2024W8_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W8_period_start_date_period_end_date_idx" ON public."maternalcohort_2024W8" USING btree (period_start_date, period_end_date);


--
-- Name: maternalcohort_2024W9_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W9_Datim ID_idx" ON public."maternalcohort_2024W9" USING btree (datimid);


--
-- Name: maternalcohort_2024W9_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W9_datimid_period_end_date_idx" ON public."maternalcohort_2024W9" USING btree (datimid, period_end_date);


--
-- Name: maternalcohort_2024W9_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W9_period_idx" ON public."maternalcohort_2024W9" USING btree (period);


--
-- Name: maternalcohort_2024W9_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "maternalcohort_2024W9_period_start_date_period_end_date_idx" ON public."maternalcohort_2024W9" USING btree (period_start_date, period_end_date);


--
-- Name: pmtcthts_2024Q3_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024Q3_Datim ID_idx" ON public."pmtcthts_2024Q3" USING btree (datimid);


--
-- Name: pmtcthts_2024Q3_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024Q3_datimid_period_end_date_idx" ON public."pmtcthts_2024Q3" USING btree (datimid, period_end_date);


--
-- Name: pmtcthts_2024Q3_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024Q3_period_idx" ON public."pmtcthts_2024Q3" USING btree (period);


--
-- Name: pmtcthts_2024Q3_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024Q3_period_start_date_period_end_date_idx" ON public."pmtcthts_2024Q3" USING btree (period_start_date, period_end_date);


--
-- Name: pmtcthts_2024Q4_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024Q4_Datim ID_idx" ON public."pmtcthts_2024Q4" USING btree (datimid);


--
-- Name: pmtcthts_2024Q4_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024Q4_datimid_period_end_date_idx" ON public."pmtcthts_2024Q4" USING btree (datimid, period_end_date);


--
-- Name: pmtcthts_2024Q4_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024Q4_period_idx" ON public."pmtcthts_2024Q4" USING btree (period);


--
-- Name: pmtcthts_2024Q4_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024Q4_period_start_date_period_end_date_idx" ON public."pmtcthts_2024Q4" USING btree (period_start_date, period_end_date);


--
-- Name: pmtcthts_2024W10_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W10_Datim ID_idx" ON public."pmtcthts_2024W10" USING btree (datimid);


--
-- Name: pmtcthts_2024W10_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W10_datimid_period_end_date_idx" ON public."pmtcthts_2024W10" USING btree (datimid, period_end_date);


--
-- Name: pmtcthts_2024W10_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W10_period_idx" ON public."pmtcthts_2024W10" USING btree (period);


--
-- Name: pmtcthts_2024W10_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W10_period_start_date_period_end_date_idx" ON public."pmtcthts_2024W10" USING btree (period_start_date, period_end_date);


--
-- Name: pmtcthts_2024W11_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W11_Datim ID_idx" ON public."pmtcthts_2024W11" USING btree (datimid);


--
-- Name: pmtcthts_2024W11_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W11_datimid_period_end_date_idx" ON public."pmtcthts_2024W11" USING btree (datimid, period_end_date);


--
-- Name: pmtcthts_2024W11_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W11_period_idx" ON public."pmtcthts_2024W11" USING btree (period);


--
-- Name: pmtcthts_2024W11_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W11_period_start_date_period_end_date_idx" ON public."pmtcthts_2024W11" USING btree (period_start_date, period_end_date);


--
-- Name: pmtcthts_2024W12_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W12_Datim ID_idx" ON public."pmtcthts_2024W12" USING btree (datimid);


--
-- Name: pmtcthts_2024W12_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W12_datimid_period_end_date_idx" ON public."pmtcthts_2024W12" USING btree (datimid, period_end_date);


--
-- Name: pmtcthts_2024W12_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W12_period_idx" ON public."pmtcthts_2024W12" USING btree (period);


--
-- Name: pmtcthts_2024W12_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W12_period_start_date_period_end_date_idx" ON public."pmtcthts_2024W12" USING btree (period_start_date, period_end_date);


--
-- Name: pmtcthts_2024W13_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W13_Datim ID_idx" ON public."pmtcthts_2024W13" USING btree (datimid);


--
-- Name: pmtcthts_2024W13_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W13_datimid_period_end_date_idx" ON public."pmtcthts_2024W13" USING btree (datimid, period_end_date);


--
-- Name: pmtcthts_2024W13_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W13_period_idx" ON public."pmtcthts_2024W13" USING btree (period);


--
-- Name: pmtcthts_2024W13_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W13_period_start_date_period_end_date_idx" ON public."pmtcthts_2024W13" USING btree (period_start_date, period_end_date);


--
-- Name: pmtcthts_2024W14_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W14_Datim ID_idx" ON public."pmtcthts_2024W14" USING btree (datimid);


--
-- Name: pmtcthts_2024W14_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W14_datimid_period_end_date_idx" ON public."pmtcthts_2024W14" USING btree (datimid, period_end_date);


--
-- Name: pmtcthts_2024W14_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W14_period_idx" ON public."pmtcthts_2024W14" USING btree (period);


--
-- Name: pmtcthts_2024W14_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W14_period_start_date_period_end_date_idx" ON public."pmtcthts_2024W14" USING btree (period_start_date, period_end_date);


--
-- Name: pmtcthts_2024W15_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W15_Datim ID_idx" ON public."pmtcthts_2024W15" USING btree (datimid);


--
-- Name: pmtcthts_2024W15_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W15_datimid_period_end_date_idx" ON public."pmtcthts_2024W15" USING btree (datimid, period_end_date);


--
-- Name: pmtcthts_2024W15_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W15_period_idx" ON public."pmtcthts_2024W15" USING btree (period);


--
-- Name: pmtcthts_2024W15_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W15_period_start_date_period_end_date_idx" ON public."pmtcthts_2024W15" USING btree (period_start_date, period_end_date);


--
-- Name: pmtcthts_2024W16_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W16_Datim ID_idx" ON public."pmtcthts_2024W16" USING btree (datimid);


--
-- Name: pmtcthts_2024W16_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W16_datimid_period_end_date_idx" ON public."pmtcthts_2024W16" USING btree (datimid, period_end_date);


--
-- Name: pmtcthts_2024W16_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W16_period_idx" ON public."pmtcthts_2024W16" USING btree (period);


--
-- Name: pmtcthts_2024W16_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W16_period_start_date_period_end_date_idx" ON public."pmtcthts_2024W16" USING btree (period_start_date, period_end_date);


--
-- Name: pmtcthts_2024W17_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W17_Datim ID_idx" ON public."pmtcthts_2024W17" USING btree (datimid);


--
-- Name: pmtcthts_2024W17_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W17_datimid_period_end_date_idx" ON public."pmtcthts_2024W17" USING btree (datimid, period_end_date);


--
-- Name: pmtcthts_2024W17_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W17_period_idx" ON public."pmtcthts_2024W17" USING btree (period);


--
-- Name: pmtcthts_2024W17_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W17_period_start_date_period_end_date_idx" ON public."pmtcthts_2024W17" USING btree (period_start_date, period_end_date);


--
-- Name: pmtcthts_2024W18_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W18_Datim ID_idx" ON public."pmtcthts_2024W18" USING btree (datimid);


--
-- Name: pmtcthts_2024W18_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W18_datimid_period_end_date_idx" ON public."pmtcthts_2024W18" USING btree (datimid, period_end_date);


--
-- Name: pmtcthts_2024W18_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W18_period_idx" ON public."pmtcthts_2024W18" USING btree (period);


--
-- Name: pmtcthts_2024W18_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W18_period_start_date_period_end_date_idx" ON public."pmtcthts_2024W18" USING btree (period_start_date, period_end_date);


--
-- Name: pmtcthts_2024W19_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W19_Datim ID_idx" ON public."pmtcthts_2024W19" USING btree (datimid);


--
-- Name: pmtcthts_2024W19_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W19_datimid_period_end_date_idx" ON public."pmtcthts_2024W19" USING btree (datimid, period_end_date);


--
-- Name: pmtcthts_2024W19_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W19_period_idx" ON public."pmtcthts_2024W19" USING btree (period);


--
-- Name: pmtcthts_2024W19_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W19_period_start_date_period_end_date_idx" ON public."pmtcthts_2024W19" USING btree (period_start_date, period_end_date);


--
-- Name: pmtcthts_2024W20_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W20_Datim ID_idx" ON public."pmtcthts_2024W20" USING btree (datimid);


--
-- Name: pmtcthts_2024W20_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W20_datimid_period_end_date_idx" ON public."pmtcthts_2024W20" USING btree (datimid, period_end_date);


--
-- Name: pmtcthts_2024W20_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W20_period_idx" ON public."pmtcthts_2024W20" USING btree (period);


--
-- Name: pmtcthts_2024W20_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W20_period_start_date_period_end_date_idx" ON public."pmtcthts_2024W20" USING btree (period_start_date, period_end_date);


--
-- Name: pmtcthts_2024W21_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W21_Datim ID_idx" ON public."pmtcthts_2024W21" USING btree (datimid);


--
-- Name: pmtcthts_2024W21_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W21_datimid_period_end_date_idx" ON public."pmtcthts_2024W21" USING btree (datimid, period_end_date);


--
-- Name: pmtcthts_2024W21_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W21_period_idx" ON public."pmtcthts_2024W21" USING btree (period);


--
-- Name: pmtcthts_2024W21_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W21_period_start_date_period_end_date_idx" ON public."pmtcthts_2024W21" USING btree (period_start_date, period_end_date);


--
-- Name: pmtcthts_2024W22_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W22_Datim ID_idx" ON public."pmtcthts_2024W22" USING btree (datimid);


--
-- Name: pmtcthts_2024W22_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W22_datimid_period_end_date_idx" ON public."pmtcthts_2024W22" USING btree (datimid, period_end_date);


--
-- Name: pmtcthts_2024W22_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W22_period_idx" ON public."pmtcthts_2024W22" USING btree (period);


--
-- Name: pmtcthts_2024W22_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W22_period_start_date_period_end_date_idx" ON public."pmtcthts_2024W22" USING btree (period_start_date, period_end_date);


--
-- Name: pmtcthts_2024W23_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W23_Datim ID_idx" ON public."pmtcthts_2024W23" USING btree (datimid);


--
-- Name: pmtcthts_2024W23_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W23_datimid_period_end_date_idx" ON public."pmtcthts_2024W23" USING btree (datimid, period_end_date);


--
-- Name: pmtcthts_2024W23_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W23_period_idx" ON public."pmtcthts_2024W23" USING btree (period);


--
-- Name: pmtcthts_2024W23_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W23_period_start_date_period_end_date_idx" ON public."pmtcthts_2024W23" USING btree (period_start_date, period_end_date);


--
-- Name: pmtcthts_2024W24_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W24_Datim ID_idx" ON public."pmtcthts_2024W24" USING btree (datimid);


--
-- Name: pmtcthts_2024W24_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W24_datimid_period_end_date_idx" ON public."pmtcthts_2024W24" USING btree (datimid, period_end_date);


--
-- Name: pmtcthts_2024W24_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W24_period_idx" ON public."pmtcthts_2024W24" USING btree (period);


--
-- Name: pmtcthts_2024W24_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W24_period_start_date_period_end_date_idx" ON public."pmtcthts_2024W24" USING btree (period_start_date, period_end_date);


--
-- Name: pmtcthts_2024W25_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W25_Datim ID_idx" ON public."pmtcthts_2024W25" USING btree (datimid);


--
-- Name: pmtcthts_2024W25_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W25_datimid_period_end_date_idx" ON public."pmtcthts_2024W25" USING btree (datimid, period_end_date);


--
-- Name: pmtcthts_2024W25_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W25_period_idx" ON public."pmtcthts_2024W25" USING btree (period);


--
-- Name: pmtcthts_2024W25_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W25_period_start_date_period_end_date_idx" ON public."pmtcthts_2024W25" USING btree (period_start_date, period_end_date);


--
-- Name: pmtcthts_2024W26_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W26_Datim ID_idx" ON public."pmtcthts_2024W26" USING btree (datimid);


--
-- Name: pmtcthts_2024W26_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W26_datimid_period_end_date_idx" ON public."pmtcthts_2024W26" USING btree (datimid, period_end_date);


--
-- Name: pmtcthts_2024W26_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W26_period_idx" ON public."pmtcthts_2024W26" USING btree (period);


--
-- Name: pmtcthts_2024W26_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W26_period_start_date_period_end_date_idx" ON public."pmtcthts_2024W26" USING btree (period_start_date, period_end_date);


--
-- Name: pmtcthts_2024W27_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W27_Datim ID_idx" ON public."pmtcthts_2024W27" USING btree (datimid);


--
-- Name: pmtcthts_2024W27_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W27_datimid_period_end_date_idx" ON public."pmtcthts_2024W27" USING btree (datimid, period_end_date);


--
-- Name: pmtcthts_2024W27_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W27_period_idx" ON public."pmtcthts_2024W27" USING btree (period);


--
-- Name: pmtcthts_2024W27_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W27_period_start_date_period_end_date_idx" ON public."pmtcthts_2024W27" USING btree (period_start_date, period_end_date);


--
-- Name: pmtcthts_2024W28_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W28_Datim ID_idx" ON public."pmtcthts_2024W28" USING btree (datimid);


--
-- Name: pmtcthts_2024W28_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W28_datimid_period_end_date_idx" ON public."pmtcthts_2024W28" USING btree (datimid, period_end_date);


--
-- Name: pmtcthts_2024W28_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W28_period_idx" ON public."pmtcthts_2024W28" USING btree (period);


--
-- Name: pmtcthts_2024W28_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W28_period_start_date_period_end_date_idx" ON public."pmtcthts_2024W28" USING btree (period_start_date, period_end_date);


--
-- Name: pmtcthts_2024W29_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W29_Datim ID_idx" ON public."pmtcthts_2024W29" USING btree (datimid);


--
-- Name: pmtcthts_2024W29_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W29_datimid_period_end_date_idx" ON public."pmtcthts_2024W29" USING btree (datimid, period_end_date);


--
-- Name: pmtcthts_2024W29_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W29_period_idx" ON public."pmtcthts_2024W29" USING btree (period);


--
-- Name: pmtcthts_2024W29_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W29_period_start_date_period_end_date_idx" ON public."pmtcthts_2024W29" USING btree (period_start_date, period_end_date);


--
-- Name: pmtcthts_2024W2_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W2_Datim ID_idx" ON public."pmtcthts_2024W2" USING btree (datimid);


--
-- Name: pmtcthts_2024W2_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W2_datimid_period_end_date_idx" ON public."pmtcthts_2024W2" USING btree (datimid, period_end_date);


--
-- Name: pmtcthts_2024W2_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W2_period_idx" ON public."pmtcthts_2024W2" USING btree (period);


--
-- Name: pmtcthts_2024W2_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W2_period_start_date_period_end_date_idx" ON public."pmtcthts_2024W2" USING btree (period_start_date, period_end_date);


--
-- Name: pmtcthts_2024W30_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W30_Datim ID_idx" ON public."pmtcthts_2024W30" USING btree (datimid);


--
-- Name: pmtcthts_2024W30_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W30_datimid_period_end_date_idx" ON public."pmtcthts_2024W30" USING btree (datimid, period_end_date);


--
-- Name: pmtcthts_2024W30_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W30_period_idx" ON public."pmtcthts_2024W30" USING btree (period);


--
-- Name: pmtcthts_2024W30_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W30_period_start_date_period_end_date_idx" ON public."pmtcthts_2024W30" USING btree (period_start_date, period_end_date);


--
-- Name: pmtcthts_2024W31_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W31_Datim ID_idx" ON public."pmtcthts_2024W31" USING btree (datimid);


--
-- Name: pmtcthts_2024W31_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W31_datimid_period_end_date_idx" ON public."pmtcthts_2024W31" USING btree (datimid, period_end_date);


--
-- Name: pmtcthts_2024W31_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W31_period_idx" ON public."pmtcthts_2024W31" USING btree (period);


--
-- Name: pmtcthts_2024W31_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W31_period_start_date_period_end_date_idx" ON public."pmtcthts_2024W31" USING btree (period_start_date, period_end_date);


--
-- Name: pmtcthts_2024W32_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W32_Datim ID_idx" ON public."pmtcthts_2024W32" USING btree (datimid);


--
-- Name: pmtcthts_2024W32_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W32_datimid_period_end_date_idx" ON public."pmtcthts_2024W32" USING btree (datimid, period_end_date);


--
-- Name: pmtcthts_2024W32_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W32_period_idx" ON public."pmtcthts_2024W32" USING btree (period);


--
-- Name: pmtcthts_2024W32_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W32_period_start_date_period_end_date_idx" ON public."pmtcthts_2024W32" USING btree (period_start_date, period_end_date);


--
-- Name: pmtcthts_2024W33_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W33_Datim ID_idx" ON public."pmtcthts_2024W33" USING btree (datimid);


--
-- Name: pmtcthts_2024W33_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W33_datimid_period_end_date_idx" ON public."pmtcthts_2024W33" USING btree (datimid, period_end_date);


--
-- Name: pmtcthts_2024W33_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W33_period_idx" ON public."pmtcthts_2024W33" USING btree (period);


--
-- Name: pmtcthts_2024W33_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W33_period_start_date_period_end_date_idx" ON public."pmtcthts_2024W33" USING btree (period_start_date, period_end_date);


--
-- Name: pmtcthts_2024W34_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W34_Datim ID_idx" ON public."pmtcthts_2024W34" USING btree (datimid);


--
-- Name: pmtcthts_2024W34_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W34_datimid_period_end_date_idx" ON public."pmtcthts_2024W34" USING btree (datimid, period_end_date);


--
-- Name: pmtcthts_2024W34_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W34_period_idx" ON public."pmtcthts_2024W34" USING btree (period);


--
-- Name: pmtcthts_2024W34_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W34_period_start_date_period_end_date_idx" ON public."pmtcthts_2024W34" USING btree (period_start_date, period_end_date);


--
-- Name: pmtcthts_2024W35_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W35_Datim ID_idx" ON public."pmtcthts_2024W35" USING btree (datimid);


--
-- Name: pmtcthts_2024W35_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W35_datimid_period_end_date_idx" ON public."pmtcthts_2024W35" USING btree (datimid, period_end_date);


--
-- Name: pmtcthts_2024W35_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W35_period_idx" ON public."pmtcthts_2024W35" USING btree (period);


--
-- Name: pmtcthts_2024W35_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W35_period_start_date_period_end_date_idx" ON public."pmtcthts_2024W35" USING btree (period_start_date, period_end_date);


--
-- Name: pmtcthts_2024W36_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W36_Datim ID_idx" ON public."pmtcthts_2024W36" USING btree (datimid);


--
-- Name: pmtcthts_2024W36_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W36_datimid_period_end_date_idx" ON public."pmtcthts_2024W36" USING btree (datimid, period_end_date);


--
-- Name: pmtcthts_2024W36_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W36_period_idx" ON public."pmtcthts_2024W36" USING btree (period);


--
-- Name: pmtcthts_2024W36_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W36_period_start_date_period_end_date_idx" ON public."pmtcthts_2024W36" USING btree (period_start_date, period_end_date);


--
-- Name: pmtcthts_2024W37_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W37_Datim ID_idx" ON public."pmtcthts_2024W37" USING btree (datimid);


--
-- Name: pmtcthts_2024W37_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W37_datimid_period_end_date_idx" ON public."pmtcthts_2024W37" USING btree (datimid, period_end_date);


--
-- Name: pmtcthts_2024W37_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W37_period_idx" ON public."pmtcthts_2024W37" USING btree (period);


--
-- Name: pmtcthts_2024W37_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W37_period_start_date_period_end_date_idx" ON public."pmtcthts_2024W37" USING btree (period_start_date, period_end_date);


--
-- Name: pmtcthts_2024W38_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W38_Datim ID_idx" ON public."pmtcthts_2024W38" USING btree (datimid);


--
-- Name: pmtcthts_2024W38_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W38_datimid_period_end_date_idx" ON public."pmtcthts_2024W38" USING btree (datimid, period_end_date);


--
-- Name: pmtcthts_2024W38_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W38_period_idx" ON public."pmtcthts_2024W38" USING btree (period);


--
-- Name: pmtcthts_2024W38_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W38_period_start_date_period_end_date_idx" ON public."pmtcthts_2024W38" USING btree (period_start_date, period_end_date);


--
-- Name: pmtcthts_2024W39_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W39_Datim ID_idx" ON public."pmtcthts_2024W39" USING btree (datimid);


--
-- Name: pmtcthts_2024W39_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W39_datimid_period_end_date_idx" ON public."pmtcthts_2024W39" USING btree (datimid, period_end_date);


--
-- Name: pmtcthts_2024W39_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W39_period_idx" ON public."pmtcthts_2024W39" USING btree (period);


--
-- Name: pmtcthts_2024W39_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W39_period_start_date_period_end_date_idx" ON public."pmtcthts_2024W39" USING btree (period_start_date, period_end_date);


--
-- Name: pmtcthts_2024W3_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W3_Datim ID_idx" ON public."pmtcthts_2024W3" USING btree (datimid);


--
-- Name: pmtcthts_2024W3_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W3_datimid_period_end_date_idx" ON public."pmtcthts_2024W3" USING btree (datimid, period_end_date);


--
-- Name: pmtcthts_2024W3_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W3_period_idx" ON public."pmtcthts_2024W3" USING btree (period);


--
-- Name: pmtcthts_2024W3_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W3_period_start_date_period_end_date_idx" ON public."pmtcthts_2024W3" USING btree (period_start_date, period_end_date);


--
-- Name: pmtcthts_2024W40_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W40_Datim ID_idx" ON public."pmtcthts_2024W40" USING btree (datimid);


--
-- Name: pmtcthts_2024W40_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W40_datimid_period_end_date_idx" ON public."pmtcthts_2024W40" USING btree (datimid, period_end_date);


--
-- Name: pmtcthts_2024W40_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W40_period_idx" ON public."pmtcthts_2024W40" USING btree (period);


--
-- Name: pmtcthts_2024W40_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W40_period_start_date_period_end_date_idx" ON public."pmtcthts_2024W40" USING btree (period_start_date, period_end_date);


--
-- Name: pmtcthts_2024W41_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W41_Datim ID_idx" ON public."pmtcthts_2024W41" USING btree (datimid);


--
-- Name: pmtcthts_2024W41_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W41_datimid_period_end_date_idx" ON public."pmtcthts_2024W41" USING btree (datimid, period_end_date);


--
-- Name: pmtcthts_2024W41_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W41_period_idx" ON public."pmtcthts_2024W41" USING btree (period);


--
-- Name: pmtcthts_2024W41_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W41_period_start_date_period_end_date_idx" ON public."pmtcthts_2024W41" USING btree (period_start_date, period_end_date);


--
-- Name: pmtcthts_2024W42_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W42_Datim ID_idx" ON public."pmtcthts_2024W42" USING btree (datimid);


--
-- Name: pmtcthts_2024W42_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W42_datimid_period_end_date_idx" ON public."pmtcthts_2024W42" USING btree (datimid, period_end_date);


--
-- Name: pmtcthts_2024W42_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W42_period_idx" ON public."pmtcthts_2024W42" USING btree (period);


--
-- Name: pmtcthts_2024W42_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W42_period_start_date_period_end_date_idx" ON public."pmtcthts_2024W42" USING btree (period_start_date, period_end_date);


--
-- Name: pmtcthts_2024W43_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W43_Datim ID_idx" ON public."pmtcthts_2024W43" USING btree (datimid);


--
-- Name: pmtcthts_2024W43_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W43_datimid_period_end_date_idx" ON public."pmtcthts_2024W43" USING btree (datimid, period_end_date);


--
-- Name: pmtcthts_2024W43_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W43_period_idx" ON public."pmtcthts_2024W43" USING btree (period);


--
-- Name: pmtcthts_2024W43_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W43_period_start_date_period_end_date_idx" ON public."pmtcthts_2024W43" USING btree (period_start_date, period_end_date);


--
-- Name: pmtcthts_2024W44_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W44_Datim ID_idx" ON public."pmtcthts_2024W44" USING btree (datimid);


--
-- Name: pmtcthts_2024W44_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W44_datimid_period_end_date_idx" ON public."pmtcthts_2024W44" USING btree (datimid, period_end_date);


--
-- Name: pmtcthts_2024W44_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W44_period_idx" ON public."pmtcthts_2024W44" USING btree (period);


--
-- Name: pmtcthts_2024W44_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W44_period_start_date_period_end_date_idx" ON public."pmtcthts_2024W44" USING btree (period_start_date, period_end_date);


--
-- Name: pmtcthts_2024W45_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W45_Datim ID_idx" ON public."pmtcthts_2024W45" USING btree (datimid);


--
-- Name: pmtcthts_2024W45_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W45_datimid_period_end_date_idx" ON public."pmtcthts_2024W45" USING btree (datimid, period_end_date);


--
-- Name: pmtcthts_2024W45_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W45_period_idx" ON public."pmtcthts_2024W45" USING btree (period);


--
-- Name: pmtcthts_2024W45_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W45_period_start_date_period_end_date_idx" ON public."pmtcthts_2024W45" USING btree (period_start_date, period_end_date);


--
-- Name: pmtcthts_2024W46_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W46_Datim ID_idx" ON public."pmtcthts_2024W46" USING btree (datimid);


--
-- Name: pmtcthts_2024W46_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W46_datimid_period_end_date_idx" ON public."pmtcthts_2024W46" USING btree (datimid, period_end_date);


--
-- Name: pmtcthts_2024W46_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W46_period_idx" ON public."pmtcthts_2024W46" USING btree (period);


--
-- Name: pmtcthts_2024W46_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W46_period_start_date_period_end_date_idx" ON public."pmtcthts_2024W46" USING btree (period_start_date, period_end_date);


--
-- Name: pmtcthts_2024W47_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W47_Datim ID_idx" ON public."pmtcthts_2024W47" USING btree (datimid);


--
-- Name: pmtcthts_2024W47_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W47_datimid_period_end_date_idx" ON public."pmtcthts_2024W47" USING btree (datimid, period_end_date);


--
-- Name: pmtcthts_2024W47_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W47_period_idx" ON public."pmtcthts_2024W47" USING btree (period);


--
-- Name: pmtcthts_2024W47_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W47_period_start_date_period_end_date_idx" ON public."pmtcthts_2024W47" USING btree (period_start_date, period_end_date);


--
-- Name: pmtcthts_2024W48_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W48_Datim ID_idx" ON public."pmtcthts_2024W48" USING btree (datimid);


--
-- Name: pmtcthts_2024W48_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W48_datimid_period_end_date_idx" ON public."pmtcthts_2024W48" USING btree (datimid, period_end_date);


--
-- Name: pmtcthts_2024W48_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W48_period_idx" ON public."pmtcthts_2024W48" USING btree (period);


--
-- Name: pmtcthts_2024W48_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W48_period_start_date_period_end_date_idx" ON public."pmtcthts_2024W48" USING btree (period_start_date, period_end_date);


--
-- Name: pmtcthts_2024W49_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W49_Datim ID_idx" ON public."pmtcthts_2024W49" USING btree (datimid);


--
-- Name: pmtcthts_2024W49_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W49_datimid_period_end_date_idx" ON public."pmtcthts_2024W49" USING btree (datimid, period_end_date);


--
-- Name: pmtcthts_2024W49_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W49_period_idx" ON public."pmtcthts_2024W49" USING btree (period);


--
-- Name: pmtcthts_2024W49_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W49_period_start_date_period_end_date_idx" ON public."pmtcthts_2024W49" USING btree (period_start_date, period_end_date);


--
-- Name: pmtcthts_2024W4_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W4_Datim ID_idx" ON public."pmtcthts_2024W4" USING btree (datimid);


--
-- Name: pmtcthts_2024W4_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W4_datimid_period_end_date_idx" ON public."pmtcthts_2024W4" USING btree (datimid, period_end_date);


--
-- Name: pmtcthts_2024W4_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W4_period_idx" ON public."pmtcthts_2024W4" USING btree (period);


--
-- Name: pmtcthts_2024W4_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W4_period_start_date_period_end_date_idx" ON public."pmtcthts_2024W4" USING btree (period_start_date, period_end_date);


--
-- Name: pmtcthts_2024W50_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W50_Datim ID_idx" ON public."pmtcthts_2024W50" USING btree (datimid);


--
-- Name: pmtcthts_2024W50_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W50_datimid_period_end_date_idx" ON public."pmtcthts_2024W50" USING btree (datimid, period_end_date);


--
-- Name: pmtcthts_2024W50_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W50_period_idx" ON public."pmtcthts_2024W50" USING btree (period);


--
-- Name: pmtcthts_2024W50_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W50_period_start_date_period_end_date_idx" ON public."pmtcthts_2024W50" USING btree (period_start_date, period_end_date);


--
-- Name: pmtcthts_2024W51_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W51_Datim ID_idx" ON public."pmtcthts_2024W51" USING btree (datimid);


--
-- Name: pmtcthts_2024W51_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W51_datimid_period_end_date_idx" ON public."pmtcthts_2024W51" USING btree (datimid, period_end_date);


--
-- Name: pmtcthts_2024W51_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W51_period_idx" ON public."pmtcthts_2024W51" USING btree (period);


--
-- Name: pmtcthts_2024W51_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W51_period_start_date_period_end_date_idx" ON public."pmtcthts_2024W51" USING btree (period_start_date, period_end_date);


--
-- Name: pmtcthts_2024W52_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W52_Datim ID_idx" ON public."pmtcthts_2024W52" USING btree (datimid);


--
-- Name: pmtcthts_2024W52_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W52_datimid_period_end_date_idx" ON public."pmtcthts_2024W52" USING btree (datimid, period_end_date);


--
-- Name: pmtcthts_2024W52_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W52_period_idx" ON public."pmtcthts_2024W52" USING btree (period);


--
-- Name: pmtcthts_2024W52_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W52_period_start_date_period_end_date_idx" ON public."pmtcthts_2024W52" USING btree (period_start_date, period_end_date);


--
-- Name: pmtcthts_2024W5_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W5_Datim ID_idx" ON public."pmtcthts_2024W5" USING btree (datimid);


--
-- Name: pmtcthts_2024W5_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W5_datimid_period_end_date_idx" ON public."pmtcthts_2024W5" USING btree (datimid, period_end_date);


--
-- Name: pmtcthts_2024W5_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W5_period_idx" ON public."pmtcthts_2024W5" USING btree (period);


--
-- Name: pmtcthts_2024W5_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W5_period_start_date_period_end_date_idx" ON public."pmtcthts_2024W5" USING btree (period_start_date, period_end_date);


--
-- Name: pmtcthts_2024W6_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W6_Datim ID_idx" ON public."pmtcthts_2024W6" USING btree (datimid);


--
-- Name: pmtcthts_2024W6_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W6_datimid_period_end_date_idx" ON public."pmtcthts_2024W6" USING btree (datimid, period_end_date);


--
-- Name: pmtcthts_2024W6_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W6_period_idx" ON public."pmtcthts_2024W6" USING btree (period);


--
-- Name: pmtcthts_2024W6_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W6_period_start_date_period_end_date_idx" ON public."pmtcthts_2024W6" USING btree (period_start_date, period_end_date);


--
-- Name: pmtcthts_2024W7_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W7_Datim ID_idx" ON public."pmtcthts_2024W7" USING btree (datimid);


--
-- Name: pmtcthts_2024W7_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W7_datimid_period_end_date_idx" ON public."pmtcthts_2024W7" USING btree (datimid, period_end_date);


--
-- Name: pmtcthts_2024W7_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W7_period_idx" ON public."pmtcthts_2024W7" USING btree (period);


--
-- Name: pmtcthts_2024W7_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W7_period_start_date_period_end_date_idx" ON public."pmtcthts_2024W7" USING btree (period_start_date, period_end_date);


--
-- Name: pmtcthts_2024W8_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W8_Datim ID_idx" ON public."pmtcthts_2024W8" USING btree (datimid);


--
-- Name: pmtcthts_2024W8_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W8_datimid_period_end_date_idx" ON public."pmtcthts_2024W8" USING btree (datimid, period_end_date);


--
-- Name: pmtcthts_2024W8_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W8_period_idx" ON public."pmtcthts_2024W8" USING btree (period);


--
-- Name: pmtcthts_2024W8_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W8_period_start_date_period_end_date_idx" ON public."pmtcthts_2024W8" USING btree (period_start_date, period_end_date);


--
-- Name: pmtcthts_2024W9_Datim ID_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W9_Datim ID_idx" ON public."pmtcthts_2024W9" USING btree (datimid);


--
-- Name: pmtcthts_2024W9_datimid_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W9_datimid_period_end_date_idx" ON public."pmtcthts_2024W9" USING btree (datimid, period_end_date);


--
-- Name: pmtcthts_2024W9_period_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W9_period_idx" ON public."pmtcthts_2024W9" USING btree (period);


--
-- Name: pmtcthts_2024W9_period_start_date_period_end_date_idx; Type: INDEX; Schema: public; Owner: lamisplus_etl
--

CREATE INDEX "pmtcthts_2024W9_period_start_date_period_end_date_idx" ON public."pmtcthts_2024W9" USING btree (period_start_date, period_end_date);


--
-- Name: aggregate_flatfile_2024Q2_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024Q2_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024Q2_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024Q2_pkey";


--
-- Name: aggregate_flatfile_2024Q3_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024Q3_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024Q3_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024Q3_pkey";


--
-- Name: aggregate_flatfile_2024Q4_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024Q4_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024Q4_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024Q4_pkey";


--
-- Name: aggregate_flatfile_2024W10_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024W10_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024W10_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024W10_pkey";


--
-- Name: aggregate_flatfile_2024W11_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024W11_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024W11_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024W11_pkey";


--
-- Name: aggregate_flatfile_2024W12_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024W12_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024W12_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024W12_pkey";


--
-- Name: aggregate_flatfile_2024W13_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024W13_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024W13_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024W13_pkey";


--
-- Name: aggregate_flatfile_2024W14_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024W14_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024W14_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024W14_pkey";


--
-- Name: aggregate_flatfile_2024W15_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024W15_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024W15_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024W15_pkey";


--
-- Name: aggregate_flatfile_2024W16_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024W16_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024W16_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024W16_pkey";


--
-- Name: aggregate_flatfile_2024W17_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024W17_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024W17_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024W17_pkey";


--
-- Name: aggregate_flatfile_2024W18_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024W18_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024W18_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024W18_pkey";


--
-- Name: aggregate_flatfile_2024W19_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024W19_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024W19_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024W19_pkey";


--
-- Name: aggregate_flatfile_2024W1_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024W1_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024W1_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024W1_pkey";


--
-- Name: aggregate_flatfile_2024W20_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024W20_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024W20_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024W20_pkey";


--
-- Name: aggregate_flatfile_2024W21_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024W21_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024W21_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024W21_pkey";


--
-- Name: aggregate_flatfile_2024W22_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024W22_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024W22_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024W22_pkey";


--
-- Name: aggregate_flatfile_2024W23_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024W23_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024W23_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024W23_pkey";


--
-- Name: aggregate_flatfile_2024W24_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024W24_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024W24_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024W24_pkey";


--
-- Name: aggregate_flatfile_2024W25_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024W25_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024W25_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024W25_pkey";


--
-- Name: aggregate_flatfile_2024W26_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024W26_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024W26_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024W26_pkey";


--
-- Name: aggregate_flatfile_2024W27_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024W27_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024W27_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024W27_pkey";


--
-- Name: aggregate_flatfile_2024W28_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024W28_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024W28_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024W28_pkey";


--
-- Name: aggregate_flatfile_2024W29_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024W29_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024W29_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024W29_pkey";


--
-- Name: aggregate_flatfile_2024W2_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024W2_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024W2_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024W2_pkey";


--
-- Name: aggregate_flatfile_2024W30_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024W30_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024W30_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024W30_pkey";


--
-- Name: aggregate_flatfile_2024W31_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024W31_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024W31_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024W31_pkey";


--
-- Name: aggregate_flatfile_2024W32_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024W32_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024W32_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024W32_pkey";


--
-- Name: aggregate_flatfile_2024W33_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024W33_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024W33_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024W33_pkey";


--
-- Name: aggregate_flatfile_2024W34_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024W34_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024W34_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024W34_pkey";


--
-- Name: aggregate_flatfile_2024W35_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024W35_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024W35_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024W35_pkey";


--
-- Name: aggregate_flatfile_2024W36_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024W36_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024W36_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024W36_pkey";


--
-- Name: aggregate_flatfile_2024W37_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024W37_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024W37_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024W37_pkey";


--
-- Name: aggregate_flatfile_2024W38_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024W38_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024W38_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024W38_pkey";


--
-- Name: aggregate_flatfile_2024W39_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024W39_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024W39_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024W39_pkey";


--
-- Name: aggregate_flatfile_2024W3_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024W3_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024W3_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024W3_pkey";


--
-- Name: aggregate_flatfile_2024W40_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024W40_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024W40_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024W40_pkey";


--
-- Name: aggregate_flatfile_2024W41_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024W41_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024W41_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024W41_pkey";


--
-- Name: aggregate_flatfile_2024W42_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024W42_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024W42_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024W42_pkey";


--
-- Name: aggregate_flatfile_2024W43_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024W43_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024W43_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024W43_pkey";


--
-- Name: aggregate_flatfile_2024W44_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024W44_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024W44_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024W44_pkey";


--
-- Name: aggregate_flatfile_2024W45_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024W45_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024W45_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024W45_pkey";


--
-- Name: aggregate_flatfile_2024W46_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024W46_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024W46_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024W46_pkey";


--
-- Name: aggregate_flatfile_2024W47_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024W47_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024W47_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024W47_pkey";


--
-- Name: aggregate_flatfile_2024W48_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024W48_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024W48_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024W48_pkey";


--
-- Name: aggregate_flatfile_2024W49_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024W49_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024W49_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024W49_pkey";


--
-- Name: aggregate_flatfile_2024W4_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024W4_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024W4_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024W4_pkey";


--
-- Name: aggregate_flatfile_2024W50_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024W50_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024W50_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024W50_pkey";


--
-- Name: aggregate_flatfile_2024W51_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024W51_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024W51_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024W51_pkey";


--
-- Name: aggregate_flatfile_2024W52_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024W52_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024W52_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024W52_pkey";


--
-- Name: aggregate_flatfile_2024W5_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024W5_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024W5_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024W5_pkey";


--
-- Name: aggregate_flatfile_2024W6_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024W6_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024W6_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024W6_pkey";


--
-- Name: aggregate_flatfile_2024W7_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024W7_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024W7_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024W7_pkey";


--
-- Name: aggregate_flatfile_2024W8_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024W8_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024W8_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024W8_pkey";


--
-- Name: aggregate_flatfile_2024W9_datim_id_date_idx; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.datimiddate_aggregateflatfilepmtctmaternal ATTACH PARTITION public."aggregate_flatfile_2024W9_datim_id_date_idx";


--
-- Name: aggregate_flatfile_2024W9_pkey; Type: INDEX ATTACH; Schema: public; Owner: emeka
--

ALTER INDEX public.aggregate_flatfile_backup_pkey3 ATTACH PARTITION public."aggregate_flatfile_2024W9_pkey";


--
-- Name: maternalcohort_2024Q3_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024Q3_Datim ID_idx";


--
-- Name: maternalcohort_2024Q3_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_maternalcohort ATTACH PARTITION public."maternalcohort_2024Q3_datimid_period_end_date_idx";


--
-- Name: maternalcohort_2024Q3_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024Q3_period_idx";


--
-- Name: maternalcohort_2024Q3_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_periodstartend_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024Q3_period_start_date_period_end_date_idx";


--
-- Name: maternalcohort_2024Q4_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024Q4_Datim ID_idx";


--
-- Name: maternalcohort_2024Q4_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_maternalcohort ATTACH PARTITION public."maternalcohort_2024Q4_datimid_period_end_date_idx";


--
-- Name: maternalcohort_2024Q4_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024Q4_period_idx";


--
-- Name: maternalcohort_2024Q4_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_periodstartend_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024Q4_period_start_date_period_end_date_idx";


--
-- Name: maternalcohort_2024W10_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W10_Datim ID_idx";


--
-- Name: maternalcohort_2024W10_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_maternalcohort ATTACH PARTITION public."maternalcohort_2024W10_datimid_period_end_date_idx";


--
-- Name: maternalcohort_2024W10_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W10_period_idx";


--
-- Name: maternalcohort_2024W10_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_periodstartend_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W10_period_start_date_period_end_date_idx";


--
-- Name: maternalcohort_2024W11_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W11_Datim ID_idx";


--
-- Name: maternalcohort_2024W11_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_maternalcohort ATTACH PARTITION public."maternalcohort_2024W11_datimid_period_end_date_idx";


--
-- Name: maternalcohort_2024W11_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W11_period_idx";


--
-- Name: maternalcohort_2024W11_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_periodstartend_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W11_period_start_date_period_end_date_idx";


--
-- Name: maternalcohort_2024W12_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W12_Datim ID_idx";


--
-- Name: maternalcohort_2024W12_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_maternalcohort ATTACH PARTITION public."maternalcohort_2024W12_datimid_period_end_date_idx";


--
-- Name: maternalcohort_2024W12_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W12_period_idx";


--
-- Name: maternalcohort_2024W12_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_periodstartend_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W12_period_start_date_period_end_date_idx";


--
-- Name: maternalcohort_2024W13_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W13_Datim ID_idx";


--
-- Name: maternalcohort_2024W13_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_maternalcohort ATTACH PARTITION public."maternalcohort_2024W13_datimid_period_end_date_idx";


--
-- Name: maternalcohort_2024W13_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W13_period_idx";


--
-- Name: maternalcohort_2024W13_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_periodstartend_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W13_period_start_date_period_end_date_idx";


--
-- Name: maternalcohort_2024W14_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W14_Datim ID_idx";


--
-- Name: maternalcohort_2024W14_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_maternalcohort ATTACH PARTITION public."maternalcohort_2024W14_datimid_period_end_date_idx";


--
-- Name: maternalcohort_2024W14_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W14_period_idx";


--
-- Name: maternalcohort_2024W14_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_periodstartend_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W14_period_start_date_period_end_date_idx";


--
-- Name: maternalcohort_2024W15_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W15_Datim ID_idx";


--
-- Name: maternalcohort_2024W15_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_maternalcohort ATTACH PARTITION public."maternalcohort_2024W15_datimid_period_end_date_idx";


--
-- Name: maternalcohort_2024W15_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W15_period_idx";


--
-- Name: maternalcohort_2024W15_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_periodstartend_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W15_period_start_date_period_end_date_idx";


--
-- Name: maternalcohort_2024W16_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W16_Datim ID_idx";


--
-- Name: maternalcohort_2024W16_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_maternalcohort ATTACH PARTITION public."maternalcohort_2024W16_datimid_period_end_date_idx";


--
-- Name: maternalcohort_2024W16_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W16_period_idx";


--
-- Name: maternalcohort_2024W16_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_periodstartend_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W16_period_start_date_period_end_date_idx";


--
-- Name: maternalcohort_2024W17_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W17_Datim ID_idx";


--
-- Name: maternalcohort_2024W17_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_maternalcohort ATTACH PARTITION public."maternalcohort_2024W17_datimid_period_end_date_idx";


--
-- Name: maternalcohort_2024W17_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W17_period_idx";


--
-- Name: maternalcohort_2024W17_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_periodstartend_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W17_period_start_date_period_end_date_idx";


--
-- Name: maternalcohort_2024W18_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W18_Datim ID_idx";


--
-- Name: maternalcohort_2024W18_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_maternalcohort ATTACH PARTITION public."maternalcohort_2024W18_datimid_period_end_date_idx";


--
-- Name: maternalcohort_2024W18_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W18_period_idx";


--
-- Name: maternalcohort_2024W18_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_periodstartend_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W18_period_start_date_period_end_date_idx";


--
-- Name: maternalcohort_2024W19_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W19_Datim ID_idx";


--
-- Name: maternalcohort_2024W19_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_maternalcohort ATTACH PARTITION public."maternalcohort_2024W19_datimid_period_end_date_idx";


--
-- Name: maternalcohort_2024W19_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W19_period_idx";


--
-- Name: maternalcohort_2024W19_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_periodstartend_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W19_period_start_date_period_end_date_idx";


--
-- Name: maternalcohort_2024W20_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W20_Datim ID_idx";


--
-- Name: maternalcohort_2024W20_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_maternalcohort ATTACH PARTITION public."maternalcohort_2024W20_datimid_period_end_date_idx";


--
-- Name: maternalcohort_2024W20_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W20_period_idx";


--
-- Name: maternalcohort_2024W20_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_periodstartend_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W20_period_start_date_period_end_date_idx";


--
-- Name: maternalcohort_2024W21_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W21_Datim ID_idx";


--
-- Name: maternalcohort_2024W21_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_maternalcohort ATTACH PARTITION public."maternalcohort_2024W21_datimid_period_end_date_idx";


--
-- Name: maternalcohort_2024W21_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W21_period_idx";


--
-- Name: maternalcohort_2024W21_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_periodstartend_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W21_period_start_date_period_end_date_idx";


--
-- Name: maternalcohort_2024W22_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W22_Datim ID_idx";


--
-- Name: maternalcohort_2024W22_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_maternalcohort ATTACH PARTITION public."maternalcohort_2024W22_datimid_period_end_date_idx";


--
-- Name: maternalcohort_2024W22_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W22_period_idx";


--
-- Name: maternalcohort_2024W22_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_periodstartend_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W22_period_start_date_period_end_date_idx";


--
-- Name: maternalcohort_2024W23_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W23_Datim ID_idx";


--
-- Name: maternalcohort_2024W23_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_maternalcohort ATTACH PARTITION public."maternalcohort_2024W23_datimid_period_end_date_idx";


--
-- Name: maternalcohort_2024W23_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W23_period_idx";


--
-- Name: maternalcohort_2024W23_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_periodstartend_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W23_period_start_date_period_end_date_idx";


--
-- Name: maternalcohort_2024W24_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W24_Datim ID_idx";


--
-- Name: maternalcohort_2024W24_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_maternalcohort ATTACH PARTITION public."maternalcohort_2024W24_datimid_period_end_date_idx";


--
-- Name: maternalcohort_2024W24_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W24_period_idx";


--
-- Name: maternalcohort_2024W24_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_periodstartend_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W24_period_start_date_period_end_date_idx";


--
-- Name: maternalcohort_2024W25_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W25_Datim ID_idx";


--
-- Name: maternalcohort_2024W25_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_maternalcohort ATTACH PARTITION public."maternalcohort_2024W25_datimid_period_end_date_idx";


--
-- Name: maternalcohort_2024W25_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W25_period_idx";


--
-- Name: maternalcohort_2024W25_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_periodstartend_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W25_period_start_date_period_end_date_idx";


--
-- Name: maternalcohort_2024W26_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W26_Datim ID_idx";


--
-- Name: maternalcohort_2024W26_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_maternalcohort ATTACH PARTITION public."maternalcohort_2024W26_datimid_period_end_date_idx";


--
-- Name: maternalcohort_2024W26_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W26_period_idx";


--
-- Name: maternalcohort_2024W26_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_periodstartend_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W26_period_start_date_period_end_date_idx";


--
-- Name: maternalcohort_2024W27_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W27_Datim ID_idx";


--
-- Name: maternalcohort_2024W27_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_maternalcohort ATTACH PARTITION public."maternalcohort_2024W27_datimid_period_end_date_idx";


--
-- Name: maternalcohort_2024W27_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W27_period_idx";


--
-- Name: maternalcohort_2024W27_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_periodstartend_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W27_period_start_date_period_end_date_idx";


--
-- Name: maternalcohort_2024W28_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W28_Datim ID_idx";


--
-- Name: maternalcohort_2024W28_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_maternalcohort ATTACH PARTITION public."maternalcohort_2024W28_datimid_period_end_date_idx";


--
-- Name: maternalcohort_2024W28_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W28_period_idx";


--
-- Name: maternalcohort_2024W28_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_periodstartend_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W28_period_start_date_period_end_date_idx";


--
-- Name: maternalcohort_2024W29_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W29_Datim ID_idx";


--
-- Name: maternalcohort_2024W29_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_maternalcohort ATTACH PARTITION public."maternalcohort_2024W29_datimid_period_end_date_idx";


--
-- Name: maternalcohort_2024W29_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W29_period_idx";


--
-- Name: maternalcohort_2024W29_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_periodstartend_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W29_period_start_date_period_end_date_idx";


--
-- Name: maternalcohort_2024W2_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W2_Datim ID_idx";


--
-- Name: maternalcohort_2024W2_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_maternalcohort ATTACH PARTITION public."maternalcohort_2024W2_datimid_period_end_date_idx";


--
-- Name: maternalcohort_2024W2_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W2_period_idx";


--
-- Name: maternalcohort_2024W2_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_periodstartend_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W2_period_start_date_period_end_date_idx";


--
-- Name: maternalcohort_2024W30_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W30_Datim ID_idx";


--
-- Name: maternalcohort_2024W30_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_maternalcohort ATTACH PARTITION public."maternalcohort_2024W30_datimid_period_end_date_idx";


--
-- Name: maternalcohort_2024W30_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W30_period_idx";


--
-- Name: maternalcohort_2024W30_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_periodstartend_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W30_period_start_date_period_end_date_idx";


--
-- Name: maternalcohort_2024W31_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W31_Datim ID_idx";


--
-- Name: maternalcohort_2024W31_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_maternalcohort ATTACH PARTITION public."maternalcohort_2024W31_datimid_period_end_date_idx";


--
-- Name: maternalcohort_2024W31_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W31_period_idx";


--
-- Name: maternalcohort_2024W31_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_periodstartend_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W31_period_start_date_period_end_date_idx";


--
-- Name: maternalcohort_2024W32_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W32_Datim ID_idx";


--
-- Name: maternalcohort_2024W32_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_maternalcohort ATTACH PARTITION public."maternalcohort_2024W32_datimid_period_end_date_idx";


--
-- Name: maternalcohort_2024W32_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W32_period_idx";


--
-- Name: maternalcohort_2024W32_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_periodstartend_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W32_period_start_date_period_end_date_idx";


--
-- Name: maternalcohort_2024W33_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W33_Datim ID_idx";


--
-- Name: maternalcohort_2024W33_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_maternalcohort ATTACH PARTITION public."maternalcohort_2024W33_datimid_period_end_date_idx";


--
-- Name: maternalcohort_2024W33_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W33_period_idx";


--
-- Name: maternalcohort_2024W33_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_periodstartend_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W33_period_start_date_period_end_date_idx";


--
-- Name: maternalcohort_2024W34_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W34_Datim ID_idx";


--
-- Name: maternalcohort_2024W34_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_maternalcohort ATTACH PARTITION public."maternalcohort_2024W34_datimid_period_end_date_idx";


--
-- Name: maternalcohort_2024W34_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W34_period_idx";


--
-- Name: maternalcohort_2024W34_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_periodstartend_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W34_period_start_date_period_end_date_idx";


--
-- Name: maternalcohort_2024W35_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W35_Datim ID_idx";


--
-- Name: maternalcohort_2024W35_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_maternalcohort ATTACH PARTITION public."maternalcohort_2024W35_datimid_period_end_date_idx";


--
-- Name: maternalcohort_2024W35_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W35_period_idx";


--
-- Name: maternalcohort_2024W35_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_periodstartend_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W35_period_start_date_period_end_date_idx";


--
-- Name: maternalcohort_2024W36_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W36_Datim ID_idx";


--
-- Name: maternalcohort_2024W36_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_maternalcohort ATTACH PARTITION public."maternalcohort_2024W36_datimid_period_end_date_idx";


--
-- Name: maternalcohort_2024W36_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W36_period_idx";


--
-- Name: maternalcohort_2024W36_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_periodstartend_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W36_period_start_date_period_end_date_idx";


--
-- Name: maternalcohort_2024W37_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W37_Datim ID_idx";


--
-- Name: maternalcohort_2024W37_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_maternalcohort ATTACH PARTITION public."maternalcohort_2024W37_datimid_period_end_date_idx";


--
-- Name: maternalcohort_2024W37_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W37_period_idx";


--
-- Name: maternalcohort_2024W37_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_periodstartend_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W37_period_start_date_period_end_date_idx";


--
-- Name: maternalcohort_2024W38_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W38_Datim ID_idx";


--
-- Name: maternalcohort_2024W38_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_maternalcohort ATTACH PARTITION public."maternalcohort_2024W38_datimid_period_end_date_idx";


--
-- Name: maternalcohort_2024W38_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W38_period_idx";


--
-- Name: maternalcohort_2024W38_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_periodstartend_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W38_period_start_date_period_end_date_idx";


--
-- Name: maternalcohort_2024W39_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W39_Datim ID_idx";


--
-- Name: maternalcohort_2024W39_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_maternalcohort ATTACH PARTITION public."maternalcohort_2024W39_datimid_period_end_date_idx";


--
-- Name: maternalcohort_2024W39_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W39_period_idx";


--
-- Name: maternalcohort_2024W39_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_periodstartend_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W39_period_start_date_period_end_date_idx";


--
-- Name: maternalcohort_2024W3_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W3_Datim ID_idx";


--
-- Name: maternalcohort_2024W3_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_maternalcohort ATTACH PARTITION public."maternalcohort_2024W3_datimid_period_end_date_idx";


--
-- Name: maternalcohort_2024W3_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W3_period_idx";


--
-- Name: maternalcohort_2024W3_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_periodstartend_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W3_period_start_date_period_end_date_idx";


--
-- Name: maternalcohort_2024W40_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W40_Datim ID_idx";


--
-- Name: maternalcohort_2024W40_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_maternalcohort ATTACH PARTITION public."maternalcohort_2024W40_datimid_period_end_date_idx";


--
-- Name: maternalcohort_2024W40_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W40_period_idx";


--
-- Name: maternalcohort_2024W40_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_periodstartend_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W40_period_start_date_period_end_date_idx";


--
-- Name: maternalcohort_2024W41_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W41_Datim ID_idx";


--
-- Name: maternalcohort_2024W41_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_maternalcohort ATTACH PARTITION public."maternalcohort_2024W41_datimid_period_end_date_idx";


--
-- Name: maternalcohort_2024W41_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W41_period_idx";


--
-- Name: maternalcohort_2024W41_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_periodstartend_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W41_period_start_date_period_end_date_idx";


--
-- Name: maternalcohort_2024W42_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W42_Datim ID_idx";


--
-- Name: maternalcohort_2024W42_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_maternalcohort ATTACH PARTITION public."maternalcohort_2024W42_datimid_period_end_date_idx";


--
-- Name: maternalcohort_2024W42_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W42_period_idx";


--
-- Name: maternalcohort_2024W42_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_periodstartend_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W42_period_start_date_period_end_date_idx";


--
-- Name: maternalcohort_2024W43_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W43_Datim ID_idx";


--
-- Name: maternalcohort_2024W43_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_maternalcohort ATTACH PARTITION public."maternalcohort_2024W43_datimid_period_end_date_idx";


--
-- Name: maternalcohort_2024W43_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W43_period_idx";


--
-- Name: maternalcohort_2024W43_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_periodstartend_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W43_period_start_date_period_end_date_idx";


--
-- Name: maternalcohort_2024W44_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W44_Datim ID_idx";


--
-- Name: maternalcohort_2024W44_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_maternalcohort ATTACH PARTITION public."maternalcohort_2024W44_datimid_period_end_date_idx";


--
-- Name: maternalcohort_2024W44_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W44_period_idx";


--
-- Name: maternalcohort_2024W44_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_periodstartend_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W44_period_start_date_period_end_date_idx";


--
-- Name: maternalcohort_2024W45_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W45_Datim ID_idx";


--
-- Name: maternalcohort_2024W45_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_maternalcohort ATTACH PARTITION public."maternalcohort_2024W45_datimid_period_end_date_idx";


--
-- Name: maternalcohort_2024W45_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W45_period_idx";


--
-- Name: maternalcohort_2024W45_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_periodstartend_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W45_period_start_date_period_end_date_idx";


--
-- Name: maternalcohort_2024W46_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W46_Datim ID_idx";


--
-- Name: maternalcohort_2024W46_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_maternalcohort ATTACH PARTITION public."maternalcohort_2024W46_datimid_period_end_date_idx";


--
-- Name: maternalcohort_2024W46_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W46_period_idx";


--
-- Name: maternalcohort_2024W46_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_periodstartend_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W46_period_start_date_period_end_date_idx";


--
-- Name: maternalcohort_2024W47_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W47_Datim ID_idx";


--
-- Name: maternalcohort_2024W47_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_maternalcohort ATTACH PARTITION public."maternalcohort_2024W47_datimid_period_end_date_idx";


--
-- Name: maternalcohort_2024W47_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W47_period_idx";


--
-- Name: maternalcohort_2024W47_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_periodstartend_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W47_period_start_date_period_end_date_idx";


--
-- Name: maternalcohort_2024W48_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W48_Datim ID_idx";


--
-- Name: maternalcohort_2024W48_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_maternalcohort ATTACH PARTITION public."maternalcohort_2024W48_datimid_period_end_date_idx";


--
-- Name: maternalcohort_2024W48_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W48_period_idx";


--
-- Name: maternalcohort_2024W48_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_periodstartend_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W48_period_start_date_period_end_date_idx";


--
-- Name: maternalcohort_2024W49_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W49_Datim ID_idx";


--
-- Name: maternalcohort_2024W49_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_maternalcohort ATTACH PARTITION public."maternalcohort_2024W49_datimid_period_end_date_idx";


--
-- Name: maternalcohort_2024W49_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W49_period_idx";


--
-- Name: maternalcohort_2024W49_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_periodstartend_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W49_period_start_date_period_end_date_idx";


--
-- Name: maternalcohort_2024W4_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W4_Datim ID_idx";


--
-- Name: maternalcohort_2024W4_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_maternalcohort ATTACH PARTITION public."maternalcohort_2024W4_datimid_period_end_date_idx";


--
-- Name: maternalcohort_2024W4_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W4_period_idx";


--
-- Name: maternalcohort_2024W4_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_periodstartend_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W4_period_start_date_period_end_date_idx";


--
-- Name: maternalcohort_2024W50_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W50_Datim ID_idx";


--
-- Name: maternalcohort_2024W50_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_maternalcohort ATTACH PARTITION public."maternalcohort_2024W50_datimid_period_end_date_idx";


--
-- Name: maternalcohort_2024W50_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W50_period_idx";


--
-- Name: maternalcohort_2024W50_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_periodstartend_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W50_period_start_date_period_end_date_idx";


--
-- Name: maternalcohort_2024W51_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W51_Datim ID_idx";


--
-- Name: maternalcohort_2024W51_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_maternalcohort ATTACH PARTITION public."maternalcohort_2024W51_datimid_period_end_date_idx";


--
-- Name: maternalcohort_2024W51_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W51_period_idx";


--
-- Name: maternalcohort_2024W51_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_periodstartend_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W51_period_start_date_period_end_date_idx";


--
-- Name: maternalcohort_2024W52_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W52_Datim ID_idx";


--
-- Name: maternalcohort_2024W52_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_maternalcohort ATTACH PARTITION public."maternalcohort_2024W52_datimid_period_end_date_idx";


--
-- Name: maternalcohort_2024W52_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W52_period_idx";


--
-- Name: maternalcohort_2024W52_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_periodstartend_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W52_period_start_date_period_end_date_idx";


--
-- Name: maternalcohort_2024W5_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W5_Datim ID_idx";


--
-- Name: maternalcohort_2024W5_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_maternalcohort ATTACH PARTITION public."maternalcohort_2024W5_datimid_period_end_date_idx";


--
-- Name: maternalcohort_2024W5_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W5_period_idx";


--
-- Name: maternalcohort_2024W5_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_periodstartend_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W5_period_start_date_period_end_date_idx";


--
-- Name: maternalcohort_2024W6_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W6_Datim ID_idx";


--
-- Name: maternalcohort_2024W6_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_maternalcohort ATTACH PARTITION public."maternalcohort_2024W6_datimid_period_end_date_idx";


--
-- Name: maternalcohort_2024W6_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W6_period_idx";


--
-- Name: maternalcohort_2024W6_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_periodstartend_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W6_period_start_date_period_end_date_idx";


--
-- Name: maternalcohort_2024W7_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W7_Datim ID_idx";


--
-- Name: maternalcohort_2024W7_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_maternalcohort ATTACH PARTITION public."maternalcohort_2024W7_datimid_period_end_date_idx";


--
-- Name: maternalcohort_2024W7_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W7_period_idx";


--
-- Name: maternalcohort_2024W7_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_periodstartend_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W7_period_start_date_period_end_date_idx";


--
-- Name: maternalcohort_2024W8_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W8_Datim ID_idx";


--
-- Name: maternalcohort_2024W8_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_maternalcohort ATTACH PARTITION public."maternalcohort_2024W8_datimid_period_end_date_idx";


--
-- Name: maternalcohort_2024W8_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W8_period_idx";


--
-- Name: maternalcohort_2024W8_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_periodstartend_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W8_period_start_date_period_end_date_idx";


--
-- Name: maternalcohort_2024W9_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W9_Datim ID_idx";


--
-- Name: maternalcohort_2024W9_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_maternalcohort ATTACH PARTITION public."maternalcohort_2024W9_datimid_period_end_date_idx";


--
-- Name: maternalcohort_2024W9_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W9_period_idx";


--
-- Name: maternalcohort_2024W9_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_periodstartend_pmtct_maternal_cohort ATTACH PARTITION public."maternalcohort_2024W9_period_start_date_period_end_date_idx";


--
-- Name: pmtcthts_2024Q3_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtcthts_weekly ATTACH PARTITION public."pmtcthts_2024Q3_Datim ID_idx";


--
-- Name: pmtcthts_2024Q3_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_pmtcthts ATTACH PARTITION public."pmtcthts_2024Q3_datimid_period_end_date_idx";


--
-- Name: pmtcthts_2024Q3_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_hts ATTACH PARTITION public."pmtcthts_2024Q3_period_idx";


--
-- Name: pmtcthts_2024Q3_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_startdateenddate_pmtct_hts ATTACH PARTITION public."pmtcthts_2024Q3_period_start_date_period_end_date_idx";


--
-- Name: pmtcthts_2024Q4_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtcthts_weekly ATTACH PARTITION public."pmtcthts_2024Q4_Datim ID_idx";


--
-- Name: pmtcthts_2024Q4_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_pmtcthts ATTACH PARTITION public."pmtcthts_2024Q4_datimid_period_end_date_idx";


--
-- Name: pmtcthts_2024Q4_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_hts ATTACH PARTITION public."pmtcthts_2024Q4_period_idx";


--
-- Name: pmtcthts_2024Q4_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_startdateenddate_pmtct_hts ATTACH PARTITION public."pmtcthts_2024Q4_period_start_date_period_end_date_idx";


--
-- Name: pmtcthts_2024W10_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtcthts_weekly ATTACH PARTITION public."pmtcthts_2024W10_Datim ID_idx";


--
-- Name: pmtcthts_2024W10_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_pmtcthts ATTACH PARTITION public."pmtcthts_2024W10_datimid_period_end_date_idx";


--
-- Name: pmtcthts_2024W10_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W10_period_idx";


--
-- Name: pmtcthts_2024W10_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_startdateenddate_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W10_period_start_date_period_end_date_idx";


--
-- Name: pmtcthts_2024W11_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtcthts_weekly ATTACH PARTITION public."pmtcthts_2024W11_Datim ID_idx";


--
-- Name: pmtcthts_2024W11_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_pmtcthts ATTACH PARTITION public."pmtcthts_2024W11_datimid_period_end_date_idx";


--
-- Name: pmtcthts_2024W11_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W11_period_idx";


--
-- Name: pmtcthts_2024W11_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_startdateenddate_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W11_period_start_date_period_end_date_idx";


--
-- Name: pmtcthts_2024W12_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtcthts_weekly ATTACH PARTITION public."pmtcthts_2024W12_Datim ID_idx";


--
-- Name: pmtcthts_2024W12_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_pmtcthts ATTACH PARTITION public."pmtcthts_2024W12_datimid_period_end_date_idx";


--
-- Name: pmtcthts_2024W12_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W12_period_idx";


--
-- Name: pmtcthts_2024W12_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_startdateenddate_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W12_period_start_date_period_end_date_idx";


--
-- Name: pmtcthts_2024W13_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtcthts_weekly ATTACH PARTITION public."pmtcthts_2024W13_Datim ID_idx";


--
-- Name: pmtcthts_2024W13_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_pmtcthts ATTACH PARTITION public."pmtcthts_2024W13_datimid_period_end_date_idx";


--
-- Name: pmtcthts_2024W13_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W13_period_idx";


--
-- Name: pmtcthts_2024W13_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_startdateenddate_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W13_period_start_date_period_end_date_idx";


--
-- Name: pmtcthts_2024W14_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtcthts_weekly ATTACH PARTITION public."pmtcthts_2024W14_Datim ID_idx";


--
-- Name: pmtcthts_2024W14_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_pmtcthts ATTACH PARTITION public."pmtcthts_2024W14_datimid_period_end_date_idx";


--
-- Name: pmtcthts_2024W14_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W14_period_idx";


--
-- Name: pmtcthts_2024W14_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_startdateenddate_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W14_period_start_date_period_end_date_idx";


--
-- Name: pmtcthts_2024W15_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtcthts_weekly ATTACH PARTITION public."pmtcthts_2024W15_Datim ID_idx";


--
-- Name: pmtcthts_2024W15_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_pmtcthts ATTACH PARTITION public."pmtcthts_2024W15_datimid_period_end_date_idx";


--
-- Name: pmtcthts_2024W15_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W15_period_idx";


--
-- Name: pmtcthts_2024W15_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_startdateenddate_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W15_period_start_date_period_end_date_idx";


--
-- Name: pmtcthts_2024W16_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtcthts_weekly ATTACH PARTITION public."pmtcthts_2024W16_Datim ID_idx";


--
-- Name: pmtcthts_2024W16_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_pmtcthts ATTACH PARTITION public."pmtcthts_2024W16_datimid_period_end_date_idx";


--
-- Name: pmtcthts_2024W16_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W16_period_idx";


--
-- Name: pmtcthts_2024W16_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_startdateenddate_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W16_period_start_date_period_end_date_idx";


--
-- Name: pmtcthts_2024W17_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtcthts_weekly ATTACH PARTITION public."pmtcthts_2024W17_Datim ID_idx";


--
-- Name: pmtcthts_2024W17_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_pmtcthts ATTACH PARTITION public."pmtcthts_2024W17_datimid_period_end_date_idx";


--
-- Name: pmtcthts_2024W17_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W17_period_idx";


--
-- Name: pmtcthts_2024W17_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_startdateenddate_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W17_period_start_date_period_end_date_idx";


--
-- Name: pmtcthts_2024W18_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtcthts_weekly ATTACH PARTITION public."pmtcthts_2024W18_Datim ID_idx";


--
-- Name: pmtcthts_2024W18_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_pmtcthts ATTACH PARTITION public."pmtcthts_2024W18_datimid_period_end_date_idx";


--
-- Name: pmtcthts_2024W18_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W18_period_idx";


--
-- Name: pmtcthts_2024W18_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_startdateenddate_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W18_period_start_date_period_end_date_idx";


--
-- Name: pmtcthts_2024W19_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtcthts_weekly ATTACH PARTITION public."pmtcthts_2024W19_Datim ID_idx";


--
-- Name: pmtcthts_2024W19_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_pmtcthts ATTACH PARTITION public."pmtcthts_2024W19_datimid_period_end_date_idx";


--
-- Name: pmtcthts_2024W19_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W19_period_idx";


--
-- Name: pmtcthts_2024W19_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_startdateenddate_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W19_period_start_date_period_end_date_idx";


--
-- Name: pmtcthts_2024W20_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtcthts_weekly ATTACH PARTITION public."pmtcthts_2024W20_Datim ID_idx";


--
-- Name: pmtcthts_2024W20_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_pmtcthts ATTACH PARTITION public."pmtcthts_2024W20_datimid_period_end_date_idx";


--
-- Name: pmtcthts_2024W20_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W20_period_idx";


--
-- Name: pmtcthts_2024W20_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_startdateenddate_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W20_period_start_date_period_end_date_idx";


--
-- Name: pmtcthts_2024W21_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtcthts_weekly ATTACH PARTITION public."pmtcthts_2024W21_Datim ID_idx";


--
-- Name: pmtcthts_2024W21_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_pmtcthts ATTACH PARTITION public."pmtcthts_2024W21_datimid_period_end_date_idx";


--
-- Name: pmtcthts_2024W21_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W21_period_idx";


--
-- Name: pmtcthts_2024W21_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_startdateenddate_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W21_period_start_date_period_end_date_idx";


--
-- Name: pmtcthts_2024W22_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtcthts_weekly ATTACH PARTITION public."pmtcthts_2024W22_Datim ID_idx";


--
-- Name: pmtcthts_2024W22_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_pmtcthts ATTACH PARTITION public."pmtcthts_2024W22_datimid_period_end_date_idx";


--
-- Name: pmtcthts_2024W22_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W22_period_idx";


--
-- Name: pmtcthts_2024W22_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_startdateenddate_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W22_period_start_date_period_end_date_idx";


--
-- Name: pmtcthts_2024W23_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtcthts_weekly ATTACH PARTITION public."pmtcthts_2024W23_Datim ID_idx";


--
-- Name: pmtcthts_2024W23_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_pmtcthts ATTACH PARTITION public."pmtcthts_2024W23_datimid_period_end_date_idx";


--
-- Name: pmtcthts_2024W23_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W23_period_idx";


--
-- Name: pmtcthts_2024W23_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_startdateenddate_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W23_period_start_date_period_end_date_idx";


--
-- Name: pmtcthts_2024W24_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtcthts_weekly ATTACH PARTITION public."pmtcthts_2024W24_Datim ID_idx";


--
-- Name: pmtcthts_2024W24_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_pmtcthts ATTACH PARTITION public."pmtcthts_2024W24_datimid_period_end_date_idx";


--
-- Name: pmtcthts_2024W24_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W24_period_idx";


--
-- Name: pmtcthts_2024W24_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_startdateenddate_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W24_period_start_date_period_end_date_idx";


--
-- Name: pmtcthts_2024W25_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtcthts_weekly ATTACH PARTITION public."pmtcthts_2024W25_Datim ID_idx";


--
-- Name: pmtcthts_2024W25_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_pmtcthts ATTACH PARTITION public."pmtcthts_2024W25_datimid_period_end_date_idx";


--
-- Name: pmtcthts_2024W25_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W25_period_idx";


--
-- Name: pmtcthts_2024W25_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_startdateenddate_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W25_period_start_date_period_end_date_idx";


--
-- Name: pmtcthts_2024W26_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtcthts_weekly ATTACH PARTITION public."pmtcthts_2024W26_Datim ID_idx";


--
-- Name: pmtcthts_2024W26_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_pmtcthts ATTACH PARTITION public."pmtcthts_2024W26_datimid_period_end_date_idx";


--
-- Name: pmtcthts_2024W26_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W26_period_idx";


--
-- Name: pmtcthts_2024W26_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_startdateenddate_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W26_period_start_date_period_end_date_idx";


--
-- Name: pmtcthts_2024W27_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtcthts_weekly ATTACH PARTITION public."pmtcthts_2024W27_Datim ID_idx";


--
-- Name: pmtcthts_2024W27_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_pmtcthts ATTACH PARTITION public."pmtcthts_2024W27_datimid_period_end_date_idx";


--
-- Name: pmtcthts_2024W27_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W27_period_idx";


--
-- Name: pmtcthts_2024W27_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_startdateenddate_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W27_period_start_date_period_end_date_idx";


--
-- Name: pmtcthts_2024W28_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtcthts_weekly ATTACH PARTITION public."pmtcthts_2024W28_Datim ID_idx";


--
-- Name: pmtcthts_2024W28_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_pmtcthts ATTACH PARTITION public."pmtcthts_2024W28_datimid_period_end_date_idx";


--
-- Name: pmtcthts_2024W28_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W28_period_idx";


--
-- Name: pmtcthts_2024W28_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_startdateenddate_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W28_period_start_date_period_end_date_idx";


--
-- Name: pmtcthts_2024W29_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtcthts_weekly ATTACH PARTITION public."pmtcthts_2024W29_Datim ID_idx";


--
-- Name: pmtcthts_2024W29_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_pmtcthts ATTACH PARTITION public."pmtcthts_2024W29_datimid_period_end_date_idx";


--
-- Name: pmtcthts_2024W29_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W29_period_idx";


--
-- Name: pmtcthts_2024W29_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_startdateenddate_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W29_period_start_date_period_end_date_idx";


--
-- Name: pmtcthts_2024W2_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtcthts_weekly ATTACH PARTITION public."pmtcthts_2024W2_Datim ID_idx";


--
-- Name: pmtcthts_2024W2_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_pmtcthts ATTACH PARTITION public."pmtcthts_2024W2_datimid_period_end_date_idx";


--
-- Name: pmtcthts_2024W2_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W2_period_idx";


--
-- Name: pmtcthts_2024W2_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_startdateenddate_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W2_period_start_date_period_end_date_idx";


--
-- Name: pmtcthts_2024W30_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtcthts_weekly ATTACH PARTITION public."pmtcthts_2024W30_Datim ID_idx";


--
-- Name: pmtcthts_2024W30_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_pmtcthts ATTACH PARTITION public."pmtcthts_2024W30_datimid_period_end_date_idx";


--
-- Name: pmtcthts_2024W30_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W30_period_idx";


--
-- Name: pmtcthts_2024W30_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_startdateenddate_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W30_period_start_date_period_end_date_idx";


--
-- Name: pmtcthts_2024W31_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtcthts_weekly ATTACH PARTITION public."pmtcthts_2024W31_Datim ID_idx";


--
-- Name: pmtcthts_2024W31_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_pmtcthts ATTACH PARTITION public."pmtcthts_2024W31_datimid_period_end_date_idx";


--
-- Name: pmtcthts_2024W31_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W31_period_idx";


--
-- Name: pmtcthts_2024W31_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_startdateenddate_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W31_period_start_date_period_end_date_idx";


--
-- Name: pmtcthts_2024W32_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtcthts_weekly ATTACH PARTITION public."pmtcthts_2024W32_Datim ID_idx";


--
-- Name: pmtcthts_2024W32_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_pmtcthts ATTACH PARTITION public."pmtcthts_2024W32_datimid_period_end_date_idx";


--
-- Name: pmtcthts_2024W32_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W32_period_idx";


--
-- Name: pmtcthts_2024W32_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_startdateenddate_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W32_period_start_date_period_end_date_idx";


--
-- Name: pmtcthts_2024W33_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtcthts_weekly ATTACH PARTITION public."pmtcthts_2024W33_Datim ID_idx";


--
-- Name: pmtcthts_2024W33_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_pmtcthts ATTACH PARTITION public."pmtcthts_2024W33_datimid_period_end_date_idx";


--
-- Name: pmtcthts_2024W33_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W33_period_idx";


--
-- Name: pmtcthts_2024W33_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_startdateenddate_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W33_period_start_date_period_end_date_idx";


--
-- Name: pmtcthts_2024W34_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtcthts_weekly ATTACH PARTITION public."pmtcthts_2024W34_Datim ID_idx";


--
-- Name: pmtcthts_2024W34_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_pmtcthts ATTACH PARTITION public."pmtcthts_2024W34_datimid_period_end_date_idx";


--
-- Name: pmtcthts_2024W34_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W34_period_idx";


--
-- Name: pmtcthts_2024W34_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_startdateenddate_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W34_period_start_date_period_end_date_idx";


--
-- Name: pmtcthts_2024W35_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtcthts_weekly ATTACH PARTITION public."pmtcthts_2024W35_Datim ID_idx";


--
-- Name: pmtcthts_2024W35_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_pmtcthts ATTACH PARTITION public."pmtcthts_2024W35_datimid_period_end_date_idx";


--
-- Name: pmtcthts_2024W35_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W35_period_idx";


--
-- Name: pmtcthts_2024W35_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_startdateenddate_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W35_period_start_date_period_end_date_idx";


--
-- Name: pmtcthts_2024W36_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtcthts_weekly ATTACH PARTITION public."pmtcthts_2024W36_Datim ID_idx";


--
-- Name: pmtcthts_2024W36_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_pmtcthts ATTACH PARTITION public."pmtcthts_2024W36_datimid_period_end_date_idx";


--
-- Name: pmtcthts_2024W36_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W36_period_idx";


--
-- Name: pmtcthts_2024W36_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_startdateenddate_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W36_period_start_date_period_end_date_idx";


--
-- Name: pmtcthts_2024W37_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtcthts_weekly ATTACH PARTITION public."pmtcthts_2024W37_Datim ID_idx";


--
-- Name: pmtcthts_2024W37_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_pmtcthts ATTACH PARTITION public."pmtcthts_2024W37_datimid_period_end_date_idx";


--
-- Name: pmtcthts_2024W37_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W37_period_idx";


--
-- Name: pmtcthts_2024W37_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_startdateenddate_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W37_period_start_date_period_end_date_idx";


--
-- Name: pmtcthts_2024W38_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtcthts_weekly ATTACH PARTITION public."pmtcthts_2024W38_Datim ID_idx";


--
-- Name: pmtcthts_2024W38_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_pmtcthts ATTACH PARTITION public."pmtcthts_2024W38_datimid_period_end_date_idx";


--
-- Name: pmtcthts_2024W38_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W38_period_idx";


--
-- Name: pmtcthts_2024W38_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_startdateenddate_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W38_period_start_date_period_end_date_idx";


--
-- Name: pmtcthts_2024W39_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtcthts_weekly ATTACH PARTITION public."pmtcthts_2024W39_Datim ID_idx";


--
-- Name: pmtcthts_2024W39_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_pmtcthts ATTACH PARTITION public."pmtcthts_2024W39_datimid_period_end_date_idx";


--
-- Name: pmtcthts_2024W39_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W39_period_idx";


--
-- Name: pmtcthts_2024W39_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_startdateenddate_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W39_period_start_date_period_end_date_idx";


--
-- Name: pmtcthts_2024W3_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtcthts_weekly ATTACH PARTITION public."pmtcthts_2024W3_Datim ID_idx";


--
-- Name: pmtcthts_2024W3_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_pmtcthts ATTACH PARTITION public."pmtcthts_2024W3_datimid_period_end_date_idx";


--
-- Name: pmtcthts_2024W3_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W3_period_idx";


--
-- Name: pmtcthts_2024W3_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_startdateenddate_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W3_period_start_date_period_end_date_idx";


--
-- Name: pmtcthts_2024W40_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtcthts_weekly ATTACH PARTITION public."pmtcthts_2024W40_Datim ID_idx";


--
-- Name: pmtcthts_2024W40_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_pmtcthts ATTACH PARTITION public."pmtcthts_2024W40_datimid_period_end_date_idx";


--
-- Name: pmtcthts_2024W40_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W40_period_idx";


--
-- Name: pmtcthts_2024W40_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_startdateenddate_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W40_period_start_date_period_end_date_idx";


--
-- Name: pmtcthts_2024W41_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtcthts_weekly ATTACH PARTITION public."pmtcthts_2024W41_Datim ID_idx";


--
-- Name: pmtcthts_2024W41_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_pmtcthts ATTACH PARTITION public."pmtcthts_2024W41_datimid_period_end_date_idx";


--
-- Name: pmtcthts_2024W41_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W41_period_idx";


--
-- Name: pmtcthts_2024W41_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_startdateenddate_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W41_period_start_date_period_end_date_idx";


--
-- Name: pmtcthts_2024W42_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtcthts_weekly ATTACH PARTITION public."pmtcthts_2024W42_Datim ID_idx";


--
-- Name: pmtcthts_2024W42_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_pmtcthts ATTACH PARTITION public."pmtcthts_2024W42_datimid_period_end_date_idx";


--
-- Name: pmtcthts_2024W42_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W42_period_idx";


--
-- Name: pmtcthts_2024W42_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_startdateenddate_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W42_period_start_date_period_end_date_idx";


--
-- Name: pmtcthts_2024W43_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtcthts_weekly ATTACH PARTITION public."pmtcthts_2024W43_Datim ID_idx";


--
-- Name: pmtcthts_2024W43_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_pmtcthts ATTACH PARTITION public."pmtcthts_2024W43_datimid_period_end_date_idx";


--
-- Name: pmtcthts_2024W43_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W43_period_idx";


--
-- Name: pmtcthts_2024W43_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_startdateenddate_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W43_period_start_date_period_end_date_idx";


--
-- Name: pmtcthts_2024W44_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtcthts_weekly ATTACH PARTITION public."pmtcthts_2024W44_Datim ID_idx";


--
-- Name: pmtcthts_2024W44_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_pmtcthts ATTACH PARTITION public."pmtcthts_2024W44_datimid_period_end_date_idx";


--
-- Name: pmtcthts_2024W44_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W44_period_idx";


--
-- Name: pmtcthts_2024W44_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_startdateenddate_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W44_period_start_date_period_end_date_idx";


--
-- Name: pmtcthts_2024W45_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtcthts_weekly ATTACH PARTITION public."pmtcthts_2024W45_Datim ID_idx";


--
-- Name: pmtcthts_2024W45_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_pmtcthts ATTACH PARTITION public."pmtcthts_2024W45_datimid_period_end_date_idx";


--
-- Name: pmtcthts_2024W45_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W45_period_idx";


--
-- Name: pmtcthts_2024W45_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_startdateenddate_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W45_period_start_date_period_end_date_idx";


--
-- Name: pmtcthts_2024W46_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtcthts_weekly ATTACH PARTITION public."pmtcthts_2024W46_Datim ID_idx";


--
-- Name: pmtcthts_2024W46_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_pmtcthts ATTACH PARTITION public."pmtcthts_2024W46_datimid_period_end_date_idx";


--
-- Name: pmtcthts_2024W46_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W46_period_idx";


--
-- Name: pmtcthts_2024W46_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_startdateenddate_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W46_period_start_date_period_end_date_idx";


--
-- Name: pmtcthts_2024W47_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtcthts_weekly ATTACH PARTITION public."pmtcthts_2024W47_Datim ID_idx";


--
-- Name: pmtcthts_2024W47_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_pmtcthts ATTACH PARTITION public."pmtcthts_2024W47_datimid_period_end_date_idx";


--
-- Name: pmtcthts_2024W47_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W47_period_idx";


--
-- Name: pmtcthts_2024W47_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_startdateenddate_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W47_period_start_date_period_end_date_idx";


--
-- Name: pmtcthts_2024W48_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtcthts_weekly ATTACH PARTITION public."pmtcthts_2024W48_Datim ID_idx";


--
-- Name: pmtcthts_2024W48_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_pmtcthts ATTACH PARTITION public."pmtcthts_2024W48_datimid_period_end_date_idx";


--
-- Name: pmtcthts_2024W48_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W48_period_idx";


--
-- Name: pmtcthts_2024W48_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_startdateenddate_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W48_period_start_date_period_end_date_idx";


--
-- Name: pmtcthts_2024W49_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtcthts_weekly ATTACH PARTITION public."pmtcthts_2024W49_Datim ID_idx";


--
-- Name: pmtcthts_2024W49_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_pmtcthts ATTACH PARTITION public."pmtcthts_2024W49_datimid_period_end_date_idx";


--
-- Name: pmtcthts_2024W49_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W49_period_idx";


--
-- Name: pmtcthts_2024W49_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_startdateenddate_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W49_period_start_date_period_end_date_idx";


--
-- Name: pmtcthts_2024W4_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtcthts_weekly ATTACH PARTITION public."pmtcthts_2024W4_Datim ID_idx";


--
-- Name: pmtcthts_2024W4_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_pmtcthts ATTACH PARTITION public."pmtcthts_2024W4_datimid_period_end_date_idx";


--
-- Name: pmtcthts_2024W4_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W4_period_idx";


--
-- Name: pmtcthts_2024W4_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_startdateenddate_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W4_period_start_date_period_end_date_idx";


--
-- Name: pmtcthts_2024W50_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtcthts_weekly ATTACH PARTITION public."pmtcthts_2024W50_Datim ID_idx";


--
-- Name: pmtcthts_2024W50_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_pmtcthts ATTACH PARTITION public."pmtcthts_2024W50_datimid_period_end_date_idx";


--
-- Name: pmtcthts_2024W50_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W50_period_idx";


--
-- Name: pmtcthts_2024W50_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_startdateenddate_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W50_period_start_date_period_end_date_idx";


--
-- Name: pmtcthts_2024W51_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtcthts_weekly ATTACH PARTITION public."pmtcthts_2024W51_Datim ID_idx";


--
-- Name: pmtcthts_2024W51_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_pmtcthts ATTACH PARTITION public."pmtcthts_2024W51_datimid_period_end_date_idx";


--
-- Name: pmtcthts_2024W51_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W51_period_idx";


--
-- Name: pmtcthts_2024W51_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_startdateenddate_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W51_period_start_date_period_end_date_idx";


--
-- Name: pmtcthts_2024W52_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtcthts_weekly ATTACH PARTITION public."pmtcthts_2024W52_Datim ID_idx";


--
-- Name: pmtcthts_2024W52_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_pmtcthts ATTACH PARTITION public."pmtcthts_2024W52_datimid_period_end_date_idx";


--
-- Name: pmtcthts_2024W52_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W52_period_idx";


--
-- Name: pmtcthts_2024W52_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_startdateenddate_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W52_period_start_date_period_end_date_idx";


--
-- Name: pmtcthts_2024W5_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtcthts_weekly ATTACH PARTITION public."pmtcthts_2024W5_Datim ID_idx";


--
-- Name: pmtcthts_2024W5_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_pmtcthts ATTACH PARTITION public."pmtcthts_2024W5_datimid_period_end_date_idx";


--
-- Name: pmtcthts_2024W5_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W5_period_idx";


--
-- Name: pmtcthts_2024W5_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_startdateenddate_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W5_period_start_date_period_end_date_idx";


--
-- Name: pmtcthts_2024W6_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtcthts_weekly ATTACH PARTITION public."pmtcthts_2024W6_Datim ID_idx";


--
-- Name: pmtcthts_2024W6_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_pmtcthts ATTACH PARTITION public."pmtcthts_2024W6_datimid_period_end_date_idx";


--
-- Name: pmtcthts_2024W6_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W6_period_idx";


--
-- Name: pmtcthts_2024W6_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_startdateenddate_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W6_period_start_date_period_end_date_idx";


--
-- Name: pmtcthts_2024W7_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtcthts_weekly ATTACH PARTITION public."pmtcthts_2024W7_Datim ID_idx";


--
-- Name: pmtcthts_2024W7_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_pmtcthts ATTACH PARTITION public."pmtcthts_2024W7_datimid_period_end_date_idx";


--
-- Name: pmtcthts_2024W7_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W7_period_idx";


--
-- Name: pmtcthts_2024W7_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_startdateenddate_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W7_period_start_date_period_end_date_idx";


--
-- Name: pmtcthts_2024W8_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtcthts_weekly ATTACH PARTITION public."pmtcthts_2024W8_Datim ID_idx";


--
-- Name: pmtcthts_2024W8_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_pmtcthts ATTACH PARTITION public."pmtcthts_2024W8_datimid_period_end_date_idx";


--
-- Name: pmtcthts_2024W8_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W8_period_idx";


--
-- Name: pmtcthts_2024W8_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_startdateenddate_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W8_period_start_date_period_end_date_idx";


--
-- Name: pmtcthts_2024W9_Datim ID_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_datim_pmtcthts_weekly ATTACH PARTITION public."pmtcthts_2024W9_Datim ID_idx";


--
-- Name: pmtcthts_2024W9_datimid_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.datimidperiodenddate_pmtcthts ATTACH PARTITION public."pmtcthts_2024W9_datimid_period_end_date_idx";


--
-- Name: pmtcthts_2024W9_period_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_period_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W9_period_idx";


--
-- Name: pmtcthts_2024W9_period_start_date_period_end_date_idx; Type: INDEX ATTACH; Schema: public; Owner: lamisplus_etl
--

ALTER INDEX public.idx_startdateenddate_pmtct_hts ATTACH PARTITION public."pmtcthts_2024W9_period_start_date_period_end_date_idx";


--
-- Name: TABLE cte_monitoring; Type: ACL; Schema: maternal_cohort; Owner: lamisplus_etl
--

GRANT SELECT ON TABLE maternal_cohort.cte_monitoring TO isaac;


--
-- Name: TABLE maternal_cohort_monitoring; Type: ACL; Schema: maternal_cohort; Owner: lamisplus_etl
--

GRANT SELECT ON TABLE maternal_cohort.maternal_cohort_monitoring TO isaac;


--
-- Name: TABLE central_data_element_pmtct; Type: ACL; Schema: pmtct_hts; Owner: lamisplus_etl
--

GRANT SELECT ON TABLE pmtct_hts.central_data_element_pmtct TO isaac;


--
-- Name: TABLE period; Type: ACL; Schema: pmtct_hts; Owner: lamisplus_etl
--

GRANT SELECT ON TABLE pmtct_hts.period TO isaac;


--
-- Name: TABLE pmtct_hts_monitoring; Type: ACL; Schema: pmtct_hts; Owner: lamisplus_etl
--

GRANT SELECT ON TABLE pmtct_hts.pmtct_hts_monitoring TO isaac;


--
-- Name: TABLE aggregate_flatfile; Type: ACL; Schema: public; Owner: emeka
--

GRANT SELECT ON TABLE public.aggregate_flatfile TO isaac;
GRANT SELECT ON TABLE public.aggregate_flatfile TO ojee;


--
-- Name: TABLE central_category_option_combo; Type: ACL; Schema: public; Owner: lamisplus_etl
--

GRANT SELECT ON TABLE public.central_category_option_combo TO isaac;
GRANT SELECT ON TABLE public.central_category_option_combo TO ojee;


--
-- Name: TABLE central_data_element; Type: ACL; Schema: public; Owner: lamisplus_etl
--

GRANT SELECT ON TABLE public.central_data_element TO isaac;
GRANT SELECT ON TABLE public.central_data_element TO ojee;


--
-- Name: TABLE central_partner_mapping; Type: ACL; Schema: public; Owner: lamisplus_etl
--

GRANT SELECT ON TABLE public.central_partner_mapping TO isaac;
GRANT SELECT ON TABLE public.central_partner_mapping TO ojee;


--
-- Name: TABLE maternal_cohort; Type: ACL; Schema: public; Owner: lamisplus_etl
--

GRANT SELECT ON TABLE public.maternal_cohort TO isaac;


--
-- Name: TABLE partner_attribute_combo; Type: ACL; Schema: public; Owner: lamisplus_etl
--

GRANT SELECT ON TABLE public.partner_attribute_combo TO isaac;
GRANT SELECT ON TABLE public.partner_attribute_combo TO ojee;


--
-- Name: TABLE pmtct_hts; Type: ACL; Schema: public; Owner: lamisplus_etl
--

GRANT SELECT ON TABLE public.pmtct_hts TO isaac;


--
-- PostgreSQL database dump complete
--

