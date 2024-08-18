-- PROCEDURE: expanded_radet.proc_upsert_cryptocol_antigen()

-- DROP PROCEDURE IF EXISTS expanded_radet.proc_upsert_cryptocol_antigen();

CREATE OR REPLACE PROCEDURE expanded_radet.proc_upsert_cryptocol_antigen(
	)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE last_load_end_time TIMESTAMP;
DECLARE start_time TIMESTAMP;
DECLARE end_time TIMESTAMP;
DECLARE record_count bigint;
DEClARE inserted_count bigint;
DEClARE updated_count bigint;

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

-- Use a temporary table to capture the rows affected by the upsert
CREATE TEMP TABLE temp_upsert_cryptocol_antigen (
		id bigint,
		personuuid12 character varying,
        labtest_uuid character varying,
        crypt_ods_datim_id character varying
    );
	
EXECUTE FORMAT('INSERT INTO expanded_radet.cryptocol_antigen
SELECT * FROM dblink(''db_link_ods'',
''SELECT DISTINCT ON (lt.id,lt.ods_datim_id) lt.id,lt.uuid labtest_uuid,lt.lab_test_id,
					 lt.archived labtest_archived,lr.patient_uuid as personuuid12,
					 lr.ods_datim_id as crypt_ods_datim_id,
CAST(lr.date_result_reported AS DATE) AS dateOfLastCrytococalAntigen, 
lr.result_reported AS lastCrytococalAntigen 
from (SELECT id,uuid,ods_datim_id,archived,lab_test_id
		FROM ods_laboratory_test
		WHERE ods_load_time >= ''%L'') lt 
INNER JOIN ods_laboratory_result lr on lr.test_id = lt.id 
AND lr.ods_datim_id = lt.ods_datim_id
WHERE lab_test_id IN (52,69,70) AND lr.date_result_reported IS NOT NULL 
AND lr.result_reported is NOT NULL'')
AS sm(id bigint,labtest_uuid character varying,lab_test_id integer,labtest_archived integer,
		personuuid12 character varying,crypt_ods_datim_id character varying,
		dateOfLastCrytococalAntigen date,lastCrytococalAntigen character varying)
		
ON CONFLICT(id, labtest_uuid, personuuid12, crypt_ods_datim_id)
DO UPDATE SET
	lab_test_id=EXCLUDED.lab_test_id,
	archived=EXCLUDED.archived,
	dateOfLastCrytococalAntigen=EXCLUDED.dateOfLastCrytococalAntigen,
	lastCrytococalAntigen=EXCLUDED.lastCrytococalAntigen
	RETURNING id, labtest_uuid, personuuid12, crypt_ods_datim_id
	INTO temp_upsert_cryptocol_antigen',
	last_load_end_time);

SELECT TIMEOFDAY() INTO end_time;

DELETE FROM expanded_radet.cryptocol_antigen
WHERE labtest_archived=1;

-- Count the number of rows inserted and updated
SELECT COUNT(personuuid12) INTO inserted_count
FROM temp_upsert_cryptocol_antigen
WHERE NOT EXISTS (
	SELECT 1
	FROM expanded_radet.cryptocol_antigen t
	WHERE t.id = temp_upsert_cryptocol_antigen.id
	AND t.labtest_uuid = temp_upsert_cryptocol_antigen.labtest_uuid
	AND t.personuuid12 = temp_upsert_cryptocol_antigen.personuuid12
	AND t.crypt_ods_datim_id = temp_upsert_cryptocol_antigen.crypt_ods_datim_id
);

SELECT COUNT(personuuid12) INTO updated_count
FROM temp_upsert_cryptocol_antigen
WHERE EXISTS (
	SELECT 1
	FROM expanded_radet.cryptocol_antigen t
	WHERE t.id = temp_upsert_cryptocol_antigen.id
	AND t.labtest_uuid = temp_upsert_cryptocol_antigen.labtest_uuid
	AND t.personuuid12 = temp_upsert_cryptocol_antigen.personuuid12
	AND t.crypt_ods_datim_id = temp_upsert_cryptocol_antigen.crypt_ods_datim_id
);

INSERT INTO public.streaming_remote_monitoring(table_name,start_time,load_end_time,inserted_count,updated_count,record_count)
VALUES('cryptocol_antigen',start_time, end_time,inserted_count,updated_count, record_count);
		
END 
$BODY$;
ALTER PROCEDURE expanded_radet.proc_upsert_cryptocol_antigen()
    OWNER TO lamisplus_etl;
