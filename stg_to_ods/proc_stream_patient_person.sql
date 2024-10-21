-- PROCEDURE: public.proc_stream_patient_person(character varying)

-- DROP PROCEDURE IF EXISTS public.proc_stream_patient_person(character varying);

CREATE OR REPLACE PROCEDURE public.proc_stream_patient_person(
	IN table_name character varying)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    deleted_count bigint;
	stream_file_name character varying;
	inserted_count bigint;
	size_before_deletion text;
	size_after_deletion text;
	
BEGIN
    -- Get the current start time
    SELECT TIMEOFDAY() INTO start_time;
    
	--Get size of table in megabytes before deletion
	EXECUTE format ('SELECT pg_size_pretty(pg_total_relation_size(table_schema || ''.'' || table_name)::bigint)
                FROM information_schema.tables WHERE table_schema = ''public'' AND table_name = ''%s''',
                 table_name)
	INTO size_before_deletion;
	
				
    -- Execute a dynamic SQL to get the count of records to be stream
--     EXECUTE format('SELECT * FROM dblink(''db_link_staging'',
-- 				   ''select count(stg_batch_id)
-- 				   FROM stg_monitoring
-- 				   WHERE EXISTS (
-- 				   select DISTINCT 1 FROM stg_monitoring sm
-- 				   WHERE sm.file_name=pp.stg_file_name
-- 				   AND processed=''''N'''' and table_name = ''''%s''''
-- 				  LIMIT 1)
-- 				   '') AS sm(count bigint)',
-- 				   table_name,table_name)
--     INTO inserted_count;

-- 	SELECT 'patient_person_1_20241018112200_decrypted.json' INTO test_stream_file_name;

	EXECUTE format('SELECT * FROM dblink(''db_link_staging'',
					   ''select file_name
					   FROM stg_monitoring
					   WHERE processed=''''N'''' AND table_name = ''''%s''''
				   	   LIMIT 1
					   '') AS sm(file_name character varying)',table_name)
		INTO stream_file_name;

-- 	SELECT 'patient_person_1_20241018112200_decrypted.json' INTO stream_file_name;
	
	-- Execute dynamic SQL to stream records from the lamisplus_staging_dwh to lamisplus_ods_dwh
	EXECUTE format('INSERT INTO ods_patient_person
					SELECT * FROM dblink(''db_link_staging'',
					''SELECT id, created_date, created_by, last_modified_date, last_modified_by, 
					active, contact_point, address, gender, identifier, deceased, 
					deceased_date_time, marital_status, employment_status, education, organization, 
					contact, date_of_birth, date_of_registration, archived, facility_id, uuid, 
					nin_number, emr_id, first_name, sex, surname, other_name, hospital_number, 
					is_date_of_birth_estimated, full_name, case_manager_id, stg_load_time ods_load_time, 
					stg_datim_id ods_datim_id, reason, latitude, longitude, source
					FROM %I pp
					WHERE stg_file_name=''%L''
					'') AS sm(id bigint,created_date timestamp without time zone,created_by character varying,
						last_modified_date timestamp,last_modified_by character varying,
						active boolean,	contact_point jsonb,address jsonb,
						gender jsonb,identifier jsonb,deceased boolean,
						deceased_date_time timestamp,marital_status jsonb,
						employment_status jsonb,education jsonb,
						organization jsonb,	contact jsonb,
						date_of_birth date,
						date_of_registration date,
						archived integer,
						facility_id bigint,
						uuid character varying,
						nin_number character varying,
						emr_id character varying,
						first_name character varying,
						sex character varying,
						surname character varying,
						other_name character varying,
						hospital_number character varying,
						is_date_of_birth_estimated boolean,
						full_name character varying,
						case_manager_id bigint,
						ods_load_time timestamp without time zone,
						ods_datim_id character varying(255),
						reason text,
						latitude character varying,
						longitude character varying,
						source character varying)
				   ON CONFLICT(uuid,ods_datim_id)
				   DO UPDATE SET
					id=EXCLUDED.id,	created_date=EXCLUDED.created_date,
					created_by=EXCLUDED.created_by,	last_modified_date=EXCLUDED.last_modified_date,
					last_modified_by=EXCLUDED.last_modified_by,
					active=EXCLUDED.active, contact_point=EXCLUDED.contact_point,
				    address=EXCLUDED.address, gender=EXCLUDED.gender,
				   	identifier=EXCLUDED.identifier,	deceased=EXCLUDED.deceased,
				    deceased_date_time=EXCLUDED.deceased_date_time, marital_status=EXCLUDED.marital_status,
				    employment_status=EXCLUDED.employment_status, education=EXCLUDED.education,
				    organization=EXCLUDED.organization, contact=EXCLUDED.contact,
				    date_of_birth=EXCLUDED.date_of_birth,date_of_registration=EXCLUDED.date_of_registration,
				    archived=EXCLUDED.archived,facility_id=EXCLUDED.facility_id,nin_number=EXCLUDED.nin_number,
				    emr_id=EXCLUDED.emr_id,first_name=EXCLUDED.first_name, sex=EXCLUDED.sex,
				    surname=EXCLUDED.surname,
				    other_name=EXCLUDED.other_name,
				    hospital_number=EXCLUDED.hospital_number,
				    is_date_of_birth_estimated=EXCLUDED.is_date_of_birth_estimated,
				    full_name=EXCLUDED.full_name,
				    case_manager_id=EXCLUDED.case_manager_id,
				    ods_load_time=EXCLUDED.ods_load_time,
				    reason=EXCLUDED.reason,
				    latitude=EXCLUDED.latitude,
				    longitude=EXCLUDED.longitude,
				    source=EXCLUDED.source',  table_name,stream_file_name);
			 
	-- Execute dynamic SQL to update processed column stg_monitoring for records inserted from the stg tables to ods_tables
	PERFORM dblink(
			'db_link_staging',
				  format('UPDATE stg_monitoring
						SET processed = ''Y'', stg_deleted=''N''
						WHERE processed = ''N'' AND table_name = ''stg_patient_person''
						AND file_name=%L
						 ',stream_file_name)
					 );

	
	-- Execute dynamic SQL to delete records from tables that has moved to data warehouse

		PERFORM dblink(
		'db_link_staging',
			  format('
					DELETE FROM stg_patient_person pp
					WHERE stg_file_name=%L',stream_file_name)
				 );
				 
					
	-- Execute dynamic SQL to update stg_deleted column on stg_monitoring for records deleted from the stg tables
	
		PERFORM dblink(
		'db_link_staging',
			  format('
					UPDATE stg_monitoring
					SET stg_deleted =''Y'', error_message=''No errors''
					WHERE processed = ''Y'' 
					AND table_name = ''stg_patient_person''
					AND stg_deleted != ''Y''
					AND file_name = %L
					',stream_file_name)
				 );
    
	--Get size of table in megabytes AFTER deletion
	EXECUTE format ('SELECT pg_size_pretty(pg_total_relation_size(table_schema || ''.'' || table_name)::bigint)
                FROM information_schema.tables WHERE table_schema = ''public'' AND table_name = ''%s''',
                'public', table_name, table_name)
	INTO size_after_deletion;
	
	-- Get the current end time
    SELECT TIMEOFDAY() INTO end_time;
	
    -- Log or perform any other operations if needed
    INSERT INTO public.ods_records_streaming_log (table_name, 
-- 												  deleted_records_count, 
												  start_time, end_time,
											size_before_deletion,size_after_deletion) 
    VALUES (table_name, 
-- 			inserted_count,
			start_time, end_time,size_before_deletion,size_after_deletion);
    
END 

$BODY$;
ALTER PROCEDURE public.proc_stream_patient_person(character varying)
    OWNER TO lamisplus_etl;
	

-- CALL public.proc_stream_patient_person('stg_patient_person');