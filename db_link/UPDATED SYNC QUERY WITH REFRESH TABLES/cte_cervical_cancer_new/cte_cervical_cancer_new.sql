CREATE TABLE cervical_cancer AS 
select  DISTINCT ON (ho.person_uuid, ho.ods_datim_id) ho.person_uuid AS person_uuid90,
ho.ods_datim_id as cerv_ods_datim_id, ho.uuid,
ho.date_of_observation AS dateOfCervicalCancerScreening, 
ho.data ->> ''screenTreatmentMethodDate'' AS treatmentMethodDate,cc_type.display AS cervicalCancerScreeningType, 
cc_method.display AS cervicalCancerScreeningMethod, cc_trtm.display AS cervicalCancerTreatmentScreened, 
cc_result.display AS resultOfCervicalCancerScreening, 
--ROW_NUMBER() OVER (PARTITION BY ho.person_uuid ORDER BY ho.date_of_observation DESC) AS row 
from ods_hiv_observation ho 
LEFT JOIN ods_base_application_codeset cc_type ON cc_type.code = CAST(ho.data ->> ''screenType'' AS VARCHAR) 
AND cc_type.ods_datim_id=ho.ods_datim_id
LEFT JOIN ods_base_application_codeset cc_method ON cc_method.code = CAST(ho.data ->> ''screenMethod'' AS VARCHAR)
AND cc_method.ods_datim_id=ho.ods_datim_id
LEFT JOIN ods_base_application_codeset cc_result ON cc_result.code = CAST(ho.data ->> ''screeningResult'' AS VARCHAR) 
AND cc_result.ods_datim_id=ho.ods_datim_id
LEFT JOIN ods_base_application_codeset cc_trtm ON cc_trtm.code = CAST(ho.data ->> ''screenTreatment'' AS VARCHAR) 
AND cc_trtm.ods_datim_id=ho.ods_datim_id
where ho.archived = 0 and type = ''Cervical cancer''
--SELECTING ONLY NEW DATA
--composite key is ho.ods_datim_id, ho.uuid - on conflict insert
--INDEX = ho.date_of_observation
-------------------------------------------------------------------------------------------------------------------------

--*****************CTES***************************
CREATE TABLE sub_cervical_cancer_new AS 
SELECT * FROM cervical_cancer ho
ROW_NUMBER() OVER (PARTITION BY ho.person_uuid90 ORDER BY ho.dateOfCervicalCancerScreening DESC) AS row 
WHERE ho.dateOfCervicalCancerScreening <= (select date from expanded_radet.period where is_active)
--INDEX row
-------------------------------------------------------------------------------------------------------------------------



CREATE cte_cervical_cancer_new
SELECT * FROM sub_cervical_cancer_new WHERE row = 1

-- INDEX FINAL OUTPUT