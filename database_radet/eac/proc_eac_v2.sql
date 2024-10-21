-- PROCEDURE: expanded_radet.proc_eac_v2()

-- DROP PROCEDURE IF EXISTS expanded_radet.proc_eac_v2();

CREATE OR REPLACE PROCEDURE expanded_radet.proc_eac_v2(
	)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE end_time TIMESTAMP;
DECLARE start_time TIMESTAMP;
BEGIN

SELECT TIMEOFDAY() INTO start_time;

DROP TABLE if exists expanded_radet.cte_eac_new;
CREATE TABLE expanded_radet.cte_eac_new AS
select fe.person_uuid as person_uuid50, fe.ods_datim_id as eac_ods_datim_id,
fe.eac_session_date as dateOfCommencementOfEAC, le.eac_session_date as dateOfLastEACSessionCompleted, 
	   ec.no_eac_session as numberOfEACSessionCompleted, exe.eac_session_date as dateOfExtendEACCompletion, 
	   pvl.result_reported as repeatViralLoadResult, pvl.date_result_reported as DateOfRepeatViralLoadResult, 
	   pvl.date_sample_collected as dateOfRepeatViralLoadEACSampleCollection 
from expanded_radet.first_eac fe 
left join expanded_radet.last_eac le on le.person_uuid = fe.person_uuid and le.ods_datim_id=fe.ods_datim_id
left join expanded_radet.eac_count ec on ec.person_uuid = fe.person_uuid and ec.ods_datim_id=fe.ods_datim_id
left join expanded_radet.extended_eac exe on exe.person_uuid = fe.person_uuid and exe.ods_datim_id=fe.ods_datim_id
left join expanded_radet.post_eac_vl pvl on pvl.patient_uuid = fe.person_uuid and pvl.ods_datim_id=fe.ods_datim_id;

DROP TABLE IF EXISTS expanded_radet.cte_eac;
ALTER TABLE expanded_radet.cte_eac_new RENAME TO cte_eac;

CREATE INDEX personuuid50eacdatimid_cte_eac ON expanded_radet.cte_eac(person_uuid50,eac_ods_datim_id);


SELECT TIMEOFDAY() INTO end_time;
INSERT INTO expanded_radet.expanded_radet_monitoring (table_name, start_time,end_time) 
VALUES ('post_eac_vl', start_time,end_time);
END
$BODY$;
ALTER PROCEDURE expanded_radet.proc_eac_v2()
    OWNER TO lamisplus_etl;
