# Terminal Session Log

## Cloning the repository
```bash
test@ip-172-31-240-50:~$ git clone https://github.com/ogbinar/ftw-de-bootcamp.git
Cloning into 'ftw-de-bootcamp'...
remote: Enumerating objects: 157, done.
remote: Counting objects: 100% (157/157), done.
remote: Compressing objects: 100% (95/95), done.
remote: Total 157 (delta 58), reused 135 (delta 36), pack-reused 0 (from 0)
Receiving objects: 100% (157/157), 229.59 KiB | 16.40 MiB/s, done.
Resolving deltas: 100% (58/58), done.
```

## Navigating to the project directory
```bash
test@ip-172-31-240-50:~$ cd ftw-de-bootcamp
test@ip-172-31-240-50:~/ftw-de-bootcamp$ ls
README.md  clickhouse  compose.yaml  dbt  dlt
```

## Building Docker containers
```bash
test@ip-172-31-240-50:~/ftw-de-bootcamp$ docker compose -p myk build dlt dbt
[+] Building 58.1s (19/19) FINISHED
[... build output truncated for brevity ...]
[+] Building 2/2
 ✔ dlt  Built                                                                                                                                                                                                               0.0s 
 ✔ dbt  Built                                                                                                                                                                                                               0.0s 
```

## Starting ClickHouse and Metabase services
```bash
test@ip-172-31-240-50:~/ftw-de-bootcamp$ docker compose -p myk up -d clickhouse --remove-orphans
[+] Running 10/10
 ✔ clickhouse Pulled                                                                                                                                                                                                       15.6s 
[... pull output truncated ...]
[+] Running 3/3
 ✔ Network myk_default           Created                                                                                                                                                                                    0.1s 
 ✔ Volume "myk_clickhouse_data"  Created                                                                                                                                                                                    0.0s 
 ✔ Container clickhouse          Started                                                                                                                                                                                    0.8s 

test@ip-172-31-240-50:~/ftw-de-bootcamp$ docker compose -p myk up -d metabase --remove-orphans
[+] Running 8/8
 ✔ metabase Pulled                                                                                                                                                                                                         12.4s 
[... pull output truncated ...]
[+] Running 3/3
 ✔ Volume "myk_metabase_data"  Created                                                                                                                                                                                      0.0s 
 ✔ Container clickhouse        Healthy                                                                                                                                                                                      0.9s 
 ✔ Container metabase          Started                                                                                                                                                                                      1.1s 
```

## Checking running containers
```bash
test@ip-172-31-240-50:~/ftw-de-bootcamp$ docker ps
CONTAINER ID   IMAGE                                COMMAND                  CREATED          STATUS                    PORTS                                                                                                NAMES
6419c47d6811   metabase/metabase:latest             "/app/run_metabase.sh"   22 seconds ago   Up 21 seconds             0.0.0.0:3001->3000/tcp, [::]:3001->3000/tcp                                                          metabase
774ca4305d70   clickhouse/clickhouse-server:23.12   "/entrypoint.sh"         41 seconds ago   Up 41 seconds (healthy)   0.0.0.0:8123->8123/tcp, [::]:8123->8123/tcp, 0.0.0.0:9000->9000/tcp, [::]:9000->9000/tcp, 9009/tcp   clickhouse
```

## Running queries and pipelines
```bash
test@ip-172-31-240-50:~/ftw-de-bootcamp$ docker compose -p myk exec clickhouse \
  clickhouse-client --query="SELECT now();"
2025-07-18 03:32:32

test@ip-172-31-240-50:~/ftw-de-bootcamp$ docker compose -p myk --profile jobs run --rm dlt python pipelines/mpg_pipeline.py
[+] Creating 1/1
 ✔ Container clickhouse  Running                                                                                                                                                                                            0.0s 

test@ip-172-31-240-50:~/ftw-de-bootcamp$ docker compose -p myk exec clickhouse \
  clickhouse-client --query="SELECT count() FROM auto_mpg___mpg_raw;"
398

test@ip-172-31-240-50:~/ftw-de-bootcamp$ docker compose -p myk --profile jobs run --rm dbt run --models cylinders_by_origin
[+] Creating 1/1
 ✔ Container clickhouse  Running                                                                                                                                                                                            0.0s 

03:33:05  Running with dbt=1.8.9
03:33:05  Registered adapter: clickhouse=1.8.6
[... dbt output truncated ...]
03:33:11  Done. PASS=1 WARN=0 ERROR=0 SKIP=0 TOTAL=1

test@ip-172-31-240-50:~/ftw-de-bootcamp$ docker compose -p myk exec clickhouse \
  clickhouse-client --query="SELECT count() FROM cylinders_by_origin;"
3
```