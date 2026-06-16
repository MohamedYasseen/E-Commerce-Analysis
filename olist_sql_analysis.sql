-- ============================================================
-- OLIST E-COMMERCE SQL ANALYSIS GUIDE
-- Designed for DBeaver (PostgreSQL / SQLite / MySQL / DuckDB)
-- Datasets: ~99K orders, 112K items, 99K customers, 3K sellers
-- ============================================================


-- ============================================================
-- SECTION 0: SETUP — Import CSVs into DBeaver
-- ============================================================
-- In DBeaver:
--   1. Create a new database (or use an existing one)
--   2. Right-click the database > Tools > Import Data (CSV)
--   3. Import each CSV as its own table, using the filename as
--      the table name (e.g. olist_orders_dataset)
--   4. Ensure DBeaver auto-detects column types, then run the
--      queries below.
--
-- Table names used throughout this file:
--   olist_orders_dataset
--   olist_order_items_dataset
--   olist_order_payments_dataset
--   olist_order_reviews_dataset
--   olist_customers_dataset
--   olist_products_dataset
--   olist_sellers_dataset
--   olist_geolocation_dataset
--   product_category_name_translation


-- ============================================================
-- SECTION 1: DATA OVERVIEW
-- ============================================================

-- 1.1 Row counts for every table
SELECT 'orders'    AS tbl, COUNT(*) AS rows FROM olist_orders_dataset
UNION ALL
SELECT 'order_items',       COUNT(*) FROM olist_order_items_dataset
UNION ALL
SELECT 'payments',          COUNT(*) FROM olist_order_payments_dataset
UNION ALL
SELECT 'reviews',           COUNT(*) FROM olist_order_reviews_dataset
UNION ALL
SELECT 'customers',         COUNT(*) FROM olist_customers_dataset
UNION ALL
SELECT 'products',          COUNT(*) FROM olist_products_dataset
UNION ALL
SELECT 'sellers',           COUNT(*) FROM olist_sellers_dataset
UNION ALL
SELECT 'geolocation',       COUNT(*) FROM olist_geolocation_dataset
UNION ALL
SELECT 'category_translation', COUNT(*) FROM product_category_name_translation;

-- 1.2 Order status breakdown
SELECT
    order_status,
    COUNT(*)                          AS total_orders,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct
FROM olist_orders_dataset
GROUP BY order_status
ORDER BY total_orders DESC;

-- 1.3 Date range of the dataset
SELECT
    MIN(order_purchase_timestamp) AS first_order,
    MAX(order_purchase_timestamp) AS last_order
FROM olist_orders_dataset;


-- ============================================================
-- SECTION 2: SALES & REVENUE
-- ============================================================

-- 2.1 Total revenue (sum of item prices + freight)
SELECT
    ROUND(SUM(price), 2)         AS total_item_revenue,
    ROUND(SUM(freight_value), 2) AS total_freight,
    ROUND(SUM(price + freight_value), 2) AS total_revenue
FROM olist_order_items_dataset;

-- 2.2 Monthly revenue trend
SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp) AS month,  -- PostgreSQL
    -- strftime('%Y-%m', o.order_purchase_timestamp)            -- SQLite
    ROUND(SUM(oi.price + oi.freight_value), 2) AS revenue,
    COUNT(DISTINCT o.order_id)                 AS num_orders
FROM olist_orders_dataset o
JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY 1
ORDER BY 1;

-- 2.3 Average order value (AOV)
SELECT
    ROUND(AVG(order_total), 2) AS avg_order_value,
    ROUND(MIN(order_total), 2) AS min_order,
    ROUND(MAX(order_total), 2) AS max_order
FROM (
    SELECT order_id, SUM(price + freight_value) AS order_total
    FROM olist_order_items_dataset
    GROUP BY order_id
) sub;

-- 2.4 Revenue by payment type
SELECT
    payment_type,
    COUNT(DISTINCT order_id)      AS num_orders,
    ROUND(SUM(payment_value), 2)  AS total_paid,
    ROUND(AVG(payment_value), 2)  AS avg_payment
