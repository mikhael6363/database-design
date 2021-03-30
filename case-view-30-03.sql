/*
 CASE
 SELECT в данном случае выступает в роли console.log из js
 */
--1
SELECT (
    CASE
      WHEN true THEN '+'
      WHEN false THEN '-'
      ELSE '???'
    END
  ) AS "test field";
--2
SELECT (
    CASE
      WHEN true = false THEN '+'
      WHEN true THEN '-'
      ELSE '???'
    END
  ) AS "test field";
--поле male & female (gender) вместо true & false у isMale
SELECT *,
  (
    CASE
      WHEN "isMale" = true THEN 'male'
      WHEN "isMale" = false THEN 'female'
      ELSE '???'
    END
  ) AS "gender"
FROM users;
-- в каком сезоне родился пользователь
SELECT *,
  (
    CASE
      extract(
        month
        from "birthday"
      )
      WHEN 1 THEN 'winter'
      WHEN 2 THEN 'winter'
      WHEN 3 THEN 'spring'
      WHEN 4 THEN 'spring'
      WHEN 5 THEN 'spring'
      WHEN 6 THEN 'summer'
      WHEN 7 THEN 'summer'
      WHEN 8 THEN 'summer'
      WHEN 9 THEN 'autumn'
      WHEN 10 THEN 'autumn'
      WHEN 11 THEN 'autumn'
      WHEN 12 THEN 'winter'
    END
  ) AS "season"
FROM users;
--показать польз, к-е несоверш в вымышл стране, а другие соверш,
SELECT *,
  (
    CASE
      WHEN extract(
        year
        from age("birthday")
      ) < 30 THEN 'not adult'
      WHEN extract(
        year
        from age("birthday")
      ) >= 30 THEN 'adult'
    END
  ) AS "age status"
FROM users;
--если бренд iphone - вернуть строку APPLE,  а если нет, то - other
SELECT *,
  (
    CASE
      WHEN "brand" ILIKE 'iphone' THEN 'Apple'
      ELSE 'Other'
    END
  ) AS "Manufacturer"
FROM phones;
/*
 1.1. если телефон меньше 10000 - доступный,
 а если больше 20000 (флагман),
 если >10 && <20 - средний
 1.2. Все телефоны дороже среднего
 */
SELECT *,
  (
    CASE
      WHEN price < 10000 THEN 'доступный'
      WHEN price > 20000 THEN 'флагман'
      ELSE 'средний'
    END
  ) AS "Статус телефона"
FROM phones;
/**/
SELECT *,
  (
    CASE
      WHEN price > (
        SELECT avg(price)
        FROM phones
      ) THEN 'High price'
      ELSE 'low'
    END
  ) AS "Статус телефона"
FROM phones;
/*
 Вывести пользователя и кол-во заказов
 Если больше 4х заказов - постоянный клиент
 больше 2х заказов - активный
 больше 0 - просто клиент
 + вывести имейл пользователя
 */
SELECT u.id,
  u.email,
  (
    CASE
      WHEN count(o.id) > 4 THEN 'constant'
      WHEN count(o.id) > 4 THEN 'active'
      ELSE 'buyer'
    END
  ) AS "Customer status"
FROM orders AS o
  RIGHT JOIN users AS u ON o."userId" = u.id
GROUP BY u.id,
  u.email
ORDER BY u.id;
--кол-во телефонов дороже 5000к
SELECT sum(
    CASE
      WHEN price > 5000 THEN 1
      ELSE 0
    END
  )
FROM phones;
--COALESCE
SELECT model,
  price,
  COALESCE("description", 'Not available')
FROM phones;
--NULLIF
SELECT NULLIF(12, 12);
/**/
SELECT NULLIF(NULL, 52) -- GREATEST / LIST
SELECT GREATEST(1, 2, 333, 4, 5);
SELECT LIST(1, 2, 333, 4, 5);
/*
 Выражения подзапросов:
 1. IN / NOT IN -> 1н столбец в подзапросе
 2. EXISTS
 Работает по типу nullin
 Возвращает true, если подзапрос не пустой и false если пустой.
 3. SOME / ANY
 ANY -
 SOME - булл true если хоть что-то
 ALL - если все
 */
