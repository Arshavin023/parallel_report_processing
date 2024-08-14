--
-- Name: proc_bio_data(); Type: PROCEDURE; Schema: expanded_radet; Owner: lamisplus_etl
--
CREATE OR REPLACE PROCEDURE expanded_radet.proc_bio_data()
    LANGUAGE plpgsql
    AS $_$DECLARE start_time TIMESTAMP;
DECLARE end_time TIMESTAMP;
BEGIN

SELECT TIMEOFDAY() INTO start_time;

drop table if exists expanded_radet.cte_bio_data_new;

create table expanded_radet.cte_bio_data_new AS
select * from dblink('db_link_ods',
'SELECT DISTINCT ON (p.uuid, p.ods_datim_id) p.uuid AS personUuid,
p.ods_datim_id AS bio_ods_datim_id,p.hospital_number AS hospitalNumber,
h.unique_id AS uniqueId,EXTRACT(YEAR FROM AGE(NOW(), CAST(p.date_of_birth AS DATE))) AS age,
INITCAP(p.sex) AS gender,p.date_of_birth AS dateOfBirth,facility.name AS facilityName,
facility_lga.name AS lga,facility_state.name AS state,boui.code AS datimId,
tgroup.display AS targetGroup,eSetting.display AS enrollmentSetting,hac.visit_date AS artStartDate, 
hr.description AS regimenAtStart,p.date_of_registration AS dateOfRegistration,h.date_of_registration AS dateOfEnrollment, 
h.ovc_number AS ovcUniqueId,h.house_hold_number AS householdUniqueNo,ecareEntry.display AS careEntry, 
hrt.description AS regimenLineAtStart
FROM ods_patient_person p 
    LEFT OUTER JOIN ods_base_organisation_unit facility ON facility.id = p.facility_id  AND facility.ods_datim_id = p.ods_datim_id
    LEFT OUTER JOIN ods_base_organisation_unit facility_lga ON facility_lga.id = facility.parent_organisation_unit_id  AND facility_lga.ods_datim_id = facility.ods_datim_id
    LEFT OUTER JOIN ods_base_organisation_unit facility_state ON facility_state.id = facility_lga.parent_organisation_unit_id  AND  facility_state.ods_datim_id = facility_lga.ods_datim_id
    LEFT OUTER JOIN ods_base_organisation_unit_identifier boui ON boui.organisation_unit_id = p.facility_id  AND boui.ods_datim_id = p.ods_datim_id
    AND boui.name = ''DATIM_ID''
    INNER JOIN ods_hiv_enrollment h ON h.person_uuid = p.uuid  AND h.ods_datim_id = p.ods_datim_id
    LEFT OUTER JOIN ods_base_application_codeset tgroup ON tgroup.id = h.target_group_id AND tgroup.ods_datim_id = h.ods_datim_id
    LEFT OUTER JOIN ods_base_application_codeset eSetting ON eSetting.id = h.enrollment_setting_id AND eSetting.ods_datim_id = h.ods_datim_id
    LEFT OUTER JOIN ods_base_application_codeset ecareEntry ON ecareEntry.id = h.entry_point_id AND ecareEntry.ods_datim_id = h.ods_datim_id
    INNER JOIN ods_hiv_art_clinical hac ON hac.hiv_enrollment_uuid = h.uuid  AND hac.ods_datim_id = h.ods_datim_id
    AND hac.archived = 0 
    INNER JOIN ods_hiv_regimen hr ON hr.id = hac.regimen_id  AND hr.ods_datim_id = hac.ods_datim_id
    LEFT OUTER JOIN ods_hiv_regimen_type hrt ON hrt.id = hac.regimen_type_id  AND hrt.ods_datim_id = hac.ods_datim_id
WHERE h.archived = 0 AND p.archived = 0 
    --AND hac.is_commencement = ''t''
    ----AND h.facility_id = ?1 
    AND hac.is_commencement = TRUE AND hac.visit_date >= ''1980-01-01'' ---$2
    AND hac.visit_date <= (select date from expanded_radet.period where is_active)  ---$3') 
AS sm(personuuid character varying,bio_ods_datim_id character varying(255),
	  hospitalnumber character varying,uniqueid character varying,age numeric,
	  gender text,dateofbirth date,facilityname character varying,lga character varying,
	  state character varying,datimid character varying,targetgroup character varying,
	  enrollmentsetting character varying,artstartdate date,regimenatstart character varying,
	  dateofregistration date,dateofenrollment date,ovcuniqueid character varying,
	  householduniqueno character varying,careentry character varying,
	  regimenlineatstart character varying);

drop table if exists expanded_radet.cte_bio_data;
alter table expanded_radet.cte_bio_data_new rename to cte_bio_data;

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time) 
VALUES ('cte_bio_date', start_time,end_time);

END
$_$;


ALTER PROCEDURE expanded_radet.proc_bio_data() OWNER TO lamisplus_etl;



--
-- Name: proc_biometric(); Type: PROCEDURE; Schema: expanded_radet; Owner: lamisplus_etl
--

CREATE OR REPLACE PROCEDURE expanded_radet.proc_biometric()
    LANGUAGE plpgsql
    AS $$DECLARE start_time TIMESTAMP;
DECLARE end_time TIMESTAMP;
BEGIN

SELECT TIMEOFDAY() INTO start_time;

DROP TABLE if exists expanded_radet.cte_biometric_new;

CREATE TABLE expanded_radet.cte_biometric_new AS
select * from dblink('db_link_ods','SELECT DISTINCT ON (he.person_uuid, he.ods_datim_id) he.person_uuid AS person_uuid60,
he.ods_datim_id as biome_ods_datim_id,biometric_count.enrollment_date AS dateBiometricsEnrolled, 
biometric_count.count AS numberOfFingersCaptured,cast(recapture_count.recapture_date as date) AS dateBiometricsRecaptured,
recapture_count.count AS numberOfFingersRecaptured,bst.biometric_status AS biometricStatus, 
bst.status_date
FROM ods_hiv_enrollment he 
  LEFT JOIN (SELECT DISTINCT on (b.person_uuid, b.ods_datim_id) b.person_uuid, b.ods_datim_id,
	  CASE WHEN COUNT(b.person_uuid) > 10 THEN 10 ELSE COUNT(b.person_uuid) END, 
	  MAX(enrollment_date) enrollment_date 
	FROM ods_biometric b 
	WHERE archived = 0 AND (recapture = 0 or recapture is null) 
	GROUP BY b.person_uuid, b.ods_datim_id
  ) biometric_count ON biometric_count.person_uuid = he.person_uuid AND
  biometric_count.ods_datim_id = he.ods_datim_id
  LEFT JOIN (SELECT DISTINCT ON(r.person_uuid, r.ods_datim_id)r.person_uuid, r.ods_datim_id,
	  CASE WHEN COUNT(r.person_uuid) > 10 THEN 10 ELSE COUNT(r.person_uuid) END, 
	  MAX(enrollment_date) recapture_date 
	FROM ods_biometric r 
	WHERE archived = 0 AND recapture = 1 
	GROUP BY r.person_uuid, r.ods_datim_id
  ) recapture_count ON recapture_count.person_uuid = he.person_uuid 
  LEFT JOIN (SELECT DISTINCT ON (person_id, ods_datim_id) person_id, ods_datim_id, biometric_status,
MAX(status_date) OVER (PARTITION BY person_id, ods_datim_id  ORDER BY status_date DESC) AS status_date 
FROM ods_hiv_status_tracker 
	WHERE archived=0  --AND facility_id=?1
	  ) bst ON bst.person_id = he.person_uuid AND bst.ods_datim_id = he.ods_datim_id 
	WHERE he.archived = 0') 
AS sm(person_uuid60 character varying,biome_ods_datim_id character varying(255),datebiometricsenrolled date,
    numberoffingerscaptured bigint,datebiometricsrecaptured date,numberoffingersrecaptured bigint,
    biometricstatus character varying,status_date date);

drop table if exists expanded_radet.cte_biometric;
alter table expanded_radet.cte_biometric_new rename to cte_biometric;

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time) 
VALUES ('biometric', start_time,end_time);

END
$$;

ALTER PROCEDURE expanded_radet.proc_biometric() OWNER TO lamisplus_etl;



--
-- Name: proc_carecardcd4(); Type: PROCEDURE; Schema: expanded_radet; Owner: lamisplus_etl
--

CREATE OR REPLACE PROCEDURE expanded_radet.proc_carecardcd4()
    LANGUAGE plpgsql
    AS $$DECLARE end_time TIMESTAMP;
DECLARE start_time TIMESTAMP;
BEGIN

SELECT TIMEOFDAY() INTO start_time;

DROP TABLE if exists expanded_radet.cte_carecardcd4_new;

CREATE TABLE expanded_radet.cte_carecardcd4_new AS
select * from dblink('db_link_ods',
'SELECT visit_date,coalesce(cast(cd_4 as varchar),cd4_semi_quantitative) as cd_4, 
person_uuid AS cccd4_person_uuid,ods_datim_id as care_ods_datim_id
FROM public.ods_hiv_art_clinical 
WHERE is_commencement is true AND archived = 0 
AND cd_4 != ''0'' AND visit_date <= (select date from expanded_radet.period where is_active) ---?3') 
AS sm(visit_date date,cd_4 character varying,cccd4_person_uuid character varying,care_ods_datim_id character varying(255));

drop table if exists expanded_radet.cte_carecardcd4;
alter table expanded_radet.cte_carecardcd4_new rename to cte_carecardcd4;

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time) 
VALUES ('carecardcd4', start_time,end_time);
END
$$;

ALTER PROCEDURE expanded_radet.proc_carecardcd4() OWNER TO lamisplus_etl;


--
-- Name: proc_case_manager(); Type: PROCEDURE; Schema: expanded_radet; Owner: lamisplus_etl
--
CREATE OR REPLACE PROCEDURE expanded_radet.proc_case_manager()
    LANGUAGE plpgsql
    AS $$DECLARE start_time TIMESTAMP;
DECLARE end_time TIMESTAMP;
BEGIN

SELECT TIMEOFDAY() INTO start_time;

DROP TABLE if exists expanded_radet.cte_case_manager_new;

CREATE TABLE expanded_radet.cte_case_manager_new AS
select * from dblink('db_link_ods',
'SELECT DISTINCT ON (cmp.person_uuid, cmp.ods_datim_id) person_uuid AS caseperson,
	cmp.ods_datim_id as case_ods_datim_id, cmp.case_manager_id, 
    CONCAT(cm.first_name, '' '', cm.last_name) AS caseManager 
  FROM (
      SELECT person_uuid,ods_datim_id,case_manager_id, 
        ROW_NUMBER () OVER (PARTITION BY person_uuid, ods_datim_id ORDER BY id DESC) 
      FROM ods_case_manager_patients
    ) cmp 
    INNER JOIN ods_case_manager cm ON cm.id = cmp.case_manager_id 
	AND cm.ods_datim_id = cmp.ods_datim_id
  WHERE cmp.row_number = 1')
AS sm(visit_date date,cd_4 character varying,
	  cccd4_person_uuid character varying,care_ods_datim_id character varying(255));

drop table if exists expanded_radet.cte_case_manager;
alter table expanded_radet.cte_case_manager_new rename to cte_case_manager;

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time) 
VALUES ('case_manager', start_time,end_time);
END
$$;

ALTER PROCEDURE expanded_radet.proc_case_manager() OWNER TO lamisplus_etl;


--
-- Name: proc_cervical_cancer(); Type: PROCEDURE; Schema: expanded_radet; Owner: lamisplus_etl
--

CREATE OR REPLACE PROCEDURE expanded_radet.proc_cervical_cancer()
    LANGUAGE plpgsql
    AS $$DECLARE end_time TIMESTAMP;
DECLARE start_time TIMESTAMP;
BEGIN

SELECT TIMEOFDAY() INTO start_time;

DROP TABLE if exists expanded_radet.cte_cervical_cancer_new;

CREATE TABLE expanded_radet.cte_cervical_cancer_new AS 
select * from dblink('db_link_ods',
'select * from (select  DISTINCT ON (ho.person_uuid, ho.ods_datim_id) ho.person_uuid AS person_uuid90,
ho.ods_datim_id as cerv_ods_datim_id,
ho.date_of_observation AS dateOfCervicalCancerScreening, 
ho.data ->> ''screenTreatmentMethodDate'' AS treatmentMethodDate,cc_type.display AS cervicalCancerScreeningType, 
cc_method.display AS cervicalCancerScreeningMethod, cc_trtm.display AS cervicalCancerTreatmentScreened, 
cc_result.display AS resultOfCervicalCancerScreening, 
ROW_NUMBER() OVER (PARTITION BY ho.person_uuid ORDER BY ho.date_of_observation DESC) AS row 
from ods_hiv_observation ho 
LEFT JOIN ods_base_application_codeset cc_type ON cc_type.code = CAST(ho.data ->> ''screenType'' AS VARCHAR) 
AND cc_type.ods_datim_id=ho.ods_datim_id
LEFT JOIN ods_base_application_codeset cc_method ON cc_method.code = CAST(ho.data ->> ''screenMethod'' AS VARCHAR)
AND cc_method.ods_datim_id=ho.ods_datim_id
LEFT JOIN ods_base_application_codeset cc_result ON cc_result.code = CAST(ho.data ->> ''screeningResult'' AS VARCHAR) 
AND cc_result.ods_datim_id=ho.ods_datim_id
LEFT JOIN ods_base_application_codeset cc_trtm ON cc_trtm.code = CAST(ho.data ->> ''screenTreatment'' AS VARCHAR) 
AND cc_trtm.ods_datim_id=ho.ods_datim_id
where ho.archived = 0 and type = ''Cervical cancer'') as cc where row = 1')
AS sm( person_uuid90 character varying,cerv_ods_datim_id character varying(255),
    dateofcervicalcancerscreening date,treatmentmethoddate text,cervicalcancerscreeningtype character varying,
    cervicalcancerscreeningmethod character varying,cervicalcancertreatmentscreened character varying,
    resultofcervicalcancerscreening character varying,"row" bigint);

drop table if exists expanded_radet.cte_cervical_cancer;
alter table expanded_radet.cte_cervical_cancer_new rename to cte_cervical_cancer;

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time) 
VALUES ('cervical_cancer', start_time,end_time);
END
$$;

ALTER PROCEDURE expanded_radet.proc_cervical_cancer() OWNER TO lamisplus_etl;



--
-- Name: proc_client_verification(); Type: PROCEDURE; Schema: expanded_radet; Owner: lamisplus_etl
--

CREATE OR REPLACE PROCEDURE expanded_radet.proc_client_verification()
    LANGUAGE plpgsql
    AS $_$DECLARE end_time TIMESTAMP;
DECLARE start_time TIMESTAMP;
BEGIN

SELECT TIMEOFDAY() INTO start_time;

DROP TABLE if exists expanded_radet.cte_client_verification_new;

CREATE TABLE expanded_radet.cte_client_verification_new AS 
select * from dblink('db_link_ods',
'SELECT * FROM (
select DISTINCT ON (person_uuid, ods_datim_id)person_uuid as client_person_uuid, 
		ods_datim_id as client_ods_datim_id,
	data->''attempt''->0->>''outcome'' AS clientVerificationOutCome, 
	data->''attempt''->0->>''outcome'' AS clientVerificationStatus,
CAST (data->''attempt''->0->>''dateOfAttempt'' AS DATE) AS dateOfOutcome,
ROW_NUMBER() OVER ( PARTITION BY person_uuid ORDER BY CAST(data->''attempt''->0->>''dateOfAttempt'' AS DATE) DESC)
from ods_hiv_observation where type = ''Client Verification''
AND archived = 0
AND CAST(data->''attempt''->0->>''dateOfAttempt'' AS DATE) <= (select date from expanded_radet.period where is_active) --$3 
AND CAST(data->''attempt''->0->>''dateOfAttempt'' AS DATE) >= ''1980-01-01'' --$2 
--AND facility_id = ?1
) clientVerification WHERE row_number = 1
AND dateOfOutcome IS NOT NULL') 
AS sm(client_person_uuid character varying,client_ods_datim_id character varying(255),
    clientverificationoutcome text,clientverificationstatus text,
    dateofoutcome date,row_number bigint);

