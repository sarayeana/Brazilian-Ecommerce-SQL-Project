/*
===============================================================================
Project: Brazilian E-Commerce (Olist) Analysis
File: 02_Data_Quality.sql

Purpose:
    Validate the integrity, completeness, and consistency of the dataset
    before performing business analysis.

Objectives:
    - Detect duplicate records
    - Identify missing values
    - Validate business rules
    - Check referential integrity
    - Ensure data consistency
===============================================================================
*/

/*
=================================================
duplicate checks
=================================================
purpose:
identify duplicate records across all tables
to ensure data integrity before analysis.
=================================================
*/
select 'customers' as table_name,
count(*) as duplicate_rows
from (
    select customer_id
    from olist_customers_dataset
    group by customer_id
    having count(*) > 1
) t

union all

select 'orders',
count(*)
from (
    select order_id
    from olist_orders_dataset
    group by order_id
    having count(*) > 1
) t

union all

select 'order_items',
count(*)
from (
    select order_id, order_item_id
    from olist_order_items_dataset
    group by order_id, order_item_id
    having count(*) > 1
) t

union all

select 'payments',
count(*)
from (
    select order_id, payment_sequential
    from olist_order_payments_dataset
    group by order_id, payment_sequential
    having count(*) > 1
) t

union all

select 'reviews',
count(*)
from (
    select review_id
    from olist_order_reviews_dataset
    group by review_id
    having count(*) > 1
) t

union all

select 'products',
count(*)
from (
    select product_id
    from olist_products_dataset
    group by product_id
    having count(*) > 1
) t

union all

select 'sellers',
count(*)
from (
    select seller_id
    from olist_sellers_dataset
    group by seller_id
    having count(*) > 1
) t;
/*
=================================================
observation
=================================================

1. no duplicate primary keys should exist in the
   customers, orders, products, sellers, or reviews tables.

2. composite keys are used to validate uniqueness in the
   order_items and order_payments tables because these
   tables naturally allow multiple records per order.

3. duplicate records can lead to incorrect revenue,
   customer counts, and business metrics, making this
   an essential first step in data quality assessment.
*/


------

/*
=================================================
2. missing value analysis
purpose:
identify missing values across all tables to
evaluate data completeness before analysis.
=================================================
*/
#---customers
select
    count(*) as total_rows,
    count(*) - count(customer_id) as missing_customer_id,
    count(*) - count(customer_unique_id) as missing_customer_unique_id,
    count(*) - count(customer_zip_code_prefix) as missing_zip_code,
    count(*) - count(customer_city) as missing_city,
    count(*) - count(customer_state) as missing_state
from olist_customers_dataset;
#---orders
select
    count(*) as total_rows,
    count(*) - count(order_id) as missing_order_id,
    count(*) - count(customer_id) as missing_customer_id,
    count(*) - count(order_status) as missing_order_status,
    count(*) - count(order_purchase_timestamp) as missing_purchase_date,
    count(*) - count(order_approved_at) as missing_approval_date,
    count(*) - count(order_delivered_carrier_date) as missing_carrier_date,
    count(*) - count(order_delivered_customer_date) as missing_delivery_date,
    count(*) - count(order_estimated_delivery_date) as missing_estimated_delivery
from olist_orders_dataset;
#---order items
select
    count(*) as total_rows,
    count(*) - count(order_id) as missing_order_id,
    count(*) - count(order_item_id) as missing_order_item_id,
    count(*) - count(product_id) as missing_product_id,
    count(*) - count(seller_id) as missing_seller_id,
    count(*) - count(shipping_limit_date) as missing_shipping_limit_date,
    count(*) - count(price) as missing_price,
    count(*) - count(freight_value) as missing_freight_value
from olist_order_items_dataset;
#---order payments
select
    count(*) as total_rows,
    count(*) - count(order_id) as missing_order_id,
    count(*) - count(payment_sequential) as missing_payment_sequential,
    count(*) - count(payment_type) as missing_payment_type,
    count(*) - count(payment_installments) as missing_installments,
    count(*) - count(payment_value) as missing_payment_value
