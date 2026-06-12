SELECT
order_date,
total_sales,

FROM  (

SELECT 
DATETRUNC(month,order_date)month_date,
SUM(sales_amount) 
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(month,order_date)
ORDER BY DATETRUNC(month,order_date)
)t  
