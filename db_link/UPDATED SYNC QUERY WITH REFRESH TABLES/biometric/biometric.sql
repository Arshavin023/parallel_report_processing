CREATE TABLE expanded_radet.base_biometric AS	
SELECT person_uuid, ods_datim_id,recapture, enrollment_date, count 
FROM biometric 
WHERE version_iso_20 is not null 
AND version_iso_20 is true 
AND archived=0 
AND recapture=0
GROUP BY person_uuid, recapture, enrollment_date, ods_datim_id, count
--SELECTING ONLY NEW DATA
--composite key is person_uuid, recapture, enrollment_date, ods_datim_id, count  - on conflict insert
--INDEX = ods_datim_id, person_uuid

-------------------------------------------------------------------------------------------------
CREATE TABLE expanded_radet.recapture_biometric AS	
SELECT person_uuid, ods_datim_id,recapture, enrollment_date, count 
FROM biometric 
WHERE version_iso_20 is not null 
AND version_iso_20 is true 
AND archived=0 
AND recapture=1
GROUP BY person_uuid, recapture, enrollment_date, ods_datim_id, count
--SELECTING ONLY NEW DATA
--composite key is person_uuid, recapture, enrollment_date, ods_datim_id, count  - on conflict insert
--INDEX = ods_datim_id, person_uuid
--------------------------------------------------------------------------------------------------
--*************CTE****************************
		 SELECT DISTINCT ON (he.person_uuid, he.ods_datim_id) he.person_uuid AS person_uuid60,
		 he.ods_datim_id as biome_ods_datim_id, he.enrollment_date AS dateBiometricsEnrolled, 
		 he.count.count AS numberOfFingersCaptured, rb.enrollment_date AS dateBiometricsRecaptured,
		 rb.count AS numberOfFingersRecaptured
		 FROM base_biometric he
		 LEFT JOIN recapture_biometric rb ON rb.person_uuid = he.person_uuid 
		 AND rb.ods_datim_id = he.ods_datim_id
		 --INDEX = ods_datim_id, person_uuid

