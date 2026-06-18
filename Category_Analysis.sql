-- Category_Analysis

-- 3.1 Top 10 categories by revenue (in English)
SELECT
    t.product_category_name_english AS category,
    COUNT(DISTINCT oi.order_id) AS num_orders,
    SUM(oi.price) AS revenue,
    ROUND(AVG(oi.price)::NUMERIC, 2) AS avg_item_price
FROM olist_order_items_dataset oi
JOIN olist_products_dataset p      ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation t
    ON p.product_category_name = t.product_category_name
GROUP BY 1
ORDER BY revenue DESC
LIMIT 10;


-- 3.2 Top 10 categories by number of orders (in English)
SELECT
    t.product_category_name_english AS category,
    COUNT(DISTINCT oi.order_id) AS num_orders
FROM olist_order_items_dataset oi
JOIN olist_products_dataset p ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation t
    ON p.product_category_name = t.product_category_name
GROUP BY 1
ORDER BY num_orders DESC
LIMIT 10;


-- 3.3 Products with most reviews and average rating

SELECT
    oi.product_id,
    t.product_category_name_english AS category,
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
