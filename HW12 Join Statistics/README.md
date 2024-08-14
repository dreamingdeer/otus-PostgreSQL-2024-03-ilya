## Работа с join'ами, статистикой

Исходное [домашнее задание](./HW12.md "Дз 12")

Возьмем схему из предыдущего домашнего задания 

```
CREATE TABLE public.vm (
	vm_id bigint,
	name varchar(255),
	ip inet,
	created_at timestamp,
	CONSTRAINT vm_pk PRIMARY KEY (vm_id)
);

CREATE TABLE public."user" (
	user_id bigint,
	login varchar(255),
	surname varchar(255),
	name varchar(255),
	lastname varchar(255),
	CONSTRAINT user_pk PRIMARY KEY (user_id)
);


CREATE TABLE public.session (
	session_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ,
	start_at timestamp,
	end_at timestamp,
	ip inet,
	vm_id_vm bigint,
	user_id_user bigint,
	CONSTRAINT session_pk PRIMARY KEY (session_id)
);


Сгенерируем пользователей
INSERT INTO "user"
SELECT id, MD5(random()::TEXT)::TEXT, MD5(random()::TEXT)::TEXT, MD5(random()::TEXT)::TEXT, MD5(random()::TEXT)::TEXT
FROM generate_series(100, 200) AS id;
INSERT 0 101

postgres=# select user_id,login from "user" limit 5;
 user_id |              login
---------+----------------------------------
     100 | c31b28ba357f8a0af4cd7e51c0a00a48
     101 | 670b4638c90c58d49b9660e744ac124f
     102 | e9a75fd112cba5998cb91c5bf266164c
     103 | 99d549042d65680f40802e10cbc5dffd
     104 | 31270567e2f4491acc2242325e79cf53
(5 rows)

Сгенерируем виртуальные машины
INSERT INTO "vm"
SELECT id, MD5(random()::TEXT)::TEXT, '192.168.0.1'::inet+id-1000, NOW() + (random() * (NOW()+'90 days' - NOW())) + '30 days'
FROM generate_series(1000, 1200) AS id;
INSERT 0 201

postgres=# select * from vm limit 5;
 vm_id |               name               |     ip      |         created_at
-------+----------------------------------+-------------+----------------------------
  1000 | e986254fd7ce31c9c93ee406208d0dc5 | 192.168.0.1 | 2024-09-13 19:09:44.157258
  1001 | 6481e4deb4fc6399390cc0d27d5463fa | 192.168.0.2 | 2024-09-27 15:47:11.829621
  1002 | 47f82127d9e0aedea8bb66dc1d5d73b1 | 192.168.0.3 | 2024-11-10 20:51:36.002969
  1003 | c694d09eb8791c524c57433c7faba6d4 | 192.168.0.4 | 2024-10-30 14:54:51.949595
  1004 | 858e31cb569ddc53d25c10c64e705ffc | 192.168.0.5 | 2024-12-06 07:42:09.247779
(5 rows)

Логины на вм
postgres=# insert into session(start_at,end_at,ip,vm_id_vm,user_id_user) select NOW() + (random() * (NOW()+'-90 days' - NOW())) + '-30 days',NOW() + (random() * (NOW()+'90 days' - NOW())) + '30 days','172.16.0.1'::inet+(random()*10000)::integer,1000+id,100+id
FROM generate_series(1, 20) AS id;
INSERT 0 20

Допустим у нас был админ и он ходил на все
postgres=# insert into session(start_at,end_at,ip,vm_id_vm,user_id_user) select NOW() + (random() * (NOW()+'-90 days' - NOW())) + '-30 days',NOW() + (random() * (NOW()+'90 days' - NOW())) + '30 days','172.16.0.1'::inet+(random()*10000)::integer,1000+id,100
FROM generate_series(1, 20) AS id;
INSERT 0 20

postgres=# select * from session limit 5;
 session_id |          start_at          |           end_at           |      ip       | vm_id_vm | user_id_user
------------+----------------------------+----------------------------+---------------+----------+--------------
          1 | 2024-05-22 21:33:50.705854 | 2024-10-13 10:48:33.43494  | 172.16.10.233 |     1001 |          101
          2 | 2024-06-04 08:52:40.281806 | 2024-11-12 22:19:26.840698 | 172.16.16.58  |     1002 |          102
          3 | 2024-06-17 14:44:11.385724 | 2024-10-31 16:21:40.796105 | 172.16.7.226  |     1003 |          103
          4 | 2024-05-06 16:25:57.58229  | 2024-10-14 04:31:07.315166 | 172.16.22.23  |     1004 |          104
          5 | 2024-05-14 11:11:21.563956 | 2024-09-30 14:58:24.528406 | 172.16.14.215 |     1005 |          105
(5 rows)

```
- Реализовать прямое соединение двух или более таблиц

"STRAIGHT_JOIN is similar to JOIN, except that the left table is always read before the right table. This can be used for those (few) cases for which the join optimizer puts the tables in the wrong order."


