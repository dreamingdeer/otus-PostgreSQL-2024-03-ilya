## PostgreSQL Работа с базами данных, пользователями и правами

Исходное [домашнее задание](./HW04.md "Дз 03")

В качестве стенда будем использовать локально [docker-compose](./docker-compose.yaml)

Для удобства подключения к контейнреу будем использовать alias на хосте у меня нету psql и когда мажорные версии клиента и сервера совпадают это всегда хорошо )
```
alias pcadmin 'podman run --rm -it --network db --env-file .env postgres:14 bash -c \'export PGPASSWORD=$PG_PASS; psql -h db -U $PG_USER $PG_DB\''
alias psql 'podman run --rm -it --network db postgres:14 psql $argv'
```

создайте новый кластер PostgresSQL 14  
зайдите в созданный кластер под пользователем postgres
```sh
> podman compose up -d
>>>> Executing external compose provider "/usr/bin/podman-compose". Please refer to the documentation for details. <<<<

a2ea5c22c042624443f6983b17a3951cedfc85ad35ca406616a3a020ec930dc3
f834bd2c33d133121bd302888ae8691997e27b3a42b93da28a90c587264e68b9
29522a381b61e148980f610f14193cf2ff88e4923be5e743b18df0b8e906c688
pghw1_pgweb_1

> podman ps
CONTAINER ID  IMAGE                            COMMAND     CREATED         STATUS         PORTS                   NAMES
f834bd2c33d1  mirror.gcr.io/postgres:14        postgres    23 seconds ago  Up 23 seconds  0.0.0.0:5000->5432/tcp  pgdb
29522a381b61  docker.io/sosedoff/pgweb:latest              22 seconds ago  Up 21 seconds  0.0.0.0:7070->8081/tcp  pghw1_pgweb_1

> pcadmin 
psql (14.12 (Debian 14.12-1.pgdg120+1))
Type "help" for help.

postgres=# 
```
создайте новую базу данных testdb

```sql
postgres=# create database testdb;
CREATE DATABASE
postgres=#
```
зайдите в созданную базу данных под пользователем postgres (у меня будет admin)

```sql
postgres=# \c testdb 
You are now connected to database "testdb" as user "admin".
postgres=# select current_user;
 current_user 
--------------
 admin
(1 row)
```
создайте новую схему testnm
```sql
testdb=# create schema testnm;
CREATE SCHEMA
testdb=# \dn
List of schemas
  Name  | Owner 
--------+-------
 public | admin
 testnm | admin
(2 rows)
```
создайте новую таблицу t1 с одной колонкой c1 типа integer
```sql
testdb=# create table t1 ( c1 integer )
testdb-# ;
CREATE TABLE
testdb=# \dt t1
       List of relations
 Schema | Name | Type  | Owner 
--------+------+-------+-------
 public | t1   | table | admin
(1 row)

testdb=# \d t1
                 Table "public.t1"
 Column |  Type   | Collation | Nullable | Default 
--------+---------+-----------+----------+---------
 c1     | integer |           |          | 

```
вставьте строку со значением c1=1
```sql
testdb=# insert into t1 values (1);
INSERT 0 1
testdb=# select * from t1;
 c1 
----
  1
(1 row)
```
создайте новую роль readonly
```sql
testdb=# create role readonly;
CREATE ROLE
testdb=# \du
                                   List of roles
 Role name |                         Attributes                         | Member of 
-----------+------------------------------------------------------------+-----------
 admin     | Superuser, Create role, Create DB, Replication, Bypass RLS | {}
 readonly  | Cannot login                                               | {}
```
дайте новой роли право на подключение к базе данных testdb  
дайте новой роли право на использование схемы testnms  
дайте новой роли право на select для всех таблиц схемы testnm

