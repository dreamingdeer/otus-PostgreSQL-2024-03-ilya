## Бэкапы

Исходное [домашнее задание](./HW09.md "Дз 09")

Создаем ВМ/докер c ПГ.

```
Используем docker-compose из HW04
services:
  db:
    container_name: pgdb
    image: mirror.gcr.io/postgres:14
    restart: always
    environment:
      POSTGRES_USER: ${PG_USER}
      POSTGRES_PASSWORD: ${PG_PASS}
      POSTGRES_DB: ${PG_DB}
    volumes:
      - ./data:/var/lib/postgresql/data
      - ./logs:/var/log/postgresql
      - ./backup:/backup
    networks:
      - pg
    ports:
      - 5000:5432

> podman compose up -d
```

Создаем БД, схему и в ней таблицу.
```sql
postgres=# create database backup;
CREATE DATABASE

postgres=# \c backup 
You are now connected to database "backup" as user "admin".

backup=# create schema XYZ;
CREATE SCHEMA

backup=# CREATE TABLE xyz.bb  (
    id SERIAL PRIMARY KEY,
    text TEXT
);
CREATE TABLE

backup=# INSERT INTO xyz.bb          
SELECT id, MD5(random()::TEXT)::TEXT
FROM generate_series(1, 100) AS id;
INSERT 0 100

backup=# select * from xyz.bb limit 5;
 id |               text               
----+----------------------------------
  1 | ace9d2c68e22f82d6572547b092b8cc3
  2 | ae8991d66ac05871f699a49cb245530e
  3 | 78dfe95607f003333abce946de42fadd
  4 | 190304d25abdfc12a7539d5b911e8423
  5 | 701e08ad0afe7a55e0811b01d3f7b38a
```
Заполним таблицы автосгенерированными 100 записями.
```sql
backup=# INSERT INTO xyz.bb          
SELECT id, MD5(random()::TEXT)::TEXT
FROM generate_series(1, 100) AS id;
INSERT 0 100

backup=# select * from xyz.bb limit 5;
 id |               text               
----+----------------------------------
  1 | ace9d2c68e22f82d6572547b092b8cc3
  2 | ae8991d66ac05871f699a49cb245530e
  3 | 78dfe95607f003333abce946de42fadd
  4 | 190304d25abdfc12a7539d5b911e8423
  5 | 701e08ad0afe7a55e0811b01d3f7b38a
```
Под линукс пользователем Postgres создадим каталог для бэкапов
```sh
> mkdir /backup
> chown -R postgres: /backup
```
Сделаем логический бэкап используя утилиту COPY
```sql
backup=# copy xyz.bb TO '/backup/bb' ;
COPY 100
```
Восстановим в 2 таблицу данные из бэкапа.
```sql
backup=# CREATE TABLE xyz.bb2  (
    id SERIAL PRIMARY KEY,
    text TEXT
);
CREATE TABLE
backup=# copy xyz.bb2 from '/backup/bb' ;
COPY 100
```
Используя утилиту pg_dump создадим бэкап в кастомном сжатом формате двух таблиц
```sql
> podman exec -it pgdb bash
> su - postgres
> pg_dump -Fc -Z -C  -n xyz -f /backup/bkp.gz backup -U admin -W
```
Используя утилиту pg_restore восстановим в новую БД только вторую таблицу!
```sql
backup=# create database bbb;
CREATE DATABASE

> pg_restore -l /backup/bkp.gz 
;
; Archive created at 2024-06-17 15:06:21 UTC
;     dbname: backup
;     TOC Entries: 19
;     Compression: 0
;     Dump Version: 1.14-0
;     Format: CUSTOM
;     Integer: 4 bytes
;     Offset: 8 bytes
;     Dumped from database version: 14.12 (Debian 14.12-1.pgdg120+1)
;     Dumped by pg_dump version: 14.12 (Debian 14.12-1.pgdg120+1)
;
;
; Selected TOC Entries:
;
5; 2615 16385 SCHEMA - xyz admin
211; 1259 16387 TABLE xyz bb admin
213; 1259 16397 TABLE xyz bb2 admin
212; 1259 16396 SEQUENCE xyz bb2_id_seq admin
3351; 0 0 SEQUENCE OWNED BY xyz bb2_id_seq admin
210; 1259 16386 SEQUENCE xyz bb_id_seq admin
3352; 0 0 SEQUENCE OWNED BY xyz bb_id_seq admin
3196; 2604 16423 DEFAULT xyz bb id admin
3197; 2604 16424 DEFAULT xyz bb2 id admin
3342; 0 16387 TABLE DATA xyz bb admin
3344; 0 16397 TABLE DATA xyz bb2 admin
3353; 0 0 SEQUENCE SET xyz bb2_id_seq admin
3354; 0 0 SEQUENCE SET xyz bb_id_seq admin
3201; 2606 16404 CONSTRAINT xyz bb2 bb2_pkey admin
3199; 2606 16394 CONSTRAINT xyz bb bb_pkey admin

pg_restore -l /backup/bkp.gz  > list.xxx


5; 2615 16385 SCHEMA - xyz admin
213; 1259 16397 TABLE xyz bb2 admin
212; 1259 16396 SEQUENCE xyz bb2_id_seq admin
3351; 0 0 SEQUENCE OWNED BY xyz bb2_id_seq admin
3197; 2604 16424 DEFAULT xyz bb2 id admin
3344; 0 16397 TABLE DATA xyz bb2 admin
3353; 0 0 SEQUENCE SET xyz bb2_id_seq admin
3201; 2606 16404 CONSTRAINT xyz bb2 bb2_pkey admin


pg_restore -L list.xxx -d bbb -U admin -W /backup/bkp.gz

bbb=# \dt xyz.*
       List of relations
 Schema | Name | Type  | Owner 
--------+------+-------+-------
 xyz    | bb2  | table | admin
(1 row)
```