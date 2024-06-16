## Механизм блокировок

Исходное [домашнее задание](./HW07.md "Дз 07")


Настройте сервер так, чтобы в журнал сообщений сбрасывалась информация о блокировках, удерживаемых более 200 миллисекунд. Воспроизведите ситуацию, при которой в журнале появятся такие сообщения.

```sql
postgres=# select * from pg_settings where name like 'log_lock_waits' \gx
-[ RECORD 1 ]---+------------------------------------
name            | log_lock_waits
setting         | off
unit            | 
category        | Reporting and Logging / What to Log
short_desc      | Logs long lock waits.
extra_desc      | 
context         | superuser
vartype         | bool
source          | default
min_val         | 
max_val         | 
enumvals        | 
boot_val        | off
reset_val       | off
sourcefile      | 
sourceline      | 
pending_restart | f

postgres=# select pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)

postgres=# show log_lock_waits;
 log_lock_waits 
----------------
 on
(1 row)

postgres=# select * from pg_settings where name='deadlock_timeout' \gx
-[ RECORD 1 ]---+--------------------------------------------------------------
name            | deadlock_timeout
setting         | 1000
unit            | ms
category        | Lock Management
short_desc      | Sets the time to wait on a lock before checking for deadlock.
extra_desc      | 
context         | superuser
vartype         | integer
source          | default
min_val         | 1
max_val         | 2147483647
enumvals        | 
boot_val        | 1000
reset_val       | 1000
sourcefile      | 
sourceline      | 
pending_restart | f

postgres=# alter system set deadlock_timeout to 200;
ALTER SYSTEM

postgres=# select pg_reload_conf()
;
 pg_reload_conf 
----------------
 t
(1 row)

postgres=# show deadlock_timeout ;
 deadlock_timeout 
------------------
 200ms
(1 row)

-- session 1;
postgres=# \c lll 
You are now connected to database "lll" as user "admin".
lll=# CREATE TABLE text_table (
    id SERIAL PRIMARY KEY,
    text TEXT
);
CREATE TABLE
lll=# INSERT INTO text_table
SELECT id, MD5(random()::TEXT)::TEXT
FROM generate_series(1, 1000000) AS id;
INSERT 0 1000000
lll=# select * from text_table limit 5;
 id |               text               
----+----------------------------------
  1 | 677d1c4852846f2eaf63ac8adb841481
  2 | 909489dd6882ba6f12563bc9f09482cb
  3 | 442a981e076b9f3d56645601fcb2c431
  4 | f6644dd0a077964c7daf41caefc4b5a8
  5 | c4518b95e3b359162fb6f337119ba6e7
(5 rows)

lll=# begin; 
update text_table SET text = 'ahaha' where id=1;
BEGIN
UPDATE 1

-- session 2l

lll=# vacuum FULL text_table ;

2024-06-16 08:49:02.298 UTC [108] LOG:  process 108 still waiting for AccessExclusiveLock on relation 16410 of database 16408 after 200.070 ms
2024-06-16 08:49:02.298 UTC [108] DETAIL:  Process holding the lock: 90. Wait queue: 108.
2024-06-16 08:49:02.298 UTC [108] STATEMENT:  vacuum FULL text_table ;
2024-06-16 08:50:00.515 UTC [108] LOG:  process 108 acquired AccessExclusiveLock on relation 16410 of database 16408 after 58417.265 ms
2024-06-16 08:50:00.515 UTC [108] STATEMENT:  vacuum FULL text_table ;

```

Смоделируйте ситуацию обновления одной и той же строки тремя командами UPDATE в разных сеансах. Изучите возникшие блокировки в представлении pg_locks и убедитесь, что все они понятны. Пришлите список блокировок и объясните, что значит каждая.

