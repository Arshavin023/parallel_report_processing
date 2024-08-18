select * from public.stg_to_ods_monitoring
where record_count > 0

update public.stg_to_ods_monitoring 
set record_count=23316393
where table_name='ods_biometric'

SELECT * FROM public.stg_to_ods_monitoring
--set streamed_by_base_biometric=NULL, streamed_by_recapture_biometric=NULL
WHERE table_name = 'ods_biometric'