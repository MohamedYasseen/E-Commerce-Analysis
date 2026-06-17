-- Seller_Performance

-- Top Sellers by Performance
SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(DISTINCT oi.order_id)     AS num_orders,
    ROUND(SUM(price)::NUMERIC, 2)         AS revenue,
    ROUND(AVG(review_score)::NUMERIC, 2)  AS avg_review_score
FROM olist_sellers_dataset s
JOIN olist_order_items_dataset oi  ON s.seller_id = oi.seller_id
LEFT JOIN olist_order_reviews_dataset r ON oi.order_id = r.order_id
GROUP BY 1, 2, 3
ORDER BY revenue DESC
LIMIT 20;


-- Seller State Breakdown

SELECT
    seller_state,
    COUNT(DISTINCT s.seller_id)  AS num_sellers,
    COUNT(DISTINCT oi.order_id)  AS num_orders,
    ROUND(SUM(oi.price), 2)      AS total_revenue
FROM olist_sellers_dataset s
JOIN olist_order_items_dataset oi ON s.seller_id = oi.seller_id
GROUP BY 1
ORDER BY total_revenue DESC;

-- Sellers with poor ratings
SELECT
    s.seller_id,
    s.seller_state,
    COUNT(r.review_id)            AS num_reviews,
    ROUND(AVG(r.review_score)::NUMERIC, 2) AS avg_score,
    ROUND(SUM(oi.price):: NUMERIC, 2)       AS revenue
FROM olist_sellers_dataset s
JOIN olist_order_items_dataset oi  ON s.seller_id = oi.seller_id
JOIN olist_order_reviews_dataset r ON oi.order_id = r.order_id
GROUP BY 1, 2
HAVING COUNT(r.review_id) >= 10 AND AVG(r.review_score) < 3
ORDER BY avg_score ASC;

