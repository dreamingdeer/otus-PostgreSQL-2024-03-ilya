## Нагрузочное тестирование и тюнинг PostgreSQL

Исходное [домашнее задание](./HW08.md "Дз 08")

развернуть виртуальную машину любым удобным способом
поставить на неё PostgreSQL 15 любым способом
```sh
Как обычно это будет терраформ

< CUT  >
Apply complete! Resources: 9 added, 0 changed, 0 destroyed.

Outputs:

pg_main = [
  "10.128.0.30",
]
> ssh 10.128.0.30

pg_lsclusters 
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 online postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log

> pgbench -V
pgbench (PostgreSQL) 15.7 (Ubuntu 15.7-1.pgdg22.04+1)

postgres=# create database bgbench
CREATE DATABASE

> pgbench -i bgbench
dropping old tables...
NOTICE:  table "pgbench_accounts" does not exist, skipping
NOTICE:  table "pgbench_branches" does not exist, skipping
NOTICE:  table "pgbench_history" does not exist, skipping
NOTICE:  table "pgbench_tellers" does not exist, skipping
creating tables...
generating data (client-side)...
100000 of 100000 tuples (100%) done (elapsed 0.07 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done in 0.43 s (drop tables 0.00 s, create tables 0.01 s, client-side generate 0.23 s, vacuum 0.04 s, primary keys 0.15 s).

> pgbench -c 40 -j 2 -P 10 -T 60 bgbench
pgbench (15.7 (Ubuntu 15.7-1.pgdg22.04+1))
starting vacuum...end.
progress: 10.0 s, 552.0 tps, lat 71.705 ms stddev 53.064, 0 failed
progress: 20.0 s, 546.9 tps, lat 72.826 ms stddev 53.345, 0 failed
progress: 30.0 s, 508.8 tps, lat 78.274 ms stddev 71.052, 0 failed
progress: 40.0 s, 572.1 tps, lat 70.415 ms stddev 60.148, 0 failed
progress: 50.0 s, 562.0 tps, lat 71.217 ms stddev 57.711, 0 failed
progress: 60.0 s, 493.3 tps, lat 81.057 ms stddev 74.538, 0 failed
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 40
number of threads: 2
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 32391
number of failed transactions: 0 (0.000%)
latency average = 74.084 ms
latency stddev = 61.930 ms
initial connection time = 56.411 ms
tps = 539.488651 (without initial connection time)

> curl -s https://packagecloud.io/install/repositories/akopytov/sysbench/script.deb.sh | sudo bash
> sudo apt -y install sysbench

> sudo -i -u postgres psql -c "CREATE ROLE sb LOGIN PASSWORD 'sdfsdfsdfsd22'"
> sudo -i -u postgres psql -c "CREATE DATABASE sb"
> sudo -i -u postgres psql -c "alter database sb owner to sb"

> sysbench --db-driver=pgsql --report-interval=5 --threads=40 --time=60 --pgsql-host=localhost --pgsql-port=5432 --pgsql-user=sb --pgsql-password=sdfsdfsdfsd22 --pgsql-db=sb /usr/share/sysbench/oltp_read_write.lua prepare
sysbench 1.0.20 (using system LuaJIT 2.1.0-beta3)

Initializing worker threads...

Creating table 'sbtest1'...
Inserting 10000 records into 'sbtest1'
Creating a secondary index on 'sbtest1'...


> sysbench \
--db-driver=pgsql \
--report-interval=5 \
--threads=40 \
--time=60 \
--pgsql-host=localhost \
--pgsql-port=5432 \
--pgsql-user=sb \
--pgsql-password=sdfsdfsdfsd22 \
--pgsql-db=sb \
/usr/share/sysbench/oltp_read_write.lua run
sysbench 1.0.20 (using system LuaJIT 2.1.0-beta3)

Running the test with following options:
Number of threads: 40
Report intermediate results every 5 second(s)
Initializing random number generator from current time


Initializing worker threads...

Threads started!

[ 5s ] thds: 40 tps: 149.30 qps: 3239.53 (r/w/o: 2302.93/600.22/336.38) lat (ms,95%): 995.51 err/s: 7.20 reconn/s: 0.00
[ 10s ] thds: 40 tps: 24.40 qps: 526.82 (r/w/o: 372.42/99.40/55.00) lat (ms,95%): 6026.41 err/s: 2.20 reconn/s: 0.00
[ 15s ] thds: 40 tps: 131.80 qps: 2777.98 (r/w/o: 1957.19/530.20/290.60) lat (ms,95%): 2009.23 err/s: 8.00 reconn/s: 0.00
[ 20s ] thds: 40 tps: 147.39 qps: 3122.46 (r/w/o: 2200.70/592.97/328.79) lat (ms,95%): 2728.81 err/s: 9.80 reconn/s: 0.00
[ 25s ] thds: 40 tps: 130.61 qps: 2766.97 (r/w/o: 1949.32/518.83/298.82) lat (ms,95%): 1129.24 err/s: 10.00 reconn/s: 0.00
[ 30s ] thds: 40 tps: 161.20 qps: 3459.36 (r/w/o: 2443.97/652.99/362.40) lat (ms,95%): 1069.86 err/s: 12.00 reconn/s: 0.00
[ 35s ] thds: 40 tps: 459.60 qps: 9536.58 (r/w/o: 6701.98/1831.60/1003.00) lat (ms,95%): 121.08 err/s: 20.80 reconn/s: 0.00
[ 40s ] thds: 40 tps: 37.60 qps: 852.60 (r/w/o: 608.80/158.60/85.20) lat (ms,95%): 2985.89 err/s: 4.20 reconn/s: 0.00
[ 45s ] thds: 40 tps: 89.00 qps: 1926.75 (r/w/o: 1363.56/355.39/207.79) lat (ms,95%): 3911.79 err/s: 8.40 reconn/s: 0.00
[ 50s ] thds: 40 tps: 55.40 qps: 1202.01 (r/w/o: 851.21/223.60/127.20) lat (ms,95%): 2082.91 err/s: 5.40 reconn/s: 0.00
[ 55s ] thds: 40 tps: 104.00 qps: 2246.82 (r/w/o: 1584.22/418.40/244.20) lat (ms,95%): 2932.60 err/s: 11.20 reconn/s: 0.00
[ 60s ] thds: 40 tps: 173.59 qps: 3637.57 (r/w/o: 2561.63/689.16/386.78) lat (ms,95%): 1089.30 err/s: 9.80 reconn/s: 0.00
SQL statistics:
    queries performed:
        read:                            124670
        write:                           33504
        other:                           18674
        total:                           176848
    transactions:                        8359   (139.06 per sec.)
    queries:                             176848 (2942.02 per sec.)
    ignored errors:                      546    (9.08 per sec.)
    reconnects:                          0      (0.00 per sec.)

General statistics:
    total time:                          60.1092s
    total number of events:              8359

Latency (ms):
         min:                                    2.77
         avg:                                  287.34
         max:                                10163.18
         95th percentile:                     1903.57
         sum:                              2401893.18

Threads fairness:
    events (avg/stddev):           208.9750/8.60
    execution time (avg/stddev):   60.0473/0.03
```

