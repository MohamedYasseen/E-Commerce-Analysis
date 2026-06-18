-- Customer-Based Analysis

-- Top Customer states by order and revenue

SELECT 
    c.customer_state as customer_state,
    COUNT(DISTINCT o.order_id) as num_orders,
    ROUND(SUM(oi.price + oi.freight_value):: NUMERIC,2) as total


FROM olist_customers_dataset c
JOIN olist_orders_dataset o ON c.customer_id = o.customer_id
JOIN olist_order_items_dataset oi ON oi.order_id = o.order_id
GROUP BY 1
ORDER BY num_orders DESC;

-- Repeat VS One-Time purchases

SELECT
    CASE WHEN order_count = 1 THEN 'one-time' ELSE 'repeat' END AS customer_type,
    COUNT(*) AS num_customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct
FROM (
    SELECT customer_unique_id, COUNT(DISTINCT o.order_id) AS order_count
    FROM olist_customers_dataset c
    JOIN olist_orders_dataset o ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
) sub
GROUP BY 1;

-- Top cities by number of customers

SELECT
    customer_city,
    customer_state,
    COUNT(DISTINCT customer_unique_id) AS unique_customers
FROM olist_customers_dataset
GROUP BY 1, 2
ORDER BY unique_customers DESC
LIMIT 20;
