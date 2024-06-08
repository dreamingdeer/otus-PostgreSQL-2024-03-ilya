## Настройка autovacuum с учетом особеностей производительности

Исходное [домашнее задание](./HW05.md "Дз 05")

Создать инстанс ВМ с 2 ядрами и 4 Гб ОЗУ и SSD 10GB  
Установить на него PostgreSQL 15 с дефолтными настройками

```ruby
Установим как обычно через терраформ.
Добавим SSD диск.

module "pg01" {
  source = "github.com/dreamingdeer/otus-PostgreSQL-2024-03-ilya.git//HW02 Postgres Install/terraform/modules/tf-yc-instance?ref=356bbb2"
  source_family = "ubuntu-2204-lts"
  vm_count = 1 # numbers of vm
  vm_nat = false
  cores = 2
  core_fraction = 100
  memory = 4
  disk_size = 15
  vm_second_disks = {
    "first" = {
      name = "hddb",
      type = "network-ssd",
      size = 10
    }s  
   }
  # set custom
  user_data_file = local.pg_meta_file
  # base name
  name = "pg"
  # get subnet id for vm from specified zone
  subnet_id = module.local-nat.yandex_vpc_subnets.id
  depends_on = [ module.bastion ]
}
```


```sh
> terraform apply -var-file ../../terraform.tfvars

Apply complete! Resources: 11 added, 0 changed, 0 destroyed.

Outputs:

base_image_id = "fd8oniokk07io6o60unf"
external_ips_bastion = [
  "158.160.170.4",
]
internal_ips_bastion = [
  "10.128.0.30",
]
pg_main = [
  "10.128.0.4",
]
 
> ssh 10.128.0.4
> pg_lsclusters 
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 online postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log
```
```sh
> sudo lsblk 
NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
loop0    7:0    0  63.3M  1 loop /snap/core20/1822
loop1    7:1    0  63.9M  1 loop /snap/core20/2318
loop2    7:2    0 111.9M  1 loop /snap/lxd/24322
loop3    7:3    0    87M  1 loop /snap/lxd/28373
loop4    7:4    0  49.8M  1 loop /snap/snapd/18357
loop5    7:5    0  38.8M  1 loop /snap/snapd/21759
vda    252:0    0    15G  0 disk 
├─vda1 252:1    0     1M  0 part 
└─vda2 252:2    0    15G  0 part /
vdb    252:16   0    10G  0 disk 

> sudo mkfs.xfs -L pgdata /dev/vdb 
meta-data=/dev/vdb               isize=512    agcount=4, agsize=655360 blks
         =                       sectsz=4096  attr=2, projid32bit=1
         =                       crc=1        finobt=1, sparse=1, rmapbt=0
         =                       reflink=1    bigtime=0 inobtcount=0
data     =                       bsize=4096   blocks=2621440, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0, ftype=1
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=4096  sunit=1 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0

> sudo mkdir /opt/pgdata
> echo "/dev/disk/by-label/pgdata /opt/pgdata xfs defaults 0 1" | sudo tee -a /etc/fstab
/dev/disk/by-label/pgdata /opt/pgdata xfs defaults 0 1

> sudo mount -a
> sudo chown -R postgres. /opt/pgdata
> sudo pg_dropcluster --stop 15 main
```
```sh
> sudo pg_createcluster 15 main --start -d /opt/pgdata/15/main
Creating new PostgreSQL cluster 15/main ...
/usr/lib/postgresql/15/bin/initdb -D /opt/pgdata/15/main --auth-local peer --auth-host scram-sha-256 --no-instructions
The files belonging to this database system will be owned by user "postgres".
This user must also own the server process.

The database cluster will be initialized with locale "en_US.UTF-8".
The default database encoding has accordingly been set to "UTF8".
The default text search configuration will be set to "english".

Data page checksums are disabled.

fixing permissions on existing directory /opt/pgdata/15/main ... ok
creating subdirectories ... ok
selecting dynamic shared memory implementation ... posix
selecting default max_connections ... 100
selecting default shared_buffers ... 128MB
selecting default time zone ... Etc/UTC
creating configuration files ... ok
running bootstrap script ... ok
performing post-bootstrap initialization ... ok
syncing data to disk ... ok
Ver Cluster Port Status Owner    Data directory      Log file
15  main    5432 online postgres /opt/pgdata/15/main /var/log/postgresql/postgresql-15-main.log

> df -h
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           392M  1.2M  390M   1% /run
/dev/vda2        15G  4.3G  9.8G  31% /
tmpfs           2.0G  1.1M  2.0G   1% /dev/shm
tmpfs           5.0M     0  5.0M   0% /run/lock
tmpfs           392M  4.0K  392M   1% /run/user/1000
/dev/vdb         10G  143M  9.9G   2% /opt/pgdata
```

