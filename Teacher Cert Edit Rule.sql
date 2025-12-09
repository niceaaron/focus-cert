/*
Name (description): Teacher Cert Contains Invalid Level and Subject Combo
requires Create Table PAEC_CCD_CERT_CODES (run first).sql to be run first 
This SQL edit rule cross references the teacher certificaiton logging field entries against a custom table of the valid combinations of certifications and levels, preventing invalid entries.
*/

-- message: PAEC TCHRCERT SP1 SQL
-- name: Teacher Cert Contains Invalid Level and Subject Combo
-- category: FocusUser
-- type: validation

SELECT sle.source_id AS staff_id
FROM custom_field_log_entries sle
JOIN custom_fields cf ON cf.id = sle.field_id
AND cf.alias = 'teacher_certifications'
JOIN custom_field_select_options cfsosub ON cfsosub.id::varchar = sle.log_field1
JOIN custom_field_select_options cfsolvl ON cfsolvl.id::varchar = sle.log_field2
WHERE NOT EXISTS
    (SELECT ''
     FROM PAEC_CERT_LOG_OPTIONS sub
     WHERE sub.code = cfsosub.code
       AND sub.level = cfsolvl.code)
  AND CURRENT_DATE::date BETWEEN sle.log_field4::date AND sle.log_field5::date