from olist_order_payments_dataset;
#---order reviews
select
    count(*) as total_rows,
    count(*) - count(review_id) as missing_review_id,
    count(*) - count(order_id) as missing_order_id,
    count(*) - count(review_score) as missing_review_score,
    count(*) - count(review_comment_title) as missing_review_title,
    count(*) - count(review_comment_message) as missing_review_message,
    count(*) - count(review_creation_date) as missing_review_creation_date,
    count(*) - count(review_answer_timestamp) as missing_review_answer_timestamp
from olist_order_reviews_dataset;
#---products
select
    count(*) as total_rows,
    count(*) - count(product_id) as missing_product_id,
    count(*) - count(product_category_name) as missing_category,
    count(*) - count(product_name_lenght) as missing_name_length,
    count(*) - count(product_description_lenght) as missing_description_length,
    count(*) - count(product_photos_qty) as missing_photos,
    count(*) - count(product_weight_g) as missing_weight,
    count(*) - count(product_length_cm) as missing_length,
    count(*) - count(product_height_cm) as missing_height,
    count(*) - count(product_width_cm) as missing_width
from olist_products_dataset;
#---sellers
select
    count(*) as total_rows,
    count(*) - count(seller_id) as missing_seller_id,
    count(*) - count(seller_zip_code_prefix) as missing_zip_code,
    count(*) - count(seller_city) as missing_city,
    count(*) - count(seller_state) as missing_state
from olist_sellers_dataset;
#---product category translation
select
    count(*) as total_rows,
    count(*) - count(product_category_name) as missing_portuguese_name,
    count(*) - count(product_category_name_english) as missing_english_name
from product_category_name_translation;
/*
=================================================
observation
=================================================

1. most key identifier columns contain no missing values,
   indicating good data integrity.

2. missing delivery-related timestamps are expected for
   orders that were canceled or never completed.

3. review titles and review messages contain many missing
   values because customers are not required to leave
   written feedback.

4. some product attributes such as dimensions and weight
   may be missing, which should be considered when
   performing logistics or product analyses.

5. understanding missing values helps distinguish between
   expected business behavior and genuine data quality
   issues before proceeding with analysis.
*/

------

/*
=================================================
3. referential integrity
purpose:
verify that relationships between tables are valid
by identifying orphan records that do not have a
matching parent record.
=================================================
*/
select
    'orders → customers' as relationship_name,
    count(*) as invalid_records
from olist_orders_dataset o
left join olist_customers_dataset c
    on o.customer_id = c.customer_id
where c.customer_id is null

union all

select
    'order_items → orders',
    count(*)
from olist_order_items_dataset oi
left join olist_orders_dataset o
    on oi.order_id = o.order_id
where o.order_id is null

union all

select
    'order_items → products',
    count(*)
from olist_order_items_dataset oi
left join olist_products_dataset p
    on oi.product_id = p.product_id
where p.product_id is null

union all

select
    'order_items → sellers',
    count(*)
from olist_order_items_dataset oi
left join olist_sellers_dataset s
    on oi.seller_id = s.seller_id
where s.seller_id is null

union all

select
    'payments → orders',
    count(*)
from olist_order_payments_dataset p
left join olist_orders_dataset o
    on p.order_id = o.order_id
where o.order_id is null

union all

select
    'reviews → orders',
    count(*)
from olist_order_reviews_dataset r
left join olist_orders_dataset o
    on r.order_id = o.order_id
where o.order_id is null;
/*
=================================================
observation
=================================================

1. all foreign key relationships are valid, indicating
   strong referential integrity across the dataset.

2. no orphan records were found between the related
   tables, ensuring that joins will produce reliable
   analytical results.

3. maintaining referential integrity is essential for
   accurate reporting, as broken relationships can lead
   to missing data, incorrect aggregations, and
   misleading business insights.
*/

------

