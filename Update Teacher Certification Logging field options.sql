--Note this requies PAEC_CERT_LOG_OPTIONS be installed first 
--Check that all the subject codes exist, if not add them:

INSERT INTO custom_field_select_options 
(SOURCE_CLASS, SOURCE_ID, CODE, LABEL, DISTRICT_ID) 
select distinct
	'CustomFieldLogColumn'
	, (select id from custom_field_log_columns cflc
			where column_name = 'LOG_FIELD1' 
			and exists (select '' from custom_fields cf 
					where cf.alias = 'teacher_certifications' 
					and cf.id = cflc.field_id))
	, pcsl.code
	, concat(pcsl.code, ' ',pcsl.label)
	, 1
from PAEC_CERT_LOG_OPTIONS pcsl
where not exists (select '' from custom_field_select_options cfso 
	where cfso.source_id = (select id from custom_field_log_columns cflc where column_name = 'LOG_FIELD1' 
		and exists (select '' from custom_fields cf where cf.alias = 'teacher_certifications' and cf.id = cflc.field_id))
	and cfso.code = pcsl.code
	and cfso.source_class = 'CustomFieldLogColumn');



--inactivate subject codes which are not on our list:
update custom_field_select_options cfso 
set inactive = 1
where cfso.source_id = (select id from custom_field_log_columns cflc where column_name = 'LOG_FIELD1' 
	and exists (select '' from custom_fields cf where cf.alias = 'teacher_certifications' and cf.id = cflc.field_id))
and cfso.source_class = 'CustomFieldLogColumn'
and not exists (select '' from PAEC_CERT_LOG_OPTIONS pcsl where cfso.code = pcsl.code)
and cfso.deleted is null
and cfso.max_syear is null
and cfso.inactive is null;

--Update the labels of the select options of the subjects to make them consistent across all the districts
update custom_field_select_options cfso 
set label = concat(pcsl.code, ' ', pcsl.label)
from PAEC_CERT_LOG_OPTIONS pcsl
where cfso.source_id = (select id from custom_field_log_columns cflc where column_name = 'LOG_FIELD1' 
	and exists (select '' from custom_fields cf where cf.alias = 'teacher_certifications' and cf.id = cflc.field_id))
and cfso.source_class = 'CustomFieldLogColumn'
and cfso.code = pcsl.code
and cfso.deleted is null
and cfso.max_syear is null
and cfso.inactive is null;

--set the sort order so that:
--4 digit ed certs are 1st 
update custom_field_select_options cfso 
set sort_order = 1
from PAEC_CERT_LOG_OPTIONS pcsl
where cfso.source_id = (select id from custom_field_log_columns cflc where column_name = 'LOG_FIELD1' 
	and exists (select '' from custom_fields cf where cf.alias = 'teacher_certifications' and cf.id = cflc.field_id))
and cfso.source_class = 'CustomFieldLogColumn'
and length(cfso.code) =4
and cfso.deleted is null
and cfso.max_syear is null
and cfso.inactive is null;

--3 digit therapists/special certs are 2nd 
update custom_field_select_options cfso 
set sort_order = 2
from PAEC_CERT_LOG_OPTIONS pcsl
where cfso.source_id = (select id from custom_field_log_columns cflc where column_name = 'LOG_FIELD1' 
	and exists (select '' from custom_fields cf where cf.alias = 'teacher_certifications' and cf.id = cflc.field_id))
and cfso.source_class = 'CustomFieldLogColumn'
and cfso.code in ('0000','900', '901', '902','893','894','880', '209', '370',  '930','941', '799')
and cfso.deleted is null
and cfso.max_syear is null
and cfso.inactive is null;

--CTE certs are 3rd 
update custom_field_select_options cfso 
set sort_order = 3
from PAEC_CERT_LOG_OPTIONS pcsl
where cfso.source_id = (select id from custom_field_log_columns cflc where column_name = 'LOG_FIELD1' 
	and exists (select '' from custom_fields cf where cf.alias = 'teacher_certifications' and cf.id = cflc.field_id))
and cfso.source_class = 'CustomFieldLogColumn'
and cfso.code not in ('0000','900', '901', '902','893','894','880', '209', '370',  '930','941', '799','940')
and length(cfso.code) != 4
and cfso.deleted is null
and cfso.max_syear is null
and cfso.inactive is null;

--everything else at bottom
update custom_field_select_options cfso 
set sort_order = 99
from PAEC_CERT_LOG_OPTIONS pcsl
where cfso.source_id = (select id from custom_field_log_columns cflc where column_name = 'LOG_FIELD1' 
	and exists (select '' from custom_fields cf where cf.alias = 'teacher_certifications' and cf.id = cflc.field_id))
and cfso.source_class = 'CustomFieldLogColumn'
and (cfso.deleted is not null
or cfso.max_syear is not null
or cfso.inactive is not null);




--inactivate levels that no longer valid 
--make sure to uncheck paginate if running in runquery 
with levels as (
	select '0' as code ,'0 - Early Childhood' as label UNION ALL
	select '1','1 - Grades 6-12' UNION ALL
	select '2','2 - Adult Education' UNION ALL
	select '3','3 - Elementary (1-6)' UNION ALL
	select '4','4 - Secondary (7-12)' UNION ALL
	select '5','5 - Grades K-8' UNION ALL
	select '6','6 - Elementary and Secondary (K-12)' UNION ALL
	select '7','7 - Career-Technical' UNION ALL
	select 'B','B - Primary (K-3)' UNION ALL
	select 'C','C - Middle Grades (5-9)' UNION ALL
	select 'D','D - Preschool-Secondary (PK-12)' UNION ALL
	select 'E','E - Endorsement' UNION ALL
	select 'F','F - District determined, valid at any level' UNION ALL
	select 'G','G - District issued employment certificate' UNION ALL
	select 'H','H - Prekindergarten/Primary (Age 3 through Grade 3)' UNION ALL
	select 'K','K - Elementary Education (K-6)' UNION ALL
	select 'L','L - Preschool (Birth through age 4)'
)
update custom_field_select_options cfso 
set inactive = 1
where cfso.source_id = (select id from custom_field_log_columns cflc where column_name = 'LOG_FIELD2' 
	and exists (select '' from custom_fields cf where cf.alias = 'teacher_certifications' and cf.id = cflc.field_id))
