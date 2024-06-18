## Репликация


Исходное [домашнее задание](./HW10.md "Дз 10")

Развернем 4 VM

```t
pg_main = [
  "10.128.0.4",  # vm1
  "10.128.0.38", # vm2 
  "10.128.0.18", # vm3
  "10.128.0.3",  # vm4
]
```

На 1 ВМ создаем таблицы test для записи, test2 для запросов на чтение.
```sql



> ssh 10.128.0.4

pg_conftool show hba_file
hba_file = '/etc/postgresql/15/main/pg_hba.conf'

echo "host all all 10.128.0.0/24 scram-sha-256" | sudo tee -a /etc/postgresql/15/main/pg_hba.conf
sudo pg_conftool set wal_level logical
sudo systemctl restart postgresql@15-main.service

Скрипт первоначальной настройки для всех 4х VM
for VARIABLE in 10.128.0.4 10.128.0.38 10.128.0.18 10.128.0.3
do
ssh $VARIABLE 'echo "host all all 10.128.0.0/24 scram-sha-256" | sudo tee -a /etc/postgresql/15/main/pg_hba.conf'
ssh $VARIABLE 'sudo pg_conftool set wal_level logical'
ssh $VARIABLE 'sudo pg_conftool set listen_addresses '*';'
ssh $VARIABLE sudo systemctl restart postgresql@15-main.service
done

postgres=# show wal_level;
 wal_level 
-----------
 logical
(1 row)

postgres=# CREATE DATABASE repl;
CREATE DATABASE

postgres=# \c repl ;
You are now connected to database "repl" as user "postgres".

repl=# CREATE TABLE test  (
    id SERIAL PRIMARY KEY,
    text TEXT
);
    CREATE TABLE test2  (
        id SERIAL PRIMARY KEY,
        text TEXT
    );
CREATE TABLE
CREATE TABLE

grant all ON test to repl ;
grant all ON test2 to repl ;

select * from pg_hba_file_rules;

```
Создаем публикацию таблицы test и подписываемся на публикацию таблицы test2 с ВМ №2.
```sql
repl=# create user repl LOGIN REPLICATION PASSWORD '293yhf9hgdws93';
CREATE ROLE

CREATE PUBLICATION test FOR TABLE test;

repl=# CREATE SUBSCRIPTION test2
    CONNECTION 'host=10.128.0.38 port=5432 user=repl dbname=repl password=293yhf9hgdws93'
    PUBLICATION test2;
NOTICE:  created replication slot "test2" on publisher
CREATE SUBSCRIPTION

repl=# select * from pg_replication_origin_status;
 local_id | external_id | remote_lsn | local_lsn 
----------+-------------+------------+-----------
        1 | pg_16414    | 0/0        | 0/0
        2 |             | 0/1968390  | 0/0
(2 rows)

-[ RECORD 1 ]----+------------------------------
pid              | 7911
usesysid         | 16408
usename          | repl
application_name | test
client_addr      | 10.128.0.38
client_hostname  | 
client_port      | 37124
backend_start    | 2024-06-18 06:53:08.401611+00
backend_xmin     | 
state            | streaming
sent_lsn         | 0/1A14760
write_lsn        | 0/1A14760
flush_lsn        | 0/1A14760
replay_lsn       | 0/1A14760
write_lag        | 
flush_lag        | 
replay_lag       | 
sync_priority    | 0
sync_state       | async
reply_time       | 2024-06-18 07:03:32.450956+00
-[ RECORD 2 ]----+------------------------------
pid              | 6516
usesysid         | 16408
usename          | repl
application_name | test31
client_addr      | 10.128.0.18
client_hostname  | 
client_port      | 36400
backend_start    | 2024-06-18 06:17:51.491643+00
backend_xmin     | 
state            | streaming
sent_lsn         | 0/1A14760
write_lsn        | 0/1A14760
flush_lsn        | 0/1A14760
replay_lsn       | 0/1A14760
write_lag        | 
flush_lag        | 
replay_lag       | 
sync_priority    | 0
sync_state       | async
reply_time       | 2024-06-18 07:03:32.445701+00

repl=# insert into test2 values (1, 'hello from vm 1');
INSERT 0 1

repl=# \dRs;
          List of subscriptions
 Name  |  Owner   | Enabled | Publication 
-------+----------+---------+-------------
 test2 | postgres | t       | {test2}
(1 row)

repl=# \dRp;
                               List of publications
 Name |  Owner   | All tables | Inserts | Updates | Deletes | Truncates | Via root 
------+----------+------------+---------+---------+---------+-----------+----------
 test | postgres | f          | t       | t       | t       | t         | f
(1 row)

```
На 2 ВМ создаем таблицы test2 для записи, test для запросов на чтение.
```sql
> ssh 10.128.0.38
Добавим воможность репликации с подсети vm 10.128.0.0/24
> echo 'host    replication     all             10.128.0.0/24           scram-sha-256' | sudo tee -a /etc/postgresql/15/main/pg_hba.conf 
> sudo systemctl restart postgresql@15-main.service
CREATE DATABASE repl;

CREATE TABLE test  (
    id SERIAL PRIMARY KEY,
    text TEXT
);

CREATE TABLE test2  (
    id SERIAL PRIMARY KEY,
    text TEXT
);

grant all ON test to repl ;
grant all ON test2 to repl ;
```

