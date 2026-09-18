-- id: 100348
-- parent_id: 100011
-- title: Teacher Certification Expiration
-- description: This report allows you to enter a date and see all the teachers who are assigned to teacher a class in the current school year who have a certification log field entry that is expired on that date. 


WITH certs AS
(
	SELECT 
		  cflc.source_id AS staff_id,
          cfso1.code AS Subject_area,
          cfso2.code AS LEVEL,
          cfso3.code AS TYPE,
          cfso3.code AS Cert_TYPE,
          CASE
              WHEN cf.column_name = 'custom_20120005' THEN cast(cflc.log_field4 AS date)
              ELSE NULL
          END AS Issue_date,
          CASE
              WHEN cf.column_name = 'custom_20120005' THEN cast(cflc.log_field5 AS date)
              ELSE NULL
          END AS Exp_date
   FROM users u
   JOIN custom_field_log_entries cflc on cflc.source_id = u.staff_id
   LEFT JOIN custom_field_select_options cfso1 ON cast(cfso1.id AS varchar) = cflc.log_field1
   LEFT JOIN custom_field_select_options cfso2 ON cast(cfso2.id AS varchar) = cflc.log_field2
   LEFT JOIN custom_field_select_options cfso3 ON cast(cfso3.id AS varchar) = cflc.log_field3
   JOIN custom_fields cf ON cf.column_name = 'custom_20120005'
   AND cf.id = cflc.field_id
),

sched_count AS
(
    SELECT 
        cp.teacher_id,
        cp.school_id,
        COUNT(DISTINCT CASE
            WHEN sc.end_date IS NULL 
                 OR sc.end_date >  '{EFFECTIVE_DATE}'::date
            THEN sc.student_id
        END) AS active_count,

        COUNT(DISTINCT CASE
            WHEN sc.end_date IS NOT NULL 
                 AND sc.end_date <=  '{EFFECTIVE_DATE}'::date
            THEN sc.student_id
        END) AS inactive_count

    FROM course_periods cp
    JOIN schedule sc 
        ON sc.course_period_id = cp.course_period_id
       AND sc.syear = {SYEAR}
    WHERE cp.syear = {SYEAR}
    GROUP BY cp.teacher_id, cp.school_id
)

SELECT 
    sch.title AS School,
    u.staff_id,
    u.last_name,
    u.first_name,
    u.custom_607 AS Cert_Number,
    c.Subject_area,
    c.LEVEL,
    c.TYPE,
    c.Issue_date,
    c.Exp_date,
    COALESCE(sc.active_count, 0) AS "Active Students",
    COALESCE(sc.inactive_count, 0) AS "Inactive Students"

FROM users u
JOIN course_periods cp 
    ON u.staff_id = cp.teacher_id
JOIN schools sch 
    ON sch.id = cp.school_id
JOIN certs c 
    ON c.staff_id = u.staff_id
LEFT JOIN sched_count sc 
    ON sc.teacher_id = u.staff_id
   AND sc.school_id = cp.school_id

WHERE cp.syear = {SYEAR}
  AND c.Exp_date <  '{EFFECTIVE_DATE}'::date

GROUP BY 
    sch.title,
    u.staff_id,
    u.last_name,
    u.first_name,
    u.custom_607,
    c.Subject_area,
    c.LEVEL,
    c.TYPE,
    c.Issue_date,
    c.Exp_date,
    sc.active_count,
    sc.inactive_count

ORDER BY 
    CASE 
        WHEN COALESCE(sc.active_count, 0) = 0 THEN 1
        ELSE 0
    END,
    CASE 
        WHEN u.custom_607 IS NULL THEN 5
        WHEN u.custom_607 = '0000000000' THEN 6
        WHEN u.custom_607 = '0000999999' THEN 7
        WHEN u.custom_607 = '8888888888' THEN 8
        WHEN u.custom_607 = '7777777777' THEN 9
        ELSE 0
    END,
    u.staff_id,
    sch.title;