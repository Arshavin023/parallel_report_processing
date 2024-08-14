-- PROCEDURE: expanded_radet.proc_upsert_cryptocol_antigen()

-- DROP PROCEDURE IF EXISTS expanded_radet.proc_upsert_cryptocol_antigen();

CREATE OR REPLACE PROCEDURE expanded_radet.proc_upsert_cryptocol_antigen(
	)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE start_time TIMESTAMP;
DECLARE end_time TIMESTAMP;
DECLARE record_count bigint;
BEGIN

SELECT TIMEOFDAY() INTO start_time;

select * from dblink('db_link_ods',
'SELECT count(uuid) FROM ods_laboratory_test
					 WHERE ods_load_time > (select end_time FROM streaming_remote_monitoring
											WHERE table_name = ''cryptocol_antigen'' 
											ORDER BY end_time desc LIMIT 1)')
AS sm(count bigint) INTO record_count;

INSERT INTO expanded_radet.cryptocol_antigen
select * from dblink('db_link_ods',
'select DISTINCT ON (lr.patient_uuid, lr.ods_datim_id) lr.patient_uuid as personuuid12,
lr.ods_datim_id as crypt_ods_datim_id,lt.id, lt.uuid,lt.archived,lt.lab_test_id,
CAST(lr.date_result_reported AS DATE) AS dateOfLastCrytococalAntigen, 
lr.result_reported AS lastCrytococalAntigen 
from (SELECT id,uuid,ods_datim_id,archived,lab_test_id
		FROM ods_laboratory_test
		WHERE ods_load_time > (select end_time FROM streaming_remote_monitoring
								WHERE table_name = ''cryptocol_antigen'' 
								ORDER BY end_time desc LIMIT 1)) lt 
inner join ods_laboratory_result lr on lr.test_id = lt.id AND lr.ods_datim_id = lt.ods_datim_id
WHERE lab_test_id IN (52,69,70)
AND lr.date_result_reported IS NOT NULL 
AND lr.result_reported is NOT NULL
')AS sm(personuuid12 character varying,crypt_ods_datim_id character varying,id bigint,
    uuid character varying,archived integer,lab_test_id integer,dateOfLastCrytococalAntigen date,
		lastCrytococalAntigen character varying)

ON CONFLICT(id, uuid, personuuid12, crypt_ods_datim_id)
DO UPDATE SET
	uuid=EXCLUDED.uuid,
	personuuid12=EXCLUDED.personuuid12,
	lab_test_id=EXCLUDED.lab_test_id,
	archived=EXCLUDED.archived,
	dateOfLastCrytococalAntigen=EXCLUDED.dateOfLastCrytococalAntigen,
	lastCrytococalAntigen=EXCLUDED.lastCrytococalAntigen;

SELECT MAX(ods_load_time)
FROM ods_laboratory_test
INTO end_time;

PERFORM dblink('db_link_ods',
      format('INSERT INTO public.streaming_remote_monitoring(table_name,record_count,start_time,end_time) 
			 VALUES (''%s'',%L, %L, %L)',
             'cryptocol_antigen', record_count,start_time, end_time)); 
END 
$BODY$;
ALTER PROCEDURE expanded_radet.proc_upsert_cryptocol_antigen()
    OWNER TO lamisplus_etl;
