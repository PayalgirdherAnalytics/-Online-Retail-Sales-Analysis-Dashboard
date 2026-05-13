-- =========================================
-- ONLINE RETAIL SALES ANALYSIS
-- =========================================

-- Database: Online Retail Dataset
-- Tool Used: SQL
-- Objective: Analyze sales, customers, products, and returns

-- ----------------------------------------------------------
-- 1. What is the Total Revenue generated?
-- ----------------------------------------------------------

SELECT
    SUM(quantity * unit_price) AS total_revenue
FROM fact_sales
WHERE quantity > 0;

-- ----------------------------------------------------------
-- 2. How does revenue change Month by Month?
-- ----------------------------------------------------------

 SELECT 
	YEAR(invoice_date) AS year,
    MONTH(invoice_date) AS month,
    SUM(revenue) as total_revenue
FROM fact_sales
GROUP BY year,month
ORDER BY year,month;

-- ----------------------------------------------------------
-- 3. Top 5 Countries by Revenue.
-- ----------------------------------------------------------

SELECT c.country, SUM(f.revenue) AS total_revenue
FROM fact_sales f
JOIN dim_customer c 
ON f.customer_id = c.customer_id 
GROUP BY c.country
ORDER BY total_revenue DESC
LIMIT 5;

-- ----------------------------------------------------------
-- 4. Top 10 Products by Revenue.
-- ----------------------------------------------------------

SELECT p.description, SUM(f.revenue) AS total_revenue
FROM fact_sales f
JOIN dim_product p 
ON f.stock_code = p.stock_code
GROUP BY p.description,p.stock_code
ORDER BY total_revenue DESC 
LIMIT 10;

-- ----------------------------------------------------------
-- 5. Top 10 Customers by Revenue.
-- ----------------------------------------------------------

SELECT c.customer_id,
	SUM(f.revenue) AS total_revenue
FROM fact_sales f
JOIN dim_customer c 
ON f.customer_id = c.customer_id
GROUP BY c.customer_id
ORDER BY total_revenue DESC
LIMIT 10;


-- ----------------------------------------------------------
-- 6. Average Order Value
-- ----------------------------------------------------------

SELECT SUM(revenue)/COUNT(DISTINCT invoice_no) AS average_order_value
FROM fact_sales;

-- ----------------------------------------------------------
-- 7. Average Quantity Per Order
-- ----------------------------------------------------------

SELECT 
ROUND(AVG(order_quantity),2) AS avg_quantity_per_order
FROM (
    SELECT 
        invoice_no,
        SUM(quantity) AS order_quantity
    FROM fact_sales
    WHERE quantity > 0
    GROUP BY invoice_no
) AS orders;

-- ----------------------------------------------------------
-- 8. Return Rate
-- ----------------------------------------------------------

SELECT 
ROUND(
    ABS(SUM(CASE 
        WHEN quantity_flag = 'Return' 
        THEN quantity 
    END)) * 100.0
    /
    SUM(CASE 
        WHEN quantity_flag <> 'Return' 
        THEN quantity 
    END),
2) AS return_rate
FROM fact_sales;

-- ----------------------------------------------------------
-- 9. Return Rate Per Product
-- ----------------------------------------------------------

SELECT p.description,
	SUM(CASE WHEN f.quantity_flag = 'Return' THEN ABS(f.quantity) ELSE 0 END)/
    SUM(CASE WHEN f.quantity_flag != 'Return' THEN f.quantity ELSE 0 END)
    AS return_rate
FROM fact_sales f
JOIN dim_product p 
ON f.stock_code = p.stock_code
GROUP BY p.stock_code,p.description
HAVING return_rate IS NOT NULL
ORDER BY return_rate DESC;

-- ----------------------------------------------------------
-- 10. AVG REVENUE PER CUSTOMER (PER COUNTRY)
-- ----------------------------------------------------------

SELECT c.customer_id,
	c.country,
    AVG(f.revenue) AS avg_revenue
FROM fact_sales f
JOIN dim_customer c
ON f.customer_id = c.customer_id
GROUP BY c.customer_id,c.country
ORDER BY avg_revenue DESC;
-- ----------------------------------------------------------
-- 11. MONTH OVER MONTH REVENUE GROWTH
-- ----------------------------------------------------------

SELECT 
    year,
    month,
    total_revenue,
    previous_month_sales,
    ROUND(
        (total_revenue - previous_month_sales) * 100 
        / previous_month_sales,
    2) AS mom_growth
FROM (
    SELECT 
        year,
        month,
        total_revenue,
        LAG(total_revenue) OVER(
            ORDER BY year, month
        ) AS previous_month_sales
    FROM (
        SELECT 
            YEAR(invoice_date) AS year,
            MONTH(invoice_date) AS month,
            SUM(revenue) AS total_revenue
        FROM fact_sales
        GROUP BY year, month
    ) AS monthly_sales
) AS final_table;