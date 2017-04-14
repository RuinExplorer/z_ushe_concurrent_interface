/* Formatted on 4/14/2017 4:41:03 PM (QP5 v5.300) */
CREATE OR REPLACE PACKAGE BODY Z_CARL_ELLSWORTH.z_ushe_concurrent_interface
AS
    /******************************************************************************
     REVISIONS:
     Date      Author                     Description
     --------  ------------------------   ---------------------------------------
     20170228  Carl Ellsworth, USU        added f_reserve_aidm,
                                          added procedures for SABNSTU, SARHEAD
     20170302  Carl Ellsworth, USU        added procedures for SARPERS,
                                          added global variables and explainations
     20170303  Carl Ellsworth, USU        added procedures for SARADDR, SARPHON
     20170306  Carl Ellsworth, USU        added procedures for SARPRFN, SARETRY, SAREFOS
     20170307  Carl Ellsworth, USU        added p_insert_residency
                                          built external table z_ushe_csv_ext
                                          added p_process_records
                                          added translation functions for bool,
                                            birth, gender, ethnicity, state, and residency
     20170308  Carl Ellsworth, USU        specification change, removed use of
                                            f_translate_bool
                                            f_translate_citizenship
                                          update to f_get_term
     20170405  Carl Ellsworth, USU        added field act_test_date
     20170412  Carl Ellsworth, USU        added procedure for SARTEST
     20170413  Carl Ellsworth, USU        added procedures for SARHSCH, SARHSUM
                                            added f_translate_school_code
                                            changed f_translate_birth to f_translate_date
     20170414  Carl Ellsworth, USU        added application_number and success indicator
                                            to p_insert_SABNSTU to prevent duplicates

    References:
     -Admissions Application Set-Up Procedures for Banner Self-Service section of
        Banner Student User Guide / 8.12 / 9.3.3
     -Banner Table SARERUL which contains a multitude of key value pairs needed for setup

    ******************************************************************************/

    --GLOBAL VARIABLES
    gv_process_date                 DATE := SYSDATE;

    --global variables, requires update from school
    gv_folder_name         CONSTANT VARCHAR2 (30) := 'USHE_ETL'; --oracle directory for USHE file
    gv_wapp_code           CONSTANT VARCHAR2 (2) := 'CE'; --STVWAPP, Banner default is 'W7'
    gv_apls_code           CONSTANT VARCHAR2 (4) := 'WEB'; --STVAPLS, Banner default is 'WEB'
    gv_curr_rule           CONSTANT NUMBER (8) := 1685; --curriculum rule for CE
    gv_lfos_rule           CONSTANT NUMBER (8) := 2468; --field of study rule for CE
    gv_data_origin         CONSTANT VARCHAR2 (30) := 'RAZIEL'; --label for data origin field
    gv_lcql_code           CONSTANT VARCHAR2 (2) := 'MA';            --STVADDR
    gv_pqlf_code_phone     CONSTANT VARCHAR2 (2) := 'MA';            --STVTELE
    gv_pqlf_code_email     CONSTANT VARCHAR2 (2) := 'EM'; --SAAERUL, PQRF-EMAILPDRFCODE
    gv_parent1_rtln_code   CONSTANT VARCHAR2 (2) := 'M';             --STVRELT
    gv_parent2_rtln_code   CONSTANT VARCHAR2 (2) := 'F';             --STVRELT
    gv_xlbl_sbgi           CONSTANT VARCHAR2 (8) := 'STVSBGI'; --SORXREF label for SBGI entries

    --global variables specific to ACT test score loading, requires update from school
    gv_act_writing         CONSTANT VARCHAR2 (6) := 'A07'; --STVTESC, act_writing
    gv_act_science         CONSTANT VARCHAR2 (6) := 'A04'; --STVTESC, act_science
    gv_act_stem            CONSTANT VARCHAR2 (6) := 'A14'; --STVTESC, act_stem
    gv_act_reading         CONSTANT VARCHAR2 (6) := 'A03'; --STVTESC, act_reading
    gv_act_math            CONSTANT VARCHAR2 (6) := 'A02'; --STVTESC, act_math
    gv_act_english         CONSTANT VARCHAR2 (6) := 'A01'; --STVTESC, act_english
    gv_act_ela             CONSTANT VARCHAR2 (6) := 'A13';  --STVTESC, act_ela
    gv_act_composite       CONSTANT VARCHAR2 (6) := 'A05'; --STVTESC, act_composite

    ----------------------------------------------------------------------------

    /**
    * reserves a new person reference number (aidm) from the SABASEQ Banner sequence.
    *
    * @return                  newly reserved aidm
    */
    FUNCTION f_reserve_aidm
        RETURN NUMBER
    AS
        lv_aidm   NUMBER (8) := NULL;
    BEGIN
        SELECT SABASEQ.NEXTVAL INTO lv_aidm FROM DUAL;

        RETURN lv_aidm;
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.put_line (
                'EXCEPTION - unhandled exception in function f_reserve_aidm');
            RAISE;
    END f_reserve_aidm;

    /**
    * gets the current Banner term code.
    *
    * @param    param_date   optional, target date
    * @return                Banner term code
    */
    FUNCTION f_get_term (param_term VARCHAR2 DEFAULT NULL)
        RETURN VARCHAR2
    AS
        lv_term   VARCHAR2 (6) := NULL;
    BEGIN
        /* --original calculateion may still be of use to other universities
            SELECT MAX (stvterm_code)
              INTO lv_term
              FROM stvterm
             WHERE stvterm_start_date < SYSDATE;
        */

        --check for validation entry
        SELECT MAX (stvterm_code)
          INTO lv_term
          FROM stvterm
         WHERE stvterm_desc = param_term;

        --Date-based backup in case term from USHE is invalid
        IF lv_term IS NULL
        THEN
            SELECT MAX (stvterm_code)
              INTO lv_term
              FROM stvterm
             WHERE stvterm_start_date < SYSDATE;
        END IF;

        RETURN lv_term;
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.put_line (
                'EXCEPTION - unhandled exception in function f_get_term');
            RAISE;
    END f_get_term;

    /**
    * translates the mixed USHE system booleans to Banner booleans.
    *
    * 20170308 - made obsolete by spec change. now all yes/no and true/false
    *            are binary 1 or 0
    *
    * @param    param_boolean   Yes/No or TRUE/FALSE field
    * @return                   'Y' or 'N'
    */
    FUNCTION f_translate_bool (param_boolean VARCHAR2)
        RETURN VARCHAR2
    AS
        lv_bool   VARCHAR2 (1) := NULL;
    BEGIN
        CASE UPPER (param_boolean)
            WHEN '1'
            THEN
                lv_bool := 'Y';
            WHEN 'TRUE'
            THEN
                lv_bool := 'Y';
            WHEN 'YES'
            THEN
                lv_bool := 'Y';
            WHEN 'Y'
            THEN
                lv_bool := 'Y';
            WHEN '0'
            THEN
                lv_bool := 'N';
            WHEN 'FALSE'
            THEN
                lv_bool := 'N';
            WHEN 'NO'
            THEN
                lv_bool := 'N';
            WHEN 'N'
            THEN
                lv_bool := 'N';
            ELSE
                lv_bool := NULL;
        END CASE;

        RETURN lv_bool;
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.put_line (
                'EXCEPTION - unhandled exception in function f_translate_bool');
            RAISE;
    END f_translate_bool;

    /**
    * translates USHE split date fields to single date string.
    *
    * 20170308 - made potentially obsolete by spec change.
    *
    * @param    param_month     USHE date month spelled out
    * @param    param_day       USHE date day
    * @param    param_year      USHE date year
    * @return                   date string MDC format
    */
    FUNCTION f_translate_date (param_month    VARCHAR2,
                               param_day      VARCHAR2 DEFAULT '01',
                               param_year     VARCHAR2)
        RETURN VARCHAR2
    AS
        lv_date   VARCHAR2 (16);
    BEGIN
        lv_date := param_month || '/' || param_day || '/' || param_year;

        RETURN lv_date;
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.put_line (
                'EXCEPTION - unhandled exception in function f_translate_date');
            RAISE;
    END f_translate_date;

    /**
    * translaters USHE gender to Banner gender.
    *
    * @param    param_gender    USHE gender value
    * @return                   Banner gender value
    */
    FUNCTION f_translate_gender (param_gender VARCHAR2)
        RETURN VARCHAR2
    AS
        lv_gender_code   VARCHAR2 (1);
    BEGIN
        CASE UPPER (param_gender)
            WHEN 'MALE'
            THEN
                lv_gender_code := 'M';
            WHEN 'M'
            THEN
                lv_gender_code := 'M';
            WHEN 'FEMALE'
            THEN
                lv_gender_code := 'F';
            WHEN 'F'
            THEN
                lv_gender_code := 'F';
            ELSE
                lv_gender_code := NULL;
        END CASE;

        RETURN lv_gender_code;
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.put_line (
                'EXCEPTION - unhandled exception in function f_translate_gender');
            RAISE;
    END f_translate_gender;

    /**
    * translation of citizenship utilizes SOAXREF on the STVCITZ table. problem is,
    * the field is only 2 characters while the USHE system uses full strings. translantion
    * is still required.
    *
    * 20170308 - made obsolete by spec change. now CAN simply use SOAXREF on STVCITZ
    *
    * @param    param_ethn      USHE citizenship value
    * @return                   translation code
    */
    FUNCTION f_translate_citizenship (param_citz VARCHAR2)
        RETURN VARCHAR2
    AS
        lv_citz   VARCHAR2 (1);
    BEGIN
        CASE (param_citz)
            WHEN 'U.S. Citizen'
            THEN
                lv_citz := 1;      --this is the baseline banner citizen value
            ELSE
                --list of values from the USHE system was not yet available
                lv_citz := NULL; --TODO: translation needs to be built out to accept other status
        END CASE;

        RETURN lv_citz;
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.put_line (
                'EXCEPTION - unhandled exception in function f_translate_citizenship');
            RAISE;
    END f_translate_citizenship;

    /**
    * translation of ethnicity is not automatic in Banner. this function compensates.
    *
    * 20170308 - made potentially obsolete by spec change.
    *
    * @param    param_ethn      USHE ethnicity value
    * @return                   Banner ethn_code
    */
    FUNCTION f_translate_ethnicity (param_ethn VARCHAR2)
        RETURN VARCHAR2
    AS
        lv_ethn_code   VARCHAR2 (1);
    BEGIN
        CASE UPPER (param_ethn)
            WHEN 'HISPANIC'
            THEN
                lv_ethn_code := 2;               --banner hispanic/latino code
            WHEN 'HISPANIC/LATINO'
            THEN
                lv_ethn_code := 2;               --banner hispanic/latino code
            WHEN '2'
            THEN
                lv_ethn_code := 2;               --banner hispanic/latino code
            WHEN '1'
            THEN
                lv_ethn_code := 1;            --banner non-hispanic/latio code
            ELSE
                lv_ethn_code := NULL;
        END CASE;

        RETURN lv_ethn_code;
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.put_line (
                'EXCEPTION - unhandled exception in function f_translate_ethnicity');
            RAISE;
    END f_translate_ethnicity;

    /**
    * translation of state to Banner State Code. USHE system opted for full spelling
    * of state names in the address. this looks up the Banner state code.
    *
    * @param    param_state     USHE state value
    * @return                   Banner state code
    */
    FUNCTION f_translate_state (param_state VARCHAR2)
        RETURN VARCHAR2
    AS
        lv_state_code   VARCHAR2 (3);
    BEGIN
        SELECT stvstat_code
          INTO lv_state_code
          FROM stvstat
         WHERE TRIM (stvstat_desc) = TRIM (param_state);

        RETURN lv_state_code;
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            DBMS_OUTPUT.put_line (
                'EXCEPTION - application contains a state with no Banner Eqivalent.');
            RETURN NULL;
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.put_line (
                'EXCEPTION - unhandled exception in function f_translate_state');
            RAISE;
    END f_translate_state;


    /**
    * translation of residency to Banner boolean value.
    *
    * @param    param_residency     USHE residency value
    * @return                       Banner residency boolean
    */
    FUNCTION f_translate_residency (param_residency VARCHAR2)
        RETURN VARCHAR2
    AS
        lv_residency   VARCHAR2 (1);
    BEGIN
        CASE UPPER (param_residency)
            WHEN 'R'
            THEN
                lv_residency := 'Y';
            WHEN '1'
            THEN
                lv_residency := 'Y';
            WHEN 'NR'
            THEN
                lv_residency := 'N';
            WHEN '0'
            THEN
                lv_residency := 'N';
            ELSE
                lv_residency := 'N';
        END CASE;

        RETURN lv_residency;
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.put_line (
                'EXCEPTION - unhandled exception in function f_translate_residency');
            RAISE;
    END f_translate_residency;

    /**
    * translation of lea/school code to Banner SBGI value.
    * requires population of SORXREF (SOAXREF) for transation to work.
    * utilizes sorxref_edi_standard_ind as active indicator, must be 'Y' to resolve.
    *
    * @param    param_lea_code      USHE lea code
    * @param    param_school_code   USHE school code
    * @return                       Banner SBGI code
    */
    FUNCTION f_translate_school_code (param_lea_code       VARCHAR2,
                                      param_school_code    VARCHAR2)
        RETURN VARCHAR2
    AS
        lv_sbgi   VARCHAR2 (6) := NULL;
    BEGIN
        SELECT sorxref_banner_value
          INTO lv_sbgi
          FROM sorxref
         WHERE     sorxref_xlbl_code = 'STVSBGI'
               AND sorxref_edi_standard_ind = 'Y'
               AND sorxref_edi_value =
                          LPAD (param_lea_code, 2, '0')
                       || '-'
                       || param_school_code;

        RETURN lv_sbgi;
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            RETURN NULL;
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.put_line (
                'EXCEPTION - unhandled exception in function f_translate_school_code');
            RAISE;
    END f_translate_school_code;

    /**
    * creates a base record in Banner electronic admissions.
    *
    * @param    param_aidm     newly reserved aidm on which to build the record
    * @param    param_id       truncated USHE application_number
    * @param    param_success  out parameter to indicate if insert was successful
    */
    PROCEDURE p_insert_sabnstu (param_aidm          NUMBER,
                                param_id            VARCHAR2,
                                param_success   OUT VARCHAR2)
    AS
    BEGIN
        IF param_aidm IS NOT NULL
        THEN
            INSERT INTO SABNSTU (SABNSTU_ID,
                                 SABNSTU_AIDM,
                                 SABNSTU_LOCKED_IND,
                                 SABNSTU_ACTIVITY_DATE,
                                 SABNSTU_DATA_ORIGIN)
                 VALUES (param_id,     --set the web user id equal to CEAPP_ID
                         param_aidm,                            --set the aidm
                         'Y',                           --lock the web account
                         gv_process_date,
                         gv_data_origin);

            param_success := 'Y';
        END IF;
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX
        THEN
            param_success := 'N';
            DBMS_OUTPUT.put_line (
                   'EXCEPTION - record CEAPP'
                || param_id
                || ' has already been processed - skipping.');
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.put_line (
                'EXCEPTION - unhandled exception in procedure p_insert_sabnstu');
            RAISE;
    END p_insert_sabnstu;

    /**
    * creates a new application in the header table.
    *
    * @param    param_aidm        newly reserved aidm on which to build the record
    * @param    param_term_code   Banner term code in which to admit
    */
    PROCEDURE p_insert_sarhead (param_aidm NUMBER, param_term_code VARCHAR2)
    AS
    BEGIN
        IF param_aidm IS NOT NULL
        THEN
            INSERT INTO SARHEAD (SARHEAD_AIDM,
                                 SARHEAD_APPL_SEQNO,
                                 SARHEAD_APPL_COMP_IND,
                                 SARHEAD_ADD_DATE,
                                 SARHEAD_APPL_STATUS_IND,
                                 SARHEAD_PERS_STATUS_IND,
                                 SARHEAD_PROCESS_IND,
                                 SARHEAD_APPL_ACCEPT_IND,
                                 SARHEAD_ACTIVITY_DATE,
                                 SARHEAD_TERM_CODE_ENTRY,
                                 SARHEAD_WAPP_CODE,
                                 SARHEAD_APLS_CODE,
                                 SARHEAD_COMPLETE_DATE,
                                 SARHEAD_DATA_ORIGIN)
                 VALUES (param_aidm,
                         1,      --always a new aidm, always first application
                         'Y', --we load the app from UHSE in a completed state
                         gv_process_date,
                         'N',                       --application verification
                         'N',                            --person verification
                         'N',                               --process complete
                         'U',                                       --accepted
                         SYSDATE,
                         param_term_code,
                         gv_wapp_code,
                         gv_apls_code,
                         gv_process_date,
                         gv_data_origin);
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.put_line (
                'EXCEPTION - unhandled exception in procedure p_insert_sarhead');
            RAISE;
    END p_insert_sarhead;



    /**
    * creates a new person record in the person table. this is used once for the student
    * once for parent1, and once more for parent 2.
    *
    * @param    param_aidm          newly reserved aidm on which to build the record
    * @param    param_person_seqno  person sequence number,
                                      1 for student 2 for parent 1 and 3 for parent 2
    * @param    param_rltn_code     relationship code, NULL for student
    * @param    param_first_name    person's given name
    * @param    param_last_name     person's surname
    * @param    param_birth_string  string representation of birthdate, ie '08/25/1998'
    * @param    param_gender        'M' for male, 'F' for female
    * @param    param_citz_code     citizenship code, needs translation
    * @param    param_ethn_code     ethnicity code, needs translation
    */
    PROCEDURE p_insert_sarpers (param_aidm            NUMBER,
                                param_person_seqno    NUMBER,
                                param_rltn_code       VARCHAR2 DEFAULT NULL,
                                param_first_name      VARCHAR2,
                                param_last_name       VARCHAR2,
                                param_birth_string    VARCHAR2 DEFAULT NULL,
                                param_gender          VARCHAR2 DEFAULT NULL,
                                param_citz_code       VARCHAR2 DEFAULT NULL,
                                param_ethn_code       VARCHAR2 DEFAULT NULL)
    AS
    BEGIN
        IF param_aidm IS NOT NULL
        THEN
            INSERT INTO SARPERS (SARPERS_AIDM,
                                 SARPERS_APPL_SEQNO,
                                 SARPERS_SEQNO,
                                 SARPERS_LOAD_IND,
                                 SARPERS_ACTIVITY_DATE,
                                 SARPERS_RLTN_CDE,                   --STVRELT
                                 SARPERS_FIRST_NAME,
                                 SARPERS_LAST_NAME,
                                 SARPERS_DFMT_CDE_BIRTH,
                                 SARPERS_BIRTH_DTE,
                                 SARPERS_GENDER,
                                 SARPERS_CITZ_CDE,          --SOAXREF, STVCITZ
                                 SARPERS_ETHN_CATEGORY, --1 not hispanic, 2 hispanic
                                 SARPERS_DATA_ORIGIN)
                 VALUES (param_aidm,
                         1,                         --always first application
                         param_person_seqno,
                         'N',                                 --load indicator
                         gv_process_date,
                         param_rltn_code,
                         param_first_name,
                         param_last_name,
                         'MDC',  --date format string MDC is Month/Day/Century
                         param_birth_string,
                         param_gender,
                         param_citz_code,
                         param_ethn_code,
                         gv_data_origin);
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.put_line (
                'EXCEPTION - unhandled exception in procedure p_insert_sarpers');
            RAISE;
    END p_insert_sarpers;


    /**
    * creates a new record in the field of study table.
    *
    * @param    param_aidm           newly reserved aidm on which to build the record
    * @param    param_ssn            student SSN number
    */
    PROCEDURE p_insert_sarprfn (param_aidm NUMBER, param_ssn VARCHAR2)
    AS
    BEGIN
        IF param_aidm IS NOT NULL
        THEN
            INSERT INTO SARPRFN (SARPRFN_AIDM,
                                 SARPRFN_APPL_SEQNO,
                                 SARPRFN_PERS_SEQNO,
                                 SARPRFN_SEQNO,
                                 SARPRFN_ACTIVITY_DATE,
                                 SARPRFN_RFQL_CDE,
                                 SARPRFN_REF_NO,
                                 SARPRFN_DATA_ORIGIN)
                 VALUES (param_aidm,
                         1,                         --always first application
                         1,              --only loading SSN for student record
                         1,                             --only loading one SSN
                         gv_process_date,
                         'SY',             --unknown, all our entires are 'SY'
                         param_ssn,
                         gv_data_origin);
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.put_line (
                'EXCEPTION - unhandled exception in procedure p_insert_sarprfn');
            RAISE;
    END p_insert_sarprfn;


    /**
    * creates a new address record in the address table.
    *
    * @param    param_aidm          newly reserved aidm on which to build the record
    * @param    param_person_seqno  person sequence number, only loading 1 for student
    * @param    param_street_line1  address line 1
    * @param    param_street_line2  address line 2
    * @param    param_street_line3  address line 3, currently not supported by process
    * @param    param_city          address city
    * @param    param_state_code    address state code
    * @param    param_zip           address zip code
    * @param    param_natn_code     address nation code, null for USA
    */
    PROCEDURE p_insert_saraddr (param_aidm            NUMBER,
                                param_person_seqno    NUMBER DEFAULT 1,
                                param_street_line1    VARCHAR2,
                                param_street_line2    VARCHAR2,
                                param_street_line3    VARCHAR2 DEFAULT NULL,
                                param_city            VARCHAR2,
                                param_state_code      VARCHAR2,
                                param_zip             VARCHAR2,
                                param_natn_code       VARCHAR2 DEFAULT NULL)
    AS
    BEGIN
        IF param_aidm IS NOT NULL
        THEN
            INSERT INTO SARADDR (SARADDR_AIDM,
                                 SARADDR_APPL_SEQNO,
                                 SARADDR_PERS_SEQNO,
                                 SARADDR_SEQNO,
                                 SARADDR_LOAD_IND,
                                 SARADDR_ACTIVITY_DATE,
                                 SARADDR_STREET_LINE1,
                                 SARADDR_STREET_LINE2,
                                 SARADDR_STREET_LINE3,
                                 SARADDR_CITY,
                                 SARADDR_STAT_CDE,
                                 SARADDR_ZIP,
                                 SARADDR_NATN_CDE,
                                 SARADDR_LCQL_CDE,
                                 SARADDR_DATA_ORIGIN)
                 VALUES (param_aidm,
                         1,                         --always first application
                         param_person_seqno,
                         1,          --only loading a single address from USHE
                         'N',                                 --load indicator
                         gv_process_date,
                         param_street_line1,
                         param_street_line2,
                         param_street_line3,              --not currently used
                         param_city,
                         param_state_code,
                         param_zip,
                         param_natn_code,                 --not currently used
                         gv_lcql_code,
                         gv_data_origin);
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.put_line (
                'EXCEPTION - unhandled exception in procedure p_insert_saraddr');
            RAISE;
    END p_insert_saraddr;

    /**
    * creates new contact records in the phone table. this includes email.
    *
    * @param    param_aidm           newly reserved aidm on which to build the record
    * @param    param_person_seqno   person sequence number,
                                       1 for student 2 for parent 1 and 3 for parent 2
    * @param    param_phone_number   phone number
    * @param    param_email_address  email address
    */
    PROCEDURE p_insert_sarphon (param_aidm             NUMBER,
                                param_person_seqno     NUMBER,
                                param_phone_number     VARCHAR2,
                                param_email_address    VARCHAR2)
    AS
    BEGIN
        IF param_aidm IS NOT NULL
        THEN
            IF param_email_address IS NOT NULL
            THEN
                INSERT INTO sarphon (SARPHON_AIDM,
                                     SARPHON_APPL_SEQNO,
                                     SARPHON_PERS_SEQNO,
                                     SARPHON_SEQNO,
                                     SARPHON_LOAD_IND,
                                     SARPHON_ACTIVITY_DATE,
                                     SARPHON_PQLF_CDE,
                                     SARPHON_PHONE,
                                     SARPHON_DATA_ORIGIN)
                     VALUES (param_aidm,
                             1,                     --always first application
                             param_person_seqno,
                             1,                   --first record will be email
                             'N',                             --load indicator
                             gv_process_date,
                             gv_pqlf_code_email,
                             param_email_address,
                             gv_data_origin);
            END IF;

            IF param_phone_number IS NOT NULL
            THEN
                INSERT INTO sarphon (SARPHON_AIDM,
                                     SARPHON_APPL_SEQNO,
                                     SARPHON_PERS_SEQNO,
                                     SARPHON_SEQNO,
                                     SARPHON_LOAD_IND,
                                     SARPHON_ACTIVITY_DATE,
                                     SARPHON_PQLF_CDE,
                                     SARPHON_PHONE,
                                     SARPHON_DATA_ORIGIN)
                     VALUES (param_aidm,
                             1,                     --always first application
                             param_person_seqno,
                             2,                  --second record will be phone
                             'N',                             --load indicator
                             gv_process_date,
                             gv_pqlf_code_phone,
                             '*WEB*' || param_phone_number,
                             gv_data_origin);
            END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.put_line (
                'EXCEPTION - unhandled exception in procedure p_insert_sarphon');
            RAISE;
    END p_insert_sarphon;

    /**
    * creates a new record in the curriculum table.
    *
    * @param    param_aidm           newly reserved aidm on which to build the record
    */
    PROCEDURE p_insert_saretry (param_aidm NUMBER)
    AS
    BEGIN
        IF param_aidm IS NOT NULL
        THEN
            INSERT INTO SARETRY (SARETRY_AIDM,
                                 SARETRY_APPL_SEQNO,
                                 SARETRY_SEQNO,
                                 SARETRY_LOAD_IND,
                                 SARETRY_ACTIVITY_DATE,
                                 SARETRY_PRIORITY,
                                 SARETRY_CURR_RULE,
                                 SARETRY_DATA_ORIGIN)
                 VALUES (param_aidm,
                         1,                         --always first application
                         1,               --only loading one curriculum record
                         'N',                                 --load indicator
                         gv_process_date,
                         1,                           --single record priority
                         gv_curr_rule,
                         gv_data_origin);
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.put_line (
                'EXCEPTION - unhandled exception in procedure p_insert_saretry');
            RAISE;
    END p_insert_saretry;

    /**
    * creates a new record in the field of study table.
    *
    * @param    param_aidm           newly reserved aidm on which to build the record
    */
    PROCEDURE p_insert_sarefos (param_aidm NUMBER)
    AS
    BEGIN
        IF param_aidm IS NOT NULL
        THEN
            INSERT INTO SAREFOS (SAREFOS_AIDM,
                                 SAREFOS_APPL_SEQNO,
                                 SAREFOS_ETRY_SEQNO,
                                 SAREFOS_SEQNO,
                                 SAREFOS_LOAD_IND,
                                 SAREFOS_ACTIVITY_DATE,
                                 SAREFOS_FLVL_CDE,
                                 SAREFOS_LFOS_RULE,
                                 SAREFOS_DATA_ORIGIN)
                 VALUES (param_aidm,
                         1,                         --always first application
                         1,               --only loading one curriculum record
                         1,           --only loading one field of study record
                         'N',                                 --load indicator
                         gv_process_date,
                         'M',                             --'M' for major code
                         gv_lfos_rule,
                         gv_data_origin);
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.put_line (
                'EXCEPTION - unhandled exception in procedure p_insert_sarefos');
            RAISE;
    END p_insert_sarefos;

    /**
    * creates a new question record in the request for information table.
    * this can be used as a template for additional custom questions.
    *
    * @param    param_aidm            newly reserved aidm on which to build the record
    * @param    param_question_seqno  optional question sequence number
                                         one unless school wishes to expand questions
    * @param    param_residency_bool  residency boolean, Y for yes, N for no
    */
    PROCEDURE p_insert_residency (param_aidm              NUMBER,
                                  param_question_seqno    NUMBER DEFAULT 1,
                                  param_residency_bool    VARCHAR2)
    AS
    BEGIN
        IF param_aidm IS NOT NULL
        THEN
            INSERT INTO SARRQST (SARRQST_AIDM,
                                 SARRQST_APPL_SEQNO,
                                 SARRQST_SEQNO,
                                 SARRQST_LOAD_IND,
                                 SARRQST_ACTIVITY_DATE,
                                 SARRQST_QSTN_CDE,
                                 SARRQST_RESP_FLAG,
                                 SARRQST_DATA_ORIGIN)
                 VALUES (param_aidm,
                         1,                         --always first application
                         param_question_seqno,
                         'N',                                 --load indicator
                         gv_process_date,
                         'RS',      --banner delivered residency question code
                         param_residency_bool,
                         gv_data_origin);
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.put_line (
                'EXCEPTION - unhandled exception in procedure p_insert_residency');
            RAISE;
    END p_insert_residency;

    /**
    * creates a new record in the test score table.
    *
    * @param    param_aidm         newly reserved aidm on which to build the record
    * @param    param_seqno        test score sequence number
    * @param    param_test_date    string representation of test date, ie '08/25/1998'
    * @param    param_subt_code    Banner STVTESC code for test
    * @param    param_test_score   string test score
    */
    PROCEDURE p_insert_sartest (param_aidm          NUMBER,
                                param_seqno         NUMBER,
                                param_test_date     VARCHAR2,
                                param_subt_code     VARCHAR2,
                                param_test_score    VARCHAR2)
    AS
    BEGIN
        IF param_aidm IS NOT NULL
        THEN
            INSERT INTO SARTEST (SARTEST_AIDM,
                                 SARTEST_APPL_SEQNO,
                                 SARTEST_SEQNO,
                                 SARTEST_LOAD_IND,
                                 SARTEST_ACTIVITY_DATE,
                                 SARTEST_DFMT_CDE,
                                 SARTEST_TEST_DTE,
                                 SARTEST_SUBT_CDE,
                                 SARTEST_TEST_SCORE1,
                                 SARTEST_DATA_ORIGIN)
                 VALUES (param_aidm,
                         1,                         --always first application
                         param_seqno,
                         'N',                                 --load indicator
                         gv_process_date,
                         'MDC',  --date format string MDC is Month/Day/Century
                         param_test_date,
                         param_subt_code,
                         param_test_score,
                         gv_data_origin);
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.put_line (
                'EXCEPTION - unhandled exception in procedure p_insert_sartest');
            RAISE;
    END p_insert_sartest;

    /**
    * creates a new record in the academic status table.
    *
    * @param    param_aidm              newly reserved aidm on which to build the record
    * @param    param_sbgi_code         banner sbgi code for school, USHE cannot provide this.
    *                                      translation will be needed from LEA/School code to SBGI
    * @param    param_graduation_date   string representation of graduation date, ie '08/25/1998'
    * @param    param_school_name       high school name from USHE
    */
    PROCEDURE p_insert_sarhsch (param_aidm               NUMBER,
                                param_sbgi_code          VARCHAR2,
                                param_graduation_date    VARCHAR2,
                                param_school_name        VARCHAR2)
    AS
    BEGIN
        IF param_aidm IS NOT NULL
        THEN
            INSERT INTO SARHSCH (SARHSCH_AIDM,
                                 SARHSCH_APPL_SEQNO,
                                 SARHSCH_SEQNO,
                                 SARHSCH_LOAD_IND,
                                 SARHSCH_ACTIVITY_DATE,
                                 SARHSCH_IDQL_CDE1,
                                 SARHSCH_IDEN_CDE1,
                                 SARHSCH_DFMT_CDE_HSGR,
                                 SARHSCH_HSGR_DTE,
                                 SARHSCH_ENTY_CDE1,
                                 SARHSCH_NAME1,
                                 SARHSCH_DATA_ORIGIN)
                 VALUES (param_aidm,
                         1,                         --always first application
                         1,                   --only loading one school record
                         'N',                                 --load indicator
                         gv_process_date,
                         'WB',             --unknown, all our entires are 'WB'
                         param_sbgi_code,
                         'MDC',  --date format string MDC is Month/Day/Century
                         param_graduation_date,
                         'HS',                   --high school identifier code
                         param_school_name,
                         gv_data_origin);
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.put_line (
                'EXCEPTION - unhandled exception in procedure p_insert_sarhsch');
            RAISE;
    END p_insert_sarhsch;

    /**
    * creates a new record in the degree summary information table.
    *
    * @param    param_aidm         newly reserved aidm on which to build the record
    * @param    param_gpa          high school gpa
    * @param    param_class_rank   high school rank
    * @param    param_class_size   high school class size
    */
    PROCEDURE p_insert_sarhsum (param_aidm          NUMBER,
                                param_gpa           VARCHAR2,
                                param_class_rank    VARCHAR2 DEFAULT NULL,
                                param_class_size    VARCHAR2 DEFAULT NULL)
    AS
    BEGIN
        IF param_aidm IS NOT NULL
        THEN
            INSERT INTO SARHSUM (SARHSUM_AIDM,
                                 SARHSUM_APPL_SEQNO,
                                 SARHSUM_HSCH_SEQNO,
                                 SARHSUM_SEQNO,
                                 SARHSUM_LOAD_IND,
                                 SARHSUM_ACTIVITY_DATE,
                                 SARHSUM_CUMULATIVE_FLAG,
                                 SARHSUM_GPA,
                                 SARHSUM_CLASS_RANK,
                                 SARHSUM_CLASS_SIZE,
                                 SARHSUM_DATA_ORIGIN)
                 VALUES (param_aidm,
                         1,                         --always first application
                         1,                    --only loaded one school record
                         1,                  --only loading one summary record
                         'N',                                 --load indicator
                         gv_process_date,
                         'Y',                         --loading cumulative GPA
                         param_gpa,
                         param_class_rank,
                         param_class_size,
                         gv_data_origin);
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.put_line (
                'EXCEPTION - unhandled exception in procedure p_insert_sarhsum');
            RAISE;
    END p_insert_sarhsum;

    /**
    * parses the ushe data file and populate the SAR*** tables prepetory to Banner
    * SARETMT process to admit students.
    *
    */
    PROCEDURE p_process_records
    AS
        CURSOR c_student
        IS
            SELECT application_number,
                   term,
                   ssid,
                   ssn,
                   gender,
                   student_first,
                   student_middle,
                   student_last,
                   student_preferred,
                   address1,
                   address2,
                   city,
                   state_desc,
                   zip_code,
                   birth_year,
                   birth_month,
                   birth_day,
                   student_email,
                   student_phone,
                   student_text_bool,
                   ethnicity,
                   race,
                   citizenship,
                   residency,
                   alien_registration_numb,
                   visa_type,
                   country_of_origin,
                   anticipated_grad_year,
                   anticipated_grad_month,
                   high_school_desc,
                   high_school_code,
                   district_desc,
                   district_code,
                   gpa,
                   act_writing,
                   act_science,
                   act_stem,
                   act_reading,
                   act_math,
                   act_english,
                   act_ela,
                   act_composite,
                   act_test_date,
                   english_first_lang_bool,
                   claimed_dependent_bool,
                   student_receive_info_bool,
                   parent1_first,
                   parent1_last,
                   parent1_email,
                   parent1_phone,
                   parent1_text_bool,
                   parent1_receive_info_bool,
                   parent2_first,
                   parent2_last,
                   parent2_email,
                   parent2_phone,
                   parent2_text_bool,
                   parent2_receive_info_bool,
                   parent_grad_bool,
                   student_sig,
                   student_sig_date,
                   parent_sig,
                   parent_sig_date,
                   transcript_bool,
                   applied_freshman_bool
              FROM Z_USHE_CSV_EXT;

        lv_aidm           NUMBER (8);
        lv_success_flag   VARCHAR2 (1) := NULL;
        lv_count          NUMBER (4) := 0;
        lv_test_count     NUMBER (2) := 0;
    BEGIN
        FOR r_student IN c_student
        LOOP
            lv_success_flag := 'Y';

            --obtain an aidm
            lv_aidm := f_reserve_aidm ();

            --create a base record
            p_insert_sabnstu (
                param_aidm      => lv_aidm,
                param_id        => REPLACE (r_student.application_number,
                                            'CEAPP',
                                            ''),
                param_success   => lv_success_flag);

            --if header record creation failed, skip this loop iteration
            CONTINUE WHEN lv_success_flag = 'N';

            --create a header record
            p_insert_sarhead (
                param_aidm        => lv_aidm,
                param_term_code   => f_get_term (r_student.term));

            --PERSON Logic
            --first call for student
            p_insert_sarpers (
                param_aidm           => lv_aidm,
                param_person_seqno   => 1,
                param_first_name     => r_student.student_first,
                param_last_name      => r_student.student_last,
                param_birth_string   => f_translate_date (
                                           r_student.birth_month,
                                           r_student.birth_day,
                                           r_student.birth_year),
                param_gender         => f_translate_gender (r_student.gender),
                param_citz_code      => r_student.citizenship,
                param_ethn_code      => f_translate_ethnicity (
                                           r_student.residency));

            p_insert_sarphon (
                param_aidm            => lv_aidm,
                param_person_seqno    => 1,
                param_phone_number    => r_student.student_phone,
                param_email_address   => r_student.student_email);

            --second call for parent1
            IF (    r_student.parent1_first IS NOT NULL
                AND r_student.parent1_last IS NOT NULL)
            THEN
                p_insert_sarpers (
                    param_aidm           => lv_aidm,
                    param_person_seqno   => 2,
                    param_rltn_code      => gv_parent1_rtln_code,
                    param_first_name     => r_student.parent1_first,
                    param_last_name      => r_student.parent1_last);

                p_insert_sarphon (
                    param_aidm            => lv_aidm,
                    param_person_seqno    => 2,
                    param_phone_number    => r_student.parent1_phone,
                    param_email_address   => r_student.parent1_email);
            END IF;

            --third call for parent2
            IF (    r_student.parent2_first IS NOT NULL
                AND r_student.parent2_last IS NOT NULL)
            THEN
                p_insert_sarpers (
                    param_aidm           => lv_aidm,
                    param_person_seqno   => 3,
                    param_rltn_code      => gv_parent2_rtln_code,
                    param_first_name     => r_student.parent2_first,
                    param_last_name      => r_student.parent2_last);

                p_insert_sarphon (
                    param_aidm            => lv_aidm,
                    param_person_seqno    => 3,
                    param_phone_number    => r_student.parent2_phone,
                    param_email_address   => r_student.parent2_email);
            END IF;

            --add SSN if provided
            IF (r_student.ssn IS NOT NULL)
            THEN
                p_insert_sarprfn (param_aidm   => lv_aidm,
                                  param_ssn    => r_student.ssn);
            END IF;

            --create address record
            p_insert_saraddr (
                param_aidm           => lv_aidm,
                param_street_line1   => r_student.address1,
                param_street_line2   => r_student.address2,
                param_city           => r_student.city,
                param_state_code     => f_translate_state (
                                           r_student.state_desc),
                param_zip            => r_student.zip_code);

            --create the curriculum and field of student records
            p_insert_saretry (param_aidm => lv_aidm);
            p_insert_sarefos (param_aidm => lv_aidm);

            --create the residency record
            p_insert_residency (
                param_aidm             => lv_aidm,
                param_residency_bool   => f_translate_residency (
                                             r_student.residency));

            --create ACT test score entries
            BEGIN
                lv_test_count := 0;

                --act_writing
                IF r_student.act_writing IS NOT NULL
                THEN
                    lv_test_count := lv_test_count + 1;
                    p_insert_sartest (
                        param_aidm         => lv_aidm,
                        param_seqno        => lv_test_count,
                        param_test_date    => r_student.act_test_date,
                        param_subt_code    => gv_act_writing,
                        param_test_score   => r_student.act_writing);
                END IF;

                --act_science
                IF r_student.act_science IS NOT NULL
                THEN
                    lv_test_count := lv_test_count + 1;
                    p_insert_sartest (
                        param_aidm         => lv_aidm,
                        param_seqno        => lv_test_count,
                        param_test_date    => r_student.act_test_date,
                        param_subt_code    => gv_act_science,
                        param_test_score   => r_student.act_science);
                END IF;

                --act_stem
                IF r_student.act_stem IS NOT NULL
                THEN
                    lv_test_count := lv_test_count + 1;
                    p_insert_sartest (
                        param_aidm         => lv_aidm,
                        param_seqno        => lv_test_count,
                        param_test_date    => r_student.act_test_date,
                        param_subt_code    => gv_act_stem,
                        param_test_score   => r_student.act_stem);
                END IF;

                --act_reading
                IF r_student.act_reading IS NOT NULL
                THEN
                    lv_test_count := lv_test_count + 1;
                    p_insert_sartest (
                        param_aidm         => lv_aidm,
                        param_seqno        => lv_test_count,
                        param_test_date    => r_student.act_test_date,
                        param_subt_code    => gv_act_reading,
                        param_test_score   => r_student.act_reading);
                END IF;

                --act_math
                IF r_student.act_math IS NOT NULL
                THEN
                    lv_test_count := lv_test_count + 1;
                    p_insert_sartest (
                        param_aidm         => lv_aidm,
                        param_seqno        => lv_test_count,
                        param_test_date    => r_student.act_test_date,
                        param_subt_code    => gv_act_math,
                        param_test_score   => r_student.act_math);
                END IF;

                --act_english
                IF r_student.act_english IS NOT NULL
                THEN
                    lv_test_count := lv_test_count + 1;
                    p_insert_sartest (
                        param_aidm         => lv_aidm,
                        param_seqno        => lv_test_count,
                        param_test_date    => r_student.act_test_date,
                        param_subt_code    => gv_act_english,
                        param_test_score   => r_student.act_english);
                END IF;

                --act_ela
                IF r_student.act_ela IS NOT NULL
                THEN
                    lv_test_count := lv_test_count + 1;
                    p_insert_sartest (
                        param_aidm         => lv_aidm,
                        param_seqno        => lv_test_count,
                        param_test_date    => r_student.act_test_date,
                        param_subt_code    => gv_act_ela,
                        param_test_score   => r_student.act_ela);
                END IF;

                --act_composite
                IF r_student.act_composite IS NOT NULL
                THEN
                    lv_test_count := lv_test_count + 1;
                    p_insert_sartest (
                        param_aidm         => lv_aidm,
                        param_seqno        => lv_test_count,
                        param_test_date    => r_student.act_test_date,
                        param_subt_code    => gv_act_composite,
                        param_test_score   => r_student.act_composite);
                END IF;
            END;

            --create the high school record
            p_insert_sarhsch (
                param_aidm              => lv_aidm,
                param_sbgi_code         => f_translate_school_code (
                                              param_lea_code      => r_student.district_code,
                                              param_school_code   => r_student.high_school_code),
                param_graduation_date   => f_translate_date (
                                              param_month   => r_student.anticipated_grad_month,
                                              param_day     => NULL,
                                              param_year    => r_student.anticipated_grad_year),
                param_school_name       => r_student.high_school_desc);

            --create the high school info record
            IF (r_student.gpa IS NOT NULL)
            THEN
                p_insert_sarhsum (param_aidm   => lv_aidm,
                                  param_gpa    => r_student.gpa);
            END IF;

            --update count for process DBMS output
            lv_count := lv_count + 1;
        END LOOP;

        DBMS_OUTPUT.put_line (
            'COMPLETION - ' || lv_count || ' records have been processed.');
    EXCEPTION
        WHEN OTHERS
        THEN
            DBMS_OUTPUT.put_line (
                'EXCEPTION - unhandled exception in procedure p_process_records');
            RAISE;
    END p_process_records;
END z_ushe_concurrent_interface;
/