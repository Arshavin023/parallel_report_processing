--SELECT dblink_connect('db_link_ods', 'host=localhost user=lamisplus_etl password=QUWeIQvD27BYei1 dbname=lamisplus_ods_dwh');
--
-- Name: proc_upsert_recapture_biometric(); Type: PROCEDURE; Schema: expanded_radet; Owner: lamisplus_etl
--
CREATE OR REPLACE PROCEDURE expanded_radet.proc_upsert_recapture_biometric()
    LANGUAGE plpgsql
    AS $_$
DECLARE start_time TIMESTAMP;
DECLARE last_load_end_time TIMESTAMP;
DECLARE end_time TIMESTAMP;
DECLARE record_count bigint;
DECLARE inserted_count bigint;
DECLARE updated_count bigint;

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

-- Use a temporary table to capture the rows affected by the upsert
CREATE TEMP TABLE temp_upsert_recapture_biometric (
		personuuid character varying,
        ods_datim_id character varying
    );

SELECT TIMEOFDAY() INTO start_time;

EXECUTE FORMAT('INSERT INTO expanded_radet.recapture_biometric
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
	  enrollment_date date,recapture integer,archived integer,count bigint)
	  
ON CONFLICT (person_uuid, ods_datim_id)
DO UPDATE SET     
	enrollment_date = EXCLUDED.enrollment_date,
    recapture = EXCLUDED.recapture,
	count = EXCLUDED.count
	RETURNING person_uuid, ods_datim_id INTO temp_upsert_recapture_biometric',
	last_load_end_time);

SELECT TIMEOFDAY() INTO end_time;

DELETE FROM expanded_radet.recapture_biometric
WHERE archived=1;

-- Count the number of rows inserted and updated
SELECT COUNT(person_uuid) INTO inserted_count
FROM temp_upsert_recapture_biometric
WHERE NOT EXISTS (
	SELECT 1
	FROM expanded_radet.cryptocol_antigen t
	WHERE t.person_uuid = temp_upsert_recapture_biometric.person_uuid
	AND t.ods_datim_id = temp_upsert_recapture_biometric.ods_datim_id
);

SELECT COUNT(person_uuid) INTO updated_count
FROM temp_upsert_recapture_biometric
WHERE EXISTS (
	SELECT 1
	FROM expanded_radet.cryptocol_antigen t
	WHERE t.person_uuid = temp_upsert_recapture_biometric.person_uuid
	AND t.ods_datim_id = temp_upsert_recapture_biometric.ods_datim_id
);


INSERT INTO public.streaming_remote_monitoring(table_name,start_time,load_end_time,inserted_count,updated_count,record_count)
VALUES('recapture_biometric',start_time, end_time,inserted_count,updated_count,record_count);
			 
END $_$;
ALTER PROCEDURE expanded_radet.proc_upsert_recapture_biometric() OWNER TO lamisplus_etl;

--call expanded_radet.proc_upsert_recapture_biometric();