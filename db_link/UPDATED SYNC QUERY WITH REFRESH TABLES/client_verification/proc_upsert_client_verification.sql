-- PROCEDURE: expanded_radet.proc_upsert_client_verification()

-- DROP PROCEDURE IF EXISTS expanded_radet.proc_upsert_client_verification();

CREATE OR REPLACE PROCEDURE expanded_radet.proc_upsert_client_verification()
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE start_time TIMESTAMP;
DECLARE last_load_end_time TIMESTAMP;
DECLARE end_time TIMESTAMP;
DECLARE record_count bigint;
--DEClARE inserted_count bigint;
--DEClARE updated_count bigint;

BEGIN
-- Fetch the last load end time
SELECT MAX(load_end_time) 
INTO last_load_end_time
FROM streaming_remote_monitoring
WHERE table_name = 'client_verification';

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
--CREATE TEMP TABLE temp_upsert_client_verification (
--		uuid character varying,
--        client_person_uuid character varying,
  --      client_ods_datim_id character varying
    --);

EXECUTE FORMAT('INSERT INTO expanded_radet.client_verification
SELECT * FROM dblink(''db_link_ods'',
''SELECT DISTINCT ON (uuid, ods_datim_id) uuid, person_uuid as client_person_uuid, 
		ods_datim_id as client_ods_datim_id,
		data->''''attempt''''->0->>''''outcome'''' AS clientVerificationOutCome, 
		data->''''attempt''''->0->>''''outcome'''' AS clientVerificationStatus,
		CAST (data->''''attempt''''->0->>''''dateOfAttempt'''' AS DATE) AS dateOfOutcome, 
		archived AS hiv_observation_archived
from ods_hiv_observation 
WHERE ods_load_time >= ''%L''
AND type = ''''Client Verification''''
--AND archived = 0
'')AS sm(uuid character varying,client_person_uuid character varying,
		client_ods_datim_id character varying,clientVerificationOutCome text,
		clientVerificationStatus text,dateOfOutcome date,archived integer)
ON CONFLICT(uuid,client_person_uuid,client_ods_datim_id)
DO UPDATE SET
	hiv_observation_archived=EXCLUDED.archived,
	clientVerificationOutCome=EXCLUDED.clientVerificationOutCome,
	clientVerificationStatus=EXCLUDED.clientVerificationStatus,
	dateOfOutcome=EXCLUDED.dateOfOutcome',
	last_load_end_time);

--RETURNING uuid, person_uuid90, cerv_ods_datim_id
--INTO temp_upsert_client_verification',
	  
SELECT TIMEOFDAY() INTO end_time;

DELETE FROM expanded_radet.client_verification
WHERE hiv_observation_archived=1;

-- -- Count the number of rows inserted and updated
-- SELECT COUNT(person_uuid90) INTO inserted_count
-- FROM temp_upsert_cervical_cancer
-- WHERE NOT EXISTS (
-- 	SELECT 1
-- 	FROM expanded_radet.cervical_cancer t
-- 	WHERE t.uuid = temp_upsert_cervical_cancer.uuid
-- 	AND t.person_uuid90 = temp_upsert_cervical_cancer.person_uuid90
-- 	AND t.cerv_ods_datim_id = temp_upsert_cervical_cancer.cerv_ods_datim_id
-- );

-- SELECT COUNT(person_uuid90) INTO updated_count
-- FROM temp_upsert_cervical_cancer
-- WHERE EXISTS (
-- 	SELECT 1
-- 	FROM expanded_radet.cervical_cancer t
-- 	WHERE t.uuid = temp_upsert_cervical_cancer.uuid
-- 	AND t.person_uuid90 = temp_upsert_cervical_cancer.person_uuid90
-- 	AND t.cerv_ods_datim_id = temp_upsert_cervical_cancer.cerv_ods_datim_id
-- );

INSERT INTO public.streaming_remote_monitoring(table_name,start_time,load_end_time,record_count)
VALUES('client_verification',start_time, end_time,record_count);
		 
END 
$BODY$;
ALTER PROCEDURE expanded_radet.proc_upsert_client_verification()
    OWNER TO lamisplus_etl;