```sql
testdb=# grant CONNECT ON DATABASE testdb TO readonly ;
GRANT
testdb=# grant USAGE ON SCHEMA testnm TO readonly ;
GRANT
testdb=# grant SELECT ON ALL TABLES IN SCHEMA testnm TO readonly ;
GRANT
```
создайте пользователя testread с паролем test123
```sql
testdb=# create user testread with password 'test123';
CREATE ROLE
testdb=# \du testread 
           List of roles
 Role name | Attributes | Member of 
-----------+------------+-----------
 testread  |            | {}
```
дайте роль readonly пользователю testread
```sql
testdb=# grant readonly TO testread ;
GRANT ROLE
testdb=# \du testread 
            List of roles
 Role name | Attributes | Member of  
-----------+------------+------------
 testread  |            | {readonly}
```
зайдите под пользователем testread в базу данных testdb
```sql
> psql -h db -d testdb -U testread 
Password for user testread: 
psql (14.12 (Debian 14.12-1.pgdg120+1))
Type "help" for help.

testdb=> 
```
сделайте select * from t1;
```sql
testdb=> select * from t1;
ERROR:  permission denied for table t1
```
получилось? (могло если вы делали сами не по шпаргалке и не упустили один существенный момент про который позже)  
напишите что именно произошло в тексте домашнего задания
у вас есть идеи почему? ведь права то дали?
посмотрите на список таблиц подсказка в шпаргалке под пунктом 20 а почему так получилось с таблицей (если делали сами и без шпаргалки то может у вас все нормально)
```sql
Коречно нет ) Потому что таблица в другой схеме. Схема не была явно указана. по умолчанию дефолт public 

testdb=> \dt public.t1 
       List of relations
 Schema | Name | Type  | Owner 
--------+------+-------+-------
 public | t1   | table | admin
(1 row)
testdb=> \dn+
                       List of schemas
  Name  | Owner | Access privileges |      Description       
--------+-------+-------------------+------------------------
 public | admin | admin=UC/admin   +| standard public schema
        |       | =UC/admin         | 
 testnm | admin | admin=UC/admin   +| 
        |       | readonly=U/admin  | 
(2 rows)
```
вернитесь в базу данных testdb под пользователем postgres
удалите таблицу t1
```sql
testdb=# drop table t1 ;
DROP TABLE
```
создайте ее заново но уже с явным указанием имени схемы testnm  
вставьте строку со значением c1=1

```sql
testdb=# create table testnm.t1 ( c1 integer );
CREATE TABLE
testdb=# \d t1
Did not find any relation named "t1".
testdb=# \d testnm.t1
                 Table "testnm.t1"
 Column |  Type   | Collation | Nullable | Default 
--------+---------+-----------+----------+---------
 c1     | integer |           |          | 

testdb=# insert into testnm.t1 values (1);
INSERT 0 1

testdb=# select * from testnm.t1 ;
 c1 
----
  1
(1 row)
```
зайдите под пользователем testread в базу данных testdb
сделайте select * from testnm.t1;
получилось?
```sql
testdb=> select * from testnm.t1;
ERROR:  permission denied for table t1
```
есть идеи почему? если нет - смотрите шпаргалку
```sql
Таблица создана после предоставления прав SELECT выше, а по умолчанию права только владельцу.

testdb=> \ddp testnm
         Default access privileges
 Owner | Schema | Type | Access privileges 
-------+--------+------+-------------------
(0 rows)
```
как сделать так чтобы такое больше не повторялось? если нет идей - смотрите шпаргалку

```sql
изменить default привилегии для схемы testnm
testdb=# alter default privileges IN SCHEMA testnm GRANT SELECT ON TABLES TO readonly;
ALTER DEFAULT PRIVILEGES
```

сделайте select * from testnm.t1;  
получилось?  
есть идеи почему? если нет - смотрите шпаргалку  