and cfso.source_class = 'CustomFieldLogColumn'
and cfso.code not in (select code from levels);


--update the label on the levels 
with levels as (
	select '0' as code ,'0 - Early Childhood' as label UNION ALL
	select '1','1 - Grades 6-12' UNION ALL
	select '2','2 - Adult Education' UNION ALL
	select '3','3 - Elementary (1-6)' UNION ALL
	select '4','4 - Secondary (7-12)' UNION ALL
	select '5','5 - Grades K-8' UNION ALL
	select '6','6 - Elementary and Secondary (K-12)' UNION ALL
	select '7','7 - Career-Technical' UNION ALL
	select 'B','B - Primary (K-3)' UNION ALL
	select 'C','C - Middle Grades (5-9)' UNION ALL
	select 'D','D - Preschool-Secondary (PK-12)' UNION ALL
	select 'E','E - Endorsement' UNION ALL
	select 'F','F - District determined, valid at any level' UNION ALL
	select 'G','G - District issued employment certificate' UNION ALL
	select 'H','H - Prekindergarten/Primary (Age 3 through Grade 3)' UNION ALL
	select 'K','K - Elementary Education (K-6)' UNION ALL
	select 'L','L - Preschool (Birth through age 4)'
)
update custom_field_select_options cfso 
set label = levels.label 
from levels 
where cfso.source_id = (select id from custom_field_log_columns cflc where column_name = 'LOG_FIELD2' 
	and exists (select '' from custom_fields cf where cf.alias = 'teacher_certifications' and cf.id = cflc.field_id))
and cfso.source_class = 'CustomFieldLogColumn'
and cfso.code =levels.code;



--add any missing levels
with levels as (
	select '0' as code ,'0 - Early Childhood' as label UNION ALL
	select '1','1 - Grades 6-12' UNION ALL
	select '2','2 - Adult Education' UNION ALL
	select '3','3 - Elementary (1-6)' UNION ALL
	select '4','4 - Secondary (7-12)' UNION ALL
	select '5','5 - Grades K-8' UNION ALL
	select '6','6 - Elementary and Secondary (K-12)' UNION ALL
	select '7','7 - Career-Technical' UNION ALL
	select 'B','B - Primary (K-3)' UNION ALL
	select 'C','C - Middle Grades (5-9)' UNION ALL
	select 'D','D - Preschool-Secondary (PK-12)' UNION ALL
	select 'E','E - Endorsement' UNION ALL
	select 'F','F - District determined, valid at any level' UNION ALL
	select 'G','G - District issued employment certificate' UNION ALL
	select 'H','H - Prekindergarten/Primary (Age 3 through Grade 3)' UNION ALL
	select 'K','K - Elementary Education (K-6)' UNION ALL
	select 'L','L - Preschool (Birth through age 4)'
)
INSERT INTO custom_field_select_options 
(SOURCE_CLASS, SOURCE_ID, CODE, LABEL, DISTRICT_ID) 
select distinct
	'CustomFieldLogColumn'
	, (select id from custom_field_log_columns cflc
			where column_name = 'LOG_FIELD2' 
			and exists (select '' from custom_fields cf 
					where cf.alias = 'teacher_certifications' 
					and cf.id = cflc.field_id))
	, levels.code
	, levels.label
	, 1
from levels
where not exists (select '' from custom_field_select_options cfso 
	where cfso.source_id = (select id from custom_field_log_columns cflc where column_name = 'LOG_FIELD2' 
		and exists (select '' from custom_fields cf where cf.alias = 'teacher_certifications' and cf.id = cflc.field_id))
	and cfso.code = levels.code
	and cfso.source_class = 'CustomFieldLogColumn');


--update level labels
with levels as (
	select '0' as code ,'0 - Early Childhood' as label UNION ALL
	select '1','1 - Grades 6-12' UNION ALL
	select '2','2 - Adult Education' UNION ALL
	select '3','3 - Elementary (1-6)' UNION ALL
	select '4','4 - Secondary (7-12)' UNION ALL
	select '5','5 - Grades K-8' UNION ALL
	select '6','6 - Elementary and Secondary (K-12)' UNION ALL
	select '7','7 - Career-Technical' UNION ALL
	select 'B','B - Primary (K-3)' UNION ALL
	select 'C','C - Middle Grades (5-9)' UNION ALL
	select 'D','D - Preschool-Secondary (PK-12)' UNION ALL
	select 'E','E - Endorsement' UNION ALL
	select 'F','F - District determined, valid at any level' UNION ALL
	select 'G','G - District issued employment certificate' UNION ALL
	select 'H','H - Prekindergarten/Primary (Age 3 through Grade 3)' UNION ALL
	select 'K','K - Elementary Education (K-6)' UNION ALL
	select 'L','L - Preschool (Birth through age 4)'
)
update custom_field_select_options cfso 
set label = levels.label 
from levels 
where cfso.source_id = (select id from custom_field_log_columns cflc where column_name = 'LOG_FIELD2' 
	and exists (select '' from custom_fields cf where cf.alias = 'teacher_certifications' and cf.id = cflc.field_id))
and cfso.source_class = 'CustomFieldLogColumn'
and cfso.code =levels.code;