```sql

lll=*# SELECT pg_relation_filepath('text_table');
 pg_relation_filepath 
----------------------
 base/16408/16419
(1 row)

-- session 1
begin; 
update text_table SET text = 'first' where id=2;

-- session 2
begin; 
update text_table SET text = 'seconds' where id=2;

-- session 3
begin; 
update text_table SET text = 'thrid' where id=2;

Из лога постгри:

2024-06-16 08:52:02.608 UTC [108] LOG:  process 108 still waiting for ShareLock on transaction 778 after 200.143 ms
2024-06-16 08:52:02.608 UTC [108] DETAIL:  Process holding the lock: 90. Wait queue: 108.
2024-06-16 08:52:02.608 UTC [108] CONTEXT:  while updating tuple (0,1) in relation "text_table"
2024-06-16 08:52:02.608 UTC [108] STATEMENT:  update text_table SET text = 'seconds' where id=2;
2024-06-16 08:52:48.396 UTC [122] STATEMENT:  update text_table SET text = 'thrid' where id=2;
2024-06-16 08:52:54.608 UTC [123] LOG:  process 123 still waiting for ExclusiveLock on tuple (0,1) of relation 16410 of database 16408 after 200.137 ms
2024-06-16 08:52:54.608 UTC [123] DETAIL:  Process holding the lock: 108. Wait queue: 123.
2024-06-16 08:52:54.608 UTC [123] STATEMENT:  update text_table SET text = 'thrid' where id=2;

lll=# select pg_blocking_pids(108);
 pg_blocking_pids 
------------------
 {90}
(1 row)

lll=# select pg_blocking_pids(123);
 pg_blocking_pids 
------------------
 {108}
(1 row)


lll=# select 'text_table'::regclass::int;
 int4  
-------
 16410
(1 row)

lll=# select 16416::regclass;
    regclass     
-----------------
 text_table_pkey
(1 row)


postgres=# select locktype,database,relation,page,tuple,transactionid,virtualtransaction,pid,mode,granted,fastpath from pg_locks where pid in (90,108,123)  order by pid ;
   locktype    | database | relation | page | tuple | transactionid | virtualtransaction | pid |       mode       | granted | fastpath 
---------------+----------+----------+------+-------+---------------+--------------------+-----+------------------+---------+----------
 relation      |    16408 |    16410 |      |       |               | 6/91               |  90 | RowExclusiveLock | t       | t
 transactionid |          |          |      |       |           778 | 6/91               |  90 | ExclusiveLock    | t       | f
 virtualxid    |          |          |      |       |               | 6/91               |  90 | ExclusiveLock    | t       | t
 relation      |    16408 |    16416 |      |       |               | 6/91               |  90 | RowExclusiveLock | t       | t
 relation      |    16408 |    16410 |      |       |               | 5/187              | 108 | RowExclusiveLock | t       | t
 relation      |    16408 |    16416 |      |       |               | 5/187              | 108 | RowExclusiveLock | t       | t
 virtualxid    |          |          |      |       |               | 5/187              | 108 | ExclusiveLock    | t       | t
 transactionid |          |          |      |       |           778 | 5/187              | 108 | ShareLock        | f       | f
 transactionid |          |          |      |       |           779 | 5/187              | 108 | ExclusiveLock    | t       | f
 tuple         |    16408 |    16410 |    0 |     1 |               | 5/187              | 108 | ExclusiveLock    | t       | f
 virtualxid    |          |          |      |       |               | 7/2                | 123 | ExclusiveLock    | t       | t
 transactionid |          |          |      |       |           780 | 7/2                | 123 | ExclusiveLock    | t       | f
 relation      |    16408 |    16416 |      |       |               | 7/2                | 123 | RowExclusiveLock | t       | t
 relation      |    16408 |    16410 |      |       |               | 7/2                | 123 | RowExclusiveLock | t       | t
 tuple         |    16408 |    16410 |    0 |     1 |               | 7/2                | 123 | ExclusiveLock    | f       | f

1) Транзакция обновила данные tuple и получила эксклюзивную блокировку для целевой таблицы и ключа
 relation      |    16408 |    16410 |      |       |               | 6/91               |  90 | RowExclusiveLock | t       | t
 relation      |    16408 |    16416 |      |       |               | 6/91               |  90 | RowExclusiveLock | t       | t

Экслюзивная блокировка транзакции самой на себя xid и vxid
 virtualxid    |          |          |      |       |               | 6/91               |  90 | ExclusiveLock    | t       | t
исключительная блокировка настоящего номера транзакции
 transactionid |          |          |      |       |           778 | 6/91               |  90 | ExclusiveLock    | t       | f

2) Получила эксклюзивную блокировку для целевой таблицы и ключа
 relation      |    16408 |    16410 |      |       |               | 5/187              | 108 | RowExclusiveLock | t       | t
 relation      |    16408 |    16416 |      |       |               | 5/187              | 108 | RowExclusiveLock | t       | t
Экслюзивная блокировка транзакции самой на себя xid и vxid
 virtualxid    |          |          |      |       |               | 5/187              | 108 | ExclusiveLock    | t       | t
исключительная блокировка настоящего номера транзакции
 transactionid |          |          |      |       |           779 | 5/187              | 108 | ExclusiveLock    | t       | f
Эксклюзивная блокировка версии строки для обновления 
 tuple         |    16408 |    16410 |    0 |     1 |               | 5/187              | 108 | ExclusiveLock    | t       | f
Установки ShareLock раздельной блокировки на заблокировавщую транзакцию строку
 transactionid |          |          |      |       |           778 | 5/187              | 108 | ShareLock        | f       | f

lll=# SELECT * FROM pgrowlocks('text_table') \gx
-[ RECORD 1 ]-----------------
locked_row | (0,1)
locker     | 778
multi      | f
xids       | {778}
modes      | {"No Key Update"}
pids       | {90}

3) Экслюзивная блокировка транзакции самой на себя xid и vxid
 virtualxid    |          |          |      |       |               | 7/2                | 123 | ExclusiveLock    | t       | t
  исключительная блокировка настоящего номера транзакции
 transactionid |          |          |      |       |           780 | 7/2                | 123 | ExclusiveLock    | t       | f
Получила эксклюзивную блокировку для целевой таблицы и ключа
 relation      |    16408 |    16416 |      |       |               | 7/2                | 123 | RowExclusiveLock | t       | t
 relation      |    16408 |    16410 |      |       |               | 7/2                | 123 | RowExclusiveLock | t       | t
Эксклюзивная блокировка версии строки для обновления не удалась  
 tuple         |    16408 |    16410 |    0 |     1 |               | 7/2                | 123 | ExclusiveLock    | f       | f


И более наглядное представление

lll=# SELECT locktype, mode, granted, pid, pg_blocking_pids(pid) AS wait_for FROM pg_locks WHERE relation = 'text_table'::regclass order by pid;
 locktype |       mode       | granted | pid | wait_for 
----------+------------------+---------+-----+----------
 relation | RowExclusiveLock | t       |  90 | {}
 relation | RowExclusiveLock | t       | 108 | {90}
 tuple    | ExclusiveLock    | t       | 108 | {90}
 relation | RowExclusiveLock | t       | 123 | {108}
 tuple    | ExclusiveLock    | f       | 123 | {108}
```

