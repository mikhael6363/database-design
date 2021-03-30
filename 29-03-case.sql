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