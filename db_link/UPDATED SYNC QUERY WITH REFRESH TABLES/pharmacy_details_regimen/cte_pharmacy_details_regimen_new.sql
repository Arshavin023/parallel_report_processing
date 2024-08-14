  ----------------------------------------------------------------------------------------------------
CREATE TABLE pharmacy AS 
SELECT p.uuid, p.person_uuid as person_uuid40,p.ods_datim_id as pharma_ods_datim_id,
COALESCE(ds_model.display, p.dsd_model_type) as dsdModel, 
p.visit_date ,r.description as ods_hiv_regimen_description, 
rt.description as ods_hiv_regimen_type_description ,p.next_appointment, r.regimen_type_id,
p.refill_period, p.ods_load_time
--ROW_NUMBER() OVER (PARTITION BY p.person_uuid, p.ods_datim_id ORDER BY p.visit_date DESC) as rnkkk3 
from public.ods_hiv_art_pharmacy p 
INNER JOIN public.ods_hiv_art_pharmacy_regimens pr ON pr.art_pharmacy_id = p.id AND pr.ods_datim_id = p.ods_datim_id  
LEFT JOIN public.ods_hiv_regimen r on r.id = pr.regimens_id AND r.ods_datim_id = pr.ods_datim_id						--INNER
LEFT JOIN public.ods_hiv_regimen_type rt on rt.id = r.regimen_type_id AND rt.ods_datim_id = r.ods_datim_id				--INNER
LEFT OUTER JOIN ods_base_application_codeset ds_model on ds_model.code = p.dsd_model_type  
AND ds_model.ods_datim_id = p.ods_datim_id  
          --WHERE 
		  --r.regimen_type_id in (1, 2, 3, 4, 14) 
		  --AND 
		  --p.archived = 0 
		  --AND p.visit_date is not null
		--AND p.refill_period is not null 
	--INDEX r.regimen_type_id, archived, visit_date, refill_period
	--composite key is ods_datim_id, uuid - on conflict insert
	--SELECTING ONLY NEW DATA

  
  
  -----------------------------------------------------------------------------------------------
  CREATE TABLE arv_pharmacy AS 
  SELECT uuid, person_uuid40, pharma_ods_datim_id, dsdModel, 
            visit_date as dateofStartofCurrentARTRegimen,ods_hiv_regimen_description as currentARTRegimen, 
            ods_hiv_regimen_type_description as currentRegimenLine,p.next_appointment as nextPickupDate, 
            CAST(CAST(refill_period AS INTEGER) / 30.0 AS DECIMAL(10, 1)) AS monthsOfARVRefill,
            --ROW_NUMBER() OVER (PARTITION BY p.person_uuid, p.ods_datim_id ORDER BY p.visit_date DESC) as rnkkk3 
          from expanded_radet.pharmacy_details_regimen p 
          WHERE regimen_type_id in (1, 2, 3, 4, 14) 
		  --AND p.archived = 0 
		  AND visit_date is not null
		AND refill_period is not null 
		AND ods_hiv_regimen_description IS NOT NULL
		AND ods_hiv_regimen_type_description IS NOT NULL
	--INDEX r.regimen_type_id, archived, visit_date, refill_period
	--composite key is ods_datim_id, uuid - on conflict insert
	--SELECTING ONLY NEW DATA

			
			
---------------------------------------------------------------------------------------------------
--************the CTES********************
CREATE TABLE sub_art_pharmacy AS 

SELECT *,
ROW_NUMBER() OVER (PARTITION BY person_uuid40, pharma_ods_datim_id ORDER BY dateofStartofCurrentARTRegimen DESC) as rnkkk3 
 FROM arv_pharmacy
 AND p.visit_date >= '1980-01-01' ---?2 
 AND p.visit_date <= (select date from expanded_radet.period where is_active) ---?3
 
 
----------------------------------------------------------------------------------------------------


SELECT * FROM sub_art_pharmacy WHERE rnkkk3=1