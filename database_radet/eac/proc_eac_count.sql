-- PROCEDURE: expANDed_radet.proc_eac_count()

-- DROP PROCEDURE IF EXISTS expANDed_radet.proc_eac_count();

CREATE OR REPLACE PROCEDURE expANDed_radet.proc_eac_count(
	)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE end_time TIMESTAMP;
DECLARE start_time TIMESTAMP;
BEGIN

SELECT TIMEOFDAY() INTO start_time;

DROP TABLE if exists expanded_radet.eac_count_new;
CREATE TABLE expanded_radet.eac_count_new AS
select hes.person_uuid,hes.ods_datim_id, COUNT(*) no_eac_session 
FROM ods_hiv_eac_session hes 
JOIN expANDed_radet.current_eac ce on ce.person_uuid = hes.person_uuid 
AND ce.ods_datim_id=hes.ods_datim_id
AND hes.eac_session_date between '1980-01-01' AND (select date FROM expANDed_radet.period where is_active)
AND hes.status in ('FIRST EAC', 'SECOND EAC', 'THIRD EAC')
GROUP BY 1,2;

DROP TABLE IF EXISTS expanded_radet.eac_count;

ALTER TABLE expanded_radet.eac_count_new RENAME TO eac_count;

CREATE INDEX personuuiddatim_eac_count
ON expanded_radet.eac_count(person_uuid,ods_datim_id);

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time) 
VALUES ('eac_count', start_time,end_time);
END
$BODY$;
ALTER PROCEDURE expanded_radet.proc_eac_count()
    OWNER TO lamisplus_etl;
