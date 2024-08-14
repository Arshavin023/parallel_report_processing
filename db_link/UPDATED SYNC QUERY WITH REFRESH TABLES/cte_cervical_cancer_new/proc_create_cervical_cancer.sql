-- PROCEDURE: expanded_radet.proc_create_cervical_cancer()

-- DROP PROCEDURE IF EXISTS expanded_radet.proc_create_cervical_cancer();

CREATE OR REPLACE PROCEDURE expanded_radet.proc_create_cervical_cancer(
	)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE start_time TIMESTAMP;
DECLARE end_time TIMESTAMP;
DECLARE record_count bigint;
BEGIN

SELECT TIMEOFDAY() INTO start_time;

select * from dblink('db_link_ods',
'SELECT count(uuid) FROM ods_hiv_observation p
					 WHERE ods_load_time > (select end_time FROM streaming_remote_monitoring
											WHERE table_name = ''cervical_cancer'' 
											ORDER BY end_time desc LIMIT 1)')
AS sm(count bigint) INTO record_count;

DROP TABLE IF EXISTS expanded_radet.cervical_cancer;
create table expanded_radet.cervical_cancer AS
select * from dblink('db_link_ods',
'select  DISTINCT ON (ho.person_uuid, ho.ods_datim_id) ho.person_uuid AS person_uuid90,
ho.ods_datim_id as cerv_ods_datim_id,ho.uuid,ho.date_of_observation AS dateOfCervicalCancerScreening, 
ho.data ->> ''screenTreatmentMethodDate'' AS treatmentMethodDate,cc_type.display AS cervicalCancerScreeningType, 
cc_method.display AS cervicalCancerScreeningMethod, cc_trtm.display AS cervicalCancerTreatmentScreened, 
cc_result.display AS resultOfCervicalCancerScreening, ho.archived hiv_observation_archived
from (SELECT person_uuid,ods_datim_id,uuid,data,date_of_observation,archived,type
		FROM ods_hiv_observation
		  WHERE ods_load_time > (select end_time FROM streaming_remote_monitoring
								WHERE table_name = ''cervical_cancer'' 
								ORDER BY end_time desc LIMIT 1)) ho 
LEFT JOIN ods_base_application_codeset cc_type ON cc_type.code = CAST(ho.data ->> ''screenType'' AS VARCHAR) 
AND cc_type.ods_datim_id=ho.ods_datim_id
LEFT JOIN ods_base_application_codeset cc_method ON cc_method.code = CAST(ho.data ->> ''screenMethod'' AS VARCHAR)
AND cc_method.ods_datim_id=ho.ods_datim_id
LEFT JOIN ods_base_application_codeset cc_result ON cc_result.code = CAST(ho.data ->> ''screeningResult'' AS VARCHAR) 
AND cc_result.ods_datim_id=ho.ods_datim_id
LEFT JOIN ods_base_application_codeset cc_trtm ON cc_trtm.code = CAST(ho.data ->> ''screenTreatment'' AS VARCHAR) 
AND cc_trtm.ods_datim_id=ho.ods_datim_id
where type = ''Cervical cancer'' 
--and ho.archived = 0
')AS sm(person_uuid90 character varying,cerv_ods_datim_id character varying,
    uuid character varying,dateOfCervicalCancerScreening date,treatmentMethodDate text,
    cervicalCancerScreeningType character varying,cervicalCancerScreeningMethod character varying,
	cervicalCancerTreatmentScreened character varying,resultOfCervicalCancerScreening character varying,
	hiv_observation_archived integer);

ALTER TABLE expanded_radet.cervical_cancer
ADD CONSTRAINT unq_cervical_cancer UNIQUE (uuid, cerv_ods_datim_id);

CREATE INDEX unq_dateofobservation_cervical_cancer 
ON expanded_radet.cervical_cancer(dateOfCervicalCancerScreening);

SELECT MAX(ods_load_time)
FROM ods_hiv_observation
INTO end_time;

PERFORM dblink('db_link_ods',
      format('INSERT INTO public.streaming_remote_monitoring(table_name,record_count,start_time,end_time) 
			 VALUES (''%s'',%L, %L, %L)',
             'cervical_cancer', record_count,start_time, end_time));
			 
END 
$BODY$;
ALTER PROCEDURE expanded_radet.proc_create_cervical_cancer()
    OWNER TO lamisplus_etl;