Не удержался
```
Форкнуть pgtune  
Разместить на гитхабе  
```
Добро пожаловать на [pgtune](http://pgtune.godream.su/)

https://pgconfigurator.cybertec.at/


настроить кластер PostgreSQL 15 на максимальную производительность не обращая внимание на возможные проблемы с надежностью в случае аварийной перезагрузки виртуальной машины  
```sql

Что предлагает pgtune/pgconfigurator:

max_connections = 40
shared_buffers = 1GB # Буфферизация для быстродейтсвия, память быстрее диска.
effective_cache_size = 3GB # 
maintenance_work_mem = 256MB # 
checkpoint_completion_target = 0.9 # растянем чекпоинт во времени максимально
wal_buffers = 16MB # Пусть в памяти полежит )
default_statistics_target = 150 # что бы статистика была по эффективнее
random_page_cost = 1.1 # так как у нас облачный network-ssd iops/speed R = W
effective_io_concurrency = 200 # и запросы мы можем лить в несколько потоков это не локальный диск 
work_mem = 13107kB # под 40 коннектов можно больше work_mem некоторые операции станут быстрее
huge_pages = off
min_wal_size = 1GB
max_wal_size = 4GB

Но мы же хотим максимальной производительности не смотря ни на что! Самый узкое место это надежность и дологовечность можно просто убрать ее:
synchronous_commit = off # Не надо беспокоится о записил вала на диск. Какой такой wal для надежности
fsync = off # Отключим синхронизацию с диском )
wal_level = minimal # ну нам же все равно на нажежность ?)
checkpoint_timeout = 30min # чекпоинты ? пусть не спешат
full_page_writes = off # чекпоинты с копиями страниц для надежности ? а зачем )
max_wal_senders = 0

data_checksums # нужно еще проверить что отключено 
```
```confs
max_connections = 40
shared_buffers = 1GB
effective_cache_size = 3GB 
maintenance_work_mem = 256MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 150
random_page_cost = 1.1
effective_io_concurrency = 200
work_mem = 13107kB
huge_pages = off
min_wal_size = 1GB
max_wal_size = 4GB
synchronous_commit = off
fsync = off
wal_level = minimal
full_page_writes = off
checkpoint_timeout = 30min
max_wal_senders = 0
```

```sh
> sudo cp /opt/pgbench.conf /etc/postgresql/15/main/conf.d/
> sudo systemctl restart postgresql@15-main.service
```

```sql
postgres=# select sourcefile,name,setting,applied from pg_file_settings;

                 sourcefile                  |             name             |                setting                 | applied 
---------------------------------------------+------------------------------+----------------------------------------+---------
 /etc/postgresql/15/main/postgresql.conf     | data_directory               | /var/lib/postgresql/15/main            | t
 /etc/postgresql/15/main/postgresql.conf     | hba_file                     | /etc/postgresql/15/main/pg_hba.conf    | t
 /etc/postgresql/15/main/postgresql.conf     | ident_file                   | /etc/postgresql/15/main/pg_ident.conf  | t
 /etc/postgresql/15/main/postgresql.conf     | external_pid_file            | /var/run/postgresql/15-main.pid        | t
 /etc/postgresql/15/main/postgresql.conf     | port                         | 5432                                   | t
 /etc/postgresql/15/main/postgresql.conf     | max_connections              | 100                                    | f
 /etc/postgresql/15/main/postgresql.conf     | unix_socket_directories      | /var/run/postgresql                    | t
 /etc/postgresql/15/main/postgresql.conf     | ssl                          | on                                     | t
 /etc/postgresql/15/main/postgresql.conf     | ssl_cert_file                | /etc/ssl/certs/ssl-cert-snakeoil.pem   | t
 /etc/postgresql/15/main/postgresql.conf     | ssl_key_file                 | /etc/ssl/private/ssl-cert-snakeoil.key | t
 /etc/postgresql/15/main/postgresql.conf     | shared_buffers               | 128MB                                  | f
 /etc/postgresql/15/main/postgresql.conf     | dynamic_shared_memory_type   | posix                                  | t
 /etc/postgresql/15/main/postgresql.conf     | max_wal_size                 | 1GB                                    | f
 /etc/postgresql/15/main/postgresql.conf     | min_wal_size                 | 80MB                                   | f
 /etc/postgresql/15/main/postgresql.conf     | log_line_prefix              | %m [%p] %q%u@%d                        | t
 /etc/postgresql/15/main/postgresql.conf     | log_timezone                 | Etc/UTC                                | t
 /etc/postgresql/15/main/postgresql.conf     | cluster_name                 | 15/main                                | t
 /etc/postgresql/15/main/postgresql.conf     | datestyle                    | iso, mdy                               | t
 /etc/postgresql/15/main/postgresql.conf     | timezone                     | Etc/UTC                                | t
 /etc/postgresql/15/main/postgresql.conf     | lc_messages                  | en_US.UTF-8                            | t
 /etc/postgresql/15/main/postgresql.conf     | lc_monetary                  | en_US.UTF-8                            | t
 /etc/postgresql/15/main/postgresql.conf     | lc_numeric                   | en_US.UTF-8                            | t
 /etc/postgresql/15/main/postgresql.conf     | lc_time                      | en_US.UTF-8                            | t
 /etc/postgresql/15/main/postgresql.conf     | default_text_search_config   | pg_catalog.english                     | t
 /etc/postgresql/15/main/conf.d/pgbench.conf | max_connections              | 40                                     | t
 /etc/postgresql/15/main/conf.d/pgbench.conf | shared_buffers               | 1GB                                    | t
 /etc/postgresql/15/main/conf.d/pgbench.conf | effective_cache_size         | 3GB                                    | t
 /etc/postgresql/15/main/conf.d/pgbench.conf | maintenance_work_mem         | 256MB                                  | t
 /etc/postgresql/15/main/conf.d/pgbench.conf | checkpoint_completion_target | 0.9                                    | t
 /etc/postgresql/15/main/conf.d/pgbench.conf | wal_buffers                  | 16MB                                   | t
 /etc/postgresql/15/main/conf.d/pgbench.conf | default_statistics_target    | 150                                    | t
 /etc/postgresql/15/main/conf.d/pgbench.conf | random_page_cost             | 1.1                                    | t
 /etc/postgresql/15/main/conf.d/pgbench.conf | effective_io_concurrency     | 200                                    | t
 /etc/postgresql/15/main/conf.d/pgbench.conf | work_mem                     | 13107kB                                | t
 /etc/postgresql/15/main/conf.d/pgbench.conf | huge_pages                   | off                                    | t
 /etc/postgresql/15/main/conf.d/pgbench.conf | min_wal_size                 | 1GB                                    | t
 /etc/postgresql/15/main/conf.d/pgbench.conf | max_wal_size                 | 4GB                                    | t
 /etc/postgresql/15/main/conf.d/pgbench.conf | synchronous_commit           | off                                    | t
 /etc/postgresql/15/main/conf.d/pgbench.conf | fsync                        | off                                    | t
 /etc/postgresql/15/main/conf.d/pgbench.conf | wal_level                    | minimal                                | t
 /etc/postgresql/15/main/conf.d/pgbench.conf | full_page_writes             | off                                    | t
 /etc/postgresql/15/main/conf.d/pgbench.conf | checkpoint_timeout           | 30min                                  | t
 /etc/postgresql/15/main/conf.d/pgbench.conf | max_wal_senders              | 0                                      | t

```
нагрузить кластер через утилиту через утилиту pgbench (https://postgrespro.ru/docs/postgrespro/14/pgbench)
```sql
> pgbench -i bgbench
dropping old tables...
creating tables...
generating data (client-side)...
100000 of 100000 tuples (100%) done (elapsed 0.07 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done in 0.17 s (drop tables 0.01 s, create tables 0.00 s, client-side generate 0.08 s, vacuum 0.04 s, primary keys 0.04 s).

> pgbench -c 40 -j 2 -P 10 -T 60 bgbench
pgbench (15.7 (Ubuntu 15.7-1.pgdg22.04+1))
starting vacuum...end.
progress: 10.0 s, 2096.1 tps, lat 18.937 ms stddev 11.251, 0 failed
progress: 20.0 s, 2112.7 tps, lat 18.937 ms stddev 10.658, 0 failed
progress: 30.0 s, 2188.1 tps, lat 18.282 ms stddev 10.711, 0 failed
progress: 40.0 s, 2139.5 tps, lat 18.695 ms stddev 10.667, 0 failed
progress: 50.0 s, 2167.0 tps, lat 18.460 ms stddev 11.383, 0 failed
progress: 60.0 s, 2182.1 tps, lat 18.333 ms stddev 11.320, 0 failed
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 40
number of threads: 2
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 128895
number of failed transactions: 0 (0.000%)
latency average = 18.615 ms
latency stddev = 11.036 ms
initial connection time = 58.752 ms
tps = 2147.024371 (without initial connection time)

```
написать какого значения tps удалось достичь, показать какие параметры в какие значения устанавливали и почему
```sql

tps = 2147.024371 (without initial connection time)  
vs
tps = 539.488651 (without initial connection time)

Параметры описаны выше, производительность достигнута засчет отключения надежности и записи в wal. А так же синронизации wal с диском.
```
Задание со *: аналогично протестировать через утилиту https://github.com/Percona-Lab/sysbench-tpcc (требует установки
https://github.com/akopytov/sysbench)

```sql

> sysbench --db-driver=pgsql --report-interval=5 --threads=40 --time=60 --pgsql-host=localhost --pgsql-port=5432 --pgsql-user=sb --pgsql-password=sdfsdfsdfsd22 --pgsql-db=sb /usr/share/sysbench/oltp_read_write.lua cleanup
sysbench 1.0.20 (using system LuaJIT 2.1.0-beta3)

Dropping table 'sbtest1'...
> sysbench --db-driver=pgsql --report-interval=5 --threads=40 --time=60 --pgsql-host=localhost --pgsql-port=5432 --pgsql-user=sb --pgsql-password=sdfsdfsdfsd22 --pgsql-db=sb /usr/share/sysbench/oltp_read_write.lua prepare
sysbench 1.0.20 (using system LuaJIT 2.1.0-beta3)

Initializing worker threads...

Creating table 'sbtest1'...
Inserting 10000 records into 'sbtest1'
Creating a secondary index on 'sbtest1'...

sysbench --db-driver=pgsql --report-interval=5 --threads=40 --time=60 --pgsql-host=localhost --pgsql-port=5432 --pgsql-user=sb --pgsql-password=sdfsdfsdfsd22 --pgsql-db=sb /usr/share/sysbench/oltp_read_write.lua run
sysbench 1.0.20 (using system LuaJIT 2.1.0-beta3)

Running the test with following options:
Number of threads: 40
Report intermediate results every 5 second(s)
Initializing random number generator from current time


Initializing worker threads...

Threads started!

[ 5s ] thds: 40 tps: 171.12 qps: 3681.82 (r/w/o: 2613.93/690.67/377.22) lat (ms,95%): 1032.01 err/s: 7.60 reconn/s: 0.00
[ 10s ] thds: 40 tps: 288.41 qps: 5903.32 (r/w/o: 4141.29/1149.82/612.21) lat (ms,95%): 995.51 err/s: 7.40 reconn/s: 0.00
[ 15s ] thds: 40 tps: 472.21 qps: 9682.98 (r/w/o: 6795.72/1887.43/999.82) lat (ms,95%): 112.67 err/s: 15.20 reconn/s: 0.00
[ 20s ] thds: 40 tps: 163.00 qps: 3430.39 (r/w/o: 2421.99/659.60/348.80) lat (ms,95%): 1069.86 err/s: 8.00 reconn/s: 0.00
[ 25s ] thds: 40 tps: 126.80 qps: 2660.92 (r/w/o: 1873.15/509.99/277.79) lat (ms,95%): 2009.23 err/s: 7.00 reconn/s: 0.00
[ 30s ] thds: 40 tps: 6.20 qps: 166.20 (r/w/o: 123.20/27.00/16.00) lat (ms,95%): 5033.35 err/s: 2.60 reconn/s: 0.00
[ 35s ] thds: 40 tps: 2.60 qps: 72.60 (r/w/o: 53.20/12.60/6.80) lat (ms,95%): 6960.17 err/s: 1.20 reconn/s: 0.00
[ 40s ] thds: 40 tps: 31.80 qps: 697.19 (r/w/o: 495.59/127.80/73.80) lat (ms,95%): 13071.47 err/s: 3.60 reconn/s: 0.00
[ 45s ] thds: 40 tps: 388.21 qps: 7931.63 (r/w/o: 5565.36/1547.45/818.82) lat (ms,95%): 960.30 err/s: 11.40 reconn/s: 0.00
[ 50s ] thds: 40 tps: 111.60 qps: 2360.16 (r/w/o: 1664.37/454.39/241.40) lat (ms,95%): 1973.38 err/s: 5.20 reconn/s: 0.00
[ 55s ] thds: 40 tps: 277.20 qps: 5713.09 (r/w/o: 4013.47/1108.62/591.01) lat (ms,95%): 1032.01 err/s: 10.40 reconn/s: 0.00
[ 60s ] thds: 40 tps: 313.00 qps: 6486.08 (r/w/o: 4556.06/1256.22/673.81) lat (ms,95%): 926.33 err/s: 13.20 reconn/s: 0.00
SQL statistics:
    queries performed:
        read:                            171738
        write:                           47278
        other:                           25239
        total:                           244255
    transactions:                        11800  (196.33 per sec.)
    queries:                             244255 (4064.04 per sec.)
    ignored errors:                      467    (7.77 per sec.)
    reconnects:                          0      (0.00 per sec.)

General statistics:
    total time:                          60.0998s
    total number of events:              11800

Latency (ms):
         min:                                    2.06
         avg:                                  203.54
         max:                                15080.81
         95th percentile:                     1032.01
         sum:                              2401721.00

Threads fairness:
    events (avg/stddev):           295.0000/7.72
    execution time (avg/stddev):   60.0430/0.03

```

```sql
SQL statistics:
    queries performed:
        read:                            171738
        write:                           47278
        other:                           25239
        total:                           244255
    transactions:                        11800  (196.33 per sec.)
    queries:                             244255 (4064.04 per sec.)
    ignored errors:                      467    (7.77 per sec.)
    reconnects:                          0      (0.00 per sec.)

VS

SQL statistics:
    queries performed:
        read:                            124670
        write:                           33504
        other:                           18674
        total:                           176848
    transactions:                        8359   (139.06 per sec.)
    queries:                             176848 (2942.02 per sec.)
    ignored errors:                      546    (9.08 per sec.)
    reconnects:                          0      (0.00 per sec.)

Как видим что по сравнению с pgbench тест sysbench чтения/записи получаем не такую внушительную производительность. Стоит ли жертвовать надежностью хранения данных. Видимо нет.
```