-- PROCEDURE: expanded_radet.proc_upsert_tbstatus_tbscreening()

-- DROP PROCEDURE IF EXISTS expanded_radet.proc_upsert_tbstatus_tbscreening();

CREATE OR REPLACE PROCEDURE expanded_radet.proc_upsert_tbstatus_tbscreening(
	)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE start_time TIMESTAMP;
DECLARE end_time TIMESTAMP;
DECLARE record_count bigint;
BEGIN

SELECT TIMEOFDAY() INTO start_time;

select * from dblink('db_link_ods',
'SELECT count(uuid) FROM ods_hiv_observation p
					 WHERE ods_load_time > (select end_time FROM streaming_remote_monitoring
											WHERE table_name = ''tbstatus_tbscreening'' 
											ORDER BY end_time desc LIMIT 1)')
AS sm(count bigint) INTO record_count;

INSERT INTO expanded_radet.tbstatus_tbscreening
select * from dblink('db_link_ods',
'SELECT uuid, person_uuid, ods_datim_id , id, date_of_observation AS dateOfTbScreened, 
					 data->''tbIptScreening''->>''status'' AS tbStatus, 
		data->''tbIptScreening''->>''tbScreeningType'' AS tbScreeningType, 
	data->''tbIptScreening''->>''outcome'' AS tbStatusOutcome,hiv.archived
FROM (SELECT id, uuid, type,person_uuid, ods_datim_id, date_of_observation, data
		FROM ods_hiv_observation WHERE ods_load_time > (select end_time FROM streaming_remote_monitoring
											WHERE table_name = ''tbstatus_tbscreening''
											ORDER BY end_time desc LIMIT 1)) hiv
WHERE type = ''Chronic Care'' and data is not null
')AS sm(uuid character varying, person_uuid character varying,ods_datim_id character varying,
		id bigint, dateoftbscreened date,tbstatus text, tbscreeningtype text, tbstatusoutcome text,
	   archived integer)
ON CONFLICT(id, uuid,person_uuid, ods_datim_id)
DO UPDATE SET
	archived=EXCLUDED.archived,
	dateOfTbScreened=EXCLUDED.dateOfTbScreened,
	tbStatus=EXCLUDED.tbStatus,
	tbScreeningType=EXCLUDED.tbScreeningType,
	tbStatusOutcome=EXCLUDED.tbStatusOutcome
;

SELECT MAX(ods_load_time)
FROM ods_hiv_observation
INTO end_time;

PERFORM dblink('db_link_ods',
      format('INSERT INTO public.streaming_remote_monitoring(table_name,record_count,start_time,end_time) 
			 VALUES (''%s'',%L, %L, %L)',
             'tbstatus_tbscreening', record_count,start_time, end_time));
			 
END 
$BODY$;
ALTER PROCEDURE expanded_radet.proc_upsert_tbstatus_tbscreening()
    OWNER TO lamisplus_etl;
