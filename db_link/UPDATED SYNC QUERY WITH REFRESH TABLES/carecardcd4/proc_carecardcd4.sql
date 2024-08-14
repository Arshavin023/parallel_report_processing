CREATE OR REPLACE PROCEDURE expanded_radet.proc_carecardcd4()
    LANGUAGE plpgsql
    AS $_$
DECLARE start_time TIMESTAMP;
DECLARE end_time TIMESTAMP;
BEGIN

SELECT TIMEOFDAY() INTO start_time;

drop table if exists expanded_radet.cte_carecardcd4_new;
create table expanded_radet.cte_carecardcd4_new AS
SELECT * FROM expanded_radet.carecardcd4 
WHERE visit_date <= (select date from expanded_radet.period where is_active) ---?3'
;

drop table if exists expanded_radet.cte_carecardcd4;
alter table expanded_radet.cte_carecardcd4_new rename to cte_carecardcd4;

create index unq_personuuid_datim_id_ctecarecard4 on expanded_radet.cte_carecardcd4(cccd4_person_uuid,care_ods_datim_id);

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time) 
VALUES ('cte_carecardcd4', start_time,end_time);

END
$_$;

ALTER PROCEDURE expanded_radet.proc_carecardcd4() OWNER TO lamisplus_etl;

--call expanded_radet.proc_carecardcd4()