Создаем публикацию таблицы test2 и подписываемся на публикацию таблицы test с ВМ №1.
```sql
repl=# create user repl LOGIN REPLICATION PASSWORD '293yhf9hgdws93';
CREATE ROLE

CREATE PUBLICATION test2 FOR TABLE test2;

repl=# CREATE SUBSCRIPTION test
    CONNECTION 'host=10.128.0.4 port=5432 user=repl dbname=repl password=293yhf9hgdws93'
    PUBLICATION test;
NOTICE:  created replication slot "test" on publisher
CREATE SUBSCRIPTION


repl=# select * from pg_replication_origin_status ;
 local_id | external_id | remote_lsn | local_lsn 
----------+-------------+------------+-----------
        1 | pg_16409    | 0/0        | 0/0
        2 |             | 0/1972A48  | 0/0
(2 rows)


repl=# select * from test;
 id |      text       
----+-----------------
  1 | hello from vm 1
(1 row)

repl=# insert into test2 values (2, 'hello from vm 2');
INSERT 0 1

```

3 ВМ использовать как реплику для чтения и бэкапов (подписаться на таблицы из ВМ №1 и №2 ).
```sql
> ssh 10.128.0.18

CREATE DATABASE repl;

postgres=# \c repl ;
You are now connected to database "repl" as user "postgres".

CREATE TABLE test  (
    id SERIAL PRIMARY KEY,
    text TEXT
);
CREATE TABLE test2  (
    id SERIAL PRIMARY KEY,
    text TEXT
);

grant all ON test to repl ;
grant all ON test2 to repl ;

repl-# \dt;
         List of relations
 Schema | Name  | Type  |  Owner   
--------+-------+-------+----------
 public | test  | table | postgres
 public | test2 | table | postgres
(2 rows)

repl=# CREATE SUBSCRIPTION test31
    CONNECTION 'host=10.128.0.4 port=5432 user=repl dbname=repl password=293yhf9hgdws93'
    PUBLICATION test;
CREATE SUBSCRIPTION test32
    CONNECTION 'host=10.128.0.38 port=5432 user=repl dbname=repl password=293yhf9hgdws93'
    PUBLICATION test2;
NOTICE:  created replication slot "test31" on publisher
CREATE SUBSCRIPTION
NOTICE:  created replication slot "test32" on publisher
CREATE SUBSCRIPTION

repl=# select * from pg_replication_origin;
 roident |  roname  
---------+----------
       1 | pg_16409
       2 | pg_16410
(2 rows)

repl=# select * from test;
 id |      text       
----+-----------------
  1 | hello from vm 1
(1 row)

repl=# select * from test2;
 id |      text       
----+-----------------
  2 | hello from vm 2
(1 row)


repl=# \dRs
           List of subscriptions
  Name  |  Owner   | Enabled | Publication 
--------+----------+---------+-------------
 test31 | postgres | t       | {test}
 test32 | postgres | t       | {test2}
(2 rows)

```


ДЗ сдается в виде миниотчета на гитхабе с описанием шагов и с какими проблемами столкнулись.

* реализовать горячее реплицирование для высокой доступности на 4ВМ. Источником должна выступать ВМ №3. Написать с какими проблемами столкнулись.

```sql
> ssh 10.128.0.3
> pg_lsclusters 
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 online postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log
> sudo systemctl stop postgresql@15-main.service 
> sudo -i -u postgres bash
> rm -fr '/var/lib/postgresql/15/main/*'
> pg_basebackup -R -D /var/lib/postgresql/15/main -h 10.128.0.18 -U repl -W
Password:

> pg_lsclusters 
Ver Cluster Port Status        Owner    Data directory              Log file
15  main    5432 down,recovery postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log

> sudo systemctl start postgresql@15-main.service

-- vm 3
postgres=# select * from pg_stat_replication \gx
-[ RECORD 1 ]----+------------------------------
pid              | 7494
usesysid         | 16388
usename          | repl
application_name | 15/main
client_addr      | 10.128.0.3
client_hostname  | 
client_port      | 60046
backend_start    | 2024-06-18 07:37:31.494863+00
backend_xmin     | 
state            | streaming
sent_lsn         | 0/5000148
write_lsn        | 0/5000148
flush_lsn        | 0/5000148
replay_lsn       | 0/5000148
write_lag        | 
flush_lag        | 
replay_lag       | 
sync_priority    | 0
sync_state       | async
reply_time       | 2024-06-18 07:39:36.07372+00
``` 