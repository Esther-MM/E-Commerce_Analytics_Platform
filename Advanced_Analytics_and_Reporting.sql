-- Comprehensive business reports

USE ecommerce_analytics;

-- Advanced RFM Analysis (Recency, Frequency, Monetary)
WITH 
customer_rfm AS (
	SELECT
		u.user_id,
        CONCAT(u.first_name, ' ', u.last_name) AS customer_name,
        COALESCE(DATEDIFF(CURDATE(), MAX(o.order_date)), 999) AS recency_days,
        COUNT(o.order_id) AS frequency,
        COALESCE(SUM(o.total_amount), 0) AS monetary_value
    FROM users u
    LEFT JOIN orders o ON u.user_id = o.user_id
    GROUP BY u.user_id, u.first_name, u.last_name
),

rfm_scores AS (
	SELECT *,
		CASE
			WHEN recency_days <= 30 THEN 5
            WHEN recency_days <= 60 THEN 4
            WHEN recency_days <= 90 THEN 3
            WHEN recency_days <= 100 THEN 2
            ELSE 1
		END AS recency_score,
        CASE 
			WHEN frequency >= 5 THEN 5
            WHEN frequency >= 3 THEN 4
            WHEN frequency >= 2 THEN 3
            WHEN frequency >= 1 THEN 2
            ELSE 1
		END AS frequency_score,
        CASE
			WHEN monetary_value >= 2000 THEN 5
            WHEN monetary_value >= 1000 THEN 4
            WHEN monetary_value >= 500 THEN 3
            WHEN monetary_value >= 100 THEN 2
            ELSE 1
		END AS monetary_score
	FROM customer_rfm
)
SELECT
	user_id,
    customer_name,
    recency_days,
    frequency,
    ROUND(monetary_value, 2) AS monetary_value,
    CONCAT(recency_score, frequency_score, monetary_score) AS rfm_score,
	CASE
		WHEN recency_score >= 4 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'Champions'
        WHEN recency_score >= 3 AND frequency_score >= 3 AND monetary_score >= 4 THEN 'Loyal Customers'
        WHEN recency_score >= 4 AND frequency_score >= 2 AND monetary_score >= 3 THEN 'New Customers'
        WHEN recency_score >= 3 AND frequency_score >= 2 AND monetary_score >= 2 THEN 'Potential Loyalists'
        WHEN recency_score >= 2 AND frequency_score >= 2 AND monetary_score >= 2 THEN 'At Risk'
        WHEN recency_score >= 2 AND frequency_score >= 2 AND monetary_score >= 4 THEN 'Cannot Lose Them'
        WHEN recency_score >= 2 AND frequency_score >= 2 AND monetary_score >= 2 THEN 'Hibernating'
		ELSE 'Others'
	END AS customer_segment
FROM rfm_scores
ORDER BY monetary_value DESC;





-- Product Recommendation Engine (Market Basket Analysis)
WITH 
product_pairs AS (
	SELECT
		oi1.product_id AS product_a,
        oi2.product_id AS product_b,
        COUNT(*)  AS frequency
	FROM order_items oi1
    JOIN order_items oi2 ON oi1.order_id = oi2.order_id
		AND oi1.product_id < oi2.product_id
	GROUP BY oi1.product_id, oi2.product_id
    HAVING frequency >= 2
),

product_support AS (
	SELECT
		product_id,
        COUNT(DISTINCT order_id) AS product_orders
	FROM order_items
    GROUP BY product_id
),

total_orders AS (
	SELECT COUNT(DISTINCT order_id) AS total_order_count
    FROM order_items
)

SELECT
	p1.product_name AS product_a,
    p2.product_name AS product_b,
    pp.frequency AS co_occurrence,
    ROUND(pp.frequency / ps1.product_orders * 100, 2) AS confidence_a_to_b,
    ROUND(pp.frequency / ps2.product_orders * 100, 2) AS confidence_b_to_a,
    ROUND(pp.frequency / (ps1.product_orders * ps2.product_orders / t.total_order_count), 2) AS lift
