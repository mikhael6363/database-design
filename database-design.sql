DROP TABLE "clients";
CREATE TABLE "clients"(
  "id" serial PRIMARY KEY,
  "firstName" varchar(64) NOT NULL CHECK("firstName" != ''),
  "lastName" varchar(64) NOT NULL CHECK("lastName" != ''),
  "address" jsonb NOT NULL,
  "mobileNumber" varchar(32)
);
/* */
DROP TABLE "orders";
CREATE TABLE "orders"(
  "id" serial PRIMARY KEY,
  "clientId" int REFERENCES "clients",
  "contractId" int REFERENCES "contracts",
);
/* */
DROP TABLE "products_to_orders";
CREATE TABLE "products_to_orders"(
  "orderId" int REFERENCES "orders",
  "productId" int REFERENCES "products",
  "quantity" int NOT NULL CHECK ("quantity" > 0),
  PRIMARY KEY ("orderId", "productId")
);
/* */
DROP TABLE "products";
CREATE TABLE "products"(
  "id" serial PRIMARY KEY,
  "name" varchar(256) NOT NULL CHECK("name" != ''),
  "price" decimal(20, 2) NOT NULL CHECK("price" >= 0),
);
/* */
CREATE EXTENSION "uuid-ossp";
DROP TABLE "contracts";
CREATE TABLE "contracts"(
  "id" uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  "clientId" int REFERENCES "clients",
);
/* */
DROP TABLE "orders_to_deliveries";
CREATE TABLE "orders_to_deliveries" (
  "deliveryId" int REFERENCES "deliveries",
  "orderId" int REFERENCES "orders",
  PRIMARY KEY ("deliveryId", "orderId")
);
/* */
DROP TABLE "deliveries";
CREATE TABLE "deliveries"(
  id serial PRIMARY KEY,
  "receiver" int REFERENCES "clients",
  "quantity" int NOT NULL CHECK ("quantity" > 0),
  "timeOfArrival" timestamp NOT NULL DEFAULT current_timestamp
);