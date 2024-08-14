CREATE TABLE crytococal_antigen AS 
  select DISTINCT ON (lr.patient_uuid, lr.ods_datim_id) lr.patient_uuid as personuuid12,
	lr.ods_datim_id as crypt_ods_datim_id, uuid,archived,
	CAST(lr.date_result_reported AS DATE) AS dateOfLastCrytococalAntigen, 
	lr.result_reported AS lastCrytococalAntigen 
  from public.ods_laboratory_test lt 
  inner join ods_laboratory_result lr on lr.test_id = lt.id AND lr.ods_datim_id = lt.ods_datim_id
  where lab_test_id = 52 OR lab_test_id = 69 OR lab_test_id = 70 
  AND lr.date_result_reported IS NOT NULL 
   
	AND lr.result_reported is NOT NULL 
	--AND lr.archived = '0'
	AND (lt.ods_load_time >
	OR lr.ods_load_time > )
	
	--for the first time it will be inner but other times it will be outter join
	--INDEX lr.result_reported, lr.archived = '0'
--composite key is ods_datim_id, uuid - on conflict insert
	
	-----------------------------------------------------------------------------------
	--*****************CTES***************************
	CREATE TABLE sub_crytococal_antigen AS 
	SELECT *,
	ROW_NUMBER() OVER (PARTITION BY lr.patient_uuid, lr.ods_datim_id ORDER BY dateOfLastCrytococalAntigen DESC) as rowNum
	WHERE 
	dateOfLastCrytococalAntigen <= (select date from expanded_radet.period where is_active) ---?3 
    dateOfLastCrytococalAntigen >= ''1980-01-01'' ---?2 
	FROM crytococal_antigen
	--INDEX dateOfLastCrytococalAntigen AND rowNum
	---------------------------------------------------------------------------------------
	
	CREATE cte_cryptococal_antigen_new AS
	SELECT * FROM sub_crytococal_antigen WHERE rowNum = 1
	
	