Воспроизведите взаимоблокировку трех транзакций. Можно ли разобраться в ситуации постфактум, изучая журнал сообщений?

```sql

-- session 1
S1>begin; update text_table SET text = text || 'first' where id=1;
BEGIN
UPDATE 1
S2>begin; update text_table SET text = text || 'second' where id=2;
BEGIN
UPDATE 1
S3>begin; update text_table SET text = text || 'thrid' where id=3;
BEGIN
UPDATE 1
S1>update text_table SET text = text || 'first' where id=2;
S2>update text_table SET text = text || 'second' where id=3;
S3>update text_table SET text = text || 'thrid' where id=1;
ERROR:  deadlock detected
DETAIL:  Process 123 waits for ShareLock on transaction 788; blocked by process 90.
Process 90 waits for ShareLock on transaction 789; blocked by process 108.
Process 108 waits for ShareLock on transaction 790; blocked by process 123.
HINT:  See server log for query details.
CONTEXT:  while updating tuple (8333,40) in relation "text_table"

2024-06-16 10:18:43.468 UTC [90] LOG:  process 90 still waiting for ShareLock on transaction 789 after 200.211 ms
2024-06-16 10:18:43.468 UTC [90] DETAIL:  Process holding the lock: 108. Wait queue: 90.
2024-06-16 10:18:43.468 UTC [90] CONTEXT:  while updating tuple (8333,44) in relation "text_table"
2024-06-16 10:18:43.468 UTC [90] STATEMENT:  update text_table SET text = text || 'first' where id=2;
2024-06-16 10:18:52.034 UTC [108] LOG:  process 108 still waiting for ShareLock on transaction 790 after 201.241 ms
2024-06-16 10:18:52.034 UTC [108] DETAIL:  Process holding the lock: 123. Wait queue: 108.
2024-06-16 10:18:52.034 UTC [108] CONTEXT:  while updating tuple (0,2) in relation "text_table"
2024-06-16 10:18:52.034 UTC [108] STATEMENT:  update text_table SET text = text || 'second' where id=3;
2024-06-16 10:19:00.649 UTC [123] LOG:  process 123 detected deadlock while waiting for ShareLock on transaction 788 after 200.214 ms
2024-06-16 10:19:00.649 UTC [123] DETAIL:  Process holding the lock: 90. Wait queue: .
2024-06-16 10:19:00.649 UTC [123] CONTEXT:  while updating tuple (8333,40) in relation "text_table"
2024-06-16 10:19:00.649 UTC [123] STATEMENT:  update text_table SET text = text || 'thrid' where id=1;
2024-06-16 10:19:00.649 UTC [123] ERROR:  deadlock detected
2024-06-16 10:19:00.649 UTC [123] DETAIL:  Process 123 waits for ShareLock on transaction 788; blocked by process 90.
	Process 90 waits for ShareLock on transaction 789; blocked by process 108.
	Process 108 waits for ShareLock on transaction 790; blocked by process 123.
	Process 123: update text_table SET text = text || 'thrid' where id=1;
	Process 90: update text_table SET text = text || 'first' where id=2;
	Process 108: update text_table SET text = text || 'second' where id=3;
2024-06-16 10:19:00.649 UTC [123] HINT:  See server log for query details.
2024-06-16 10:19:00.649 UTC [123] CONTEXT:  while updating tuple (8333,40) in relation "text_table"
2024-06-16 10:19:00.649 UTC [123] STATEMENT:  update text_table SET text = text || 'thrid' where id=1;
2024-06-16 10:19:00.649 UTC [108] LOG:  process 108 acquired ShareLock on transaction 790 after 8816.585 ms
2024-06-16 10:19:00.649 UTC [108] CONTEXT:  while updating tuple (0,2) in relation "text_table"
2024-06-16 10:19:00.649 UTC [108] STATEMENT:  update text_table SET text = text || 'second' where id=3;

Довольно сложно разобратся в журнале событий. Сложно востановить полностью транзакцию в каждой сессии.

```

