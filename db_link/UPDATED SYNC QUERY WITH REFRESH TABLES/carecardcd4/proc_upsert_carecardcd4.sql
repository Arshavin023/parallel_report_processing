-- PROCEDURE: expanded_radet.proc_upsert_carecardcd4()

-- DROP PROCEDURE IF EXISTS expanded_radet.proc_upsert_carecardcd4();

CREATE OR REPLACE PROCEDURE expanded_radet.proc_upsert_carecardcd4(
	)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE 
		last_load_end_time TIMESTAMP;
		start_time TIMESTAMP;
		end_time TIMESTAMP;
		record_count bigint;
		inserted_count bigint;
		updated_count bigint;

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

-- Use a temporary table to capture the rows affected by the upsert
CREATE TEMP TABLE temp_upsert_carecardcd4 (
		uuid character varying,
        cccd4_person_uuid character varying,
        pharma_ods_datim_id character varying
    );

EXECUTE FORMAT('INSERT INTO expanded_radet.carecardcd4
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
	visit_date date, cd_4 character varying,archived integer)
	ON CONFLICT (uuid,cccd4_person_uuid,care_ods_datim_id)
	DO 	UPDATE SET  
		visit_date = EXCLUDED.visit_date,
		cd_4 = EXCLUDED.cd_4
		RETURNING uuid,cccd4_person_uuid,care_ods_datim_id
		INTO temp_upsert_carecardcd4',
		last_load_end_time);

-- Count the number of rows inserted and updated
SELECT COUNT(cccd4_person_uuid) INTO inserted_count
FROM temp_upsert_carecardcd4
WHERE NOT EXISTS (
	SELECT 1
	FROM expanded_radet.pharmacy_details_regimen t
	WHERE t.uuid = temp_upsert_carecardcd4.uuid
	AND t.pharma_ods_datim_id = temp_upsert_carecardcd4.care_ods_datim_id
	AND t.person_uuid40=temp_upsert_carecardcd4.cccd4_person_uuid
);

SELECT COUNT(cccd4_person_uuid) INTO updated_count
FROM temp_upsert_carecardcd4
WHERE EXISTS (
	SELECT 1
	FROM expanded_radet.pharmacy_details_regimen t
	WHERE t.uuid = temp_upsert_carecardcd4.uuid
	AND t.pharma_ods_datim_id = temp_upsert_carecardcd4.care_ods_datim_id
	AND t.person_uuid40=temp_upsert_carecardcd4.cccd4_person_uuid
);

INSERT INTO public.streaming_remote_monitoring(table_name,start_time,load_end_time,inserted_count,updated_count,record_count)
VALUES('carecardcd4',start_time, end_time,inserted_count, updated_count, record_count);
	
			 
END 
$BODY$;
ALTER PROCEDURE expanded_radet.proc_upsert_carecardcd4()
    OWNER TO lamisplus_etl;