drop table if exists expanded_radet.cte_client_verification;
alter table expanded_radet.cte_client_verification_new rename to cte_client_verification;

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time) 
VALUES ('client_verification', start_time,end_time);
END
$_$;

ALTER PROCEDURE expanded_radet.proc_client_verification() OWNER TO lamisplus_etl;


--
-- Name: proc_cryptocol_antigen(); Type: PROCEDURE; Schema: expanded_radet; Owner: lamisplus_etl
--
CREATE OR REPLACE PROCEDURE expanded_radet.proc_cryptocol_antigen()
    LANGUAGE plpgsql
    AS $$DECLARE end_time TIMESTAMP;
DECLARE start_time TIMESTAMP;
BEGIN
SELECT TIMEOFDAY() INTO start_time;
DROP TABLE if exists expanded_radet.cte_cryptococal_antigen_new;
CREATE TABLE expanded_radet.cte_cryptococal_antigen_new AS
SELECT * from dblink('db_link_ods',
'select *  from (
  select DISTINCT ON (lr.patient_uuid, lr.ods_datim_id) lr.patient_uuid as personuuid12,
	lr.ods_datim_id as crypt_ods_datim_id,
	CAST(lr.date_result_reported AS DATE) AS dateOfLastCrytococalAntigen, 
	lr.result_reported AS lastCrytococalAntigen , 
	ROW_NUMBER() OVER (PARTITION BY lr.patient_uuid, lr.ods_datim_id ORDER BY lr.date_result_reported DESC) as rowNum 
  from public.ods_laboratory_test lt inner join ods_laboratory_result lr on lr.test_id = lt.id 
  AND lr.ods_datim_id = lt.ods_datim_id
  where lab_test_id = 52 OR lab_test_id = 69 OR lab_test_id = 70 AND lr.date_result_reported IS NOT NULL 
   AND lr.date_result_reported <= (select date from expanded_radet.period where is_active) ---?3 
   AND lr.date_result_reported >= ''1980-01-01'' ---?2 
	AND lr.result_reported is NOT NULL AND lr.archived = ''0'') dt 
	where rowNum = 1')
AS sm(personuuid12 character varying,crypt_ods_datim_id character varying(255),
    dateoflastcrytococalantigen date,lastcrytococalantigen character varying,
    rownum bigint);

drop table if exists expanded_radet.cte_cryptococal_antigen;
alter table expanded_radet.cte_cryptococal_antigen_new rename to cte_cryptococal_antigen;

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time) 
VALUES ('cryptocol_antigen', start_time,end_time);
END
$$;

ALTER PROCEDURE expanded_radet.proc_cryptocol_antigen() OWNER TO lamisplus_etl;



--
-- Name: proc_current_clinical(); Type: PROCEDURE; Schema: expanded_radet; Owner: lamisplus_etl
--
CREATE OR REPLACE PROCEDURE expanded_radet.proc_current_clinical()
    LANGUAGE plpgsql
    AS $$DECLARE start_time TIMESTAMP;
DECLARE end_time TIMESTAMP;
BEGIN
SELECT TIMEOFDAY() INTO start_time;

DROP TABLE if exists expanded_radet.cte_current_clinical_new;
CREATE TABLE expanded_radet.cte_current_clinical_new AS
SELECT * FROM dblink('db_link_ods',
'SELECT DISTINCT ON (tvs.person_uuid, tvs.ods_datim_id) tvs.person_uuid AS person_uuid10, 
tvs.ods_datim_id as clin_ods_datim_id,body_weight AS currentWeight,tbs.display AS tbStatus1, 
bac.display AS currentClinicalStage,
(CASE 
 --WHEN INITCAP(pp.sex) = ''Male'' THEN NULL
 WHEN preg.display IS NOT NULL THEN preg.display ELSE hac.pregnancy_status END
) AS pregnancyStatus, 
CASE WHEN hac.tb_screen IS NOT NULL THEN CAST(hac.visit_date AS DATE) ELSE NULL END AS dateOfTbScreened1 
FROM ods_triage_vital_sign tvs 
INNER JOIN expanded_radet.cte_sub_triage_current_clinical AS current_triage ON current_triage.MAXDATE = CAST(tvs.capture_date AS DATE) 
AND current_triage.person_uuid = tvs.person_uuid AND current_triage.ods_datim_id = tvs.ods_datim_id
INNER JOIN ods_hiv_art_clinical hac ON tvs.uuid = hac.vital_sign_uuid AND tvs.ods_datim_id = hac.ods_datim_id
INNER JOIN expanded_radet.cte_sub_date_current_clinical AS current_clinical_date ON current_clinical_date.MAXDATE = CAST(hac.visit_date AS DATE)
AND current_clinical_date.person_uuid = hac.person_uuid AND current_clinical_date.ods_datim_id = hac.ods_datim_id
INNER JOIN ods_hiv_enrollment he ON he.person_uuid = hac.person_uuid AND he.ods_datim_id = hac.ods_datim_id
LEFT JOIN ods_base_application_codeset bac ON bac.id = hac.clinical_stage_id AND bac.ods_datim_id = hac.ods_datim_id
LEFT JOIN ods_base_application_codeset preg ON preg.code = hac.pregnancy_status AND preg.ods_datim_id = hac.ods_datim_id
LEFT JOIN ods_base_application_codeset tbs ON tbs.id = CAST(hac.tb_status AS INTEGER) AND tbs.ods_datim_id = hac.ods_datim_id
--LEFT JOIN patient_person pp ON tvs.person_uuid = pp.uuid and tvs.ods_datim_id=pp.ods_datim_id
WHERE hac.archived = 0 AND he.archived = 0 
AND hac.visit_date <= (SELECT date FROM expanded_radet.period WHERE is_active) ---?3')
AS sm(person_uuid10 character varying,clin_ods_datim_id character varying(255),
currentweight double precision,tbstatus1 character varying,currentclinicalstage character varying,
pregnancystatus character varying,dateoftbscreened1 date);

drop table if exists expanded_radet.cte_current_clinical;
alter table expanded_radet.cte_current_clinical_new rename to cte_current_clinical;

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time) 
VALUES ('cte_current_clinical', start_time,end_time);
END
$$;
ALTER PROCEDURE expanded_radet.proc_current_clinical() OWNER TO lamisplus_etl;


--
-- Name: proc_current_status(); Type: PROCEDURE; Schema: expanded_radet; Owner: lamisplus_etl
--
CREATE OR REPLACE PROCEDURE expanded_radet.proc_current_status()
    LANGUAGE plpgsql
    AS $$DECLARE end_time TIMESTAMP;
DECLARE start_time TIMESTAMP;
BEGIN

SELECT TIMEOFDAY() INTO start_time;
DROP TABLE if exists expanded_radet.cte_current_status_new;
CREATE TABLE expanded_radet.cte_current_status_new AS 
SELECT * FROM dblink('db_link_ods',
'SELECT DISTINCT ON (pharmacy.person_uuid, pharmacy.ods_datim_id) pharmacy.person_uuid AS cuPersonUuid,
	pharmacy.maxdate AS last_visit_date, pharmacy.refill_period,
    pharmacy.ods_datim_id as cus_ods_datim_id, 
    ( CASE WHEN stat.hiv_status ILIKE ''%DEATH%'' OR stat.hiv_status ILIKE ''%Died%'' THEN ''Died'' 
	  WHEN(stat.status_date > pharmacy.maxdate 
	  AND (stat.hiv_status ILIKE ''%stop%'' OR stat.hiv_status ILIKE ''%out%'' OR stat.hiv_status ILIKE ''%Invalid %'')
		) THEN stat.hiv_status ELSE pharmacy.status END
    ) AS status, 
    (CASE WHEN stat.hiv_status ILIKE ''%DEATH%'' 
      OR stat.hiv_status ILIKE ''%Died%'' THEN CAST(stat.status_date AS DATE) 
	  WHEN(stat.status_date > pharmacy.maxdate 
        AND (stat.hiv_status ILIKE ''%stop%'' OR stat.hiv_status ILIKE ''%out%'' 
          OR stat.hiv_status ILIKE ''%Invalid %'')
      ) THEN CAST(stat.status_date AS DATE) ELSE pharmacy.visit_date END
    ) AS status_date, stat.cause_of_death, stat.va_cause_of_death 
  FROM 
    (SELECT hp.refill_period,
        (CASE WHEN CAST(hp.visit_date AS DATE) + CAST(hp.refill_period AS INTEGER) + INTERVAL ''29 day'' < (SELECT date FROM expanded_radet.period WHERE is_active) ---?3 next_appointment + refill_period + 29 days
          THEN ''IIT'' ELSE ''Active'' END) status, 
        (CASE WHEN CAST(hp.visit_date AS DATE) + CAST(hp.refill_period AS INTEGER) + INTERVAL ''29 day'' < (SELECT date FROM expanded_radet.period WHERE is_active) ---?3 
          THEN CAST(hp.visit_date AS DATE) + CAST(hp.refill_period AS INTEGER) + INTERVAL ''29 day'' ELSE CAST(hp.visit_date AS DATE) END
        ) AS visit_date, 
        hp.person_uuid, hp.ods_datim_id, MAXDATE 
      FROM ods_hiv_art_pharmacy hp 
        INNER JOIN (SELECT hap.person_uuid,hap.ods_datim_id,hap.visit_date AS MAXDATE, 
            ROW_NUMBER() OVER (PARTITION BY hap.person_uuid, hap.ods_datim_id ORDER BY hap.visit_date DESC) as rnkkk3 
          FROM public.ods_hiv_art_pharmacy hap 
            INNER JOIN public.ods_hiv_art_pharmacy_regimens pr ON pr.art_pharmacy_id = hap.id AND pr.ods_datim_id = hap.ods_datim_id
            INNER JOIN public.ods_hiv_enrollment h ON h.person_uuid = hap.person_uuid AND h.ods_datim_id = hap.ods_datim_id
            AND h.archived = 0 
            INNER JOIN public.ods_hiv_regimen r on r.id = pr.regimens_id AND r.ods_datim_id = pr.ods_datim_id
            INNER JOIN public.ods_hiv_regimen_type rt on rt.id = r.regimen_type_id AND rt.ods_datim_id = r.ods_datim_id
          WHERE 
            r.regimen_type_id in (1, 2, 3, 4, 14) 
            AND hap.archived = 0 
            AND hap.visit_date <= (SELECT date FROM expanded_radet.period WHERE is_active) ---?3
        ) MAX ON MAX.MAXDATE = hp.visit_date 
        AND MAX.person_uuid = hp.person_uuid AND MAX.ods_datim_id = hp.ods_datim_id
        AND MAX.rnkkk3 = 1 AND hp.refill_period is not null
       INNER JOIN public.ods_hiv_art_pharmacy_regimens pr ON pr.art_pharmacy_id = hp.id AND pr.ods_datim_id = hp.ods_datim_id
	   INNER JOIN public.ods_hiv_regimen r on r.id = pr.regimens_id AND r.ods_datim_id = pr.ods_datim_id
       INNER JOIN public.ods_hiv_regimen_type rt on rt.id = r.regimen_type_id AND rt.ods_datim_id = r.ods_datim_id
      WHERE r.regimen_type_id in (1, 2, 3, 4, 14) AND hp.archived = 0 
	 AND hp.visit_date <= (SELECT date FROM expanded_radet.period WHERE is_active) ---?3
    ) pharmacy 
    LEFT JOIN (SELECT hst.hiv_status,hst.person_id,hst.ods_datim_id,hst.cause_of_death, 
        hst.va_cause_of_death,hst.status_date 
      FROM 
        (SELECT * 
          FROM 
            (SELECT DISTINCT ON (person_id, ods_datim_id) person_id, 
                ods_datim_id,status_date,cause_of_death,va_cause_of_death,hiv_status, 
                ROW_NUMBER() OVER (PARTITION BY person_id, ods_datim_id 
                  ORDER BY status_date DESC) 
              FROM ods_hiv_status_tracker 
              WHERE archived = 0 
               AND status_date <= (SELECT date FROM expanded_radet.period WHERE is_active) ---?3
            ) s 
			WHERE s.row_number = 1
        ) hst 
        INNER JOIN ods_hiv_enrollment he ON he.person_uuid = CAST(hst.person_id AS TEXT) AND he.ods_datim_id = hst.ods_datim_id
      WHERE hst.status_date <= (SELECT date FROM expanded_radet.period WHERE is_active) ---?3
    ) stat ON CAST(stat.person_id AS TEXT) = pharmacy.person_uuid AND stat.ods_datim_id = pharmacy.ods_datim_id')
AS sm(cupersonuuid character varying,last_visit_date date,refill_period integer,
    cus_ods_datim_id character varying(255),status text, status_date timestamp without time zone,
    cause_of_death character varying,va_cause_of_death character varying);

drop table if exists expanded_radet.cte_current_status;
alter table expanded_radet.cte_current_status_new rename to cte_current_status;

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time) 
VALUES ('cte_current_status', start_time,end_time);

END
$$;

ALTER PROCEDURE expanded_radet.proc_current_status() OWNER TO lamisplus_etl;



--
-- Name: proc_current_tb_result(); Type: PROCEDURE; Schema: expanded_radet; Owner: lamisplus_etl
--

CREATE OR REPLACE PROCEDURE expanded_radet.proc_current_tb_result()
    LANGUAGE plpgsql
    AS $$DECLARE end_time TIMESTAMP;
DECLARE start_time TIMESTAMP;
BEGIN

SELECT TIMEOFDAY() INTO start_time;

DROP TABLE if exists expanded_radet.cte_current_tb_result_new;

CREATE TABLE expanded_radet.cte_current_tb_result_new AS
SELECT * FROM dblink('db_link_ods',
'WITH tb_test as (
	SELECT DISTINCT ON (personTbResult, ods_datim_id)personTbResult, ods_datim_id as curr_ods_datim_id, 
	dateofTbDiagnosticResultReceived,
   coalesce(MAX(CASE WHEN lab_test_id = 65 THEN tbDiagnosticResult END),MAX(CASE WHEN lab_test_id = 51 THEN tbDiagnosticResult END),
           MAX(CASE WHEN lab_test_id = 66 THEN tbDiagnosticResult END),MAX(CASE WHEN lab_test_id = 64 THEN tbDiagnosticResult END),
           MAX(CASE WHEN lab_test_id = 67 THEN tbDiagnosticResult END),MAX(CASE WHEN lab_test_id = 68 THEN tbDiagnosticResult END)
       ) as tbDiagnosticResult ,
   coalesce(MAX(CASE WHEN lab_test_id = 65 THEN ''Gene Xpert'' END),MAX(CASE WHEN lab_test_id = 51 THEN ''TB-LAM'' END),
           MAX(CASE WHEN lab_test_id = 66 THEN ''Chest X-ray'' END), MAX(CASE WHEN lab_test_id = 64 THEN ''AFB microscopy'' END),
           MAX(CASE WHEN lab_test_id = 67 THEN ''Gene Xpert'' END), MAX(CASE WHEN lab_test_id = 58 THEN ''TB-LAM'' END)
       ) as tbDiagnosticTestType

        FROM (SELECT DISTINCT ON(sm.patient_uuid, sm.ods_datim_id)sm.patient_uuid as personTbResult,
			sm.ods_datim_id,sm.result_reported as tbDiagnosticResult,
 CAST(sm.date_result_reported AS DATE) as dateofTbDiagnosticResultReceived,
 lt.lab_test_id
     FROM ods_laboratory_result  sm
  INNER JOIN ods_laboratory_test  lt on sm.test_id = lt.id and sm.ods_datim_id = lt.ods_datim_id
     WHERE lt.lab_test_id IN (65,51,66,64) and sm.archived = ''0''
       AND sm.date_result_reported is not null
       --AND sm.facility_id = ?1
       AND sm.date_result_reported <= (select date from expanded_radet.period where is_active) ----?3
 ) as dt
        GROUP BY dt.personTbResult, dt.ods_datim_id, dt.dateofTbDiagnosticResultReceived
				)
   select * from (select *, row_number() over (partition by personTbResult, curr_ods_datim_id
         order by dateofTbDiagnosticResultReceived desc ) as rnk from tb_test) as dt
   where rnk = 1')
AS sm(persontbresult character varying,curr_ods_datim_id character varying(255),
    dateoftbdiagnosticresultreceived date,tbdiagnosticresult text,
    tbdiagnostictesttype text,rnk bigint);

