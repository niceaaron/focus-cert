--The purpose of these queries is to translate the CCD Certification Res to the Course Catalog in Focus. There are specific requirements for this data which are noted in comments above each query.
--Replace 2025 with the current school year. 

--This removes the special symbols from the CCD data file.
update master_courses mc
set certification_requirements =
replace(replace(
	trim(replace(replace(replace(replace(replace(replace(replace(replace(ccd.cert_levels, 'Z',' '), 'S',' '), 'W',' '), 'J',' '), 'Y',' '), 'O',' '), 'R',' '), 'T',' '))
,' ',', '),', , ',', ')
from course_code_directory ccd 
where ccd.course_year = '2025' 
and ccd.course_year = mc.syear::varchar 
and ccd.course_number = substring(mc.short_name,1,7);

--Add level codes to therapies. 
UPDATE master_courses SET certification_requirements = REGEXP_REPLACE(certification_requirements, '(^| )900(?=\D|$)','\16900') WHERE syear = 2025;
UPDATE master_courses SET certification_requirements = REGEXP_REPLACE(certification_requirements, '(^| )901(?=\D|$)','\16901') WHERE syear = 2025;
UPDATE master_courses SET certification_requirements = REGEXP_REPLACE(certification_requirements, '(^| )902(?=\D|$)','\16902') WHERE syear = 2025;
UPDATE master_courses SET certification_requirements = REGEXP_REPLACE(certification_requirements, '(^| )893(?=\D|$)','\16893') WHERE syear = 2025;
UPDATE master_courses SET certification_requirements = REGEXP_REPLACE(certification_requirements, '(^| )894(?=\D|$)','\16894') WHERE syear = 2025;
UPDATE master_courses SET certification_requirements = REGEXP_REPLACE(certification_requirements, '(^| )880(?=\D|$)','\16880') WHERE syear = 2025;
UPDATE master_courses SET certification_requirements = REGEXP_REPLACE(certification_requirements, '(^| )209(?=\D|$)','\16209') WHERE syear = 2025;
UPDATE master_courses SET certification_requirements = REGEXP_REPLACE(certification_requirements, '(^| )941(?=\D|$)','\1H941') WHERE syear = 2025;
UPDATE master_courses SET certification_requirements = REGEXP_REPLACE(certification_requirements, '(^| )930(?=\D|$)','\16930') WHERE syear = 2025;

--VPK Cert requirements are a little wierd in the data file, this just standardizes those courses. 
--added CDA code option H941 on 2026-06-22
UPDATE master_courses SET certification_requirements = 'L1042, H1041, E1065, H940, H941' WHERE syear in (2025,2026) and substring(short_name,1,7) = '5100580';
UPDATE master_courses SET certification_requirements = 'L1042, H1041, E1065, H940, H941' WHERE syear in (2025,2026) and substring(short_name,1,7) = '5100590';
--added two more VPK courses 2026-06-22:
UPDATE master_courses SET certification_requirements = 'L1042, H1041, E1065, H940, H941' WHERE syear in (2025,2026) and substring(short_name,1,7) = '5100570'; -- School Readiness
UPDATE master_courses SET certification_requirements = 'L1042, H1041, E1065, H940, H941' WHERE syear in (2025,2026) and substring(short_name,1,7) = '5100620'; -- Summer Bridge


