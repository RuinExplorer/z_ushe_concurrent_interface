/* Formatted on 5/5/2017 3:01:29 PM (QP5 v5.300) */
  SELECT *
    FROM dba_directories
ORDER BY directory_name;

SELECT * FROM Z_USHE_CSV_EXT;

BEGIN
    baninst1.z_ushe_concurrent_interface.p_process_records ();
END;

SELECT *
  FROM sabnstu
 WHERE sabnstu_data_origin = 'RAZIEL';

SELECT *
  FROM sarhead
 WHERE sarhead_data_origin = 'RAZIEL';

SELECT *
  FROM sarpers
 WHERE sarpers_data_origin = 'RAZIEL';

SELECT *
  FROM saraddr
 WHERE saraddr_data_origin = 'RAZIEL';

SELECT *
  FROM sarphon
 WHERE sarphon_data_origin = 'RAZIEL';

SELECT *
  FROM sarprfn
 WHERE sarprfn_data_origin = 'RAZIEL';

SELECT *
  FROM saretry
 WHERE saretry_data_origin = 'RAZIEL';

SELECT *
  FROM sarefos
 WHERE sarefos_data_origin = 'RAZIEL';

SELECT *
  FROM sarprac
 WHERE sarprac_data_origin = 'RAZIEL';

SELECT *
  FROM sarrqst
 WHERE sarrqst_data_origin = 'RAZIEL';

SELECT *
  FROM sartest
 WHERE sartest_data_origin = 'RAZIEL';

SELECT *
  FROM sarhsch
 WHERE sarhsch_data_origin = 'RAZIEL';

SELECT *
  FROM sarhsum
 WHERE sarhsum_data_origin = 'RAZIEL';


SELECT SYSDATE - 1
  FROM DUAL;

DECLARE
    v_frozen_aidm   NUMBER (8) := 507725;
BEGIN                                                         --remove process
    DELETE FROM sarhsum
          WHERE     sarhsum_data_origin = 'RAZIEL'
                AND sarhsum_activity_date >= SYSDATE - 1
                AND sarhsum_aidm > v_frozen_aidm;

    DELETE FROM sarhsch
          WHERE     sarhsch_data_origin = 'RAZIEL'
                AND sarhsch_activity_date >= SYSDATE - 1
                AND sarhsch_aidm > v_frozen_aidm;

    DELETE FROM sartest
          WHERE     sartest_data_origin = 'RAZIEL'
                AND sartest_activity_date >= SYSDATE - 1
                AND sartest_aidm > v_frozen_aidm;

    DELETE FROM saraddr
          WHERE     saraddr_data_origin = 'RAZIEL'
                AND saraddr_activity_date >= SYSDATE - 1
                AND saraddr_aidm > v_frozen_aidm;

    DELETE FROM sarphon
          WHERE     sarphon_data_origin = 'RAZIEL'
                AND sarphon_activity_date >= SYSDATE - 1
                AND sarphon_aidm > v_frozen_aidm;

    DELETE FROM sarprfn
          WHERE     sarprfn_data_origin = 'RAZIEL'
                AND sarprfn_activity_date >= SYSDATE - 1
                AND sarprfn_aidm > v_frozen_aidm;

    DELETE FROM saretry
          WHERE     saretry_data_origin = 'RAZIEL'
                AND saretry_activity_date >= SYSDATE - 1
                AND saretry_aidm > v_frozen_aidm;

    DELETE FROM sarefos
          WHERE     sarefos_data_origin = 'RAZIEL'
                AND sarefos_activity_date >= SYSDATE - 1
                AND sarefos_aidm > v_frozen_aidm;

    DELETE FROM sarprac
          WHERE     sarprac_data_origin = 'RAZIEL'
                AND sarprac_activity_date >= SYSDATE - 1
                AND sarprac_aidm > v_frozen_aidm;

    DELETE FROM sarrqst
          WHERE     sarrqst_data_origin = 'RAZIEL'
                AND sarrqst_activity_date >= SYSDATE - 1
                AND sarrqst_aidm > v_frozen_aidm;

    DELETE FROM sarpers
          WHERE     sarpers_data_origin = 'RAZIEL'
                AND sarpers_activity_date >= SYSDATE - 1
                AND sarpers_aidm > v_frozen_aidm;

    DELETE FROM sarhead
          WHERE     sarhead_data_origin = 'RAZIEL'
                AND sarhead_activity_date >= SYSDATE - 1
                AND sarhead_aidm > v_frozen_aidm;

    DELETE FROM sabnstu
          WHERE     sabnstu_data_origin = 'RAZIEL'
                AND sabnstu_activity_date >= SYSDATE - 1
                AND sabnstu_aidm > v_frozen_aidm;
END;