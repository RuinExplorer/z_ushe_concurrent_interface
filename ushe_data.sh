#!/bin/bash
#DOCUMENTATION: https://usu.app.box.com/notes/142846323111?s=qxb5ntj6ncmqdm9xsj0aj3ffpoyrzn7n
# through curl the output file can be changed to a static filename for ease of automation
# 'sn_ushe_data.csv' is assumed for the external table spec

#METHOD 1 (days parameter)
#curl --basic -u username:password "https://ushecedev.service-now.com/x_utsu_ushe_ce_get_data.do?days=30" -o /u01/jobsub/data/ushe_etl/sn_ushe_data.csv

#METHOD 2 (start_date & end_date parameters)
from_date=$(date --date="yesterday" +%Y-%m-%dT00:00:00)
to_date=$(date --date="yesterday" +%Y-%m-%dT23:59:59)
curl --basic -u username:password "https://ushecedev.service-now.com/x_utsu_ushe_ce_get_data?start_date=$from_date&end_date=$to_date" -o /u01/jobsub/data/ushe_etl/sn_ushe_data.csv
