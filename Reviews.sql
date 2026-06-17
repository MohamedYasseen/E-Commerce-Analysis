-- Review Analysis

-- Overall review Distribution
SELECT
    review_score,
    COUNT(*)  AS num_reviews,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM olist_order_reviews_dataset
GROUP BY 1
ORDER BY 1;

--7.2 Monthly average review score trend
SELECT
    DATE_TRUNC('month', review_creation_date::TIMESTAMP) AS month,  -- PostgreSQL
    
    ROUND(AVG(review_score):: NUMERIC, 2) AS avg_score,
    COUNT(*) AS num_reviews
FROM olist_order_reviews_dataset
GROUP BY 1
ORDER BY 1;

-- 7.3 Review response time (hours between creation and answer)
SELECT
    ROUND(AVG(
        review_answer_timestamp::DATE - review_creation_date:: DATE 
    ), 2) AS avg_response_hours
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

