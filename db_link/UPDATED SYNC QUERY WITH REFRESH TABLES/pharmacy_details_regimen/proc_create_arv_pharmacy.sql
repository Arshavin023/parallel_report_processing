--drop table if exists expanded_radet.arv_pharmacy;
--
-- Name: proc_create_arv_pharmacy(); Type: PROCEDURE; Schema: expanded_radet; Owner: lamisplus_etl
--
CREATE OR REPLACE PROCEDURE expanded_radet.proc_create_arv_pharmacy()
    LANGUAGE plpgsql
    AS $_$
DECLARE start_time TIMESTAMP;
DECLARE end_time TIMESTAMP;
DECLARE record_count bigint;
BEGIN

SELECT TIMEOFDAY() INTO start_time;

EXECUTE format('SELECT count(uuid) FROM expanded_radet.pharmacy_details_regimen
				WHERE phar_details_regimen_load_time > 
			   (select load_end_time FROM public.streaming_remote_monitoring
					WHERE table_name = ''arv_pharmacy''
					ORDER BY load_end_time desc LIMIT 1)')
INTO record_count;

CREATE TABLE expanded_radet.arv_pharmacy AS
SELECT uuid, person_uuid40, pharma_ods_datim_id, dsdModel,visit_date as dateofStartofCurrentARTRegimen,
ods_hiv_regimen_description as currentARTRegimen,ods_hiv_regimen_type_description as currentRegimenLine,
p.next_appointment as nextPickupDate, 
CAST(CAST(refill_period AS INTEGER) / 30.0 AS DECIMAL(10, 1)) AS monthsOfARVRefill
FROM (SELECT uuid, person_uuid40, pharma_ods_datim_id, dsdmodel, visit_date, ods_hiv_regimen_description, 
	  ods_hiv_regimen_type_description, next_appointment, regimen_type_id, refill_period, 
	  phar_details_regimen_load_time 
	  FROM expanded_radet.pharmacy_details_regimen
	  WHERE phar_details_regimen_load_time > 
				   (select load_end_time FROM public.streaming_remote_monitoring
						WHERE table_name = 'arv_pharmacy'
						ORDER BY load_end_time desc LIMIT 1)) p
WHERE regimen_type_id in (1, 2, 3, 4, 14) 
--AND p.archived = 0 
AND visit_date is not null
AND refill_period is not null 
AND ods_hiv_regimen_description IS NOT NULL
AND ods_hiv_regimen_type_description IS NOT NULL
;

ALTER TABLE expanded_radet.arv_pharmacy
ADD CONSTRAINT unq_uuid_datimid_arv_pharmacy UNIQUE (uuid, person_uuid40, pharma_ods_datim_id);

CREATE INDEX unq_visitdate_arv_pharmacy ON expanded_radet.arv_pharmacy(dateofStartofCurrentARTRegimen);

SELECT TIMEOFDAY() INTO end_time;

EXECUTE format('INSERT INTO public.streaming_remote_monitoring(table_name,record_count,load_start_time,load_end_time) 
			 VALUES (''%s'',%L, %L, %L)',
			 'arv_pharmacy', record_count,start_time, end_time);
			 
END $_$;
ALTER PROCEDURE expanded_radet.proc_create_arv_pharmacy() OWNER TO lamisplus_etl;

--call expanded_radet.proc_create_arv_pharmacy();