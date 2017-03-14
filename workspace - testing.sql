/* Formatted on 3/13/2017 1:32:00 PM (QP5 v5.300) */
  SELECT *
    FROM dba_directories
ORDER BY directory_name;

SELECT * FROM Z_USHE_CSV_EXT;

ALTER TABLE Z_USHE_CSV_EXT location (USHE_ETL:'sn_ushe_data.csv');

BEGIN
    z_ushe_concurrent_interface.p_process_records ();
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
  FROM sarrqst
 WHERE sarrqst_data_origin = 'RAZIEL';

SELECT SYSDATE - 1
  FROM DUAL;

BEGIN                                                         --remove process
    DELETE FROM saraddr
          WHERE     saraddr_data_origin = 'RAZIEL'
                AND saraddr_activity_date >= SYSDATE - 1
                AND saraddr_aidm > 507673;

    DELETE FROM sarphon
          WHERE     sarphon_data_origin = 'RAZIEL'
                AND sarphon_activity_date >= SYSDATE - 1
                AND sarphon_aidm > 507673;

    DELETE FROM sarprfn
          WHERE     sarprfn_data_origin = 'RAZIEL'
                AND sarprfn_activity_date >= SYSDATE - 1
                AND sarprfn_aidm > 507673;

    DELETE FROM saretry
          WHERE     saretry_data_origin = 'RAZIEL'
                AND saretry_activity_date >= SYSDATE - 1
                AND saretry_aidm > 507673;

    DELETE FROM sarefos
          WHERE     sarefos_data_origin = 'RAZIEL'
                AND sarefos_activity_date >= SYSDATE - 1
                AND saraddr_aidm > 507673;

    DELETE FROM sarrqst
          WHERE     sarrqst_data_origin = 'RAZIEL'
                AND sarrqst_activity_date >= SYSDATE - 1
                AND sarrqst_aidm > 507673;

    DELETE FROM sarpers
          WHERE     sarpers_data_origin = 'RAZIEL'
                AND sarpers_activity_date >= SYSDATE - 1
                AND sarpers_aidm > 507673;

    DELETE FROM sarhead
          WHERE     sarhead_data_origin = 'RAZIEL'
                AND sarhead_activity_date >= SYSDATE - 1
                AND sarhead_aidm > 507673;

    DELETE FROM sabnstu
          WHERE     sabnstu_data_origin = 'RAZIEL'
                AND sabnstu_activity_date >= SYSDATE - 1
                AND sabnstu_aidm > 507673;
END;