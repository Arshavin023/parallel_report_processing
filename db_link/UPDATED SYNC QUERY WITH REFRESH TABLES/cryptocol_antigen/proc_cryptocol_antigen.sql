CREATE OR REPLACE PROCEDURE expanded_radet.proc_cryptocol_antigen()
    LANGUAGE plpgsql
    AS $_$
DECLARE start_time TIMESTAMP;
DECLARE end_time TIMESTAMP;
BEGIN

SELECT TIMEOFDAY() INTO start_time;

drop table if exists expanded_radet.cte_cryptocol_antigen_new;

create table expanded_radet.cte_cryptocol_antigen_new AS
SELECT * FROM expanded_radet.sub_cryptocol_antigen WHERE rowNum = 1;

drop table if exists expanded_radet.cte_cryptocol_antigen;
alter table expanded_radet.cte_cryptocol_antigen_new rename to cte_cryptocol_antigen;

create index unq_personuuid_datimid_cryptocol_antigen
on expanded_radet.cte_cryptocol_antigen(personuuid12,crypt_ods_datim_id);

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time) 
VALUES ('cte_cryptocol_antigen', start_time,end_time);

END
$_$;

ALTER PROCEDURE expanded_radet.proc_cryptocol_antigen() OWNER TO lamisplus_etl;

--call expanded_radet.proc_cryptocol_antigen()
