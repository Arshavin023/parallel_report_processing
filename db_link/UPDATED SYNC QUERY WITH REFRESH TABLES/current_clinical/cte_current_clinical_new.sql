SELECT DISTINCT ON (tvs.person_uuid, tvs.ods_datim_id) tvs.person_uuid AS person_uuid10, 
tvs.ods_datim_id as clin_ods_datim_id,body_weight AS currentWeight,tbs.display AS tbStatus1, 
bac.display AS currentClinicalStage,
(CASE 
 --WHEN INITCAP(pp.sex) = ''Male'' THEN NULL
 WHEN preg.display IS NOT NULL THEN preg.display ELSE hac.pregnancy_status END
) AS pregnancyStatus, 
CASE WHEN hac.tb_screen IS NOT NULL THEN CAST(hac.visit_date AS DATE) ELSE NULL END AS dateOfTbScreened1 
FROM ods_triage_vital_sign tvs 
INNER JOIN expanded_radet.cte_sub_triage_current_clinical AS current_triage ON current_triage.MAXDATE = CAST(tvs.capture_date AS DATE) 
AND current_triage.person_uuid = tvs.person_uuid AND current_triage.ods_datim_id = tvs.ods_datim_id
INNER JOIN ods_hiv_art_clinical hac ON tvs.uuid = hac.vital_sign_uuid AND tvs.ods_datim_id = hac.ods_datim_id
INNER JOIN expanded_radet.cte_sub_date_current_clinical AS current_clinical_date ON current_clinical_date.MAXDATE = CAST(hac.visit_date AS DATE)
AND current_clinical_date.person_uuid = hac.person_uuid AND current_clinical_date.ods_datim_id = hac.ods_datim_id AND current_clinical_date.max=1 
INNER JOIN ods_hiv_enrollment he ON he.person_uuid = hac.person_uuid AND he.ods_datim_id = hac.ods_datim_id
LEFT JOIN ods_base_application_codeset bac ON bac.id = hac.clinical_stage_id AND bac.ods_datim_id = hac.ods_datim_id
LEFT JOIN ods_base_application_codeset preg ON preg.code = hac.pregnancy_status AND preg.ods_datim_id = hac.ods_datim_id
LEFT JOIN ods_base_application_codeset tbs ON tbs.id = CAST(hac.tb_status AS INTEGER) AND tbs.ods_datim_id = hac.ods_datim_id
--LEFT JOIN patient_person pp ON tvs.person_uuid = pp.uuid and tvs.ods_datim_id=pp.ods_datim_id
WHERE hac.archived = 0 AND he.archived = 0 
AND hac.visit_date <= (SELECT date FROM expanded_radet.period WHERE is_active)

--index properly





DROP TABLE if exists expanded_radet.cte_sub_date_current_clinical_new;
CREATE TABLE expanded_radet.cte_sub_date_current_clinical_new AS
SELECT DISTINCT ON (person_uuid, ods_datim_id) person_uuid, ods_datim_id,hac.visit_date as MAXDATE,
ROW_NUMBER() OVER (PARTITION BY hac.person_uuid, hac.ods_datim_id ORDER BY hac.visit_date  DESC) as max

--MAX(CAST(hac.visit_date AS DATE)) AS MAXDATE 
FROM ods_hiv_art_clinical hac 
GROUP BY person_uuid, ods_datim_id