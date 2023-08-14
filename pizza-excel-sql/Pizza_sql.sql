-- ------------ Data Cleaning ------------ --

-- Change the data type of order_id

ALTER TABLE pizza_sales
ADD COLUMN new_quantity INT AFTER pizza_id;

UPDATE pizza_sales
SET new_quantity = CAST(quantity AS SIGNED);

ALTER TABLE pizza_sales
DROP COLUMN quantity;

ALTER TABLE pizza_sales
CHANGE COLUMN new_quantity quantity INT;

-- Change the data type of total_price
ALTER TABLE pizza_sales
ADD COLUMN new_total_price FLOAT AFTER order_time;

UPDATE pizza_sales
SET new_total_price = CAST(total_price AS FLOAT);

ALTER TABLE pizza_sales
DROP COLUMN total_price;

ALTER TABLE pizza_sales
CHANGE COLUMN new_total_price total_price FLOAT;

-- Change the data type of order_date.
UPDATE pizza_sales
SET order_date = STR_TO_DATE(order_date, '%d-%m-%Y');

ALTER TABLE pizza_sales
MODIFY COLUMN order_date DATE;

-- Change the data type of drder_time.
UPDATE pizza_sales
SET order_time = STR_TO_DATE(order_time, '%H:%i:%s');

ALTER TABLE pizza_sales
MODIFY COLUMN order_time TIME;


SELECT * FROM pizza_sales
-- 
-- ------------ Data Analysis ------------ --

-- 1- Total Ravenue
SELECT ROUND(SUM(total_price), 2) AS Total_Revenue
FROM pizza_sales;

-- 2- Average Oreder VAlue
SELECT ROUND(SUM(total_price)/COUNT(DISTINCT(order_id)), 2) AS Avg_Order_Value 
FROM pizza_sales;

-- 3- Total Pizzas Sold
SELECT ROUND(SUM(total_price)/COUNT(DISTINCT(order_id)), 2) AS Avg_Order_Value 
FROM pizza_sales;

-- 4- Total Orders
SELECT count(DISTINCT order_id) AS Total_Orders
FROM pizza_sales;

-- 5- Average Pizzas per Order
SELECT CAST(SUM(quantity) / COUNT(DISTINCT order_id) AS UNSIGNED) AS Avg_Pizzas_per_Order
FROM pizza_sales;

-- 6- Daily Trend of Orders
SELECT 
    DAYNAME(order_date) AS Order_Day,
    COUNT(DISTINCT order_id) AS Total_Orders
FROM pizza_sales
GROUP BY DAYNAME(order_date);


-- 6- Hourly Trend of Orders
SELECT 
    EXTRACT(HOUR FROM order_time) AS Order_Hour,
    COUNT(DISTINCT order_id) AS Total_Orders
FROM pizza_sales
GROUP BY  EXTRACT(HOUR FROM order_time)

-- 7- Percentage of Sales by Pizza Category
SELECT 
    pizza_category, 
    CAST(SUM(total_price) AS UNSIGNED) AS Total_Sales,
    CONCAT(ROUND(SUM(total_price) * 100 / (SELECT SUM(total_price) FROM pizza_sales ), 2), '%') AS Perc_Total_Sales
FROM pizza_sales
GROUP BY pizza_category;


-- 8- Percentage of Sales by Pizza Category filtered by Month

SET @month_number = 5;

SELECT 
    pizza_category, 
    CAST(SUM(total_price) AS UNSIGNED) AS Total_Sales,
    CONCAT(ROUND(100 * SUM(total_price) / (SELECT SUM(total_price) FROM pizza_sales WHERE MONTH(order_date) = @month_number), 2), '%') AS Perc_Total_Sales
FROM pizza_sales
WHERE MONTH(order_date) = @month_number
GROUP BY pizza_category;


-- 9- Percentage of Sales by Pizza Size
SELECT 
    pizza_size, 
    CAST(SUM(total_price) AS UNSIGNED) AS Total_Sales,
    CONCAT(CAST(ROUND(100 * SUM(total_price) / (SELECT SUM(total_price) FROM pizza_sales), 2) AS DECIMAL(5, 2)), '%') AS Perc_Total_Sales

FROM pizza_sales
GROUP BY pizza_size
ORDER BY Perc_Total_Sales DESC;


-- 9- Percentage of Sales by Pizza Size Filtered by Quarter
SET @quarter_number = 1;

SELECT 
    pizza_size, 
    CAST(SUM(total_price) AS UNSIGNED) AS Total_Sales,
    CONCAT(CAST(ROUND(100 * SUM(total_price) / (SELECT SUM(total_price) FROM pizza_sales WHERE QUARTER(order_date) = @quarter_number), 2) AS DECIMAL(5, 2)), '%') AS Perc_Total_Sales
FROM pizza_sales
WHERE QUARTER(order_date) = @quarter_number
GROUP BY pizza_size
ORDER BY Perc_Total_Sales DESC;


-- 10- Total Pizza sold by Pizzas Category
SELECT pizza_category, SUM(quantity) AS Total_Pizzas_Sold
FROM pizza_sales
GROUP BY pizza_category;

-- 11- Top 5 Best Sellers by Total Pizzas Sold
SELECT pizza_name, SUM(quantity) AS Total_Pizzas_Sold
FROM pizza_sales
GROUP BY pizza_name
ORDER BY Total_Pizzas_Sold DESC
LIMIT 5;

-- 12- Bottom 5 Best Sellers by Total Pizzas Sold
SELECT pizza_name, SUM(quantity) AS Total_Pizzas_Sold
FROM pizza_sales
GROUP BY pizza_name
ORDER BY Total_Pizzas_Sold  ASC
LIMIT 5;
