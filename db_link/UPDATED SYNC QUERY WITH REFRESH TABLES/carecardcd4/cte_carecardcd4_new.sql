CREATE care_card_cd4 AS 
SELECT visit_date,coalesce(cast(cd_4 as varchar),cd4_semi_quantitative) as cd_4, 
person_uuid AS cccd4_person_uuid,ods_datim_id as care_ods_datim_id, uuid
FROM public.ods_hiv_art_clinical 
WHERE is_commencement is true AND archived = 0 
AND cd_4 != ''0'' 
--SELECTING ONLY NEW DATA
--INDEX
--composite key  - uuid, ods_datim_id - on conflict insert
-------------------------------------------------------------------------------------------

--*****************CTES***************************

CREATE cte_carecardcd4_new AS 
SELECT * FROM care_card AND visit_date <= (select date from expanded_radet.period where is_active) ---?3'
--INDEX