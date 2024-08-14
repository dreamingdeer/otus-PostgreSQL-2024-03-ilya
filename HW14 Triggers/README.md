## Триггеры, поддержка заполнения витрин

Исходное [домашнее задание](./HW14.md "Дз 14")


hw_triggers.sql
```sql
-- ДЗ тема: триггеры, поддержка заполнения витрин

DROP SCHEMA IF EXISTS pract_functions CASCADE;
CREATE SCHEMA pract_functions;

SET search_path = pract_functions, public;

-- товары:
CREATE TABLE goods
(
    goods_id    integer PRIMARY KEY,
    good_name   varchar(63) NOT NULL,
    good_price  numeric(12, 2) NOT NULL CHECK (good_price > 0.0)
);
INSERT INTO goods (goods_id, good_name, good_price)
VALUES 	(1, 'Спички хозайственные', .50),
		(2, 'Автомобиль Ferrari FXX K', 185000000.01);

-- Продажи
CREATE TABLE sales
(
    sales_id    integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    good_id     integer REFERENCES goods (goods_id),
    sales_time  timestamp with time zone DEFAULT now(),
    sales_qty   integer CHECK (sales_qty > 0)
);

INSERT INTO sales (good_id, sales_qty) VALUES (1, 10), (1, 1), (1, 120), (2, 1);

-- отчет:
SELECT G.good_name, sum(G.good_price * S.sales_qty)
FROM goods G
INNER JOIN sales S ON S.good_id = G.goods_id
GROUP BY G.good_name;

-- с увеличением объёма данных отчет стал создаваться медленно
-- Принято решение денормализовать БД, создать таблицу
CREATE TABLE good_sum_mart
(
	good_name   varchar(63) NOT NULL,
	sum_sale	numeric(16, 2)NOT NULL
);

-- Создать триггер (на таблице sales) для поддержки.
-- Подсказка: не забыть, что кроме INSERT есть еще UPDATE и DELETE

-- Чем такая схема (витрина+триггер) предпочтительнее отчета, создаваемого "по требованию" (кроме производительности)?
-- Подсказка: В реальной жизни возможны изменения цен.

```

Заполним витрину пока старым способом
```sql
vitrina=# insert into good_sum_mart SELECT G.good_name, sum(G.good_price * S.sales_qty)
FROM goods G
INNER JOIN sales S ON S.good_id = G.goods_id
GROUP BY G.good_name;
INSERT 0 2
vitrina=# select * from good_sum_mart ;
        good_name         |   sum_sale
--------------------------+--------------
 Автомобиль Ferrari FXX K | 185000000.01
 Спички хозайственные     |        65.50
(2 rows)
```

Создадим функцию которая будет изменять витрину
```sql
CREATE OR REPLACE FUNCTION pract_functions.v_fill()
 RETURNS trigger
 LANGUAGE plpgsql
AS $xxx$
declare
  v_csm good_sum_mart.sum_sale%type;
  v_nsm     good_sum_mart.sum_sale%type;
  v_gp	      goods.good_price%type;
  v_gn		  goods.good_name%type;
  v_record 		  record;
begin
  -- Получим текущую статистику продаж товара цены и наименование
  select coalesce(v.sum_sale, 0), g.good_price, g.good_name 
  into v_csm, v_gp, v_gn
  from goods g
  left join good_sum_mart v on v.good_name = g.good_name
  where g.goods_id = coalesce(new.good_id, old.good_id);

  case TG_OP
    -- Для вставки добавляем к текущему значению
    when 'INSERT' then
      v_nsm := v_csm + new.sales_qty * v_gp;
      v_record      := new;
    -- Для обновления вычитаем старое значение из текущего и добавляем новое
    when 'UPDATE' then
      v_nsm := v_csm - old.sales_qty * v_gp + new.sales_qty * v_gp;
      v_record      := new;
    -- Для удаления вычитаем старое значение из текущего значения
    when 'DELETE' then
      v_nsm := v_csm - old.sales_qty * v_gp;
      v_record      := old;
  end case;
     
RAISE NOTICE 'Good name: %', v_gn;
RAISE NOTICE 'New total sale %', v_nsm;

MERGE INTO good_sum_mart AS v
USING (SELECT v_gn as gn, v_nsm as nsm ) AS t ON v.good_name = t.gn
WHEN NOT MATCHED THEN 
   INSERT (good_name, sum_sale)
   VALUES(t.gn, t.nsm)
WHEN MATCHED  THEN
   UPDATE SET sum_sale = t.nsm;

return v_record;
end;
$xxx$;
```
Создадим вызов триггерной функции на вставку удаление или обновление данных таблицы продаж
```sql
CREATE or REPLACE TRIGGER fill_view
AFTER
INSERT OR UPDATE OR DELETE
ON pract_functions.sales
FOR EACH ROW
EXECUTE FUNCTION pract_functions.v_fill();
```
Проверим текущие продажи в витрине
```sql
vitrina=#  select v.*
  from goods g
  join good_sum_mart v on g.good_name = v.good_name
 where g.goods_id = 1;
      good_name       | sum_sale
----------------------+----------
 Спички хозайственные |    65.50
 (1 row)
```
Добавим продажу спичек
```sql
vitrina=# INSERT INTO sales (good_id, sales_qty) VALUES (1, 70);
NOTICE:  Good name: Спички хозайственные
NOTICE:  New total sale 100.50
INSERT 0 1

select v.*
  from goods g
  join good_sum_mart v on g.good_name = v.good_name
 where g.goods_id = 1;
      good_name       | sum_sale
----------------------+----------
 Спички хозайственные |   100.50
(1 row)

```
Обновление данных в продаже
```sql
vitrina=# update sales set sales_qty = 69 where sales_id = 5;
NOTICE:  Good name: Спички хозайственные
NOTICE:  New total sale 100.00
UPDATE 1

vitrina=# select v.*
  from goods g
  join good_sum_mart v on g.good_name = v.good_name
 where g.goods_id = 1;
      good_name       | sum_sale
----------------------+----------
 Спички хозайственные |   100.00
(1 row)
```
Удалим какую нибудь продажу
```sql
vitrina=# delete from sales where sales_id = 1;
NOTICE:  Good name: Спички хозайственные
NOTICE:  New total sale 95.00
DELETE 1

vitrina=# select v.*
  from goods g
  join good_sum_mart v on g.good_name = v.good_name
 where g.goods_id = 1;
      good_name       | sum_sale
----------------------+----------
 Спички хозайственные |    95.00
(1 row)
```


