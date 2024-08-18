-- PROCEDURE: expanded_radet.proc_create_recapture_biometric()

-- DROP PROCEDURE IF EXISTS expanded_radet.proc_create_recapture_biometric();

CREATE OR REPLACE PROCEDURE expanded_radet.proc_create_recapture_biometric(
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
WHERE table_name = 'recapture_biometric';

-- Fetch record count from the remote database using dblink
EXECUTE format(
	'SELECT *
	 FROM dblink(''db_link_ods'',
	 ''
	 SELECT count(person_uuid) 
	 FROM ods_biometric 
	 WHERE ods_load_time >= ''%L''			   
	'') 
	 AS sm(count bigint)',last_load_end_time) 
INTO record_count;

DROP TABLE IF EXISTS expanded_radet.recapture_biometric;

SELECT TIMEOFDAY() INTO start_time;
EXECUTE FORMAT('CREATE TABLE expanded_radet.recapture_biometric AS
SELECT * FROM dblink(''db_link_ods'',
''SELECT DISTINCT ON (id, ods_datim_id) id,person_uuid,ods_datim_id,
enrollment_date,recapture, archived,count
FROM ods_biometric 
WHERE ods_load_time >= ''%L''
AND version_iso_20 is not null AND version_iso_20 is true 
--AND archived=0 
AND recapture!=0 and recapture is not null
GROUP BY id, person_uuid, ods_datim_id, enrollment_date,recapture, archived, count'')
AS sm(id character varying, person_uuid character varying,ods_datim_id character varying, 
	  enrollment_date date,recapture integer,archived integer,count bigint)',
	  last_load_end_time);

SELECT TIMEOFDAY() INTO end_time;

ALTER TABLE expanded_radet.recapture_biometric
ADD CONSTRAINT unq_recapture_biometric UNIQUE (id,person_uuid,ods_datim_id);

CREATE INDEX unq_basebiometric_personuuid_datimid 
ON expanded_radet.recapture_biometric(person_uuid, ods_datim_id);

DELETE FROM expanded_radet.recapture_biometric
WHERE archived=1;

INSERT INTO public.streaming_remote_monitoring(table_name,start_time,load_end_time,inserted_count,record_count)
VALUES('recapture_biometric', start_time, end_time,record_count,record_count);

			 
END 
$BODY$;
ALTER PROCEDURE expanded_radet.proc_create_recapture_biometric()
    OWNER TO lamisplus_etl;
