CREATE TABLE client_Verification AS 
SELECT DISTINCT ON (person_uuid, ods_datim_id)person_uuid as client_person_uuid, 
		ods_datim_id as client_ods_datim_id, uuid,
	data->''attempt''->0->>''outcome'' AS clientVerificationOutCome, 
	data->''attempt''->0->>''outcome'' AS clientVerificationStatus,
CAST (data->''attempt''->0->>''dateOfAttempt'' AS DATE) AS dateOfOutcome,
--ROW_NUMBER() OVER ( PARTITION BY person_uuid ORDER BY CAST(data->''attempt''->0->>''dateOfAttempt'' AS DATE) DESC)
from ods_hiv_observation 
WHERE type = ''Client Verification''
--AND archived = 0
--INDEX type AND archived AND dateOfOutcome on
--composite keys - uuid, ods_datim_id - on conflict insert
---------------------------------------------------------------------------------------

--*****************CTES***************************
CREATE TABLE sub_client_Verification AS 
SELECT * FROM client_Verification 
ROW_NUMBER() OVER ( PARTITION BY person_uuid ORDER BY CAST(dateOfOutcome AS DATE) DESC)
WHERE 
AND dateOfOutcome <= (select date from expanded_radet.period where is_active) --$3 
AND dateOfOutcome >= ''1980-01-01'' --$2 
--INDEX row_number
------------------------------------------------------------------------------------------------------------------

SELECT * FROM sub_client_Verification
WHERE row_number = 1
