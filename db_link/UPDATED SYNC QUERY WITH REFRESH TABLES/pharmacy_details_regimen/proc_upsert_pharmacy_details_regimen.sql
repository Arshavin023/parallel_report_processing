-- PROCEDURE: expanded_radet.proc_upsert_pharmacy_details_regimen()

-- DROP PROCEDURE IF EXISTS expanded_radet.proc_upsert_pharmacy_details_regimen();

CREATE OR REPLACE PROCEDURE expanded_radet.proc_upsert_pharmacy_details_regimen(
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

-- Use a temporary table to capture the rows affected by the upsert
CREATE TEMP TABLE temp_upsert_pharmacy_details_regimen (
		uuid character varying,
        person_uuid40 character varying,
        pharma_ods_datim_id character varying
    );

SELECT TIMEOFDAY() INTO start_time;

EXECUTE FORMAT('INSERT INTO expanded_radet.pharmacy_details_regimen
	SELECT * from dblink(''db_link_ods'',
	''SELECT DISTINCT ON (p.uuid,p.ods_datim_id) p.uuid, p.person_uuid AS person_uuid40,
	p.ods_datim_id as pharma_ods_datim_id,COALESCE(ds_model.display, p.dsd_model_type) as dsdModel, 
	p.visit_date ,r.description as ods_hiv_regimen_description, 
	rt.description as ods_hiv_regimen_type_description ,p.next_appointment, r.regimen_type_id,
	p.refill_period,p.archived
	from (SELECT id,uuid,person_uuid,ods_datim_id,dsd_model_type,archived,
						 visit_date,refill_period,next_appointment
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
	refill_period integer,archived integer)

	ON CONFLICT(uuid, person_uuid40,pharma_ods_datim_id)
	DO UPDATE SET
		archived=EXCLUDED.archived,
		dsdmodel=EXCLUDED.dsdmodel,
		visit_date=EXCLUDED.visit_date,
		ods_hiv_regimen_description=EXCLUDED.ods_hiv_regimen_description,
		ods_hiv_regimen_type_description=EXCLUDED.ods_hiv_regimen_type_description,
		next_appointment=EXCLUDED.next_appointment,
		regimen_type_id=EXCLUDED.regimen_type_id,
		refill_period=EXCLUDED.refill_period
		RETURNING uuid, person_uuid40,pharma_ods_datim_id 
		INTO temp_upsert_pharmacy_details_regimen
		',last_load_end_time);

SELECT TIMEOFDAY() INTO end_time;

DELETE FROM expanded_radet.pharmacy_details_regimen
WHERE archived=1;

-- Count the number of rows inserted and updated
SELECT COUNT(person_uuid40) INTO inserted_count
FROM temp_upsert_pharmacy_details_regimen
WHERE NOT EXISTS (
	SELECT 1
	FROM expanded_radet.pharmacy_details_regimen t
	WHERE t.uuid = temp_upsert_pharmacy_details_regimen.uuid
	AND t.pharma_ods_datim_id = temp_upsert_pharmacy_details_regimen.pharma_ods_datim_id
	AND t.person_uuid40=temp_upsert_pharmacy_details_regimen.person_uuid40
);

SELECT COUNT(person_uuid40) INTO updated_count
FROM temp_upsert_pharmacy_details_regimen
WHERE EXISTS (
	SELECT 1
	FROM expanded_radet.pharmacy_details_regimen t
	WHERE t.uuid = temp_upsert_pharmacy_details_regimen.uuid
	AND t.pharma_ods_datim_id = temp_upsert_pharmacy_details_regimen.pharma_ods_datim_id
	AND t.person_uuid40=temp_upsert_pharmacy_details_regimen.person_uuid40
);

INSERT INTO public.streaming_remote_monitoring(table_name,start_time,load_end_time,inserted_count,updated_count,record_count)
VALUES('pharmacy_details_regimen',start_time, end_time,inserted_count, updated_count, record_count);
	
END 
$BODY$;
ALTER PROCEDURE expanded_radet.proc_upsert_pharmacy_details_regimen()
    OWNER TO lamisplus_etl;
