/* Formatted on 4/21/2017 4:37:15 PM (QP5 v5.300) */
--Script to return values of SBGI CROSSWALK

SELECT sorxref_edi_value, sorxref_banner_value, sorxref_desc
  FROM sorxref
 WHERE sorxref_xlbl_code = 'STVSBGI' AND sorxref_edi_standard_ind = 'Y';

/*******************************************************************************
  STVXLBL SETUP SCRIPT - Script to build out the required cross-walk label.
*******************************************************************************/

INSERT INTO stvxlbl (stvxlbl_code,
                     stvxlbl_desc,
                     stvxlbl_system_req_ind,
                     stvxlbl_activity_date)
     VALUES ('STVSBGI',
             'SBGI codes',
             'N',
             TRUNC (SYSDATE));

COMMIT;

SELECT *
  FROM stvxlbl
 WHERE stvxlbl_code = 'STVSBGI';

/*******************************************************************************
  INFO - Script to verify successful load of BannerSBGI.csv table to SORXREF
         via TOAD, SQL Loader, or Banner MDUU (Mass Data Update Utility)
*******************************************************************************/

SELECT *
  FROM sorxref
 WHERE sorxref_xlbl_code = 'STVSBGI';

/*******************************************************************************
  WARNING - OPTIONAL SCRIPT - Scripts to manually build out SORXREF entries
   
  This is unessesary if data was loaded via alternate method.
  This script is supplied as a reference.
*******************************************************************************/

SELECT *
  FROM stvsbgi
 WHERE stvsbgi_desc LIKE '%CACHE%';

--return was 450168

INSERT INTO sorxref (SORXREF_XLBL_CODE,
                     SORXREF_EDI_VALUE,
                     SORXREF_EDI_STANDARD_IND,
                     SORXREF_DISP_WEB_IND,
                     SORXREF_ACTIVITY_DATE,
                     SORXREF_EDI_QLFR,
                     SORXREF_DESC,
                     SORXREF_BANNER_VALUE,
                     SORXREF_PESC_XML_IND)
     VALUES ('STVSBGI',
             '04-710',                         --lea and school code from USHE
             'Y',
             'N',
             TRUNC (SYSDATE),
             NULL,
             'CACHE HIGH',
             '450168', --Banner SBGI code from STVSBGI, USU happens to match ACT code
             'N');

/*******************************************************************************
  TESTING SCRIPT - Script to spot check the crosswalk for specific entries.
*******************************************************************************/

DECLARE
    param_lea_code      VARCHAR2 (2) := '4';
    param_school_code   VARCHAR2 (3) := '710';

    lv_sbgi             VARCHAR2 (6) := NULL;
BEGIN
    SELECT sorxref_banner_value
      INTO lv_sbgi
      FROM sorxref
     WHERE     sorxref_xlbl_code = 'STVSBGI'
           AND sorxref_edi_standard_ind = 'Y'
           AND sorxref_edi_value =
                   LPAD (param_lea_code, 2, '0') || '-' || param_school_code;

    DBMS_OUTPUT.put_line (lv_sbgi);
EXCEPTION
    WHEN NO_DATA_FOUND
    THEN
        RAISE;
END;
