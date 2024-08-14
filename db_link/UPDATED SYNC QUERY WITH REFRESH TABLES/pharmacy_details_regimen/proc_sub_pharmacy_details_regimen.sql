CREATE OR REPLACE PROCEDURE expanded_radet.proc_sub_client_verification()
    LANGUAGE plpgsql
    AS $_$
DECLARE start_time TIMESTAMP;
DECLARE end_time TIMESTAMP;
BEGIN

SELECT TIMEOFDAY() INTO start_time;

drop table if exists expanded_radet.sub_client_verification_new;

create table expanded_radet.sub_client_verification_new AS
SELECT *,
		ROW_NUMBER() OVER (PARTITION BY client_person_uuid ORDER BY CAST(dateOfOutcome AS DATE) DESC)
FROM expanded_radet.client_Verification 
WHERE dateOfOutcome <= (select date from expanded_radet.period where is_active) --$3 
AND dateOfOutcome >= '1980-01-01' --$2
;

drop table if exists expanded_radet.sub_client_verification;
alter table expanded_radet.sub_client_verification_new rename to sub_client_verification;

create index idx_client_verification_rownum on expanded_radet.sub_client_verification(row_number);

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time) 
VALUES ('sub_client_verification', start_time,end_time);

END
$_$;

ALTER PROCEDURE expanded_radet.proc_sub_client_verification() OWNER TO lamisplus_etl;

--call expanded_radet.proc_sub_client_verification()
