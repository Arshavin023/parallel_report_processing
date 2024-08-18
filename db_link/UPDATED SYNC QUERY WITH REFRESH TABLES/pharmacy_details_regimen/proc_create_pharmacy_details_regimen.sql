--SELECT dblink_connect('db_link_ods', 'host=localhost user=lamisplus_etl password=QUWeIQvD27BYei1 dbname=lamisplus_ods_dwh');

---drop table if exists expanded_radet.pharmacy_details_regimen;
--
-- Name: proc_create_pharmacy_details_regimen(); Type: PROCEDURE; Schema: expanded_radet; Owner: lamisplus_etl
--
CREATE OR REPLACE PROCEDURE expanded_radet.proc_create_pharmacy_details_regimen()
    LANGUAGE plpgsql
    AS $_$
DECLARE start_time TIMESTAMP;
DECLARE last_load_end_time TIMESTAMP;
DECLARE end_time TIMESTAMP;
DECLARE record_count bigint;

BEGIN
-- Fetch the last load end time
SELECT MAX(load_end_time) 
INTO last_load_end_time
FROM streaming_remote_monitoring
WHERE table_name = 'pharmacy_details_regimen';

-- Fetch record count from the remote database using dblink
EXECUTE format(
	'SELECT *
	 FROM dblink(''db_link_ods'',
	 ''
	 SELECT count(uuid) 
	 FROM ods_hiv_art_pharmacy 
	 WHERE ods_load_time >= ''%L''			   
	'') 
	 AS sm(count bigint)',last_load_end_time) 
INTO record_count;


DROP TABLE IF EXISTS expanded_radet.pharmacy_details_regimen;

SELECT TIMEOFDAY() INTO start_time;

EXECUTE FORMAT('CREATE TABLE expanded_radet.pharmacy_details_regimen AS
	SELECT * from dblink(''db_link_ods'',
	''SELECT DISTINCT ON (p.uuid,p.ods_datim_id) p.uuid, p.person_uuid AS person_uuid40,p.ods_datim_id as pharma_ods_datim_id,
						 COALESCE(ds_model.display, p.dsd_model_type) as dsdModel, 
	p.visit_date ,r.description as ods_hiv_regimen_description, 
	rt.description as ods_hiv_regimen_type_description ,p.next_appointment, r.regimen_type_id,
	p.refill_period,p.archived,TIMEOFDAY() AS phar_details_regimen_load_time
	from (SELECT id,uuid,person_uuid,ods_datim_id,dsd_model_type,archived,
						 visit_date,refill_period,next_appointment,ods_load_time
			FROM public.ods_hiv_art_pharmacy 
		WHERE ods_load_time >= ''%L'') p 
	INNER JOIN public.ods_hiv_art_pharmacy_regimens pr ON pr.art_pharmacy_id = p.id AND pr.ods_datim_id = p.ods_datim_id  
	LEFT JOIN public.ods_hiv_regimen r on r.id = pr.regimens_id AND r.ods_datim_id = pr.ods_datim_id						--INNER
	LEFT JOIN public.ods_hiv_regimen_type rt on rt.id = r.regimen_type_id AND rt.ods_datim_id = r.ods_datim_id				--INNER
	LEFT OUTER JOIN ods_base_application_codeset ds_model on ds_model.code = p.dsd_model_type  
	AND ds_model.ods_datim_id = p.ods_datim_id'')
	AS sm(uuid character varying, person_uuid40 character varying, pharma_ods_datim_id character varying,
	dsdmodel character varying, visit_date date,ods_hiv_regimen_description character varying,
	ods_hiv_regimen_type_description character varying, next_appointment date, regimen_type_id bigint,
	refill_period integer,archived integer,phar_details_regimen_load_time TIMESTAMP)',last_load_end_time);

SELECT TIMEOFDAY() INTO end_time;

ALTER TABLE expanded_radet.pharmacy_details_regimen
ADD CONSTRAINT unq_uuid_datimid_pharmacy_details_regimen UNIQUE (uuid, person_uuid40,pharma_ods_datim_id);

CREATE INDEX unq_dateofoutcome_archived_pharmacy_details_regimen 
ON expanded_radet.pharmacy_details_regimen(regimen_type_id,visit_date,refill_period)
WHERE regimen_type_id in (1, 2, 3, 4, 14)
AND visit_date is not null AND refill_period is not null 
AND ods_hiv_regimen_description IS NOT NULL	
AND ods_hiv_regimen_type_description IS NOT NULL;

DELETE FROM expanded_radet.pharmacy_details_regimen
WHERE archived=1;

INSERT INTO public.streaming_remote_monitoring(table_name,start_time,load_end_time,record_count,inserted_count)
VALUES('pharmacy_details_regimen',start_time, end_time,record_count, record_count);
		 
END $_$;
ALTER PROCEDURE expanded_radet.proc_create_pharmacy_details_regimen() OWNER TO lamisplus_etl;

--call expanded_radet.proc_create_pharmacy_details_regimen();