--All of the 3 digit codes in Column A of the tab NWRDC Dual Certification are required to not have a level attached in the catalog in order to be evaluated correctly.
--I used a simple excel formula to generate these queries: 
--="UPDATE master_courses SET certification_requirements = REGEXP_REPLACE(certification_requirements, '(?<=^|,| )\w"&TEXT(A1,"000")&"', '"&TEXT(A1,"000")&"') where syear = 2025;"
--I then removed any queries that returned no results leaving the following updates
UPDATE master_courses SET certification_requirements = REGEXP_REPLACE(certification_requirements, '(?<=^|,| )\w025', '025') where syear = 2025;
UPDATE master_courses SET certification_requirements = REGEXP_REPLACE(certification_requirements, '(?<=^|,| )\w066', '066') where syear = 2025;
UPDATE master_courses SET certification_requirements = REGEXP_REPLACE(certification_requirements, '(?<=^|,| )\w068', '068') where syear = 2025;
UPDATE master_courses SET certification_requirements = REGEXP_REPLACE(certification_requirements, '(?<=^|,| )\w119', '119') where syear = 2025;
UPDATE master_courses SET certification_requirements = REGEXP_REPLACE(certification_requirements, '(?<=^|,| )\w330', '330') WHERE syear = 2025
UPDATE master_courses SET certification_requirements = REGEXP_REPLACE(certification_requirements, '(?<=^|,| )\w331', '331') WHERE syear = 2025
UPDATE master_courses SET certification_requirements = REGEXP_REPLACE(certification_requirements, '(?<=^|,| )\w723', '723') WHERE syear = 2025
UPDATE master_courses SET certification_requirements = REGEXP_REPLACE(certification_requirements, '(?<=^|,| )\w724', '724') WHERE syear = 2025
UPDATE master_courses SET certification_requirements = REGEXP_REPLACE(certification_requirements, '(?<=^|,| )\w744', '744') WHERE syear = 2025
UPDATE master_courses SET certification_requirements = REGEXP_REPLACE(certification_requirements, '(?<=^|,| )\w756', '756') WHERE syear = 2025
UPDATE master_courses SET certification_requirements = REGEXP_REPLACE(certification_requirements, '(?<=^|,| )\w757', '757') WHERE syear = 2025
UPDATE master_courses SET certification_requirements = REGEXP_REPLACE(certification_requirements, '(?<=^|,| )\w758', '758') WHERE syear = 2025
UPDATE master_courses SET certification_requirements = REGEXP_REPLACE(certification_requirements, '(?<=^|,| )\w759', '759') WHERE syear = 2025
UPDATE master_courses SET certification_requirements = REGEXP_REPLACE(certification_requirements, '(?<=^|,| )\w860', '860') WHERE syear = 2025
UPDATE master_courses SET certification_requirements = REGEXP_REPLACE(certification_requirements, '(?<=^|,| )\w768', '768') WHERE syear = 2025

--All of the 3 digit codes in Column D of the state-issued need the Instructional Level prepended in the FOCUS catalog
--I used a simple excel formulas to generate these queries: 
--="update master_courses mc set certification_requirements = replace(certification_requirements, ' "&TEXT(A1,"000")&"', ' "&B1&TEXT(A1,"000")&"') where syear = 2025;"
--="update master_courses mc set certification_requirements = replace(certification_requirements, '"&TEXT(A1,"000")&"', ' "&B1&TEXT(A1,"000")&"') where syear = 2025 and certification_requirements = '"&TEXT(A1,"000")&"';"
--="update master_courses mc set certification_requirements = replace(certification_requirements, '"&TEXT(A1,"000")&",', ' "&B1&TEXT(A1,"000")&"') where syear = 2025 and certification_requirements like '"&TEXT(A1,"000")&",%';"
--EXCEL FORMULA IF NEEDED LATER ="UPDATE master_courses SET certification_requirements = REGEXP_REPLACE(certification_requirements, '(^| )"&TEXT(A1,"000")&"(?=\D|$)','\1"&B1&TEXT(A1,"000")&"') WHERE syear = 2025;"
--I then removed any queries that returned no results leaving just a handful of the following updates
UPDATE master_courses SET certification_requirements = REGEXP_REPLACE(certification_requirements, '(^| )981(?=\D|$)','\1E981') WHERE syear = 2025
UPDATE master_courses SET certification_requirements = REGEXP_REPLACE(certification_requirements, '(^| )172(?=\D|$)','\16172') WHERE syear = 2025
UPDATE master_courses SET certification_requirements = REGEXP_REPLACE(certification_requirements, '(^| )217(?=\D|$)','\16217') WHERE syear = 2025

--Set dual enrollment courses to 9999
update master_courses
SET certification_requirements ='9999'
where SUBSTRING(UPPER(short_name), 1,1) BETWEEN 'A' AND 'Z'
and syear = 2025
and not exists (Select '' from course_code_directory ccd where ccd.course_year = '2025' 
and ccd.course_year = master_courses.syear::varchar 
and ccd.course_number = substring(master_courses.short_name,1,7));


--set ELL flag for everything except post-secondary courses
update master_courses
SET ELL = 1
where SUBSTRING(UPPER(short_name), 1,1) NOT BETWEEN 'A' AND 'Z'
and syear in (2025,2026);