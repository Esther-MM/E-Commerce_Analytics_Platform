-- User management and Security

USE ecommerce_analytics;

-- 1. Create different user roles
CREATE USER 'analytics_read_only'@'%' IDENTIFIED BY 'SecurePassword123!';
CREATE USER 'sales_user'@'%' IDENTIFIED BY 'SalesPass456!';
CREATE USER 'admin_user'@'%' IDENTIFIED BY 	'AdminPass789!';

-- 2. Grant appropriate permissions
-- Analytics user - read-only access with limited stored procedure execution 
GRANT SELECT ON ecommerce_analytics.* TO 'analytics_read_only'@'%';
GRANT EXECUTE ON PROCEDURE ecommerce_analytics.CalculateCustomerSegmentation TO 'analytics_read_only'@'%';
GRANT EXECUTE ON PROCEDURE ecommerce_analytics.GetLowStockAlerts TO 'analytics_read_only'@'%';

-- Sales user - can modify users, orders and order_items; read-only access to products and categories
GRANT SELECT, INSERT, UPDATE ON ecommerce_analytics.users TO 'sales_user'@'%';
GRANT SELECT, INSERT, UPDATE ON ecommerce_analytics.orders TO 'sales_user'@'%';
GRANT SELECT, INSERT, UPDATE ON ecommerce_analytics.order_items TO 'sales_user'@'%';
GRANT SELECT ON ecommerce_analytics.products TO 'sales_user'@'%';
GRANT SELECT ON ecommerce_analytics.categories TO 'sales_user'@'%';

-- Admin user - full access
GRANT ALL PRIVILEGES ON ecommerce_analytics.* TO 'admin_user'@'%';


-- 3. Create views for sensitive data protection
CREATE VIEW customer_safe_view AS
SELECT
	user_id,
    first_name,
    CONCAT(LEFT(last_name, 1), '****') AS last_name_masked,
    CONCAT(LEFT(email, 3), '****@', SUBSTRING_INDEX(email, '@', -1)) AS email_masked,
    registration_date,
    country,
    city,
    is_active
FROM users;


-- 4. Create audit table for sensitive operations
CREATE TABLE audit_log ( 
	audit_id INT PRIMARY KEY AUTO_INCREMENT,
    table_name VARCHAR(50) NOT NULL,
    operation VARCHAR(10),
    old_values JSON,
    new_values JSON,
    user_name VARCHAR(100),
    event_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- 5. Audit trigger for user changes 
DELIMITER //
CREATE TRIGGER audit_user_changes
	AFTER UPDATE ON users
    FOR EACH ROW
BEGIN
	INSERT INTO audit_log (table_name, operation, old_values, new_values, user_name)
		VALUES (
			'users',
            'update',
            JSON_OBJECT('user_id', OLD.user_id, 'email', OLD.email, 'first_name', OLD.first_name, 'last_name', OLD.last_name),
            JSON_OBJECT('user_id', NEW.user_id, 'email', NEW.email, 'first_name', NEW.first_name, 'last_name', NEW.last_name),
            USER()
        );
END //
DELIMITER ;