FROM olist_order_payments_dataset
GROUP BY payment_type
ORDER BY total_paid DESC;

-- 2.5 Credit card installment distribution
SELECT
    payment_installments,
    COUNT(*) AS num_transactions,
    ROUND(SUM(payment_value), 2) AS total_value
FROM olist_order_payments_dataset
WHERE payment_type = 'credit_card'
GROUP BY payment_installments
ORDER BY payment_installments;


-- ============================================================
-- SECTION 3: PRODUCT & CATEGORY ANALYSIS
-- ============================================================

-- 3.1 Top 15 categories by revenue (with English names)
SELECT
    COALESCE(t.product_category_name_english, p.product_category_name) AS category,
    COUNT(DISTINCT oi.order_id)         AS num_orders,
    SUM(oi.price)                       AS revenue,
    ROUND(AVG(oi.price), 2)             AS avg_item_price
FROM olist_order_items_dataset oi
JOIN olist_products_dataset p      ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation t
    ON p.product_category_name = t.product_category_name
GROUP BY 1
ORDER BY revenue DESC
LIMIT 15;

-- 3.2 Top 15 categories by number of orders
SELECT
    COALESCE(t.product_category_name_english, p.product_category_name) AS category,
    COUNT(DISTINCT oi.order_id) AS num_orders
FROM olist_order_items_dataset oi
JOIN olist_products_dataset p ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation t
    ON p.product_category_name = t.product_category_name
GROUP BY 1
ORDER BY num_orders DESC
LIMIT 15;

-- 3.3 Products with most reviews and average rating
SELECT
    oi.product_id,
    COALESCE(t.product_category_name_english, p.product_category_name) AS category,
    COUNT(r.review_id)              AS num_reviews,
    ROUND(AVG(r.review_score), 2)  AS avg_score
FROM olist_order_items_dataset oi
JOIN olist_order_reviews_dataset r ON oi.order_id = r.order_id
JOIN olist_products_dataset p      ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation t
    ON p.product_category_name = t.product_category_name
GROUP BY 1, 2
ORDER BY num_reviews DESC
LIMIT 20;

-- 3.4 Category average review score (min 50 reviews)
SELECT
    COALESCE(t.product_category_name_english, p.product_category_name) AS category,
    COUNT(r.review_id)             AS num_reviews,
    ROUND(AVG(r.review_score), 2) AS avg_score
FROM olist_order_items_dataset oi
JOIN olist_order_reviews_dataset r ON oi.order_id = r.order_id
JOIN olist_products_dataset p      ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation t
    ON p.product_category_name = t.product_category_name
GROUP BY 1
HAVING COUNT(r.review_id) >= 50
ORDER BY avg_score DESC;


-- ============================================================
-- SECTION 4: SELLER PERFORMANCE
-- ============================================================

-- 4.1 Top 20 sellers by revenue
SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(DISTINCT oi.order_id)     AS num_orders,
    ROUND(SUM(oi.price), 2)         AS revenue,
    ROUND(AVG(r.review_score), 2)  AS avg_review_score
FROM olist_sellers_dataset s
JOIN olist_order_items_dataset oi  ON s.seller_id = oi.seller_id
LEFT JOIN olist_order_reviews_dataset r ON oi.order_id = r.order_id
GROUP BY 1, 2, 3
ORDER BY revenue DESC
LIMIT 20;

-- 4.2 Seller state breakdown
SELECT
    seller_state,
    COUNT(DISTINCT s.seller_id)  AS num_sellers,
    COUNT(DISTINCT oi.order_id)  AS num_orders,
    ROUND(SUM(oi.price), 2)      AS total_revenue
FROM olist_sellers_dataset s
JOIN olist_order_items_dataset oi ON s.seller_id = oi.seller_id
GROUP BY 1
ORDER BY total_revenue DESC;

-- 4.3 Sellers with poor ratings (avg score < 3, min 10 reviews)
SELECT
    s.seller_id,
    s.seller_state,
    COUNT(r.review_id)            AS num_reviews,
    ROUND(AVG(r.review_score), 2) AS avg_score,
    ROUND(SUM(oi.price), 2)       AS revenue
