/**********************************************************************************
  
PROGRAM:      C:\MEPS\SAS\PROG\EXERCISE1.SAS

DESCRIPTION:  THIS PROGRAM GENERATES THE FOLLOWING ESTIMATES ON NATIONAL HEALTH CARE EXPENSES BY TYPE OF SERVICE, 2014:

	           (1) PERCENTAGE DISTRIBUTION OF EXPENSES BY TYPE OF SERVICE
	           (2) PERCENTAGE OF PERSONS WITH AN EXPENSE, BY TYPE OF SERVIC
	           (3) MEAN EXPENSE PER PERSON WITH AN EXPENSE, BY TYPE OF SERVICE

             DEFINED SERVICE CATEGORIES ARE:
                HOSPITAL INPATIENT
                AMBULATORY SERVICE: OFFICE-BASED & HOSPITAL OUTPATIENT VISITS
                PRESCRIBED MEDICINES
                DENTAL VISITS
                EMERGENCY ROOM
                HOME HEALTH CARE (AGENCY & NON-AGENCY) AND OTHER (TOTAL EXPENDITURES - ABOVE EXPENDITURE CATEGORIES)

            NOTE: EXPENSES INCLUDE BOTH FACILITY AND PHYSICIAN EXPENSES.

INPUT FILE:   C:\MEPS\SAS\DATA\H171.SAS7BDAT (2014 FULL-YEAR FILE)

*********************************************************************************/;
OPTIONS LS=132 PS=79 NODATE;

*LIBNAME CDATA 'C:\MEPS\SAS\DATA';
LIBNAME CDATA "\\programs.ahrq.local\programs\meps\AHRQ4_CY2\B_CFACT\BJ001DVK\Workshop_2017\SAS\Data";

PROC FORMAT;
  VALUE AGEF
     0-  64 = '0-64'
     65-HIGH = '65+'
	          ;

  VALUE AGECAT
	   1 = '0-64'
	   2 = '65+'
	     ;

  VALUE GTZERO
     0         = '0'
     0 <- HIGH = '>0'
               ;
RUN;

TITLE1 '2017 AHRQ MEPS DATA USERS WORKSHOP';
TITLE2 "EXERCISE1.SAS: NATIONAL HEALTH CARE EXPENSES, 2014";

/* READ IN DATA FROM 2014 CONSOLIDATED DATA FILE (HC-163) */
DATA PUF171;
  SET CDATA.H171 (KEEP= TOTEXP14 IPDEXP14 IPFEXP14 OBVEXP14 RXEXP14
	                      OPDEXP14 OPFEXP14 DVTEXP14 ERDEXP14 ERFEXP14
	                      HHAEXP14 HHNEXP14 OTHEXP14 VISEXP14 AGE14X AGE42X AGE31X
	                      VARSTR   VARPSU   PERWT14F );

  /* Define expenditure variables by type of service  */

  TOTAL                = TOTEXP14;
  HOSPITAL_INPATIENT   = IPDEXP14 + IPFEXP14;
  AMBULATORY           = OBVEXP14 + OPDEXP14 + OPFEXP14 + ERDEXP14 + ERFEXP14;
  PRESCRIBED_MEDICINES = RXEXP14;
  DENTAL               = DVTEXP14;
  HOME_HEALTH_OTHER    = HHAEXP14 + HHNEXP14 + OTHEXP14 + VISEXP14;

 /*QC CHECK IF THE SUM OF EXPENDITURES BY TYPE OF SERVICE IS EQUAL TO TOTAL*/

  DIFF = TOTAL-HOSPITAL_INPATIENT - AMBULATORY   - PRESCRIBED_MEDICINES
              - DENTAL            - HOME_HEALTH_OTHER        ;

 /* CREATE FLAG (1/0) VARIABLES FOR PERSONS WITH AN EXPENSE, BY TYPE OF SERVICE  */

  ARRAY EXX  (6) TOTAL     HOSPITAL_INPATIENT   AMBULATORY     PRESCRIBED_MEDICINES
                 DENTAL    HOME_HEALTH_OTHER      ;

  ARRAY ANYX (6) X_ANYSVCE X_HOSPITAL_INPATIENT X_AMBULATORY    X_PRESCRIBED_MEDICINES
                 X_DENTAL  X_HOME_HEALTH_OTHER    ;

  DO II=1 TO 6;
    ANYX(II) = 0;
    IF EXX(II) > 0 THEN ANYX(II) = 1;
  END;
  DROP II;

  /* CREATE A SUMMARY VARIABLE FROM END OF YEAR, 42, AND 31 VARIABLES*/

       IF AGE14X >= 0 THEN AGE = AGE14X ;
  ELSE IF AGE42X >= 0 THEN AGE = AGE42X ;
  ELSE IF AGE31X >= 0 THEN AGE = AGE31X ;

       IF 0 LE AGE LE 64 THEN AGECAT=1 ;
  ELSE IF      AGE  > 64 THEN AGECAT=2 ;
RUN;

