CREATE TABLE tbstatus_tbscreening
SELECT uuid, person_uuid, ods_datim_id , id, date_of_observation AS dateOfTbScreened, data->'tbIptScreening'->>'status' AS tbStatus, 
		data->'tbIptScreening'->>'tbScreeningType' AS tbScreeningType, 
	data->'tbIptScreening'->>'outcome' AS tbStatusOutcome,
		--ROW_NUMBER() OVER (PARTITION BY person_uuid, ods_datim_id ORDER BY date_of_observation DESC) AS rowNums 
FROM ods_hiv_observation 
WHERE type = 'Chronic Care' 
and data is not null 
--and archived = 0 
	--and date_of_observation between '1980-01-01' and (select date from expanded_radet.period where is_active) 
	--and facility_id = ?1 
	--composite key is ods_datim_id, uuid - on conflict insert
	--SELECTING ONLY NEW DATA
	--Proper index - person_uuid, ods_datim_id, dateOfTbScreened
	
------------------------------------------------------------------------------------------------------
--*****************CTES***************************
CREATE TABLE AS sub_tb_status_tbscreening
SELECT * , 
ROW_NUMBER() OVER (PARTITION BY person_uuid, ods_datim_id ORDER BY dateOfTbScreened DESC) AS rowNums 
WHERE date_of_observation between '1980-01-01' and (select date from expanded_radet.period where is_active) 
FROM 
	--Proper index - rowNums

-----------------------------------------------------------------------------------------------------------
CREATE TABLE AS cte_tbstatus_tbscreening_cs_new
SELECT * FROM sub_tb_status_tbscreening WHERE rowNums=1