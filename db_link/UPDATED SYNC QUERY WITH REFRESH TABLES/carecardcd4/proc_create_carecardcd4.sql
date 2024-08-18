-- PROCEDURE: expanded_radet.proc_create_carecardcd4()

-- DROP PROCEDURE IF EXISTS expanded_radet.proc_create_carecardcd4();

CREATE OR REPLACE PROCEDURE expanded_radet.proc_create_carecardcd4(
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
WHERE table_name = 'carecardcd4';

-- Fetch record count from the remote database using dblink
EXECUTE format(
	'SELECT *
	 FROM dblink(''db_link_ods'',
	 ''
	 SELECT count(uuid) 
	 FROM ods_hiv_art_clinical 
	 WHERE ods_load_time >= ''%L''			   
	'') 
	 AS sm(count bigint)',last_load_end_time) 
INTO record_count;

DROP TABLE IF EXISTS expanded_radet.carecardcd4;

SELECT TIMEOFDAY() INTO start_time;

EXECUTE FORMAT('CREATE TABLE expanded_radet.carecardcd4 AS
SELECT * FROM dblink(''db_link_ods'',
''SELECT DISTINCT ON (hac.uuid,hac.ods_datim_id) hac.uuid, hac.person_uuid AS cccd4_person_uuid,
					hac.ods_datim_id as care_ods_datim_id,hac.visit_date,
					 coalesce(cast(cd_4 as varchar),cd4_semi_quantitative) as cd_4,
					 hac.archived
FROM (select uuid,person_uuid,ods_datim_id,cd_4,visit_date,archived
	 FROM public.ods_hiv_art_clinical 
	  WHERE ods_load_time >= ''%L'') hac 
WHERE is_commencement is true 
--AND archived = 0 
AND cd_4 != ''''0''''
'') 
AS sm(uuid character varying,cccd4_person_uuid character varying,care_ods_datim_id character varying, 
visit_date date, cd_4 character varying,archived integer)',last_load_end_time);

SELECT TIMEOFDAY() INTO end_time;

ALTER TABLE expanded_radet.carecardcd4
ADD CONSTRAINT unq_personuuid_uuid_datim_carecardcd4 UNIQUE (cccd4_person_uuid, uuid,care_ods_datim_id);

CREATE INDEX idx_carecardcd4_visitdate ON expanded_radet.carecardcd4(visit_date);

DELETE FROM expanded_radet.carecardcd4
WHERE archived=1;

INSERT INTO public.streaming_remote_monitoring(table_name,start_time,load_end_time,inserted_count,record_count)
VALUES('carecardcd4', start_time, end_time,record_count,record_count);

			 
END 
$BODY$;
ALTER PROCEDURE expanded_radet.proc_create_carecardcd4()
    OWNER TO lamisplus_etl;
