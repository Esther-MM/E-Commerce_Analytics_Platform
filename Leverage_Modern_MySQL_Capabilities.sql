-- Using Window Functions for Advanced Analytics

USE ecommerce_analytics;

-- 1. Running totals and moving averages
SELECT
	DATE(order_date) as order_date,
    COUNT(order_id) as daily_orders,
    SUM(total_amount) as daily_revenue,
    SUM(SUM(total_amount)) OVER (ORDER BY DATE(order_date)) as running_total_revenue, 					-- Running total
    AVG(SUM(total_amount)) OVER (ORDER BY DATE(order_date)
		ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) as seven_day_avg_revenue, 		  					-- 7 day moving average
	ROUND(SUM(total_amount) / SUM(SUM(total_amount)) OVER () * 100, 2) as percent_of_total_revenue		-- percentage of total revenue 
FROM orders
WHERE status != 'cancelled'
GROUP BY DATE(order_date)
ORDER BY order_date;



-- 2. Common Table Expression (CTEs) for Complex Hierarchicals Queries
WITH 
RECURSIVE category_hierarchy AS (

	-- Base case: Top level categories
	SELECT
		category_id,
        category_name,
        parent_category_id,
        0 as level,
        category_name as full_path
	FROM categories
    WHERE parent_category_id IS NULL
    
    UNION ALL
    
    -- Recursive case: Subcategories
    SELECT
		c.category_id,
        c.category_name,
        c.parent_category_id,
        ch.level + 1,
        CONCAT(ch.full_path, ' > ', c.category_name) as full_path
	FROM categories c
    JOIN category_hierarchy ch ON c.parent_category_id = ch.category_id
)

SELECT 
	ch.category_id,
    ch.category_name,
    ch.level,
    ch.full_path,
    COUNT(p.product_id) as product_count,
    COALESCE(SUM(oi.quantity), 0) as total_units_sold
FROM category_hierarchy as ch
LEFT JOIN products p ON ch.category_id = p.category_id
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY ch.category_id, ch.category_name, ch.level, ch.full_path
ORDER BY ch.level, ch.category_name;



-- 3. JSON aggregation for complex reprting
SELECT
	DATE_FORMAT(MIN(o.order_date), '%Y-%m') as month,
    JSON_OBJECT(
		'total_orders', COUNT(o.order_id),
        'total_revenue', ROUND(SUM(o.total_amount) ,2),
        'avg_order_value', ROUND(AVG(o.total_amount), 2),
        'top_products', (
			SELECT JSON_ARRAYAGG(
				JSON_OBJECT(
					'product_name', sub.product_name,
                    'units_sold', sub.units_sold
                 )
            )
            FROM (
				SELECT 
					p.product_name,
                    SUM(oi.quantity) as units_sold
				FROM order_items oi
				JOIN products p ON oi.product_id = p.product_id
                JOIN orders o2 ON oi.order_id = o2.order_id
				WHERE DATE_FORMAT(o2.order_date, '%Y-%m') = DATE_FORMAT(MIN(o.order_date), '%Y-%m')
					AND o2.status != 'cancelled'
				GROUP BY p.product_name
                ORDER BY units_sold DESC
                LIMIT 3
            ) sub
		)            
	) as monthly_summary
FROM orders o
WHERE o.status != 'cancelled'
GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
ORDER BY month;



-- 4. Using MySQL 8.0 Ranking Function
SELECT
	p.product_name,
    c.category_name,
    p.price,
    COUNT(oi.order_item_id) as units_sold,
    SUM(oi.total_price) as total_revenue,    
    RANK() OVER (PARTITION BY c.category_id ORDER BY SUM(oi.total_price) DESC) as revenue_rank_in_category,      -- Rank products by revenue within each category
    PERCENT_RANK() OVER(ORDER BY SUM(oi.total_price)) as revenue_percentile,                                     -- Percentile rank across all products  
    DENSE_RANK() OVER(ORDER BY SUM(oi.total_price) DESC) as overall_revenue_rank                                 -- Dense rank for top products
FROM products p
JOIN categories c ON p.category_id = c.category_id
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name, c.category_name, p.price
HAVING units_sold > 0
ORDER BY c.category_name, revenue_rank_in_category;
    
    