FROM olist_sellers_dataset s
JOIN olist_order_items_dataset oi  ON s.seller_id = oi.seller_id
JOIN olist_order_reviews_dataset r ON oi.order_id = r.order_id
GROUP BY 1, 2
HAVING COUNT(r.review_id) >= 10 AND AVG(r.review_score) < 3
ORDER BY avg_score ASC;


-- ============================================================
-- SECTION 5: CUSTOMER ANALYSIS
-- ============================================================

-- 5.1 Top customer states by orders and revenue
SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id)         AS num_orders,
    COUNT(DISTINCT c.customer_unique_id) AS unique_customers,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_spend
FROM olist_customers_dataset c
JOIN olist_orders_dataset o        ON c.customer_id = o.customer_id
JOIN olist_order_items_dataset oi  ON o.order_id = oi.order_id
GROUP BY 1
ORDER BY num_orders DESC;

-- 5.2 Repeat vs one-time customers
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

-- 5.3 Top cities by number of customers
SELECT
    customer_city,
    customer_state,
    COUNT(DISTINCT customer_unique_id) AS unique_customers
FROM olist_customers_dataset
GROUP BY 1, 2
ORDER BY unique_customers DESC
LIMIT 20;


-- ============================================================
-- SECTION 6: DELIVERY & LOGISTICS
-- ============================================================

-- 6.1 Average delivery time (in days) by state
SELECT
    c.customer_state,
    ROUND(AVG(
        JULIANDAY(o.order_delivered_customer_date)         -- SQLite
        - JULIANDAY(o.order_purchase_timestamp)
        -- For PostgreSQL use:
        -- EXTRACT(EPOCH FROM (order_delivered_customer_date - order_purchase_timestamp)) / 86400
    ), 1) AS avg_delivery_days,
    COUNT(o.order_id) AS num_orders
FROM olist_orders_dataset o
JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY 1
ORDER BY avg_delivery_days DESC;

-- 6.2 On-time vs late deliveries
SELECT
    CASE
        WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 'on-time'
        ELSE 'late'
    END AS delivery_status,
    COUNT(*)                            AS num_orders,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct
FROM olist_orders_dataset
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL
GROUP BY 1;

-- 6.3 Late delivery impact on review score
SELECT
    CASE
        WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 'on-time'
        ELSE 'late'
    END AS delivery_status,
    COUNT(r.review_id)             AS num_reviews,
    ROUND(AVG(r.review_score), 2) AS avg_score
FROM olist_orders_dataset o
JOIN olist_order_reviews_dataset r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY 1;

-- 6.4 Average time from purchase to carrier pickup
SELECT
    ROUND(AVG(
        JULIANDAY(order_delivered_carrier_date)
        - JULIANDAY(order_purchase_timestamp)
    ), 1) AS avg_days_to_carrier
FROM olist_orders_dataset
WHERE order_delivered_carrier_date IS NOT NULL;


-- ============================================================
-- SECTION 7: REVIEW & SATISFACTION ANALYSIS
-- ============================================================

-- 7.1 Overall review score distribution
SELECT
    review_score,
    COUNT(*)  AS num_reviews,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct
FROM olist_order_reviews_dataset
GROUP BY 1
ORDER BY 1;

-- 7.2 Monthly average review score trend
SELECT
    DATE_TRUNC('month', review_creation_date) AS month,  -- PostgreSQL
    -- strftime('%Y-%m', review_creation_date)             -- SQLite
    ROUND(AVG(review_score), 2) AS avg_score,
    COUNT(*)                    AS num_reviews
FROM olist_order_reviews_dataset
GROUP BY 1
ORDER BY 1;

-- 7.3 Review response time (hours between creation and answer)
SELECT
    ROUND(AVG(
        (JULIANDAY(review_answer_timestamp) - JULIANDAY(review_creation_date)) * 24
    ), 1) AS avg_response_hours
