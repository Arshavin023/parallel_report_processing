CREATE OR REPLACE PROCEDURE expanded_radet.proc_biometric()
    LANGUAGE plpgsql
    AS $_$
DECLARE start_time TIMESTAMP;
DECLARE end_time TIMESTAMP;
BEGIN

SELECT TIMEOFDAY() INTO start_time;

drop table if exists expanded_radet.cte_biometric_new;
create table expanded_radet.cte_biometric_new AS
SELECT DISTINCT ON (he.person_uuid, he.ods_datim_id) he.person_uuid AS person_uuid60,
he.ods_datim_id as biome_ods_datim_id, he.enrollment_date AS dateBiometricsEnrolled, 
he.count AS numberOfFingersCaptured, rb.enrollment_date AS dateBiometricsRecaptured,
rb.count AS numberOfFingersRecaptured
FROM expanded_radet.base_biometric he
LEFT JOIN expanded_radet.recapture_biometric rb ON rb.person_uuid = he.person_uuid 
AND rb.ods_datim_id = he.ods_datim_id;

drop table if exists expanded_radet.cte_biometric;
alter table expanded_radet.cte_biometric_new rename to cte_biometric;

create index unq_personuuid_datimid_ctebiometric 
on expanded_radet.cte_biometric(person_uuid60,biome_ods_datim_id);

SELECT TIMEOFDAY() INTO end_time;
INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time) 
VALUES ('cte_biometric', start_time,end_time);

END
$_$;

ALTER PROCEDURE expanded_radet.proc_biometric() OWNER TO lamisplus_etl;
--call expanded_radet.proc_biometric()