Могут ли две транзакции, выполняющие единственную команду UPDATE одной и той же таблицы (без where), заблокировать друг друга?

```sql
Нет преграды фантазии как выстрелить себе в ногу! SQL велик и могуч.
```
Задание со звездочкой*
Попробуйте воспроизвести 

```sql
Используя блокировки строк для обновления с разным порядком таблицы можно заблокировать друг друга.

UPDATE text_table set text = (select text from text_table order by id limit 1 for update);

UPDATE text_table set text = (select text from text_table order by id desc limit 1 for update);


S1>SHOW TRANSACTION ISOLATION LEVEL;
 transaction_isolation 
-----------------------
 read committed
(1 row)


S2>SHOW TRANSACTION ISOLATION LEVEL;
 transaction_isolation 
-----------------------
 read committed
(1 row)


S1>UPDATE text_table set text = (select text from text_table order by id limit 1 for update);
ERROR:  deadlock detected
DETAIL:  Process 90 waits for ShareLock on transaction 855; blocked by process 108.
Process 108 waits for ShareLock on transaction 854; blocked by process 90.
HINT:  See server log for query details.
CONTEXT:  while updating tuple (13092,117) in relation "text_table"


S2>UPDATE text_table set text = (select text from text_table order by id desc limit 1 for update);
UPDATE 1000000


2024-06-16 12:09:24.496 UTC [108] LOG:  process 108 still waiting for ShareLock on transaction 856 after 200.126 ms
2024-06-16 12:09:24.496 UTC [108] DETAIL:  Process holding the lock: 90. Wait queue: 108.
2024-06-16 12:09:24.496 UTC [108] CONTEXT:  while updating tuple (17440,1) in relation "text_table"
2024-06-16 12:09:24.496 UTC [108] STATEMENT:  UPDATE text_table set text = (select text from text_table order by id desc limit 1 for update);
2024-06-16 12:09:24.951 UTC [90] LOG:  process 90 detected deadlock while waiting for ShareLock on transaction 857 after 200.128 ms
2024-06-16 12:09:24.951 UTC [90] DETAIL:  Process holding the lock: 108. Wait queue: .
2024-06-16 12:09:24.951 UTC [90] CONTEXT:  while updating tuple (18778,37) in relation "text_table"
2024-06-16 12:09:24.951 UTC [90] STATEMENT:  UPDATE text_table set text = (select text from text_table order by id limit 1 for update);
2024-06-16 12:09:24.951 UTC [90] ERROR:  deadlock detected
2024-06-16 12:09:24.951 UTC [90] DETAIL:  Process 90 waits for ShareLock on transaction 857; blocked by process 108.
	Process 108 waits for ShareLock on transaction 856; blocked by process 90.
	Process 90: UPDATE text_table set text = (select text from text_table order by id limit 1 for update);
	Process 108: UPDATE text_table set text = (select text from text_table order by id desc limit 1 for update);
2024-06-16 12:09:24.951 UTC [90] HINT:  See server log for query details.
2024-06-16 12:09:24.951 UTC [90] CONTEXT:  while updating tuple (18778,37) in relation "text_table"
2024-06-16 12:09:24.951 UTC [90] STATEMENT:  UPDATE text_table set text = (select text from text_table order by id limit 1 for update);
2024-06-16 12:09:24.951 UTC [108] LOG:  process 108 acquired ShareLock on transaction 856 after 655.386 ms
2024-06-16 12:09:24.951 UTC [108] CONTEXT:  while updating tuple (17440,1) in relation "text_table"
2024-06-16 12:09:24.951 UTC [108] STATEMENT:  UPDATE text_table set text = (select text from text_table order by id desc limit 1 for update);


Поскольку оба запроса пытаются заблокировать разные строки в одной таблице, они будут блокировать друг друга до тех пор, пока один из них не завершится. Это может привести к взаимной блокировке запросов, если они выполняются одновременно.

```