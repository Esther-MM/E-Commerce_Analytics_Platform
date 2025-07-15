-- Create Busines Logic Procedures

USE ecommerce_analytics;

-- 1. Stored procedure for calculating customer segmentation
DELIMITER //

-- Drop procedure if exists
DROP PROCEDURE IF EXISTS CalculateCustomerSegmentation;

CREATE PROCEDURE CalculateCustomerSegmentation()
BEGIN
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		ROLLBACK;
        RESIGNAL;
	END;
    
	START TRANSACTION;

	-- Drop temporary table if exists
	DROP TEMPORARY TABLE IF EXISTS temporary_customer_segments;

	-- Create temporary table for segmentation
	CREATE TEMPORARY TABLE temporary_customer_segments AS
	WITH 
	customer_stats AS (
		SELECT 
			u.user_id,
			COALESCE(COUNT(o.order_id), 0) AS order_count,
			COALESCE(SUM(o.total_amount), 0) AS total_spent,
			COALESCE(MAX(o.order_date), u.registration_date, 0) AS last_order_date,
			DATEDIFF(CURDATE(), COALESCE(MAX(o.order_date), u.registration_date, '1900-01-01')) AS days_since_last_order
		FROM users u
		LEFT JOIN orders o ON u.user_id = o.user_id
		AND o.status != 'CANCELLED'
		GROUP BY u.user_id, u.registration_date
	)
	SELECT 
		user_id,
		order_count,
		total_spent,
		days_since_last_order,
		CASE
			WHEN order_count >= 5 AND total_spent >= 1000 AND days_since_last_order <= 30 THEN 'Champions'
			WHEN order_count >= 3 AND total_spent >= 500 AND days_since_last_order <= 60 THEN 'Loyal Customers'
			WHEN order_count >= 2 AND days_since_last_order <= 90 THEN 'Potential Loyalists'
			WHEN order_count = 1 AND days_since_last_order <= 30 THEN 'New Customers'
			WHEN order_count >= 2 AND days_since_last_order > 90 THEN 'At Risk'
			WHEN order_count = 1 AND days_since_last_order > 90 THEN 'Lost Customers'
			ELSE 'Others'
		END AS segment
	FROM customer_stats;

	-- Return results
	SELECT
		segment,
		COUNT(*) AS customer_count,
		ROUND(AVG(total_spent), 2) AS avg_total_spent,
		ROUND(AVG(order_count), 2) AS avg_order_count
	FROM temporary_customer_segments
	GROUP BY segment
	ORDER BY customer_count DESC;

	COMMIT;
END //
DELIMITER ;





-- 2. Function to create profitability
DELIMITER //

-- Drop function if exists
DROP FUNCTION IF EXISTS CalculateOrderProfit;

CREATE FUNCTION CalculateOrderProfit(order_id_param INT)
RETURNS DECIMAL(10, 2)
READS SQL DATA
DETERMINISTIC
BEGIN
	DECLARE total_profit DECIMAL(10, 2) DEFAULT 0;
    
    SELECT
		SUM((oi.unit_price - p.cost) * oi.quantity) INTO total_profit
	FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    WHERE oi.order_id = order_id_param;
    
    RETURN COALESCE(total_profit, 0);
    
END //
DELIMITER ;





-- 3. Procedure for inventory management alerts
DELIMITER //

-- Drop procedure table if exists
DROP PROCEDURE IF EXISTS GetLowStockAlerts;

CREATE PROCEDURE GetLowStockAlerts(IN threshold_quantity INT)
BEGIN
	SELECT
		p.product_id,
        p.product_name,
        c.category_name,
        p.stock_quantity,
        p.price,
        COALESCE(SUM(oi.quantity), 0) AS units_sold_last_30_days,
        CASE
			WHEN p.stock_quantity = 0 THEN 'Out of Stock'
            WHEN p.stock_quantity <= threshold_quantity THEN 'Low Stock'
            ELSE 'Adequate'
		END AS stock_status
	FROM products p
    JOIN categories c ON p.category_id = c.category_id
    LEFT JOIN order_items oi ON p.product_id = oi.product_id
    LEFT JOIN orders o ON oi.order_id = o.order_id
		AND o.order_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
        AND o.status != 'cancelled'
	WHERE p.stock_quantity <= threshold_quantity
    GROUP BY p.product_id, p.product_name, c.category_name, p.stock_quantity, p.price
    ORDER BY p.stock_quantity ASC, units_sold_last_30_days DESC;
END//
DELIMITER ;
		


