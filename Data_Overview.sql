-- Row counts for each table

select
	'orders' as table,
	count(*) as rows
from olist_orders_dataset 
union all
select 
	'products',
	count(*)
from olist_products_dataset
union all
select 
	'sellers',
	count(*)
from olist_sellers_dataset
union all
select 
	'customers',
	count(*)
from olist_customers_dataset
union all
select 
	'geolocation',
	count(*)
from olist_geolocation_dataset
union all
select 
	'payments',
	count(*)
from olist_order_payments_dataset
union all 
select
	'items',
	count(*)
from olist_order_items_dataset
union all
select 
	'reviews',
	count(*)
from olist_order_reviews_dataset
union all
select 
	'products',
	count(*)
from olist_products_dataset
order by rows DESC;

-- 1.2 Number of products in English

SELECT
    pct.product_category_name_english AS product,
    COUNT(*) AS total_products
FROM olist_products_dataset p
JOIN product_category_name_translation pct
    ON p.product_category_name = pct.product_category_name
GROUP BY pct.product_category_name_english
ORDER BY total_products DESC;

-- 1.3 Order Status Breakdown

SELECT
    order_status as status,
    COUNT(*) AS total_orders,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct
FROM olist_orders_dataset
GROUP BY order_status
ORDER BY total_orders DESC;

-- 1.4 Date Range

SELECT 
    Min(order_purchase_timestamp) AS First_order,
    Max(order_purchase_timestamp) AS Last_order



from olist_orders_dataset;