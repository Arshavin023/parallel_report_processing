CREATE OR REPLACE PROCEDURE expanded_radet.proc_bio_data()
    LANGUAGE plpgsql
    AS $_$
DECLARE start_time TIMESTAMP;
DECLARE end_time TIMESTAMP;
BEGIN

SELECT TIMEOFDAY() INTO start_time;

drop table if exists expanded_radet.cte_bio_data_new;
create table expanded_radet.cte_bio_data_new AS
SELECT *,EXTRACT(YEAR from AGE(NOW(),  dateofbirth)) as age
FROM expanded_radet.patient_bio_data
WHERE ods_hiv_enrollment_person_uuid IS NOT NULL
AND ods_hiv_art_clinical_person_uuid IS NOT NULL
AND regimenAtStart IS NOT NULL
AND ods_hiv_art_clinical_archived = 0
AND ods_hiv_enrollment_archived = 0
AND is_commencement = TRUE
AND visit_date >= '1980-01-01'
AND visit_date <= (select date from expanded_radet.period where is_active);

drop table if exists expanded_radet.cte_bio_data;
alter table expanded_radet.cte_bio_data_new rename to cte_bio_data;

create index unq_personuuid_datim_ctebiodata 
on expanded_radet.cte_bio_data(personuuid,bio_ods_datim_id);

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time) 
VALUES ('patient_bio_data', start_time,end_time);

END
$_$;

ALTER PROCEDURE expanded_radet.proc_bio_data() OWNER TO lamisplus_etl;

--call expanded_radet.proc_bio_data()
