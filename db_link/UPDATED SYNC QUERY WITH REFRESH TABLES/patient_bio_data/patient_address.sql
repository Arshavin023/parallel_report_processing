SELECT r.id, r.archived, r.uuid as personuuid, r.ods_datim_id, r.address, res_state.name as residentialState, res_lga AS residentialLga
 FROM (SELECT p.archived, p.id, p.uuid, p.ods_datim_id, REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CAST(address_object->>'line' AS text), '"', ''), ']', ''), '[', ''), 'null',''), '\\\\\\\', '') AS address,
    CASE WHEN address_object->>'stateId'  ~ '^\\\\d(\\\\.\\\\d)?$' THEN address_object->>'stateId' ELSE null END  AS stateId,
    CASE WHEN address_object->>'district'  ~ '^\\\\d(\\\\.\\\\d)?$' THEN address_object->>'district' ELSE null END  AS lgaId
    FROM ods_patient_person p
    left join jsonb_array_elements(p.address-> 'address') as l(address_object) on true) r
	LEFT JOIN ods_base_organisation_unit res_state ON res_state.id=CAST(r.stateid AS BIGINT) and res_state.ods_datim_id=p.ods_datim_id
	LEFT JOIN ods_base_organisation_unit res_lga ON res_lga.id=CAST(r.lgaid AS BIGINT) AND res_lga.ods_datim_id=p.ods_datim_id;