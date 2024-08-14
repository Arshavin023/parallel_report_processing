-- PROCEDURE: expanded_radet.proc_upsert_pharmacy_details_regimen()

-- DROP PROCEDURE IF EXISTS expanded_radet.proc_upsert_pharmacy_details_regimen();

CREATE OR REPLACE PROCEDURE expanded_radet.proc_upsert_pharmacy_details_regimen(
	)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE start_time TIMESTAMP;
DECLARE end_time TIMESTAMP;
DECLARE record_count bigint;
BEGIN

SELECT TIMEOFDAY() INTO start_time;

select * from dblink('db_link_ods',
'SELECT count(uuid) FROM ods_hiv_art_pharmacy p
					 WHERE ods_load_time > (select end_time FROM streaming_remote_monitoring
											WHERE table_name = ''pharmacy_details_regimen'' 
											ORDER BY end_time desc LIMIT 1)')
AS sm(count bigint) INTO record_count;

INSERT INTO expanded_radet.pharmacy_details_regimen
select * from dblink('db_link_ods',
'SELECT p.uuid, p.person_uuid as person_uuid40,p.ods_datim_id as pharma_ods_datim_id,
COALESCE(ds_model.display, p.dsd_model_type) as dsdModel, 
p.visit_date ,r.description as ods_hiv_regimen_description, 
rt.description as ods_hiv_regimen_type_description ,p.next_appointment, r.regimen_type_id,
p.refill_period,p.archived,TIMEOFDAY() AS phar_details_regimen_load_time
from (SELECT id,uuid,person_uuid,ods_datim_id,dsd_model_type,visit_date,refill_period,next_appointment,ods_load_time
		FROM public.ods_hiv_art_pharmacy WHERE ods_load_time > (select end_time FROM streaming_remote_monitoring
																WHERE table_name = ''pharmacy_details_regimen'' 
																ORDER BY end_time desc LIMIT 1)) p 
INNER JOIN public.ods_hiv_art_pharmacy_regimens pr ON pr.art_pharmacy_id = p.id AND pr.ods_datim_id = p.ods_datim_id  
LEFT JOIN public.ods_hiv_regimen r on r.id = pr.regimens_id AND r.ods_datim_id = pr.ods_datim_id						--INNER
LEFT JOIN public.ods_hiv_regimen_type rt on rt.id = r.regimen_type_id AND rt.ods_datim_id = r.ods_datim_id				--INNER
LEFT OUTER JOIN ods_base_application_codeset ds_model on ds_model.code = p.dsd_model_type  
AND ds_model.ods_datim_id = p.ods_datim_id 
')AS sm(uuid character varying, person_uuid40 character varying, pharma_ods_datim_id character varying,
dsdmodel character varying, visit_date date,ods_hiv_regimen_description character varying,
ods_hiv_regimen_type_description character varying, next_appointment date, regimen_type_id bigint,
refill_period integer,archived integer,phar_details_regimen_load_time TIMESTAMP)

ON CONFLICT(person_uuid40,pharma_ods_datim_id,uuid)
DO UPDATE SET
	archived=EXCLUDED.archived,
	dsdmodel=EXCLUDED.dsdmodel,
	visit_date=EXCLUDED.visit_date,
	ods_hiv_regimen_description=EXCLUDED.ods_hiv_regimen_description,
	ods_hiv_regimen_type_description=EXCLUDED.ods_hiv_regimen_type_description,
	next_appointment=EXCLUDED.next_appointment,
	regimen_type_id=EXCLUDED.regimen_type_id,
	refill_period=EXCLUDED.refill_period
;
	

SELECT MAX(ods_load_time)
FROM ods_hiv_art_pharmacy
INTO end_time;

PERFORM dblink('db_link_ods',
      format('INSERT INTO public.streaming_remote_monitoring(table_name,record_count,start_time,end_time) 
			 VALUES (''%s'',%L, %L, %L)',
             'pharmacy_details_regimen', record_count,start_time, end_time));
			 
END 
$BODY$;
ALTER PROCEDURE expanded_radet.proc_upsert_pharmacy_details_regimen()
    OWNER TO lamisplus_etl;
