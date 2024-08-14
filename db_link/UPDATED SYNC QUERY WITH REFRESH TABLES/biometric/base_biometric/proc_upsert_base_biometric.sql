-- PROCEDURE: expanded_radet.proc_upsert_base_biometric()

-- DROP PROCEDURE IF EXISTS expanded_radet.proc_upsert_base_biometric();

CREATE OR REPLACE PROCEDURE expanded_radet.proc_upsert_base_biometric(
	)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE start_time TIMESTAMP;
DECLARE end_time TIMESTAMP;
DECLARE record_count bigint;
BEGIN

SELECT TIMEOFDAY() INTO start_time;

select * from dblink('db_link_ods',
'SELECT count(person_uuid) FROM ods_biometric
					 WHERE ods_load_time > (select end_time FROM streaming_remote_monitoring
											WHERE table_name = ''ods_base_biometric'' 
											ORDER BY end_time desc LIMIT 1)')
AS sm(count bigint) INTO record_count;

INSERT INTO expanded_radet.base_biometric
select * from dblink('db_link_ods',
'SELECT DISTINCT ON (id, person_uuid, ods_datim_id) id,person_uuid,ods_datim_id,
					 enrollment_date,recapture, archived,facility_id,count
					FROM ods_biometric WHERE ods_load_time > (
					 select end_time FROM streaming_remote_monitoring
					WHERE table_name = ''ods_base_biometric'' 
					ORDER BY end_time desc LIMIT 1)
AND version_iso_20 is not null AND version_iso_20 is true 
--AND archived=0 
AND recapture=0
GROUP BY id, person_uuid, ods_datim_id, enrollment_date,recapture, archived, facility_id,count')
AS sm(id character varying, person_uuid character varying,ods_datim_id character varying, enrollment_date date,
	  recapture integer,archived integer,facility_id bigint,count bigint)
ON CONFLICT (id,person_uuid,ods_datim_id,facility_id)
DO UPDATE SET
	archived=EXCLUDED.archived
	;

SELECT MAX(ods_load_time)
FROM ods_biometric
INTO end_time;

PERFORM dblink('db_link_ods',
      format('INSERT INTO public.streaming_remote_monitoring(table_name,record_count,start_time,end_time) 
			 VALUES (''%s'',%L, %L, %L)',
             'ods_base_biometric', record_count,start_time, end_time));
			 
END 
$BODY$;
ALTER PROCEDURE expanded_radet.proc_upsert_base_biometric()
    OWNER TO lamisplus_etl;
