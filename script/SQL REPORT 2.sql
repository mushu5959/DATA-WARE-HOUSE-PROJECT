/*
===============================================================================
Customer Report
===============================================================================
Purpose:
    - This report consolidates key customer metrics and behaviors

Highlights:
    1. Gathers essential fields such as names, ages, and transaction details.
	2. Segments customers into categories (VIP, Regular, New) and age groups.
    3. Aggregates customer-level metrics:
	   - total orders
	   - total sales
	   - total quantity purchased
	   - total products
	   - lifespan (in months)
    4. Calculates valuable KPIs:
	    - recency (months since last order)
		- average order value
		- average monthly spend
===============================================================================
*/

-- =============================================================================
-- Create Report: gold.report_customers
-- =============================================================================

CREATE VIEW gold.CUSTOMERS_REPORT AS
WITH customer_reports AS 
(
SELECT 
f.order_number,
f.product_key,
f.order_date,
f.sales_amount,
f.quantity,
c.customer_key,
c.customer_number,
DATEDIFF(year,c.birthdate,GETDATE()) AS customer_age,
CONCAT(first_name,'-',last_name) AS customer_name
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON f.customer_key=c.customer_key
WHERE order_date IS NOT NULL 
)

, customer_aggregation AS
(

SELECT
customer_key,
customer_number,
customer_name,
customer_age,
COUNT(DISTINCT order_date) AS totalorders,
SUM(sales_amount) AS totalamount,
SUM(quantity) AS totalquantity,
COUNT(DISTINCT product_key) AS totalproduct,
MAX (order_date) AS lastorder,
DATEDIFF(year,MIN(order_date),MAX(order_date)) AS lifespan
FROM customer_reports
GROUP BY customer_key,
customer_number,
customer_name,
customer_age
)

SELECT
customer_key,
customer_number,
customer_name,
customer_age,
CASE
WHEN customer_age<20 THEN 'under 20'
WHEN customer_age between 20 and 29 THEN '20-29'
WHEN customer_age between 30 and 39 THEN '30-39'
WHEN customer_age between 40 and 49 THEN '40-49'
ELSE '50 AND ABOVE'
END AS age_group,

CASE
		WHEN lifespan>=12 AND  totalamount>5000 THEN 'VIP'
		WHEN lifespan>=12 AND totalamount>1000 THEN 'REGULAR'
		ELSE 'NEW'
END AS customer_segment,
totalorders,
DATEDIFF(month,lastorder,GETDATE()) AS recency,

totalamount,
totalquantity,
 totalproduct,
 lastorder,
 lifespan,
 --Compuate average order value (AVO) 
 CASE WHEN totalamount = 0 THEN 0
 ELSE totalamount / totalorders
 END AS avg_order_value,
 --compuate average monthly apend 
 CASE WHEN lifespan = 0 THEN totalamount
 ELSE totalamount/lifespan
 END AS avg_monthly_spend
 FROM customer_aggregation