> Получим сессии пользователей с проведенным временем
```sql
postgres=# select session_id,user_id,login,s.ip as from_ip,end_at-start_at as timespend 
from session s inner join "user" u on u.user_id = s.user_id_user 
limit 30;
 session_id | user_id |              login               |    from_ip    |        timespend
------------+---------+----------------------------------+---------------+--------------------------
         40 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.9.89   | 183 days 08:06:09.920146
         21 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.18.151 | 87 days 09:21:44.525695
         22 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.33.200 | 212 days 13:42:24.69426
         23 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.15.176 | 139 days 02:58:49.220824
         24 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.26.224 | 120 days 10:35:37.916827
         25 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.17.117 | 204 days 22:05:19.590449
         26 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.13.72  | 164 days 03:05:44.231542
         27 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.4.230  | 156 days 01:52:32.874509
         28 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.38.246 | 87 days 13:04:45.921973
         29 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.3.188  | 193 days 04:10:07.738937
         30 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.25.226 | 211 days 15:34:22.287993
         31 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.17.223 | 110 days 17:03:25.891715
         32 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.37.71  | 179 days 00:24:35.879978
         33 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.11.26  | 110 days 22:53:04.273756
         34 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.12.6   | 178 days 01:24:42.794127
         35 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.12.123 | 205 days 19:52:23.637379
         36 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.0.37   | 208 days 19:08:40.249301
         37 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.5.30   | 153 days 06:34:02.031961
         38 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.24.200 | 159 days 16:48:55.728513
         39 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.30.82  | 144 days 16:22:09.096879
          1 |     101 | 15ef677448121b05e4fa8bb90f5db488 | 172.16.10.233 | 143 days 13:14:42.729086
          2 |     102 | 2de14747364085d30aeb262680b6a8b6 | 172.16.16.58  | 161 days 13:26:46.558892
          3 |     103 | ccc478d451b529eb4b2fee8c7832b7b3 | 172.16.7.226  | 136 days 01:37:29.410381
          4 |     104 | e23ebdaefdc8a3731f93f9d6673c84cd | 172.16.22.23  | 160 days 12:05:09.732876
          5 |     105 | 7d1f036cb03137843d09350a27945ad7 | 172.16.14.215 | 139 days 03:47:02.96445
          6 |     106 | 683019bccf31772fa6a1491f5f7749b1 | 172.16.19.53  | 207 days 20:07:07.621939
          7 |     107 | db953ccae7e04b701e788a89e4a1af77 | 172.16.9.49   | 185 days 06:08:43.205269
          8 |     108 | db75f8ad611ef272ae3bc7a792baef88 | 172.16.37.198 | 200 days 06:41:37.258294
          9 |     109 | f69382dca7c54921f5bdcf819d1775b7 | 172.16.5.146  | 154 days 11:14:40.109694
         10 |     110 | cbd7d76227c0de299587f14b2a0dd482 | 172.16.11.148 | 191 days 07:59:19.494845
```
> Странная сортировка. 
> А давайте SET enable_mergejoin = off; и посмотрим разницу плана запросов с статистикой в постгресе и без нее:
```sql
postgres=# explain select session_id,user_id,login,s.ip as from_ip,end_at-start_at as timespend 
from session s inner join "user" u on u.user_id = s.user_id_user 
limit 30;
                                 QUERY PLAN
-----------------------------------------------------------------------------
 Limit  (cost=1.45..6.09 rows=20 width=72)
   ->  Hash Join  (cost=1.45..6.09 rows=20 width=72)
         Hash Cond: (u.user_id = s.user_id_user)
         ->  Seq Scan on "user" u  (cost=0.00..4.01 rows=101 width=41)
         ->  Hash  (cost=1.20..1.20 rows=20 width=39)
               ->  Seq Scan on session s  (cost=0.00..1.20 rows=20 width=39)

ANALYZE;
postgres=# select * from pg_stat_user_tables \gx
-[ RECORD 1 ]-------+------------------------------
relid               | 16492
schemaname          | public
relname             | session
seq_scan            | 23
seq_tup_read        | 760
idx_scan            | 0
idx_tup_fetch       | 0
n_tup_ins           | 80
n_tup_upd           | 0
n_tup_del           | 0
n_tup_hot_upd       | 0
n_live_tup          | 40
n_dead_tup          | 0
n_mod_since_analyze | 0
n_ins_since_vacuum  | 40
last_vacuum         |
last_autovacuum     |
last_analyze        | 2024-08-13 13:35:59.890522+00
last_autoanalyze    | 2024-08-13 13:01:38.926179+00
vacuum_count        | 0
autovacuum_count    | 0
analyze_count       | 2
autoanalyze_count   | 1
-[ RECORD 2 ]-------+------------------------------
relid               | 16484
schemaname          | public
relname             | user
seq_scan            | 6
seq_tup_read        | 325
idx_scan            | 31
idx_tup_fetch       | 250
n_tup_ins           | 101
n_tup_upd           | 0
n_tup_del           | 0
n_tup_hot_upd       | 0
n_live_tup          | 101
n_dead_tup          | 0
n_mod_since_analyze | 0
n_ins_since_vacuum  | 101
last_vacuum         |
last_autovacuum     |
last_analyze        | 2024-08-13 13:35:59.879625+00
last_autoanalyze    | 2024-08-13 12:59:38.859257+00
vacuum_count        | 0
autovacuum_count    | 0
analyze_count       | 2
autoanalyze_count   | 1
-[ RECORD 3 ]-------+------------------------------
relid               | 16477
schemaname          | public
relname             | vm
seq_scan            | 2
seq_tup_read        | 5
idx_scan            | 0
idx_tup_fetch       | 0
n_tup_ins           | 201
n_tup_upd           | 0
n_tup_del           | 0
n_tup_hot_upd       | 0
n_live_tup          | 201
n_dead_tup          | 0
n_mod_since_analyze | 0
n_ins_since_vacuum  | 201
last_vacuum         |
last_autovacuum     |
last_analyze        | 2024-08-13 13:35:59.889709+00
last_autoanalyze    | 2024-08-13 13:00:38.873858+00
vacuum_count        | 0
autovacuum_count    | 0
analyze_count       | 2
autoanalyze_count   | 1
```
> Теперь хитрый postgres имеет представление о том сколько данных в таблицах и строит уже совсем другой план запроса. А так же в выдаче мы получим уже другой порядок записей.
```sql
postgres=# explain select session_id,user_id,login,s.ip as from_ip,end_at-start_at as timespend 
from session s 
inner join "user" u on u.user_id = s.user_id_user 
limit 30;
                                 QUERY PLAN
-----------------------------------------------------------------------------
 Limit  (cost=5.27..6.48 rows=30 width=72)
   ->  Hash Join  (cost=5.27..6.88 rows=40 width=72)
         Hash Cond: (s.user_id_user = u.user_id)
         ->  Seq Scan on session s  (cost=0.00..1.40 rows=40 width=39)
         ->  Hash  (cost=4.01..4.01 rows=101 width=41)
               ->  Seq Scan on "user" u  (cost=0.00..4.01 rows=101 width=41)
(6 rows)


postgres=# select session_id,user_id,login,s.ip as from_ip,end_at-start_at as timespend 
from session s 
inner join "user" u on u.user_id = s.user_id_user 
limit 30;

 session_id | user_id |              login               |    from_ip    |        timespend
------------+---------+----------------------------------+---------------+--------------------------
          1 |     101 | 15ef677448121b05e4fa8bb90f5db488 | 172.16.10.233 | 143 days 13:14:42.729086
          2 |     102 | 2de14747364085d30aeb262680b6a8b6 | 172.16.16.58  | 161 days 13:26:46.558892
          3 |     103 | ccc478d451b529eb4b2fee8c7832b7b3 | 172.16.7.226  | 136 days 01:37:29.410381
          4 |     104 | e23ebdaefdc8a3731f93f9d6673c84cd | 172.16.22.23  | 160 days 12:05:09.732876
          5 |     105 | 7d1f036cb03137843d09350a27945ad7 | 172.16.14.215 | 139 days 03:47:02.96445
          6 |     106 | 683019bccf31772fa6a1491f5f7749b1 | 172.16.19.53  | 207 days 20:07:07.621939
          7 |     107 | db953ccae7e04b701e788a89e4a1af77 | 172.16.9.49   | 185 days 06:08:43.205269
          8 |     108 | db75f8ad611ef272ae3bc7a792baef88 | 172.16.37.198 | 200 days 06:41:37.258294
          9 |     109 | f69382dca7c54921f5bdcf819d1775b7 | 172.16.5.146  | 154 days 11:14:40.109694
         10 |     110 | cbd7d76227c0de299587f14b2a0dd482 | 172.16.11.148 | 191 days 07:59:19.494845
         11 |     111 | f39511320f80369707c32cf1217d4054 | 172.16.29.139 | 136 days 04:11:38.014355
         12 |     112 | d75c15fd843b1c43d31604a46c22e754 | 172.16.21.61  | 130 days 15:41:19.253019
         13 |     113 | 0589e85441499a36561d48ba995261c9 | 172.16.18.55  | 166 days 10:23:53.058434
         14 |     114 | 0424595e377eb34f2144999a16140b60 | 172.16.9.61   | 113 days 03:57:15.757445
         15 |     115 | fb809895aa6415341c13b57c05115c26 | 172.16.16.45  | 178 days 08:20:36.773885
         16 |     116 | f3c0974d58aadd8f6db46ad37a189cf0 | 172.16.15.22  | 199 days 01:34:19.294509
         17 |     117 | 0993f1b5776be3fee998b34f3c8760b7 | 172.16.27.26  | 81 days 04:12:17.064496
         18 |     118 | ea9139d6d89c266cc6051a70ac2ea0ba | 172.16.20.154 | 139 days 08:24:09.780612
         19 |     119 | 7d9cdad6ba8d4a8c3e5d00817a4a0e12 | 172.16.15.5   | 200 days 08:26:07.01516
         20 |     120 | d65f566055a9a54ae054d5b354ee8d9b | 172.16.27.165 | 104 days 13:28:52.824867
         21 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.18.151 | 87 days 09:21:44.525695
         22 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.33.200 | 212 days 13:42:24.69426
         23 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.15.176 | 139 days 02:58:49.220824
         24 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.26.224 | 120 days 10:35:37.916827
         25 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.17.117 | 204 days 22:05:19.590449
         26 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.13.72  | 164 days 03:05:44.231542
         27 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.4.230  | 156 days 01:52:32.874509
         28 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.38.246 | 87 days 13:04:45.921973
         29 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.3.188  | 193 days 04:10:07.738937
         30 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.25.226 | 211 days 15:34:22.287993
(30 rows)
```



