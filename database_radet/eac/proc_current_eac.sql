-- PROCEDURE: expanded_radet.proc_current_eac()

-- DROP PROCEDURE IF EXISTS expanded_radet.proc_current_eac();

CREATE OR REPLACE PROCEDURE expanded_radet.proc_current_eac(
	)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE end_time TIMESTAMP;
DECLARE start_time TIMESTAMP;
BEGIN

SELECT TIMEOFDAY() INTO start_time;

DROP TABLE if exists expanded_radet.sub_eac_current_eac_new;
CREATE TABLE expanded_radet.sub_eac_current_eac_new AS 
select id, person_uuid, uuid, status,ods_datim_id,
ROW_NUMBER() OVER (PARTITION BY person_uuid,ods_datim_id ORDER BY id DESC) AS row 
from public.ods_hiv_eac where archived = 0;

drop table IF EXISTS expanded_radet.sub_eac_current_eac;
alter table expanded_radet.sub_eac_current_eac_new rename to sub_eac_current_eac;

CREATE INDEX row_sub_eac_current_eac
ON expanded_radet.sub_eac_current_eac(row);

DROP TABLE IF EXISTS expanded_radet.current_eac_new;
CREATE TABLE expanded_radet.current_eac_new AS
SELECT * FROM expanded_radet.sub_eac_current_eac
WHERE row=1;

DROP TABLE IF EXISTS expanded_radet.current_eac;

ALTER TABLE expanded_radet.current_eac_new RENAME TO current_eac;

CREATE INDEX uuidodsdatimid_current_eac
ON expanded_radet.current_eac(uuid,person_uuid,ods_datim_id);

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time) 
VALUES ('current_eac', start_time,end_time);
END
$BODY$;
ALTER PROCEDURE expanded_radet.proc_current_eac()
    OWNER TO lamisplus_etl;
