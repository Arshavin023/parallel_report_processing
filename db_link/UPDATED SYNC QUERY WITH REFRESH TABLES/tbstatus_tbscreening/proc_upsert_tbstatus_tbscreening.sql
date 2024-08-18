--SELECT dblink_connect('db_link_ods', 'host=localhost user=lamisplus_etl password=QUWeIQvD27BYei1 dbname=lamisplus_ods_dwh');
--
-- PROCEDURE: expanded_radet.proc_upsert_tbstatus_tbscreening()

-- DROP PROCEDURE IF EXISTS expanded_radet.proc_upsert_tbstatus_tbscreening();

CREATE OR REPLACE PROCEDURE expanded_radet.proc_upsert_tbstatus_tbscreening()
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
WHERE table_name = 'tbstatus_tbscreening';

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
--CREATE TEMP TABLE temp_upsert_tbstatus_tbscreening (
--			id bigint,
--         uuid character varying,
  --      ods_datim_id character varying
    --);

EXECUTE FORMAT('INSERT INTO expanded_radet.tbstatus_tbscreening
SELECT * FROM dblink(''db_link_ods'',
''SELECT uuid, person_uuid, ods_datim_id , date_of_observation AS dateOfTbScreened, 
					 data->''''tbIptScreening''''->>''''status'''' AS tbStatus, 
		data->''''tbIptScreening''''->>''''tbScreeningType'''' AS tbScreeningType, 
	data->''''tbIptScreening''''->>''''outcome'''' AS tbStatusOutcome, 
	archived hiv_observation_archived
FROM (SELECT id, uuid, type,person_uuid, ods_datim_id, date_of_observation, data,archived 
		FROM ods_hiv_observation WHERE ods_load_time >= ''%L'') ho
WHERE type = ''''Chronic Care'''' and data is not null
'')AS sm(uuid character varying, person_uuid character varying,ods_datim_id character varying,
		dateoftbscreened date,tbstatus text, tbscreeningtype text, tbstatusoutcome text, 
		hiv_observation_archived integer)
ON CONFLICT(uuid, person_uuid, ods_datim_id)
DO UPDATE SET
	dateOfTbScreened=EXCLUDED.dateOfTbScreened,
	tbStatus=EXCLUDED.tbStatus,
	tbScreeningType=EXCLUDED.tbScreeningType,
	tbStatusOutcome=EXCLUDED.tbStatusOutcome',
	last_load_end_time);

--RETURNING uuid, person_uuid, ods_datim_id
--INTO temp_upsert_tbstatus_tbscreening',

SELECT TIMEOFDAY() INTO end_time;

DELETE FROM expanded_radet.tbstatus_tbscreening
WHERE hiv_observation_archived=1;

-- -- Count the number of rows inserted and updated
-- SELECT COUNT(person_uuid) INTO inserted_count
-- FROM temp_upsert_tbstatus_tbscreening
-- WHERE NOT EXISTS (
-- 	SELECT 1
-- 	FROM expanded_radet.cervical_cancer t
-- 	WHERE t.uuid = temp_upsert_tbstatus_tbscreening.uuid
-- 	AND t.person_uuid = temp_upsert_tbstatus_tbscreening.person_uuid
-- 	AND t.cerv_ods_datim_id = temp_upsert_tbstatus_tbscreening.cerv_ods_datim_id
-- );

-- SELECT COUNT(person_uuid) INTO updated_count
-- FROM temp_upsert_tbstatus_tbscreening
-- WHERE EXISTS (
-- 	SELECT 1
-- 	FROM expanded_radet.cervical_cancer t
-- 	WHERE t.uuid = temp_upsert_tbstatus_tbscreening.uuid
-- 	AND t.person_uuid = temp_upsert_tbstatus_tbscreening.person_uuid
-- 	AND t.cerv_ods_datim_id = temp_upsert_tbstatus_tbscreening.cerv_ods_datim_id
-- );

INSERT INTO public.streaming_remote_monitoring(table_name,start_time,load_end_time,record_count)
VALUES('tbstatus_tbscreening',start_time, end_time,record_count);
		
		
END 
$BODY$;
ALTER PROCEDURE expanded_radet.proc_upsert_tbstatus_tbscreening()
    OWNER TO lamisplus_etl;

--call expanded_radet.proc_upsert_tbstatus_tbscreening();