TITLE3 "Supporting crosstabs for the flag variables";
PROC FREQ DATA=PUF171;
   TABLES X_ANYSVCE              * TOTAL
          X_HOSPITAL_INPATIENT   * HOSPITAL_INPATIENT
          X_AMBULATORY           * AMBULATORY
          X_PRESCRIBED_MEDICINES * PRESCRIBED_MEDICINES
          X_DENTAL               * DENTAL
          X_HOME_HEALTH_OTHER    * HOME_HEALTH_OTHER
          AGECAT*AGE
          DIFF/LIST MISSING;
   FORMAT TOTAL          
          HOSPITAL_INPATIENT   
          AMBULATORY
          PRESCRIBED_MEDICINES 
          DENTAL
          HOME_HEALTH_OTHER         gtzero.
          AGE            agef.
     ;
RUN;

TITLE3 'PERCENTAGE DISTRIBUTION OF EXPENSES BY TYPE OF SERVICE (STAT BRIEF #491 FIGURE 1)';
PROC SURVEYMEANS DATA=PUF171 SUM STD;
	STRATUM VARSTR;
	CLUSTER VARPSU;
	WEIGHT PERWT14F;
	VAR   HOSPITAL_INPATIENT 
        AMBULATORY        
        PRESCRIBED_MEDICINES
	      DENTAL             
        HOME_HEALTH_OTHER 
        TOTAL ;
	RATIO  HOSPITAL_INPATIENT 
         AMBULATORY   
         PRESCRIBED_MEDICINES 
	       DENTAL             
         HOME_HEALTH_OTHER   / TOTAL ;
RUN;

TITLE3 'PERCENTAGE OF PERSONS WITH AN EXPENSE, BY TYPE OF SERVICE';
PROC SURVEYMEANS DATA= PUF171 MEAN STDERR SUM STD;
	STRATUM VARSTR ;
	CLUSTER VARPSU ;
	WEIGHT  PERWT14F ;
	VAR X_ANYSVCE  
	    X_HOSPITAL_INPATIENT  
	    X_AMBULATORY      
	    X_PRESCRIBED_MEDICINES
	    X_DENTAL   
	    X_HOME_HEALTH_OTHER;
RUN;

TITLE3 'MEAN EXPENSE PER PERSON WITH AN EXPENSE, BY TYPE OF SERVICE, FOR OVERALL, AGE 0-64, AND AGE 65+';
PROC SURVEYMEANS DATA= PUF171 MEAN NOBS SUMWGT STDERR SUM STD;
	STRATUM VARSTR ;
	CLUSTER VARPSU ;
	WEIGHT  PERWT14F ;	
	VAR  TOTAL;
	DOMAIN  X_ANYSVCE X_ANYSVCE*AGECAT ;
	FORMAT  AGECAT agecat.;
RUN;

PROC SURVEYMEANS DATA= PUF171 MEAN NOBS SUMWGT STDERR SUM STD;
	STRATUM VARSTR ;
	CLUSTER VARPSU ;
	WEIGHT  PERWT14F ;	
	VAR  HOSPITAL_INPATIENT;
	DOMAIN  X_HOSPITAL_INPATIENT X_HOSPITAL_INPATIENT*AGECAT ;
	FORMAT  AGECAT agecat.;
RUN;

PROC SURVEYMEANS DATA= PUF171 MEAN NOBS SUMWGT STDERR SUM STD;
	STRATUM VARSTR ;
	CLUSTER VARPSU ;
	WEIGHT  PERWT14F ;	
	VAR  AMBULATORY;
	DOMAIN  X_AMBULATORY  X_AMBULATORY*AGECAT ;
	FORMAT  AGECAT agecat.;
RUN;

PROC SURVEYMEANS DATA= PUF171 MEAN NOBS SUMWGT STDERR SUM STD;
	STRATUM VARSTR ;
	CLUSTER VARPSU ;
	WEIGHT  PERWT14F ;	
	VAR  PRESCRIBED_MEDICINES;
	DOMAIN  X_PRESCRIBED_MEDICINES X_PRESCRIBED_MEDICINES*AGECAT ;
	FORMAT  AGECAT agecat.;
RUN;

PROC SURVEYMEANS DATA= PUF171 MEAN NOBS SUMWGT STDERR SUM STD;
	STRATUM VARSTR ;
	CLUSTER VARPSU ;
	WEIGHT  PERWT14F ;	
	VAR  DENTAL;
	DOMAIN   X_DENTAL X_DENTAL*AGECAT ;
	FORMAT  AGECAT agecat.;
RUN;

PROC SURVEYMEANS DATA= PUF171 MEAN NOBS SUMWGT STDERR SUM STD;
	STRATUM VARSTR ;
	CLUSTER VARPSU ;
	WEIGHT  PERWT14F ;	
	VAR  HOME_HEALTH_OTHER;
	DOMAIN  X_HOME_HEALTH_OTHER X_HOME_HEALTH_OTHER*AGECAT ;
	FORMAT  AGECAT agecat.;
RUN;

