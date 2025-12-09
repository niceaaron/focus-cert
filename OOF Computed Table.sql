--requires Create Table PAEC_CCD_CERT_CODES (run first).sql to be run first 
--This is the SQL for setting up a student field computed table (Students > Student Fields) listing that individual student's out of field teachers
--This table can be embedded in a communication template to generate individual OOF letters for the parents 


WITH teacher_certs AS (
--This CTE gets the teacher's certification logging field data 
	SELECT
		cflc.source_id AS staff_id,
		cfso1.label AS Subject_area,
		cfso2.code AS LEVEL,
		cfso3.code AS TYPE,
		cflc.log_field4 AS Issue_date,
		cflc.log_field5 AS Exp_date
	FROM
		custom_field_log_entries cflc
		LEFT JOIN custom_field_select_options cfso1 ON CAST(cfso1.id AS varchar) = cflc.log_field1
		LEFT JOIN custom_field_select_options cfso2 ON CAST(cfso2.id AS varchar) = cflc.log_field2
		LEFT JOIN custom_field_select_options cfso3 ON CAST(cfso3.id AS varchar) = cflc.log_field3
	WHERE
		EXISTS (
			SELECT
				''
			FROM
				custom_fields cf
			WHERE
				cf.column_name = 'custom_20120005'
				AND cf.id = cflc.field_id
		)
		AND cflc.source_class = 'FocusUser'
		AND CURRENT_DATE::date BETWEEN cflc.log_field4::date  AND cflc.log_field5::date
),
ESE as (
--This CTE gets the student's ESE status
		SELECT
			esel.source_id AS student_id,
			exc.code AS exc
		FROM
			custom_field_log_entries esel
			JOIN custom_field_select_options exc ON esel.log_field3 = exc.id::varchar
			JOIN custom_field_select_options sts ON esel.log_field6 = sts.id::varchar
			JOIN custom_fields cf ON cf.id = esel.field_id
			AND cf.column_name = 'custom_890'
		WHERE
			1=1
			AND esel.log_field4 = 'Y'
			AND sts.code = 'A'
),
sched as (
--This gets the schedule records for which the student has an OOF teacher 
	SELECT 
		cp.school_id 
		, cp.course_period_id 
		, JSON_ARRAY_ELEMENTS(cp.out_reason :: JSON):: TEXT AS reason --note this reason is only populated when you have run the Update Teacher Certification scheduled job or reconciled on the OOF report
		, sc.custom_22 as tier --this is the reading intervention tier
		, cp.teacher_id
		, sc.student_id 
		, case when cc.label is not null then cc.label else 'None' end as catalog_cert
		, c.short_name 
		, c.title 
	FROM
		schedule sc
		join student_enrollment se on se.student_id = sc.student_id
		and se.syear = sc.syear 
		and (
				(
					CAST(CURRENT_DATE AS date) BETWEEN se.start_date AND se.end_date
				)
				OR (
					CAST(CURRENT_DATE AS date) >= se.start_date
					AND se.end_date IS NULL
				)
			)
		JOIN course_periods cp ON cp.course_period_id = sc.course_period_id
		JOIN courses c ON c.course_id = cp.course_id
		JOIN master_courses mc ON SUBSTRING(mc.short_name, 1, 7) = SUBSTRING(c.short_name, 1, 7)
		AND mc.syear = c.syear
		--this next part just translates the codes into their descriptions 
		LEFT JOIN (select ccd.code, ccd.label 
						from PAEC_CCD_CERT_CODES ccd
						union all 
						select concat(log.level,log.code) as code, log.description as label from PAEC_CERT_LOG_OPTIONS log 
					) cc  ON 
			(cc.code = CASE
				WHEN SUBSTRING((STRING_TO_ARRAY(TRIM(',' FROM mc.certification_requirements), ','))[1] FROM 1) ILIKE '%and%'
				THEN CAST(SUBSTRING((STRING_TO_ARRAY(mc.certification_requirements, ' and '))[1] FROM 1) AS VARCHAR)
				ELSE SUBSTRING((STRING_TO_ARRAY(TRIM(',' FROM mc.certification_requirements), ','))[1] FROM 1)
			END)

	WHERE
		sc.syear = {SYEAR}
		and sc.student_id = {STUDENT_ID}
		and COALESCE(cp.out_reason, '') <> ''		
		--check to make sure the schedule is active 
		and 
		(
			(
				CAST(CURRENT_DATE AS date) BETWEEN sc.start_date AND sc.end_date
			)
			OR (
				CAST(CURRENT_DATE AS date) >= sc.start_date
				AND sc.end_date IS NULL
			)
		)
		AND cp.custom_28 in ('O','B')
		AND cp.CP_CHECKBOX_SETTING_5 IS DISTINCT FROM 'Y' 
		AND (
			EXISTS (
				SELECT
					''
				FROM
					marking_periods mp
				WHERE
					(mp.marking_period_id = sc.marking_period_id OR (sc.marking_period_id = 0 and mp.type = 'year'))
					and mp.syear = {SYEAR}
					and mp.school_id = sc.school_id 
					AND mp.start_date <= CAST(CURRENT_DATE AS date)
					AND mp.end_date >= CAST(CURRENT_DATE AS date)
			)
		)
		
)
SELECT
	DISTINCT 
	sch.title AS "School Name",
	sc.student_id AS student_id,
	CONCAT(u.last_name, ', ', u.first_name) AS "Teacher Name",
	sc.title as "Course Name",
	case 
		when not exists (select '' from teacher_certs tc where tc.staff_id = u.staff_id) then 'None'
		else array_to_string(array(
				SELECT
					TRIM(LEADING '0123456789 ' FROM tc.Subject_area)
				FROM
					teacher_certs tc
				WHERE
					tc.staff_id = u.staff_id
			),
			', <br>'
		) 
	end AS "Current Area of Certification",
	STRING_AGG(
		DISTINCT CASE 
			WHEN sc.reason = '"ELL"'  AND ell.code = 'LY'                         THEN 'ESOL'
			WHEN sc.reason = '"ESE"'  AND COALESCE(ese.exc, '') NOT IN ('L', '')  THEN 'ESE ENDORSEMENT'
			WHEN sc.reason = '"GIFT"' AND COALESCE(ese.exc, '') = 'L'             THEN 'GIFTED'
			WHEN sc.reason = '"REA"'  AND sc.tier IN ('A', 'B')                   THEN 'READING ENDORSEMENT'
			WHEN sc.catalog_cert = 'None'                                         THEN 'None'
			ELSE TRIM(LEADING '0123456789 ' FROM sc.catalog_cert) 
		END,
		', <br>'
	) AS "Out-of-Field Subject Area/Endorsement"

	from students s 
	join sched sc ON sc.student_id = s.student_id
	JOIN schools sch ON sch.id = sc.school_id
	JOIN users u ON u.staff_id = sc.teacher_id
	LEFT JOIN custom_field_select_options ell ON s.custom_626 = ell.id
	AND ell.source_class = 'CustomField'
	LEFT join ese ON sc.student_id = ese.student_id
	where  (
		sc.reason IN (
			'"SUB"', '"COMBINED"', '"CER"', '"ASD"',
			'"GRADE"'
		)
		OR (
			sc.reason = '"ELL"'
			AND ell.code = 'LY'
		) 
		OR (
			sc.reason = '"ESE"'
			AND COALESCE(ese.exc, '') NOT IN ('L', '')
		) 
		OR (
			sc.reason = '"GIFT"'
			AND COALESCE(ese.exc, '') = 'L'
		)
		OR (
			sc.reason = '"REA"'
			AND sc.tier IN ('A', 'B')
		)
	) 
	and s.student_id = {STUDENT_ID}
GROUP BY sc.student_id, sch.title, u.last_name, u.first_name, sc.title, u.staff_id
order by 1,2,3