-- PROCEDURE: expanded_radet.proc_create_client_verification()

-- DROP PROCEDURE IF EXISTS expanded_radet.proc_create_client_verification();

CREATE OR REPLACE PROCEDURE expanded_radet.proc_create_client_verification(
	)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE start_time TIMESTAMP;
DECLARE last_load_end_time TIMESTAMP;
DECLARE end_time TIMESTAMP;
DECLARE record_count bigint;

BEGIN

-- Fetch the last load end time
SELECT MAX(load_end_time) 
INTO last_load_end_time
FROM streaming_remote_monitoring
WHERE table_name = 'client_verification';

-- Fetch record count from the remote database using dblink
EXECUTE FORMAT(
	'SELECT *
	 FROM dblink(''db_link_ods'',
	 ''
	 SELECT count(uuid) 
	 FROM ods_hiv_observation 
	 WHERE ods_load_time >= ''%L''			   
	'') 
	 AS sm(count bigint)',last_load_end_time) 
INTO record_count;

DROP TABLE IF EXISTS expanded_radet.client_verification;

SELECT TIMEOFDAY() INTO start_time;

EXECUTE FORMAT('CREATE TABLE expanded_radet.client_verification AS
SELECT * FROM dblink(''db_link_ods'',
''SELECT DISTINCT ON (uuid, ods_datim_id) uuid, person_uuid as client_person_uuid, 
		ods_datim_id as client_ods_datim_id,
		data->''''attempt''''->0->>''''outcome'''' AS clientVerificationOutCome, 
		data->''''attempt''''->0->>''''outcome'''' AS clientVerificationStatus,
		CAST (data->''''attempt''''->0->>''''dateOfAttempt'''' AS DATE) AS dateOfOutcome, 
		archived AS hiv_observation_archived
from ods_hiv_observation 
WHERE ods_load_time >= ''%L''
AND type = ''''Client Verification''''
--AND archived = 0
'')AS sm(uuid character varying,client_person_uuid character varying,
		client_ods_datim_id character varying,clientVerificationOutCome text,
		clientVerificationStatus text,dateOfOutcome date,archived integer)',
		last_load_end_time);

SELECT TIMEOFDAY() INTO end_time;

ALTER TABLE expanded_radet.client_verification
ADD CONSTRAINT unq_uuid_datimid_client_verification UNIQUE (uuid, client_person_uuid,client_ods_datim_id);

CREATE INDEX unq_dateofoutcome_archived_client_verification 
ON expanded_radet.client_verification(dateOfOutcome,archived);

DELETE FROM expanded_radet.client_verification
WHERE hiv_observation_archived=1;

INSERT INTO public.streaming_remote_monitoring(table_name,start_time,load_end_time,record_count)
VALUES('client_verification',start_time, end_time, record_count);
			 
END 
$BODY$;
ALTER PROCEDURE expanded_radet.proc_create_client_verification()
    OWNER TO lamisplus_etl;
