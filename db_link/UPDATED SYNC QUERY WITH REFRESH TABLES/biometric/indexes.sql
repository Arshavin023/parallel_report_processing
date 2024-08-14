--BASE AND RECAPTURE BIOMETRIC INDEXES;
-- Partial index for specific filtering
CREATE INDEX idx_biometric_partial
ON biometric (person_uuid, ods_datim_id, enrollment_date, count)
WHERE version_iso_20 IS TRUE
  AND archived = 0
  AND recapture = 0;