- Реализовать левостороннее (или правостороннее)
соединение двух или более таблиц

> Так как у нас таблица сессия слабая сущность то получим такой же результат как и прямое соединение
```sql
postgres=# select session_id,user_id,login,s.ip as from_ip,end_at-start_at as timespend 
from session s 
left join "user" u on u.user_id = s.user_id_user;
 session_id | user_id |              login               |    from_ip    |        timespend
------------+---------+----------------------------------+---------------+--------------------------
         40 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.9.89   | 183 days 08:06:09.920146
         21 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.18.151 | 87 days 09:21:44.525695
         22 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.33.200 | 212 days 13:42:24.69426
         23 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.15.176 | 139 days 02:58:49.220824
         24 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.26.224 | 120 days 10:35:37.916827
         25 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.17.117 | 204 days 22:05:19.590449
         26 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.13.72  | 164 days 03:05:44.231542
         27 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.4.230  | 156 days 01:52:32.874509
         28 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.38.246 | 87 days 13:04:45.921973
         29 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.3.188  | 193 days 04:10:07.738937
         30 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.25.226 | 211 days 15:34:22.287993
         31 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.17.223 | 110 days 17:03:25.891715
         32 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.37.71  | 179 days 00:24:35.879978
         33 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.11.26  | 110 days 22:53:04.273756
         34 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.12.6   | 178 days 01:24:42.794127
         35 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.12.123 | 205 days 19:52:23.637379
         36 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.0.37   | 208 days 19:08:40.249301
         37 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.5.30   | 153 days 06:34:02.031961
         38 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.24.200 | 159 days 16:48:55.728513
         39 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.30.82  | 144 days 16:22:09.096879
          1 |     101 | 15ef677448121b05e4fa8bb90f5db488 | 172.16.10.233 | 143 days 13:14:42.729086
          2 |     102 | 2de14747364085d30aeb262680b6a8b6 | 172.16.16.58  | 161 days 13:26:46.558892
          3 |     103 | ccc478d451b529eb4b2fee8c7832b7b3 | 172.16.7.226  | 136 days 01:37:29.410381
          4 |     104 | e23ebdaefdc8a3731f93f9d6673c84cd | 172.16.22.23  | 160 days 12:05:09.732876
          5 |     105 | 7d1f036cb03137843d09350a27945ad7 | 172.16.14.215 | 139 days 03:47:02.96445
          6 |     106 | 683019bccf31772fa6a1491f5f7749b1 | 172.16.19.53  | 207 days 20:07:07.621939
          7 |     107 | db953ccae7e04b701e788a89e4a1af77 | 172.16.9.49   | 185 days 06:08:43.205269
          8 |     108 | db75f8ad611ef272ae3bc7a792baef88 | 172.16.37.198 | 200 days 06:41:37.258294
          9 |     109 | f69382dca7c54921f5bdcf819d1775b7 | 172.16.5.146  | 154 days 11:14:40.109694
         10 |     110 | cbd7d76227c0de299587f14b2a0dd482 | 172.16.11.148 | 191 days 07:59:19.494845
         11 |     111 | f39511320f80369707c32cf1217d4054 | 172.16.29.139 | 136 days 04:11:38.014355
         12 |     112 | d75c15fd843b1c43d31604a46c22e754 | 172.16.21.61  | 130 days 15:41:19.253019
         13 |     113 | 0589e85441499a36561d48ba995261c9 | 172.16.18.55  | 166 days 10:23:53.058434
         14 |     114 | 0424595e377eb34f2144999a16140b60 | 172.16.9.61   | 113 days 03:57:15.757445
         15 |     115 | fb809895aa6415341c13b57c05115c26 | 172.16.16.45  | 178 days 08:20:36.773885
         16 |     116 | f3c0974d58aadd8f6db46ad37a189cf0 | 172.16.15.22  | 199 days 01:34:19.294509
         17 |     117 | 0993f1b5776be3fee998b34f3c8760b7 | 172.16.27.26  | 81 days 04:12:17.064496
         18 |     118 | ea9139d6d89c266cc6051a70ac2ea0ba | 172.16.20.154 | 139 days 08:24:09.780612
         19 |     119 | 7d9cdad6ba8d4a8c3e5d00817a4a0e12 | 172.16.15.5   | 200 days 08:26:07.01516
         20 |     120 | d65f566055a9a54ae054d5b354ee8d9b | 172.16.27.165 | 104 days 13:28:52.824867
(40 rows)
```
> Правостороннее - а вот так как у нас есть пользователи без сессий то получим больше записей
```sql
postgres=# select session_id,user_id,login,s.ip as from_ip,end_at-start_at as timespend 
from session s 
right join "user" u on u.user_id = s.user_id_user;
 session_id | user_id |              login               |    from_ip    |        timespend
------------+---------+----------------------------------+---------------+--------------------------
          1 |     101 | 15ef677448121b05e4fa8bb90f5db488 | 172.16.10.233 | 143 days 13:14:42.729086
          2 |     102 | 2de14747364085d30aeb262680b6a8b6 | 172.16.16.58  | 161 days 13:26:46.558892
          3 |     103 | ccc478d451b529eb4b2fee8c7832b7b3 | 172.16.7.226  | 136 days 01:37:29.410381
          4 |     104 | e23ebdaefdc8a3731f93f9d6673c84cd | 172.16.22.23  | 160 days 12:05:09.732876
          5 |     105 | 7d1f036cb03137843d09350a27945ad7 | 172.16.14.215 | 139 days 03:47:02.96445
          6 |     106 | 683019bccf31772fa6a1491f5f7749b1 | 172.16.19.53  | 207 days 20:07:07.621939
          7 |     107 | db953ccae7e04b701e788a89e4a1af77 | 172.16.9.49   | 185 days 06:08:43.205269
          8 |     108 | db75f8ad611ef272ae3bc7a792baef88 | 172.16.37.198 | 200 days 06:41:37.258294
          9 |     109 | f69382dca7c54921f5bdcf819d1775b7 | 172.16.5.146  | 154 days 11:14:40.109694
         10 |     110 | cbd7d76227c0de299587f14b2a0dd482 | 172.16.11.148 | 191 days 07:59:19.494845
         11 |     111 | f39511320f80369707c32cf1217d4054 | 172.16.29.139 | 136 days 04:11:38.014355
         12 |     112 | d75c15fd843b1c43d31604a46c22e754 | 172.16.21.61  | 130 days 15:41:19.253019
         13 |     113 | 0589e85441499a36561d48ba995261c9 | 172.16.18.55  | 166 days 10:23:53.058434
         14 |     114 | 0424595e377eb34f2144999a16140b60 | 172.16.9.61   | 113 days 03:57:15.757445
         15 |     115 | fb809895aa6415341c13b57c05115c26 | 172.16.16.45  | 178 days 08:20:36.773885
         16 |     116 | f3c0974d58aadd8f6db46ad37a189cf0 | 172.16.15.22  | 199 days 01:34:19.294509
         17 |     117 | 0993f1b5776be3fee998b34f3c8760b7 | 172.16.27.26  | 81 days 04:12:17.064496
         18 |     118 | ea9139d6d89c266cc6051a70ac2ea0ba | 172.16.20.154 | 139 days 08:24:09.780612
         19 |     119 | 7d9cdad6ba8d4a8c3e5d00817a4a0e12 | 172.16.15.5   | 200 days 08:26:07.01516
         20 |     120 | d65f566055a9a54ae054d5b354ee8d9b | 172.16.27.165 | 104 days 13:28:52.824867
         21 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.18.151 | 87 days 09:21:44.525695
         22 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.33.200 | 212 days 13:42:24.69426
         23 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.15.176 | 139 days 02:58:49.220824
         24 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.26.224 | 120 days 10:35:37.916827
         25 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.17.117 | 204 days 22:05:19.590449
         26 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.13.72  | 164 days 03:05:44.231542
         27 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.4.230  | 156 days 01:52:32.874509
         28 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.38.246 | 87 days 13:04:45.921973
         29 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.3.188  | 193 days 04:10:07.738937
         30 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.25.226 | 211 days 15:34:22.287993
         31 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.17.223 | 110 days 17:03:25.891715
         32 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.37.71  | 179 days 00:24:35.879978
         33 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.11.26  | 110 days 22:53:04.273756
         34 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.12.6   | 178 days 01:24:42.794127
         35 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.12.123 | 205 days 19:52:23.637379
         36 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.0.37   | 208 days 19:08:40.249301
         37 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.5.30   | 153 days 06:34:02.031961
         38 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.24.200 | 159 days 16:48:55.728513
         39 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.30.82  | 144 days 16:22:09.096879
         40 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.9.89   | 183 days 08:06:09.920146
            |     151 | 3e0634d020bf6530647c82c20f9fcedc |               |
            <  cut  >
            |     183 | a055d89abe08b51d9966c43a8d03ce38 |               |
            |     130 | a9f0f55a96b7178a5f5477850c8d3b48 |               |
            |     144 | 1255df530a409f29d5d2bd4c0b254f64 |               |
(120 rows)
```

