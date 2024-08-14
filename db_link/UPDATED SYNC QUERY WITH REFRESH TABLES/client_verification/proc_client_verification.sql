CREATE OR REPLACE PROCEDURE expanded_radet.proc_client_verification()
    LANGUAGE plpgsql
    AS $_$
DECLARE start_time TIMESTAMP;
DECLARE end_time TIMESTAMP;
BEGIN

SELECT TIMEOFDAY() INTO start_time;

drop table if exists expanded_radet.cte_client_verification_new;

create table expanded_radet.cte_client_verification_new AS
SELECT * FROM expanded_radet.sub_client_verification WHERE row_number = 1
;

drop table if exists expanded_radet.cte_client_verification;
alter table expanded_radet.cte_client_verification_new rename to cte_client_verification;

create index unq_personuuid_datimid_client_verification
on expanded_radet.cte_client_verification(client_person_uuid,client_ods_datim_id);

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time) 
VALUES ('cte_client_verification', start_time,end_time);

END
$_$;

ALTER PROCEDURE expanded_radet.proc_client_verification() OWNER TO lamisplus_etl;

--call expanded_radet.proc_client_verification()
