-- PROCEDURE: expanded_radet.proc_create_cryptocol_antigen()

-- DROP PROCEDURE IF EXISTS expanded_radet.proc_create_cryptocol_antigen();

CREATE OR REPLACE PROCEDURE expanded_radet.proc_create_cryptocol_antigen(
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
WHERE table_name = 'cryptocol_antigen';

-- Fetch record count from the remote database using dblink
EXECUTE FORMAT(
	'SELECT *
	 FROM dblink(''db_link_ods'',
	 ''
	 SELECT count(uuid) 
	 FROM ods_laboratory_test 
	 WHERE ods_load_time >= ''%L''			   
	'') 
	 AS sm(count bigint)',last_load_end_time) 
INTO record_count;

DROP TABLE IF EXISTS expanded_radet.cryptocol_antigen;

SELECT TIMEOFDAY() INTO start_time;

EXECUTE FORMAT('CREATE TABLE expanded_radet.cryptocol_antigen AS
SELECT * FROM dblink(''db_link_ods'',
''SELECT DISTINCT ON (lr.patient_uuid, lr.ods_datim_id) lr.patient_uuid as personuuid12,
	lr.ods_datim_id as crypt_ods_datim_id, lr.uuid,lr.archived,
CAST(lr.date_result_reported AS DATE) AS dateOfLastCrytococalAntigen, 
lr.result_reported AS lastCrytococalAntigen 
from (SELECT id,uuid,ods_datim_id,archived,lab_test_id
		FROM ods_laboratory_test
		WHERE ods_load_time >= ''%L'') lt 
INNER JOIN ods_laboratory_result lr on lr.test_id = lt.id 
AND lr.ods_datim_id = lt.ods_datim_id
WHERE lt.lab_test_id IN (52,69,70) AND lr.date_result_reported IS NOT NULL 
AND lr.result_reported is NOT NULL'')
AS sm(personuuid12 character varying,crypt_ods_datim_id character varying,
	   uuid character varying,archived integer, dateOfLastCrytococalAntigen date,
	lastCrytococalAntigen character varying)',last_load_end_time);

SELECT TIMEOFDAY() INTO end_time;

ALTER TABLE expanded_radet.cryptocol_antigen
ADD CONSTRAINT unq_uuid_datimid_cryptocol_antigen UNIQUE (uuid, personuuid12, crypt_ods_datim_id);

CREATE INDEX unq_dateresultreported_cryptocol_antigen 
ON expanded_radet.cryptocol_antigen(dateOfLastCrytococalAntigen)
WHERE lab_test_id IN (52,69,70)
AND dateOfLastCrytococalAntigen IS NOT NULL 
AND lastCrytococalAntigen is NOT NULL;

DELETE FROM expanded_radet.pharmacy_details_regimen
WHERE archived=1;

INSERT INTO public.streaming_remote_monitoring(table_name,start_time,load_end_time,record_count,inserted_count)
VALUES('cryptocol_antigen',start_time, end_time,record_count, record_count);

			 
END 
$BODY$;
ALTER PROCEDURE expanded_radet.proc_create_cryptocol_antigen()
    OWNER TO lamisplus_etl;
