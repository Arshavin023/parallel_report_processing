PATIENT_BIO_DATA indexes
archived, uuid, ods_datim_id, facility_id,ods_load_time on ods_patient_person on lamisplus_ods_dwh database
uuid, person_uuid, ods_datim_id, target_group_id, enrollment_setting_id,entry_point_id, on ods_hiv_enrollment on lamisplus_ods_dwh database
id, ods_datim_id on ods_base_application_codeset on lamisplus_ods_dwh database
hiv_enrollment_uuid, ods_datim_id, person_uuid, regimen_id, is_commencement, archived on ods_hiv_art_clinical on lamisplus_ods_dwh database
id, ods_datim_id on ods_hiv_regimen on lamisplus_ods_dwh database
id, ods_datim_id on ods_hiv_regimen_type on lamisplus_ods_dwh database
end_time, table_name on public.streaming_remote_monitoring on lamisplus_ods_dwh database


LEFT OUTER JOIN central_partner_mapping facility ON facility.facility_id = p.facility_id  AND facility.datim_id = p.ods_datim_id
LEFT JOIN ods_hiv_enrollment h ON h.person_uuid = p.uuid  AND h.ods_datim_id = p.ods_datim_id  --iNNER
LEFT OUTER JOIN ods_base_application_codeset tgroup ON tgroup.id = h.target_group_id AND tgroup.ods_datim_id = h.ods_datim_id
LEFT OUTER JOIN ods_base_application_codeset eSetting ON eSetting.id = h.enrollment_setting_id AND eSetting.ods_datim_id = h.ods_datim_id
LEFT OUTER JOIN ods_base_application_codeset ecareEntry ON ecareEntry.id = h.entry_point_id AND ecareEntry.ods_datim_id = h.ods_datim_id
LEFT JOIN ods_hiv_art_clinical hac ON hac.hiv_enrollment_uuid = h.uuid  AND hac.ods_datim_id = h.ods_datim_id AND hac.person_uuid=p.uuid
AND hac.is_commencement = TRUE  --iNNER
AND hac.archived = 0 
LEFT JOIN ods_hiv_regimen hr ON hr.id = hac.regimen_id  AND hr.ods_datim_id = hac.ods_datim_id  --INNER
LEFT OUTER JOIN ods_hiv_regimen_type hrt ON hrt.id = hac.regimen_type_id  AND hrt.ods_datim_id = hac.ods_datim_id
WHERE p.archived = 0'


PROPOSED INDEXES;
CREATE INDEX idx_ods_patient_person_load_time_archived 
ON ods_patient_person (ods_load_time DESC, archived);

CREATE INDEX idx_ods_patient_person_uuid_ods_datim_id 
ON ods_patient_person (uuid, ods_datim_id);


CREATE INDEX idx_ods_hiv_enrollment_person_uuid_ods_datim_id 
ON ods_hiv_enrollment (person_uuid, ods_datim_id);

CREATE INDEX idx_ods_hiv_enrollment_codesets 
ON ods_hiv_enrollment (target_group_id, enrollment_setting_id, entry_point_id, ods_datim_id);


CREATE INDEX idx_ods_base_application_codeset_id_ods_datim_id 
ON ods_base_application_codeset (id, ods_datim_id);


CREATE INDEX idx_ods_hiv_art_clinical_enrollment_uuid_datim_id_person_uuid
ON ods_hiv_art_clinical (hiv_enrollment_uuid, ods_datim_id, person_uuid);
CREATE INDEX idx_ods_hiv_art_clinical_commencement_archived_regimen_id_datim_id
ON ods_hiv_art_clinical (is_commencement, archived, regimen_id, ods_datim_id);


CREATE INDEX idx_ods_hiv_regimen_id_ods_datim_id ON ods_hiv_regimen (id, ods_datim_id);

CREATE INDEX idx_streaming_remote_monitoring_table_name_end_time 
ON public.streaming_remote_monitoring (table_name, end_time DESC);




CTE_BIO_DATA_NEW indexes
SELECT * FROM patient_bio_data
WHERE ods_hiv_enrollment_person_uuid IS NOT NULL
AND ods_hiv_art_clinical_person_uuid IS NOT NULL
AND regimenAtStart IS NOT NULL
AND ods_hiv_art_clinical_archived = 0
AND ods_hiv_enrollment_archived = 0
AND is_commencement = TRUE
AND hac.visit_date >= '1980-01-01'
AND visit_date <= (select date from expanded_radet.period where is_active)

CREATE INDEX idx_patient_bio_data_non_nulls
ON expanded_radet.patient_bio_data (visit_date)
WHERE ods_hiv_enrollment_person_uuid IS NOT NULL
AND ods_hiv_art_clinical_person_uuid IS NOT NULL
AND regimenAtStart IS NOT NULL AND ods_hiv_art_clinical_archived = 0
AND ods_hiv_enrollment_archived = 0 AND is_commencement = TRUE;