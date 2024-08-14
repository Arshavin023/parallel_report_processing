-- PROCEDURE: expanded_radet.proc_create_carecardcd4()

-- DROP PROCEDURE IF EXISTS expanded_radet.proc_create_carecardcd4();

CREATE OR REPLACE PROCEDURE expanded_radet.proc_create_carecardcd4(
	)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE start_time TIMESTAMP;
DECLARE end_time TIMESTAMP;
DECLARE record_count bigint;
BEGIN

SELECT TIMEOFDAY() INTO start_time;

select * from dblink('db_link_ods',
'SELECT count(uuid) FROM ods_hiv_art_clinical
					 WHERE ods_load_time > (select end_time FROM streaming_remote_monitoring
											WHERE table_name = ''carecardcd4'' 
											ORDER BY end_time DESC LIMIT 1)')
AS sm(count bigint) INTO record_count;

DROP TABLE IF EXISTS expanded_radet.carecardcd4;
create table expanded_radet.carecardcd4 AS
select * from dblink('db_link_ods',
'SELECT hac.person_uuid AS cccd4_person_uuid,hac.ods_datim_id as care_ods_datim_id, hac.uuid,
hac.visit_date,coalesce(cast(cd_4 as varchar),cd4_semi_quantitative) as cd_4,hac.archived
FROM (select * from public.ods_hiv_art_clinical 
	  WHERE ods_load_time > (select end_time FROM streaming_remote_monitoring
					WHERE table_name = ''carecardcd4'' 
					ORDER BY end_time desc LIMIT 1)) hac 
WHERE is_commencement is true 
--AND archived = 0 
AND cd_4 != ''0''
') AS sm(cccd4_person_uuid character varying,care_ods_datim_id character varying, 
	  uuid character varying,visit_date date, cd_4 character varying,archived integer);

ALTER TABLE expanded_radet.carecardcd4
ADD CONSTRAINT unq_personuuid_uuid_datim_carecardcd4 UNIQUE (cccd4_person_uuid, uuid,care_ods_datim_id);

CREATE INDEX idx_carecardcd4_visitdate ON expanded_radet.carecardcd4(visit_date);

SELECT max(ods_load_time) 
FROM ods_hiv_art_clinical
INTO end_time;

PERFORM dblink('db_link_ods',
      format('INSERT INTO public.streaming_remote_monitoring(table_name,record_count,start_time,end_time) 
			 VALUES (''%s'',%L, %L, %L)',
             'carecardcd4', record_count,start_time, end_time));
			 
END 
$BODY$;
ALTER PROCEDURE expanded_radet.proc_create_carecardcd4()
    OWNER TO lamisplus_etl;
