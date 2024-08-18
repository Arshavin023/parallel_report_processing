-- PROCEDURE: expanded_radet.proc_create_cervical_cancer()

-- DROP PROCEDURE IF EXISTS expanded_radet.proc_create_cervical_cancer();

CREATE OR REPLACE PROCEDURE expanded_radet.proc_create_cervical_cancer()
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

DROP TABLE IF EXISTS expanded_radet.cervical_cancer;

SELECT TIMEOFDAY() INTO start_time;

EXECUTE FORMAT ('CREATE TABLE expanded_radet.cervical_cancer AS
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
		resultOfCervicalCancerScreening character varying,hiv_observation_archived integer)',
		last_load_end_time);

SELECT TIMEOFDAY() INTO end_time;

ALTER TABLE expanded_radet.cervical_cancer
ADD CONSTRAINT unq_cervical_cancer UNIQUE (uuid, person_uuid90, cerv_ods_datim_id);

CREATE INDEX unq_dateofobservation_cervical_cancer 
ON expanded_radet.cervical_cancer(dateOfCervicalCancerScreening);

DELETE FROM expanded_radet.cervical_cancer
WHERE hiv_observation_archived=1;

INSERT INTO public.streaming_remote_monitoring(table_name,start_time,load_end_time,record_count,inserted_count)
VALUES('cervical_cancer',start_time, end_time,record_count, record_count);

			 
END 
$BODY$;
ALTER PROCEDURE expanded_radet.proc_create_cervical_cancer()
    OWNER TO lamisplus_etl;