Создать БД для тестов: выполнить pgbench -i postgres  
Запустить pgbench -c8 -P 6 -T 60 -U postgres postgres

```sql
А давайте сначала прогреем постгрю выполнив этот пункт 2 раза и посмотрим результаты.  А во второй сесси посмотрим что происходит с помощью iotop. 1) если fs ext4 то мы имеем отложенную инициализацию fs. 2) не все wal файлы не созданы.

-- -- session 2
-- > echo 1 | sudo tee  /proc/sys/kernel/task_delayacct
-- > sudo iotop

-- session 1
> sudo -i -u postgres bash

> ls -lh /opt/pgdata/15/main/pg_wal/
total 16M
-rw------- 1 postgres postgres 16M Jun  8 05:41 000000010000000000000001
drwx------ 2 postgres postgres   6 Jun  8 05:40 archive_status

> psql -c 'create database pgtest'
CREATE DATABASE
> ls -lh /opt/pgdata/15/main/pg_wal/
total 32M
-rw------- 1 postgres postgres 16M Jun  8 05:42 000000010000000000000001
-rw------- 1 postgres postgres 16M Jun  8 05:42 000000010000000000000002
drwx------ 2 postgres postgres   6 Jun  8 05:40 archive_status

>  pgbench -i pgtest
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
done in 1.18 s (drop tables 0.00 s, create tables 0.01 s, client-side generate 0.88 s, vacuum 0.03 s, primary keys 0.26 s).


> pgbench -c8 -P 6 -T 60 -U postgres pgtest
pgbench (15.7 (Ubuntu 15.7-1.pgdg22.04+1))
starting vacuum...end.
progress: 6.0 s, 712.5 tps, lat 11.186 ms stddev 8.251, 0 failed
progress: 12.0 s, 590.5 tps, lat 13.506 ms stddev 16.148, 0 failed
progress: 18.0 s, 615.5 tps, lat 13.039 ms stddev 11.282, 0 failed
progress: 24.0 s, 773.3 tps, lat 10.336 ms stddev 6.909, 0 failed
progress: 30.0 s, 750.7 tps, lat 10.489 ms stddev 8.597, 0 failed
progress: 36.0 s, 717.2 tps, lat 11.329 ms stddev 19.217, 0 failed
progress: 42.0 s, 605.0 tps, lat 13.205 ms stddev 13.245, 0 failed
progress: 48.0 s, 624.7 tps, lat 12.826 ms stddev 11.245, 0 failed
progress: 54.0 s, 697.7 tps, lat 11.466 ms stddev 8.310, 0 failed
progress: 60.0 s, 669.7 tps, lat 11.924 ms stddev 8.498, 0 failed
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 8
number of threads: 1
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 40548
number of failed transactions: 0 (0.000%)
latency average = 11.836 ms
latency stddev = 11.722 ms
initial connection time = 15.283 ms
tps = 675.625779 (without initial connection time)

> ls -lh /opt/pgdata/15/main/pg_wal/
total 48M
-rw------- 1 postgres postgres 16M Jun  8 05:42 000000010000000000000001
-rw------- 1 postgres postgres 16M Jun  8 05:43 000000010000000000000002
-rw------- 1 postgres postgres 16M Jun  8 05:44 000000010000000000000003
drwx------ 2 postgres postgres   6 Jun  8 05:40 archive_status

Так же видим что при выполнении только запись на диск 5Mb/sec запустим повторно

pgbench -c8 -P 6 -T 60 -U postgres pgtest
pgbench (15.7 (Ubuntu 15.7-1.pgdg22.04+1))
starting vacuum...end.
 progress: 6.0 s, 540.3 tps, lat 14.741 ms stddev 29.978, 0 failed
progress: 12.0 s, 538.7 tps, lat 14.865 ms stddev 12.614, 0 failed
progress: 18.0 s, 806.0 tps, lat 9.904 ms stddev 7.461, 0 failed
progress: 24.0 s, 771.5 tps, lat 10.386 ms stddev 7.242, 0 failed
progress: 30.0 s, 666.7 tps, lat 11.998 ms stddev 21.299, 0 failed
progress: 36.0 s, 638.3 tps, lat 12.493 ms stddev 13.808, 0 failed
progress: 42.0 s, 546.7 tps, lat 14.663 ms stddev 12.837, 0 failed
progress: 48.0 s, 786.5 tps, lat 10.177 ms stddev 7.501, 0 failed
progress: 54.0 s, 742.5 tps, lat 10.763 ms stddev 8.939, 0 failed
progress: 60.0 s, 646.3 tps, lat 12.388 ms stddev 8.389, 0 failed
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 8
number of threads: 1
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 40109
number of failed transactions: 0 (0.000%)
latency average = 11.965 ms
latency stddev = 14.168 ms
initial connection time = 15.833 ms
tps = 668.435395 (without initial connection time)

ls -lh /opt/pgdata/15/main/pg_wal/
total 80M
-rw------- 1 postgres postgres 16M Jun  8 05:42 000000010000000000000001
-rw------- 1 postgres postgres 16M Jun  8 05:43 000000010000000000000002
-rw------- 1 postgres postgres 16M Jun  8 05:45 000000010000000000000003
-rw------- 1 postgres postgres 16M Jun  8 05:46 000000010000000000000004
-rw------- 1 postgres postgres 16M Jun  8 05:46 000000010000000000000005
drwx------ 2 postgres postgres   6 Jun  8 05:40 archive_status

pg_conftool show all
cluster_name = '15/main'
data_directory = '/opt/pgdata/15/main'
datestyle = 'iso, mdy'
default_text_search_config = 'pg_catalog.english'
dynamic_shared_memory_type = posix
external_pid_file = '/var/run/postgresql/15-main.pid'
hba_file = '/etc/postgresql/15/main/pg_hba.conf'
ident_file = '/etc/postgresql/15/main/pg_ident.conf'
lc_messages = 'en_US.UTF-8'
lc_monetary = 'en_US.UTF-8'
lc_numeric = 'en_US.UTF-8'
lc_time = 'en_US.UTF-8'
log_line_prefix = '%m [%p] %q%u@%d '
log_timezone = 'Etc/UTC'
max_connections = 100
max_wal_size = 1GB
min_wal_size = 80MB
port = 5432
shared_buffers = 128MB
ssl = on
ssl_cert_file = '/etc/ssl/certs/ssl-cert-snakeoil.pem'
ssl_key_file = '/etc/ssl/private/ssl-cert-snakeoil.key'
timezone = 'Etc/UTC'
unix_socket_directories = '/var/run/postgresql'

Посмотрим отличия от дефолтных

> select sourcefile,name,setting,applied from pg_file_settings ;

               sourcefile                |            name            |                setting                 | applied 
-----------------------------------------+----------------------------+----------------------------------------+---------
 /etc/postgresql/15/main/postgresql.conf | data_directory             | /opt/pgdata/15/main                    | t
 /etc/postgresql/15/main/postgresql.conf | hba_file                   | /etc/postgresql/15/main/pg_hba.conf    | t
 /etc/postgresql/15/main/postgresql.conf | ident_file                 | /etc/postgresql/15/main/pg_ident.conf  | t
 /etc/postgresql/15/main/postgresql.conf | external_pid_file          | /var/run/postgresql/15-main.pid        | t
 /etc/postgresql/15/main/postgresql.conf | port                       | 5432                                   | t
 /etc/postgresql/15/main/postgresql.conf | max_connections            | 100                                    | t
 /etc/postgresql/15/main/postgresql.conf | unix_socket_directories    | /var/run/postgresql                    | t
 /etc/postgresql/15/main/postgresql.conf | ssl                        | on                                     | t
 /etc/postgresql/15/main/postgresql.conf | ssl_cert_file              | /etc/ssl/certs/ssl-cert-snakeoil.pem   | t
 /etc/postgresql/15/main/postgresql.conf | ssl_key_file               | /etc/ssl/private/ssl-cert-snakeoil.key | t
 /etc/postgresql/15/main/postgresql.conf | shared_buffers             | 128MB                                  | t
 /etc/postgresql/15/main/postgresql.conf | dynamic_shared_memory_type | posix                                  | t
 /etc/postgresql/15/main/postgresql.conf | max_wal_size               | 1GB                                    | t
 /etc/postgresql/15/main/postgresql.conf | min_wal_size               | 80MB                                   | t
 /etc/postgresql/15/main/postgresql.conf | log_line_prefix            | %m [%p] %q%u@%d                        | t
 /etc/postgresql/15/main/postgresql.conf | log_timezone               | Etc/UTC                                | t
 /etc/postgresql/15/main/postgresql.conf | cluster_name               | 15/main                                | t
 /etc/postgresql/15/main/postgresql.conf | datestyle                  | iso, mdy                               | t
 /etc/postgresql/15/main/postgresql.conf | timezone                   | Etc/UTC                                | t
 /etc/postgresql/15/main/postgresql.conf | lc_messages                | en_US.UTF-8                            | t
 /etc/postgresql/15/main/postgresql.conf | lc_monetary                | en_US.UTF-8                            | t
 /etc/postgresql/15/main/postgresql.conf | lc_numeric                 | en_US.UTF-8                            | t
 /etc/postgresql/15/main/postgresql.conf | lc_time                    | en_US.UTF-8                            | t
 /etc/postgresql/15/main/postgresql.conf | default_text_search_config | pg_catalog.english                     | t

```

