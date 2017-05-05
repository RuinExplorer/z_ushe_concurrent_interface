/* Formatted on 5/5/2017 3:01:55 PM (QP5 v5.300) */
--Script to return values of Race CROSSWALK

SELECT sorxref_edi_value, sorxref_banner_value, sorxref_desc
  FROM sorxref
 WHERE sorxref_xlbl_code = 'GORRACE' AND sorxref_edi_standard_ind = 'Y';

/*******************************************************************************
  STVXLBL SETUP SCRIPT - Script to build out the required cross-walk label.
*******************************************************************************/

INSERT INTO stvxlbl (stvxlbl_code,
                     stvxlbl_desc,
                     stvxlbl_system_req_ind,
                     stvxlbl_activity_date)
     VALUES ('GORRACE',
             'Race codes',
             'N',
             TRUNC (SYSDATE));

COMMIT;

/*******************************************************************************
  INFO - Script to verify successful build of cross-walk label.
*******************************************************************************/

SELECT *
  FROM stvxlbl
 WHERE stvxlbl_code = 'GORRACE';

/*******************************************************************************
  DATA LOAD SCRIPTS - Scripts to manually build out SORXREF entries
   
  These are unessesary if data was loaded via alternate method.
*******************************************************************************/

INSERT INTO sorxref (SORXREF_XLBL_CODE,
                     SORXREF_EDI_VALUE,
                     SORXREF_EDI_STANDARD_IND,
                     SORXREF_DISP_WEB_IND,
                     SORXREF_ACTIVITY_DATE,
                     SORXREF_EDI_QLFR,
                     SORXREF_DESC,
                     SORXREF_BANNER_VALUE,
                     SORXREF_PESC_XML_IND)
     VALUES ('GORRACE',
             'B',                                             --USHE Race Code
             'Y',
             'N',
             TRUNC (SYSDATE),
             NULL,
             'Black/African American',
             'B',   --Banner Race code from GORRACE, USU happens to match USHE
             'N');

INSERT INTO sorxref (SORXREF_XLBL_CODE,
                     SORXREF_EDI_VALUE,
                     SORXREF_EDI_STANDARD_IND,
                     SORXREF_DISP_WEB_IND,
                     SORXREF_ACTIVITY_DATE,
                     SORXREF_EDI_QLFR,
                     SORXREF_DESC,
                     SORXREF_BANNER_VALUE,
                     SORXREF_PESC_XML_IND)
     VALUES ('GORRACE',
             'I',                                             --USHE Race Code
             'Y',
             'N',
             TRUNC (SYSDATE),
             NULL,
             'American Indian',
             'I',   --Banner Race code from GORRACE, USU happens to match USHE
             'N');

INSERT INTO sorxref (SORXREF_XLBL_CODE,
                     SORXREF_EDI_VALUE,
                     SORXREF_EDI_STANDARD_IND,
                     SORXREF_DISP_WEB_IND,
                     SORXREF_ACTIVITY_DATE,
                     SORXREF_EDI_QLFR,
                     SORXREF_DESC,
                     SORXREF_BANNER_VALUE,
                     SORXREF_PESC_XML_IND)
     VALUES ('GORRACE',
             'P',                                             --USHE Race Code
             'Y',
             'N',
             TRUNC (SYSDATE),
             NULL,
             'Native Hawaiian',
             'P',   --Banner Race code from GORRACE, USU happens to match USHE
             'N');

INSERT INTO sorxref (SORXREF_XLBL_CODE,
                     SORXREF_EDI_VALUE,
                     SORXREF_EDI_STANDARD_IND,
                     SORXREF_DISP_WEB_IND,
                     SORXREF_ACTIVITY_DATE,
                     SORXREF_EDI_QLFR,
                     SORXREF_DESC,
                     SORXREF_BANNER_VALUE,
                     SORXREF_PESC_XML_IND)
     VALUES ('GORRACE',
             'S',                                             --USHE Race Code
             'Y',
             'N',
             TRUNC (SYSDATE),
             NULL,
             'Asian',
             'S',   --Banner Race code from GORRACE, USU happens to match USHE
             'N');

INSERT INTO sorxref (SORXREF_XLBL_CODE,
                     SORXREF_EDI_VALUE,
                     SORXREF_EDI_STANDARD_IND,
                     SORXREF_DISP_WEB_IND,
                     SORXREF_ACTIVITY_DATE,
                     SORXREF_EDI_QLFR,
                     SORXREF_DESC,
                     SORXREF_BANNER_VALUE,
                     SORXREF_PESC_XML_IND)
     VALUES ('GORRACE',
             'W',                                             --USHE Race Code
             'Y',
             'N',
             TRUNC (SYSDATE),
             NULL,
             'White',
             'W',   --Banner Race code from GORRACE, USU happens to match USHE
             'N');


/*******************************************************************************
  INFO - Script to verify successful load of cross-walk values to SORXREF.
*******************************************************************************/

SELECT *
  FROM sorxref
 WHERE sorxref_xlbl_code = 'GORRACE';