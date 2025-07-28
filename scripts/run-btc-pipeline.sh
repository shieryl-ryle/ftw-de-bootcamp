#!/usr/bin/env bash
# ~/scripts/run-btc-pipeline.sh

set -e
cd /projects/ftw-de-bootcamp
/usr/bin/docker compose -p myk --profile jobs run --rm \
  --user $(id -u):$(id -g) \
  dlt \
  python pipelines/dlt-btc-pipeline.py \
  >> /projects/ftw-de-bootcamp/logs/dlt-btc-pipeline.log 2>&1

# make sure to apply chmod +x run-btc-pipeline.sh
# do sample run first ftw-de-bootcamp$ scripts/run-btc-pipeline.sh
# schedule cronjob to run this script every 1 minutes
# crontab -e
# * * * * *  /projects/ftw-de-bootcamp/scripts/run-btc-pipeline.sh