--все польз. к-е не делали заказы
SELECT *
FROM users AS u
WHERE u.id NOT IN (
    SELECT "userId"
    FROM orders
  );
-- найти телефоны к-е не заказывали
SELECT *
FROM phones AS p
WHERE p.id NOT IN (
    SELECT "phoneId"
    FROM phones_to_orders
  );
--EXISTS - есть ли у нас такой польз-ль (true/false)
SELECT EXISTS (
    SELECT *
    FROM users AS u
    WHERE u.id = 1
  );
--делал ли польз. заказаз
SELECT *
FROM users u
WHERE EXISTS (
    SELECT *
    FROM orders o
    WHERE u.id = o."userId"
  );
--Телефоны дороже всех айфонов
SELECT *
FROM phones
WHERE price > (
    SELECT max(price)
    FROM phones
    WHERE brand ILIKE 'iphone'
  );
/* Представления  | VIEWS | Вирт. таблицы */
CREATE VIEW "uwoa" AS(
  SELECT u.*,
    count(o.id) AS "order amount"
  FROM users AS u
    JOIN orders AS o ON u.id = o."userId"
  GROUP BY u.id,
    u.email
);
SELECT *
FROM "uwoa"
WHERE "order amount" > 3;
--заказ и его стоимость
CREATE VIEW "orders_with_price" AS (
  SELECT o."userId",
    o.id,
    sum(pto.quantity * p.price)
  FROM orders AS o
    JOIN phones_to_orders AS pto ON o.id = pto."orderId"
    JOIN phones AS p ON pto."phoneId" = p.id
  GROUP BY o.id
  ORDER BY o."userId"
);
CREATE VIEW "spam_list" AS (
  SELECT owp.*,
    u.email,
    u.birthday
  FROM "orders_with_price" AS owp
    JOIN users AS u ON u.id = owp."userId"
);
SELECT *
FROM "spam_list";
/*
 View: fullname, age, gender
 */
CREATE VIEW "users_info" AS (
  SELECT concat("firstName", ' ', "lastName"),
    extract(
      years
      from age("birthday")
    ),
    (
      CASE
        WHEN "isMale" = true THEN 'male'
        WHEN "isMale" = false THEN 'female'
        ELSE '???'
      END
    ) AS "gender"
  FROM users
);
SELECT *
FROM "users_info";
/*
 Top 10 most expensive buyers,
 1.1. Отобразить всех покупателей + цена.
 1.2. Отобразить топ-10
 */
CREATE VIEW "users_with_order_prices" AS (
  SELECT o."userId",
    sum(pto.quantity * p.price) AS "Sum of order"
  FROM orders AS o
    JOIN phones_to_orders AS pto ON o.id = pto."orderId"
    JOIN phones AS p ON pto."phoneId" = p.id
  GROUP BY o."userId"
  ORDER BY "Sum of order" DESC
  LIMIT 10 OFFSET 0
);
/*
 Biggest amount of orders
 1. Пользователей с их кол-вом заказов
 2. топ-10 польз. с самым крупным кол-вом заказов
 */
CREATE VIEW "users_with_order_amount" AS (
  SELECT u.id AS "ID Пользователя",
    count(o.id) AS "Кол-во заказов"
  FROM users AS u
    LEFT OUTER JOIN orders AS o ON u.id = o."userId"
  GROUP BY u.id
  ORDER BY "Кол-во заказов" DESC
  LIMIT 10 OFFSET 0
);
/*
 
 
 /*
 Принципы ACID:
 Требования к транзакциям. Которые гарантирует PostgreSQL.
 
 
 Изменения таблиц -> ALTER TABLE  
 
 */
