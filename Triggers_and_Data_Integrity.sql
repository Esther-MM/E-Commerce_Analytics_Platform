-- Created Automated Business Loogic

USE ecommerce_analytics;

-- 1. Trigger to update product stock after order
DELIMITER //
CREATE TRIGGER update_stock_after_order
	AFTER INSERT ON order_items
    FOR EACH ROW
BEGIN
	UPDATE products
    SET stock_quantity = stock_quantity - NEW.quantity,
		updated_at = CURRENT_TIMESTAMP()
	WHERE product_id = NEW.product_id;
END //
DELIMITER ;





-- 2. Trigger to Log Order Status Changes
-- First create the log table
CREATE TABLE  order_status_log(
	log_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT NOT NULL,
    old_status VARCHAR(20),
    new_status VARCHAR(20),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

-- Create the trigger
DELIMITER //
CREATE TRIGGER log_order_status_change
	AFTER UPDATE ON orders
	FOR EACH ROW
BEGIN
	IF OLD.status != NEW.status THEN
		INSERT INTO order_status_log (order_id, old_status, new_status)
        VALUES (NEW.order_id, OLD.status, NEW.status);
	END IF;
END //
DELIMITER ;





-- 3. Trigger to automatically verify reviews from actaual purchasers
DELIMITER //
CREATE TRIGGER verify_review_authenticity
	BEFORE INSERT ON reviews
    FOR EACH ROW
BEGIN
	DECLARE purchase_exists INT DEFAULT 0;
    
    SELECT COUNT(*) INTO purchase_exists
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.user_id = NEW.user_id
		AND oi.product_id = NEW.product_id
        AND o.status = 'delivered';
	
    IF purchase_exists > 0 THEN
		SET NEW.is_verified = TRUE;
	ELSE
		SET NEW.is_verified = FALSE;
	END IF;
END //
DELIMITER ;