drop table if exists expanded_radet.cte_current_tb_result;
alter table expanded_radet.cte_current_tb_result_new rename to cte_current_tb_result;

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time) 
VALUES ('cte_current_tb_result', start_time,end_time);
END
$$;

ALTER PROCEDURE expanded_radet.proc_current_tb_result() OWNER TO lamisplus_etl;



--
-- Name: proc_current_vl_result(); Type: PROCEDURE; Schema: expanded_radet; Owner: lamisplus_etl
--

CREATE OR REPLACE PROCEDURE expanded_radet.proc_current_vl_result()
    LANGUAGE plpgsql
    AS $$
DECLARE start_time TIMESTAMP; 
DECLARE end_time TIMESTAMP;
BEGIN

SELECT TIMEOFDAY() INTO start_time;

DROP TABLE if exists expanded_radet.cte_current_vl_result_new;
CREATE TABLE expanded_radet.cte_current_vl_result_new AS	
SELECT * FROM dblink('db_link_ods',
'SELECT dateOfCurrentViralLoadSample,patient_uuid as person_uuid130,
    ods_datim_id as cvl_ods_datim_id,facility_id as vlFacility,
    vlArchived, viralLoadIndication, currentViralLoad,
    dateOfCurrentViralLoad
FROM expanded_radet.sub_cte_current_vl_result
WHERE rank2 = 1 AND (vlArchived = 0 OR vlArchived IS NULL)')
AS sm(dateofcurrentviralloadsample timestamp without time zone,
    person_uuid130 character varying,cvl_ods_datim_id character varying(255),
    vlfacility integer,vlarchived integer,viralloadindication character varying,
    currentviralload character varying,dateofcurrentviralload timestamp without time zone);

DROP INDEX IF EXISTS expanded_radet.idx_cte_current_vl_result;
CREATE INDEX idx_cte_current_vl_result ON expanded_radet.cte_current_vl_result_new (person_uuid130, cvl_ods_datim_id);	

drop table if exists expanded_radet.cte_current_vl_result;
alter table expanded_radet.cte_current_vl_result_new rename to cte_current_vl_result;

SELECT TIMEOFDAY() INTO end_time; 
INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time)
VALUES ('sub_cte_current_vl_result', start_time,end_time);
END
$$;

ALTER PROCEDURE expanded_radet.proc_current_vl_result() OWNER TO lamisplus_etl;



--
-- Name: proc_dsd1(); Type: PROCEDURE; Schema: expanded_radet; Owner: lamisplus_etl
--
CREATE OR REPLACE PROCEDURE expanded_radet.proc_dsd1()
    LANGUAGE plpgsql
    AS $$DECLARE end_time TIMESTAMP;
DECLARE start_time TIMESTAMP;
BEGIN SELECT TIMEOFDAY() INTO start_time;

DROP TABLE if exists expanded_radet.cte_dsd1_new;

CREATE TABLE expanded_radet.cte_dsd1_new AS 
SELECT * FROM dblink('db_link_ods',
'select person_uuid as person_uuid_dsd_1, ods_datim_id as dsd1_ods_datim_id, dateOfDevolvement, modelDevolvedTo 
from (select Distinct on (d.person_uuid, d.ods_datim_id) person_uuid, d.ods_datim_id, d.date_devolved as dateOfDevolvement, bmt.display as modelDevolvedTo, 
       ROW_NUMBER() OVER (PARTITION BY d.person_uuid ORDER BY d.date_devolved ASC ) AS row 
	   from ods_dsd_devolvement d 
       left join ods_base_application_codeset bmt on bmt.code = d.dsd_type AND bmt.ods_datim_id = d.ods_datim_id
where d.archived = 0 and d.date_devolved between ''1980-01-01'' 
and (select date from expanded_radet.period where is_active)
) d1 where row = 1')
AS sm(person_uuid_dsd_1 character varying(255),dsd1_ods_datim_id character varying(255),
    dateofdevolvement date,modeldevolvedto character varying);

drop table if exists expanded_radet.cte_dsd1;
alter table expanded_radet.cte_dsd1_new rename to cte_dsd1;

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time) 
VALUES ('cte_dsd1', start_time,end_time);
END
$$;

ALTER PROCEDURE expanded_radet.proc_dsd1() OWNER TO lamisplus_etl;


--
-- Name: proc_dsd2(); Type: PROCEDURE; Schema: expanded_radet; Owner: lamisplus_etl
--

CREATE PROCEDURE expanded_radet.proc_dsd2()
    LANGUAGE plpgsql
    AS $$DECLARE end_time TIMESTAMP;
DECLARE start_time TIMESTAMP;
BEGIN
	SELECT TIMEOFDAY() INTO start_time;

DROP TABLE if exists expanded_radet.cte_dsd2_new;

CREATE TABLE expanded_radet.cte_dsd2_new AS 
select person_uuid as person_uuid_dsd_2, ods_datim_id as dsd2_ods_datim_id, dateOfCurrentDSD, currentDSDModel, dateReturnToSite 
from (select DISTINCT ON (d.person_uuid, d.ods_datim_id) person_uuid, d.ods_datim_id, d.date_devolved as dateOfCurrentDSD, bmt.display as currentDSDModel, d.date_return_to_site AS dateReturnToSite, 
       ROW_NUMBER() OVER (PARTITION BY d.person_uuid ORDER BY d.date_devolved DESC ) AS row 
	   from ods_dsd_devolvement d 
	   left join ods_base_application_codeset bmt on bmt.code = d.dsd_type AND bmt.ods_datim_id = d.ods_datim_id
where d.archived = 0 and d.date_devolved between '1980-01-01' 
	 and (select date from expanded_radet.period where is_active)
	 ) d2 where row = 1;

drop table if exists expanded_radet.cte_dsd2;
alter table expanded_radet.cte_dsd2_new rename to cte_dsd2;

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO cte_monitoring (table_name, start_time,end_time) 
VALUES ('cte_dsd2', start_time,end_time);
END
$$;


ALTER PROCEDURE expanded_radet.proc_dsd2() OWNER TO lamisplus_etl;

--
-- Name: proc_eac(); Type: PROCEDURE; Schema: expanded_radet; Owner: lamisplus_etl
--

CREATE PROCEDURE expanded_radet.proc_eac()
    LANGUAGE plpgsql
    AS $$DECLARE end_time TIMESTAMP;
DECLARE start_time TIMESTAMP;
BEGIN

SELECT TIMEOFDAY() INTO start_time;

DROP TABLE if exists expanded_radet.cte_eac_new;

CREATE TABLE expanded_radet.cte_eac_new AS 
with first_eac as ( 
        select * 
		from (with current_eac as (
          select id, person_uuid, uuid, status,ods_datim_id,
		  ROW_NUMBER() OVER (PARTITION BY person_uuid,ods_datim_id ORDER BY id DESC) AS row 
          from ods_hiv_eac where archived = 0 
        ) 
        select ce.id, ce.person_uuid, hes.eac_session_date, hes.ods_datim_id,
	   ROW_NUMBER() OVER (PARTITION BY hes.person_uuid,hes.ods_datim_id  ORDER BY hes.eac_session_date ASC ) AS row 
			  from ods_hiv_eac_session hes 
	join current_eac ce on ce.uuid = hes.eac_id and ce.ods_datim_id=hes.ods_datim_id
	where ce.row = 1 and hes.archived = 0 
		and hes.eac_session_date between '1980-01-01' and (select date from expanded_radet.period where is_active) 
		and hes.status in ('FIRST EAC')) as fes where row = 1 
    ), 
    last_eac as ( 
        select * 
		from (with current_eac as ( 
          select id, person_uuid, uuid, status, ods_datim_id,
               ROW_NUMBER() OVER (PARTITION BY person_uuid,ods_datim_id  ORDER BY id DESC) AS row 
            from ods_hiv_eac where archived = 0 
        ) 
        select ce.id, ce.person_uuid, hes.eac_session_date, hes.ods_datim_id,
               ROW_NUMBER() OVER (PARTITION BY hes.person_uuid,hes.ods_datim_id  ORDER BY hes.eac_session_date DESC ) AS row 
			  from ods_hiv_eac_session hes 
            join current_eac ce on ce.uuid = hes.eac_id and ce.ods_datim_id=hes.ods_datim_id
			  where ce.row = 1 and hes.archived = 0 
                and hes.eac_session_date between '1980-01-01' and (select date from expanded_radet.period where is_active) 
                and hes.status in ('FIRST EAC', 'SECOND EAC', 'THIRD EAC')) as les where row = 1 
    ), 
    eac_count as (
        select person_uuid, ods_datim_id,count(*) as no_eac_session from ( 
        with current_eac as (
          select id, person_uuid, uuid, status, ods_datim_id,
			ROW_NUMBER() OVER (PARTITION BY person_uuid,ods_datim_id ORDER BY id DESC) AS row 
			from ods_hiv_eac where archived = 0 
        ) 
        select hes.person_uuid,hes.ods_datim_id
			from ods_hiv_eac_session hes join current_eac ce on ce.person_uuid = hes.person_uuid 
			and ce.ods_datim_id=hes.ods_datim_id
			where ce.row = 1 and hes.archived = 0 
                and hes.eac_session_date between '1980-01-01' and (select date from expanded_radet.period where is_active)
                and hes.status in ('FIRST EAC', 'SECOND EAC', 'THIRD EAC') 
           ) as c group by person_uuid,ods_datim_id
    ), 
    extended_eac as (
        select * from (with current_eac as ( 
          select id, person_uuid, uuid, status, ods_datim_id,
               ROW_NUMBER() OVER (PARTITION BY person_uuid,ods_datim_id ORDER BY id DESC) AS row 
            from ods_hiv_eac where archived = 0 
        ) 
        select ce.id, ce.person_uuid, hes.eac_session_date, hes.ods_datim_id,
               ROW_NUMBER() OVER (PARTITION BY hes.person_uuid,hes.ods_datim_id ORDER BY hes.eac_session_date DESC ) AS row 
					   from ods_hiv_eac_session hes 
            join current_eac ce on ce.uuid = hes.eac_id and ce.ods_datim_id=hes.ods_datim_id
					   where ce.row = 1 and hes.archived = 0 and hes.status is not null 
					   and hes.eac_session_date between '1980-01-01' and (select date from expanded_radet.period where is_active) 
                and hes.status not in ('FIRST EAC', 'SECOND EAC', 'THIRD EAC')) as exe where row = 1 
    ), 
    post_eac_vl as ( 
        select * from(select lt.patient_uuid, lt.ods_datim_id, cast(ls.date_sample_collected as date), lr.result_reported, 
					  cast(lr.date_result_reported as date), 
            ROW_NUMBER() OVER (PARTITION BY lt.patient_uuid,lt.ods_datim_id ORDER BY ls.date_sample_collected DESC) AS row 
        from ods_laboratory_test lt 
        left join ods_laboratory_sample ls on ls.test_id = lt.id and ls.ods_datim_id=lt.ods_datim_id
        left join ods_laboratory_result lr on lr.test_id = lt.id and lr.ods_datim_id=lt.ods_datim_id
                 where lt.viral_load_indication = '302' and lt.archived = '0' and ls.archived = '0' 
        and ls.date_sample_collected between '1980-01-01' and (select date from expanded_radet.period where is_active)
					 ) pe where row = 1 
    ) 
    select fe.person_uuid as person_uuid50, fe.ods_datim_id as eac_ods_datim_id,
	fe.eac_session_date as dateOfCommencementOfEAC, le.eac_session_date as dateOfLastEACSessionCompleted, 
           ec.no_eac_session as numberOfEACSessionCompleted, exe.eac_session_date as dateOfExtendEACCompletion, 
           pvl.result_reported as repeatViralLoadResult, pvl.date_result_reported as DateOfRepeatViralLoadResult, 
           pvl.date_sample_collected as dateOfRepeatViralLoadEACSampleCollection 
    from first_eac fe 
    left join last_eac le on le.person_uuid = fe.person_uuid and le.ods_datim_id=fe.ods_datim_id
    left join eac_count ec on ec.person_uuid = fe.person_uuid and ec.ods_datim_id=fe.ods_datim_id
    left join extended_eac exe on exe.person_uuid = fe.person_uuid and exe.ods_datim_id=fe.ods_datim_id
    left join post_eac_vl pvl on pvl.patient_uuid = fe.person_uuid and pvl.ods_datim_id=fe.ods_datim_id;


drop table expanded_radet.cte_eac;
alter table expanded_radet.cte_eac_new rename to cte_eac;

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time) 
VALUES ('cte_eac', start_time,end_time);
END
$$;


ALTER PROCEDURE expanded_radet.proc_eac() OWNER TO lamisplus_etl;

--
-- Name: proc_expanded_radet_weekly(); Type: PROCEDURE; Schema: expanded_radet; Owner: lamisplus_etl
--

CREATE PROCEDURE expanded_radet.proc_expanded_radet_weekly()
    LANGUAGE plpgsql
    AS $_$DECLARE start_time TIMESTAMP;
DECLARE end_time TIMESTAMP;
DECLARE partition_name TEXT;
DECLARE period_date DATE;
DECLARE period_text TEXT;
DECLARE period_start DATE;
DECLARE period_end DATE;

BEGIN
SELECT TIMEOFDAY() INTO start_time;
--SELECT (date - INTERVAL '1 week')::date into period_start
--FROM public.period WHERE is_active;

SELECT start_date INTO period_start
FROM expanded_radet.period WHERE is_active;

SELECT date into period_end
FROM expanded_radet.period WHERE is_active;

SELECT table_name INTO partition_name
from expanded_radet.period where is_active;

SELECT periodid INTO period_text
from expanded_radet.period where is_active;

SELECT date INTO period_date 
FROM expanded_radet.period where is_active;

EXECUTE format('DROP TABLE IF EXISTS expanded_radet.%I',partition_name);

EXECUTE format('CREATE TABLE expanded_radet.%I PARTITION OF expanded_radet.expanded_radet_weekly
			   FOR VALUES FROM (%L) TO (%L)',
			   partition_name, period_start,period_end);
			   
EXECUTE format('ALTER TABLE expanded_radet.%I
			   ADD CONSTRAINT %I_check CHECK (period_start_date >= %L 
			   and period_end_date <= %L)',
			   partition_name,partition_name,period_start,period_end);
			   
