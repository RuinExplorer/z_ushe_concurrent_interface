/* Formatted on 3/7/2017 4:13:16 PM (QP5 v5.300) */
DROP TABLE Z_USHE_CSV_EXT;

CREATE TABLE Z_USHE_CSV_EXT
(
    application_number          VARCHAR2 (32),
    term                        VARCHAR2 (32),
    ssid                        VARCHAR2 (32),
    ssn                         VARCHAR2 (32),
    gender                      VARCHAR2 (32),
    student_first               VARCHAR2 (60),
    student_middle              VARCHAR2 (60),
    student_last                VARCHAR2 (60),
    student_preferred           VARCHAR2 (60),
    address1                    VARCHAR2 (60),
    address2                    VARCHAR2 (60),
    city                        VARCHAR2 (60),
    state_desc                  VARCHAR2 (60),
    zip_code                    VARCHAR2 (32),
    birth_year                  VARCHAR2 (32),
    birth_month                 VARCHAR2 (32),
    birth_day                   VARCHAR2 (32),
    student_email               VARCHAR2 (60),
    student_phone               VARCHAR2 (32),
    student_text_bool           VARCHAR2 (32),
    ethnicity                   VARCHAR2 (60),
    race                        VARCHAR2 (60),
    citizenship                 VARCHAR2 (60),
    residency                   VARCHAR2 (60),
    alien_registration_numb     VARCHAR2 (60),
    visa_type                   VARCHAR2 (60),
    country_of_origin           VARCHAR2 (60),
    anticipated_grad_year       VARCHAR2 (32),
    anticipated_grad_month      VARCHAR2 (32),
    high_school_desc            VARCHAR2 (60),
    high_school_code            VARCHAR2 (32),
    district_desc               VARCHAR2 (60),
    district_code               VARCHAR2 (32),
    gpa                         VARCHAR2 (32),
    act_writing                 VARCHAR2 (32),
    act_science                 VARCHAR2 (32),
    act_stem                    VARCHAR2 (32),
    act_reading                 VARCHAR2 (32),
    act_math                    VARCHAR2 (32),
    act_english                 VARCHAR2 (32),
    act_ela                     VARCHAR2 (32),
    act_composite               VARCHAR2 (32),
    act_test_date               VARCHAR2 (32),
    english_first_lang_bool     VARCHAR2 (32),
    claimed_dependent_bool      VARCHAR2 (32),
    student_receive_info_bool   VARCHAR2 (32),
    parent1_first               VARCHAR2 (60),
    parent1_last                VARCHAR2 (60),
    parent1_email               VARCHAR2 (60),
    parent1_phone               VARCHAR2 (32),
    parent1_text_bool           VARCHAR2 (32),
    parent1_receive_info_bool   VARCHAR2 (32),
    parent2_first               VARCHAR2 (60),
    parent2_last                VARCHAR2 (60),
    parent2_email               VARCHAR2 (60),
    parent2_phone               VARCHAR2 (32),
    parent2_text_bool           VARCHAR2 (32),
    parent2_receive_info_bool   VARCHAR2 (32),
    parent_grad_bool            VARCHAR2 (32),
    student_sig                 VARCHAR2 (124),
    student_sig_date            VARCHAR2 (32),
    parent_sig                  VARCHAR2 (124),
    parent_sig_date             VARCHAR2 (32),
    transcript_bool             VARCHAR2 (32),
    applied_freshman_bool       VARCHAR2 (32)
)
ORGANIZATION EXTERNAL
    (TYPE ORACLE_LOADER
          DEFAULT DIRECTORY USHE_ETL
              ACCESS PARAMETERS (
                  RECORDS DELIMITED BY NEWLINE
                  SKIP 1                             --skips the header record
                  FIELDS
                      TERMINATED BY ','
                      OPTIONALLY ENCLOSED BY '"'
                      LRTRIM
                  MISSING FIELD VALUES ARE NULL
              )
          LOCATION ('sn_ushe_data.csv'));