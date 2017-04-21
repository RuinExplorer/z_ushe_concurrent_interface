/* Formatted on 3/7/2017 3:41:22 PM (QP5 v5.300) */
CREATE OR REPLACE PACKAGE BANINST1.z_ushe_concurrent_interface
AS
    /******************************************************************************
       NAME:       z_ushe_concurrent_interface
       PURPOSE:    Interface between USHE online concurrent enrollment application
                   and local university Banner system.

    ******************************************************************************/
    PROCEDURE p_process_records;
END z_ushe_concurrent_interface;
/