FROM product_pairs pp
JOIN products p1 ON pp.product_a = p1.product_id
JOIN products p2 ON  pp.product_b = p2.product_id
JOIN product_support ps1 ON  pp.product_a = ps1.product_id
JOIN product_support ps2 ON pp.product_b = ps2.product_id
CROSS JOIN total_orders t
ORDER BY lift DESC, confidence_a_to_b DESC;





-- Seasonal Sales Analysis
SELECT 
	YEAR(o.order_date) AS year,
    MONTH(o.order_date) AS month,
    MONTHNAME(o.order_date) AS month_name,
    QUARTER(o.order_date) AS quarter,
    COUNT(o.order_id) AS total_orders,
    ROUND(SUM(o.total_amount), 2) AS total_revenue,
    ROUND(AVG(o.total_amount), 2) AS average_order_value,
    COUNT(DISTINCT o.user_id) AS unique_customers,
    ROUND(SUM(o.total_amount) / COUNT(DISTINCT o.order_id) ,2) AS revenue_per_customer,
    
    -- Year-over-year comparison
    ROUND(
		SUM((o.total_amount) - LAG(SUM(o.total_amount)) OVER (
			PARTITION BY MONTH(o.order_date)
            ORDER BY YEAR(o.order_date)
		)) / LAG(SUM(o.total_amount)) OVER (
			PARTITION BY MONTH(o.order_date)
            ORDER BY YEAR(o.order_date)
		) * 100 ,2
	) AS yoy_growth_percent
    FROM orders o
    WHERE o.status != 'cancelled'
    GROUP BY YEAR(o.order_date), MONTH(o.order_date), MONTHNAME(o.order_date), QUARTER(o.order_date)
    ORDER BY year, month;
    
    
    
    
    
-- Customer Churn Prediction Analysis
WITH
customer_activity AS (
	SELECT
		u.user_id,
        u.registration_date,
        COUNT(o.order_id) AS total_orders,
        MAX(o.order_date) AS last_order_date,
        DATEDIFF(CURDATE(), MAX(o.order_date)) AS days_since_last_order,
        SUM(o.total_amount) AS total_spent,
        AVG(DATEDIFF(o.order_date, LAG(o.order_date) OVER (PARTITION BY u.user_id ORDER BY o.order_date))) AS avg_days_between_orders
	FROM users u
    LEFT JOIN orders o ON u.user_id = o.user_id
    GROUP BY  u.user_id, u.registration_date
    HAVING total_orders > 0
),

churn_indicators AS (
	SELECT *,
		CASE
			WHEN days_since_last_order > (avg_days_between_orders * 2) THEN 'High Risk'
            WHEN days_since_last_order > avg_days_between_orders THEN 'Medium Risk'
            ELSE 'Low Risk'
		END AS churn_risk,
        CASE
			WHEN total_orders = 1 AND days_since_last_order > 90 THEN 'One-time Buyer'
            WHEN total_orders > 1 AND days_since_last_order > 180 THEN 'Churned'
            ELSE 'Active'
		END AS customer_status
	FROM customer_activity
    WHERE avg_days_between_orders IS NOT NULL
)

SELECT 
	churn_risk,
    customer_status,
    COUNT(*) AS customer_count,
    ROUND(AVG(total_spent) ,2) AS avg_total_spent,
    ROUND(AVG(total_orders) ,2) AS avg_total_orders,
    ROUND(AVG(days_since_last_order) ,2) AS avg_days_since_last_orders
FROM churn_indicators
GROUP BY churn_risk, customer_status
ORDER BY 
	CASE churn_risk
		WHEN 'High Risk' THEN 1
        WHEN 'Medium Risk' THEN 2
        ELSE 3
	END,
    customer_count DESC;