EXECUTE format('INSERT INTO expanded_radet.%I
    SELECT %L AS period,
    uniquepersonuuid,
    bio_ods_datim_id AS datim_id,
    hospitalnumber,
    uniqueid,
    age,
    gender,
    CAST(dateofbirth AS DATE) dateofbirth,
    facilityname,
    lga,
    state,
    datimid,
    targetgroup,
    enrollmentsetting,
    CAST(artstartdate AS DATE) artstartdate, 
    regimenatstart,
    CAST(dateofregistration AS DATE) dateofregistration,
    CAST(dateofenrollment AS DATE) dateofenrollment,
    ovcuniqueid, 
    householduniqueno,
    careentry,
    regimenlineatstart,
    ndrpatientidentifier,
    CAST(dateofviralloadsamplecollection AS DATE) dateofviralloadsamplecollection,  
    CAST(dateofcurrentviralloadsample AS DATE) dateofcurrentviralloadsample, 
    vlfacility,
    vlarchived,
    viralloadindication,
    currentviralload,
    CAST(dateofcurrentviralload AS DATE) dateofcurrentviralload,
    dsdmodel,
    CAST(dateofStartofCurrentARTRegimen AS DATE) AS dateofstartofcurrentartregimen,
    CAST(ct_last_visit_date AS DATE) AS lastpickupdate,
    currentartregimen,
    currentregimenline,
    CAST(nextpickupdate AS DATE) nextpickupdate,
    ct_refill_period AS monthsofarvrefill,
    CAST(datebiometricsenrolled AS DATE) datebiometricsenrolled,
    numberoffingerscaptured,
    CAST(dateofcommencementofeac AS DATE) dateofcommencementofeac,
    numberofeacsessioncompleted,
    CAST(dateoflasteacsessioncompleted AS DATE) dateoflasteacsessioncompleted,
    CAST(dateofextendeaccompletion AS DATE) dateofextendeaccompletion,
    CAST(dateofrepeatviralloadresult AS DATE) dateofrepeatviralloadresult,
    repeatviralloadresult,
    CAST(dateofiptstart AS DATE) dateofiptstart,
    CAST(iptcompletiondate AS DATE) iptcompletiondate,
    iptcompletionstatus,
    ipttype,
    CAST(dateofcervicalcancerscreening AS DATE) dateofcervicalcancerscreening,
    CASE WHEN trim(treatmentmethoddate) <> '''' AND treatmentmethoddate ~ ''^\d+$''
	THEN CAST(treatmentmethoddate as date) ELSE NULL END AS treatmentmethoddate,
    cervicalcancerscreeningtype,
    cervicalcancerscreeningmethod,
    cervicalcancertreatmentscreened,
    resultofcervicalcancerscreening,
    ovcnumber,
    householdnumber,
    tbtreatementtype,
    CAST(tbtreatmentstartdate AS DATE) tbtreatmentstartdate,
    tbtreatmentoutcome,
    CAST(tbcompletiondate AS DATE) tbcompletiondate,
    tbtreatmentpersonuuid,
    dateoftbsamplecollection,
    persontbsample,
    persontbresult,
    CAST(dateofTbDiagnosticResultReceived AS DATE) dateofTbDiagnosticResultReceived,
    CAST(dateofTbDiagnosticResultReceived AS DATE) AS date_result_reported,
    tbdiagnosticresult,
    tbdiagnostictesttype,
    CAST(dateoftbscreened AS DATE) dateoftbscreened,
    tbstatus,
    CAST(dateoflasttblam AS DATE) dateoflasttblam,
    tblamresult,
    causeofdeath,
    vacauseofdeath,
    previousstatus,
    previousstatusdate,
    currentstatus,
    CAST(currentstatusdate AS DATE) currentstatusdate,
    vleligibilitystatus,
    CAST(dateofvleligibilitystatus AS DATE) dateofvleligibilitystatus,
    lastcd4count,
    CAST(dateoflastcd4count AS DATE) dateoflastcd4count,
    CAST(dateoflastcrytococalantigen AS DATE) dateoflastcrytococalantigen,
    lastcrytococalantigen,
    casemanager,
    clientverificationstatus,
    currentweight,
    pregnancyStatus,
    currentStatusDate AS dateofcurrentartstatus,
    clientverificationoutcome,
    modeldevolvedto,
    dateofdevolvement,
    currentdsdmodel,
    dateofcurrentdsd,
    datereturntosite,
    dateofrepeatviralloadeacsamplecollection,
    tbscreeningtype,
	tbStatusOutcome,
    currentclinicalstage,
    datebiometricsrecaptured,
    numberoffingersrecaptured,
    %L AS period_start_date,
    %L AS period_end_date
	FROM expanded_radet.obt_radet',  
	partition_name, period_text, period_start, period_end);
	
update expanded_radet.period 
set is_radet_available=true
where periodid in (select periodid from expanded_radet.period where is_active);
--update expanded_radet.expanded_radet_weekly
--set treatmentmethoddate = null 
--where treatmentmethoddate = '';

--UPDATE expanded_radet.expanded_radet_weekly 
--SET currentstatus = null, 
--dateofcurrentartstatus = null 
--WHERE monthsOfArvRefill IS NULL AND period = periodtxt;

---CREATE MATERIALIZED VIEW mv_final_radet_counts AS
---SELECT datim_id, COUNT(*) AS record_count
---FROM final_radet
---GROUP BY datim_id;
SELECT TIMEOFDAY() INTO end_time; 
INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time,end_time)
VALUES ('expanded_radet_weekly', start_time,end_time,end_time);

END;
$_$;


ALTER PROCEDURE expanded_radet.proc_expanded_radet_weekly() OWNER TO lamisplus_etl;

--
-- Name: proc_ipt(); Type: PROCEDURE; Schema: expanded_radet; Owner: lamisplus_etl
--

CREATE PROCEDURE expanded_radet.proc_ipt()
    LANGUAGE plpgsql
    AS $$DECLARE end_time TIMESTAMP;
DECLARE start_time TIMESTAMP;
BEGIN

SELECT TIMEOFDAY() INTO start_time;

DROP TABLE if exists expanded_radet.cte_ipt_new;

CREATE TABLE expanded_radet.cte_ipt_new AS 
select DISTINCT ON (c.person_uuid, c.ipt_c_ods_datim_id) c.person_uuid AS personuuid80, c.ipt_c_ods_datim_id 
AS cte_ipt_ods_datim_id, 
coalesce(cs.iptCompletionDSC, c.iptCompletionDate) as iptCompletionDate, 
coalesce(cs.iptCompletionSCS, c.iptCompletionStatus) as iptCompletionStatus, s.dateOfIptStart, s.iptType 
from expanded_radet.sub_cte_ipt_c c
left join expanded_radet.sub_cte_ipt_s s on s.person_uuid = c.person_uuid 
AND s.ipt_s_ods_datim_id=c.ipt_c_ods_datim_id
left join expanded_radet.sub_cte_ipt_c_cs  cs on s.person_uuid = cs.person_uuid 
AND cs.ipt_c_cs_ods_datim_id=s.ipt_s_ods_datim_id;

drop table if exists expanded_radet.cte_ipt;
alter table expanded_radet.cte_ipt_new rename to cte_ipt;

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time) 
VALUES ('sub_cte_ipt_c_cs', start_time,end_time);
END
$$;


ALTER PROCEDURE expanded_radet.proc_ipt() OWNER TO lamisplus_etl;

--
-- Name: proc_labcd4(); Type: PROCEDURE; Schema: expanded_radet; Owner: lamisplus_etl
--

CREATE PROCEDURE expanded_radet.proc_labcd4()
    LANGUAGE plpgsql
    AS $$DECLARE start_time TIMESTAMP;
DECLARE end_time TIMESTAMP;
BEGIN

SELECT TIMEOFDAY() INTO start_time;

DROP TABLE if exists expanded_radet.cte_labcd4_new;
CREATE TABLE expanded_radet.cte_labcd4_new AS
 SELECT 
    * 
  FROM 
    (
      SELECT 
        sm.patient_uuid AS cd4_person_uuid, 
		sm.ods_datim_id as lab_ods_datim_id,
        sm.result_reported as cd4Lb, 
        sm.date_result_reported as dateOfCD4Lb, 
        ROW_NUMBER () OVER (
          PARTITION BY sm.patient_uuid, sm.ods_datim_id
          ORDER BY 
            date_result_reported DESC
        ) as rnk 
      FROM 
        public.ods_laboratory_result sm 
        INNER JOIN public.ods_laboratory_test lt on sm.test_id = lt.id AND sm.ods_datim_id = lt.ods_datim_id
      WHERE 
        lt.lab_test_id IN (1, 50) 
        AND sm.date_result_reported IS NOT NULL 
        AND sm.archived = '0'
        AND sm.date_result_reported <= (select date from expanded_radet.period where is_active) ---?3
    ) as cd4_result 
  WHERE 
    cd4_result.rnk = 1
	;

drop table if exists expanded_radet.cte_labcd4;
alter table expanded_radet.cte_labcd4_new rename to cte_labcd4;

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time) 
VALUES ('cte_labcd4', start_time,end_time);
END
$$;


ALTER PROCEDURE expanded_radet.proc_labcd4() OWNER TO lamisplus_etl;

--
-- Name: proc_naive_vl_data(); Type: PROCEDURE; Schema: expanded_radet; Owner: lamisplus_etl
--

CREATE PROCEDURE expanded_radet.proc_naive_vl_data()
    LANGUAGE plpgsql
    AS $$DECLARE end_time TIMESTAMP;
DECLARE start_time TIMESTAMP;
BEGIN
SELECT TIMEOFDAY() INTO start_time;

DROP TABLE if exists expanded_radet.cte_naive_vl_data_new;
  
CREATE TABLE expanded_radet.cte_naive_vl_data_new AS
SELECT pp.uuid AS nvl_person_uuid,pp.ods_datim_id as nvl_ods_datim_id,
EXTRACT(YEAR FROM AGE(NOW(), CAST(pp.date_of_birth AS DATE))) as age, 
ph.visit_date, ph.regimen 
FROM ods_patient_person pp 
INNER JOIN expanded_radet.cte_sub_naive_vl_data ph 
ON ph.person_uuid = pp.uuid AND ph.ods_datim_id_hap = pp.ods_datim_id
WHERE NOT EXISTS (
	SELECT 1 
	FROM expanded_radet.cte_sub2_naive_vl_data sub2 
	WHERE sub2.patient_uuid = pp.uuid AND sub2.ods_datim_id = pp.ods_datim_id);

drop table expanded_radet.cte_naive_vl_data;
alter table expanded_radet.cte_naive_vl_data_new rename to cte_naive_vl_data;

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time) 
VALUES ('cte_naive_vl_data', start_time,end_time);
END
$$;


ALTER PROCEDURE expanded_radet.proc_naive_vl_data() OWNER TO lamisplus_etl;

--
-- Name: proc_ovc(); Type: PROCEDURE; Schema: expanded_radet; Owner: lamisplus_etl
--

CREATE PROCEDURE expanded_radet.proc_ovc()
    LANGUAGE plpgsql
    AS $$DECLARE start_time TIMESTAMP;
DECLARE end_time TIMESTAMP;
BEGIN
SELECT TIMEOFDAY() INTO start_time;

DROP TABLE if exists expanded_radet.cte_ovc_new;
CREATE TABLE expanded_radet.cte_ovc_new AS
SELECT DISTINCT ON (person_uuid, ods_datim_id) person_uuid AS personUuid100, 
ods_datim_id as ovc_ods_datim_id,ovc_number AS ovcNumber, house_hold_number AS householdNumber 
FROM ods_hiv_enrollment;

drop table expanded_radet.cte_ovc;
alter table expanded_radet.cte_ovc_new rename to cte_ovc;

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time) 
VALUES ('cte_ovc', start_time,end_time);
END
$$;


ALTER PROCEDURE expanded_radet.proc_ovc() OWNER TO lamisplus_etl;

--
-- Name: proc_patient_lga(); Type: PROCEDURE; Schema: expanded_radet; Owner: lamisplus_etl
--

CREATE PROCEDURE expanded_radet.proc_patient_lga()
    LANGUAGE plpgsql
    AS $_$DECLARE end_time TIMESTAMP;
DECLARE start_time TIMESTAMP;
BEGIN

SELECT TIMEOFDAY() INTO start_time;

DROP TABLE IF EXISTS expanded_radet.cte_patient_lga_new;
CREATE TABLE expanded_radet.cte_patient_lga_new AS
select DISTINCT ON (ods_datim_id, personUuid) personUuid as personUuid11,  
case when (addr ~ '^[0-9\\\\.]$') =TRUE  
then (select distinct name from ods_base_organisation_unit 
	  where id = cast(addr as int) limit 1) ELSE
(select distinct name from ods_base_organisation_unit 
 where id = cast(facilityLga as int) limit 1) end as lgaOfResidence  
from (
select distinct on (pp.uuid, ods_datim_id) pp.uuid AS personUuid, pp.ods_datim_id,  
	facility_lga.parent_organisation_unit_id AS facilityLga, 
	(jsonb_array_elements(pp.address->'address')->>'district') as addr 
	from ods_patient_person pp
LEFT JOIN ods_base_organisation_unit facility_lga 
	ON facility_lga.id = CAST (pp.organization->'id' AS INTEGER)  and
facility_lga.ods_datim_id=pp.ods_datim_id
) dt;

drop table expanded_radet.cte_patient_lga;
alter table expanded_radet.cte_patient_lga_new rename to cte_patient_lga;
	
SELECT TIMEOFDAY() INTO end_time;
INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time) 
VALUES ('cte_patient_lga', start_time,end_time);
END
$_$;


ALTER PROCEDURE expanded_radet.proc_patient_lga() OWNER TO lamisplus_etl;

--
-- Name: proc_pharmacy_details_regimen(); Type: PROCEDURE; Schema: expanded_radet; Owner: lamisplus_etl
--

CREATE PROCEDURE expanded_radet.proc_pharmacy_details_regimen()
    LANGUAGE plpgsql
    AS $$DECLARE end_time TIMESTAMP;
DECLARE start_time TIMESTAMP;
BEGIN
SELECT TIMEOFDAY() INTO start_time;

DROP TABLE if exists expanded_radet.cte_pharmacy_details_regimen_new;
CREATE TABLE expanded_radet.cte_pharmacy_details_regimen_new AS
SELECT 
    * 
  from 
    (select *,ROW_NUMBER() OVER (PARTITION BY pr1.person_uuid40, pr1.pharma_ods_datim_id 
											ORDER BY pr1.dateofStartofCurrentARTRegimen DESC) as rnk3 
      from 
        (SELECT p.person_uuid as person_uuid40,p.ods_datim_id as pharma_ods_datim_id,
            COALESCE(ds_model.display, p.dsd_model_type) as dsdModel, 
            p.visit_date as dateofStartofCurrentARTRegimen,r.description as currentARTRegimen, 
            rt.description as currentRegimenLine,p.next_appointment as nextPickupDate, 
            CAST(CAST(p.refill_period AS INTEGER) / 30.0 AS DECIMAL(10, 1)) AS monthsOfARVRefill,
            ROW_NUMBER() OVER (PARTITION BY p.person_uuid, p.ods_datim_id ORDER BY p.visit_date DESC) as rnkkk3 
          from public.ods_hiv_art_pharmacy p 
            INNER JOIN public.ods_hiv_art_pharmacy_regimens pr ON pr.art_pharmacy_id = p.id AND pr.ods_datim_id = p.ods_datim_id 
            INNER JOIN public.ods_hiv_regimen r on r.id = pr.regimens_id AND r.ods_datim_id = pr.ods_datim_id
            INNER JOIN public.ods_hiv_regimen_type rt on rt.id = r.regimen_type_id AND rt.ods_datim_id = r.ods_datim_id
            LEFT OUTER JOIN ods_base_application_codeset ds_model on ds_model.code = p.dsd_model_type  
			AND ds_model.ods_datim_id = p.ods_datim_id  
          WHERE r.regimen_type_id in (1, 2, 3, 4, 14) AND p.archived = 0 AND p.visit_date is not null
			AND p.refill_period is not null AND p.visit_date >= '1980-01-01' ---?2 
            AND p.visit_date <= (select date from expanded_radet.period where is_active) ---?3
        ) as pr1 where pr1.rnkkk3=1
    ) as pr2 
  where pr2.rnk3 = 1;
	
drop table if exists expanded_radet.cte_pharmacy_details_regimen;
alter table expanded_radet.cte_pharmacy_details_regimen_new rename to cte_pharmacy_details_regimen;
	
SELECT TIMEOFDAY() INTO end_time;
INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time) 
VALUES ('cte_pharmacy_details_regimen', start_time,end_time);
END
$$;


ALTER PROCEDURE expanded_radet.proc_pharmacy_details_regimen() OWNER TO lamisplus_etl;

--
-- Name: proc_previous(); Type: PROCEDURE; Schema: expanded_radet; Owner: lamisplus_etl
--

CREATE PROCEDURE expanded_radet.proc_previous()
    LANGUAGE plpgsql
    AS $$DECLARE end_time TIMESTAMP;
DECLARE start_time TIMESTAMP;
BEGIN

SELECT TIMEOFDAY() INTO start_time;

DROP TABLE if exists expanded_radet.cte_previous_new;
CREATE TABLE expanded_radet.cte_previous_new AS
SELECT 
    DISTINCT ON (pharmacy.person_uuid, pharmacy.ods_datim_id) pharmacy.person_uuid AS prePersonUuid,
	pharmacy.maxdate AS previous_last_visit_date, pharmacy.refill_period AS previous_refill_period,
    pharmacy.ods_datim_id as pre_ods_datim_id, 
    (CASE WHEN stat.hiv_status ILIKE '%DEATH%' OR stat.hiv_status ILIKE '%Died%' THEN 'Died' 
	  WHEN(stat.status_date > pharmacy.maxdate 
        AND (stat.hiv_status ILIKE '%stop%' OR stat.hiv_status ILIKE '%out%' OR stat.hiv_status ILIKE '%Invalid %')
      ) THEN stat.hiv_status ELSE pharmacy.status END
    ) AS status, 
    (
      CASE WHEN stat.hiv_status ILIKE '%DEATH%' 
      OR stat.hiv_status ILIKE '%Died%' THEN CAST(stat.status_date AS DATE) 
	  WHEN(stat.status_date > pharmacy.maxdate 
        AND (
          stat.hiv_status ILIKE '%stop%' 
          OR stat.hiv_status ILIKE '%out%' 
          OR stat.hiv_status ILIKE '%Invalid %'
        )
      ) THEN CAST(stat.status_date AS DATE) ELSE pharmacy.visit_date END
    ) AS status_date, 
    stat.cause_of_death, 
    stat.va_cause_of_death 
  FROM 
    (
      SELECT 
		hp.refill_period,
        (
          CASE WHEN CAST(hp.visit_date AS DATE) + CAST(hp.refill_period AS INTEGER) + INTERVAL '29 day' < '2024-03-31' ---?4 
          THEN 'IIT' ELSE 'Active' END
        ) status, 
        (
          CASE WHEN CAST(hp.visit_date AS DATE) + CAST(hp.refill_period AS INTEGER) + INTERVAL '29 day' < '2024-03-31' ---?4 
          THEN CAST(hp.visit_date AS DATE) + CAST(hp.refill_period AS INTEGER) + INTERVAL '29 day' ELSE CAST(hp.visit_date AS DATE) END
        ) AS visit_date, 
        hp.person_uuid,
        hp.ods_datim_id, 
        MAXDATE 
      FROM 
        ods_hiv_art_pharmacy hp 
        INNER JOIN (
          SELECT 
            hap.person_uuid,
            hap.ods_datim_id, 
            hap.visit_date AS MAXDATE, 
            ROW_NUMBER() OVER (
              PARTITION BY hap.person_uuid, hap.ods_datim_id 
              ORDER BY 
                hap.visit_date DESC
            ) as rnkkk3 
          FROM 
            public.ods_hiv_art_pharmacy hap 
            INNER JOIN public.ods_hiv_art_pharmacy_regimens pr ON pr.art_pharmacy_id = hap.id AND pr.ods_datim_id = hap.ods_datim_id
            INNER JOIN ods_hiv_enrollment h ON h.person_uuid = hap.person_uuid AND h.ods_datim_id = hap.ods_datim_id
            AND h.archived = 0 
            INNER JOIN public.ods_hiv_regimen r on r.id = pr.regimens_id AND r.ods_datim_id = pr.ods_datim_id
            INNER JOIN public.ods_hiv_regimen_type rt on rt.id = r.regimen_type_id AND rt.ods_datim_id = r.ods_datim_id
          WHERE 
            r.regimen_type_id in (1, 2, 3, 4, 14) 
            AND hap.archived = 0 
            AND hap.visit_date <= '2024-03-31' ---?4
        ) MAX ON MAX.MAXDATE = hp.visit_date 
        AND MAX.person_uuid = hp.person_uuid AND MAX.ods_datim_id = hp.ods_datim_id
        AND MAX.rnkkk3 = 1 
      WHERE 
        hp.archived = 0 
        AND hp.visit_date <= '2024-03-31' ---?4
    ) pharmacy 
    LEFT JOIN (
      SELECT 
        hst.hiv_status, 
        hst.person_id, 
        hst.ods_datim_id,
        hst.cause_of_death, 
        hst.va_cause_of_death, 
        hst.status_date 
      FROM 
        (
          SELECT 
            * 
          FROM 
            (
              SELECT 
                DISTINCT ON (person_id, ods_datim_id) person_id, 
                ods_datim_id,
                status_date, 
                cause_of_death, 
                va_cause_of_death, 
                hiv_status, 
                ROW_NUMBER() OVER (
                  PARTITION BY person_id, ods_datim_id 
                  ORDER BY 
                    status_date DESC
                ) 
              FROM 
                ods_hiv_status_tracker 
              WHERE 
                archived = 0 
               AND status_date <= '2024-03-31' ---?4
            ) s 
          WHERE 
            s.row_number = 1
        ) hst 
        INNER JOIN ods_hiv_enrollment he ON he.person_uuid = CAST(hst.person_id AS TEXT) AND he.ods_datim_id = hst.ods_datim_id
      WHERE 
        hst.status_date <= '2024-03-31' ---?4
    ) stat ON CAST(stat.person_id AS TEXT) = pharmacy.person_uuid AND stat.ods_datim_id = pharmacy.ods_datim_id
;

drop table if exists expanded_radet.cte_previous;
alter table expanded_radet.cte_previous_new rename to cte_previous;

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time) 
VALUES ('cte_previous', start_time,end_time);
END
$$;


ALTER PROCEDURE expanded_radet.proc_previous() OWNER TO lamisplus_etl;

--
-- Name: proc_previous_previous(); Type: PROCEDURE; Schema: expanded_radet; Owner: lamisplus_etl
--

CREATE PROCEDURE expanded_radet.proc_previous_previous()
    LANGUAGE plpgsql
    AS $$DECLARE end_time TIMESTAMP;
DECLARE start_time TIMESTAMP;
BEGIN

SELECT TIMEOFDAY() INTO start_time;

DROP TABLE if exists expanded_radet.cte_previous_previous_new;

CREATE TABLE expanded_radet.cte_previous_previous_new AS
SELECT 
    DISTINCT ON (pharmacy.person_uuid, pharmacy.ods_datim_id) pharmacy.person_uuid AS preprePersonUuid,
	pharmacy.maxdate AS previous_last_visit_date, pharmacy.refill_period AS previous_refill_period,
    pharmacy.ods_datim_id as prepre_ods_datim_id, 
    (
      CASE WHEN stat.hiv_status ILIKE '%DEATH%' 
      OR stat.hiv_status ILIKE '%Died%' THEN 'Died' 
	  WHEN(stat.status_date > pharmacy.maxdate 
        AND (
          stat.hiv_status ILIKE '%stop%' 
          OR stat.hiv_status ILIKE '%out%' 
          OR stat.hiv_status ILIKE '%Invalid %'
        )
      ) THEN stat.hiv_status ELSE pharmacy.status END
    ) AS status, 
    (
      CASE WHEN stat.hiv_status ILIKE '%DEATH%' 
      OR stat.hiv_status ILIKE '%Died%' THEN CAST(stat.status_date AS DATE) WHEN(
        stat.status_date > pharmacy.maxdate 
        AND (
          stat.hiv_status ILIKE '%stop%' 
          OR stat.hiv_status ILIKE '%out%' 
          OR stat.hiv_status ILIKE '%Invalid %'
        )
      ) THEN CAST(stat.status_date AS DATE) ELSE pharmacy.visit_date END
    ) AS status_date, 
    stat.cause_of_death, 
    stat.va_cause_of_death 
  FROM 
    (
      SELECT 
		hp.refill_period,
        (
          CASE WHEN CAST(hp.visit_date AS DATE) + CAST(hp.refill_period AS INTEGER) + INTERVAL '29 day' < '2023-12-31' ---?5
          THEN 'IIT' ELSE 'Active' END
        ) status, 
        (
          CASE WHEN CAST(hp.visit_date AS DATE) + CAST(hp.refill_period AS INTEGER) + INTERVAL '29 day' < '2023-12-31' ---?5 
          THEN CAST(hp.visit_date AS DATE) + CAST(hp.refill_period AS INTEGER) + INTERVAL '29 day' ELSE CAST(hp.visit_date AS DATE) END
        ) AS visit_date, 
        hp.person_uuid,
        hp.ods_datim_id, 
        MAXDATE 
      FROM 
        ods_hiv_art_pharmacy hp 
        INNER JOIN (
          SELECT 
            hap.person_uuid,
            hap.ods_datim_id, 
            hap.visit_date AS MAXDATE, 
            ROW_NUMBER() OVER (
              PARTITION BY hap.person_uuid, hap.ods_datim_id 
              ORDER BY 
                hap.visit_date DESC
            ) as rnkkk3 
          FROM 
            public.ods_hiv_art_pharmacy hap 
            INNER JOIN public.ods_hiv_art_pharmacy_regimens pr ON pr.art_pharmacy_id = hap.id AND pr.ods_datim_id = hap.ods_datim_id
            INNER JOIN ods_hiv_enrollment h ON h.person_uuid = hap.person_uuid AND h.ods_datim_id = hap.ods_datim_id
            AND h.archived = 0 
            INNER JOIN public.ods_hiv_regimen r on r.id = pr.regimens_id AND r.ods_datim_id = pr.ods_datim_id
            INNER JOIN public.ods_hiv_regimen_type rt on rt.id = r.regimen_type_id AND rt.ods_datim_id = r.ods_datim_id
          WHERE 
            r.regimen_type_id in (1, 2, 3, 4, 14) 
            AND hap.archived = 0 
            AND hap.visit_date <= '2023-12-31' ---?5
        ) MAX ON MAX.MAXDATE = hp.visit_date 
        AND MAX.person_uuid = hp.person_uuid AND MAX.ods_datim_id = hp.ods_datim_id
        AND MAX.rnkkk3 = 1 
      WHERE 
        hp.archived = 0 
        AND hp.visit_date <= '2023-12-31' ---?5
    ) pharmacy 
    LEFT JOIN (
      SELECT 
        hst.hiv_status, 
        hst.person_id, 
        hst.ods_datim_id,
        hst.cause_of_death, 
        hst.va_cause_of_death, 
        hst.status_date 
      FROM 
        (
          SELECT 
            * 
          FROM 
            (
              SELECT 
                DISTINCT ON (person_id, ods_datim_id) person_id, 
                ods_datim_id,
                status_date, 
                cause_of_death, 
                va_cause_of_death, 
                hiv_status, 
                ROW_NUMBER() OVER (
                  PARTITION BY person_id, ods_datim_id 
                  ORDER BY 
                    status_date DESC
                ) 
              FROM 
                ods_hiv_status_tracker 
              WHERE 
                archived = 0 
               AND status_date <= '2023-12-31' ---?5
            ) s 
          WHERE 
            s.row_number = 1
        ) hst 
        INNER JOIN ods_hiv_enrollment he ON he.person_uuid = CAST(hst.person_id AS TEXT) AND he.ods_datim_id = hst.ods_datim_id
      WHERE 
        hst.status_date <= '2023-12-31' ---?5
    ) stat ON CAST(stat.person_id AS TEXT) = pharmacy.person_uuid AND stat.ods_datim_id = pharmacy.ods_datim_id
;

drop table if exists expanded_radet.cte_previous_previous;
alter table expanded_radet.cte_previous_previous_new rename to cte_previous_previous;

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time) 
VALUES ('cte_previous_previous', start_time,end_time);
END
$$;


ALTER PROCEDURE expanded_radet.proc_previous_previous() OWNER TO lamisplus_etl;

--
-- Name: proc_radet_joined(); Type: PROCEDURE; Schema: expanded_radet; Owner: lamisplus_etl
--

CREATE PROCEDURE expanded_radet.proc_radet_joined()
    LANGUAGE plpgsql
    AS $$DECLARE start_time TIMESTAMP;
DECLARE end_time TIMESTAMP;
BEGIN

SELECT TIMEOFDAY() INTO start_time;

DROP TABLE IF EXISTS expanded_radet.obt_radet_new ;

CREATE TABLE expanded_radet.obt_radet_new AS
SELECT DISTINCT ON (bd.personUuid, bd.bio_ods_datim_id) 
    bd.personUuid AS uniquePersonUuid,
    bd.*,
    CONCAT(bd.datimId, '_', bd.personUuid) AS ndrPatientIdentifier, 
    p_lga.*,
    scd.*,
    cvlr.*,
    pdr.*,
    b.*,
    c.*,
    e.*,
    ca.dateOfCurrentRegimen,
    ca.person_uuid70,
    ipt.dateOfIptStart,
    ipt.iptCompletionDate,
    ipt.iptCompletionStatus,
    ipt.iptType,
    cc.*,
    dsd1.*,
    dsd2.*,
    ov.*,
    tbTment.*,
    tbSample.*,
    tbResult.*,
    tbS.*,
    tbl.*,
    crypt.*, 
    ct.cause_of_death AS causeOfDeath,
    ct.va_cause_of_death AS vaCauseOfDeath,
	ct.last_visit_date AS ct_last_visit_date,
	CAST(CAST(ct.refill_period AS INTEGER) / 30.0 AS DECIMAL(10, 1)) AS ct_refill_period,
	 (
   CASE
       WHEN prepre.status ILIKE '%DEATH%' THEN 'Died'
       WHEN prepre.status ILIKE '%out%' THEN 'Transferred Out'
       WHEN pre.status ILIKE '%DEATH%' THEN 'Died'
       WHEN pre.status ILIKE '%out%' THEN 'Transferred Out'
       WHEN (
prepre.status ILIKE '%IIT%'
        OR prepre.status ILIKE '%stop%'
    )
           AND (pre.status ILIKE '%ACTIVE%') THEN 'Active Restart'
       WHEN prepre.status ILIKE '%ACTIVE%'
           AND pre.status ILIKE '%ACTIVE%' THEN 'Active'
		   	WHEN pre.status ILIKE '%stop%' THEN 'Stopped Treatment'

       ELSE REPLACE(pre.status, '_', ' ')
       END
   ) AS previousStatus,
           CAST((
   CASE
       WHEN prepre.status ILIKE '%DEATH%' THEN prepre.status_date
       WHEN prepre.status ILIKE '%out%' THEN prepre.status_date
       WHEN pre.status ILIKE '%DEATH%' THEN pre.status_date
       WHEN pre.status ILIKE '%out%' THEN pre.status_date
       WHEN (
prepre.status ILIKE '%IIT%'
        OR prepre.status ILIKE '%stop%'
    )
           AND (pre.status ILIKE '%ACTIVE%') THEN pre.status_date
       WHEN prepre.status ILIKE '%ACTIVE%'
           AND pre.status ILIKE '%ACTIVE%' THEN pre.status_date
       ELSE pre.status_date
       END
   ) AS DATE)AS previousStatusDate,
           (
   CASE
       WHEN prepre.status ILIKE '%DEATH%' THEN 'Died'
       WHEN prepre.status ILIKE '%out%' THEN 'Transferred Out'
       WHEN pre.status ILIKE '%DEATH%' THEN 'Died'
       WHEN pre.status ILIKE '%out%' THEN 'Transferred Out'
       WHEN ct.status ILIKE '%IIT%' THEN 'IIT'
       WHEN ct.status ILIKE '%out%' THEN 'Transferred Out'
       WHEN ct.status ILIKE '%DEATH%' THEN 'Died'
       WHEN (
pre.status ILIKE '%IIT%'
        OR pre.status ILIKE '%stop%'
    )
           AND (ct.status ILIKE '%ACTIVE%') THEN 'Active Restart'
       WHEN pre.status ILIKE '%ACTIVE%'
           AND ct.status ILIKE '%ACTIVE%' THEN 'Active'
	WHEN ct.status ILIKE '%stop%' THEN 'Stopped Treatment'
       ELSE REPLACE(ct.status, '_', ' ')
       END
   ) AS currentStatus,
           CAST((
   CASE
       WHEN prepre.status ILIKE '%DEATH%' THEN prepre.status_date
       WHEN prepre.status ILIKE '%out%' THEN prepre.status_date
       WHEN pre.status ILIKE '%DEATH%' THEN pre.status_date
       WHEN pre.status ILIKE '%out%' THEN pre.status_date
       WHEN ct.status ILIKE '%IIT%' THEN
           CASE
   WHEN (pre.status ILIKE '%DEATH%' OR pre.status ILIKE '%out%' OR pre.status ILIKE '%stop%') THEN pre.status_date
   ELSE ct.status_date --check the pre to see the status and return date appropriate
   END
       WHEN ct.status ILIKE '%stop%' THEN
           CASE
   WHEN (pre.status ILIKE '%DEATH%' OR pre.status ILIKE '%out%' OR pre.status ILIKE '%IIT%') THEN pre.status_date
   ELSE ct.status_date --check the pre to see the status and return date appropriate
   END
       WHEN ct.status ILIKE '%out%' THEN
           CASE
   WHEN (pre.status ILIKE '%DEATH%' OR pre.status ILIKE '%stop%' OR pre.status ILIKE '%IIT%') THEN pre.status_date
   ELSE ct.status_date --check the pre to see the status and return date appropriate
   END
       WHEN (
pre.status ILIKE '%IIT%'
        OR pre.status ILIKE '%stop%'
    )
           AND (ct.status ILIKE '%ACTIVE%') THEN ct.status_date
       WHEN pre.status ILIKE '%ACTIVE%'
           AND ct.status ILIKE '%ACTIVE%' THEN ct.status_date
       ELSE ct.status_date
       END
   )AS DATE) AS currentStatusDate,
	
	
    cvl.clientVerificationStatus, 
    cvl.clientVerificationOutCome,
    COALESCE(
        CASE
            WHEN prepre.status ILIKE '%DEATH%' THEN FALSE
            WHEN prepre.status ILIKE '%out%' THEN FALSE
            WHEN pre.status ILIKE '%DEATH%' THEN FALSE
            WHEN pre.status ILIKE '%out%' THEN FALSE
            WHEN ct.status ILIKE '%IIT%' THEN FALSE
            WHEN ct.status ILIKE '%out%' THEN FALSE
            WHEN ct.status ILIKE '%DEATH%' THEN FALSE
            WHEN ct.status ILIKE '%stop%' THEN FALSE
            WHEN nvd.age >= 15 AND nvd.regimen ILIKE '%DTG%' AND (bd.artstartdate::date + INTERVAL '91 days') < (select date from expanded_radet.period where is_active)    ----?3 
            THEN TRUE
            WHEN nvd.age >= 15 AND nvd.regimen NOT ILIKE '%DTG%' AND (bd.artstartdate::date + INTERVAL '181 days') < (select date from expanded_radet.period where is_active)    ----?3 
            THEN TRUE
            WHEN nvd.age <= 15 AND (bd.artstartdate::date + INTERVAL '181 days') < (select date from expanded_radet.period where is_active)    ----?3 
            THEN TRUE
            WHEN CAST(NULLIF(REGEXP_REPLACE(cvlr.currentviralload, '[^0-9]', '', 'g'), '') AS INTEGER) IS NULL
                AND scd.dateofviralloadsamplecollection IS NULL AND cvlr.dateofcurrentviralload IS NULL
                AND (CAST(bd.artstartdate AS DATE) + INTERVAL '181 days') < (select date from expanded_radet.period where is_active)    ----?3 
                THEN TRUE
            WHEN CAST(NULLIF(REGEXP_REPLACE(cvlr.currentviralload, '[^0-9]', '', 'g'), '') AS INTEGER) IS NULL
                AND scd.dateofviralloadsamplecollection IS NOT NULL AND cvlr.dateofcurrentviralload IS NULL
                AND (CAST(bd.artstartdate AS DATE) + INTERVAL '91 days') < (select date from expanded_radet.period where is_active)    ----?3 
                THEN TRUE
            WHEN CAST(NULLIF(REGEXP_REPLACE(cvlr.currentviralload, '[^0-9]', '', 'g'), '') AS INTEGER) < 1000
                AND (scd.dateofviralloadsamplecollection < cvlr.dateofcurrentviralload OR scd.dateofviralloadsamplecollection IS NULL)
                AND (CAST(cvlr.dateofcurrentviralload AS DATE) + INTERVAL '181 days') < (select date from expanded_radet.period where is_active)    ----?3 
                THEN TRUE
            WHEN CAST(NULLIF(REGEXP_REPLACE(cvlr.currentviralload, '[^0-9]', '', 'g'), '') AS INTEGER) < 1000
                AND (scd.dateofviralloadsamplecollection > cvlr.dateofcurrentviralload OR cvlr.dateofcurrentviralload IS NULL)
                AND (CAST(scd.dateofviralloadsamplecollection AS DATE) + INTERVAL '91 days') < (select date from expanded_radet.period where is_active)    ----?3 
                THEN TRUE
            WHEN CAST(NULLIF(REGEXP_REPLACE(cvlr.currentviralload, '[^0-9]', '', 'g'), '') AS INTEGER) > 1000
                AND (scd.dateofviralloadsamplecollection < cvlr.dateofcurrentviralload OR scd.dateofviralloadsamplecollection IS NULL)
                AND (CAST(cvlr.dateofcurrentviralload AS DATE) + INTERVAL '91 days') < (select date from expanded_radet.period where is_active)    ----?3 
                THEN TRUE
            WHEN CAST(NULLIF(REGEXP_REPLACE(cvlr.currentviralload, '[^0-9]', '', 'g'), '') AS INTEGER) > 1000
                AND (scd.dateofviralloadsamplecollection > cvlr.dateofcurrentviralload OR cvlr.dateofcurrentviralload IS NULL)
                AND (CAST(scd.dateofviralloadsamplecollection AS DATE) + INTERVAL '91 days') < (select date from expanded_radet.period where is_active)    ----?3 
                THEN TRUE
            ELSE FALSE
        END, FALSE) AS vlEligibilityStatus,
    COALESCE(NULLIF(
        CASE
            WHEN prepre.status ILIKE '%DEATH%' THEN NULL
            WHEN prepre.status ILIKE '%out%' THEN NULL
            WHEN pre.status ILIKE '%DEATH%' THEN NULL
            WHEN pre.status ILIKE '%out%' THEN NULL
            WHEN ct.status ILIKE '%IIT%' THEN NULL
            WHEN ct.status ILIKE '%out%' THEN NULL
            WHEN ct.status ILIKE '%DEATH%' THEN NULL
            WHEN ct.status ILIKE '%stop%' THEN NULL
            WHEN nvd.age >= 15 AND nvd.regimen ILIKE '%DTG%' AND (bd.artstartdate::date + INTERVAL '91 days') < (select date from expanded_radet.period where is_active)    ----?3 
            THEN CAST(bd.artstartdate AS DATE) + INTERVAL '91 days'
            WHEN nvd.age >= 15 AND nvd.regimen NOT ILIKE '%DTG%' AND (bd.artstartdate::date + INTERVAL '181 days') < (select date from expanded_radet.period where is_active)    ----?3 
            THEN CAST(bd.artstartdate AS DATE) + INTERVAL '181 days'
            WHEN nvd.age <= 15 AND (bd.artstartdate::date + INTERVAL '181 days') < (select date from expanded_radet.period where is_active)    ----?3 
            THEN CAST(bd.artstartdate AS DATE) + INTERVAL '181 days'
            WHEN CAST(NULLIF(REGEXP_REPLACE(cvlr.currentviralload, '[^0-9]', '', 'g'), '') AS INTEGER) IS NULL
                AND scd.dateofviralloadsamplecollection IS NULL AND cvlr.dateofcurrentviralload IS NULL
                AND (CAST(bd.artstartdate AS DATE) + INTERVAL '181 days') < (select date from expanded_radet.period where is_active)    ----?3 
                THEN CAST(bd.artstartdate AS DATE) + INTERVAL '181 days'
            WHEN CAST(NULLIF(REGEXP_REPLACE(cvlr.currentviralload, '[^0-9]', '', 'g'), '') AS INTEGER) IS NULL
                AND scd.dateofviralloadsamplecollection IS NOT NULL AND cvlr.dateofcurrentviralload IS NULL
                AND (CAST(bd.artstartdate AS DATE) + INTERVAL '91 days') < (select date from expanded_radet.period where is_active)    ----?3 
                THEN CAST(bd.artstartdate AS DATE) + INTERVAL '91 days'
            WHEN CAST(NULLIF(REGEXP_REPLACE(cvlr.currentviralload, '[^0-9]', '', 'g'), '') AS INTEGER) < 1000
                AND (scd.dateofviralloadsamplecollection < cvlr.dateofcurrentviralload OR scd.dateofviralloadsamplecollection IS NULL)
                AND (CAST(cvlr.dateofcurrentviralload AS DATE) + INTERVAL '181 days') < (select date from expanded_radet.period where is_active)    ----?3 
                THEN CAST(cvlr.dateofcurrentviralload AS DATE) + INTERVAL '181 days'
            WHEN CAST(NULLIF(REGEXP_REPLACE(cvlr.currentviralload, '[^0-9]', '', 'g'), '') AS INTEGER) < 1000
                AND (scd.dateofviralloadsamplecollection > cvlr.dateofcurrentviralload OR cvlr.dateofcurrentviralload IS NULL)
                AND (CAST(scd.dateofviralloadsamplecollection AS DATE) + INTERVAL '91 days') < (select date from expanded_radet.period where is_active)    ----?3 
                THEN CAST(scd.dateofviralloadsamplecollection AS DATE) + INTERVAL '91 days'
            WHEN CAST(NULLIF(REGEXP_REPLACE(cvlr.currentviralload, '[^0-9]', '', 'g'), '') AS INTEGER) > 1000
                AND (scd.dateofviralloadsamplecollection < cvlr.dateofcurrentviralload OR scd.dateofviralloadsamplecollection IS NULL)
                AND (CAST(cvlr.dateofcurrentviralload AS DATE) + INTERVAL '91 days') < (select date from expanded_radet.period where is_active)    ----?3 
                THEN CAST(cvlr.dateofcurrentviralload AS DATE) + INTERVAL '91 days'
            WHEN CAST(NULLIF(REGEXP_REPLACE(cvlr.currentviralload, '[^0-9]', '', 'g'), '') AS INTEGER) > 1000
                AND (scd.dateofviralloadsamplecollection > cvlr.dateofcurrentviralload OR cvlr.dateofcurrentviralload IS NULL)
                AND (CAST(scd.dateofviralloadsamplecollection AS DATE) + INTERVAL '91 days') < (select date from expanded_radet.period where is_active)    ----?3 
                THEN CAST(scd.dateofviralloadsamplecollection AS DATE) + INTERVAL '91 days'
            ELSE NULL END, NULL), NULL) AS dateOfVlEligibilityStatus,
    COALESCE(
        CASE
            WHEN cd.cd4lb IS NOT NULL THEN cd.cd4lb
            WHEN ccd.cd_4 IS NOT NULL THEN CAST(ccd.cd_4 as VARCHAR)
            ELSE NULL
        END, NULL) as lastCd4Count,
    COALESCE(
        CASE
            WHEN cd.dateOfCd4Lb IS NOT NULL THEN CAST(cd.dateOfCd4Lb as DATE)
            WHEN ccd.visit_date IS NOT NULL THEN CAST(ccd.visit_date as DATE)
            ELSE NULL
        END, NULL) as dateOfLastCd4Count, 
    INITCAP(cm.caseManager) AS caseManager 
FROM expanded_radet.cte_bio_data bd
LEFT JOIN expanded_radet.cte_patient_lga p_lga ON p_lga.personUuid11 = bd.personUuid 
LEFT JOIN expanded_radet.cte_pharmacy_details_regimen pdr ON pdr.person_uuid40 = bd.personUuid
and bd.bio_ods_datim_id = pdr.pharma_ods_datim_id
LEFT JOIN expanded_radet.cte_current_clinical c ON c.person_uuid10 = bd.personUuid
and bd.bio_ods_datim_id = c.clin_ods_datim_id
LEFT JOIN expanded_radet.cte_sample_collection_date scd ON scd.person_uuid120 = bd.personUuid
and bd.bio_ods_datim_id = scd.sampd_ods_datim_id
LEFT JOIN expanded_radet.cte_current_vl_result cvlr ON cvlr.person_uuid130 = bd.personUuid
and bd.bio_ods_datim_id = cvlr.cvl_ods_datim_id
LEFT JOIN expanded_radet.cte_labCD4 cd ON cd.cd4_person_uuid = bd.personUuid
and bd.bio_ods_datim_id = cd.lab_ods_datim_id
LEFT JOIN expanded_radet.cte_careCardCD4 ccd ON ccd.cccd4_person_uuid = bd.personUuid
and bd.bio_ods_datim_id = ccd.care_ods_datim_id
LEFT JOIN expanded_radet.cte_eac e ON e.person_uuid50 = bd.personUuid
LEFT JOIN expanded_radet.cte_biometric b ON b.person_uuid60 = bd.personUuid
and bd.bio_ods_datim_id = b.biome_ods_datim_id
LEFT JOIN expanded_radet.cte_current_regimen ca ON ca.person_uuid70 = bd.personUuid
and bd.bio_ods_datim_id = ca.creg_ods_datim_id
LEFT JOIN expanded_radet.cte_ipt ipt ON ipt.personUuid80 = bd.personUuid
and bd.bio_ods_datim_id = ipt.cte_ipt_ods_datim_id
LEFT JOIN expanded_radet.cte_cervical_cancer cc ON cc.person_uuid90 = bd.personUuid
and bd.bio_ods_datim_id = cc.cerv_ods_datim_id
LEFT JOIN expanded_radet.cte_ovc ov ON ov.personUuid100 = bd.personUuid
and bd.bio_ods_datim_id = ov.ovc_ods_datim_id
LEFT JOIN expanded_radet.cte_current_status ct ON ct.cuPersonUuid = bd.personUuid
and bd.bio_ods_datim_id = ct.cus_ods_datim_id
LEFT JOIN expanded_radet.cte_previous pre ON pre.prePersonUuid = ct.cuPersonUuid
and bd.bio_ods_datim_id = pre.pre_ods_datim_id
LEFT JOIN expanded_radet.cte_previous_previous prepre ON prepre.prePrePersonUuid = ct.cuPersonUuid
and bd.bio_ods_datim_id = prepre.prepre_ods_datim_id
LEFT JOIN expanded_radet.cte_naive_vl_data nvd ON nvd.nvl_person_uuid = bd.personUuid
and bd.bio_ods_datim_id = nvd.nvl_ods_datim_id
LEFT JOIN expanded_radet.cte_tb_sample_collection tbSample ON tbSample.personTbSample = bd.personUuid
and bd.bio_ods_datim_id = tbSample.samp_ods_datim_id
LEFT JOIN expanded_radet.cte_tbTreatment tbTment ON tbTment.tbTreatmentPersonUuid = bd.personUuid
and bd.bio_ods_datim_id = tbTment.tbtreat_ods_datim_id
LEFT JOIN expanded_radet.cte_current_tb_result tbResult ON tbResult.personTbResult = bd.personUuid
and bd.bio_ods_datim_id = tbResult.curr_ods_datim_id
LEFT JOIN expanded_radet.cte_cryptococal_antigen crypt ON crypt.personuuid12 = bd.personUuid
and bd.bio_ods_datim_id = crypt.crypt_ods_datim_id
LEFT JOIN expanded_radet.cte_tbstatus tbS ON tbS.person_uuid = bd.personUuid
and bd.bio_ods_datim_id = tbS.tbstat_ods_datim_id
LEFT JOIN expanded_radet.cte_tblam tbl ON tbl.personuuidtblam = bd.personUuid 
LEFT JOIN expanded_radet.cte_dsd1 dsd1 ON dsd1.person_uuid_dsd_1 = bd.personUuid 
and bd.bio_ods_datim_id = dsd1.dsd1_ods_datim_id
LEFT JOIN expanded_radet.cte_dsd2 dsd2 ON dsd2.person_uuid_dsd_2 = bd.personUuid 
and bd.bio_ods_datim_id = dsd2.dsd2_ods_datim_id
LEFT JOIN expanded_radet.cte_case_manager cm ON cm.caseperson = bd.personUuid
and bd.bio_ods_datim_id = cm.case_ods_datim_id
LEFT JOIN expanded_radet.cte_client_verification cvl ON cvl.client_person_uuid = bd.personUuid
and bd.bio_ods_datim_id = cvl.client_ods_datim_id;

drop table expanded_radet.obt_radet;
alter table expanded_radet.obt_radet_new rename to obt_radet;

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time) 
VALUES ('obt_radet', start_time,end_time);
END
$$;


ALTER PROCEDURE expanded_radet.proc_radet_joined() OWNER TO lamisplus_etl;

--
-- Name: proc_sample_collection_date(); Type: PROCEDURE; Schema: expanded_radet; Owner: lamisplus_etl
--

CREATE PROCEDURE expanded_radet.proc_sample_collection_date()
    LANGUAGE plpgsql
    AS $$DECLARE start_time TIMESTAMP;
DECLARE end_time TIMESTAMP;
BEGIN
SELECT TIMEOFDAY() INTO start_time;

drop table if exists expanded_radet.cte_sample_collection_date_new;
create table expanded_radet.cte_sample_collection_date_new as 
 SELECT cast(sample.date_sample_collected as date) as dateOfViralLoadSampleCollection, patient_uuid as person_uuid120,ods_datim_id as sampd_ods_datim_id
  FROM 
    ( SELECT lt.viral_load_indication,sm.facility_id,sm.date_sample_collected,sm.patient_uuid,sm.ods_datim_id,sm.archived, 
        ROW_NUMBER () OVER (PARTITION BY sm.patient_uuid, sm.ods_datim_id ORDER BY date_sample_collected DESC) as rnkk 
      FROM public.ods_laboratory_sample sm 
        INNER JOIN public.ods_laboratory_test lt ON lt.id = sm.test_id AND lt.ods_datim_id = sm.ods_datim_id
      WHERE lt.lab_test_id = 16 AND lt.viral_load_indication != '719' AND date_sample_collected IS NOT null 
        AND date_sample_collected <= (select date from expanded_radet.period where is_active) ---?3
    ) as sample 
  WHERE sample.rnkk = 1 AND (sample.archived is null OR sample.archived = '0') 
    ----AND sample.facility_id = ?1
	;

drop table if exists expanded_radet.cte_sample_collection_date;
alter table expanded_radet.cte_sample_collection_date_new rename to cte_sample_collection_date;

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time) 
VALUES ('cte_sample_collection_date', start_time,end_time);
END
$$;


ALTER PROCEDURE expanded_radet.proc_sample_collection_date() OWNER TO lamisplus_etl;

--
-- Name: proc_sub2_naive_vl_data(); Type: PROCEDURE; Schema: expanded_radet; Owner: lamisplus_etl
--

CREATE PROCEDURE expanded_radet.proc_sub2_naive_vl_data()
    LANGUAGE plpgsql
    AS $$DECLARE end_time TIMESTAMP;
DECLARE start_time TIMESTAMP;
BEGIN
SELECT TIMEOFDAY() INTO start_time;

DROP TABLE if exists expanded_radet.cte_sub2_naive_vl_data_new;
CREATE TABLE expanded_radet.cte_sub2_naive_vl_data_new AS
SELECT COUNT(ls.patient_uuid), ls.patient_uuid,ls.ods_datim_id
FROM ods_laboratory_sample ls 
INNER JOIN ods_laboratory_test lt ON lt.id = ls.test_id AND lt.ods_datim_id = ls.ods_datim_id
AND lt.lab_test_id = 16 
WHERE ls.archived = '0' 
GROUP BY ls.patient_uuid,ls.ods_datim_id;

drop table if exists expanded_radet.cte_sub2_naive_vl_data;
alter table expanded_radet.cte_sub2_naive_vl_data_new rename to cte_sub2_naive_vl_data;

drop index if exists idx_cte_sub2_naive_vl_data;
create index idx_cte_sub2_naive_vl_data on expanded_radet.cte_sub2_naive_vl_data (patient_uuid,ods_datim_id);

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time) 
VALUES ('cte_sub2_naive_vl_data', start_time,end_time);
END
$$;


ALTER PROCEDURE expanded_radet.proc_sub2_naive_vl_data() OWNER TO lamisplus_etl;

--
-- Name: proc_sub_current_vl_result(); Type: PROCEDURE; Schema: expanded_radet; Owner: lamisplus_etl
--

CREATE PROCEDURE expanded_radet.proc_sub_current_vl_result()
    LANGUAGE plpgsql
    AS $$
DECLARE start_time TIMESTAMP; 
DECLARE end_time TIMESTAMP;
BEGIN

SELECT TIMEOFDAY() INTO start_time;

DROP TABLE if exists expanded_radet.sub_cte_current_vl_result_new;
CREATE TABLE expanded_radet.sub_cte_current_vl_result_new AS
SELECT
        sm.patient_uuid,
        sm.ods_datim_id,
        sm.facility_id,
        sm.archived AS vlArchived,
        acode.display AS viralLoadIndication,
        sm.result_reported AS currentViralLoad,
        sm.date_result_reported AS dateOfCurrentViralLoad,
        ls.date_sample_collected AS dateOfCurrentViralLoadSample,
        ROW_NUMBER() OVER (PARTITION BY sm.patient_uuid, sm.ods_datim_id 
						   ORDER BY sm.date_result_reported DESC) AS rank2
    FROM public.ods_laboratory_result sm
    INNER JOIN public.ods_laboratory_test lt ON sm.test_id = lt.id AND sm.ods_datim_id = lt.ods_datim_id
    INNER JOIN public.ods_laboratory_sample ls ON ls.test_id = lt.id AND ls.ods_datim_id = lt.ods_datim_id
    INNER JOIN public.ods_base_application_codeset acode ON acode.id = CAST(lt.viral_load_indication AS INTEGER) AND acode.ods_datim_id = lt.ods_datim_id
    WHERE
        lt.lab_test_id = 16 AND lt.viral_load_indication != 719 AND sm.date_result_reported IS NOT NULL
        AND sm.date_result_reported <= (
			(SELECT date FROM expanded_radet.period WHERE is_active) 
			--+ INTERVAL '1' MONTH
									   )
        AND sm.result_reported IS NOT NULL AND ls.date_sample_collected <= (SELECT date FROM expanded_radet.period WHERE is_active);

DROP INDEX IF EXISTS expanded_radet.idx_sub_cte_current_vl_result;
CREATE INDEX idx_sub_cte_current_vl_result ON expanded_radet.sub_cte_current_vl_result_new (rank2, vlArchived);	

drop table if exists expanded_radet.sub_cte_current_vl_result;
alter table expanded_radet.sub_cte_current_vl_result_new rename to sub_cte_current_vl_result;

SELECT TIMEOFDAY() INTO end_time; 
INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time)
VALUES ('sub_cte_current_vl_result', start_time,end_time);
END
$$;


ALTER PROCEDURE expanded_radet.proc_sub_current_vl_result() OWNER TO lamisplus_etl;

--
-- Name: proc_sub_date_current_clinical(); Type: PROCEDURE; Schema: expanded_radet; Owner: lamisplus_etl
--

CREATE PROCEDURE expanded_radet.proc_sub_date_current_clinical()
    LANGUAGE plpgsql
    AS $$DECLARE end_time TIMESTAMP;
DECLARE start_time TIMESTAMP;
BEGIN
SELECT TIMEOFDAY() INTO start_time;

DROP TABLE if exists expanded_radet.cte_sub_date_current_clinical_new;
CREATE TABLE expanded_radet.cte_sub_date_current_clinical_new AS
SELECT DISTINCT ON (person_uuid, ods_datim_id) person_uuid, ods_datim_id,
MAX(CAST(hac.visit_date AS DATE)) AS MAXDATE 
FROM ods_hiv_art_clinical hac 
GROUP BY person_uuid, ods_datim_id;

drop table if exists expanded_radet.cte_sub_date_current_clinical;
alter table expanded_radet.cte_sub_date_current_clinical_new rename to cte_sub_date_current_clinical;

drop index if exists idx_datecurrentclinical_maxdatepersonuuidodsdatimid;
CREATE INDEX idx_datecurrentclinical_maxdatepersonuuidodsdatimid
ON expanded_radet.cte_sub_date_current_clinical (MAXDATE, person_uuid, ods_datim_id);

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time) 
VALUES ('cte_sub_date_current_clinical', start_time,end_time);
END
$$;


ALTER PROCEDURE expanded_radet.proc_sub_date_current_clinical() OWNER TO lamisplus_etl;

--
-- Name: proc_sub_ipt_c(); Type: PROCEDURE; Schema: expanded_radet; Owner: lamisplus_etl
--

CREATE PROCEDURE expanded_radet.proc_sub_ipt_c()
    LANGUAGE plpgsql
    AS $$DECLARE end_time TIMESTAMP;
DECLARE start_time TIMESTAMP;
BEGIN

SELECT TIMEOFDAY() INTO start_time;

DROP TABLE IF EXISTS expanded_radet.sub_cte_ipt_c_new;
CREATE TABLE expanded_radet.sub_cte_ipt_c_new AS      
SELECT person_uuid,ods_datim_id as ipt_c_ods_datim_id, date_completed AS iptCompletionDate, iptCompletionStatus 
FROM 
(SELECT distinct on (person_uuid,ods_datim_id) person_uuid,ods_datim_id,
 CASE WHEN (ipt->>'dateCompleted' is not null and ipt->>'dateCompleted' != 'null' and ipt->>'dateCompleted' != '' 
AND TRIM(ipt->>'dateCompleted') <> '')THEN CAST(ipt ->> 'dateCompleted' AS DATE) ELSE NULL END AS date_completed,
COALESCE(NULLIF(CAST(ipt ->> 'completionStatus' AS text), ''), '') AS iptCompletionStatus,
 ROW_NUMBER() OVER (PARTITION BY person_uuid,ods_datim_id ORDER BY visit_date DESC) AS rnk 
 FROM ods_hiv_art_pharmacy WHERE archived = 0 ) ic 
 WHERE ic.rnk = 1;

drop table if exists expanded_radet.sub_cte_ipt_c;
alter table expanded_radet.sub_cte_ipt_c_new rename to sub_cte_ipt_c;

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time) 
VALUES ('sub_cte_ipt_c', start_time,end_time);
END
$$;


ALTER PROCEDURE expanded_radet.proc_sub_ipt_c() OWNER TO lamisplus_etl;

--
-- Name: proc_sub_ipt_c_cs(); Type: PROCEDURE; Schema: expanded_radet; Owner: lamisplus_etl
--

CREATE PROCEDURE expanded_radet.proc_sub_ipt_c_cs()
    LANGUAGE plpgsql
    AS $$DECLARE end_time TIMESTAMP;
DECLARE start_time TIMESTAMP;
BEGIN

SELECT TIMEOFDAY() INTO start_time;

DROP TABLE if exists expanded_radet.sub_cte_ipt_c_cs_new;
CREATE TABLE expanded_radet.sub_cte_ipt_c_cs_new AS 
       SELECT person_uuid, ods_datim_id as ipt_c_cs_ods_datim_id,iptStartDate, iptCompletionSCS, iptCompletionDSC 
FROM (SELECT distinct on (person_uuid,ods_datim_id) person_uuid,ods_datim_id,  
	  CASE WHEN (data->'tbIptScreening'->>'dateTPTStart') IS NULL 
		 OR (data->'tbIptScreening'->>'dateTPTStart') = '' 
		 OR (data->'tbIptScreening'->>'dateTPTStart') = ' '  THEN NULL
	ELSE CAST((data->'tbIptScreening'->>'dateTPTStart') AS DATE) END as iptStartDate, 
data->'tptMonitoring'->>'outComeOfIpt' as iptCompletionSCS, 
CASE WHEN (data->'tptMonitoring'->>'date') = 'null' OR (data->'tptMonitoring'->>'date') = '' 
	  OR (data->'tptMonitoring'->>'date') = ' '  THEN NULL ELSE cast(data->'tptMonitoring'->>'date' as date) 
END as iptCompletionDSC, ROW_NUMBER() OVER (PARTITION BY person_uuid,ods_datim_id ORDER BY 
CASE WHEN (data->'tptMonitoring'->>'date') = 'null' OR (data->'tptMonitoring'->>'date') = '' OR (data->'tptMonitoring'->>'date') = ' '  THEN NULL 
ELSE cast(data->'tptMonitoring'->>'date' as date) 
END DESC) AS ipt_c_sc_rnk 
FROM ods_hiv_observation 
WHERE type = 'Chronic Care' AND archived = 0 AND (data->'tptMonitoring'->>'date') IS NOT NULL 
AND (data->'tptMonitoring'->>'date') != 'null' 
) AS ipt_ccs 
WHERE ipt_c_sc_rnk = 1;

drop table if exists expanded_radet.sub_cte_ipt_c_cs;
alter table expanded_radet.sub_cte_ipt_c_cs_new rename to sub_cte_ipt_c_cs;

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time) 
VALUES ('sub_cte_ipt_c_cs', start_time,end_time);
END
$$;


ALTER PROCEDURE expanded_radet.proc_sub_ipt_c_cs() OWNER TO lamisplus_etl;

--
-- Name: proc_sub_ipt_s(); Type: PROCEDURE; Schema: expanded_radet; Owner: lamisplus_etl
--

CREATE PROCEDURE expanded_radet.proc_sub_ipt_s()
    LANGUAGE plpgsql
    AS $$DECLARE end_time TIMESTAMP;
DECLARE start_time TIMESTAMP;
BEGIN

SELECT TIMEOFDAY() INTO start_time;

DROP TABLE if exists expanded_radet.sub_cte_ipt_s_new;
CREATE TABLE expanded_radet.sub_cte_ipt_s_new AS 
SELECT person_uuid, ods_datim_id as ipt_s_ods_datim_id,
visit_date as dateOfIptStart, regimen_name as iptType 
FROM ( 
SELECT DISTINCT ON (h.person_uuid,h.ods_datim_id) h.person_uuid,h.ods_datim_id, h.visit_date, CAST(pharmacy_object ->> 'regimenName' AS VARCHAR) AS regimen_name, 
ROW_NUMBER() OVER (PARTITION BY h.person_uuid,h.ods_datim_id ORDER BY h.visit_date DESC) AS rnk 
FROM ods_hiv_art_pharmacy h 
INNER JOIN jsonb_array_elements(h.extra -> 'regimens') WITH ORDINALITY p(pharmacy_object) ON TRUE 
INNER JOIN ods_hiv_regimen hr ON hr.description = CAST(p.pharmacy_object ->> 'regimenName' AS VARCHAR) 
AND hr.ods_datim_id=h.ods_datim_id
INNER JOIN ods_hiv_regimen_type hrt ON hrt.id = hr.regimen_type_id AND hr.ods_datim_id=hrt.ods_datim_id
WHERE hrt.id = 15 AND h.archived = 0 and h.ipt ->> 'type' ILIKE '%INITIATION%' OR ipt ->> 'type' ILIKE 'START_REFILL' 
) AS ic 
WHERE ic.rnk = 1;

drop table if exists expanded_radet.sub_cte_ipt_s;
alter table expanded_radet.sub_cte_ipt_s_new rename to sub_cte_ipt_s;

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time) 
VALUES ('sub_cte_ipt_s', start_time,end_time);
END
$$;


ALTER PROCEDURE expanded_radet.proc_sub_ipt_s() OWNER TO lamisplus_etl;

--
-- Name: proc_sub_naive_vl_data(); Type: PROCEDURE; Schema: expanded_radet; Owner: lamisplus_etl
--

CREATE PROCEDURE expanded_radet.proc_sub_naive_vl_data()
    LANGUAGE plpgsql
    AS $$DECLARE end_time TIMESTAMP;
DECLARE start_time TIMESTAMP;
BEGIN
SELECT TIMEOFDAY() INTO start_time;

DROP TABLE if exists expanded_radet.cte_sub_naive_vl_data_new;
CREATE TABLE expanded_radet.cte_sub_naive_vl_data_new AS
SELECT DISTINCT ON (ph.person_uuid,ph.ods_datim_id_hap) ph.person_uuid,ph.ods_datim_id_hap,regimen,visit_date
FROM (SELECT pharm.*,
	  ROW_NUMBER() OVER (PARTITION BY pharm.person_uuid, pharm.ods_datim_id_hap 
						 ORDER BY pharm.visit_date DESC) 
FROM   (SELECT DISTINCT *, hap.ods_datim_id as ods_datim_id_hap
FROM ods_hiv_art_pharmacy hap 
INNER JOIN ods_hiv_art_pharmacy_regimens hapr ON hapr.art_pharmacy_id = hap.id AND hap.ods_datim_id = hapr.ods_datim_id
INNER JOIN ods_hiv_regimen hr ON hr.id = hapr.regimens_id AND hr.ods_datim_id = hapr.ods_datim_id
INNER JOIN ods_hiv_regimen_type hrt ON hrt.id = hr.regimen_type_id AND hrt.ods_datim_id = hr.ods_datim_id
INNER JOIN ods_hiv_regimen_resolver hrr ON hrr.regimensys = hr.description AND hrr.ods_datim_id = hr.ods_datim_id
WHERE hap.archived = 0 AND hrt.id IN (1, 2, 3, 4, 14)) pharm
) ph WHERE ph.row_number = 1;

drop table if exists expanded_radet.cte_sub_naive_vl_data;
alter table expanded_radet.cte_sub_naive_vl_data_new rename to cte_sub_naive_vl_data;

drop index if exists idx_cte_sub_naive_vl_data;
create index idx_cte_sub_naive_vl_data on expanded_radet.cte_sub_naive_vl_data(person_uuid,ods_datim_id_hap);

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time) 
VALUES ('cte_sub_naive_vl_data', start_time,end_time);
END
$$;


ALTER PROCEDURE expanded_radet.proc_sub_naive_vl_data() OWNER TO lamisplus_etl;

--
-- Name: proc_sub_triage_current_clinical(); Type: PROCEDURE; Schema: expanded_radet; Owner: lamisplus_etl
--

CREATE PROCEDURE expanded_radet.proc_sub_triage_current_clinical()
    LANGUAGE plpgsql
    AS $$DECLARE end_time TIMESTAMP;
DECLARE start_time TIMESTAMP;
BEGIN
SELECT TIMEOFDAY() INTO start_time;

DROP TABLE if exists expanded_radet.cte_sub_triage_current_clinical_new;
CREATE TABLE expanded_radet.cte_sub_triage_current_clinical_new AS
SELECT DISTINCT ON (person_uuid, ods_datim_id) person_uuid, ods_datim_id,MAX(CAST(capture_date AS DATE)) AS MAXDATE 
FROM ods_triage_vital_sign 
GROUP BY person_uuid, ods_datim_id;
	
drop table if exists expanded_radet.cte_sub_triage_current_clinical;
alter table expanded_radet.cte_sub_triage_current_clinical_new rename to cte_sub_triage_current_clinical;

drop index if exists idx_triagecurrentclinical_maxdatepersonuuidodsdatimid;
CREATE INDEX idx_triagecurrentclinical_maxdatepersonuuidodsdatimid
ON expanded_radet.cte_sub_triage_current_clinical (MAXDATE, person_uuid, ods_datim_id);

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time) 
VALUES ('cte_sub_triage_current_clinical', start_time,end_time);
END
$$;


ALTER PROCEDURE expanded_radet.proc_sub_triage_current_clinical() OWNER TO lamisplus_etl;

--
-- Name: proc_tb_sample_collection(); Type: PROCEDURE; Schema: expanded_radet; Owner: lamisplus_etl
--

CREATE PROCEDURE expanded_radet.proc_tb_sample_collection()
    LANGUAGE plpgsql
    AS $$DECLARE start_time TIMESTAMP;
DECLARE end_time TIMESTAMP;
BEGIN
SELECT TIMEOFDAY() INTO start_time;

DROP TABLE if exists expanded_radet.cte_tb_sample_collection_new;
CREATE TABLE expanded_radet.cte_tb_sample_collection_new AS 
SELECT DISTINCT ON (patient_uuid, ods_datim_id)patient_uuid as personTbSample, ods_datim_id as samp_ods_datim_id, sample.created_by,
CAST(sample.date_sample_collected AS DATE) as dateOfTbSampleCollection  
FROM (
	SELECT DISTINCT ON (sm.patient_uuid, sm.ods_datim_id) sm.patient_uuid, sm.ods_datim_id,  llt.lab_test_name,sm.created_by, lt.viral_load_indication, sm.facility_id,sm.date_sample_collected, sm.archived, 
	ROW_NUMBER () OVER (PARTITION BY sm.patient_uuid, sm.ods_datim_id ORDER BY date_sample_collected DESC) as rnkk
	FROM ods_laboratory_sample  sm
         INNER JOIN ods_laboratory_test lt ON lt.id = sm.test_id AND lt.ods_datim_id=sm.ods_datim_id
         INNER JOIN  ods_laboratory_labtest llt on llt.id = lt.lab_test_id and llt.ods_datim_id = lt.ods_datim_id
WHERE lt.lab_test_id IN (65,51,66,64)
        AND sm.archived = '0'
        AND sm. date_sample_collected <= (select date from expanded_radet.period where is_active)
        --AND sm.facility_id = ?1
        )as sample
      WHERE sample.rnkk = 1; 

drop table expanded_radet.cte_tb_sample_collection;
alter table expanded_radet.cte_tb_sample_collection_new rename to cte_tb_sample_collection;

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time) 
VALUES ('cte_tb_sample_collection', start_time,end_time);
END
$$;


ALTER PROCEDURE expanded_radet.proc_tb_sample_collection() OWNER TO lamisplus_etl;

--
-- Name: proc_tblam(); Type: PROCEDURE; Schema: expanded_radet; Owner: lamisplus_etl
--

CREATE PROCEDURE expanded_radet.proc_tblam()
    LANGUAGE plpgsql
    AS $$DECLARE start_time TIMESTAMP;
DECLARE end_time TIMESTAMP;
BEGIN
SELECT TIMEOFDAY() INTO start_time;

DROP TABLE if exists expanded_radet.cte_tblam_new;
CREATE TABLE expanded_radet.cte_tblam_new AS 
SELECT 
    * 
  FROM 
    (SELECT DISTINCT ON (lr.patient_uuid, lr.ods_datim_id)lr.patient_uuid as personuuidtblam,
        CAST(lr.date_result_reported AS DATE) AS dateOfLastTbLam,lr.result_reported as tbLamResult, 
        ROW_NUMBER () OVER (PARTITION BY lr.patient_uuid, lr.ods_datim_id ORDER BY lr.date_result_reported DESC) as rank2333 
      FROM  ods_laboratory_result lr 
      INNER JOIN ods_laboratory_test lt on lr.test_id = lt.id AND lr.ods_datim_id=lt.ods_datim_id
      WHERE lt.lab_test_id = 51 AND lr.date_result_reported IS NOT NULL AND lr.date_result_reported >= '1980-01-01' 
	  AND lr.date_result_reported <= (select date from expanded_radet.period where is_active)
	  AND lr.result_reported is NOT NULL 
	  AND lr.archived = '0' 
        --AND lr.facility_id = ?1
    ) as tblam 
  WHERE tblam.rank2333 = 1;

drop table expanded_radet.cte_tblam;
alter table expanded_radet.cte_tblam_new rename to cte_tblam;

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time) 
VALUES ('cte_tblam', start_time,end_time);
END
$$;


ALTER PROCEDURE expanded_radet.proc_tblam() OWNER TO lamisplus_etl;

--
-- Name: proc_tbstatus(); Type: PROCEDURE; Schema: expanded_radet; Owner: lamisplus_etl
--

CREATE PROCEDURE expanded_radet.proc_tbstatus()
    LANGUAGE plpgsql
    AS $$DECLARE end_time TIMESTAMP;
DECLARE start_time TIMESTAMP;
BEGIN
SELECT TIMEOFDAY() INTO start_time;

DROP TABLE if exists expanded_radet.cte_tbstatus_new;	
CREATE TABLE expanded_radet.cte_tbstatus_new AS 
SELECT DISTINCT ON (tcs.person_uuid, tcs.ods_datim_id) tcs.person_uuid, tcs.ods_datim_id tbstat_ods_datim_id,
CASE WHEN tcs.tbStatus IS NOT NULL THEN tcs.tbStatus 
WHEN tcs.tbStatus IS NULL AND th.h_status IS NOT NULL THEN th.h_status END AS tbStatus, 
CASE WHEN tcs.tbStatus IS NOT NULL THEN tcs.dateOfTbScreened::date 
	WHEN tcs.tbStatus IS NULL AND th.h_status IS NOT NULL THEN th.visit_date::date END AS dateOfTbScreened, 
tcs.tbScreeningType,tcs.tbStatusOutcome	
FROM expanded_radet.cte_tbstatus_tbscreening_cs tcs 
LEFT JOIN expanded_radet.cte_tbstatus_tbscreening_hac th ON th.person_uuid = tcs.person_uuid 
AND th.ods_datim_id = tcs.ods_datim_id;
	
drop table expanded_radet.cte_tbstatus;
alter table expanded_radet.cte_tbstatus_new rename to cte_tbstatus;

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO cte_monitoring (table_name, start_time,end_time) 
VALUES ('cte_tbstatus', start_time,end_time);
END
$$;


ALTER PROCEDURE expanded_radet.proc_tbstatus() OWNER TO lamisplus_etl;

--
-- Name: proc_tbstatus_tbscreening_cs(); Type: PROCEDURE; Schema: expanded_radet; Owner: lamisplus_etl
--

CREATE PROCEDURE expanded_radet.proc_tbstatus_tbscreening_cs()
    LANGUAGE plpgsql
    AS $$DECLARE end_time TIMESTAMP;
DECLARE start_time TIMESTAMP;

BEGIN
SELECT TIMEOFDAY() INTO start_time;

DROP TABLE if exists expanded_radet.cte_tbstatus_tbscreening_cs_new;
 
CREATE TABLE expanded_radet.cte_tbstatus_tbscreening_cs_new as  
SELECT * FROM (
	SELECT DISTINCT ON (person_uuid, ods_datim_id)person_uuid, ods_datim_id , id, date_of_observation AS dateOfTbScreened, data->'tbIptScreening'->>'status' AS tbStatus, 
		data->'tbIptScreening'->>'tbScreeningType' AS tbScreeningType, 
	data->'tbIptScreening'->>'outcome' AS tbStatusOutcome,
		ROW_NUMBER() OVER (PARTITION BY person_uuid, ods_datim_id ORDER BY date_of_observation DESC) AS rowNums 
FROM ods_hiv_observation 
WHERE type = 'Chronic Care' and data is not null and archived = 0 
	and date_of_observation between '1980-01-01' and (select date from expanded_radet.period where is_active) 
	--and facility_id = ?1 
) cs WHERE rowNums = 1;
	
drop table if exists expanded_radet.cte_tbstatus_tbscreening_cs;
alter table expanded_radet.cte_tbstatus_tbscreening_cs_new rename to cte_tbstatus_tbscreening_cs;

create index idx_tbstatustbscreeningcs_personuuidodsdatimid 
ON expanded_radet.cte_tbstatus_tbscreening_cs(person_uuid,ods_datim_id);

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time) 
VALUES ('cte_tbstatus_tbscreening_cs', start_time,end_time);
END
$$;


ALTER PROCEDURE expanded_radet.proc_tbstatus_tbscreening_cs() OWNER TO lamisplus_etl;

--
-- Name: proc_tbstatus_tbscreening_hac(); Type: PROCEDURE; Schema: expanded_radet; Owner: lamisplus_etl
--

CREATE PROCEDURE expanded_radet.proc_tbstatus_tbscreening_hac()
    LANGUAGE plpgsql
    AS $_$DECLARE end_time TIMESTAMP;
DECLARE start_time TIMESTAMP;
BEGIN

SELECT TIMEOFDAY() INTO start_time;

DROP TABLE if exists expanded_radet.cte_tbstatus_tbscreening_hac_new;
CREATE TABLE expanded_radet.cte_tbstatus_tbscreening_hac_new as  
SELECT * FROM (
    SELECT DISTINCT ON (h.person_uuid, h.ods_datim_id) h.person_uuid, h.ods_datim_id, h.visit_date, h.id, 
        CASE WHEN trim(h.tb_screen->>'tbStatusId') <> '' AND h.tb_screen->>'tbStatusId' ~ '^\d+$'
             THEN CAST(h.tb_screen->>'tbStatusId' as bigint) ELSE NULL END AS tb_status_id, 
        b.display as h_status, ROW_NUMBER() OVER (PARTITION BY h.person_uuid, h.ods_datim_id ORDER BY h.visit_date DESC) AS rowNums 
    FROM ods_hiv_art_clinical h 
    LEFT JOIN ods_base_application_codeset b 
        ON b.id = CASE WHEN trim(h.tb_screen->>'tbStatusId') <> '' AND h.tb_screen->>'tbStatusId' ~ '^\d+$'
                      THEN CAST(h.tb_screen->>'tbStatusId' AS bigint) ELSE NULL END
        AND b.ods_datim_id = h.ods_datim_id
    WHERE h.archived = 0 
      AND h.visit_date BETWEEN '1980-01-01' AND (SELECT date FROM expanded_radet.period WHERE is_active)
) hac 
WHERE rowNums = 1;

drop table if exists expanded_radet.cte_tbstatus_tbscreening_hac;
alter table expanded_radet.cte_tbstatus_tbscreening_hac_new rename to cte_tbstatus_tbscreening_hac;

create index idx_tbstatustbscreeninghac_personuuidodsdatimid 
ON expanded_radet.cte_tbstatus_tbscreening_hac(person_uuid,ods_datim_id);

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time) 
VALUES ('cte_tbstatus_tbscreening_hac', start_time,end_time);
END
$_$;


ALTER PROCEDURE expanded_radet.proc_tbstatus_tbscreening_hac() OWNER TO lamisplus_etl;

--
-- Name: proc_tbtreatment(); Type: PROCEDURE; Schema: expanded_radet; Owner: lamisplus_etl
--

CREATE PROCEDURE expanded_radet.proc_tbtreatment()
    LANGUAGE plpgsql
    AS $$DECLARE end_time TIMESTAMP;
DECLARE start_time TIMESTAMP;
BEGIN
SELECT TIMEOFDAY() INTO start_time;

DROP TABLE if exists expanded_radet.cte_tbtreatment_new;
CREATE TABLE expanded_radet.cte_tbtreatment_new AS
SELECT * FROM (
	SELECT
	DISTINCT ON (person_uuid, ods_datim_id) person_uuid as tbTreatmentPersonUuid,ods_datim_id as tbtreat_ods_datim_id,
     COALESCE(NULLIF(CAST(data->'tbIptScreening'->>'treatementType' AS text), ''), '') as tbTreatementType,
     NULLIF(CAST(NULLIF(data->'tbIptScreening'->>'tbTreatmentStartDate', '') AS DATE), NULL)as tbTreatmentStartDate,
     CAST(data->'tbIptScreening'->>'treatmentOutcome' AS text) as tbTreatmentOutcome,
     NULLIF(CAST(NULLIF(data->'tbIptScreening'->>'completionDate', '') AS DATE), NULL) as tbCompletionDate,
     ROW_NUMBER() OVER (PARTITION BY person_uuid, ods_datim_id ORDER BY date_of_observation DESC)
 FROM public.ods_hiv_observation WHERE type = 'Chronic Care' and archived = 0
       --AND facility_id = ?1 
) tbTreatment WHERE row_number = 1 AND tbTreatmentStartDate IS NOT NULL;

drop table expanded_radet.cte_tbtreatment;
alter table expanded_radet.cte_tbtreatment_new rename to cte_tbtreatment;

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time) 
VALUES ('cte_tbtreatment', start_time,end_time);
END
$$;


ALTER PROCEDURE expanded_radet.proc_tbtreatment() OWNER TO lamisplus_etl;

--
-- Name: proc_update_expanded_radet_period_table(); Type: PROCEDURE; Schema: expanded_radet; Owner: lamisplus_etl
--

CREATE PROCEDURE expanded_radet.proc_update_expanded_radet_period_table()
    LANGUAGE plpgsql
    AS $$
DECLARE start_time TIMESTAMP;
DECLARE end_time TIMESTAMP;
BEGIN
SELECT TIMEOFDAY() INTO start_time;

update expanded_radet.period 
set is_active = false 
where is_active;

update expanded_radet.period 
set is_active = true 
where date = current_date-11;

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time) 
VALUES ('period', start_time,end_time);
END
$$;


ALTER PROCEDURE expanded_radet.proc_update_expanded_radet_period_table() OWNER TO lamisplus_etl;

--
-- Name: proc_update_hiv_status_tracker(); Type: PROCEDURE; Schema: expanded_radet; Owner: lamisplus_etl
--

CREATE PROCEDURE expanded_radet.proc_update_hiv_status_tracker()
    LANGUAGE plpgsql
    AS $$
DECLARE start_time TIMESTAMP;
BEGIN

SELECT TIMEOFDAY() INTO start_time;

update ods_hiv_status_tracker set hiv_status=biometric_status 
where biometric_status is not null and biometric_status != ''
and (biometric_status ilike '%invalid%' or biometric_status ilike '%duplicate%')
and (hiv_status not ilike '%art%' 
	 or hiv_status not ilike '%died%' 
	 or hiv_status not ilike '%death%'
	 or hiv_status not ilike '%stop%'
	 or hiv_status not ilike '%transfer%');

INSERT INTO cte_monitoring (table_name, start_time) VALUES ('ods_hiv_status_tracker', start_time);
END
$$;


ALTER PROCEDURE expanded_radet.proc_update_hiv_status_tracker() OWNER TO lamisplus_etl;
