CREATE OR REPLACE PROCEDURE expanded_radet.proc_sub_cryptocol_antigen()
    LANGUAGE plpgsql
    AS $_$
DECLARE start_time TIMESTAMP;
DECLARE end_time TIMESTAMP;
BEGIN

SELECT TIMEOFDAY() INTO start_time;

drop table if exists expanded_radet.sub_cryptocol_antigen_new;

create table expanded_radet.sub_cryptocol_antigen_new AS
SELECT *,
ROW_NUMBER() OVER (PARTITION BY personuuid12, crypt_ods_datim_id ORDER BY dateOfLastCrytococalAntigen DESC) as rowNum
FROM expanded_radet.cryptocol_antigen
WHERE dateOfLastCrytococalAntigen <= (select date from expanded_radet.period where is_active) ---?3 
AND dateOfLastCrytococalAntigen >= '1980-01-01' ---?2 
;

drop table if exists expanded_radet.sub_cryptocol_antigen;
alter table expanded_radet.sub_cryptocol_antigen_new rename to sub_cryptocol_antigen;

create index idx_cryptocol_antigen_rownum on expanded_radet.sub_cryptocol_antigen(rowNum);

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time) 
VALUES ('sub_cryptocol_antigen', start_time,end_time);

END
$_$;

ALTER PROCEDURE expanded_radet.proc_sub_cryptocol_antigen() OWNER TO lamisplus_etl;

--call expanded_radet.proc_sub_cryptocol_antigen()