- Реализовать кросс соединение двух или более таблиц
> Потенциально возможные "логины" в сессиях с вм с адресом 192.168.0.201
```sql
postgres=# select v.ip,u.login 
from vm v 
cross join "user" u 
where v.ip='192.168.0.201';

      ip       |              login
---------------+----------------------------------
 192.168.0.201 | eb5c6fda5bde721e91844a19b984c594
 192.168.0.201 | 15ef677448121b05e4fa8bb90f5db488
 192.168.0.201 | 2de14747364085d30aeb262680b6a8b6
 192.168.0.201 | ccc478d451b529eb4b2fee8c7832b7b3
 192.168.0.201 | e23ebdaefdc8a3731f93f9d6673c84cd
 192.168.0.201 | 7d1f036cb03137843d09350a27945ad7
 192.168.0.201 | 683019bccf31772fa6a1491f5f7749b1
 192.168.0.201 | db953ccae7e04b701e788a89e4a1af77
 192.168.0.201 | db75f8ad611ef272ae3bc7a792baef88
 192.168.0.201 | f69382dca7c54921f5bdcf819d1775b7
 192.168.0.201 | cbd7d76227c0de299587f14b2a0dd482
 192.168.0.201 | f39511320f80369707c32cf1217d4054
 192.168.0.201 | d75c15fd843b1c43d31604a46c22e754
 192.168.0.201 | 0589e85441499a36561d48ba995261c9
 192.168.0.201 | 0424595e377eb34f2144999a16140b60
 192.168.0.201 | fb809895aa6415341c13b57c05115c26
 192.168.0.201 | f3c0974d58aadd8f6db46ad37a189cf0
 192.168.0.201 | 0993f1b5776be3fee998b34f3c8760b7
 192.168.0.201 | ea9139d6d89c266cc6051a70ac2ea0ba
 192.168.0.201 | 7d9cdad6ba8d4a8c3e5d00817a4a0e12
 192.168.0.201 | d65f566055a9a54ae054d5b354ee8d9b
 192.168.0.201 | 0b2e945236f109d69b3dd2d5f0ad7d3c
 192.168.0.201 | b0244a35a75d709ffcc60dec7a420bb3
 192.168.0.201 | e6f07beeef2e142302f25c66e4ed3907
 192.168.0.201 | 440e5fe08a0c95a585f8cd63f1cafacd
 192.168.0.201 | b4c31b33236bdf857d73a58a1f127e5e
 192.168.0.201 | 78da3482f4f18101e9857870b33e6f31
 192.168.0.201 | cfa8c21aeaf6b73b84c4f38fbd5a9078
 192.168.0.201 | 36fe5473068319cbf6c365c3f409855c
 192.168.0.201 | 321168b5f20278e450e8ecec085bbf87
 192.168.0.201 | a9f0f55a96b7178a5f5477850c8d3b48
 192.168.0.201 | d99a8f11bc15c8688eaef86fbea8d870
 192.168.0.201 | 30fc822128be1f640906c1d78e4ff9ca
 192.168.0.201 | b6449b581f8d9aaa9788f1d887c5e99d
 192.168.0.201 | 9cbd9ea9296d2d568177059cee616979
 192.168.0.201 | df7c07754a2d755da43be47e053292a2
 192.168.0.201 | 9926dbaa9b52898657abc149ef3c0110
 192.168.0.201 | c1a5d7c90f631a6d12ce1d86faa587d8
 192.168.0.201 | 3460f13459c835e24e2e77d2def0b59b
 192.168.0.201 | 17a2e888410b0669ea4b76496077d561
 192.168.0.201 | 9bf011cfebdb518f7f1942c345a8d3b9
 192.168.0.201 | f4eba14b2cca2f014864cc5ff26a1b37
 192.168.0.201 | 29cd5d0b65bf9d4feb17f9fc75ba08a9
 192.168.0.201 | 6fc8eff05e6f8b16e4a546f7f45c32d1
 192.168.0.201 | 1255df530a409f29d5d2bd4c0b254f64
 192.168.0.201 | 203389d536ff10ba6a003492c468c9dd
 192.168.0.201 | d34e4bd664cb6816d35566b196c2c6c2
 192.168.0.201 | 3778c75d4f7119005613db8cd9e1537c
 192.168.0.201 | 8ac5017f61c95563655a5ed69acc88bd
 192.168.0.201 | a0f8227268734f9f5a9c0e973c5c3403
 192.168.0.201 | aff6dc5ef80efe97af5dda0c683ccf1b
 192.168.0.201 | 3e0634d020bf6530647c82c20f9fcedc
 192.168.0.201 | 56b3c1969246e08064da338b32c90722
 192.168.0.201 | 7377dd4c48271e9bd4d72e1985e78b05
 192.168.0.201 | 3d306a93271a154f8a4cbea109334301
 192.168.0.201 | dc4cb01569de9acd1f0efc040992eae4
 192.168.0.201 | 38833e1b74703ee65733ff2966bcc541
 192.168.0.201 | d1576b7dc4fb7295ec9c529b16c1ef8c
 192.168.0.201 | d8fb78dc7dbdc573c7950eba000a3141
 192.168.0.201 | 18bddecf52cdfb1d0335a2f46d42778f
 192.168.0.201 | 40aaa55c92986bcd288b7c55497dfb0e
 192.168.0.201 | e085cb0254948b214e97749fffd53a61
 192.168.0.201 | 5d111b3c75b88fc77abd07c06c4cb239
 192.168.0.201 | 4198b9685f5d5f5b110fbdba3dc65a97
 192.168.0.201 | c7289ccf0535acdbabee83db59071d3a
 192.168.0.201 | 639cc3378057c6e862889d7a3cc4e507
 192.168.0.201 | 5da36d87de113ee924d797443e392d11
 192.168.0.201 | 1699bad98dab1bd128933f656fe2353a
 192.168.0.201 | 5b8632ca6f338446b11539112c2a6426
 192.168.0.201 | 0dd3bb56380c33f1c66f97d446ccad64
 192.168.0.201 | 201ca37a1a3c99fe7394670343abb199
 192.168.0.201 | aab8a58c6860b22d9cb474b904a1b925
 192.168.0.201 | 29b8dbf1665a6bc9805ce6e92ffe87b4
 192.168.0.201 | d9eb85f53d5e39d157675f78a0f300fa
 192.168.0.201 | a25a7713e86b46b35f27919cedc58378
 192.168.0.201 | b1ba3f5f2c1cfe53e261759e9fad56a4
 192.168.0.201 | b2daa06c5aadae025df6992727756b2e
 192.168.0.201 | ce1b0afe3fe05064ee42c4fdc4096c7a
 192.168.0.201 | c1e269cf9abb59fe92c000f996330e44
 192.168.0.201 | 7f8562f0e93be0986f5860299459ce6e
 192.168.0.201 | b154e3fb04c6efa2e4e867119e2c7228
 192.168.0.201 | c29289c4c115498ca2db4ae96f4f09d0
 192.168.0.201 | 31f517520e5dff4724e910a598b6208e
 192.168.0.201 | a055d89abe08b51d9966c43a8d03ce38
 192.168.0.201 | 6ce9a616f250997ef42505de8c646190
 192.168.0.201 | 5e1ba371ea4585eab2a7b0264c162449
 192.168.0.201 | 14d4c970afa02a3c3c4efd9a9fc14a46
 192.168.0.201 | 5ca1f293eaa96a7f8830d23790afdb6a
 192.168.0.201 | 1a0ef1285ea2fdd252787cef0fef411d
 192.168.0.201 | abd17076e92aac1354d8a20d8ca965b1
 192.168.0.201 | d3ede2ef8d9d93fd6ce44fad100938ae
 192.168.0.201 | 3a43fc3cb34569a166b2473087e4a5c0
 192.168.0.201 | 4decc8bb2969adac0e05f69333cecb82
 192.168.0.201 | 1be86a8d9968d9ff0925f3944bf8a09f
 192.168.0.201 | f0f153153032fe4b996f2213e1b55e01
 192.168.0.201 | d8bbed2847dc4f6a5eef8952a2e28d95
 192.168.0.201 | 2863022e26d3506f3fd98d33b982f8f3
 192.168.0.201 | 2434de331ae3b66b4076cefbc875b46c
 192.168.0.201 | 660994982866d10bb5d1fadd7d08b2d5
 192.168.0.201 | 42e425c1c402063d7d769d3511f15a29
 192.168.0.201 | 9ac0eac6737825c8cc98e891b417eb10
(101 rows)
```
> Так как индексов нет все просто прямой перебор и последовательное чтение 
```sql
postgres=# explain select v.ip,u.login from vm v cross join "user" u where v.ip='192.168.0.201';
                           QUERY PLAN
-----------------------------------------------------------------
 Nested Loop  (cost=0.00..10.53 rows=101 width=40)
   ->  Seq Scan on vm v  (cost=0.00..5.51 rows=1 width=7)
         Filter: (ip = '192.168.0.201'::inet)
   ->  Seq Scan on "user" u  (cost=0.00..4.01 rows=101 width=33)
(4 rows)
```
- Реализовать полное соединение двух или более таблиц
> Сделаем полное соединение сессий с пользователями и получим то же самое что правостороннее соединение.
```sql
postgres=# select session_id,user_id,login,s.ip as from_ip,end_at-start_at as timespend 
from session s 
full join "user" u on u.user_id = s.user_id_user;
 session_id | user_id |              login               |    from_ip    |        timespend
------------+---------+----------------------------------+---------------+--------------------------
          1 |     101 | 15ef677448121b05e4fa8bb90f5db488 | 172.16.10.233 | 143 days 13:14:42.729086
          2 |     102 | 2de14747364085d30aeb262680b6a8b6 | 172.16.16.58  | 161 days 13:26:46.558892
          3 |     103 | ccc478d451b529eb4b2fee8c7832b7b3 | 172.16.7.226  | 136 days 01:37:29.410381
          4 |     104 | e23ebdaefdc8a3731f93f9d6673c84cd | 172.16.22.23  | 160 days 12:05:09.732876
          5 |     105 | 7d1f036cb03137843d09350a27945ad7 | 172.16.14.215 | 139 days 03:47:02.96445
          6 |     106 | 683019bccf31772fa6a1491f5f7749b1 | 172.16.19.53  | 207 days 20:07:07.621939
          7 |     107 | db953ccae7e04b701e788a89e4a1af77 | 172.16.9.49   | 185 days 06:08:43.205269
          8 |     108 | db75f8ad611ef272ae3bc7a792baef88 | 172.16.37.198 | 200 days 06:41:37.258294
          9 |     109 | f69382dca7c54921f5bdcf819d1775b7 | 172.16.5.146  | 154 days 11:14:40.109694
         10 |     110 | cbd7d76227c0de299587f14b2a0dd482 | 172.16.11.148 | 191 days 07:59:19.494845
         11 |     111 | f39511320f80369707c32cf1217d4054 | 172.16.29.139 | 136 days 04:11:38.014355
         12 |     112 | d75c15fd843b1c43d31604a46c22e754 | 172.16.21.61  | 130 days 15:41:19.253019
         13 |     113 | 0589e85441499a36561d48ba995261c9 | 172.16.18.55  | 166 days 10:23:53.058434
         14 |     114 | 0424595e377eb34f2144999a16140b60 | 172.16.9.61   | 113 days 03:57:15.757445
         15 |     115 | fb809895aa6415341c13b57c05115c26 | 172.16.16.45  | 178 days 08:20:36.773885
         16 |     116 | f3c0974d58aadd8f6db46ad37a189cf0 | 172.16.15.22  | 199 days 01:34:19.294509
         17 |     117 | 0993f1b5776be3fee998b34f3c8760b7 | 172.16.27.26  | 81 days 04:12:17.064496
         18 |     118 | ea9139d6d89c266cc6051a70ac2ea0ba | 172.16.20.154 | 139 days 08:24:09.780612
         19 |     119 | 7d9cdad6ba8d4a8c3e5d00817a4a0e12 | 172.16.15.5   | 200 days 08:26:07.01516
         20 |     120 | d65f566055a9a54ae054d5b354ee8d9b | 172.16.27.165 | 104 days 13:28:52.824867
         21 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.18.151 | 87 days 09:21:44.525695
         22 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.33.200 | 212 days 13:42:24.69426
         23 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.15.176 | 139 days 02:58:49.220824
         24 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.26.224 | 120 days 10:35:37.916827
         25 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.17.117 | 204 days 22:05:19.590449
         26 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.13.72  | 164 days 03:05:44.231542
         27 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.4.230  | 156 days 01:52:32.874509
         28 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.38.246 | 87 days 13:04:45.921973
         29 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.3.188  | 193 days 04:10:07.738937
         30 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.25.226 | 211 days 15:34:22.287993
         31 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.17.223 | 110 days 17:03:25.891715
         32 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.37.71  | 179 days 00:24:35.879978
         33 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.11.26  | 110 days 22:53:04.273756
         34 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.12.6   | 178 days 01:24:42.794127
         35 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.12.123 | 205 days 19:52:23.637379
         36 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.0.37   | 208 days 19:08:40.249301
         37 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.5.30   | 153 days 06:34:02.031961
         38 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.24.200 | 159 days 16:48:55.728513
         39 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.30.82  | 144 days 16:22:09.096879
         40 |     100 | eb5c6fda5bde721e91844a19b984c594 | 172.16.9.89   | 183 days 08:06:09.920146
            |     151 | 3e0634d020bf6530647c82c20f9fcedc |               |
            |     137 | c1a5d7c90f631a6d12ce1d86faa587d8 |               |
            < cut >
            |     130 | a9f0f55a96b7178a5f5477850c8d3b48 |               |
            |     144 | 1255df530a409f29d5d2bd4c0b254f64 |               |
(120 rows)
```
- Реализовать запрос, в котором будут использованы
разные типы соединений

