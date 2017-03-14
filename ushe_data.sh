#!/bin/bash

curl --basic -u username:password "https://usudev.service-now.com/x_utsu_ushe_ce_get_data.do?days=30" -o /u01/jobsub/data/ushe_etl/sn_ushe_data.csv
