CREATE OR REPLACE PROCEDURE expanded_radet.proc_sub_cervical_cancer()
    LANGUAGE plpgsql
    AS $_$
DECLARE start_time TIMESTAMP;
DECLARE end_time TIMESTAMP;
BEGIN

SELECT TIMEOFDAY() INTO start_time;

drop table if exists expanded_radet.sub_cervical_cancer_new;

create table expanded_radet.sub_cervical_cancer_new AS
SELECT *,ROW_NUMBER() OVER (PARTITION BY person_uuid90 ORDER BY dateOfCervicalCancerScreening DESC) AS row 
FROM expanded_radet.cervical_cancer 
WHERE dateOfCervicalCancerScreening <= (select date from expanded_radet.period where is_active) ---?3
;

drop table if exists expanded_radet.sub_cervical_cancer;
alter table expanded_radet.sub_cervical_cancer_new rename to sub_cervical_cancer;

create index idx_cerv_cancer_rownum on expanded_radet.sub_cervical_cancer(row);

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time) 
VALUES ('sub_cervical_cancer', start_time,end_time);

END
$_$;

ALTER PROCEDURE expanded_radet.proc_sub_cervical_cancer() OWNER TO lamisplus_etl;

--call expanded_radet.proc_sub_cervical_cancer()