--удалять / добавлять столбцы
ALTER TABLE user_tasks DROP COLUMN test;
-- уд. / доб. ограничения
ALTER TABLE user_tasks
ADD CONSTRAINT "tasks_createdAt_check" CHECK(createdAt <= timestamp);
--удалить/изменить ограничение
ALTER TABLE user_tasks
ALTER COLUMN createdAt DROP NOT NULL;
-- установить ограничение
ALTER TABLE user_tasks
ALTER COLUMN createdAt
SET NOT NULL;
--изменять значения по ум.(удалять)
ALTER TABLE user_tasks
ALTER COLUMN isdone DROP DEFAULT;
--изменять значения по ум.(добавлять)
ALTER TABLE user_tasks
ALTER COLUMN isdone
SET DEFAULT false;
--Изменять типы данных столбцов
ALTER TABLE user_tasks
ALTER COLUMN body TYPE varchar(512);
--Переименовать столбцы
ALTER TABLE user_tasks
  RENAME COLUMN isdone TO status;
--Переименовать таблицы
ALTER TABLE user_tasks
  RENAME TO tasks;
/*
 
 создание своих типов данных:
 CREATE TYPE task_status AS ENUM ('done', 'inProcess', 'notDone');
 ALTER TABLE user_tasks
 
 создаем каст:
 CREATE CAST (boolean AS task_status)
 */
/*
 users: log, email, pass
 employees: salary, department, position, hire_date, name
 
 
 CREATE SCHEMA -> создание схемы (public по ум.)
 */
/**/
DROP TABLE IF EXISTS "usersForEmp";
DROP TABLE IF EXISTS employees;
/**/
CREATE TABLE "usersForEmp"(
  "id" serial PRIMARY KEY,
  "login" varchar(64) NOT NULL,
  "password" varchar(64) NOT NULL,
  "email" varchar(256) NOT NULL CHECK (email != '')
);
INSERT INTO "usersForEmp" ("login", "email", "password_hash")
VALUES (
    'test1',
    'test1@gmail.com',
    'OUGFHIf247fgb2euif29-8fH-==1==12dikvlEDmkvL'
  ),
  (
    'test2',
    'test2@gmail.com',
    'OUGFHIf247fgb2euif29-8fH-==1==12dikvlEDmkvL'
  ),
  (
    'test3',
    'test3@gmail.com',
    'OUGFHIf247fgb2euif29-8fH-==1==12dikvlEDmkvL'
  ),
  (
    'test4',
    'test4@gmail.com',
    'OUGFHIf247fgb2euif29-8fH-==1==12dikvlEDmkvL'
  ),
  (
    'test5',
    'test5@gmail.com',
    'OUGFHIf247fgb2euif29-8fH-==1==12dikvlEDmkvL'
  ),
  (
    'test6',
    'test6@gmail.com',
    'OUGFHIf247fgb2euif29-8fH-==1==12dikvlEDmkvL'
  );
CREATE TABLE employees(
  -- "id" serial PRIMARY KEY,
  "firstName" varchar(128),
  "lastName" varchar(128),
  "salary" decimal(10, 2) NOT NULL DEFAULT 0 CHECK("salary" >= 0),
  "department" varchar(128) NOT NULL,
  "position" varchar(128),
  "hire_date" date NOT NULL CHECK (
    "hire_date" < current_date
    AND "hire_date" > '2010/1/1'
  ),
  CONSTRAINT "CK_FULL_NAME" CHECK (
    "firstName" != ''
    AND "lastName" != ''
  )
);
INSERT INTO employees (
    "salary",
    "department",
    "position",
    hire_date,
    user_id
  )
VALUES (
    10000,
    'development',
    'senior developer',
    '1990-1-1',
    1
  ),
  (
    6000,
    'development',
    'senior developer',
    '2010-1-1',
    2
  ),
  (
    1000,
    'HR',
    'hr',
    '2020-1-1',
    3
  ),
  (
    1000,
    'Sales',
    'manager',
    '2019-1-1',
    4
  );
