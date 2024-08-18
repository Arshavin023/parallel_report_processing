--SELECT dblink_connect('db_link_ods', 'host=localhost user=lamisplus_etl password=QUWeIQvD27BYei1 dbname=lamisplus_ods_dwh');
--
-- PROCEDURE: expanded_radet.proc_create_tbstatus_tbscreening()

-- DROP PROCEDURE IF EXISTS expanded_radet.proc_create_tbstatus_tbscreening();

CREATE OR REPLACE PROCEDURE expanded_radet.proc_create_tbstatus_tbscreening()
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

DROP TABLE IF EXISTS expanded_radet.tbstatus_tbscreening;

SELECT TIMEOFDAY() INTO start_time;

EXECUTE FORMAT ('CREATE TABLE expanded_radet.tbstatus_tbscreening AS
SELECT * from dblink(''db_link_ods'',
''SELECT uuid, person_uuid, ods_datim_id , date_of_observation AS dateOfTbScreened, 
					 data->''''tbIptScreening''''->>''''status'''' AS tbStatus, 
		data->''''tbIptScreening''''->>''''tbScreeningType'''' AS tbScreeningType, 
	data->''''tbIptScreening''''->>''''outcome'''' AS tbStatusOutcome, 
	archived hiv_observation_archived
FROM (SELECT id, uuid, type,person_uuid, ods_datim_id, date_of_observation, data,archived 
		FROM ods_hiv_observation WHERE ods_load_time >= ''%L'') ho
WHERE type = ''Chronic Care'' and data is not null
'')AS sm(uuid character varying, person_uuid character varying,ods_datim_id character varying,
		dateoftbscreened date,tbstatus text, tbscreeningtype text, tbstatusoutcome text, 
		hiv_observation_archived integer)',	last_load_end_time);

SELECT TIMEOFDAY() INTO end_time;

ALTER TABLE expanded_radet.tbstatus_tbscreening
ADD CONSTRAINT unq_tbstatus_tbscreening UNIQUE (uuid, person_uuid, ods_datim_id);

CREATE INDEX unq_dateOfTbScreened_tbstatus_tbscreening 
ON expanded_radet.tbstatus_tbscreening(dateOfTbScreened);

DELETE FROM expanded_radet.tbstatus_tbscreening
WHERE hiv_observation_archived=1;

INSERT INTO public.streaming_remote_monitoring(table_name,start_time,load_end_time,record_count)
VALUES('tbstatus_tbscreening',start_time, end_time,record_count);

			 
END 
$BODY$;
ALTER PROCEDURE expanded_radet.proc_create_tbstatus_tbscreening()
    OWNER TO lamisplus_etl;