Применить параметры настройки PostgreSQL из прикрепленного к материалам занятия файла  
Протестировать заново

```conf
max_connections = 40 # максимальное число подключиений
shared_buffers = 1GB # размер буфферного кэша под страницы
effective_cache_size = 3GB # эффиктивный размер кэша диска
maintenance_work_mem = 512MB # влияет на рабочие процессы постгри (например автовакуум)
checkpoint_completion_target = 0.9 # Задаёт целевое время для завершения процедуры контрольной точки, как коэффициент для общего времени между контрольными точками. 
wal_buffers = 16MB # буффер для wal
default_statistics_target = 500 # планировщик будет более точнее
random_page_cost = 4 # стоимость для планировщика рандомного чтения (в принципе у нас network-ssd с SLA R=W iops/read можно ставить что то вроде 1.1)
effective_io_concurrency = 2 #  Number of simultaneous requests that can be handled efficiently by the disk subsystem для SSD можно поставить и по больше
work_mem = 6553kB # рабочая память для процессса 
min_wal_size = 4GB # размер вал лога
max_wal_size = 16GB # какой то суицид на разделе с 10G ;]
```

```sql
Пересоздадим кластер
> sudo pg_dropcluster --stop 15 main
> sudo pg_createcluster 15 main -d /opt/pgdata/15/main
Ver Cluster Port Status Owner    Data directory      Log file
15  main    5432 down   postgres /opt/pgdata/15/main /var/log/postgresql/postgresql-15-main.log
> sudo -i -u postgres cp /opt/pgbench.conf /etc/postgresql/15/main/conf.d/
> sudo systemctl restart postgresql@15-main


postgres=# \pset pager 0
Pager usage is off.
postgres=# select sourcefile,name,setting,applied from pg_file_settings ;
                 sourcefile                  |             name             |                setting                 | applied 
---------------------------------------------+------------------------------+----------------------------------------+---------
 /etc/postgresql/15/main/postgresql.conf     | data_directory               | /opt/pgdata/15/main                    | t
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
 /etc/postgresql/15/main/conf.d/pgbench.conf | maintenance_work_mem         | 512MB                                  | t
 /etc/postgresql/15/main/conf.d/pgbench.conf | checkpoint_completion_target | 0.9                                    | t
 /etc/postgresql/15/main/conf.d/pgbench.conf | wal_buffers                  | 16MB                                   | t
 /etc/postgresql/15/main/conf.d/pgbench.conf | default_statistics_target    | 500                                    | t
 /etc/postgresql/15/main/conf.d/pgbench.conf | random_page_cost             | 4                                      | t
 /etc/postgresql/15/main/conf.d/pgbench.conf | effective_io_concurrency     | 2                                      | t
 /etc/postgresql/15/main/conf.d/pgbench.conf | min_wal_size                 | 4GB                                    | t
 /etc/postgresql/15/main/conf.d/pgbench.conf | max_wal_size                 | 16GB                                   | t
(35 rows)

Все настройки из нашей конфигурации применились

postgres=# create database pgtest;
CREATE DATABASE
\q

> pgbench -i pgtest
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
done in 1.17 s (drop tables 0.00 s, create tables 0.01 s, client-side generate 0.87 s, vacuum 0.06 s, primary keys 0.24 s).

> pgbench -c8 -P 6 -T 60 -U postgres pgtest
pgbench (15.7 (Ubuntu 15.7-1.pgdg22.04+1))
starting vacuum...end.
progress: 6.0 s, 467.7 tps, lat 16.982 ms stddev 21.905, 0 failed
progress: 12.0 s, 712.7 tps, lat 11.262 ms stddev 9.734, 0 failed
progress: 18.0 s, 798.0 tps, lat 10.004 ms stddev 6.616, 0 failed
progress: 24.0 s, 713.3 tps, lat 11.235 ms stddev 9.045, 0 failed
progress: 30.0 s, 599.3 tps, lat 13.342 ms stddev 10.208, 0 failed
progress: 36.0 s, 455.0 tps, lat 17.556 ms stddev 22.433, 0 failed
progress: 42.0 s, 611.7 tps, lat 13.093 ms stddev 10.396, 0 failed
progress: 48.0 s, 649.3 tps, lat 12.308 ms stddev 8.993, 0 failed
progress: 54.0 s, 637.0 tps, lat 12.558 ms stddev 10.202, 0 failed
progress: 60.0 s, 468.8 tps, lat 17.072 ms stddev 11.934, 0 failed
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 8
number of threads: 1
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 36685
number of failed transactions: 0 (0.000%)
latency average = 13.083 ms
latency stddev = 12.566 ms
initial connection time = 16.006 ms
tps = 611.307141 (without initial connection time)

Что то лучше не стало ) Перезапустим


avg-cpu:  %user   %nice %system %iowait  %steal   %idle
          13.13    0.00    6.67   39.49    0.00   40.72

Device             tps    kB_read/s    kB_wrtn/s    kB_dscd/s    kB_read    kB_wrtn    kB_dscd
vdb             625.80         0.00      8696.80         0.00          0      43484          0

pgbench -c8 -P 6 -T 60 -U postgres pgtest
pgbench (15.7 (Ubuntu 15.7-1.pgdg22.04+1))
starting vacuum...end.
progress: 6.0 s, 624.7 tps, lat 12.734 ms stddev 14.544, 0 failed
progress: 12.0 s, 571.0 tps, lat 14.025 ms stddev 10.436, 0 failed
progress: 18.0 s, 484.8 tps, lat 16.482 ms stddev 17.215, 0 failed
progress: 24.0 s, 405.2 tps, lat 19.779 ms stddev 18.643, 0 failed
progress: 30.0 s, 648.5 tps, lat 12.336 ms stddev 10.021, 0 failed
progress: 36.0 s, 577.5 tps, lat 13.841 ms stddev 12.291, 0 failed
progress: 42.0 s, 616.8 tps, lat 12.980 ms stddev 9.710, 0 failed
progress: 48.0 s, 482.7 tps, lat 16.537 ms stddev 15.228, 0 failed
progress: 54.0 s, 511.7 tps, lat 15.663 ms stddev 12.129, 0 failed
progress: 60.0 s, 709.7 tps, lat 11.264 ms stddev 7.970, 0 failed
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 8
number of threads: 1
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 33803
number of failed transactions: 0 (0.000%)
latency average = 14.198 ms
latency stddev = 12.996 ms
initial connection time = 16.215 ms
tps = 563.337647 (without initial connection time)

Лучше не стало вернем все как было )

> sudo pg_dropcluster --stop 15 main
> sudo pg_createcluster 15 main -d /opt/pgdata/15/main
> sudo rm /etc/postgresql/15/main/conf.d/pgbench.conf
> sudo systemctl restart postgresql@15-main
> sudo -i -u postgres bash
> psql -c 'create database pgtest';
CREATE DATABASE

> psql -c 'select sourcefile,name,setting,applied from pg_file_settings ';
               sourcefile                |            name            |                setting                 | applied 
-----------------------------------------+----------------------------+----------------------------------------+---------
 /etc/postgresql/15/main/postgresql.conf | data_directory             | /opt/pgdata/15/main                    | t
 /etc/postgresql/15/main/postgresql.conf | hba_file                   | /etc/postgresql/15/main/pg_hba.conf    | t
 /etc/postgresql/15/main/postgresql.conf | ident_file                 | /etc/postgresql/15/main/pg_ident.conf  | t
 /etc/postgresql/15/main/postgresql.conf | external_pid_file          | /var/run/postgresql/15-main.pid        | t
 /etc/postgresql/15/main/postgresql.conf | port                       | 5432                                   | t
 /etc/postgresql/15/main/postgresql.conf | max_connections            | 100                                    | t
 /etc/postgresql/15/main/postgresql.conf | unix_socket_directories    | /var/run/postgresql                    | t
 /etc/postgresql/15/main/postgresql.conf | ssl                        | on                                     | t
 /etc/postgresql/15/main/postgresql.conf | ssl_cert_file              | /etc/ssl/certs/ssl-cert-snakeoil.pem   | t
 /etc/postgresql/15/main/postgresql.conf | ssl_key_file               | /etc/ssl/private/ssl-cert-snakeoil.key | t
 /etc/postgresql/15/main/postgresql.conf | shared_buffers             | 128MB                                  | t
 /etc/postgresql/15/main/postgresql.conf | dynamic_shared_memory_type | posix                                  | t
 /etc/postgresql/15/main/postgresql.conf | max_wal_size               | 1GB                                    | t
 /etc/postgresql/15/main/postgresql.conf | min_wal_size               | 80MB                                   | t
 /etc/postgresql/15/main/postgresql.conf | log_line_prefix            | %m [%p] %q%u@%d                        | t
 /etc/postgresql/15/main/postgresql.conf | log_timezone               | Etc/UTC                                | t
 /etc/postgresql/15/main/postgresql.conf | cluster_name               | 15/main                                | t
 /etc/postgresql/15/main/postgresql.conf | datestyle                  | iso, mdy                               | t
 /etc/postgresql/15/main/postgresql.conf | timezone                   | Etc/UTC                                | t
 /etc/postgresql/15/main/postgresql.conf | lc_messages                | en_US.UTF-8                            | t
 /etc/postgresql/15/main/postgresql.conf | lc_monetary                | en_US.UTF-8                            | t
 /etc/postgresql/15/main/postgresql.conf | lc_numeric                 | en_US.UTF-8                            | t
 /etc/postgresql/15/main/postgresql.conf | lc_time                    | en_US.UTF-8                            | t
 /etc/postgresql/15/main/postgresql.conf | default_text_search_config | pg_catalog.english                     | t
(24 rows)


pgbench -i pgtest
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
done in 1.16 s (drop tables 0.00 s, create tables 0.01 s, client-side generate 0.87 s, vacuum 0.03 s, primary keys 0.26 s).

> pgbench -c8 -P 6 -T 60 -U postgres pgtest
pgbench (15.7 (Ubuntu 15.7-1.pgdg22.04+1))
starting vacuum...end.
progress: 6.0 s, 793.0 tps, lat 10.035 ms stddev 6.768, 0 failed
progress: 12.0 s, 628.3 tps, lat 12.741 ms stddev 10.964, 0 failed
progress: 18.0 s, 577.2 tps, lat 13.869 ms stddev 10.711, 0 failed
progress: 24.0 s, 600.3 tps, lat 13.114 ms stddev 12.906, 0 failed
progress: 30.0 s, 295.5 tps, lat 27.468 ms stddev 30.533, 0 failed
progress: 36.0 s, 617.7 tps, lat 12.972 ms stddev 9.977, 0 failed
progress: 42.0 s, 572.7 tps, lat 13.961 ms stddev 10.465, 0 failed
progress: 48.0 s, 631.8 tps, lat 12.662 ms stddev 9.579, 0 failed
progress: 54.0 s, 643.0 tps, lat 12.394 ms stddev 12.566, 0 failed
progress: 60.0 s, 502.2 tps, lat 15.994 ms stddev 17.863, 0 failed
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 8
number of threads: 1
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 35178
number of failed transactions: 0 (0.000%)
latency average = 13.642 ms
latency stddev = 13.508 ms
initial connection time = 15.417 ms
tps = 586.302072 (without initial connection time)

> iostat vdb 5

avg-cpu:  %user   %nice %system %iowait  %steal   %idle
          14.99    0.00    5.98   38.91    0.00   40.12

Device             tps    kB_read/s    kB_wrtn/s    kB_dscd/s    kB_read    kB_wrtn    kB_dscd
vdb             636.80         0.00      8100.80         0.00          0      40504          0

Результаты сравнимы мы уперлись в дисковую подсистему
```
Выводы
```
Результаты сравнимы мы уперлись в дисковую подсистему, к сожалению диски на яндексе ограничены iops поэтому заметной производильености мы не получили.
```

