-- PROCEDURE: expanded_radet.proc_post_eac_vl()

-- DROP PROCEDURE IF EXISTS expanded_radet.proc_post_eac_vl();

CREATE OR REPLACE PROCEDURE expanded_radet.proc_post_eac_vl(
	)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE end_time TIMESTAMP;
DECLARE start_time TIMESTAMP;
BEGIN

SELECT TIMEOFDAY() INTO start_time;

DROP TABLE if exists expanded_radet.sub_post_eac_vl;
CREATE TABLE expanded_radet.sub_post_eac_vl AS
select lt.patient_uuid, lt.ods_datim_id, cast(ls.date_sample_collected as date), lr.result_reported, 
cast(lr.date_result_reported as date), 
ROW_NUMBER() OVER (PARTITION BY lt.patient_uuid,lt.ods_datim_id ORDER BY ls.date_sample_collected DESC) AS row 
FROM ods_laboratory_test lt 
LEFT JOIN ods_laboratory_sample ls on ls.test_id = lt.id AND ls.ods_datim_id=lt.ods_datim_id AND ls.patient_uuid=lt.patient_uuid
LEFT JOIN ods_laboratory_result lr on lr.test_id = lt.id AND lr.ods_datim_id=lt.ods_datim_id AND lr.patient_uuid=lt.patient_uuid
WHERE lt.viral_load_indication = '302' AND lt.archived = '0' AND ls.archived = '0' 
AND ls.date_sample_collected between '1980-01-01' AND (select date FROM expanded_radet.period WHERE is_active);

CREATE INDEX row_sub_post_eac_vl ON expanded_radet.sub_post_eac_vl(row);

DROP TABLE IF EXISTS expanded_radet.post_eac_vl_new;
CREATE TABLE expanded_radet.post_eac_vl_new AS
SELECT * FROM expanded_radet.sub_post_eac_vl WHERE row=1;

DROP TABLE IF EXISTS expanded_radet.post_eac_vl;

ALTER TABLE expanded_radet.post_eac_vl_new RENAME TO post_eac_vl;

CREATE INDEX patientuuidodsdatimid_post_eac_vl ON expanded_radet.post_eac_vl(patient_uuid,ods_datim_id);

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time) 
VALUES ('post_eac_vl', start_time,end_time);
END
$BODY$;
ALTER PROCEDURE expanded_radet.proc_post_eac_vl()
    OWNER TO lamisplus_etl;
