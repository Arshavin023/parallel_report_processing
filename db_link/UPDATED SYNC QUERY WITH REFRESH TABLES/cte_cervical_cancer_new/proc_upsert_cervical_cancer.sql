-- PROCEDURE: expanded_radet.proc_upsert_cervical_cancer()

-- DROP PROCEDURE IF EXISTS expanded_radet.proc_upsert_cervical_cancer();

CREATE OR REPLACE PROCEDURE expanded_radet.proc_upsert_cervical_cancer(
	)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE start_time TIMESTAMP;
DECLARE last_load_end_time TIMESTAMP;
DECLARE end_time TIMESTAMP;
DECLARE record_count bigint;
DEClARE inserted_count bigint;
DEClARE updated_count bigint;

BEGIN

-- Fetch the last load end time
SELECT MAX(load_end_time) 
INTO last_load_end_time
FROM streaming_remote_monitoring
WHERE table_name = 'cervical_cancer';

-- Fetch record count from the remote database using dblink
EXECUTE FORMAT(
	'SELECT *
	 FROM dblink(''db_link_ods'',
	 ''
	 SELECT count(uuid) 
	 FROM ods_hiv_observation 
	 WHERE ods_load_time >= ''%L''			   
	'') 
	 AS sm(count bigint)',last_load_end_time) 
INTO record_count;

-- Use a temporary table to capture the rows affected by the upsert
CREATE TEMP TABLE temp_upsert_cervical_cancer (
		uuid character varying,
        person_uuid90 character varying,
        cerv_ods_datim_id character varying
    );

EXECUTE FORMAT('INSERT INTO expanded_radet.cervical_cancer
SELECT * from dblink(''db_link_ods'',
''SELECT DISTINCT ON (ho.uuid, ho.ods_datim_id) ho.uuid, ho.person_uuid AS person_uuid90,
ho.ods_datim_id as cerv_ods_datim_id, ho.date_of_observation AS dateOfCervicalCancerScreening, 
ho.data ->> ''''screenTreatmentMethodDate'''' AS treatmentMethodDate,cc_type.display AS cervicalCancerScreeningType, 
cc_method.display AS cervicalCancerScreeningMethod, cc_trtm.display AS cervicalCancerTreatmentScreened, 
cc_result.display AS resultOfCervicalCancerScreening, ho.archived hiv_observation_archived
from (SELECT uuid, person_uuid,ods_datim_id,uuid,data,date_of_observation,archived,type
		FROM ods_hiv_observation
		  WHERE ods_load_time >= ''%L'') ho 
LEFT JOIN ods_base_application_codeset cc_type ON cc_type.code = CAST(ho.data ->> ''''screenType'''' AS VARCHAR) 
AND cc_type.ods_datim_id=ho.ods_datim_id
LEFT JOIN ods_base_application_codeset cc_method ON cc_method.code = CAST(ho.data ->> ''''screenMethod'''' AS VARCHAR)
AND cc_method.ods_datim_id=ho.ods_datim_id
LEFT JOIN ods_base_application_codeset cc_result ON cc_result.code = CAST(ho.data ->> ''''screeningResult'''' AS VARCHAR) 
AND cc_result.ods_datim_id=ho.ods_datim_id
LEFT JOIN ods_base_application_codeset cc_trtm ON cc_trtm.code = CAST(ho.data ->> ''''screenTreatment'''' AS VARCHAR) 
AND cc_trtm.ods_datim_id=ho.ods_datim_id
where type = ''''Cervical cancer''''
--and ho.archived = 0
'')AS sm(uuid character varying, person_uuid90 character varying,cerv_ods_datim_id character varying,
		dateOfCervicalCancerScreening date,treatmentMethodDate text,cervicalCancerScreeningType character varying,
		cervicalCancerScreeningMethod character varying,cervicalCancerTreatmentScreened character varying,
		resultOfCervicalCancerScreening character varying,hiv_observation_archived integer)
	
ON CONFLICT (uuid, person_uuid90, cerv_ods_datim_id)
DO UPDATE SET 
	  dateOfCervicalCancerScreening=EXCLUDED.dateOfCervicalCancerScreening,
	  treatmentMethodDate=EXCLUDED.treatmentMethodDate,
	  cervicalCancerScreeningType=EXCLUDED.cervicalCancerScreeningType,
	  cervicalCancerScreeningMethod=EXCLUDED.cervicalCancerScreeningMethod,
	  cervicalCancerTreatmentScreened=EXCLUDED.cervicalCancerTreatmentScreened,
	  resultOfCervicalCancerScreening=EXCLUDED.resultOfCervicalCancerScreening
	  RETURNING uuid, person_uuid90, cerv_ods_datim_id
	  INTO temp_upsert_cervical_cancer',
	  last_load_end_time);

SELECT TIMEOFDAY() INTO end_time;

DELETE FROM expanded_radet.cervical_cancer
WHERE hiv_observation_archived=1;

-- Count the number of rows inserted and updated
SELECT COUNT(person_uuid90) INTO inserted_count
FROM temp_upsert_cervical_cancer
WHERE NOT EXISTS (
	SELECT 1
	FROM expanded_radet.cervical_cancer t
	WHERE t.uuid = temp_upsert_cervical_cancer.uuid
	AND t.person_uuid90 = temp_upsert_cervical_cancer.person_uuid90
	AND t.cerv_ods_datim_id = temp_upsert_cervical_cancer.cerv_ods_datim_id
);

SELECT COUNT(person_uuid90) INTO updated_count
FROM temp_upsert_cervical_cancer
WHERE EXISTS (
	SELECT 1
	FROM expanded_radet.cervical_cancer t
	WHERE t.uuid = temp_upsert_cervical_cancer.uuid
	AND t.person_uuid90 = temp_upsert_cervical_cancer.person_uuid90
	AND t.cerv_ods_datim_id = temp_upsert_cervical_cancer.cerv_ods_datim_id
);

INSERT INTO public.streaming_remote_monitoring(table_name,start_time,load_end_time,inserted_count,updated_count,record_count)
VALUES('cervical_cancer',start_time, end_time,inserted_count,updated_count, record_count);

			 
END 
$BODY$;
ALTER PROCEDURE expanded_radet.proc_upsert_cervical_cancer()
    OWNER TO lamisplus_etl;