/*
=================================================
4. business rule validation
purpose:
validate business rules to identify logically
incorrect records that may affect analysis.
=================================================
*/
select
'delivery before purchase' as rule_name,
count(*) as violations
from olist_orders_dataset
where order_delivered_customer_date < order_purchase_timestamp

union all

select
'approval before purchase',
count(*)
from olist_orders_dataset
where order_approved_at < order_purchase_timestamp

union all

select
'carrier before approval',
count(*)
from olist_orders_dataset
where order_delivered_carrier_date < order_approved_at

union all

select
'delivery before carrier',
count(*)
from olist_orders_dataset
where order_delivered_customer_date < order_delivered_carrier_date

union all

select
'estimated delivery before purchase',
count(*)
from olist_orders_dataset
where order_estimated_delivery_date < order_purchase_timestamp

union all

select
'negative prices',
count(*)
from olist_order_items_dataset
where price < 0

union all

select
'negative freight',
count(*)
from olist_order_items_dataset
where freight_value < 0

union all

select
'invalid review scores',
count(*)
from olist_order_reviews_dataset
where review_score not between 1 and 5;
/*
=================================================
observation
=================================================

1. there is some business rule violations but the
dataset is logically consistent and suitable for
business analysis.

2. validating business rules is different from
checking referential integrity. referential
integrity ensures relationships are valid,
whereas business rule validation ensures the
data reflects realistic business processes.

3. identifying business rule violations early
helps prevent misleading reports and inaccurate
performance metrics.
*/

------

/*
=================================================
5. data quality summary report
purpose:
provide an executive summary of all major data
quality checks performed on the dataset.
=================================================
*/
select
    'Duplicate Customer IDs' as check_name,
    case when count(*) = 0 then 'PASS' else 'FAIL' end as status,
    count(*) as failed_records
from (
    select customer_id
    from olist_customers_dataset
    group by customer_id
    having count(*) > 1
) t

union all

select
    'Duplicate Order IDs',
    case when count(*) = 0 then 'PASS' else 'FAIL' end,
    count(*)
from (
    select order_id
    from olist_orders_dataset
    group by order_id
    having count(*) > 1
) t

union all

select
    'Duplicate Product IDs',
    case when count(*) = 0 then 'PASS' else 'FAIL' end,
    count(*)
from (
    select product_id
    from olist_products_dataset
    group by product_id
    having count(*) > 1
) t

union all

select
    'Duplicate Seller IDs',
    case when count(*) = 0 then 'PASS' else 'FAIL' end,
    count(*)
from (
    select seller_id
    from olist_sellers_dataset
    group by seller_id
    having count(*) > 1
) t

union all

select
    'Missing Product Categories',
    case
        when count(*) = 0 then 'PASS'
        else 'WARNING'
    end,
    count(*)
from olist_products_dataset
where product_category_name is null

union all

select
    'Missing Approval Dates',
    case
        when count(*) = 0 then 'PASS'
        else 'WARNING'
    end,
    count(*)
from olist_orders_dataset
where order_approved_at is null

union all

select
    'Missing Carrier Dates',
    case
        when count(*) = 0 then 'PASS'
        else 'WARNING'
    end,
    count(*)
from olist_orders_dataset
where order_delivered_carrier_date is null

union all

select
    'Missing Delivery Dates',
    case
        when count(*) = 0 then 'PASS'
        else 'WARNING'
    end,
    count(*)
from olist_orders_dataset
where order_delivered_customer_date is null

union all

select
    'Missing Product Dimensions',
    case
        when count(*) = 0 then 'PASS'
        else 'WARNING'
    end,
    count(*)
from olist_products_dataset
where product_length_cm is null
   or product_height_cm is null
   or product_width_cm is null

union all

select
    'Orders Without Customers',
    case when count(*) = 0 then 'PASS' else 'FAIL' end,
    count(*)
from olist_orders_dataset o
left join olist_customers_dataset c
    on o.customer_id = c.customer_id
where c.customer_id is null

union all

select
    'Order Items Without Orders',
    case when count(*) = 0 then 'PASS' else 'FAIL' end,
    count(*)
