#!/usr/bin/env bash
mkdir -p dlt/staging/chinook-initdb/
curl -L \
  https://raw.githubusercontent.com/lerocha/chinook-database/master/ChinookDatabase/DataSources/Chinook_PostgreSql.sql \
  -o dlt/staging/chinook-initdb/chinook.sql

# download dataset
# startup docker 