### Чем такая схема (витрина+триггер) предпочтительнее отчета, создаваемого "по требованию" (кроме производительности)?

Ответ прост при изменении цены например спички стали стоить по рублю у нас будет действительный отчет. А вот если мы его пересчитаем то все поломается. Что бы такого избежать нужно хранить историю цен. 

Проверим:
```sql
vitrina=# select * from goods ;
 goods_id |        good_name         |  good_price
----------+--------------------------+--------------
        1 | Спички хозайственные     |         0.50
        2 | Автомобиль Ferrari FXX K | 185000000.01
(2 rows)


vitrina=# select * from sales ;
 sales_id | good_id |          sales_time           | sales_qty
----------+---------+-------------------------------+-----------
        2 |       1 | 2024-08-14 16:52:02.346709+00 |         1
        3 |       1 | 2024-08-14 16:52:02.346709+00 |       120
        4 |       2 | 2024-08-14 16:52:02.346709+00 |         1
        5 |       1 | 2024-08-14 16:53:57.623009+00 |        69
(4 rows)

vitrina=# select * from good_sum_mart ;
        good_name         |   sum_sale
--------------------------+--------------
 Автомобиль Ferrari FXX K | 185000000.01
 Спички хозайственные     |        95.00
(2 rows)


vitrina=# update goods set good_price = 1 where goods_id = 1;
UPDATE 1
vitrina=# select * from goods ;
 goods_id |        good_name         |  good_price
----------+--------------------------+--------------
        2 | Автомобиль Ferrari FXX K | 185000000.01
        1 | Спички хозайственные     |         1.00
(2 rows)

vitrina=# INSERT INTO sales (good_id, sales_qty) VALUES (1, 100);
NOTICE:  Good name: Спички хозайственные
NOTICE:  New total sale 195.00
INSERT 0 1

vitrina=# select v.*
  from goods g
  join good_sum_mart v on g.good_name = v.good_name
 where g.goods_id = 1;
      good_name       | sum_sale
----------------------+----------
 Спички хозайственные |   195.00
(1 row)
```
Как видим в данном случае когда наша цена на спички поменялась у нас правильные данные в витрине.

```sql
vitrina=# truncate table good_sum_mart;
TRUNCATE TABLE
vitrina=# insert into good_sum_mart SELECT G.good_name, sum(G.good_price * S.sales_qty)
FROM goods G
INNER JOIN sales S ON S.good_id = G.goods_id
GROUP BY G.good_name;
INSERT 0 2
vitrina=# select v.*
  from goods g
  join good_sum_mart v on g.good_name = v.good_name
 where g.goods_id = 1;
      good_name       | sum_sale
----------------------+----------
 Спички хозайственные |   290.00
(1 row)
```
А вот так теперь имеем не правильные данные