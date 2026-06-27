-- Monday Coffee Expansion Data Analysis

USE monday_coffee_db;

SELECT * FROM city;
SELECT * FROM customers;
SELECT * FROM products;
SELECT * FROM sales;

-- Report & Data Analysis
-- How many people in each city are estimated to consume coffee, given that 25% does?
SELECT 
	city_name,
	ROUND((population * 0.25) / 1000000, 2) AS coffee_consumer_in_millions,
	ROUND(population / 1000000, 2) as total_population_in_millions,
	city_rank FROM city
ORDER BY population DESC;

-- What is the total revenue generated from coffee sales in the last quarter of 2023?
SELECT 
	SUM(total) as total_revenue
FROM sales
WHERE
	YEAR(sales_date) = 2023 
    AND
    QUARTER(sales_date) = 4;

-- What is the total revenue generated from coffee sales in the last quarter of 2023 from each city?
SELECT 
	ci.city_name, 
    SUM(s.total) as total_revenue
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON c.city_id = ci.city_id
WHERE 
	YEAR(s.sales_date) = 2023 
    AND 
    QUARTER(s.sales_date) = 4
GROUP BY ci.city_name
ORDER BY total_revenue DESC;

-- How many units of each coffee products have been sold?
SELECT 
	p.product_name,
	COUNT(*) as total_units
FROM sales as s
JOIN products as p
ON s.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_units DESC;

-- What is the average sales amount per customer in each city?
SELECT
	ci.city_name,
    SUM(s.total) as total_revenue,
    COUNT(DISTINCT s.customer_id) as total_customers,
    ROUND(SUM(s.total) / COUNT(DISTINCT s.customer_id), 2) as average_sales_per_cust
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON c.city_id = ci.city_id
GROUP BY ci.city_name
ORDER BY total_revenue DESC;

-- Provide a list of cities along with thier population and estimated coffee consumers
WITH city_table as
(
	SELECT
		city_name,
		ROUND((population * 0.25 / 1000000), 2) as coffee_consumers_in_millions
	FROM city
),
customers_table
AS
(
	SELECT
		ci.city_name,
		COUNT(DISTINCT c.customer_id) as unique_customers
	FROM customers as c
	JOIN sales as s
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON c.city_id = ci.city_id
	GROUP BY ci.city_name
)

SELECT 
	city_table.city_name,
    city_table.coffee_consumers_in_millions,
    customers_table.unique_customers
FROM city_table
JOIN customers_table
ON city_table.city_name = customers_table.city_name;

-- What are the top 3 selling products in each city based on sales volume?
SELECT * 
FROM
(
	SELECT
		ci.city_name,
		p.product_name,
		COUNT(s.sales_id) as total_orders,
		DENSE_RANK() OVER(PARTITION BY ci.city_name ORDER BY COUNT(s.sales_id) DESC) as ranking
	FROM sales as s
	JOIN products as p
	ON s.product_id = p.product_id
	JOIN customers as c
	ON s.customer_id = c.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY ci.city_name, p.product_name
	-- ORDER BY city_name, COUNT(s.sales_id) DESC 
) AS t1
WHERE ranking <= 3;

-- How manu unique customers are there in each city who has purchased coffee products
SELECT 
	ci.city_name,
    COUNT(DISTINCT cu.customer_id) as unique_customers
FROM city as ci
JOIN customers as cu
ON ci.city_id  = cu.city_id
JOIN sales as s 
ON s.customer_id = cu.customer_id
WHERE
	s.product_id IN (1,2,3,4,5,8,9,11,13)
GROUP BY ci.city_name;

-- Find each city and thier average sale per customer and average rent per customer
WITH city_table
AS
(
	SELECT 
		ci.city_name,
		SUM(s.total) as total_revenue,
		COUNT(DISTINCT s.customer_id) as total_customers,
		ROUND(SUM(s.total) / COUNT(DISTINCT s.customer_id), 2) as avg_sale_per_cust
	FROM sales as s
	JOIN customers as cu
	ON s.customer_id = cu.customer_id
	JOIN city as ci
	ON ci.city_id = cu.city_id
	GROUP BY ci.city_name
	ORDER BY total_revenue DESC
),
city_rent
AS
(
	SELECT
		city_name,
        estimated_rent
	FROM city
)

SELECT
	ct.city_name,
    cr.estimated_rent,
    ct.total_customers,
    ct.avg_sale_per_cust,
    ROUND((estimated_rent / ct.total_customers), 2) as avg_sale_per_cust
FROM city_table as ct
JOIN city_rent as cr
ON ct.city_name = cr.city_name
ORDER BY avg_sale_per_cust DESC;

-- Sales growth rate: Calculate the percentage growth rate (or decline) in sales over different periods (by monthly) for each city
WITH monthly_sales
AS
(
	SELECT
		ci.city_name,
		MONTH(s.sales_date) as monthn,
		YEAR(s.sales_date) as yearn,
		SUM(s.total) as total_sale
	FROM sales as s
	JOIN customers as cu
	ON s.customer_id = cu.customer_id
	JOIN city as ci
	ON ci.city_id = cu.city_id
	GROUP BY ci.city_name, monthn, yearn
	ORDER BY ci.city_name, yearn, monthn
),
last_month_sale
AS
(
		SELECT
			city_name,
			monthn,
			yearn,
			total_sale,
			LAG(total_sale, 1) OVER(PARTITION BY city_name ORDER BY yearn, monthn) as last_month_sale
        FROM monthly_sales
)

SELECT
	city_name,
    monthn,
    yearn,
    total_sale,
    last_month_sale,
    ROUND(
			(total_sale - last_month_sale)/ last_month_sale * 100, 
		 2) as growth_ratio
FROM last_month_sale
WHERE
	last_month_sale IS NOT NULL;

-- Market Potential Analysis: Identify top 3 cities based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumers
WITH city_table
AS
(
	SELECT
		ci.city_name,
		SUM(s.total) as total_sale,
		COUNT(DISTINCT s.customer_id) as total_customers,
		ROUND(SUM(s.total) / COUNT(DISTINCT s.customer_id), 2) as avg_sale_per_cust
	FROM sales as s
	JOIN customers as cu
	ON s.customer_id = cu.customer_id
	JOIN city as ci
	ON ci.city_id = cu.city_id
	GROUP BY ci.city_name
	ORDER BY total_sale
),
city_rent
AS 
(
	SELECT
		city_name,
        estimated_rent,
        ROUND((population * 0.25 / 1000000), 2) as estimated_coffee_consumer_in_millions
	FROM city
)
SELECT
	ct.city_name,
    ct.total_sale,
    cr.estimated_rent as total_rent,
    ct.total_customers,
    cr.estimated_coffee_consumer_in_millions,
    ct.avg_sale_per_cust,
    ROUND(cr.estimated_rent / ct.total_customers, 2) as avg_rent_per_cust
FROM city_table as ct
JOIN city_rent as cr
ON ct.city_name = cr.city_name
ORDER BY ct.city_name;
	











