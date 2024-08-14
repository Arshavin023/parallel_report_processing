CREATE patient_bio_data
SELECT DISTINCT ON (p.uuid, p.ods_datim_id) p.uuid AS personUuid,
p.ods_datim_id AS bio_ods_datim_id,p.hospital_number AS hospitalNumber,
h.unique_id AS uniqueId,EXTRACT(YEAR FROM AGE(NOW(), CAST(p.date_of_birth AS DATE))) AS age,
INITCAP(p.sex) AS gender,p.date_of_birth AS dateOfBirth,facility.facility_name AS facilityName,
facility.facility_lga AS lga,facility.facility_state AS state, p.ods_datim_id AS datimId,
tgroup.display AS targetGroup,eSetting.display AS enrollmentSetting,hac.visit_date AS artStartDate, 
hr.description AS regimenAtStart,p.date_of_registration AS dateOfRegistration,h.date_of_registration AS dateOfEnrollment, 
h.ovc_number AS ovcUniqueId,h.house_hold_number AS householdUniqueNo,ecareEntry.display AS careEntry, 
hrt.description AS regimenLineAtStart, hac.is_commencement, hac.visit_date, 
hac.archived AS ods_hiv_art_clinical_archived, h.archived AS ods_hiv_enrollment_archived,
h.person_uuid AS ods_hiv_enrollment_person_uuid, hac.person_uuid AS ods_hiv_art_clinical_person_uuid
FROM ods_patient_person p 
    LEFT OUTER JOIN central_partner_mapping facility ON facility.facility_id = p.facility_id  AND facility.ods_datim_id = p.ods_datim_id
    LEFT JOIN ods_hiv_enrollment h ON h.person_uuid = p.uuid  AND h.ods_datim_id = p.ods_datim_id  --iNNER
    LEFT OUTER JOIN ods_base_application_codeset tgroup ON tgroup.id = h.target_group_id AND tgroup.ods_datim_id = h.ods_datim_id
    LEFT OUTER JOIN ods_base_application_codeset eSetting ON eSetting.id = h.enrollment_setting_id AND eSetting.ods_datim_id = h.ods_datim_id
    LEFT OUTER JOIN ods_base_application_codeset ecareEntry ON ecareEntry.id = h.entry_point_id AND ecareEntry.ods_datim_id = h.ods_datim_id
    LEFT JOIN ods_hiv_art_clinical hac ON hac.hiv_enrollment_uuid = h.uuid  AND hac.ods_datim_id = h.ods_datim_id AND hac.person_uuid=p.uuid
	AND hac.is_commencement = TRUE  --iNNER
    AND hac.archived = 0 
    LEFT JOIN ods_hiv_regimen hr ON hr.id = hac.regimen_id  AND hr.ods_datim_id = hac.ods_datim_id  --INNER
    LEFT OUTER JOIN ods_hiv_regimen_type hrt ON hrt.id = hac.regimen_type_id  AND hrt.ods_datim_id = hac.ods_datim_id
WHERE p.archived = 0 
--SELECTING ONLY NEW DATA
--INDEX
-- composite key uuid, ods_datim_id - on conflict insert
-------------------------------------------------------------------------------------------

--*****************CTES***************************
CREATE cte_bio_data_new AS 
SELECT * FROM patient_bio_data
WHERE ods_hiv_enrollment_person_uuid IS NOT NULL
AND ods_hiv_art_clinical_person_uuid IS NOT NULL
AND regimenAtStart IS NOT NULL
AND ods_hiv_art_clinical_archived = 0
AND ods_hiv_enrollment_archived = 0
AND is_commencement = TRUE
AND hac.visit_date >= '1980-01-01'
AND visit_date <= (select date from expanded_radet.period where is_active)

--INDEX


    --AND hac.is_commencement = ''t''
    ----AND h.facility_id = ?1 
	--AND h.archived = 0
    --AND hac.is_commencement = TRUE AND hac.visit_date >= ''1980-01-01'' ---$2
    --AND hac.visit_date <= (select date from expanded_radet.period where is_active)
	
	
	-- index = ods_hiv_art_clinical.is_commencement, ods_hiv_art_clinical.visit_date
	-- index = ods_hiv_enrollment.archived
	-- index the final output = bio.personUuid, bio.bio_ods_datim_id