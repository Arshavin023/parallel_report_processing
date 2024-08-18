-- PROCEDURE: expanded_radet.proc_create_patient_bio_data()

-- DROP PROCEDURE IF EXISTS expanded_radet.proc_create_patient_bio_data();

CREATE OR REPLACE PROCEDURE expanded_radet.proc_create_patient_bio_data(
	)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE start_time TIMESTAMP;
DECLARE last_load_end_time TIMESTAMP;
DECLARE end_time TIMESTAMP;
DECLARE record_count bigint;

BEGIN

-- Fetch the last load end time
SELECT MAX(load_end_time) 
INTO last_load_end_time
FROM streaming_remote_monitoring
WHERE table_name = 'patient_bio_data';

-- Fetch record count from the remote database using dblink
EXECUTE format(
	'SELECT *
	 FROM dblink(''db_link_ods'',
	 ''
	 SELECT count(uuid) 
	 FROM ods_patient_person 
	 WHERE ods_load_time >= ''%L''			   
	'') 
	 AS sm(count bigint)',last_load_end_time) 
INTO record_count;


DROP TABLE IF EXISTS expanded_radet.patient_bio_data;

SELECT TIMEOFDAY() INTO start_time;

EXECUTE format('CREATE TABLE expanded_radet.patient_bio_data AS
SELECT * FROM dblink(''db_link_ods'',
''SELECT DISTINCT ON (p.uuid, p.ods_datim_id) p.uuid AS personUuid,
p.ods_datim_id AS bio_ods_datim_id,p.hospital_number AS hospitalNumber,
p.marital_status->>''''display'''' as maritalStatus,education->>''''display'''' as education, 
p.employment_status->>''''display'''' as occupation,p.address,p.stateId,p.lgaId,res_state.name as residentialState,
res_lga AS residentialLga,h.unique_id AS uniqueId,
(CASE WHEN contact_point->''''contactPoint''''->0->>''''type''''=''''phone'''' THEN contact_point->''''contactPoint''''->0->>''''value'''' ELSE null END) AS phone,
INITCAP(p.sex) AS gender,p.date_of_birth AS dateOfBirth,facility.facility_name AS facilityName,
facility.facility_lga AS lga,facility.facility_state AS state, p.ods_datim_id AS datimId,
facility.ip_code,facility.ip_name,tgroup.display AS targetGroup,
eSetting.display AS enrollmentSetting,hac.visit_date AS artStartDate, 
hr.description AS regimenAtStart,p.date_of_registration AS dateOfRegistration,h.date_of_registration AS dateOfEnrollment, 
h.ovc_number AS ovcUniqueId,h.house_hold_number AS householdUniqueNo,ecareEntry.display AS careEntry, 
hrt.description AS regimenLineAtStart, hac.is_commencement, hac.visit_date,p.archived ods_patient_person_archived,
hac.archived AS ods_hiv_art_clinical_archived, h.archived AS ods_hiv_enrollment_archived,
h.person_uuid AS ods_hiv_enrollment_person_uuid, hac.person_uuid AS ods_hiv_art_clinical_person_uuid
FROM (select uuid,ods_datim_id,hospital_number,date_of_birth,sex,facility_id,
	date_of_registration,archived,marital_status,education,contact_point,employment_status,
	REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CAST(address_object->>''''line'''' AS text),
		''''"'''', ''''''''), '''']'''', ''''''''), ''''['''', ''''''''), ''''null'''',''''''''), ''''\\\\\\\'''', '''''''') AS address,
	CASE WHEN address_object->>''''stateId''''  ~ ''''^\\\\d(\\\\.\\\\d)?$'''' THEN address_object->>''''stateId'''' ELSE null END  AS stateId,
	CASE WHEN address_object->>''''district''''  ~ ''''^\\\\d(\\\\.\\\\d)?$'''' THEN address_object->>''''district'''' ELSE null END  AS lgaId
	FROM ods_patient_person pp 
	LEFT JOIN jsonb_array_elements(pp.address-> ''''address'''') as l(address_object) on true
	WHERE ods_load_time >= ''%L'')p
LEFT OUTER JOIN central_partner_mapping facility ON facility.facility_id = p.facility_id  AND facility.datim_id = p.ods_datim_id
LEFT JOIN ods_hiv_enrollment h ON h.person_uuid = p.uuid  AND h.ods_datim_id = p.ods_datim_id  --iNNER
LEFT OUTER JOIN ods_base_application_codeset tgroup ON tgroup.id = h.target_group_id AND tgroup.ods_datim_id = h.ods_datim_id
LEFT OUTER JOIN ods_base_application_codeset eSetting ON eSetting.id = h.enrollment_setting_id AND eSetting.ods_datim_id = h.ods_datim_id
LEFT OUTER JOIN ods_base_application_codeset ecareEntry ON ecareEntry.id = h.entry_point_id AND ecareEntry.ods_datim_id = h.ods_datim_id
LEFT JOIN ods_hiv_art_clinical hac ON hac.hiv_enrollment_uuid = h.uuid  AND hac.ods_datim_id = h.ods_datim_id AND hac.person_uuid=p.uuid
AND hac.is_commencement = TRUE  --iNNER
LEFT JOIN ods_hiv_regimen hr ON hr.id = hac.regimen_id  AND hr.ods_datim_id = hac.ods_datim_id  --INNER
LEFT OUTER JOIN ods_hiv_regimen_type hrt ON hrt.id = hac.regimen_type_id  AND hrt.ods_datim_id = hac.ods_datim_id
LEFT JOIN ods_base_organisation_unit res_state ON res_state.id=CAST(p.stateid AS BIGINT) and res_state.ods_datim_id=p.ods_datim_id
LEFT JOIN ods_base_organisation_unit res_lga ON res_lga.id=CAST(p.lgaid AS BIGINT) AND res_lga.ods_datim_id=p.ods_datim_id
'')
AS sm(personuuid character varying,bio_ods_datim_id character varying(255),hospitalnumber character varying,
    maritalstatus text,education text,occupation text,address text,stateid text,lgaid text,residentialState character varying,
    residentialLga character varying, uniqueid character varying,phone text,gender text,dateofbirth date,facilityname character varying(255),
    lga character varying(255),state character varying(255),datimid character varying(255),
    ip_code bigint,ip_name character varying(255),targetgroup character varying,enrollmentsetting character varying,
    artstartdate date,regimenatstart character varying,dateofregistration date,dateofenrollment date,
    ovcuniqueid character varying,householduniqueno character varying,careentry character varying,
    regimenlineatstart character varying,is_commencement boolean,visit_date date,ods_patient_person_archived integer,
    ods_hiv_art_clinical_archived integer,ods_hiv_enrollment_archived integer,ods_hiv_enrollment_person_uuid character varying,
    ods_hiv_art_clinical_person_uuid character varying)',last_load_end_time);

SELECT TIMEOFDAY() INTO end_time;

ALTER TABLE expanded_radet.patient_bio_data
ADD CONSTRAINT unq_patient_bio_data UNIQUE (personuuid, bio_ods_datim_id);

CREATE INDEX idx_patient_bio_data_non_nulls ON expanded_radet.patient_bio_data (visit_date)
WHERE ods_hiv_enrollment_person_uuid IS NOT NULL
AND ods_hiv_art_clinical_person_uuid IS NOT NULL
AND regimenAtStart IS NOT NULL 
--AND ods_hiv_art_clinical_archived = 0
--AND ods_hiv_enrollment_archived = 0 
AND is_commencement = TRUE;

DELETE FROM expanded_radet.patient_bio_data
WHERE ods_patient_person_archived=1;

INSERT INTO public.streaming_remote_monitoring(table_name,start_time,load_end_time,inserted_count,record_count)
VALUES('patient_bio_data',start_time, end_time,record_count, record_count);
			 
END 
$BODY$;
ALTER PROCEDURE expanded_radet.proc_create_patient_bio_data()
    OWNER TO lamisplus_etl;

--call expanded_radet.proc_create_patient_bio_data()