from olist_order_items_dataset oi
left join olist_orders_dataset o
    on oi.order_id = o.order_id
where o.order_id is null

union all

select
    'Order Items Without Products',
    case when count(*) = 0 then 'PASS' else 'FAIL' end,
    count(*)
from olist_order_items_dataset oi
left join olist_products_dataset p
    on oi.product_id = p.product_id
where p.product_id is null

union all

select
    'Order Items Without Sellers',
    case when count(*) = 0 then 'PASS' else 'FAIL' end,
    count(*)
from olist_order_items_dataset oi
left join olist_sellers_dataset s
    on oi.seller_id = s.seller_id
where s.seller_id is null

union all

select
    'Payments Without Orders',
    case when count(*) = 0 then 'PASS' else 'FAIL' end,
    count(*)
from olist_order_payments_dataset p
left join olist_orders_dataset o
    on p.order_id = o.order_id
where o.order_id is null

union all

select
    'Reviews Without Orders',
    case when count(*) = 0 then 'PASS' else 'FAIL' end,
    count(*)
from olist_order_reviews_dataset r
left join olist_orders_dataset o
    on r.order_id = o.order_id
where o.order_id is null

union all

select
    'Delivered Orders Missing Delivery Date',
    case when count(*) = 0 then 'PASS' else 'FAIL' end,
    count(*)
from olist_orders_dataset
where order_status = 'delivered'
and order_delivered_customer_date is null

union all

select
    'Purchase After Delivery',
    case when count(*) = 0 then 'PASS' else 'FAIL' end,
    count(*)
from olist_orders_dataset
where order_delivered_customer_date < order_purchase_timestamp

union all

select
    'Approval Before Purchase',
    case when count(*) = 0 then 'PASS' else 'FAIL' end,
    count(*)
from olist_orders_dataset
where order_approved_at < order_purchase_timestamp

union all

select
    'Carrier Pickup Before Approval',
    case when count(*) = 0 then 'PASS' else 'FAIL' end,
    count(*)
from olist_orders_dataset
where order_delivered_carrier_date < order_approved_at

union all

select
    'Invalid Review Scores',
    case when count(*) = 0 then 'PASS' else 'FAIL' end,
    count(*)
from olist_order_reviews_dataset
where review_score not between 1 and 5

union all

select
    'Negative Prices',
    case when count(*) = 0 then 'PASS' else 'FAIL' end,
    count(*)
from olist_order_items_dataset
where price < 0

union all

select
    'Negative Freight',
    case when count(*) = 0 then 'PASS' else 'FAIL' end,
    count(*)
from olist_order_items_dataset
where freight_value < 0

union all

select
    'Invalid Product Dimensions',
    case when count(*) = 0 then 'PASS' else 'FAIL' end,
    count(*)
from olist_products_dataset
where product_length_cm <= 0
   or product_height_cm <= 0
   or product_width_cm <= 0

union all

select
    'Orders Without Items',
    case when count(*) = 0 then 'PASS' else 'FAIL' end,
    count(*)
from olist_orders_dataset o
left join olist_order_items_dataset oi
    on o.order_id = oi.order_id
where oi.order_id is null

union all

select
    'Orders Without Payments',
    case when count(*) = 0 then 'PASS' else 'FAIL' end,
    count(*)
from olist_orders_dataset o
left join olist_order_payments_dataset p
    on o.order_id = p.order_id
where p.order_id is null;
/*
=================================================
observation
=================================================

1. the dataset demonstrates strong overall data quality,
   with no duplicate primary keys or broken foreign key
   relationships detected.

2. warning-level findings mainly relate to expected
   business scenarios, such as missing approval or
   delivery timestamps for canceled or unavailable orders,
   and missing product attributes.

3. no critical business rule violations were identified,
   indicating that the dataset is suitable for analytical
   reporting and dashboard development.

4. this summary provides a concise data quality assessment
   that can be used as an ETL validation report or
   executive data quality dashboard.
*/
