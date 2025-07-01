-- sample data population generated with the help of AI
-- Insert categories (hierarchical structure)
INSERT INTO categories (category_name, parent_category_id) VALUES
('Electronics', NULL),
('Clothing', NULL),
('Home & Garden', NULL),
('Smartphones', 1),
('Laptops', 1),
('Men''s Clothing', 2),
('Women''s Clothing', 2),
('Furniture', 3),
('Kitchen', 3);

-- Insert users (diverse dataset for analysis)
INSERT INTO users (email, first_name, last_name, birth_date, gender, country, city) VALUES
('john.ellis@email.com', 'John', 'Doe', '1985-03-15', 'M', 'USA', 'New York'),
('jane.smith@email.com', 'Jane', 'Smith', '1990-07-22', 'F', 'USA', 'Los Angeles'),
('mike.chapman@email.com', 'Mike', 'Johnson', '1982-11-08', 'M', 'Canada', 'Toronto'),
('sarah.williams@email.com', 'Sarah', 'Williams', '1995-01-30', 'F', 'UK', 'London'),
('david.brown@email.com', 'David', 'Brown', '1988-09-12', 'M', 'Australia', 'Sydney'),
('emma.davis@email.com', 'Emma', 'Davis', '1992-05-18', 'F', 'USA', 'Chicago'),
('alex.wilson@email.com', 'Alex', 'Wilson', '1987-12-03', 'Other', 'Germany', 'Berlin'),
('lisa.moore@email.com', 'Lisa', 'Moore', '1993-04-25', 'F', 'France', 'Paris'),
('tom.taylor@email.com', 'Tom', 'Taylor', '1980-08-17', 'M', 'USA', 'Houston'),
('anna.anderson@email.com', 'Anna', 'Anderson', '1991-10-09', 'F', 'Sweden', 'Stockholm');

-- Insert products with JSON dimensions
INSERT INTO products (product_name, category_id, brand, price, cost, stock_quantity, description, weight_kg, dimension) VALUES
('iPhone 14 Pro', 4, 'Apple', 999.99, 650.00, 50, 'Latest iPhone with advanced camera system', 0.206, '{"length": 15.1, "width": 7.1, "height": 0.79}'),
('Samsung Galaxy S23', 4, 'Samsung', 899.99, 580.00, 75, 'Flagship Android smartphone', 0.168, '{"length": 14.6, "width": 7.1, "height": 0.76}'),
('MacBook Pro 16"', 5, 'Apple', 2499.99, 1650.00, 25, 'Professional laptop for creative work', 2.15, '{"length": 35.57, "width": 24.81, "height": 1.68}'),
('Dell XPS 13', 5, 'Dell', 1299.99, 850.00, 40, 'Ultrabook for professionals', 1.27, '{"length": 29.6, "width": 19.9, "height": 1.17}'),
('Men''s Casual Shirt', 6, 'Ralph Lauren', 89.99, 35.00, 100, 'Cotton casual shirt', 0.25, '{"chest": 102, "length": 76, "sleeve": 64}'),
('Women''s Summer Dress', 7, 'Zara', 79.99, 30.00, 80, 'Floral summer dress', 0.3, '{"bust": 86, "waist": 70, "length": 95}'),
('Dining Table', 8, 'IKEA', 299.99, 150.00, 15, 'Wooden dining table for 4', 25.5, '{"length": 120, "width": 75, "height": 74}'),
('Coffee Maker', 9, 'Breville', 199.99, 120.00, 60, 'Automatic drip coffee maker', 3.2, '{"length": 35, "width": 20, "height": 38}');

-- Generate orders and order items (complex realistic data)
INSERT INTO orders (user_id, order_date, status, total_amount, shipping_cost, tax_amount, payment_method, shipping_address) VALUES
(1, '2024-01-15 10:30:00', 'delivered', 1089.98, 9.99, 87.20, 'credit_card', '{"street": "123 Main St", "city": "New York", "state": "NY", "zip": "10001", "country": "USA"}'),
(2, '2024-01-18 14:22:00', 'delivered', 899.99, 0.00, 72.00, 'paypal', '{"street": "456 Oak Ave", "city": "Los Angeles", "state": "CA", "zip": "90210", "country": "USA"}'),
(3, '2024-01-20 09:15:00', 'shipped', 2499.99, 19.99, 200.00, 'credit_card', '{"street": "789 Pine St", "city": "Toronto", "state": "ON", "zip": "M5V 3A1", "country": "Canada"}'),
(1, '2024-02-01 16:45:00', 'delivered', 169.98, 7.99, 13.60, 'debit_card', '{"street": "123 Main St", "city": "New York", "state": "NY", "zip": "10001", "country": "USA"}'),
(4, '2024-02-05 11:30:00', 'cancelled', 379.98, 12.99, 30.40, 'credit_card', '{"street": "321 Queen St", "city": "London", "zip": "SW1A 1AA", "country": "UK"}'),
(5, '2024-02-10 13:20:00', 'delivered', 1299.99, 15.99, 104.00, 'bank_transfer', '{"street": "654 George St", "city": "Sydney", "state": "NSW", "zip": "2000", "country": "Australia"}');

INSERT INTO order_items (order_id, product_id, quantity, unit_price, total_price) VALUES
(1, 1, 1, 999.99, 999.99),
(1, 5, 1, 89.99, 89.99),
(2, 2, 1, 899.99, 899.99),
(3, 3, 1, 2499.99, 2499.99),
(4, 6, 1, 79.99, 79.99),
(4, 5, 1, 89.99, 89.99),
(5, 8, 2, 199.99, 399.98),
(6, 4, 1, 1299.99, 1299.99);

-- Insert reviews
INSERT INTO reviews (user_id, product_id, order_id, rating, review_text, is_verified) VALUES
(1, 1, 1, 5, 'Amazing phone with great camera quality!', TRUE),
(1, 5, 1, 4, 'Good quality shirt, fits well', TRUE),
(2, 2, 2, 4, 'Great Android phone, battery life is excellent', TRUE),
(3, 3, 3, 5, 'Perfect laptop for video editing work', TRUE);

-- Insert shopping cart data (for abandoned cart analysis)
INSERT INTO shopping_cart (user_id, product_id, quantity, added_date) VALUES
(7, 1, 1, '2024-02-15 10:30:00'),
(8, 3, 1, '2024-02-14 15:22:00'),
(9, 6, 2, '2024-02-16 12:45:00');