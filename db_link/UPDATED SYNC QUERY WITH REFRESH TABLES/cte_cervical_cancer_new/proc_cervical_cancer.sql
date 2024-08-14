CREATE OR REPLACE PROCEDURE expanded_radet.proc_cervical_cancer()
    LANGUAGE plpgsql
    AS $_$
DECLARE start_time TIMESTAMP;
DECLARE end_time TIMESTAMP;
BEGIN

SELECT TIMEOFDAY() INTO start_time;

drop table if exists expanded_radet.cte_cervical_cancer_new;

create table expanded_radet.cte_cervical_cancer_new AS
SELECT * 
FROM expanded_radet.sub_cervical_cancer
WHERE row = 1
;

drop table if exists expanded_radet.cte_cervical_cancer;
alter table expanded_radet.cte_cervical_cancer_new rename to cte_cervical_cancer;

create index unq_personuuid_datimid_cerv_cancer 
on expanded_radet.cte_cervical_cancer(person_uuid90,cerv_ods_datim_id);

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time) 
VALUES ('cte_cervical_cancer', start_time,end_time);

END
$_$;

ALTER PROCEDURE expanded_radet.proc_cervical_cancer() OWNER TO lamisplus_etl;

--call expanded_radet.proc_cervical_cancer()
