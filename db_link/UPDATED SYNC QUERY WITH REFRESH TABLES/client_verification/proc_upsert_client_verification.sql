-- PROCEDURE: expanded_radet.proc_upsert_client_verification()

-- DROP PROCEDURE IF EXISTS expanded_radet.proc_upsert_client_verification();

CREATE OR REPLACE PROCEDURE expanded_radet.proc_upsert_client_verification(
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
											WHERE table_name = ''client_verification'' 
											ORDER BY end_time desc LIMIT 1)')
AS sm(count bigint) INTO record_count;

INSERT INTO expanded_radet.client_verification
select * from dblink('db_link_ods',
'SELECT DISTINCT ON (person_uuid, ods_datim_id)person_uuid as client_person_uuid, 
		ods_datim_id as client_ods_datim_id, uuid,archived,
	data->''attempt''->0->>''outcome'' AS clientVerificationOutCome, 
	data->''attempt''->0->>''outcome'' AS clientVerificationStatus,
CAST (data->''attempt''->0->>''dateOfAttempt'' AS DATE) AS dateOfOutcome
from ods_hiv_observation 
WHERE ods_load_time > (select end_time FROM streaming_remote_monitoring
						WHERE table_name = ''client_verification'' 
						ORDER BY end_time desc LIMIT 1)
AND type = ''Client Verification''
--AND archived = 0
')AS sm(client_person_uuid character varying,client_ods_datim_id character varying,
    uuid character varying,archived integer,clientVerificationOutCome text,
		clientVerificationStatus text,dateOfOutcome date)
ON CONFLICT(uuid, client_ods_datim_id)
DO UPDATE SET
	archived=EXCLUDED.archived,
	clientVerificationOutCome=EXCLUDED.clientVerificationOutCome,
	clientVerificationStatus=EXCLUDED.clientVerificationStatus,
	dateOfOutcome=EXCLUDED.dateOfOutcome;

SELECT MAX(ods_load_time)
FROM ods_hiv_observation
INTO end_time;

PERFORM dblink('db_link_ods',
      format('INSERT INTO public.streaming_remote_monitoring(table_name,record_count,start_time,end_time) 
			 VALUES (''%s'',%L, %L, %L)',
             'client_verification', record_count,start_time, end_time));
			 
END 
$BODY$;
ALTER PROCEDURE expanded_radet.proc_upsert_client_verification()
    OWNER TO lamisplus_etl;
