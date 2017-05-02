# z_ushe_concurrent_interface
Custom Banner package designed for Utah state colleges to consume USHE concurrent enrollment applicant information. The complete solution can be downloaded using the 'clone or download' button. Viewing individual files, the 'raw' button can be used to show plain text for copying directly from the browser.

Setup Instructions:

1 - Begin with "setup - directory creation and grants.sql".
    This creates the oracle directory (you may need to update the path) and grants permissions 

2 - Then use "setup - external table creation.sql".
    This create the external table definition for use by the custom package 

3 - Compile the custom package from "Z_USHE_CONCURRENT_INTERFACE.pks" and "Z_USHE_CONCURRENT_INTERFACE.pkb" respectively.
    In the package body, immediately following the revision comments you will find a number of global variables.
    These need to be updated with values specific to your school:
    
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

4 - Then use the STVXLBL SETUP SCRIPT from the "setup - high school crosswalk prep.sql" to create a crosswalk label.
    (This file contains additional sripts to check the crosswalk tables for existing values, and examples of scripts you can use to populate SORXREF via inserts if desired.)

5 - Populate the SORXREF_BANNER_VALUE field of "BannerSBGI.csv" with the Banner SGBI values specific to your university.
    "BannerSBGI-USUexample.csv" is provided as a completed example. SBGI values are found through STVSBGI.
    Use Toad, SQL Loader, or the the  Banner MDUU, to load the completed high school SBGI code crosswalk to SORXREF.

6 - Verify successful load through the Banner Admin interface on SOAXREF. Check the Cross-Reference Label STVSBGI for the recently loaded values. Update the Cross-Reference Label STVCITZ as needed to match your Banner citizenship codes with the USHE values described at https://usu.app.box.com/s/2l1ebuc69vk183w01dtngctue9k3ybq1.

7 - Update the "ushe_data.sh" shell script with the username/password and path specific to your institution.
    Use this file to retrieve records from the USHE Concurrent Enrollment Participation system.
    A data sharing agreement will need to be compelted with USHE for them to provide credentials and create firewall exceptions.

8 - Complete setup of the Banner SARETMT (Electronic Application Verify/Load Process) in accordance with Ellucain documentation.
    We found the "Banner Student Self-Service Admissions Training Workbook Release 8.1 - October 2008) to be most helpful.
    While dated and variance exists between INB and Banner Pages, the step-by-step guide may be more useful than extensive user manuals.

Operational Overview:

1 - The shell script retrieves records from the USHE system

2 - The process Z_USHE_CONCURRENT_INTERFACE.p_process_records stages those records in the Banner SAR**** tables

3 - The Baseline Banner process SARETMT pushes records from the SAR**** tables to Banner Student Admissions