/**/
ALTER TABLE "usersForEmp"
ADD CONSTRAINT login_unique UNIQUE ("login");
/**/
ALTER TABLE "usersForEmp"
ADD CONSTRAINT email_unique UNIQUE ("email");
/*
 change user table:
 
 1- delete pass column
 2- create column password_hash
 
 users 1 <=> 0..1 employees - связь только с пом. ALTER
 
 Тип связи 1:n
 */
ALTER TABLE "usersForEmp" DROP COLUMN password;
/**/
ALTER TABLE "usersForEmp"
ADD COLUMN "password_hash" varchar(500) NOT NULL;
/**/
ALTER TABLE employees
ADD COLUMN user_id int PRIMARY KEY REFERENCES users;
/*
 Запросы:
 
 Всех users с информ. о зарплате
 */
CREATE VIEW "users_with_order_prices" AS (
  SELECT COALESCE(e.salary, 0),
    u.*
  FROM employees AS e
    RIGHT JOIN "usersForEmp" AS u ON e."user_id" = u.id
  ORDER BY e.salary DESC
);
/* Пользователей к-е не сотрудники */
SELECT *
FROM "usersForEmp" AS u
WHERE u.id NOT IN (
    SELECT user_id
    FROM employees
  );
/* Окнонные ф-ции */
CREATE SCHEMA wf;
/**/
DROP TABLE wf.departments;
CREATE TABLE wf.departments(
  "id" serial PRIMARY KEY,
  "name" varchar(64) NOT NULL
);
INSERT INTO wf.departments("name")
VALUES ('SALES'),
  ('HR'),
  ('DEVELOPMENT'),
  ('QA'),
  ('TOP MANAGEMENT');
/**/
DROP TABLE wf.employees;
CREATE TABLE wf.employees(
  "id" serial PRIMARY KEY,
  "department_id" int REFERENCES wf.departments,
  "name" varchar(64) NOT NULL,
  "salary" decimal(10, 2) NOT NULL DEFAULT 0 CHECK("salary" >= 0),
  "hire_date" date NOT NULL CHECK ("hire_date" < current_date)
);
INSERT INTO wf.employees ("name", salary, hire_date, department_id)
VALUES ('TEST TESTov', 10000, '1990-1-1', 1),
  ('John Doe', 6000, '2010-1-1', 2),
  ('Matew Doe', 3456, '2020-1-1', 2),
  ('Matew Doe1', 53462, '2020-1-1', 3),
  ('Matew Doe2', 124543, '2012-1-1', 4),
  ('Matew Doe3', 12365, '2004-1-1', 5),
  ('Matew Doe4', 1200, '2000-8-1', 5),
  ('Matew Doe5', 2535, '2010-1-1', 2),
  ('Matew Doe6', 1000, '2014-1-1', 3),
  ('Matew Doe6', 63456, '2017-6-1', 1),
  ('Matew Doe7', 1000, '2020-1-1', 3),
  ('Matew Doe8', 346434, '2015-4-1', 2),
  ('Matew Doe9', 3421, '2018-1-1', 3),
  ('Matew Doe0', 34563, '2013-2-1', 5),
  ('Matew Doe10', 2466, '2011-1-1', 1),
  ('Matew Doe11', 9999, '1999-1-1', 5),
  ('TESTing 1', 1000, '2019-1-1', 2);
/* Вся ЗП на отдел */
SELECT sum(e.salary) OVER (PARTITION BY d.id) AS "ЗП на весь отдел",
  d.name AS "Имя отдела"
FROM wf.departments AS d
  JOIN wf.employees AS e ON e.department_id = d.id;
/* Ск. денег всего уходит на ЗП */
SELECT sum(e.salary) OVER () AS "Вся Зарплата"
FROM wf.departments AS d
  JOIN wf.employees AS e ON e.department_id = d.id;
/**/