Создать таблицу с текстовым полем и заполнить случайными или сгенерированными данным в размере 1млн строк
Посмотреть размер файла с таблицей
SELECT pg_size_pretty(pg_total_relation_size(text_table));


```sql
CREATE TABLE text_table (
    id SERIAL PRIMARY KEY,
    text TEXT
);

postgres=# INSERT INTO text_table
SELECT id, random()::TEXT
FROM generate_series(1, 1000000) AS id;
INSERT 0 1000000

postgres=# SELECT pg_size_pretty(pg_total_relation_size('text_table'));
 pg_size_pretty 
----------------
 72 MB
(1 row)

```
5 раз обновить все строчки и добавить к каждой строчке любой символ  

```sql
postgres=# update text_table SET text = random()::TEXT || '1';
UPDATE 1000000
postgres=# update text_table SET text = random()::TEXT || 'q';
UPDATE 1000000
postgres=# update text_table SET text = random()::TEXT || 'x';
UPDATE 1000000
postgres=# update text_table SET text = random()::TEXT || 'w';
UPDATE 1000000
postgres=# update text_table SET text = random()::TEXT || 'yx';
UPDATE 1000000
```

Посмотреть количество мертвых строчек в таблице и когда последний раз приходил автовакуум

```sql

postgres=# SELECT relname, n_live_tup, n_dead_tup, trunc(100*n_dead_tup/(n_live_tup+1))::float "ratio%", last_autovacuum FROM pg_stat_user_tables WHERE relname = 'text_table';
  relname   | n_live_tup | n_dead_tup | ratio% |        last_autovacuum        
------------+------------+------------+--------+-------------------------------
 text_table |    1000000 |    5169085 |    516 | 2024-06-07 13:49:25.751215+00
(1 row)

postgres=# SELECT relname, n_live_tup, n_dead_tup, trunc(100*n_dead_tup/(n_live_tup+1))::float "ratio%", last_autovacuum FROM pg_stat_user_tables WHERE relname = 'text_table';
  relname   | n_live_tup | n_dead_tup | ratio% |        last_autovacuum        
------------+------------+------------+--------+-------------------------------
 text_table |    1000000 |          0 |      0 | 2024-06-07 13:49:25.751215+00
```

