-- Query Optimization Examples

USE ecommerce_analytics;

-- Optimization using EXPLAIN

-- Slower Query before optimization
EXPLAIN FORMAT = JSON
SELECT 
	u.user_id,
    u.first_name,
    COUNT(o.order_id) AS order_count,
    SUM(o.total_amount) AS total_spent
FROM users u 
LEFT JOIN orders o ON u.user_id = o.user_id
WHERE u.registration_date >= '2024-01-01'
GROUP BY u.user_id, u.first_name
HAVING total_spent > 500;

-- optimized version with better indexing strategy
CREATE INDEX idx_users_registration_date ON users(registration_date);
CREATE INDEX idx_orders_user_total ON orders(user_id, total_amount);

-- Create a materialized view alternative using a table
CREATE TABLE customer_summary AS
SELECT
	u.user_id,
    u.first_name,
    u.last_name,
    u.registration_date,
    COUNT(o.order_id) AS total_orders,
    COALESCE(SUM(o.total_amount), 0) AS total_spent,
    COALESCE(AVG(o.total_amount), 0) AS avg_order_value,
    MAX(o.order_date) AS last_order_date
FROM users u
LEFT JOIN orders o ON u.user_id = o.user_id AND o.status != 'cancelled'
GROUP BY u.user_id, u.first_name, u.last_name, u.registration_date;

-- Procedure to refresh the summary table
DELIMITER //
CREATE PROCEDURE RefreshCustomerSummary()
BEGIN
	TRUNCATE TABLE customer_summary;
    
    INSERT INTO customer_summary
	SELECT 
		u.user_id,
        u.first_name,
        u.last_name,
        u.registration_date,
        COUNT(o.order_id) AS total_orders,
        COALESCE(SUM(o.total_amount), 0) AS total_spent,
        COALESCE(AVG(o.total_amount), 0) AS avg_order_value,
		MAX(o.order_date) AS last_order_date
	FROM users u
    LEFT JOIN orders o ON u.user_id = o.user_id AND o.status != 'cancelled'
    GROUP BY u.user_id, u.first_name, u.last_name, u.registration_date;
END //
DELIMITER ;