> Ну например наркоманский заход на получение списка пользователей которые никогда не заходили на vm. Сначала найдем все vm на которые были сессии (inner join) а затем выберем всех пользователей которые не участвовали в этих сессиях (right join).

```sql
postgres=# select u.user_id,u.login 
from vm v 
inner join session s on v.vm_id=s.vm_id_vm
right join "user" u on s.user_id_user = u.user_id 
where s.user_id_user is null;

 user_id |              login
---------+----------------------------------
     121 | 0b2e945236f109d69b3dd2d5f0ad7d3c
     122 | b0244a35a75d709ffcc60dec7a420bb3
     123 | e6f07beeef2e142302f25c66e4ed3907
     124 | 440e5fe08a0c95a585f8cd63f1cafacd
     125 | b4c31b33236bdf857d73a58a1f127e5e
     126 | 78da3482f4f18101e9857870b33e6f31
     127 | cfa8c21aeaf6b73b84c4f38fbd5a9078
     128 | 36fe5473068319cbf6c365c3f409855c
     129 | 321168b5f20278e450e8ecec085bbf87
     130 | a9f0f55a96b7178a5f5477850c8d3b48
     131 | d99a8f11bc15c8688eaef86fbea8d870
     132 | 30fc822128be1f640906c1d78e4ff9ca
     133 | b6449b581f8d9aaa9788f1d887c5e99d
     134 | 9cbd9ea9296d2d568177059cee616979
     135 | df7c07754a2d755da43be47e053292a2
     136 | 9926dbaa9b52898657abc149ef3c0110
     137 | c1a5d7c90f631a6d12ce1d86faa587d8
     138 | 3460f13459c835e24e2e77d2def0b59b
     139 | 17a2e888410b0669ea4b76496077d561
     140 | 9bf011cfebdb518f7f1942c345a8d3b9
     141 | f4eba14b2cca2f014864cc5ff26a1b37
     142 | 29cd5d0b65bf9d4feb17f9fc75ba08a9
     143 | 6fc8eff05e6f8b16e4a546f7f45c32d1
     144 | 1255df530a409f29d5d2bd4c0b254f64
     145 | 203389d536ff10ba6a003492c468c9dd
     146 | d34e4bd664cb6816d35566b196c2c6c2
     147 | 3778c75d4f7119005613db8cd9e1537c
     148 | 8ac5017f61c95563655a5ed69acc88bd
     149 | a0f8227268734f9f5a9c0e973c5c3403
     150 | aff6dc5ef80efe97af5dda0c683ccf1b
     151 | 3e0634d020bf6530647c82c20f9fcedc
     152 | 56b3c1969246e08064da338b32c90722
     153 | 7377dd4c48271e9bd4d72e1985e78b05
     154 | 3d306a93271a154f8a4cbea109334301
     155 | dc4cb01569de9acd1f0efc040992eae4
     156 | 38833e1b74703ee65733ff2966bcc541
     157 | d1576b7dc4fb7295ec9c529b16c1ef8c
     158 | d8fb78dc7dbdc573c7950eba000a3141
     159 | 18bddecf52cdfb1d0335a2f46d42778f
     160 | 40aaa55c92986bcd288b7c55497dfb0e
     161 | e085cb0254948b214e97749fffd53a61
     162 | 5d111b3c75b88fc77abd07c06c4cb239
     163 | 4198b9685f5d5f5b110fbdba3dc65a97
     164 | c7289ccf0535acdbabee83db59071d3a
     165 | 639cc3378057c6e862889d7a3cc4e507
     166 | 5da36d87de113ee924d797443e392d11
     167 | 1699bad98dab1bd128933f656fe2353a
     168 | 5b8632ca6f338446b11539112c2a6426
     169 | 0dd3bb56380c33f1c66f97d446ccad64
     170 | 201ca37a1a3c99fe7394670343abb199
     171 | aab8a58c6860b22d9cb474b904a1b925
     172 | 29b8dbf1665a6bc9805ce6e92ffe87b4
     173 | d9eb85f53d5e39d157675f78a0f300fa
     174 | a25a7713e86b46b35f27919cedc58378
     175 | b1ba3f5f2c1cfe53e261759e9fad56a4
     176 | b2daa06c5aadae025df6992727756b2e
     177 | ce1b0afe3fe05064ee42c4fdc4096c7a
     178 | c1e269cf9abb59fe92c000f996330e44
     179 | 7f8562f0e93be0986f5860299459ce6e
     180 | b154e3fb04c6efa2e4e867119e2c7228
     181 | c29289c4c115498ca2db4ae96f4f09d0
     182 | 31f517520e5dff4724e910a598b6208e
     183 | a055d89abe08b51d9966c43a8d03ce38
     184 | 6ce9a616f250997ef42505de8c646190
     185 | 5e1ba371ea4585eab2a7b0264c162449
     186 | 14d4c970afa02a3c3c4efd9a9fc14a46
     187 | 5ca1f293eaa96a7f8830d23790afdb6a
     188 | 1a0ef1285ea2fdd252787cef0fef411d
     189 | abd17076e92aac1354d8a20d8ca965b1
     190 | d3ede2ef8d9d93fd6ce44fad100938ae
     191 | 3a43fc3cb34569a166b2473087e4a5c0
     192 | 4decc8bb2969adac0e05f69333cecb82
     193 | 1be86a8d9968d9ff0925f3944bf8a09f
     194 | f0f153153032fe4b996f2213e1b55e01
     195 | d8bbed2847dc4f6a5eef8952a2e28d95
     196 | 2863022e26d3506f3fd98d33b982f8f3
     197 | 2434de331ae3b66b4076cefbc875b46c
     198 | 660994982866d10bb5d1fadd7d08b2d5
     199 | 42e425c1c402063d7d769d3511f15a29
     200 | 9ac0eac6737825c8cc98e891b417eb10
(80 rows)



```
Судя по плану запроса - он исполняется как написан.  берем сессии клеим к vm потом anti join к пользователям. 
```sql
postgres=# 
explain select u.user_id,u.login 
from vm v 
inner join session s on v.vm_id=s.vm_id_vm
right join "user" u on s.user_id_user = u.user_id 
where s.user_id_user is null;
                                         QUERY PLAN
--------------------------------------------------------------------------------------------
 Hash Anti Join  (cost=5.45..10.89 rows=80 width=41)
   Hash Cond: (u.user_id = s.user_id_user)
   ->  Seq Scan on "user" u  (cost=0.00..4.01 rows=101 width=41)
   ->  Hash  (cost=4.95..4.95 rows=40 width=8)
         ->  Merge Join  (cost=2.70..4.95 rows=40 width=8)
               Merge Cond: (v.vm_id = s.vm_id_vm)
               ->  Index Only Scan using vm_pk on vm v  (cost=0.14..17.16 rows=201 width=8)
               ->  Sort  (cost=2.46..2.56 rows=40 width=16)
                     Sort Key: s.vm_id_vm
                     ->  Seq Scan on session s  (cost=0.00..1.40 rows=40 width=16)
```
Сомнительный способ выбрать всех пользователей которые не заходили на вм 1001
```sql
select u.user_id,u.login 
from (select * from vm vvv where vvv.vm_id='1001') as gg inner join session s on gg.vm_id=s.vm_id_vm
right join "user" u on s.user_id_user = u.user_id 
where s.user_id_user is null;

 user_id |              login
---------+----------------------------------
     102 | 2de14747364085d30aeb262680b6a8b6
     103 | ccc478d451b529eb4b2fee8c7832b7b3
     104 | e23ebdaefdc8a3731f93f9d6673c84cd
     105 | 7d1f036cb03137843d09350a27945ad7
     106 | 683019bccf31772fa6a1491f5f7749b1
     107 | db953ccae7e04b701e788a89e4a1af77
     108 | db75f8ad611ef272ae3bc7a792baef88
     109 | f69382dca7c54921f5bdcf819d1775b7
     110 | cbd7d76227c0de299587f14b2a0dd482
     111 | f39511320f80369707c32cf1217d4054
     112 | d75c15fd843b1c43d31604a46c22e754
     113 | 0589e85441499a36561d48ba995261c9
     114 | 0424595e377eb34f2144999a16140b60
     115 | fb809895aa6415341c13b57c05115c26
     116 | f3c0974d58aadd8f6db46ad37a189cf0
     117 | 0993f1b5776be3fee998b34f3c8760b7
     118 | ea9139d6d89c266cc6051a70ac2ea0ba
     119 | 7d9cdad6ba8d4a8c3e5d00817a4a0e12
     120 | d65f566055a9a54ae054d5b354ee8d9b
     121 | 0b2e945236f109d69b3dd2d5f0ad7d3c
     122 | b0244a35a75d709ffcc60dec7a420bb3
     123 | e6f07beeef2e142302f25c66e4ed3907
     124 | 440e5fe08a0c95a585f8cd63f1cafacd
     125 | b4c31b33236bdf857d73a58a1f127e5e
     126 | 78da3482f4f18101e9857870b33e6f31
     127 | cfa8c21aeaf6b73b84c4f38fbd5a9078
     128 | 36fe5473068319cbf6c365c3f409855c
     129 | 321168b5f20278e450e8ecec085bbf87
     130 | a9f0f55a96b7178a5f5477850c8d3b48
     131 | d99a8f11bc15c8688eaef86fbea8d870
     132 | 30fc822128be1f640906c1d78e4ff9ca
     133 | b6449b581f8d9aaa9788f1d887c5e99d
     134 | 9cbd9ea9296d2d568177059cee616979
     135 | df7c07754a2d755da43be47e053292a2
     136 | 9926dbaa9b52898657abc149ef3c0110
     137 | c1a5d7c90f631a6d12ce1d86faa587d8
     138 | 3460f13459c835e24e2e77d2def0b59b
     139 | 17a2e888410b0669ea4b76496077d561
     140 | 9bf011cfebdb518f7f1942c345a8d3b9
     141 | f4eba14b2cca2f014864cc5ff26a1b37
     142 | 29cd5d0b65bf9d4feb17f9fc75ba08a9
     143 | 6fc8eff05e6f8b16e4a546f7f45c32d1
     144 | 1255df530a409f29d5d2bd4c0b254f64
     145 | 203389d536ff10ba6a003492c468c9dd
     146 | d34e4bd664cb6816d35566b196c2c6c2
     147 | 3778c75d4f7119005613db8cd9e1537c
     148 | 8ac5017f61c95563655a5ed69acc88bd
     149 | a0f8227268734f9f5a9c0e973c5c3403
     150 | aff6dc5ef80efe97af5dda0c683ccf1b
     151 | 3e0634d020bf6530647c82c20f9fcedc
     152 | 56b3c1969246e08064da338b32c90722
     153 | 7377dd4c48271e9bd4d72e1985e78b05
     154 | 3d306a93271a154f8a4cbea109334301
     155 | dc4cb01569de9acd1f0efc040992eae4
     156 | 38833e1b74703ee65733ff2966bcc541
     157 | d1576b7dc4fb7295ec9c529b16c1ef8c
     158 | d8fb78dc7dbdc573c7950eba000a3141
     159 | 18bddecf52cdfb1d0335a2f46d42778f
     160 | 40aaa55c92986bcd288b7c55497dfb0e
     161 | e085cb0254948b214e97749fffd53a61
     162 | 5d111b3c75b88fc77abd07c06c4cb239
     163 | 4198b9685f5d5f5b110fbdba3dc65a97
     164 | c7289ccf0535acdbabee83db59071d3a
     165 | 639cc3378057c6e862889d7a3cc4e507
     166 | 5da36d87de113ee924d797443e392d11
     167 | 1699bad98dab1bd128933f656fe2353a
     168 | 5b8632ca6f338446b11539112c2a6426
     169 | 0dd3bb56380c33f1c66f97d446ccad64
     170 | 201ca37a1a3c99fe7394670343abb199
     171 | aab8a58c6860b22d9cb474b904a1b925
     172 | 29b8dbf1665a6bc9805ce6e92ffe87b4
     173 | d9eb85f53d5e39d157675f78a0f300fa
     174 | a25a7713e86b46b35f27919cedc58378
     175 | b1ba3f5f2c1cfe53e261759e9fad56a4
     176 | b2daa06c5aadae025df6992727756b2e
     177 | ce1b0afe3fe05064ee42c4fdc4096c7a
     178 | c1e269cf9abb59fe92c000f996330e44
     179 | 7f8562f0e93be0986f5860299459ce6e
     180 | b154e3fb04c6efa2e4e867119e2c7228
     181 | c29289c4c115498ca2db4ae96f4f09d0
     182 | 31f517520e5dff4724e910a598b6208e
     183 | a055d89abe08b51d9966c43a8d03ce38
     184 | 6ce9a616f250997ef42505de8c646190
     185 | 5e1ba371ea4585eab2a7b0264c162449
     186 | 14d4c970afa02a3c3c4efd9a9fc14a46
     187 | 5ca1f293eaa96a7f8830d23790afdb6a
     188 | 1a0ef1285ea2fdd252787cef0fef411d
     189 | abd17076e92aac1354d8a20d8ca965b1
     190 | d3ede2ef8d9d93fd6ce44fad100938ae
     191 | 3a43fc3cb34569a166b2473087e4a5c0
     192 | 4decc8bb2969adac0e05f69333cecb82
     193 | 1be86a8d9968d9ff0925f3944bf8a09f
     194 | f0f153153032fe4b996f2213e1b55e01
     195 | d8bbed2847dc4f6a5eef8952a2e28d95
     196 | 2863022e26d3506f3fd98d33b982f8f3
     197 | 2434de331ae3b66b4076cefbc875b46c
     198 | 660994982866d10bb5d1fadd7d08b2d5
     199 | 42e425c1c402063d7d769d3511f15a29
     200 | 9ac0eac6737825c8cc98e891b417eb10
(99 rows)

```
- Сделать комментарии на каждый запрос
> Комментарии оставлены
- К работе приложить структуру таблиц, для которых
выполнялись соединения
> Структура в самом начале

