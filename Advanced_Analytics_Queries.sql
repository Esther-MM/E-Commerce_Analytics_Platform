-- Business Intelligence Queries

USE ecommerce_analytics;

-- 1. Customer Lifetime Value (CLV) Analysis with Window Function
WITH 
customer_metrics AS (
	SELECT
		u.user_id,
		u.first_name,
		u.last_name,
		u.registration_date,
		COUNT(o.order_id) OVER (PARTITION BY u.user_id) AS total_orders,
		SUM(o.total_amount) OVER (PARTITION BY u.user_id) AS total_spent,
		AVG(o.total_amount) OVER (PARTITION BY u.user_id) AS avg_order_value,
		DATEDIFF(CURDATE(), u.registration_date) AS days_since_registration,
		FIRST_VALUE(o.order_date) OVER (PARTITION BY u.user_id ORDER BY o.order_date) AS first_order_date,
		LAST_VALUE(o.order_date) OVER (PARTITION BY u.user_id ORDER BY o.order_date 
			ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
		) AS last_order_date
	FROM users u
	LEFT JOIN orders o ON u.user_id = o.user_id AND o.status != 'CANCELLED'
),
clv_calculation AS (
	SELECT *,
		CASE
			WHEN days_since_registration > 0 THEN (total_spent / days_since_registration) * 365
			ELSE 0
		END AS estimated_annual_value,
		NTILE(5) OVER (ORDER BY total_spent DESC) AS value_quintile
	FROM customer_metrics
)
SELECT 
	user_id,
	CONCAT(first_name, ' ', last_name) AS customer_name,
	MAX(total_orders) AS total_orders,
	ROUND(MAX(total_spent), 2) AS total_spent,
	ROUND(MAX(avg_order_value), 2) AS avg_order_value,
	ROUND(MAX(estimated_annual_value), 2) AS estimated_annual_value,
	MAX(
		CASE value_quintile
			WHEN 1 THEN 'High Value'
			WHEN 2 THEN 'Medium-High Value'
			WHEN 3 THEN 'Medium Value'
			WHEN 4 THEN 'Medium-Low Value'
			WHEN 5 THEN 'Low Value'
		END
	) AS customer_segments
FROM clv_calculation
GROUP BY user_id, first_name, last_name
ORDER BY total_spent DESC;





-- 2. Product performance analysis with JSON functions
SELECT
	p.product_id,
    p.product_name,
    c.category_name,
    p.brand,
    p.price,
    JSON_EXTRACT(p.dimension, '$.length') AS length_cm,
    JSON_EXTRACT(p.dimension, '$.width') AS width_cm,
    COUNT(oi.order_item_id) AS units_sold,
    SUM(oi.total_price) AS total_revenue,
    ROUND(AVG(r.rating), 2) AS avg_rating,
    COUNT(r.review_id) AS review_count,
    ROUND((p.price - p.cost) / p.price * 100, 2) AS profit_margin_percent
FROM products p
LEFT JOIN categories c ON p.category_id = c.category_id
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN reviews r on p.product_id = r.product_id
GROUP BY p.product_id, p.product_name, c.category_name, p.brand, p.price
HAVING units_sold > 0
ORDER BY total_revenue DESC;





-- 3. Monthly Revenue Trend with Growth Rate
WITH 
monthly_revenue AS (
	SELECT
		DATE_FORMAT(order_date, '%Y-%m') AS month_year,
        SUM(total_amount) AS revenue,
        COUNT(order_id) AS order_count,
        COUNT(DISTINCT user_id) as unique_customers
	FROM orders
    WHERE status != 'cancelled'
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
),
revenue_with_growth AS (
	SELECT *,
		LAG(revenue) OVER (ORDER BY month_year) AS previous_month_revenue        
	FROM monthly_revenue
)
SELECT
	month_year,
    ROUND(revenue, 2) AS monthly_revenue,
    order_count,
    unique_customers,
    COALESCE(ROUND(((revenue - previous_month_revenue) / previous_month_revenue) * 100 ,2), 0) AS revenue_growth_percent,
    ROUND(revenue / order_count, 2) AS avg_order_value
FROM revenue_with_growth
ORDER BY month_year;





-- 4. Customer Cohort Analysis
WITH 
first_orders AS (
	SELECT
		user_id,
        DATE_FORMAT(MIN(order_date), '%Y-%m') AS cohort_month
	FROM orders
    WHERE status != 'CANCELLED'
    GROUP BY user_id
),
monthly_activity AS (
	SELECT DISTINCT
		fo.user_id,
        fo.cohort_month,
        DATE_FORMAT(o.order_date, '%Y-%m') AS activity_month,
        PERIOD_DIFF(
			CAST(REPLACE( DATE_FORMAT(o.order_date, '%Y-%m'), '-', '') AS UNSIGNED),
            CAST(REPLACE(fo.cohort_month, '-', '') AS UNSIGNED)
        ) AS period_number
	FROM first_orders fo
    LEFT JOIN orders o on fo.user_id = o.user_id
    WHERE o.status != 'CANCELLED'
)
SELECT
	cohort_month,
    COUNT(DISTINCT CASE WHEN period_number = 0 THEN user_id END) AS customers,
    ROUND(COUNT(DISTINCT CASE WHEN period_number = 1 THEN user_id END) / 
		  COUNT(DISTINCT CASE WHEN period_number = 0 THEN user_id END) * 100, 2) as month_1_retention,
	ROUND(COUNT(DISTINCT CASE WHEN period_number = 2 THEN user_id END) / 
		  COUNT(DISTINCT CASE WHEN period_number = 0 THEN user_id END) * 100, 2) as month_2_retention
FROM monthly_activity
GROUP BY cohort_month
ORDER BY cohort_month;





-- 5. Abandoned Cart Analysis
SELECT
	u.user_id,
    CONCAT(u.first_name, ' ', u.last_name) AS customer_name,
    COUNT(sc.product_id) AS items_in_cart,
    SUM(p.price * sc.quantity) AS cart_value,
    MAX(sc.added_date) AS last_cart_activity,
	DATEDIFF(CURDATE(), MAX(sc.added_date)) AS days_since_last_activity,
    CASE
		WHEN DATEDIFF(CURDATE(), MAX(sc.added_date)) <= 1 THEN 'Hot Lead'
        WHEN DATEDIFF(CURDATE(), MAX(sc.added_date)) <= 7 THEN 'Warm Lead'
        WHEN DATEDIFF(CURDATE(), MAX(sc.added_date)) <= 30 THEN 'Cold Lead'
        ELSE 'Inactive'
	END AS lead_status
FROM shopping_cart sc
JOIN users u on sc.user_id = u.user_id
JOIN products p on sc.product_id = p.product_id
GROUP BY user_id, first_name, last_name
HAVING cart_value > 100
ORDER BY cart_value DESC, days_since_last_activity;
    




-- 6. Full text search query example
SELECT
	product_id,
    product_name,
    description,
    price,
    MATCH(product_name, description) AGAINST('phone smartphone mobile' IN NATURAL LANGUAGE MODE) AS relevance_score
FROM products
WHERE MATCH(product_name, description) AGAINST('phone smartphone mobile' IN NATURAL LANGUAGE MODE)
ORDER BY relevance_score DESC;