5 раз обновить все строчки и добавить к каждой строчке любой символ
Посмотреть размер файла с таблицей

```sql
CREATE EXTENSION pgcrypto;

Есть нюанс это одна транзакция )

DO $$
BEGIN
    FOR i IN 1..5 LOOP
        update text_table SET text = gen_random_uuid();
    END LOOP;
END;
$$ LANGUAGE plpgsql;

SELECT pg_size_pretty(pg_total_relation_size(text_table));
postgres=# SELECT pg_size_pretty(pg_total_relation_size('text_table'));
 pg_size_pretty 
----------------
 520 MB
(1 row)
```

Отключить Автовакуум на конкретной таблице
10 раз обновить все строчки и добавить к каждой строчке любой символ

```sql
postgres=# alter table text_table set (autovacuum_enabled=off);
ALTER TABLE

DO $$
BEGIN
    FOR i IN 1..10 LOOP
        update text_table SET text = gen_random_uuid() || 'ю';
        RAISE NOTICE 'Шаг %', i;
    END LOOP;
END;
$$ LANGUAGE plpgsql;
```

Посмотреть размер файла с таблицей
Объясните полученный результат
```sql
Нету того парня который бы отметил что tuples свободны и их можно переиспользовать ) Но не в этом дело у меня одна транзакция. Если делать в разных и будет проходить вакуум то таблица не будет расти.

postgres=# SELECT relname, n_live_tup, n_dead_tup, trunc(100*n_dead_tup/(n_live_tup+1))::float "ratio%", last_autovacuum FROM pg_stat_user_tables WHERE relname = 'text_table';
  relname   | n_live_tup | n_dead_tup | ratio% |       last_autovacuum        
------------+------------+------------+--------+------------------------------
 text_table |    1000550 |   10340791 |   1033 | 2024-06-07 14:04:19.24687+00
(1 row)

SELECT pg_size_pretty(pg_total_relation_size('text_table'));
postgres=# SELECT pg_size_pretty(pg_total_relation_size('text_table'));
 pg_size_pretty 
----------------
 957 MB
(1 row)
```

Не забудьте включить автовакуум )

```sql
postgres=# alter table text_table set (autovacuum_enabled=on);
ALTER TABLE
postgres=# SELECT relname, n_live_tup, n_dead_tup, trunc(100*n_dead_tup/(n_live_tup+1))::float "ratio%", last_autovacuum FROM pg_stat_user_tables WHERE relname = 'text_table';\
  relname   | n_live_tup | n_dead_tup | ratio% |        last_autovacuum        
------------+------------+------------+--------+-------------------------------
 text_table |    1002151 |          0 |      0 | 2024-06-07 14:25:38.558017+00
(1 row)
```

Написать анонимную процедуру, в которой в цикле 10 раз обновятся все строчки в искомой таблице.  
Не забыть вывести номер шага цикла.
```sql
DO $$
BEGIN
    FOR i IN 1..10 LOOP
        update text_table SET text = gen_random_uuid() || 'ю';
        RAISE NOTICE 'Шаг %', i;
    END LOOP;
END;
$$ LANGUAGE plpgsql;
```