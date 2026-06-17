-- Sales & Revenue

-- 2.1 Total Revenue (price + freight_value)
SELECT
    ROUND(SUM(price):: NUMERIC, 2) AS total_item_revenue,
    ROUND(SUM(freight_value):: NUMERIC, 2) AS total_freight,
    ROUND(SUM(price + freight_value):: NUMERIC, 2) AS total_revenue
FROM olist_order_items_dataset;

-- 2.2 Monthly Revenue Trend

SELECT
    DATE_TRUNC('month', order_purchase_timestamp::TIMESTAMP) AS month,  -- PostgreSQL
    --strftime('%Y-%m', order_purchase_timestamp),            -- SQLite
    ROUND(SUM(price + freight_value)::NUMERIC, 2) AS revenue,
    COUNT(DISTINCT o.order_id) AS num_orders
FROM olist_orders_dataset o
JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY 1
ORDER BY 1;

-- 2.3 Average Order Value

SELECT
    ROUND(AVG(order_total)::NUMERIC, 2) AS avg_order_value,
    ROUND(MIN(order_total):: NUMERIC, 2) AS min_order,
    ROUND(MAX(order_total):: NUMERIC, 2) AS max_order
FROM (
    SELECT order_id, SUM(price + freight_value) AS order_total
    FROM olist_order_items_dataset
    GROUP BY order_id
) sub;


-- 2.4 Revenue by payment type

SELECT
    payment_type,
    COUNT(DISTINCT order_id)      AS num_orders,
    ROUND(SUM(payment_value)::NUMERIC, 2)  AS total_paid,
    ROUND(AVG(payment_value):: NUMERIC, 2)  AS avg_payment
FROM olist_order_payments_dataset
GROUP BY payment_type
ORDER BY total_paid DESC;

-- 2.5 Credit Card distribution by installments

select 
    payment_installments as installments,
    count(*) as num_of_transactions,
    ROUND(SUM(payment_value):: NUMERIC, 2) AS total_value
from olist_order_payments_dataset
WHERE payment_type = 'credit_card'
GROUP BY installments
ORDER BY installments;
