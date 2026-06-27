DROP DATABASE IF EXISTS monday_coffee_db;

CREATE DATABASE monday_coffee_db;

USE monday_coffee_db;

-- Monday Coffee Schemas

DROP TABLE IF EXISTS sales;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS city;

-- City
CREATE TABLE city(
	city_id INT PRIMARY KEY,
    city_name VARCHAR(20),
    population BIGINT,
    estimated_rent float,
    city_rank INT
);

-- Customers
CREATE TABLE customers(
	customer_id INT PRIMARY KEY,
    customer_name VARCHAR(20),
    city_id INT,
    constraint fk_city FOREIGN KEY(city_id) REFERENCES city(city_id)
);

-- Product
CREATE TABLE products(
	product_id INT PRIMARY KEY,
    product_name VARCHAR(40),
    price float
);

-- Sales
CREATE TABLE sales(
	sales_id INT PRIMARY KEY,
    sales_date DATE,
    product_id INT,
    customer_id INT,
    total FLOAT,
    rating INT,
    CONSTRAINT fk_products FOREIGN KEY(product_id) REFERENCES products(product_id),
    CONSTRAINT fk_customer FOREIGN KEY(customer_id) REFERENCES customers(customer_id)
);

show tables;