FROM olist_order_reviews_dataset
WHERE review_answer_timestamp IS NOT NULL;

-- 7.4 Orders with score 1 — how many had late delivery?
SELECT
    CASE
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 'late'
        ELSE 'on-time / unknown'
    END AS delivery_status,
    COUNT(*) AS num_score_1_reviews
FROM olist_order_reviews_dataset r
JOIN olist_orders_dataset o ON r.order_id = o.order_id
WHERE r.review_score = 1
GROUP BY 1;


-- ============================================================
-- SECTION 8: ADVANCED / COMBINED INSIGHTS
-- ============================================================

-- 8.1 Full order summary (join all key tables)
SELECT
    o.order_id,
    o.order_status,
    o.order_purchase_timestamp,
    c.customer_state,
    COUNT(oi.order_item_id)        AS items,
    ROUND(SUM(oi.price), 2)        AS item_total,
    ROUND(SUM(oi.freight_value), 2) AS freight_total,
    ROUND(SUM(p.payment_value), 2) AS amount_paid,
    MAX(r.review_score)            AS review_score
FROM olist_orders_dataset o
JOIN olist_customers_dataset c           ON o.customer_id = c.customer_id
JOIN olist_order_items_dataset oi        ON o.order_id = oi.order_id
LEFT JOIN olist_order_payments_dataset p ON o.order_id = p.order_id
LEFT JOIN olist_order_reviews_dataset r  ON o.order_id = r.order_id
GROUP BY 1, 2, 3, 4
LIMIT 100;

-- 8.2 Freight as % of total by category
SELECT
    COALESCE(t.product_category_name_english, pr.product_category_name) AS category,
    ROUND(SUM(oi.price), 2)          AS item_revenue,
    ROUND(SUM(oi.freight_value), 2)  AS freight_cost,
    ROUND(SUM(oi.freight_value) * 100.0 / SUM(oi.price + oi.freight_value), 2) AS freight_pct
FROM olist_order_items_dataset oi
JOIN olist_products_dataset pr ON oi.product_id = pr.product_id
LEFT JOIN product_category_name_translation t
    ON pr.product_category_name = t.product_category_name
GROUP BY 1
HAVING SUM(oi.price) > 1000
ORDER BY freight_pct DESC
LIMIT 20;

-- 8.3 Day-of-week order volume (busiest shopping days)
SELECT
    -- PostgreSQL:
    TO_CHAR(order_purchase_timestamp, 'Day') AS day_of_week,
    EXTRACT(DOW FROM order_purchase_timestamp) AS day_num,
    -- SQLite: strftime('%w', order_purchase_timestamp) AS day_num,
    COUNT(*) AS num_orders
FROM olist_orders_dataset
GROUP BY 1, 2
ORDER BY 2;

-- 8.4 Hour-of-day order volume
SELECT
    EXTRACT(HOUR FROM order_purchase_timestamp) AS hour,  -- PostgreSQL
    -- CAST(strftime('%H', order_purchase_timestamp) AS INTEGER) -- SQLite
    COUNT(*) AS num_orders
FROM olist_orders_dataset
GROUP BY 1
ORDER BY 1;

-- 8.5 Seller-level NPS proxy
--     (% 5-star minus % 1- and 2-star orders)
SELECT
    s.seller_id,
    s.seller_state,
    COUNT(r.review_id) AS total_reviews,
    ROUND(
        100.0 * SUM(CASE WHEN r.review_score = 5 THEN 1 ELSE 0 END) / COUNT(r.review_id)
        - 100.0 * SUM(CASE WHEN r.review_score <= 2 THEN 1 ELSE 0 END) / COUNT(r.review_id)
    , 1) AS nps_proxy
FROM olist_sellers_dataset s
JOIN olist_order_items_dataset oi  ON s.seller_id = oi.seller_id
JOIN olist_order_reviews_dataset r ON oi.order_id = r.order_id
GROUP BY 1, 2
HAVING COUNT(r.review_id) >= 20
ORDER BY nps_proxy DESC
LIMIT 30;
