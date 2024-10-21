-- PROCEDURE: expanded_radet.proc_first_eac()

-- DROP PROCEDURE IF EXISTS expanded_radet.proc_first_eac();

CREATE OR REPLACE PROCEDURE expanded_radet.proc_first_eac(
	)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE end_time TIMESTAMP;
DECLARE start_time TIMESTAMP;
BEGIN

SELECT TIMEOFDAY() INTO start_time;

DROP TABLE if exists expanded_radet.sub_first_hes;
CREATE TABLE expanded_radet.sub_first_hes AS
SELECT eac_id, ods_datim_id, person_uuid, eac_session_date,
ROW_NUMBER() OVER (PARTITION BY hes.person_uuid,hes.ods_datim_id  ORDER BY hes.eac_session_date ASC) AS row 
FROM public.ods_hiv_eac_session hes
WHERE eac_session_date BETWEEN '1980-01-01' 
AND (select date from expanded_radet.period where is_active) 
AND status IN ('FIRST EAC') AND archived=0;

CREATE INDEX row_sub_first_hes ON expanded_radet.sub_first_hes(row);

DROP TABLE IF EXISTS expanded_radet.first_hes;
CREATE TABLE expanded_radet.first_hes AS
SELECT * FROM expanded_radet.sub_first_hes WHERE row=1;

CREATE INDEX eacidpersonuuidodsdatimid_first_hes 
ON expanded_radet.first_hes(eac_id,person_uuid,ods_datim_id);

DROP TABLE IF EXISTS expanded_radet.first_eac_new;
CREATE TABLE expanded_radet.first_eac_new AS
select ce.id, ce.person_uuid, hes.eac_session_date, hes.ods_datim_id
FROM expanded_radet.first_hes hes 
JOIN expanded_radet.current_eac ce on hes.person_uuid=ce.person_uuid 
AND ce.uuid = hes.eac_id 
AND ce.ods_datim_id=hes.ods_datim_id;

DROP TABLE IF EXISTS expanded_radet.first_eac;

ALTER TABLE expanded_radet.first_eac_new RENAME TO first_eac;

CREATE INDEX personuuiddatim_first_eac ON expanded_radet.first_eac(person_uuid, ods_datim_id);

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time) 
VALUES ('first_eac', start_time,end_time);
END
$BODY$;
ALTER PROCEDURE expanded_radet.proc_first_eac()
    OWNER TO lamisplus_etl;