```sql
testdb=> select * from testnm.t1;
ERROR:  permission denied for table t1

> Все так же, таблица создана после изменения схемы. При создании таблицы выдаются права. Обычно только owner. 
 
select * from pg_catalog.pg_default_acl
testdb-# ;
  oid  | defaclrole | defaclnamespace | defaclobjtype |     defaclacl      
-------+------------+-----------------+---------------+--------------------
 16394 |         10 |           16385 | r             | {readonly=r/admin}
(1 row)


> Если создать сейчас таблицу в схеме testnm то все будет ок
testdb=# create table testnm.t2 ( c1 integer);
CREATE TABLE

testdb=> \dp testnm.t2 
                             Access privileges
 Schema | Name | Type  |  Access privileges  | Column privileges | Policies 
--------+------+-------+---------------------+-------------------+----------
 testnm | t2   | table | admin=arwdDxt/admin+|                   | 
        |      |       | readonly=r/admin    |                   | 


testdb=> select * from testnm.t2;
 c1 
----
(0 rows)

> Заново выдадим права роли readonly на чтение всех существующих таблиц

testdb=# grant SELECT ON ALL TABLES IN SCHEMA testnm TO readonly;
GRANT
```

сделайте select * from testnm.t1;
получилось?

```sql
Конечно получилось )
testdb=> \dp testnm.t1
                             Access privileges
 Schema | Name | Type  |  Access privileges  | Column privileges | Policies 
--------+------+-------+---------------------+-------------------+----------
 testnm | t1   | table | admin=arwdDxt/admin+|                   | 
        |      |       | readonly=r/admin    |                   | 
(1 row)

testdb=> select * from testnm.t1;
 c1 
----
  1
(1 row)
```
теперь попробуйте выполнить команду create table t2(c1 integer); insert into t2 values (2);
```
> Успешный успех по тому что по умолчанию даются права на схему default всем пользователям.

testdb=> create table t2(c1 integer); insert into t2 values (2);
CREATE TABLE
INSERT 0 1

testdb=> \dt
        List of relations
 Schema | Name | Type  |  Owner   
--------+------+-------+----------
 public | t2   | table | testread
(1 row)

testdb=> select * from pg_catalog.pg_namespace 
testdb-> ;
  oid  |      nspname       | nspowner |              nspacl               
-------+--------------------+----------+-----------------------------------
    99 | pg_toast           |       10 | 
    11 | pg_catalog         |       10 | {admin=UC/admin,=U/admin}
  2200 | public             |       10 | {admin=UC/admin,=UC/admin}
 13414 | information_schema |       10 | {admin=UC/admin,=U/admin}
 16385 | testnm             |       10 | {admin=UC/admin,readonly=U/admin}
 16401 | bla                |       10 | 
(6 rows)
```
есть идеи как убрать эти права? если нет - смотрите шпаргалку
```sql
Отобрать права на схему паблик )
testdb=# REVOKE CREATE on SCHEMA public FROM PUBLIC ;
REVOKE
testdb=# REVOKE ALL on DATABASE testdb FROM public; 
REVOKE

testdb=# select * from pg_catalog.pg_namespace ;
  oid  |      nspname       | nspowner |              nspacl               
-------+--------------------+----------+-----------------------------------
    99 | pg_toast           |       10 | 
    11 | pg_catalog         |       10 | {admin=UC/admin,=U/admin}
 13414 | information_schema |       10 | {admin=UC/admin,=U/admin}
 16385 | testnm             |       10 | {admin=UC/admin,readonly=U/admin}
  2200 | public             |       10 | {admin=UC/admin,=U/admin}
(5 rows)

> Теперь любой пользователь не может создавать в public ) 
```
теперь попробуйте выполнить команду create table t3(c1 integer); insert into t2 values (2);  
расскажите что получилось и почему 
```sql
> А теперь нельзя создать - нету прав всем на содание обьектов в public схеме {admin=UC/admin,=U/admin}

testdb=> create table t4(c1 integer); insert into t2 values (2);
ERROR:  permission denied for schema public
LINE 1: create table t4(c1 integer);
                     ^
INSERT 0 1
```