### Задание со звездочкой*

#### Придумайте 3 своих метрики на основе показанных 

1. топ 5 медленных запросов - id запроса и сам запрос 
```
demo=#  select queryid,query, max_exec_time from pg_stat_statements order by max_exec_time desc limit 5 \gx
-[ RECORD 1 ]-+-----------------------------------------------------------------------------------------
queryid       | -8936197513781663229
query         | select count(book_ref) from bookings
max_exec_time | 45.763603
-[ RECORD 2 ]-+-----------------------------------------------------------------------------------------
queryid       | -2805371546787823309
query         | select count(flight_id) from flights
max_exec_time | 16.602072
-[ RECORD 3 ]-+-----------------------------------------------------------------------------------------
queryid       | -8682882351414142379
query         | WITH all_objects AS (                                                                   +
              |   SELECT                                                                                +
              |     c.oid,                                                                              +
              |     n.nspname AS schema,                                                                +
              |     c.relname AS name,                                                                  +
              |     CASE c.relkind                                                                      +
              |       WHEN $1 THEN $2                                                                   +
              |       WHEN $3 THEN $4                                                                   +
              |       WHEN $5 THEN $6                                                                   +
              |       WHEN $7 THEN $8                                                                   +
              |       WHEN $9 THEN $10                                                                  +
              |       WHEN $11 THEN $12                                                                 +
              |       WHEN $13 THEN $14                                                                 +
              |     END AS type,                                                                        +
              |     pg_catalog.pg_get_userbyid(c.relowner) AS owner,                                    +
              |     pg_catalog.obj_description(c.oid) AS comment                                        +
              |   FROM                                                                                  +
              |     pg_catalog.pg_class c                                                               +
              |   LEFT JOIN                                                                             +
              |     pg_catalog.pg_namespace n ON n.oid = c.relnamespace                                 +
              |   WHERE                                                                                 +
              |     c.relkind IN ($15,$16,$17,$18,$19,$20)                                              +
              |     AND n.nspname !~ $21                                                                +
              |     AND n.nspname NOT IN ($22, $23)                                                     +
              |     AND has_schema_privilege(n.nspname, $24)                                            +
              |                                                                                         +
              |   UNION                                                                                 +
              |                                                                                         +
              |   SELECT                                                                                +
              |     p.oid,                                                                              +
              |     n.nspname AS schema,                                                                +
              |     p.proname AS name,                                                                  +
              |     $25 AS function,                                                                    +
              |     pg_catalog.pg_get_userbyid(p.proowner) AS owner,                                    +
              |     $26 AS comment                                                                      +
              |   FROM                                                                                  +
              |     pg_catalog.pg_namespace n                                                           +
              |   JOIN                                                                                  +
              |     pg_catalog.pg_proc p ON p.pronamespace = n.oid                                      +
              |   WHERE                                                                                 +
              |     n.nspname !~ $27                                                                    +
              |     AND n.nspname NOT IN ($28, $29)                                                     +
              | )                                                                                       +
              | SELECT * FROM all_objects                                                               +
              | ORDER BY 2, 3
max_exec_time | 2.7014080000000003
-[ RECORD 4 ]-+-----------------------------------------------------------------------------------------
queryid       | -1186071970426635212
query         | select query, max_exec_time from pg_stat_statements order by max_exec_time desc limit $1
max_exec_time | 2.444284
-[ RECORD 5 ]-+-----------------------------------------------------------------------------------------
queryid       | 2172006323285382077
query         | select * from pg_stat_statements order by max_exec_time desc limit $1
max_exec_time | 2.151576
```

2. Ищем долгие запросы которые сейчас выполняются в базе более 5 минут
```sql

demo=# select datname, usename, client_addr, state, pid, query, now() - query_start AS waiting_duration 
from pg_stat_activity 
where state <> 'idle' and  wait_event <> 'WalSenderMain' and query_start + '5m' < now();

 datname | usename | client_addr | state | pid | query | waiting_duration
---------+---------+-------------+-------+-----+-------+------------------
(0 rows)
```

3. Топ 5 таблиц с большим процентом мертвых строк

```sql
demo=#
SELECT
    relname AS "table",
    n_live_tup AS live_rows,
    n_dead_tup AS dead_rows,
    ROUND(n_dead_tup/(n_live_tup + n_dead_tup),2) AS dead_ratio
FROM
    pg_stat_user_tables
WHERE
    n_live_tup > 0 and  n_dead_tup > 0
ORDER BY
    dead_ratio DESC;
LIMIT 5;

 table | live_rows | dead_rows | dead_ratio
-------+-----------+-----------+------------
(0 rows)
```
