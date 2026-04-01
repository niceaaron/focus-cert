-- 989 requirement says "SEE CURRICULUM FRAMEWORK FOR SPECIFIC CTE COVERAGE" we need to convert these to the correct codes based on the frameworks
-- The query in the next comment will show you which courses currently have the 989 requirement: 
-- select short_name,title, long_Title,status, certification_requirements from master_Courses where syear = 2025 and certification_requirements = '989' order by short_name

-- Using this list then have to manually look up each in the CTE curriculum frameworks website:
-- https://www.fldoe.org/academics/career-adult-edu/career-tech-edu/curriculum-frameworks/
-- In each individul .rtf of the framework you will find a table of courses with a column for "Teacher Certification" 
-- Using that value run it through the Crosswalk in CCD to find the appropriate codes to assign 

--Many of these do not have an appropriate code in the Crosswalk to use
--I guess if a district offered one of these they would need to "make up" a code to use in the catalog and their cert logging field 

--8601800	WORK-BASED EXP	Work-Based Experience/Level 2
--Since this program serves as a capstone experience for the student, the teacher certification must be appropriate to the student’s Engineering & Technology program of study and the teacher certifications specified in the respective curriculum framework.

--8601900	ADV TECHNOLOGY APPS	Advanced Technology Applications/Level 3
--Since this program serves as a capstone experience for the student, the teacher certification must be appropriate to the student’s Engineering & Technology program of study and the teacher certifications specified in the respective curriculum framework.

--REE0047	REAL ESTATE SALES AG	Real Estate Sales Agent
--Florida Licensed Real Estate Instructor

--REE0089	REAL EST SALES ASSC	Real Estate Sales Associate Post Licensing
--Florida Licensed Real Estate Instructor

--REE0092	MORTGAGE LOAN ORIG	Mortgage Loan Originator
-- Approval by Nationwide Mortgage Licensing System (NMLS)

--RMI0070	PROPERTY ADJ EST	Property Adjuster Estimating
--State Licensed Property Adjuster

--RMI0093	(INS) CUST SRV REP	(Insurance) Customer Service Representative
--Approval by and Registration with the Florida Department of Financial Services 

--RMI0094	INSURANCE CLAIMS ADJ	Insurance Claims Adjuster
--Approval by and Registration with the Florida Department of Financial Services 

--9500420	TRANSPORTATION OJT	Transportation Distribution and Logistics Cooperative Education OJT
--9501000	TRANSPORT DIR ST	Transportation Distribution and Logistics Directed Study
--These courses say "Any Certification appropriate to the students’ chosen career field"

--9700420	ENERGY OJT	Energy Cooperative Education - OJT
--9701000	ENERGY DIRECTED ST	Energy Directed Study
--These courses say "Any Certification appropriate to the students’ chosen career field"

--8700100	ARCH & CONST DS	Architecture and Construction Education Directed Study
--8700400	ARCH & CONSTRC - OJT	Architecture and Construction Cooperative Education - OJT
--These courses say "Any Certification appropriate to the students’ chosen career field"

--9200420	MANUFACTURING OJT	Manufacturing Cooperative Education OJT
--9201000	MANUF DIRECTED ST	Manufacturing Directed Study
--These courses say "Any Certification appropriate to the students’ chosen career field"



--DEA0725	INTRO TO DENTAL ASST	Introduction to Dental Assisting
--DEA0726	DENT INFECT CTRL AST	Dental Infection Control Assistant
--DEA0727	DENTAL ASSISTING 1	Dental Assisting 1
--DEA0728	DENTAL ASSISTING 2	Dental Assisting 2
--These courses say "DENTL ASST @7 7G"
update master_courses
set certification_requirements = '7417'
where syear  in (2025,2026) and short_name in (
'DEA0725',
'DEA0726',
'DEA0727',
'DEA0728');


--HSC0003	BASIC HEALTHCARE WKR	Basic Healthcare Worker
--PTN0084	PHARMACY TECH 1	Pharmacy Technician 1
--PTN0085	PHARMACY TECH 2	Pharmacy Technician 2
--PTN0086	PHARMACY TECH 3	Pharmacy Technician 3
--These courses are 989 and the curriuculm frameworks says "PHARMACY 7G" where is 7694
update master_courses
set certification_requirements = '7694'
where syear  in (2025,2026) and short_name in (
'HSC0003',
'PTN0084',
'PTN0085',
'PTN0086');

--EMS0110	EMER MEDICAL TECH	Emergency Medical Technician (EMT)
--This courses is 989 and curriuculm frameworks says :
--PARAMEDIC @7 7G = 7691
--EMT 7G = 7135
--REG NURSE 7 G = 7719
--PRAC NURSE @7  = 7505
update master_courses
set certification_requirements = '7691, 7135, 7719, 7505'
where syear  in (2025,2026) and short_name = 'EMS0110';

--8800420	HOSP & TOUR OJT	Hospitality and Tourism Cooperative Education OJT
--This courses is 989 in the CCD and frameworks says ANY CTE FIELD OR COVERAGE
update master_courses
set certification_requirements = '991'
where syear  in (2025,2026) and short_name = '8800420';


--HIM0009	INTRO TO H I T	Introduction to Health Information Technology
--HIM0091	MED CODER/BILLER 1	Medical Coder/Biller I
--HIM0092	MED CODER/BILLER 2	Medical Coder/Biller II
--HIM0093	MED CODER/BILLER 3	Medical Coder/Biller III
--Allow for: MED RECTEC 7G, MED ASST 7G, MED TRANS 7G
update master_courses
set certification_requirements = '7664, G664, 7664, G664, 7692, G692, 7701, G701'
where syear in (2025,2026) and short_name in ('HIM0009','HIM0091','HIM0092','HIM0093');
