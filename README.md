# z_ushe_concurrent_interface
Custom Banner package designed for Utah state colleges to consume USHE concurrent enrollment applicant information.

To Install:

 1 - begin with "setup - directory creation and grants.sql"
     This creates the oracle directory and grants permissions
 2 - then use "setup - external table creation.sql"
     This create the external table definition for use by the custom package
 3 - compile the custom package from "Z_USHE_CONCURRENT_INTERFACE.pks" and "Z_USHE_CONCURRENT_INTERFACE.pkb" respectively
     Update the global variables with values specific to your school
 4 - use Toad, SQL Loader, or the the Banner MDUU, to load the high school SBGI code crosswalk to SORXREF
     "BannerSBGI.csv" is a blank list for you to populate, "BannerSBGI-USUexample.csv" is provided as an example
 5 - Update the "ushe_data.sh" shell script with the username/password and path specific to you institution
     Use this file to retrieve records from the USHE Concurrent Enrollment Participation system
     