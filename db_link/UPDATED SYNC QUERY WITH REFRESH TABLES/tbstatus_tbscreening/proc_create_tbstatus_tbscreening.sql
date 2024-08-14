-- PROCEDURE: expanded_radet.proc_create_tbstatus_tbscreening()

-- DROP PROCEDURE IF EXISTS expanded_radet.proc_create_tbstatus_tbscreening();

CREATE OR REPLACE PROCEDURE expanded_radet.proc_create_tbstatus_tbscreening(
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

DROP TABLE IF EXISTS expanded_radet.tbstatus_tbscreening;
create table expanded_radet.tbstatus_tbscreening AS
select * from dblink('db_link_ods',
'SELECT hiv.uuid, hiv.person_uuid, hiv.ods_datim_id , hiv.id, hiv.date_of_observation AS dateOfTbScreened, 
					 hiv.data->''tbIptScreening''->>''status'' AS tbStatus, 
		hiv.data->''tbIptScreening''->>''tbScreeningType'' AS tbScreeningType, 
	hiv.data->''tbIptScreening''->>''outcome'' AS tbStatusOutcome,hiv.archived
FROM (SELECT id, uuid, type,person_uuid, ods_datim_id, date_of_observation,archived, data
		FROM ods_hiv_observation WHERE ods_load_time > (select end_time FROM streaming_remote_monitoring
											WHERE table_name = ''tbstatus_tbscreening''
											ORDER BY end_time desc LIMIT 1)) hiv
WHERE type = ''Chronic Care'' and data is not null
')AS sm(uuid character varying, person_uuid character varying,ods_datim_id character varying,
		id bigint, dateoftbscreened date,tbstatus text, tbscreeningtype text, 
		tbstatusoutcome text,archived integer);

ALTER TABLE expanded_radet.tbstatus_tbscreening
ADD CONSTRAINT unq_tbstatus_tbscreening UNIQUE (id, uuid, person_uuid,ods_datim_id);

CREATE INDEX unq_dateOfTbScreened_tbstatus_tbscreening 
ON expanded_radet.tbstatus_tbscreening(dateOfTbScreened);

SELECT MAX(ods_load_time)
FROM ods_hiv_observation
INTO end_time;

PERFORM dblink('db_link_ods',
      format('INSERT INTO public.streaming_remote_monitoring(table_name,record_count,start_time,end_time) 
			 VALUES (''%s'',%L, %L, %L)',
             'tbstatus_tbscreening', record_count,start_time, end_time));
			 
END 
$BODY$;
ALTER PROCEDURE expanded_radet.proc_create_tbstatus_tbscreening()
    OWNER TO lamisplus_etl;
