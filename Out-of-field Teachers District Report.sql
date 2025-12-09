-- title: Out-of-field Teachers
-- description: Enter an effective date which will determine which courses/terms and student schedules are included in the report. This report requires the automated job Update Teacher Certifications to be running that assigns Cert/Licensure/Qual Status based on the Certification logging field. The report will show by school all teachers who have been assigned a section of students with an out of field subject area and their current area of certification. Note: the out of field subject area that displays in the report is the first subject listed in the CCD Requirements column of the catalog for the course, if the requirement does not display and invalid subject is listed first.
-- required one custom variable EFFECTIVE_DATE
-- note: this is a district wide report, larger districts may need to break this up by school
-- This report uses the same logic as OOF Computed Table.sql

WITH teacher_certs AS
--This CTE gets the teacher's certification logging field data 

  (SELECT cflc.source_id AS staff_id,
          cfso1.label AS Subject_area,
          cfso2.code AS LEVEL,
          cfso3.code AS TYPE,
          cflc.log_field4 AS Issue_date,
          cflc.log_field5 AS Exp_date
   FROM custom_field_log_entries cflc
   LEFT JOIN custom_field_select_options cfso1 ON CAST(cfso1.id AS varchar) = cflc.log_field1
   LEFT JOIN custom_field_select_options cfso2 ON CAST(cfso2.id AS varchar) = cflc.log_field2
   LEFT JOIN custom_field_select_options cfso3 ON CAST(cfso3.id AS varchar) = cflc.log_field3
   WHERE EXISTS
       (SELECT ''
        FROM custom_fields cf
        WHERE cf.column_name = 'custom_20120005'
          AND cf.id = cflc.field_id)
     AND cflc.source_class = 'FocusUser'
     AND '{EFFECTIVE_DATE}'::date BETWEEN cflc.log_field4::date AND cflc.log_field5::date
),
ESE AS
--This CTE gets the student's ESE status
  (SELECT esel.source_id AS student_id,
          exc.code AS exc
   FROM custom_field_log_entries esel
   JOIN custom_field_select_options exc ON esel.log_field3 = exc.id::varchar
   JOIN custom_field_select_options sts ON esel.log_field6 = sts.id::varchar
   JOIN custom_fields cf ON cf.id = esel.field_id
   AND cf.column_name = 'custom_890'
   WHERE 1=1
     AND esel.log_field4 = 'Y'
     AND sts.code = 'A'
),
sched AS
--This gets the schedule records for which the student has an OOF teacher 
  (SELECT cp.school_id,
          cp.course_period_id,
		  JSON_ARRAY_ELEMENTS(cp.out_reason :: JSON):: TEXT AS reason --note this reason is only populated when you have run the Update Teacher Certification scheduled job or reconciled on the OOF report
          sc.custom_22 AS tier,--this is the reading intervention tier
          cp.teacher_id,
          sc.student_id,
          CASE
              WHEN cc.label IS NOT NULL THEN cc.label
              ELSE 'None'
          END AS catalog_cert,
          c.short_name,
          c.title
   FROM schedule sc
   JOIN student_enrollment se ON se.student_id = sc.student_id
   AND se.syear = sc.syear
   AND ((CAST('{EFFECTIVE_DATE}' AS date) BETWEEN se.start_date AND se.end_date)
        OR (CAST('{EFFECTIVE_DATE}' AS date) >= se.start_date
            AND se.end_date IS NULL))
   JOIN course_periods cp ON cp.course_period_id = sc.course_period_id
   JOIN courses c ON c.course_id = cp.course_id
   JOIN master_courses mc ON SUBSTRING(mc.short_name, 1, 7) = SUBSTRING(c.short_name, 1, 7)
   AND mc.syear = c.syear
   LEFT JOIN
     (SELECT ccd.code,
             ccd.label
      FROM PAEC_CCD_CERT_CODES ccd
      UNION ALL SELECT concat(log.level, log.code) AS code,
                       log.description AS label
      FROM PAEC_CERT_LOG_OPTIONS log) cc 
	  --this was originally developed to handle the word and in the Catalog CCD Reqs, we no longer user that option but did not remove the functionality in the report in case we ever need it
		ON (cc.code = CASE
                          WHEN SUBSTRING((STRING_TO_ARRAY(TRIM(','
                                                               FROM mc.certification_requirements), ','))[1]
                                         FROM 1) ILIKE '%and%' THEN CAST(SUBSTRING((STRING_TO_ARRAY(mc.certification_requirements, ' and '))[1]
                                                                                   FROM 1) AS VARCHAR)
                          ELSE SUBSTRING((STRING_TO_ARRAY(TRIM(','
                                                               FROM mc.certification_requirements), ','))[1]
                                         FROM 1)
                      END)
   WHERE sc.syear = {SYEAR}
     AND COALESCE(cp.out_reason, '') <> ''
     AND ((CAST('{EFFECTIVE_DATE}' AS date) BETWEEN sc.start_date AND sc.end_date)
          OR (CAST('{EFFECTIVE_DATE}' AS date) >= sc.start_date
              AND sc.end_date IS NULL))
     AND cp.custom_28 IN ('O','B')
     AND cp.CP_CHECKBOX_SETTING_5 IS DISTINCT
     FROM 'Y'
     AND (EXISTS
            (SELECT ''
             FROM marking_periods mp
             WHERE (mp.marking_period_id = sc.marking_period_id
                    OR (sc.marking_period_id = 0
                        AND mp.type = 'year'))
               AND mp.syear = {SYEAR}
               AND mp.school_id = sc.school_id
               AND mp.start_date <= CAST('{EFFECTIVE_DATE}' AS date)
               AND mp.end_date >= CAST('{EFFECTIVE_DATE}' AS date)))
)
SELECT DISTINCT 
	sch.title AS "School Name",
    CONCAT(u.last_name, ', ', u.first_name) AS "Teacher Name",
    sc.title AS "Course Name",
    CASE
        WHEN NOT EXISTS
               (SELECT ''
                FROM teacher_certs tc
                WHERE tc.staff_id = u.staff_id) THEN 'None'
        ELSE array_to_string(array
                               (SELECT TRIM(LEADING '0123456789 '
                                            FROM tc.Subject_area)
                                FROM teacher_certs tc
                                WHERE tc.staff_id = u.staff_id), ',<br>')
    END AS "Current Area of Certification",
    STRING_AGG(DISTINCT CASE
                            WHEN sc.reason = '"ELL"'
                                 AND ell.code = 'LY' THEN 'ESOL'
                            WHEN sc.reason = '"ESE"'
                                 AND COALESCE(ese.exc, '') NOT IN ('L', '') THEN 'ESE ENDORSEMENT'
                            WHEN sc.reason = '"GIFT"'
                                 AND COALESCE(ese.exc, '') = 'L' THEN 'GIFTED'
                            WHEN sc.reason = '"REA"'
                                 AND sc.tier IN ('A', 'B') THEN 'READING ENDORSEMENT'
                            WHEN sc.catalog_cert = 'None' THEN 'None'
                            ELSE TRIM(LEADING '0123456789 '
                                      FROM sc.catalog_cert)
                        END, ',<br>') AS "Out-of-Field Subject Area/Endorsement"
FROM students s
JOIN sched sc ON sc.student_id = s.student_id
JOIN schools sch ON sch.id = sc.school_id
JOIN users u ON u.staff_id = sc.teacher_id
LEFT JOIN custom_field_select_options ell ON s.custom_626 = ell.id
AND ell.source_class = 'CustomField'
LEFT JOIN ese ON sc.student_id = ese.student_id
WHERE (sc.reason IN ('"SUB"',
                     '"COMBINED"',
                     '"CER"',
                     '"ASD"',
                     '"GRADE"')
       OR (sc.reason = '"ELL"'
           AND ell.code = 'LY')
       OR (sc.reason = '"ESE"'
           AND COALESCE(ese.exc, '') NOT IN ('L',
                                             ''))
       OR (sc.reason = '"GIFT"'
           AND COALESCE(ese.exc, '') = 'L')
       OR (sc.reason = '"REA"'
           AND sc.tier IN ('A',
                           'B')))
GROUP BY sch.title,
         u.last_name,
         u.first_name,
         sc.title,
         u.staff_id,
         sc.course_period_id
ORDER BY 1,
         2,
         3
