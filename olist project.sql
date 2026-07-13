/*
===========================================
Brazilian E-Commerce Dataset
SQL Project
===========================================
Author : Maha Yena
Database : MySQL
Dataset : Olist Brazilian E-Commerce
===========================================
*/


/*
=================================================
database schema overview
=================================================

The Olist dataset consists of transactional tables
and lookup tables connected through primary and
foreign keys.

                        customers
                   (customer_id)
                          │
                          │
                          ▼
                     orders
                   (order_id)
                          │
          ┌───────────────┼────────────────┐
          │               │                │
          ▼               ▼                ▼
    order_items      order_reviews   order_payments
          │
          │
    ┌─────┴─────┐
    │           │
    ▼           ▼
products     sellers

products
    │
    ▼
product_category_name_translation

customers
    │
    ▼
geolocation
(via zip code prefix)

-------------------------------------------------
primary keys
-------------------------------------------------

customers
- customer_id

orders
- order_id

order_items
- (order_id, order_item_id)

payments
- (order_id, payment_sequential)

reviews
- review_id

products
- product_id

sellers
- seller_id

category_translation
- product_category_name

-------------------------------------------------
main relationships
-------------------------------------------------

customers.customer_id
    → orders.customer_id

orders.order_id
    → order_items.order_id

orders.order_id
    → order_payments.order_id

orders.order_id
    → order_reviews.order_id

order_items.product_id
    → products.product_id

order_items.seller_id
    → sellers.seller_id

products.product_category_name
    → product_category_name_translation.product_category_name

customers.customer_zip_code_prefix
    → geolocation.geolocation_zip_code_prefix

=================================================
*/


/*
===============================================================================
Project: Brazilian E-Commerce (Olist) Analysis
File: 01_Data_Exploration.sql

Purpose:
    Explore the dataset structure, understand business scale,
    verify table relationships, and gain familiarity with the data
    before performing analytical queries.

Dataset:
    Olist Brazilian E-Commerce Public Dataset

Author: Your Name
SQL Dialect: MySQL 8.0
===============================================================================
*/


/*
=================================================
1. Number of Rows in Every Table
Purpose:
Check the size of each table in the dataset.
=================================================
*/
select 
	"Customers" as TableName,
    COUNT(*) as Total_Rows
from olist_customers_dataset

union all

select 'Orders',
       COUNT(*)
from olist_orders_dataset

union all

select 'Order Items',
       COUNT(*)
from olist_order_items_dataset

union all

select 'Order Payments',
       COUNT(*)
from olist_order_payments_dataset

union all

select 'Order Reviews',
       COUNT(*)
from olist_order_reviews_dataset

union all

select 'Products',
       COUNT(*)
FROM olist_products_dataset

union all

select 'Product Categories',
       COUNT(*)
from product_category_name_translation

union all

select 'Sellers',
       COUNT(*)
from olist_sellers_dataset

union all

select 'Geolocation',
       COUNT(*)
from olist_geolocation_dataset

order by Total_Rows desc;
/*
=================================================
Observation
=================================================

1. The Geolocation table is the largest table in the dataset, containing over 1 million records.
   This indicates that location data is recorded at a very granular level and may require optimization
   when joining with other tables.

2. The Orders and Customers tables contain almost the same number of records, suggesting that
   each order is associated with a unique customer_id. However, a customer_unique_id may have
   multiple customer_id values because the Olist dataset generates a new customer_id for each order.

3. The Order Items table contains more records than the Orders table, confirming that a single
   order can contain multiple products.

4. The Order Payments and Order Reviews tables have nearly the same number of rows as the Orders
   table, indicating that most orders have payment and review information available.

5. The Product Category Translation table is a small lookup table used to translate Portuguese
   product category names into English.

6. Understanding the size of each table helps estimate query complexity and identify which joins
   may be more computationally expensive.
*/

------

/*
=================================================
2. Number of Columns in Every Table
Purpose:
Check the structure of each table by counting
how many columns it contains.
=================================================
*/
select 
	table_name,
    COUNT(*) AS Total_Columns
from information_schema.columns
where table_schema='olist'
group by table_name
order by Total_Columns desc;
/*
Observation:
- The products table has the largest number of columns.
- The customers and sellers tables have relatively simple structures.
- The orders table contains multiple timestamp fields that will be useful for logistics and delivery analysis.
*/

------

/*
=================================================
3. preview every table
purpose:
preview the first 5 rows of each table to understand
the structure and sample data.
=================================================
*/
-- customers
select *
from olist_customers_dataset
limit 5;

-- orders
select *
from olist_orders_dataset
limit 5;

-- order items
select *
from olist_order_items_dataset
limit 5;

-- order payments
select *
from olist_order_payments_dataset
limit 5;

-- order reviews
select *
from olist_order_reviews_dataset
limit 5;

-- products
select *
from olist_products_dataset
limit 5;

-- product category translation
select *
from product_category_name_translation
limit 5;

-- sellers
select *
from olist_sellers_dataset
limit 5;

-- geolocation
select *
from olist_geolocation_dataset
limit 5;

/*
=================================================
observation
=================================================

1. previewing each table helps understand the available columns and sample values before performing analysis.

2. the dataset consists of transactional tables (orders, order_items, payments, reviews) and master tables (customers, products, sellers, geolocation).

3. unique identifiers such as order_id, customer_id, product_id, and seller_id will be the primary keys used for joining tables.

4. datetime columns in the orders table will be useful for time-series, sales, and logistics analysis.

5. the product_category_name_translation table is a lookup table used to convert portuguese category names into english.
*/

------

/*
=================================================
4. business time period and Operating Period
purpose:
determine the start date, end date, and duration
of the dataset.
=================================================
*/
select
    min(order_purchase_timestamp) as first_order_date,
    max(order_purchase_timestamp) as last_order_date,
    timestampdiff(
        year,
        min(order_purchase_timestamp),
        max(order_purchase_timestamp)
    ) as total_years,
    timestampdiff(
        month,
        min(order_purchase_timestamp),
        max(order_purchase_timestamp)
    ) as total_months,
    datediff(
        max(order_purchase_timestamp),
        min(order_purchase_timestamp)
    ) as total_days
from olist_orders_dataset;
/*
=================================================
observation
=================================================

1. the dataset covers approximately two years of business operations.

2. this time period is sufficient for analyzing sales trends, customer behavior, seasonality, and business growth.

3. monthly and yearly comparisons can be performed reliably because the dataset spans multiple calendar years.

4. the first and last purchase dates define the business timeline and will be used as the reference period for subsequent analyses.
*/

------

/*
=================================================
5. business scale
purpose:
provide a high-level overview of the business by
showing the total customers, orders, products,
sellers, and revenue.
=================================================
*/

select
    (select count(distinct customer_unique_id)
     from olist_customers_dataset) as total_customers,

    (select count(*)
     from olist_orders_dataset) as total_orders,

    (select count(distinct product_id)
     from olist_products_dataset) as total_products,

    (select count(distinct seller_id)
     from olist_sellers_dataset) as total_sellers,

    (select round(sum(price),2)
     from olist_order_items_dataset) as total_revenue,
     
     (select round(
            sum(price) /
            count(distinct order_id),2)
     from olist_order_items_dataset) as average_order_value;
/*
=================================================
observation
=================================================

1. the business has served thousands of unique customers and processed nearly one hundred thousand orders.

2. the product catalog contains over thirty thousand unique products sold by more than three thousand sellers.

3. the total revenue generated indicates a large-scale e-commerce marketplace with significant transaction volume.

4. these key metrics provide an executive-level overview of the overall size and performance of the business.
*/


------

/*
=================================================
6. order status exploration
purpose:
analyze the distribution of order statuses by
showing the number and percentage of orders
in each status.
=================================================
*/

select
    order_status as status,
    count(*) as orders,
    concat(round(
        count(*) * 100.0 /
        (select count(*) from olist_orders_dataset),
        3
    ),'%') as percentage
from olist_orders_dataset
group by order_status
order by orders desc;
/*
=================================================
observation
=================================================

1. the vast majority of orders have been successfully delivered, indicating a high order fulfillment rate.

2. canceled and unavailable orders account for only a small percentage of total orders, suggesting relatively few failed transactions.

3. only a very small number of orders remain in intermediate statuses such as created, approved, invoiced, or processing, indicating that most orders progress through the fulfillment process efficiently.

4. monitoring the distribution of order statuses helps evaluate operational performance and identify potential bottlenecks in the order lifecycle.
*/


------

/*
=================================================
7. geographic coverage
purpose:
analyze the geographic presence of the business
by examining states, cities, customers, and sellers.
=================================================
*/
select
    count(distinct customer_state) as total_states
from olist_customers_dataset;

select
    count(distinct customer_city) as total_cities
from olist_customers_dataset;

select
    customer_state,
    count(distinct customer_unique_id) as total_customers
from olist_customers_dataset
group by customer_state
order by total_customers desc;

select
    seller_state,
    count(distinct seller_id) as total_sellers
from olist_sellers_dataset
group by seller_state
order by total_sellers desc;
/*
=================================================
observation
=================================================

1. the business serves customers across multiple brazilian states,
   demonstrating nationwide market coverage.
2. customers are distributed across hundreds of cities,
   indicating a broad geographic customer base.
3. customer distribution is uneven across states.

4. identifying states with the largest customer base helps
   prioritize marketing campaigns and regional expansion.
. sellers are concentrated in a few states, indicating
   regional hubs for e-commerce operations.

5. comparing seller and customer distribution can reveal
   opportunities for expanding the seller network in
   underserved regions.
*/

/*
=================================================
customers vs sellers by state
purpose:
compare customer demand and seller presence
across brazilian states.
=================================================
*/

with customers as (
    select
        customer_state as state,
        count(distinct customer_unique_id) as total_customers
    from olist_customers_dataset
    group by customer_state
),
sellers as (
    select
        seller_state as state,
        count(distinct seller_id) as total_sellers
    from olist_sellers_dataset
    group by seller_state
)

select
    c.state,
    c.total_customers,
    coalesce(s.total_sellers,0) as total_sellers
from customers c
left join sellers s
on c.state = s.state
order by total_customers desc;
/*
=================================================
observation
=================================================

1. some states have a large customer base but relatively
   few sellers, suggesting opportunities to expand the
   seller network.

2. comparing customer demand with seller availability
   helps identify regions with potential supply-demand
   imbalances.
*/


------

/*
=================================================
8. order lifecycle exploration
purpose:
understand the order fulfillment process by
examining the availability of timestamps at each
stage of the order lifecycle.
=================================================
*/

select
    count(*) as total_orders,

    count(order_purchase_timestamp) as purchase_timestamp,

    count(order_approved_at) as approved_timestamp,

    count(order_delivered_carrier_date) as carrier_timestamp,

    count(order_delivered_customer_date) as delivered_timestamp,

    count(order_estimated_delivery_date) as estimated_delivery_timestamp

from olist_orders_dataset;

/*
=================================================
missing timestamps in the order lifecycle
=================================================
*/

select
    sum(case when order_approved_at is null then 1 else 0 end)
        as missing_approval_date,

    sum(case when order_delivered_carrier_date is null then 1 else 0 end)
        as missing_carrier_date,

    sum(case when order_delivered_customer_date is null then 1 else 0 end)
        as missing_delivery_date,

    sum(case when order_estimated_delivery_date is null then 1 else 0 end)
        as missing_estimated_delivery_date

from olist_orders_dataset;

/*
=================================================
observation
=================================================

1. every order contains a purchase timestamp, indicating that each order has a recorded creation date.

2. some orders do not have approval, carrier, or delivery timestamps because they were cancelled, unavailable, or never progressed through the complete fulfillment process.

3. the estimated delivery date is expected to be available for almost all orders since it is generated when the order is created.

4. understanding timestamp availability helps explain the order lifecycle and prepares the dataset for logistics and delivery analysis.
*/

------

/*
=================================================
9. quick business health check
purpose:
provide a high-level overview of business operations
by checking key order metrics and fulfillment status.
=================================================
*/
select
    (select count(*)
     from olist_orders_dataset o
     left join olist_order_payments_dataset p
        on o.order_id = p.order_id
     where p.order_id is null) as orders_without_payment,

    (select count(*)
     from olist_orders_dataset o
     left join olist_order_reviews_dataset r
        on o.order_id = r.order_id
     where r.order_id is null) as orders_without_review,

    (select count(*)
     from olist_orders_dataset o
     left join olist_order_items_dataset oi
        on o.order_id = oi.order_id
     where oi.order_id is null) as orders_without_items,

    (select count(*)
     from olist_orders_dataset
     where order_status = 'delivered') as delivered_orders,

    (select count(*)
     from olist_orders_dataset
     where order_status = 'canceled') as canceled_orders,

    (
        select round(avg(items_per_order),2)
        from (
            select
                order_id,
                count(*) as items_per_order
            from olist_order_items_dataset
            group by order_id
        ) t
    ) as average_items_per_order;
/*
=================================================
observation
=================================================

1. the majority of orders have associated payments,
   reviews, and order items, indicating that the
   dataset is largely complete.

2. delivered orders represent the largest portion
   of all orders, reflecting successful order
   fulfillment.

3. canceled orders account for only a small
   percentage of total orders.

4. the average number of items per order provides
   insight into typical customer purchasing
   behavior and basket size.

5. this health check offers a quick snapshot of
   the marketplace before performing deeper sales,
   customer, product, and logistics analyses.
*/










---------------------------------------------------------------------------------------------------------









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

1. no business rule violations indicate that the
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










----------------------------------------------------------------------------------









/*
=================================================
Project: Brazilian E-Commerce (Olist) Analysis
File: 03_Sales_Analysis.sql
=================================================
Purpose:
    analyze revenue, order performance, geographic
sales distribution, product performance,
growth trends, and seasonality to generate
business insights.
Dataset:
    Olist Brazilian E-Commerce Public Dataset
=================================================
*/

/*
=================================================
1.1 executive sales overview
=================================================
*/

select

    round(sum(oi.price),2) as total_revenue,

    count(distinct o.order_id) as total_orders,

    count(*) as total_items_sold,

    round(
        sum(oi.price) /
        count(distinct o.order_id),
        2
    ) as average_order_value,

    round(
        count(*) /
        count(distinct o.order_id),
        2
    ) as average_items_per_order,

    round(avg(oi.price),2) as average_item_price,

    round(sum(oi.freight_value),2) as total_freight,

    round(
        sum(oi.freight_value)*100/
        sum(oi.price),
        2
    ) as freight_percentage

from olist_orders_dataset o
join olist_order_items_dataset oi
on o.order_id = oi.order_id
where o.order_status='delivered';
/*
=================================================
observation
=================================================

1. total revenue is calculated only from delivered
orders to represent realized sales.

2. average order value measures customer spending
per completed order.

3. freight percentage indicates how much shipping
cost contributes relative to product revenue.

4. these KPIs serve as the foundation for executive
sales reporting.
=================================================
*/

/*
=================================================
1.2 revenue vs freight
=================================================
*/

select

    round(sum(price),2) as product_revenue,

    round(sum(freight_value),2) as freight_revenue,

    round(sum(price)+sum(freight_value),2) as gross_sales

from olist_order_items_dataset oi

join olist_orders_dataset o
on oi.order_id=o.order_id

where order_status='delivered';

/*
=================================================
1.3 average revenue per customer
=================================================
*/

select

round(
sum(price)/
count(distinct customer_unique_id)
,2) as revenue_per_customer

from olist_orders_dataset o

join olist_order_items_dataset oi
on o.order_id=oi.order_id

join olist_customers_dataset c
on o.customer_id=c.customer_id

where order_status='delivered';

/*
=================================================
1.4 average revenue per seller
=================================================
*/

select

round(
sum(price)/
count(distinct seller_id)
,2) as revenue_per_seller

from olist_order_items_dataset oi

join olist_orders_dataset o
on oi.order_id=o.order_id

where order_status='delivered';

/*
=================================================
1.5 highest value order
=================================================
*/

select

order_id,

round(sum(price),2) as order_value

from olist_order_items_dataset

group by order_id

order by order_value desc

limit 10;

/*
=================================================
1.6 lowest value order
=================================================
*/

select

order_id,

round(sum(price),2) as order_value

from olist_order_items_dataset

group by order_id

order by order_value

limit 10;

/*
=================================================
1.7 revenue distribution
=================================================
*/

select

case

when price<50 then 'Below 50'

when price<100 then '50-99'

when price<250 then '100-249'

when price<500 then '250-499'

else '500+'

end as price_range,

count(*) items,

round(sum(price),2) revenue

from olist_order_items_dataset

group by price_range

order by min(price);
/*
=================================================
sales overview summary
=================================================

• total revenue represents realized marketplace sales.

• average order value measures customer spending.

• freight analysis highlights logistics cost.

• revenue per customer estimates customer value.

• revenue per seller measures seller productivity.

• highest-value orders reveal premium purchases.

• revenue distribution shows customer buying patterns.

=================================================
*/


--------


/*
=================================================
2. revenue trends
purpose:
analyze how revenue changes over time to identify
growth patterns, seasonality, and business trends.
=================================================
*/
/*
=================================================
2.1 daily revenue
=================================================
*/

select
    date(o.order_purchase_timestamp) as order_date,
    round(sum(oi.price),2) as revenue
from olist_orders_dataset o
join olist_order_items_dataset oi
    on o.order_id = oi.order_id
where o.order_status = 'delivered'
group by order_date
order by order_date;

/*
=================================================
2.2 weekly revenue
=================================================
*/

select
    year(order_purchase_timestamp) as year,
    week(order_purchase_timestamp) as week_number,
    round(sum(oi.price),2) as revenue
from olist_orders_dataset o
join olist_order_items_dataset oi
    on o.order_id = oi.order_id
where o.order_status = 'delivered'
group by
    year(order_purchase_timestamp),
    week(order_purchase_timestamp)
order by
    year,
    week_number;
    
/*
=================================================
2.3 monthly revenue
=================================================
*/

select
    date_format(order_purchase_timestamp,'%Y-%m') as month,
    round(sum(oi.price),2) as revenue
from olist_orders_dataset o
join olist_order_items_dataset oi
    on o.order_id = oi.order_id
where o.order_status = 'delivered'
group by month
order by month;

/*
=================================================
2.4 quarterly revenue
=================================================
*/

select
    concat(
        year(order_purchase_timestamp),
        '-Q',
        quarter(order_purchase_timestamp)
    ) as quarter,
    round(sum(oi.price),2) as revenue
from olist_orders_dataset o
join olist_order_items_dataset oi
    on o.order_id = oi.order_id
where o.order_status='delivered'
group by
    quarter
order by
    quarter;
    
/*
=================================================
2.5 yearly revenue
=================================================
*/
select
    year(order_purchase_timestamp) as year,
    round(sum(oi.price),2) as revenue
from olist_orders_dataset o
join olist_order_items_dataset oi
    on o.order_id = oi.order_id
where o.order_status='delivered'
group by year
order by year;

/*
=================================================
2.6 running total revenue
=================================================
*/

with monthly_revenue as (

    select
        date_format(order_purchase_timestamp,'%Y-%m') as month,
        sum(oi.price) as revenue
    from olist_orders_dataset o
    join olist_order_items_dataset oi
        on o.order_id=oi.order_id
    where o.order_status='delivered'
    group by month

)

select

    month,

    round(revenue,2) as monthly_revenue,

    round(
        sum(revenue) over(
            order by month
        ),
        2
    ) as cumulative_revenue

from monthly_revenue;

/*
=================================================
2.7 three-month rolling average revenue
=================================================
*/

with monthly_revenue as (

    select
        date_format(order_purchase_timestamp,'%Y-%m') as month,
        sum(oi.price) as revenue
    from olist_orders_dataset o
    join olist_order_items_dataset oi
        on o.order_id=oi.order_id
    where o.order_status='delivered'
    group by month

)

select

    month,

    round(revenue,2) as revenue,

    round(
        avg(revenue) over(
            order by month
            rows between 2 preceding and current row
        ),
        2
    ) as rolling_3_month_average

from monthly_revenue;

/*
=================================================
2.8 highest revenue month
=================================================
*/

select
    date_format(order_purchase_timestamp,'%Y-%m') as month,
    round(sum(oi.price),2) as revenue
from olist_orders_dataset o
join olist_order_items_dataset oi
    on o.order_id=oi.order_id
where o.order_status='delivered'
group by month
order by revenue desc
limit 1;

/*
=================================================
2.9 lowest revenue month
=================================================
*/

select
    date_format(order_purchase_timestamp,'%Y-%m') as month,
    round(sum(oi.price),2) as revenue
from olist_orders_dataset o
join olist_order_items_dataset oi
    on o.order_id=oi.order_id
where o.order_status='delivered'
group by month
order by revenue
limit 1;

/*
=================================================
2.10 month-over-month revenue growth
=================================================
*/
with monthly_revenue as (

    select
        date_format(o.order_purchase_timestamp, '%Y-%m') as month,
        sum(oi.price) as revenue
    from olist_orders_dataset o
    join olist_order_items_dataset oi
        on o.order_id = oi.order_id
    where o.order_status = 'delivered'
    group by month

)

select

    month,

    round(revenue,2) as revenue,

    round(
        lag(revenue) over(order by month),
        2
    ) as previous_month_revenue,

    round(
        (
            revenue -
            lag(revenue) over(order by month)
        )
        *100 /
        lag(revenue) over(order by month),
        2
    ) as mom_growth_percent

from monthly_revenue
order by month;

/*
=================================================
2.11 year-over-year revenue growth
=================================================
*/
with yearly_revenue as (

    select
        year(o.order_purchase_timestamp) as year,
        sum(oi.price) as revenue
    from olist_orders_dataset o
    join olist_order_items_dataset oi
        on o.order_id = oi.order_id
    where o.order_status = 'delivered'
    group by year

)

select

    year,

    round(revenue,2) as revenue,

    round(
        lag(revenue) over(order by year),
        2
    ) as previous_year_revenue,

    round(
        (
            revenue -
            lag(revenue) over(order by year)
        )
        *100 /
        lag(revenue) over(order by year),
        2
    ) as yoy_growth_percent

from yearly_revenue
order by year;
/*
=================================================
observation
=================================================

1. revenue trends reveal how sales evolve over time
   and help identify periods of growth or decline.

2. monthly and quarterly analysis smooths daily
   fluctuations, making long-term patterns easier
   to interpret.

3. the running total illustrates cumulative business
   growth throughout the dataset.

4. the rolling three-month average reduces the impact
   of short-term volatility and highlights underlying
   sales trends.

5. identifying the highest and lowest revenue months
   helps evaluate the effectiveness of seasonal demand,
   marketing campaigns, and operational performance.
6. month-over-month (mom) growth measures short-term
   changes in sales performance and helps identify
   seasonal trends or the impact of promotions.

7. year-over-year (yoy) growth compares annual
   performance while minimizing seasonal effects,
   making it a key metric for evaluating long-term
   business growth.

8. positive growth percentages indicate revenue
   expansion, while negative values highlight periods
   of declining sales that may require further
   investigation.
=================================================
*/


--------


/*
=================================================
3. order analysis
purpose:
analyze order volume, customer purchasing behavior,
and shopping patterns to understand how customers
interact with the marketplace.
=================================================
*/

/*
=================================================
3.1 daily orders
=================================================
*/

select

    date(order_purchase_timestamp) as order_date,

    count(*) as total_orders

from olist_orders_dataset

where order_status='delivered'

group by order_date

order by order_date;

/*
=================================================
3.2 monthly orders
=================================================
*/

select

    date_format(order_purchase_timestamp,'%Y-%m') as month,

    count(*) as total_orders

from olist_orders_dataset

where order_status='delivered'

group by month

order by month;

/*
=================================================
3.3 orders by day of week
=================================================
*/

select

    dayname(order_purchase_timestamp) as weekday,

    count(*) as total_orders

from olist_orders_dataset

where order_status='delivered'

group by weekday

order by field(
    weekday,
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
);

/*
=================================================
3.4 orders by hour
=================================================
*/

select

    hour(order_purchase_timestamp) as purchase_hour,

    count(*) as total_orders

from olist_orders_dataset

where order_status='delivered'

group by purchase_hour

order by purchase_hour;

/*
=================================================
3.5 average orders per customer
=================================================
*/

select

    round(

        count(distinct o.order_id)

        /

        count(distinct c.customer_unique_id)

    ,2) as average_orders_per_customer

from olist_orders_dataset o

join olist_customers_dataset c

on o.customer_id=c.customer_id

where order_status='delivered';

/*
=================================================
3.6 distribution of order sizes
=================================================
*/

with order_size as (

select

    order_id,

    count(*) as total_items

from olist_order_items_dataset

group by order_id

)

select

case

when total_items=1 then '1 Item'

when total_items=2 then '2 Items'

when total_items=3 then '3 Items'

when total_items=4 then '4 Items'

else '5+ Items'

end as order_size,

count(*) as total_orders

from order_size

group by order_size

order by min(total_items);

/*
=================================================
3.7 top 10 highest value orders
=================================================
*/

select

    oi.order_id,

    round(sum(price),2) as order_value

from olist_order_items_dataset oi

join olist_orders_dataset o

on oi.order_id=o.order_id

where order_status='delivered'

group by oi.order_id

order by order_value desc

limit 10;

/*
=================================================
3.8 average order processing time
=================================================
*/

select

round(

avg(

timestampdiff(

hour,

order_purchase_timestamp,

order_approved_at

)

)

,2) as average_processing_hours

from olist_orders_dataset

where order_status='delivered'

and order_approved_at is not null;

/*
=================================================
3.9 executive summary
=================================================
*/

select

count(*) as delivered_orders,

round(

count(*)/

count(distinct customer_id)

,2) as average_orders_per_customer,

round(

avg(timestampdiff(

hour,

order_purchase_timestamp,

order_approved_at

))

,2) as average_processing_hours

from olist_orders_dataset

where order_status='delivered';
/*
=================================================
observation
=================================================

1. order volume reveals customer purchasing activity
   over time and complements revenue analysis.

2. daily and monthly order trends help identify
   business growth and seasonal demand.

3. day-of-week and hourly analyses reveal peak
   shopping periods, supporting staffing and
   marketing decisions.

4. order size distribution provides insight into
   customer basket behavior and cross-selling
   opportunities.

5. average processing time measures operational
   efficiency from purchase to order approval.

=================================================
*/


--------


/*
=================================================
4. geographic sales analysis
purpose:
analyze sales performance across states and cities
to identify high-performing markets, customer
concentration, and regional revenue opportunities.
=================================================
*/

/*
=================================================
4.1 revenue by state
=================================================
*/

select

    c.customer_state as state,

    round(sum(oi.price),2) as revenue

from olist_orders_dataset o

join olist_customers_dataset c
    on o.customer_id = c.customer_id

join olist_order_items_dataset oi
    on o.order_id = oi.order_id

where o.order_status = 'delivered'

group by state

order by revenue desc;

/*
=================================================
4.2 top 10 states by revenue
=================================================
*/

select

    c.customer_state as state,

    round(sum(oi.price),2) as revenue

from olist_orders_dataset o

join olist_customers_dataset c
    on o.customer_id = c.customer_id

join olist_order_items_dataset oi
    on o.order_id = oi.order_id

where o.order_status='delivered'

group by state

order by revenue desc

limit 10;

/*
=================================================
4.3 bottom 10 states by revenue
=================================================
*/

select

    c.customer_state as state,

    round(sum(oi.price),2) as revenue

from olist_orders_dataset o

join olist_customers_dataset c
    on o.customer_id=c.customer_id

join olist_order_items_dataset oi
    on o.order_id=oi.order_id

where o.order_status='delivered'

group by state

order by revenue

limit 10;
/*
=================================================
4.4 revenue by city
=================================================
*/

select

    c.customer_city as city,

    round(sum(oi.price),2) as revenue

from olist_orders_dataset o

join olist_customers_dataset c
    on o.customer_id=c.customer_id

join olist_order_items_dataset oi
    on o.order_id=oi.order_id

where o.order_status='delivered'

group by city

order by revenue desc;

/*
=================================================
4.5 top 20 cities by revenue
=================================================
*/

select

    c.customer_city as city,

    round(sum(oi.price),2) as revenue

from olist_orders_dataset o

join olist_customers_dataset c
    on o.customer_id=c.customer_id

join olist_order_items_dataset oi
    on o.order_id=oi.order_id

where o.order_status='delivered'

group by city

order by revenue desc

limit 20;

/*
=================================================
4.6 average order value by state
=================================================
*/

select

    c.customer_state as state,

    round(

        sum(oi.price)

        /

        count(distinct o.order_id)

    ,2) as average_order_value

from olist_orders_dataset o

join olist_customers_dataset c
    on o.customer_id=c.customer_id

join olist_order_items_dataset oi
    on o.order_id=oi.order_id

where o.order_status='delivered'

group by state

order by average_order_value desc;

/*
=================================================
4.7 orders by state
=================================================
*/

select

    c.customer_state as state,

    count(distinct o.order_id) as total_orders

from olist_orders_dataset o

join olist_customers_dataset c
    on o.customer_id=c.customer_id

where o.order_status='delivered'

group by state

order by total_orders desc;

/*
=================================================
4.8 customers by state
=================================================
*/

select

    customer_state as state,

    count(distinct customer_unique_id) as total_customers

from olist_customers_dataset

group by state

order by total_customers desc;

/*
=================================================
4.9 revenue per customer by state
=================================================
*/

select

    c.customer_state as state,

    round(

        sum(oi.price)

        /

        count(distinct c.customer_unique_id)

    ,2) as revenue_per_customer

from olist_orders_dataset o

join olist_customers_dataset c
    on o.customer_id=c.customer_id

join olist_order_items_dataset oi
    on o.order_id=oi.order_id

where o.order_status='delivered'

group by state

order by revenue_per_customer desc;

/*
=================================================
4.10 revenue contribution by state
=================================================
*/

with state_revenue as (

select

    c.customer_state as state,

    sum(oi.price) as revenue

from olist_orders_dataset o

join olist_customers_dataset c
    on o.customer_id=c.customer_id

join olist_order_items_dataset oi
    on o.order_id=oi.order_id

where o.order_status='delivered'

group by state

)

select

    state,

    round(revenue,2) as revenue,

    round(

        revenue*100

        /

        sum(revenue) over()

    ,2) as revenue_percentage

from state_revenue

order by revenue desc;

/*
=================================================
4.11 geographic executive summary
=================================================
*/

with state_summary as (

select

    c.customer_state,

    sum(oi.price) revenue,

    count(distinct o.order_id) orders,

    count(distinct c.customer_unique_id) customers

from olist_orders_dataset o

join olist_customers_dataset c
on o.customer_id=c.customer_id

join olist_order_items_dataset oi
on o.order_id=oi.order_id

where order_status='delivered'

group by customer_state

)

select

customer_state,

round(revenue,2) as revenue,

orders,

customers,

round(revenue/orders,2) as average_order_value,

round(revenue/customers,2) as revenue_per_customer

from state_summary

order by revenue desc;
/*
=================================================
observation
=================================================

1. geographic analysis identifies the regions that
generate the highest revenue and order volume.

2. comparing revenue, customers, and average order
value highlights differences in customer purchasing
behavior across states.

3. revenue contribution by state helps prioritize
markets for expansion, marketing investment, and
operational improvements.

4. identifying low-performing regions provides
opportunities to investigate potential barriers to
growth and develop targeted business strategies.

=================================================
*/


--------


/*
=================================================
5. product category sales
purpose:
analyze product category performance by measuring
revenue, sales volume, pricing, and contribution
to identify the marketplace's strongest and
weakest categories.
=================================================
*/

/*
=================================================
5.1 revenue by category
=================================================
*/

select

    coalesce(
        pc.product_category_name_english,
        'Unknown'
    ) as category,

    round(sum(oi.price),2) as revenue

from olist_order_items_dataset oi

join olist_products_dataset p
    on oi.product_id = p.product_id

left join product_category_name_translation pc
    on p.product_category_name = pc.product_category_name

group by category

order by revenue desc;

/*
=================================================
5.2 top 10 categories by revenue
=================================================
*/

select

    coalesce(
        pc.product_category_name_english,
        'Unknown'
    ) as category,

    round(sum(oi.price),2) as revenue

from olist_order_items_dataset oi

join olist_products_dataset p
    on oi.product_id=p.product_id

left join product_category_name_translation pc
    on p.product_category_name=pc.product_category_name

group by category

order by revenue desc

limit 10;

/*
=================================================
5.3 bottom 10 categories by revenue
=================================================
*/

select

    coalesce(
        pc.product_category_name_english,
        'Unknown'
    ) as category,

    round(sum(oi.price),2) as revenue

from olist_order_items_dataset oi

join olist_products_dataset p
    on oi.product_id=p.product_id

left join product_category_name_translation pc
    on p.product_category_name=pc.product_category_name

group by category

order by revenue

limit 10;

/*
=================================================
5.4 units sold by category
=================================================
*/

select

    coalesce(
        pc.product_category_name_english,
        'Unknown'
    ) as category,

    count(*) as units_sold

from olist_order_items_dataset oi

join olist_products_dataset p
    on oi.product_id=p.product_id

left join product_category_name_translation pc
    on p.product_category_name=pc.product_category_name

group by category

order by units_sold desc;

/*
=================================================
5.5 orders by category
=================================================
*/

select

    coalesce(
        pc.product_category_name_english,
        'Unknown'
    ) as category,

    count(distinct oi.order_id) as total_orders

from olist_order_items_dataset oi

join olist_products_dataset p
    on oi.product_id=p.product_id

left join product_category_name_translation pc
    on p.product_category_name=pc.product_category_name

group by category

order by total_orders desc;

/*
=================================================
5.6 average selling price by category
=================================================
*/

select

    coalesce(
        pc.product_category_name_english,
        'Unknown'
    ) as category,

    round(avg(oi.price),2) as average_price

from olist_order_items_dataset oi

join olist_products_dataset p
    on oi.product_id=p.product_id

left join product_category_name_translation pc
    on p.product_category_name=pc.product_category_name

group by category

order by average_price desc;

/*
=================================================
5.7 average order value by category
=================================================
*/

select

    coalesce(
        pc.product_category_name_english,
        'Unknown'
    ) as category,

    round(
        sum(oi.price)/
        count(distinct oi.order_id),
        2
    ) as average_order_value

from olist_order_items_dataset oi

join olist_products_dataset p
    on oi.product_id=p.product_id

left join product_category_name_translation pc
    on p.product_category_name=pc.product_category_name

group by category

order by average_order_value desc;

/*
=================================================
5.8 revenue contribution by category
=================================================
*/

with category_revenue as (

select

    coalesce(
        pc.product_category_name_english,
        'Unknown'
    ) as category,

    sum(oi.price) as revenue

from olist_order_items_dataset oi

join olist_products_dataset p
    on oi.product_id=p.product_id

left join product_category_name_translation pc
    on p.product_category_name=pc.product_category_name

group by category

)

select

    category,

    round(revenue,2) as revenue,

    round(
        revenue*100/
        sum(revenue) over(),
        2
    ) as revenue_percentage

from category_revenue

order by revenue desc;

/*
=================================================
5.9 rank categories by revenue
=================================================
*/

with category_revenue as (

select

    coalesce(
        pc.product_category_name_english,
        'Unknown'
    ) as category,

    sum(oi.price) as revenue

from olist_order_items_dataset oi

join olist_products_dataset p
    on oi.product_id=p.product_id

left join product_category_name_translation pc
    on p.product_category_name=pc.product_category_name

group by category

)

select

    rank() over(
        order by revenue desc
    ) as revenue_rank,

    category,

    round(revenue,2) as revenue

from category_revenue;

/*
=================================================
5.10 product category executive summary
=================================================
*/

with category_summary as (

select

    coalesce(
        pc.product_category_name_english,
        'Unknown'
    ) as category,

    sum(oi.price) as revenue,

    count(*) as units_sold,

    count(distinct oi.order_id) as total_orders

from olist_order_items_dataset oi

join olist_products_dataset p
    on oi.product_id=p.product_id

left join product_category_name_translation pc
    on p.product_category_name=pc.product_category_name

group by category

)

select

    category,

    round(revenue,2) as revenue,

    units_sold,

    total_orders,

    round(
        revenue/total_orders,
        2
    ) as average_order_value,

    round(
        revenue/units_sold,
        2
    ) as average_selling_price

from category_summary

order by revenue desc;
/*
=================================================
observation
=================================================

1. revenue by category identifies the marketplace's
highest and lowest performing product categories.

2. comparing units sold and revenue distinguishes
high-volume categories from premium-priced categories.

3. average selling price highlights pricing
differences across product categories.

4. revenue contribution reveals which categories
generate the largest share of total marketplace
sales and should receive strategic attention.

5. ranking categories helps prioritize inventory,
marketing investment, and product portfolio
decisions.

=================================================
*/


--------


/*
=================================================
6. order value analysis
purpose:
analyze customer spending behavior by measuring
order values, identifying purchasing patterns,
and comparing order value across time and regions.
=================================================
*/

/*
=================================================
6.1 average order value
=================================================
*/

select

    round(
        sum(oi.price) /
        count(distinct o.order_id),
        2
    ) as average_order_value

from olist_orders_dataset o

join olist_order_items_dataset oi
    on o.order_id = oi.order_id

where o.order_status = 'delivered';

/*
=================================================
6.2 order value distribution
=================================================
*/

with order_value as (

select

    order_id,

    sum(price) as order_value

from olist_order_items_dataset

group by order_id

)

select

case

    when order_value < 50 then 'Below 50'

    when order_value < 100 then '50 - 99'

    when order_value < 250 then '100 - 249'

    when order_value < 500 then '250 - 499'

    when order_value < 1000 then '500 - 999'

    else '1000+'

end as order_value_range,

count(*) as total_orders,

round(avg(order_value),2) as average_order_value

from order_value

group by order_value_range

order by min(order_value);

/*
=================================================
6.3 top 20 highest value orders
=================================================
*/

select

    oi.order_id,

    round(sum(oi.price),2) as order_value

from olist_order_items_dataset oi

group by oi.order_id

order by order_value desc

limit 20;

/*
=================================================
6.4 lowest value orders
=================================================
*/

select

    oi.order_id,

    round(sum(oi.price),2) as order_value

from olist_order_items_dataset oi

group by oi.order_id

order by order_value

limit 20;

/*
=================================================
6.5 monthly average order value
=================================================
*/

select

    date_format(o.order_purchase_timestamp,'%Y-%m') as month,

    round(

        sum(oi.price)

        /

        count(distinct o.order_id)

    ,2) as average_order_value

from olist_orders_dataset o

join olist_order_items_dataset oi

on o.order_id = oi.order_id

where o.order_status='delivered'

group by month

order by month;

/*
=================================================
6.6 average order value by state
=================================================
*/

select

    c.customer_state,

    round(

        sum(oi.price)

        /

        count(distinct o.order_id)

    ,2) as average_order_value

from olist_orders_dataset o

join olist_customers_dataset c

on o.customer_id=c.customer_id

join olist_order_items_dataset oi

on o.order_id=oi.order_id

where o.order_status='delivered'

group by c.customer_state

order by average_order_value desc;

/*
=================================================
6.7 order value quartiles
=================================================
*/

with order_value as (

select

    order_id,

    sum(price) as order_value

from olist_order_items_dataset

group by order_id

)

select

    order_id,

    round(order_value,2) as order_value,

    ntile(4) over(order by order_value) as quartile

from order_value

order by order_value desc;

/*
=================================================
6.8 executive summary
=================================================
*/

with order_value as (

select

    order_id,

    sum(price) as order_value

from olist_order_items_dataset

group by order_id

)

select

    round(avg(order_value),2) as average_order_value,

    round(min(order_value),2) as minimum_order_value,

    round(max(order_value),2) as maximum_order_value,

    round(sum(order_value),2) as total_revenue,

    count(*) as total_orders

from order_value;
/*
=================================================
observation
=================================================

1. average order value measures the typical amount
spent per completed order and is a key indicator
of customer purchasing behavior.

2. order value distribution reveals whether the
business relies on many low-value orders or fewer
high-value purchases.

3. monthly average order value helps identify
changes in customer spending over time and
evaluates the impact of pricing or promotional
strategies.

4. comparing average order value across states
highlights regional differences in purchasing
power and customer preferences.

5. order value quartiles segment orders into
spending groups, supporting customer targeting,
pricing strategies, and premium product analysis.

=================================================
*/


--------


/*
=================================================
7. revenue contribution
purpose:
measure the percentage contribution of different
business segments to total revenue in order to
identify the marketplace's most valuable
customers, sellers, states, and product categories.
=================================================
*/

/*
=================================================
7.1 revenue contribution by state
=================================================
*/

with state_revenue as (

    select

        c.customer_state,

        sum(oi.price) as revenue

    from olist_orders_dataset o

    join olist_customers_dataset c
        on o.customer_id = c.customer_id

    join olist_order_items_dataset oi
        on o.order_id = oi.order_id

    where o.order_status = 'delivered'

    group by c.customer_state

)

select

    customer_state,

    round(revenue,2) as revenue,

    round(
        revenue * 100 /
        sum(revenue) over(),
        2
    ) as revenue_percentage

from state_revenue

order by revenue desc;

/*
=================================================
7.2 revenue contribution by product category
=================================================
*/

with category_revenue as (

select

    coalesce(pc.product_category_name_english,'Unknown') as category,

    sum(oi.price) as revenue

from olist_order_items_dataset oi

join olist_products_dataset p
    on oi.product_id=p.product_id

left join product_category_name_translation pc
    on p.product_category_name=pc.product_category_name

group by category

)

select

    category,

    round(revenue,2) as revenue,

    round(
        revenue*100/
        sum(revenue) over(),
        2
    ) as revenue_percentage

from category_revenue

order by revenue desc;

/*
=================================================
7.3 revenue contribution by seller
=================================================
*/

with seller_revenue as (

select

    seller_id,

    sum(price) as revenue

from olist_order_items_dataset

group by seller_id

)

select

    seller_id,

    round(revenue,2) as revenue,

    round(
        revenue*100/
        sum(revenue) over(),
        2
    ) as revenue_percentage

from seller_revenue

order by revenue desc;

/*
=================================================
7.4 revenue contribution by customer
=================================================
*/

with customer_revenue as (

select

    c.customer_unique_id,

    sum(oi.price) as revenue

from olist_orders_dataset o

join olist_customers_dataset c

on o.customer_id=c.customer_id

join olist_order_items_dataset oi

on o.order_id=oi.order_id

where o.order_status='delivered'

group by c.customer_unique_id

)

select

    customer_unique_id,

    round(revenue,2) as revenue,

    round(
        revenue*100/
        sum(revenue) over(),
        4
    ) as revenue_percentage

from customer_revenue

order by revenue desc;

/*
=================================================
7.5 top 10 revenue-contributing customers
=================================================
*/

select

    c.customer_unique_id,

    round(sum(oi.price),2) as revenue

from olist_orders_dataset o

join olist_customers_dataset c

on o.customer_id=c.customer_id

join olist_order_items_dataset oi

on o.order_id=oi.order_id

where o.order_status='delivered'

group by c.customer_unique_id

order by revenue desc

limit 10;

/*
=================================================
7.6 top 10 revenue-contributing sellers
=================================================
*/

select

    seller_id,

    round(sum(price),2) as revenue

from olist_order_items_dataset

group by seller_id

order by revenue desc

limit 10;

/*
=================================================
7.7 executive summary
=================================================
*/

with contribution as (

select

    c.customer_state as state,

    coalesce(pc.product_category_name_english,'Unknown') as category,

    oi.seller_id,

    c.customer_unique_id,

    sum(oi.price) as revenue

from olist_orders_dataset o

join olist_customers_dataset c
    on o.customer_id=c.customer_id

join olist_order_items_dataset oi
    on o.order_id=oi.order_id

join olist_products_dataset p
    on oi.product_id=p.product_id

left join product_category_name_translation pc
    on p.product_category_name=pc.product_category_name

where o.order_status='delivered'

group by
    state,
    category,
    seller_id,
    customer_unique_id

)

select

    count(distinct state) as states,

    count(distinct category) as categories,

    count(distinct seller_id) as sellers,

    count(distinct customer_unique_id) as customers,

    round(sum(revenue),2) as total_revenue

from contribution;
/*
=================================================
observation
=================================================

1. revenue contribution analysis measures each
business segment's share of total revenue rather
than absolute sales.

2. comparing contribution percentages helps identify
the marketplace's most valuable states, product
categories, sellers, and customers.

3. a small number of customers or sellers often
generate a disproportionately large share of total
revenue, highlighting opportunities for targeted
retention and partnership strategies.

4. understanding revenue contribution supports
resource allocation, marketing investment, and
long-term business planning.

=================================================
*/


--------


/*
=================================================
8. pareto analysis (80/20 rule)
purpose:
identify the products, customers, sellers, and
states that contribute the majority of revenue
using the pareto principle.
=================================================
*/

/*
=================================================
8.1 pareto analysis by product category
=================================================
*/

with category_revenue as (

    select
        coalesce(pc.product_category_name_english,'Unknown') as category,
        sum(oi.price) as revenue
    from olist_order_items_dataset oi
    join olist_products_dataset p
        on oi.product_id = p.product_id
    left join product_category_name_translation pc
        on p.product_category_name = pc.product_category_name
    group by category

)

select

    category,

    round(revenue,2) as revenue,

    round(
        sum(revenue) over(order by revenue desc),
        2
    ) as cumulative_revenue,

    round(
        sum(revenue) over(order by revenue desc)
        *100/
        sum(revenue) over(),
        2
    ) as cumulative_percentage,

    case
        when
            sum(revenue) over(order by revenue desc)
            *100/
            sum(revenue) over() <=80
        then 'Top 80%'
        else 'Remaining 20%'
    end as pareto_group

from category_revenue

order by revenue desc;

/*
=================================================
8.2 pareto analysis by customer
=================================================
*/

with customer_revenue as (

select

    c.customer_unique_id,

    sum(oi.price) as revenue

from olist_orders_dataset o

join olist_customers_dataset c
    on o.customer_id=c.customer_id

join olist_order_items_dataset oi
    on o.order_id=oi.order_id

where o.order_status='delivered'

group by c.customer_unique_id

)

select

    customer_unique_id,

    round(revenue,2) as revenue,

    round(
        sum(revenue) over(order by revenue desc),
        2
    ) as cumulative_revenue,

    round(
        sum(revenue) over(order by revenue desc)
        *100/
        sum(revenue) over(),
        2
    ) as cumulative_percentage,

    case
        when
            sum(revenue) over(order by revenue desc)
            *100/
            sum(revenue) over() <=80
        then 'Top 80%'
        else 'Remaining 20%'
    end as pareto_group

from customer_revenue

order by revenue desc;

/*
=================================================
8.3 pareto analysis by seller
=================================================
*/

with seller_revenue as (

select

    seller_id,

    sum(price) as revenue

from olist_order_items_dataset

group by seller_id

)

select

    seller_id,

    round(revenue,2) as revenue,

    round(
        sum(revenue) over(order by revenue desc),
        2
    ) as cumulative_revenue,

    round(
        sum(revenue) over(order by revenue desc)
        *100/
        sum(revenue) over(),
        2
    ) as cumulative_percentage,

    case
        when
            sum(revenue) over(order by revenue desc)
            *100/
            sum(revenue) over() <=80
        then 'Top 80%'
        else 'Remaining 20%'
    end as pareto_group

from seller_revenue

order by revenue desc;

/*
=================================================
8.4 pareto analysis by state
=================================================
*/

with state_revenue as (

select

    c.customer_state,

    sum(oi.price) as revenue

from olist_orders_dataset o

join olist_customers_dataset c
    on o.customer_id=c.customer_id

join olist_order_items_dataset oi
    on o.order_id=oi.order_id

where o.order_status='delivered'

group by c.customer_state

)

select

    customer_state,

    round(revenue,2) as revenue,

    round(
        sum(revenue) over(order by revenue desc),
        2
    ) as cumulative_revenue,

    round(
        sum(revenue) over(order by revenue desc)
        *100/
        sum(revenue) over(),
        2
    ) as cumulative_percentage,

    case
        when
            sum(revenue) over(order by revenue desc)
            *100/
            sum(revenue) over() <=80
        then 'Top 80%'
        else 'Remaining 20%'
    end as pareto_group

from state_revenue

order by revenue desc;

/*
=================================================
8.5 executive summary
=================================================
*/

select
    'Product Categories' as segment,
    count(distinct product_category_name) as total_entities
from olist_products_dataset

union all

select
    'Customers',
    count(distinct customer_unique_id)
from olist_customers_dataset

union all

select
    'Sellers',
    count(distinct seller_id)
from olist_sellers_dataset

union all

select
    'States',
    count(distinct customer_state)
from olist_customers_dataset;

/*
=================================================
8.6 pareto summary by product category
=================================================
*/

with category_revenue as (

    select
        coalesce(pc.product_category_name_english,'Unknown') as category,
        sum(oi.price) as revenue
    from olist_order_items_dataset oi
    join olist_products_dataset p
        on oi.product_id = p.product_id
    left join product_category_name_translation pc
        on p.product_category_name = pc.product_category_name
    group by category

),

pareto as (

select

    category,

    revenue,

    sum(revenue) over(order by revenue desc) as cumulative_revenue,

    sum(revenue) over() as total_revenue

from category_revenue

)

select

    count(*) as total_categories,

    sum(
        case
            when cumulative_revenue <= total_revenue*0.80
            then 1
            else 0
        end
    ) as categories_for_80_percent,

    round(

        sum(
            case
                when cumulative_revenue <= total_revenue*0.80
                then 1
                else 0
            end
        )*100.0

        /

        count(*)

    ,2) as percentage_of_categories

from pareto;

/*
=================================================
8.7 pareto summary by customer
=================================================
*/

with customer_revenue as (

select

    c.customer_unique_id,

    sum(oi.price) revenue

from olist_orders_dataset o

join olist_customers_dataset c

on o.customer_id=c.customer_id

join olist_order_items_dataset oi

on o.order_id=oi.order_id

where o.order_status='delivered'

group by c.customer_unique_id

),

pareto as (

select

    customer_unique_id,

    revenue,

    sum(revenue) over(order by revenue desc) cumulative_revenue,

    sum(revenue) over() total_revenue

from customer_revenue

)

select

count(*) total_customers,

sum(

case

when cumulative_revenue<=total_revenue*0.80

then 1

else 0

end

) customers_for_80_percent,

round(

sum(

case

when cumulative_revenue<=total_revenue*0.80

then 1

else 0

end

)*100.0

/

count(*)

,2) percentage_of_customers

from pareto;

/*
=================================================
8.8 pareto summary by seller
=================================================
*/

with seller_revenue as (

select

seller_id,

sum(price) revenue

from olist_order_items_dataset

group by seller_id

),

pareto as (

select

seller_id,

revenue,

sum(revenue) over(order by revenue desc) cumulative_revenue,

sum(revenue) over() total_revenue

from seller_revenue

)

select

count(*) total_sellers,

sum(

case

when cumulative_revenue<=total_revenue*0.80

then 1

else 0

end

) sellers_for_80_percent,

round(

sum(

case

when cumulative_revenue<=total_revenue*0.80

then 1

else 0

end

)*100.0

/

count(*)

,2) percentage_of_sellers

from pareto;

/*
=================================================
8.9 pareto summary by state
=================================================
*/

with state_revenue as (

select

c.customer_state,

sum(oi.price) revenue

from olist_orders_dataset o

join olist_customers_dataset c

on o.customer_id=c.customer_id

join olist_order_items_dataset oi

on o.order_id=oi.order_id

where o.order_status='delivered'

group by c.customer_state

),

pareto as (

select

customer_state,

revenue,

sum(revenue) over(order by revenue desc) cumulative_revenue,

sum(revenue) over() total_revenue

from state_revenue

)

select

count(*) total_states,

sum(

case

when cumulative_revenue<=total_revenue*0.80

then 1

else 0

end

) states_for_80_percent,

round(

sum(

case

when cumulative_revenue<=total_revenue*0.80

then 1

else 0

end

)*100.0

/

count(*)

,2) percentage_of_states

from pareto;

/*
=================================================
8.10 executive pareto summary
=================================================
*/

-- Product Categories
with category_summary as (
    with category_revenue as (
        select
            coalesce(pc.product_category_name_english,'Unknown') as entity,
            sum(oi.price) revenue
        from olist_order_items_dataset oi
        join olist_products_dataset p
            on oi.product_id=p.product_id
        left join product_category_name_translation pc
            on p.product_category_name=pc.product_category_name
        group by entity
    ),
    pareto as (
        select
            entity,
            revenue,
            sum(revenue) over(order by revenue desc) cumulative_revenue,
            sum(revenue) over() total_revenue
        from category_revenue
    )
    select
        'Product Categories' as segment,
        count(*) as total_entities,
        sum(case when cumulative_revenue <= total_revenue*0.80 then 1 else 0 end) as entities_for_80_percent
    from pareto
)

select
    segment,
    total_entities,
    entities_for_80_percent,
    round(entities_for_80_percent*100.0/total_entities,2) as percentage_of_entities
from category_summary;
/*
=================================================
observation
=================================================

1. pareto analysis evaluates whether a small number
of entities generate a disproportionately large
share of total revenue.

2. cumulative revenue percentages identify the
point at which approximately 80% of revenue is
reached, highlighting the marketplace's key
revenue drivers.

3. understanding which customers, sellers,
product categories, or states contribute the
majority of revenue enables more effective
marketing, inventory planning, and resource
allocation.

4. if revenue is highly concentrated among a small
number of entities, the business may face greater
risk from losing those key contributors and should
consider strategies to diversify revenue sources.

=================================================
*/


--------


/*
=================================================
9. seasonality analysis
purpose:
identify seasonal purchasing patterns by analyzing
sales performance across months, quarters,
weekdays, and hours to support inventory planning,
marketing campaigns, staffing, and demand
forecasting.
=================================================
*/

/*
=================================================
9.1 monthly revenue index
purpose:
compare monthly revenue against the average monthly
revenue to identify seasonal peaks and slow periods.
=================================================
*/
with monthly_revenue as (

    select
        date_format(o.order_purchase_timestamp,'%Y-%m') as month,
        sum(oi.price) as revenue
    from olist_orders_dataset o
    join olist_order_items_dataset oi
        on o.order_id = oi.order_id
    where o.order_status = 'delivered'
    group by month

)

select

    month,

    round(revenue,2) as revenue,

    round(avg(revenue) over(),2) as average_monthly_revenue,

    round(
        revenue * 100 /
        avg(revenue) over(),
        2
    ) as revenue_index

from monthly_revenue

order by month;

/*
=================================================
9.2 monthly order index
=================================================
*/

with monthly_orders as (

    select

        date_format(order_purchase_timestamp,'%Y-%m') as month,

        count(distinct order_id) as orders

    from olist_orders_dataset

    where order_status='delivered'

    group by month

)

select

    month,

    orders,

    round(avg(orders) over(),2) as average_orders,

    round(
        orders*100/
        avg(orders) over(),
        2
    ) as order_index

from monthly_orders

order by month;
/*
=================================================
9.3 quarterly performance
=================================================
*/

select

    concat(
        year(o.order_purchase_timestamp),
        '-Q',
        quarter(o.order_purchase_timestamp)
    ) as quarter,

    count(distinct o.order_id) as total_orders,

    round(sum(oi.price),2) as revenue,

    round(
        sum(oi.price)/
        count(distinct o.order_id),
        2
    ) as average_order_value

from olist_orders_dataset o

join olist_order_items_dataset oi

on o.order_id=oi.order_id

where o.order_status='delivered'

group by

quarter

order by

quarter;

/*
=================================================
9.4 weekday performance
=================================================
*/

select

    dayname(o.order_purchase_timestamp) as weekday,

    count(distinct o.order_id) as total_orders,

    round(sum(oi.price),2) as revenue,

    round(
        sum(oi.price)/
        count(distinct o.order_id),
        2
    ) as average_order_value

from olist_orders_dataset o

join olist_order_items_dataset oi

on o.order_id=oi.order_id

where o.order_status='delivered'

group by weekday

order by field(

weekday,

'Monday',

'Tuesday',

'Wednesday',

'Thursday',

'Friday',

'Saturday',

'Sunday'

);

/*
=================================================
9.5 hourly shopping pattern
=================================================
*/

select

    hour(order_purchase_timestamp) as purchase_hour,

    count(distinct order_id) as total_orders

from olist_orders_dataset

where order_status='delivered'

group by purchase_hour

order by purchase_hour;

/*
=================================================
9.6 average order value by month
=================================================
*/

select

    date_format(o.order_purchase_timestamp,'%Y-%m') as month,

    round(

        sum(oi.price)

        /

        count(distinct o.order_id)

    ,2) as average_order_value

from olist_orders_dataset o

join olist_order_items_dataset oi

on o.order_id=oi.order_id

where o.order_status='delivered'

group by month

order by month;

/*
=================================================
9.7 best and worst performing months
=================================================
*/

with monthly_sales as (

select

    date_format(o.order_purchase_timestamp,'%Y-%m') as month,

    count(distinct o.order_id) as orders,

    sum(oi.price) as revenue

from olist_orders_dataset o

join olist_order_items_dataset oi

on o.order_id=oi.order_id

where o.order_status='delivered'

group by month

)

select

    month,

    orders,

    round(revenue,2) as revenue,

    rank() over(order by revenue desc) as revenue_rank

from monthly_sales

order by revenue_rank;

/*
=================================================
9.8 executive summary
=================================================
*/

with monthly_sales as (

select

    date_format(o.order_purchase_timestamp,'%Y-%m') as month,

    count(distinct o.order_id) orders,

    sum(oi.price) revenue

from olist_orders_dataset o

join olist_order_items_dataset oi

on o.order_id=oi.order_id

where o.order_status='delivered'

group by month

)

select

    round(avg(revenue),2) as average_monthly_revenue,

    round(max(revenue),2) as highest_monthly_revenue,

    round(min(revenue),2) as lowest_monthly_revenue,

    round(avg(orders),2) as average_monthly_orders,

    max(orders) as highest_monthly_orders,

    min(orders) as lowest_monthly_orders

from monthly_sales;

/*
=================================================
observation
=================================================

1. seasonality analysis identifies recurring patterns
   in customer purchasing behavior across months,
   quarters, weekdays, and hours.

2. the monthly revenue and order indices compare
   each month's performance against the overall
   average, making seasonal peaks and slow periods
   easy to identify.

3. quarterly performance highlights broader business
   cycles, while weekday and hourly analyses reveal
   customer shopping habits that support staffing,
   inventory planning, and marketing campaigns.

4. ranking the best and worst performing months
   helps evaluate the impact of seasonal demand,
   promotions, and external events.

5. these insights support demand forecasting and
   enable data-driven operational and strategic
   planning.
=================================================
*/





-----------------------------------------------------





/*
=================================================
Project: Brazilian E-Commerce (Olist) Analysis
File: 04_customer_analysis
=================================================
purpose:
analyze the customer base by measuring customer
growth, geographic distribution, purchasing
behavior, and customer value to support retention
and marketing strategies.
Dataset:
    Olist Brazilian E-Commerce Public Dataset
=================================================
*/

/*
=================================================
1.1 total customers
=================================================
*/

select

    count(distinct customer_unique_id) as total_customers

from olist_customers_dataset;

/*
=================================================
1.2 new vs returning customers
=================================================
*/

with customer_orders as (

    select

        c.customer_unique_id,

        count(distinct o.order_id) as total_orders

    from olist_customers_dataset c

    join olist_orders_dataset o

        on c.customer_id = o.customer_id

    where o.order_status = 'delivered'

    group by c.customer_unique_id

)

select

    case

        when total_orders = 1 then 'New Customer'

        else 'Returning Customer'

    end as customer_type,

    count(*) as total_customers

from customer_orders

group by customer_type;

/*
=================================================
1.3 active vs inactive customers
=================================================
*/

with customer_last_purchase as (

select

    c.customer_unique_id,

    max(o.order_purchase_timestamp) as last_purchase

from olist_customers_dataset c

join olist_orders_dataset o

on c.customer_id=o.customer_id

where o.order_status='delivered'

group by c.customer_unique_id

),

reference_date as (

select

    max(order_purchase_timestamp) as reference_date

from olist_orders_dataset

)

select

case

when datediff(r.reference_date,last_purchase)<=90

then 'Active'

else 'Inactive'

end as customer_status,

count(*) as total_customers

from customer_last_purchase cl

cross join reference_date r

group by customer_status;

/*
=================================================
1.4 customers by state
=================================================
*/

select

customer_state,

count(distinct customer_unique_id) as total_customers

from olist_customers_dataset

group by customer_state

order by total_customers desc;

/*
=================================================
1.5 customers by city
=================================================
*/

select

customer_city,

count(distinct customer_unique_id) as total_customers

from olist_customers_dataset

group by customer_city

order by total_customers desc;

/*
=================================================
1.6 average orders per customer
=================================================
*/

select

round(

count(distinct o.order_id)

/

count(distinct c.customer_unique_id)

,2) as average_orders_per_customer

from olist_orders_dataset o

join olist_customers_dataset c

on o.customer_id=c.customer_id

where o.order_status='delivered';

/*
=================================================
1.7 customer lifetime value
=================================================
*/

select

c.customer_unique_id,

count(distinct o.order_id) as total_orders,

round(sum(oi.price),2) as lifetime_revenue,

round(

sum(oi.price)

/

count(distinct o.order_id)

,2) as average_order_value

from olist_customers_dataset c

join olist_orders_dataset o

on c.customer_id=o.customer_id

join olist_order_items_dataset oi

on o.order_id=oi.order_id

where o.order_status='delivered'

group by c.customer_unique_id

order by lifetime_revenue desc;

/*
=================================================
1.8 first vs last purchase date
=================================================
*/

select

c.customer_unique_id,

min(o.order_purchase_timestamp) as first_purchase,

max(o.order_purchase_timestamp) as last_purchase,

count(distinct o.order_id) as total_orders

from olist_customers_dataset c

join olist_orders_dataset o

on c.customer_id=o.customer_id

where o.order_status='delivered'

group by c.customer_unique_id;

/*
=================================================
1.9 executive summary
=================================================
*/

select

count(distinct c.customer_unique_id) as total_customers,

count(distinct o.order_id) as total_orders,

round(

count(distinct o.order_id)

/

count(distinct c.customer_unique_id)

,2) as average_orders_per_customer,

round(

sum(oi.price)

/

count(distinct c.customer_unique_id)

,2) as average_customer_value

from olist_customers_dataset c

join olist_orders_dataset o

on c.customer_id=o.customer_id

join olist_order_items_dataset oi

on o.order_id=oi.order_id

where o.order_status='delivered';
/*
=================================================
observation
=================================================

1. customer analysis provides an overview of the
marketplace's customer base, including customer
growth, geographic distribution, purchasing
behavior, and lifetime value.

2. distinguishing between new and returning
customers helps evaluate customer retention and
repeat purchasing behavior.

3. identifying active and inactive customers
supports targeted retention campaigns and customer
re-engagement strategies.

4. customer lifetime value highlights the most
valuable customers and supports segmentation for
loyalty programs and personalized marketing.

5. first and last purchase dates reveal customer
relationships over time and help measure customer
longevity and recency.

=================================================
*/


--------


/*
=================================================
2. customer acquisition
purpose:
analyze how the customer base grows over time by
tracking first-time purchases, monthly customer
acquisition, regional acquisition patterns, and
growth trends.
=================================================
*/

/*
=================================================
2.1 first purchase date for each customer
=================================================
*/

select

    c.customer_unique_id,

    min(o.order_purchase_timestamp) as first_purchase_date

from olist_customers_dataset c

join olist_orders_dataset o
    on c.customer_id = o.customer_id

where o.order_status = 'delivered'

group by c.customer_unique_id

order by first_purchase_date;

/*
=================================================
2.2 new customers by month
=================================================
*/

with first_purchase as (

    select

        c.customer_unique_id,

        min(o.order_purchase_timestamp) as first_purchase

    from olist_customers_dataset c

    join olist_orders_dataset o
        on c.customer_id = o.customer_id

    where o.order_status = 'delivered'

    group by c.customer_unique_id

)

select

    date_format(first_purchase,'%Y-%m') as month,

    count(*) as new_customers

from first_purchase

group by month

order by month;

/*
=================================================
2.3 month-over-month customer growth
=================================================
*/

with monthly_customers as (

    select

        date_format(min(o.order_purchase_timestamp),'%Y-%m') as month,

        count(*) as new_customers

    from olist_customers_dataset c

    join olist_orders_dataset o
        on c.customer_id = o.customer_id

    where o.order_status = 'delivered'

    group by c.customer_unique_id

)

select

    month,

    new_customers,

    lag(new_customers) over(order by month) as previous_month,

    round(

        (
            new_customers -
            lag(new_customers) over(order by month)
        )

        *100.0

        /

        lag(new_customers) over(order by month)

    ,2) as growth_percentage

from monthly_customers

order by month;

/*
=================================================
2.4 new customers by state
=================================================
*/

with first_purchase as (

select

    c.customer_unique_id,

    c.customer_state,

    min(o.order_purchase_timestamp) first_purchase

from olist_customers_dataset c

join olist_orders_dataset o

on c.customer_id=o.customer_id

where o.order_status='delivered'

group by

c.customer_unique_id,

c.customer_state

)

select

customer_state,

count(*) as new_customers

from first_purchase

group by customer_state

order by new_customers desc;

/*
=================================================
2.5 new customer percentage
=================================================
*/

with customer_orders as (

select

    c.customer_unique_id,

    count(distinct o.order_id) total_orders

from olist_customers_dataset c

join olist_orders_dataset o

on c.customer_id=o.customer_id

where o.order_status='delivered'

group by c.customer_unique_id

)

select

round(

sum(

case

when total_orders=1

then 1

else 0

end

)

*100.0

/

count(*)

,2) as new_customer_percentage

from customer_orders;

/*
=================================================
2.6 top 10 customer acquisition months
=================================================
*/

with first_purchase as (

select

c.customer_unique_id,

min(o.order_purchase_timestamp) first_purchase

from olist_customers_dataset c

join olist_orders_dataset o

on c.customer_id=o.customer_id

where o.order_status='delivered'

group by c.customer_unique_id

)

select

date_format(first_purchase,'%Y-%m') as month,

count(*) as new_customers

from first_purchase

group by month

order by new_customers desc

limit 10;

/*
=================================================
2.7 executive summary
=================================================
*/

with first_purchase as (

select

c.customer_unique_id,

min(o.order_purchase_timestamp) first_purchase

from olist_customers_dataset c

join olist_orders_dataset o

on c.customer_id=o.customer_id

where o.order_status='delivered'

group by c.customer_unique_id

)

select

count(*) as total_customers,

min(first_purchase) as first_customer,

max(first_purchase) as latest_customer,

count(distinct date_format(first_purchase,'%Y-%m')) as acquisition_months

from first_purchase;
/*
=================================================
observation
=================================================

1. customer acquisition analysis measures how the
customer base grows over time by tracking each
customer's first purchase.

2. monthly acquisition trends reveal whether
marketing and growth initiatives are attracting
more new customers over time.

3. month-over-month growth highlights periods of
accelerated or declining customer acquisition and
supports evaluation of promotional campaigns.

4. analyzing new customers by state identifies the
regions contributing most to customer growth and
helps prioritize geographic expansion.

5. the percentage of new customers provides insight
into the balance between acquiring new customers
and retaining existing ones.

=================================================
*/


--------


/*
=================================================
3. customer retention
purpose:
analyze customer loyalty and repeat purchasing
behavior by measuring repeat purchases, purchase
frequency, and the time between purchases.
=================================================
*/

/*
=================================================
3.1 repeat customers
=================================================
*/

select

    count(*) as repeat_customers

from (

    select

        c.customer_unique_id

    from olist_customers_dataset c

    join olist_orders_dataset o
        on c.customer_id = o.customer_id

    where o.order_status = 'delivered'

    group by c.customer_unique_id

    having count(distinct o.order_id) > 1

) rc;

/*
=================================================
3.2 repeat purchase rate
=================================================
*/

with customer_orders as (

select

    c.customer_unique_id,

    count(distinct o.order_id) as total_orders

from olist_customers_dataset c

join olist_orders_dataset o

on c.customer_id=o.customer_id

where o.order_status='delivered'

group by c.customer_unique_id

)

select

round(

sum(

case

when total_orders>1

then 1

else 0

end

)

*100.0

/

count(*)

,2) as repeat_purchase_rate

from customer_orders;

/*
=================================================
3.3 orders per repeat customer
=================================================
*/

with repeat_customers as (

select

    c.customer_unique_id,

    count(distinct o.order_id) as total_orders

from olist_customers_dataset c

join olist_orders_dataset o

on c.customer_id=o.customer_id

where o.order_status='delivered'

group by c.customer_unique_id

having count(distinct o.order_id)>1

)

select

round(avg(total_orders),2) as average_orders_per_repeat_customer

from repeat_customers;

/*
=================================================
3.4 days until second purchase
=================================================
*/

with ranked_orders as (

select

    c.customer_unique_id,

    o.order_purchase_timestamp,

    row_number() over(

        partition by c.customer_unique_id

        order by o.order_purchase_timestamp

    ) as purchase_number

from olist_customers_dataset c

join olist_orders_dataset o

on c.customer_id=o.customer_id

where o.order_status='delivered'

),

first_second as (

select

    customer_unique_id,

    max(case when purchase_number=1 then order_purchase_timestamp end) as first_purchase,

    max(case when purchase_number=2 then order_purchase_timestamp end) as second_purchase

from ranked_orders

group by customer_unique_id

)

select

round(

avg(

datediff(second_purchase,first_purchase)

)

,0) as average_days_until_second_purchase

from first_second

where second_purchase is not null;

/*
=================================================
3.5 purchase frequency distribution
=================================================
*/

with customer_orders as (

select

    c.customer_unique_id,

    count(distinct o.order_id) as total_orders

from olist_customers_dataset c

join olist_orders_dataset o

on c.customer_id=o.customer_id

where o.order_status='delivered'

group by c.customer_unique_id

)

select

total_orders,

count(*) as customers

from customer_orders

group by total_orders

order by total_orders;

/*
=================================================
3.6 most loyal customers
=================================================
*/

select

c.customer_unique_id,

count(distinct o.order_id) as total_orders,

round(sum(oi.price),2) as lifetime_revenue,

min(o.order_purchase_timestamp) as first_purchase,

max(o.order_purchase_timestamp) as last_purchase

from olist_customers_dataset c

join olist_orders_dataset o

on c.customer_id=o.customer_id

join olist_order_items_dataset oi

on o.order_id=oi.order_id

where o.order_status='delivered'

group by c.customer_unique_id

order by total_orders desc,

lifetime_revenue desc

limit 20;

/*
=================================================
3.7 executive summary
=================================================
*/

with customer_orders as (

select

    c.customer_unique_id,

    count(distinct o.order_id) total_orders

from olist_customers_dataset c

join olist_orders_dataset o

on c.customer_id=o.customer_id

where o.order_status='delivered'

group by c.customer_unique_id

)

select

count(*) as total_customers,

sum(case when total_orders>1 then 1 else 0 end) as repeat_customers,

round(avg(total_orders),2) as average_orders_per_customer,

max(total_orders) as maximum_orders_by_customer

from customer_orders;
/*
=================================================
observation
=================================================

1. customer retention analysis measures how
successfully the business encourages customers to
make repeat purchases.

2. the repeat purchase rate indicates the
proportion of customers who return after their
first order, providing a key measure of customer
loyalty.

3. the average time until a second purchase helps
evaluate how quickly customers return and supports
the design of targeted retention campaigns.

4. purchase frequency distribution distinguishes
one-time buyers from highly engaged customers,
revealing patterns in customer behavior.

5. identifying the most loyal customers enables
personalized marketing, loyalty rewards, and
customer relationship management strategies.

=================================================
*/



------


/*
=================================================
4. customer lifetime value (ltv)
purpose:
measure the revenue generated by customers over
their lifetime, identify high-value customers,
analyze customer lifespan, and evaluate the
distribution of customer value.
=================================================
*/

/*
=================================================
4.1 customer lifetime revenue
=================================================
*/

select

    c.customer_unique_id,

    count(distinct o.order_id) as total_orders,

    round(sum(oi.price),2) as lifetime_revenue

from olist_customers_dataset c

join olist_orders_dataset o
    on c.customer_id = o.customer_id

join olist_order_items_dataset oi
    on o.order_id = oi.order_id

where o.order_status='delivered'

group by c.customer_unique_id

order by lifetime_revenue desc;

/*
=================================================
4.2 top 20 customers by lifetime value
=================================================
*/

select

    c.customer_unique_id,

    count(distinct o.order_id) as total_orders,

    round(sum(oi.price),2) as lifetime_revenue

from olist_customers_dataset c

join olist_orders_dataset o
    on c.customer_id=o.customer_id

join olist_order_items_dataset oi
    on o.order_id=oi.order_id

where o.order_status='delivered'

group by c.customer_unique_id

order by lifetime_revenue desc

limit 20;

/*
=================================================
4.3 average customer lifetime value
=================================================
*/

select

    round(

        sum(oi.price)

        /

        count(distinct c.customer_unique_id)

    ,2) as average_customer_ltv

from olist_customers_dataset c

join olist_orders_dataset o

on c.customer_id=o.customer_id

join olist_order_items_dataset oi

on o.order_id=oi.order_id

where o.order_status='delivered';

/*
=================================================
4.4 customer lifetime (days)
=================================================
*/

select

    c.customer_unique_id,

    min(o.order_purchase_timestamp) as first_purchase,

    max(o.order_purchase_timestamp) as last_purchase,

    datediff(

        max(o.order_purchase_timestamp),

        min(o.order_purchase_timestamp)

    ) as lifetime_days

from olist_customers_dataset c

join olist_orders_dataset o

on c.customer_id=o.customer_id

where o.order_status='delivered'

group by c.customer_unique_id

order by lifetime_days desc;

/*
=================================================
4.5 revenue per customer by state
=================================================
*/

select

    c.customer_state,

    round(

        sum(oi.price)

        /

        count(distinct c.customer_unique_id)

    ,2) as revenue_per_customer

from olist_customers_dataset c

join olist_orders_dataset o

on c.customer_id=o.customer_id

join olist_order_items_dataset oi

on o.order_id=oi.order_id

where o.order_status='delivered'

group by c.customer_state

order by revenue_per_customer desc;

/*
=================================================
4.6 customer value distribution
=================================================
*/

with customer_value as (

select

    c.customer_unique_id,

    sum(oi.price) as lifetime_revenue

from olist_customers_dataset c

join olist_orders_dataset o

on c.customer_id=o.customer_id

join olist_order_items_dataset oi

on o.order_id=oi.order_id

where o.order_status='delivered'

group by c.customer_unique_id

)

select

case

when lifetime_revenue <100 then 'Below 100'

when lifetime_revenue <250 then '100 - 249'

when lifetime_revenue <500 then '250 - 499'

when lifetime_revenue <1000 then '500 - 999'

else '1000+'

end as value_segment,

count(*) as customers,

round(avg(lifetime_revenue),2) as average_revenue

from customer_value

group by value_segment

order by min(lifetime_revenue);

/*
=================================================
4.7 executive summary
=================================================
*/

with customer_ltv as (

select

    c.customer_unique_id,

    sum(oi.price) as lifetime_revenue,

    count(distinct o.order_id) as total_orders,

    datediff(

        max(o.order_purchase_timestamp),

        min(o.order_purchase_timestamp)

    ) as lifetime_days

from olist_customers_dataset c

join olist_orders_dataset o

on c.customer_id=o.customer_id

join olist_order_items_dataset oi

on o.order_id=oi.order_id

where o.order_status='delivered'

group by c.customer_unique_id

)

select

    count(*) as total_customers,

    round(avg(lifetime_revenue),2) as average_ltv,

    round(max(lifetime_revenue),2) as highest_ltv,

    round(avg(total_orders),2) as average_orders,

    round(avg(lifetime_days),0) as average_customer_lifetime_days

from customer_ltv;
/*
=================================================
observation
=================================================

1. customer lifetime value analysis measures the
total revenue generated by each customer across
their relationship with the business.

2. identifying high-value customers supports
customer retention strategies, loyalty programs,
and personalized marketing campaigns.

3. customer lifetime in days provides insight into
how long customers remain active and helps evaluate
long-term engagement.

4. revenue per customer by state highlights regional
differences in customer value, supporting geographic
marketing and expansion decisions.

5. customer value distribution reveals whether
revenue is concentrated among a small number of
high-value customers or spread more evenly across
the customer base.

=================================================
*/


--------


/*
=================================================
5. rfm analysis
purpose:
segment customers based on recency, frequency, and
monetary value to identify loyal customers,
high-value customers, at-risk customers, and
customers requiring marketing intervention.
=================================================
*/

/*
=================================================
5.1 Build RFM Metrics
=================================================
*/

with reference_date as (

    select
        max(order_purchase_timestamp) as reference_date
    from olist_orders_dataset
    where order_status = 'delivered'

),

rfm_metrics as (

    select

        c.customer_unique_id,

        datediff(
            r.reference_date,
            max(o.order_purchase_timestamp)
        ) as recency,

        count(distinct o.order_id) as frequency,

        round(sum(oi.price),2) as monetary

    from olist_customers_dataset c

    join olist_orders_dataset o
        on c.customer_id = o.customer_id

    join olist_order_items_dataset oi
        on o.order_id = oi.order_id

    cross join reference_date r

    where o.order_status='delivered'

    group by
        c.customer_unique_id,
        r.reference_date

)

select *

from rfm_metrics

order by monetary desc;

/*
=================================================
5.2 Assign R Score
=================================================
*/

with reference_date as (

    select
        max(order_purchase_timestamp) as reference_date
    from olist_orders_dataset
    where order_status='delivered'

),

rfm_metrics as (

    select

        c.customer_unique_id,

        datediff(
            r.reference_date,
            max(o.order_purchase_timestamp)
        ) as recency,

        count(distinct o.order_id) as frequency,

        round(sum(oi.price),2) as monetary

    from olist_customers_dataset c

    join olist_orders_dataset o
        on c.customer_id=o.customer_id

    join olist_order_items_dataset oi
        on o.order_id=oi.order_id

    cross join reference_date r

    where o.order_status='delivered'

    group by
        c.customer_unique_id,
        r.reference_date

)

select

    customer_unique_id,

    recency,

    frequency,

    monetary,

    6 - ntile(5) over(
        order by recency
    ) as r_score

from rfm_metrics

order by r_score desc,recency;
         

/*
=================================================
5.3 Assign Frequency Score
=================================================
*/

with reference_date as (

    select
        max(order_purchase_timestamp) as reference_date
    from olist_orders_dataset
    where order_status='delivered'

),

rfm_metrics as (

    select

        c.customer_unique_id,

        datediff(
            r.reference_date,
            max(o.order_purchase_timestamp)
        ) as recency,

        count(distinct o.order_id) as frequency,

        round(sum(oi.price),2) as monetary

    from olist_customers_dataset c

    join olist_orders_dataset o
        on c.customer_id = o.customer_id

    join olist_order_items_dataset oi
        on o.order_id = oi.order_id

    cross join reference_date r

    where o.order_status='delivered'

    group by
        c.customer_unique_id,
        r.reference_date

)

select

    customer_unique_id,

    recency,

    frequency,

    monetary,

    ntile(5) over(
        order by frequency
    ) as f_score

from rfm_metrics

order by
    f_score desc,
    frequency desc;
    
/*
=================================================
5.4 Assign Monetary Score
=================================================
*/

with reference_date as (

    select
        max(order_purchase_timestamp) as reference_date
    from olist_orders_dataset
    where order_status='delivered'

),

rfm_metrics as (

    select

        c.customer_unique_id,

        datediff(
            r.reference_date,
            max(o.order_purchase_timestamp)
        ) as recency,

        count(distinct o.order_id) as frequency,

        round(sum(oi.price),2) as monetary

    from olist_customers_dataset c

    join olist_orders_dataset o
        on c.customer_id=o.customer_id

    join olist_order_items_dataset oi
        on o.order_id=oi.order_id

    cross join reference_date r

    where o.order_status='delivered'

    group by
        c.customer_unique_id,
        r.reference_date

)

select

    customer_unique_id,

    recency,

    frequency,

    monetary,

    ntile(5) over(
        order by monetary
    ) as m_score

from rfm_metrics

order by
    m_score desc,
    monetary desc;
    
/*
=================================================
5.5 Calculate Overall RFM Score
=================================================
*/

with reference_date as (

    select
        max(order_purchase_timestamp) as reference_date
    from olist_orders_dataset
    where order_status='delivered'

),

rfm_metrics as (

    select

        c.customer_unique_id,

        datediff(
            r.reference_date,
            max(o.order_purchase_timestamp)
        ) as recency,

        count(distinct o.order_id) as frequency,

        round(sum(oi.price),2) as monetary

    from olist_customers_dataset c

    join olist_orders_dataset o
        on c.customer_id=o.customer_id

    join olist_order_items_dataset oi
        on o.order_id=oi.order_id

    cross join reference_date r

    where o.order_status='delivered'

    group by
        c.customer_unique_id,
        r.reference_date

),

rfm_scores as (

    select

        customer_unique_id,

        recency,

        frequency,

        monetary,

        6 - ntile(5) over(order by recency) as r_score,

        ntile(5) over(order by frequency) as f_score,

        ntile(5) over(order by monetary) as m_score

    from rfm_metrics

)

select

    customer_unique_id,

    recency,

    frequency,

    monetary,

    r_score,

    f_score,

    m_score,

    concat(r_score,f_score,m_score) as rfm_code,

    (r_score+f_score+m_score) as total_rfm_score

from rfm_scores

order by

    total_rfm_score desc,

    monetary desc;
    
/*
=================================================
5.6 Customer Segments
=================================================
*/

with reference_date as (

    select
        max(order_purchase_timestamp) as reference_date
    from olist_orders_dataset
    where order_status='delivered'

),

rfm_metrics as (

    select

        c.customer_unique_id,

        datediff(
            r.reference_date,
            max(o.order_purchase_timestamp)
        ) as recency,

        count(distinct o.order_id) as frequency,

        round(sum(oi.price),2) as monetary

    from olist_customers_dataset c

    join olist_orders_dataset o
        on c.customer_id = o.customer_id

    join olist_order_items_dataset oi
        on o.order_id = oi.order_id

    cross join reference_date r

    where o.order_status='delivered'

    group by
        c.customer_unique_id,
        r.reference_date

),

rfm_scores as (

    select

        customer_unique_id,

        recency,

        frequency,

        monetary,

        6 - ntile(5) over(order by recency) as r_score,

        ntile(5) over(order by frequency) as f_score,

        ntile(5) over(order by monetary) as m_score

    from rfm_metrics

)

select

    customer_unique_id,

    recency,

    frequency,

    monetary,

    r_score,

    f_score,

    m_score,

    concat(r_score,f_score,m_score) as rfm_code,

    case

        when r_score>=4
         and f_score>=4
         and m_score>=4
            then 'Champions'

        when r_score>=4
         and f_score>=3
            then 'Loyal Customers'

        when r_score>=4
         and f_score<=2
            then 'Potential Loyalists'

        when r_score<=2
         and f_score>=4
            then 'At Risk'

        when r_score<=2
         and f_score<=2
            then 'Lost Customers'

        else 'Need Attention'

    end as customer_segment

from rfm_scores

order by
    customer_segment,
    monetary desc;
    
/*
=================================================
5.7 Segment Summary
=================================================
*/

with reference_date as (

    select max(order_purchase_timestamp) reference_date
    from olist_orders_dataset
    where order_status='delivered'

),

rfm_metrics as (

    select

        c.customer_unique_id,

        datediff(
            r.reference_date,
            max(o.order_purchase_timestamp)
        ) recency,

        count(distinct o.order_id) frequency,

        round(sum(oi.price),2) monetary

    from olist_customers_dataset c

    join olist_orders_dataset o
        on c.customer_id=o.customer_id

    join olist_order_items_dataset oi
        on o.order_id=oi.order_id

    cross join reference_date r

    where o.order_status='delivered'

    group by
        c.customer_unique_id,
        r.reference_date

),

rfm_scores as (

    select

        customer_unique_id,

        recency,

        frequency,

        monetary,

        6-ntile(5) over(order by recency) r_score,

        ntile(5) over(order by frequency) f_score,

        ntile(5) over(order by monetary) m_score

    from rfm_metrics

),

segments as (

select

*,

case

    when r_score>=4 and f_score>=4 and m_score>=4
        then 'Champions'

    when r_score>=4 and f_score>=3
        then 'Loyal Customers'

    when r_score>=4 and f_score<=2
        then 'Potential Loyalists'

    when r_score<=2 and f_score>=4
        then 'At Risk'

    when r_score<=2 and f_score<=2
        then 'Lost Customers'

    else 'Need Attention'

end as customer_segment

from rfm_scores

)

select

    customer_segment,

    count(*) as total_customers,

    round(avg(recency),0) as avg_recency,

    round(avg(frequency),2) as avg_frequency,

    round(avg(monetary),2) as avg_monetary

from segments

group by customer_segment

order by avg_monetary desc;

/*
=================================================
5.8 Executive Summary
=================================================
*/

with reference_date as (

    select max(order_purchase_timestamp) reference_date
    from olist_orders_dataset
    where order_status='delivered'

),

rfm_metrics as (

    select

        c.customer_unique_id,

        datediff(
            r.reference_date,
            max(o.order_purchase_timestamp)
        ) recency,

        count(distinct o.order_id) frequency,

        round(sum(oi.price),2) monetary

    from olist_customers_dataset c

    join olist_orders_dataset o
        on c.customer_id=o.customer_id

    join olist_order_items_dataset oi
        on o.order_id=oi.order_id

    cross join reference_date r

    where o.order_status='delivered'

    group by
        c.customer_unique_id,
        r.reference_date

),

rfm_scores as (

select

    customer_unique_id,

    recency,

    frequency,

    monetary,

    6-ntile(5) over(order by recency) r_score,

    ntile(5) over(order by frequency) f_score,

    ntile(5) over(order by monetary) m_score

from rfm_metrics

)

select

    count(*) as total_customers,

    round(avg(recency),0) as average_recency_days,

    round(avg(frequency),2) as average_orders_per_customer,

    round(avg(monetary),2) as average_customer_lifetime_value,

    max(monetary) as highest_customer_value,

    min(monetary) as lowest_customer_value

from rfm_scores;
/*
=================================================
observation
=================================================

1. rfm analysis segments customers based on
purchase recency, purchase frequency, and total
spending to identify different customer behaviors.

2. customers with high recency, frequency, and
monetary scores are the most valuable and should
be prioritized for retention and loyalty programs.

3. customers with low recency scores but strong
historical purchasing behavior may be at risk of
churning and should be targeted with win-back
campaigns.

4. customer segmentation enables personalized
marketing strategies instead of treating all
customers equally.

5. rfm analysis provides a data-driven framework
for improving customer retention, increasing
customer lifetime value, and optimizing marketing
investment.

=================================================
*/



------


/*
=================================================
6. customer cohort analysis.
purpose:
analyze customer retention by grouping customers
into cohorts based on the month of their first
purchase and tracking their purchasing behavior
over time.

=================================================
*/

/*
=================================================
6.1 Customer First Purchase (Cohort Assignment)
=================================================
*/
select

    c.customer_unique_id,

    min(o.order_purchase_timestamp) as first_purchase_date,

    date_format(
        min(o.order_purchase_timestamp),
        '%Y-%m'
    ) as cohort_month

from olist_customers_dataset c

join olist_orders_dataset o
    on c.customer_id = o.customer_id

where o.order_status = 'delivered'

group by c.customer_unique_id

order by cohort_month;

/*
=================================================
6.2 Cohort Size
=================================================
*/

with cohorts as (

    select

        c.customer_unique_id,

        date_format(
            min(o.order_purchase_timestamp),
            '%Y-%m'
        ) as cohort_month

    from olist_customers_dataset c

    join olist_orders_dataset o
        on c.customer_id = o.customer_id

    where o.order_status='delivered'

    group by c.customer_unique_id

)

select

    cohort_month,

    count(*) as total_customers

from cohorts

group by cohort_month

order by cohort_month;

/*
=================================================
6.3 Customer Activity by Cohort
=================================================
*/

with cohorts as (

    select

        c.customer_unique_id,

        min(o.order_purchase_timestamp) as first_purchase

    from olist_customers_dataset c

    join olist_orders_dataset o
        on c.customer_id=o.customer_id

    where o.order_status='delivered'

    group by c.customer_unique_id

)

select

    date_format(
        c.first_purchase,
        '%Y-%m'
    ) as cohort_month,

    date_format(
        o.order_purchase_timestamp,
        '%Y-%m'
    ) as purchase_month,

    count(distinct c.customer_unique_id) as active_customers

from cohorts c

join olist_customers_dataset cu
    on c.customer_unique_id=cu.customer_unique_id

join olist_orders_dataset o
    on cu.customer_id=o.customer_id

where o.order_status='delivered'

group by

    cohort_month,

    purchase_month

order by

    cohort_month,

    purchase_month;
    
/*
=================================================
6.4 Monthly Cohort Retention
=================================================
*/

with cohorts as (

    select

        c.customer_unique_id,

        min(o.order_purchase_timestamp) as first_purchase

    from olist_customers_dataset c

    join olist_orders_dataset o
        on c.customer_id=o.customer_id

    where o.order_status='delivered'

    group by c.customer_unique_id

)

select

    date_format(
        c.first_purchase,
        '%Y-%m'
    ) as cohort_month,

    timestampdiff(

        month,

        c.first_purchase,

        o.order_purchase_timestamp

    ) as month_number,

    count(distinct c.customer_unique_id) as retained_customers

from cohorts c

join olist_customers_dataset cu
    on c.customer_unique_id=cu.customer_unique_id

join olist_orders_dataset o
    on cu.customer_id=o.customer_id

where o.order_status='delivered'

group by

    cohort_month,

    month_number

order by

    cohort_month,

    month_number;
    
/*
=================================================
6.5 Cohort Retention Percentage
=================================================
*/

with cohorts as (

    select

        c.customer_unique_id,

        min(o.order_purchase_timestamp) as first_purchase

    from olist_customers_dataset c

    join olist_orders_dataset o
        on c.customer_id=o.customer_id

    where o.order_status='delivered'

    group by c.customer_unique_id

),

retention as (

    select

        date_format(
            c.first_purchase,
            '%Y-%m'
        ) as cohort_month,

        timestampdiff(

            month,

            c.first_purchase,

            o.order_purchase_timestamp

        ) as month_number,

        count(distinct c.customer_unique_id) as retained_customers

    from cohorts c

    join olist_customers_dataset cu
        on c.customer_unique_id=cu.customer_unique_id

    join olist_orders_dataset o
        on cu.customer_id=o.customer_id

    where o.order_status='delivered'

    group by

        cohort_month,

        month_number

),

cohort_size as (

    select

        cohort_month,

        retained_customers as total_customers

    from retention

    where month_number=0

)

select

    r.cohort_month,

    r.month_number,

    r.retained_customers,

    cs.total_customers,

    round(

        r.retained_customers*100.0

        / cs.total_customers,

        2

    ) as retention_percentage

from retention r

join cohort_size cs

on r.cohort_month=cs.cohort_month

order by

    r.cohort_month,

    r.month_number;
    

/*
=================================================
6.6 Best Performing Cohorts
=================================================
*/

with cohorts as (

    select

        c.customer_unique_id,

        min(o.order_purchase_timestamp) first_purchase

    from olist_customers_dataset c

    join olist_orders_dataset o

    on c.customer_id=o.customer_id

    where o.order_status='delivered'

    group by c.customer_unique_id

),

retention as (

    select

        date_format(
            c.first_purchase,
            '%Y-%m'
        ) cohort_month,

        timestampdiff(

            month,

            c.first_purchase,

            o.order_purchase_timestamp

        ) month_number,

        count(distinct c.customer_unique_id) retained_customers

    from cohorts c

    join olist_customers_dataset cu

    on c.customer_unique_id=cu.customer_unique_id

    join olist_orders_dataset o

    on cu.customer_id=o.customer_id

    where o.order_status='delivered'

    group by

        cohort_month,

        month_number

),

cohort_size as (

    select

        cohort_month,

        retained_customers total_customers

    from retention

    where month_number=0

)

select

    r.cohort_month,

    round(

        r.retained_customers*100.0

        / cs.total_customers,

        2

    ) as month1_retention

from retention r

join cohort_size cs

on r.cohort_month=cs.cohort_month

where r.month_number=1

order by month1_retention desc;

/*
=================================================
6.7 Executive Summary
=================================================
*/

with cohorts as (

    select

        c.customer_unique_id,

        date_format(

            min(o.order_purchase_timestamp),

            '%Y-%m'

        ) cohort_month

    from olist_customers_dataset c

    join olist_orders_dataset o

    on c.customer_id=o.customer_id

    where o.order_status='delivered'

    group by c.customer_unique_id

),

cohort_size as (

    select

        cohort_month,

        count(*) total_customers

    from cohorts

    group by cohort_month

)

select

    count(*) as total_cohorts,

    sum(total_customers) as total_customers,

    round(avg(total_customers),2) as average_cohort_size,

    max(total_customers) as largest_cohort,

    min(total_customers) as smallest_cohort

from cohort_size;
/*
=================================================
observations
=================================================

1. customer cohorts reveal how well the business
retains customers after their first purchase.

2. retention typically declines over time, with
the highest customer activity occurring in the
acquisition month and decreasing in subsequent
months.

3. cohorts with higher month-1 retention indicate
more successful customer acquisition and stronger
customer engagement.

4. comparing cohort performance helps identify
which acquisition periods resulted in the most
loyal customers.

5. low retention in the early months suggests an
opportunity to improve onboarding, marketing
campaigns, or loyalty programs.

6. cohort analysis provides a more accurate view
of customer behavior than simply tracking monthly
active customers because it separates customer
retention from new customer acquisition.

7. these insights support business decisions
related to customer retention strategies,
marketing effectiveness, and long-term revenue
growth.

=================================================
*/


--------


/*
=================================================
7. customer churn analysis.
purpose:
identify inactive customers, measure churn, and
understand customer attrition patterns to improve
retention strategies.
=================================================
*/

/*
=================================================
7.1 define active vs churned customers
=================================================
*/

with reference_date as (

    select
        max(order_purchase_timestamp) as reference_date
    from olist_orders_dataset
    where order_status='delivered'

),

customer_status as (

    select

        c.customer_unique_id,

        max(o.order_purchase_timestamp) as last_purchase,

        datediff(
            r.reference_date,
            max(o.order_purchase_timestamp)
        ) as days_since_last_purchase

    from olist_customers_dataset c

    join olist_orders_dataset o
        on c.customer_id=o.customer_id

    cross join reference_date r

    where o.order_status='delivered'

    group by
        c.customer_unique_id,
        r.reference_date

)

select

    customer_unique_id,

    last_purchase,

    days_since_last_purchase,

    case

        when days_since_last_purchase<=90
            then 'Active'

        else 'Churned'

    end as customer_status

from customer_status

order by days_since_last_purchase desc;

/*
=================================================
7.2 customer churn rate
=================================================
*/

with reference_date as (

    select max(order_purchase_timestamp) reference_date
    from olist_orders_dataset
    where order_status='delivered'

),

customer_status as (

    select

        c.customer_unique_id,

        datediff(
            r.reference_date,
            max(o.order_purchase_timestamp)
        ) days_since_last_purchase

    from olist_customers_dataset c

    join olist_orders_dataset o
        on c.customer_id=o.customer_id

    cross join reference_date r

    where o.order_status='delivered'

    group by
        c.customer_unique_id,
        r.reference_date

)

select

    count(*) total_customers,

    sum(case when days_since_last_purchase<=90 then 1 else 0 end) active_customers,

    sum(case when days_since_last_purchase>90 then 1 else 0 end) churned_customers,

    round(

        sum(case when days_since_last_purchase>90 then 1 else 0 end)

        *100.0

        /count(*),

        2

    ) churn_rate

from customer_status;

/*
=================================================
7.3 churn by state
=================================================
*/

with reference_date as (

    select max(order_purchase_timestamp) reference_date
    from olist_orders_dataset
    where order_status='delivered'

),

customer_status as (

    select

        c.customer_unique_id,

        c.customer_state,

        datediff(
            r.reference_date,
            max(o.order_purchase_timestamp)
        ) days_since_last_purchase

    from olist_customers_dataset c

    join olist_orders_dataset o
        on c.customer_id=o.customer_id

    cross join reference_date r

    where o.order_status='delivered'

    group by
        c.customer_unique_id,
        c.customer_state,
        r.reference_date

)

select

    customer_state,

    count(*) total_customers,

    sum(case when days_since_last_purchase>90 then 1 else 0 end) churned_customers,

    round(

        sum(case when days_since_last_purchase>90 then 1 else 0 end)

        *100.0

        /count(*),

        2

    ) churn_rate

from customer_status

group by customer_state

order by churn_rate desc;

/*
=================================================
7.4 churn by acquisition cohort
=================================================
*/

with reference_date as (

    select max(order_purchase_timestamp) reference_date
    from olist_orders_dataset
    where order_status='delivered'

),

customer_cohort as (

    select

        c.customer_unique_id,

        min(o.order_purchase_timestamp) first_purchase,

        max(o.order_purchase_timestamp) last_purchase,

        datediff(
            r.reference_date,
            max(o.order_purchase_timestamp)
        ) days_since_last_purchase

    from olist_customers_dataset c

    join olist_orders_dataset o
        on c.customer_id=o.customer_id

    cross join reference_date r

    where o.order_status='delivered'

    group by
        c.customer_unique_id,
        r.reference_date

)

select

    date_format(first_purchase,'%Y-%m') cohort_month,

    count(*) total_customers,

    sum(case when days_since_last_purchase>90 then 1 else 0 end) churned_customers,

    round(

        sum(case when days_since_last_purchase>90 then 1 else 0 end)

        *100.0

        /count(*),

        2

    ) churn_rate

from customer_cohort

group by cohort_month

order by cohort_month;

/*
=================================================
7.5 days since last purchase
=================================================
*/

with reference_date as (

    select MAX(order_purchase_timestamp) AS reference_date
    from olist_orders_dataset
    where order_status = 'delivered'

),

customer_last_purchase as (

    select
        c.customer_unique_id,
        MAX(o.order_purchase_timestamp) AS last_purchase
    from olist_customers_dataset c
    join olist_orders_dataset o
        on c.customer_id = o.customer_id
    where o.order_status = 'delivered'
    group by c.customer_unique_id

)

select

    DATEDIFF(
        r.reference_date,
        clp.last_purchase
    ) as days_since_last_purchase,

    COUNT(*) as customers

from customer_last_purchase clp
cross join reference_date r

group by days_since_last_purchase

order by days_since_last_purchase;

/*
=================================================
7.6 top 20 highest-value churned customers
=================================================
*/

with reference_date as (

    select max(order_purchase_timestamp) reference_date
    from olist_orders_dataset
    where order_status='delivered'

),

customer_value as (

    select

        c.customer_unique_id,

        max(o.order_purchase_timestamp) last_purchase,

        datediff(
            r.reference_date,
            max(o.order_purchase_timestamp)
        ) days_since_last_purchase,

        round(sum(oi.price),2) lifetime_revenue

    from olist_customers_dataset c

    join olist_orders_dataset o
        on c.customer_id=o.customer_id

    join olist_order_items_dataset oi
        on o.order_id=oi.order_id

    cross join reference_date r

    where o.order_status='delivered'

    group by
        c.customer_unique_id,
        r.reference_date

)

select *

from customer_value

where days_since_last_purchase>90

order by lifetime_revenue desc

limit 20;

/*
=================================================
7.7 executive summary
=================================================
*/

with reference_date as (

    select max(order_purchase_timestamp) reference_date
    from olist_orders_dataset
    where order_status='delivered'

),

customer_summary as (

    select

        c.customer_unique_id,

        datediff(
            r.reference_date,
            max(o.order_purchase_timestamp)
        ) days_since_last_purchase,

        round(sum(oi.price),2) lifetime_revenue

    from olist_customers_dataset c

    join olist_orders_dataset o
        on c.customer_id=o.customer_id

    join olist_order_items_dataset oi
        on o.order_id=oi.order_id

    cross join reference_date r

    where o.order_status='delivered'

    group by
        c.customer_unique_id,
        r.reference_date

)

select

    count(*) total_customers,

    sum(case when days_since_last_purchase<=90 then 1 else 0 end) active_customers,

    sum(case when days_since_last_purchase>90 then 1 else 0 end) churned_customers,

    round(

        sum(case when days_since_last_purchase>90 then 1 else 0 end)

        *100.0

        /count(*),

        2

    ) churn_rate,

    round(avg(days_since_last_purchase),0) average_days_since_last_purchase,

    max(lifetime_revenue) highest_customer_value,

    round(avg(lifetime_revenue),2) average_customer_value

from customer_summary;
/*
=================================================
observations
=================================================

1. customer churn is measured using the latest
purchase date in the dataset as the reference date.

2. customers with no purchases in the last 90 days
are classified as churned.

3. churn analysis helps identify customers who may
need targeted retention or win-back campaigns.

4. comparing churn across states and acquisition
cohorts highlights markets with stronger or weaker
customer loyalty.

5. identifying high-value churned customers enables
the business to prioritize retention efforts where
they can have the greatest financial impact.

=================================================
*/



--------


/*
=================================================
8. customer purchasing behavior
=================================================

purpose:
analyze how customers purchase over time,
their buying frequency, spending patterns,
and ordering behavior.
=================================================
*/



/*
=================================================
8.1 orders per customer
=================================================
*/

select

    c.customer_unique_id,

    count(distinct o.order_id) as total_orders

from olist_customers_dataset c

join olist_orders_dataset o
    on c.customer_id = o.customer_id

where o.order_status='delivered'

group by c.customer_unique_id

order by total_orders desc;

/*
=================================================
8.2 average days between orders
=================================================
*/

with customer_orders as (

    select

        c.customer_unique_id,

        o.order_purchase_timestamp,

        lag(o.order_purchase_timestamp)
            over(
                partition by c.customer_unique_id
                order by o.order_purchase_timestamp
            ) as previous_purchase

    from olist_customers_dataset c

    join olist_orders_dataset o
        on c.customer_id=o.customer_id

    where o.order_status='delivered'

)

select

    customer_unique_id,

    round(

        avg(

            datediff(
                order_purchase_timestamp,
                previous_purchase
            )

        ),

        1

    ) as average_days_between_orders

from customer_orders

where previous_purchase is not null

group by customer_unique_id

order by average_days_between_orders;

/*
=================================================
8.3 purchase frequency distribution
=================================================
*/

with customer_orders as (

    select

        c.customer_unique_id,

        count(distinct o.order_id) as total_orders

    from olist_customers_dataset c

    join olist_orders_dataset o

    on c.customer_id=o.customer_id

    where o.order_status='delivered'

    group by c.customer_unique_id

)

select

    total_orders,

    count(*) as customers

from customer_orders

group by total_orders

order by total_orders;

/*
=================================================
8.4 top 20 most frequent buyers
=================================================
*/

with customer_sales as (

    select

        c.customer_unique_id,

        count(distinct o.order_id) as total_orders,

        round(sum(oi.price),2) as lifetime_revenue

    from olist_customers_dataset c

    join olist_orders_dataset o

    on c.customer_id=o.customer_id

    join olist_order_items_dataset oi

    on o.order_id=oi.order_id

    where o.order_status='delivered'

    group by c.customer_unique_id

)

select *

from customer_sales

order by

    total_orders desc,

    lifetime_revenue desc

limit 20;

/*
=================================================
8.5 revenue by order frequency
=================================================
*/

with customer_sales as (

    select

        c.customer_unique_id,

        count(distinct o.order_id) as total_orders,

        round(sum(oi.price),2) as lifetime_revenue

    from olist_customers_dataset c

    join olist_orders_dataset o

    on c.customer_id=o.customer_id

    join olist_order_items_dataset oi

    on o.order_id=oi.order_id

    where o.order_status='delivered'

    group by c.customer_unique_id

)

select

    total_orders,

    count(*) as customers,

    round(avg(lifetime_revenue),2) as average_revenue,

    round(sum(lifetime_revenue),2) as total_revenue

from customer_sales

group by total_orders

order by total_orders;

/*
=================================================
8.6 executive summary
=================================================
*/

with customer_sales as (

    select

        c.customer_unique_id,

        count(distinct o.order_id) as total_orders,

        round(sum(oi.price),2) as lifetime_revenue

    from olist_customers_dataset c

    join olist_orders_dataset o

    on c.customer_id=o.customer_id

    join olist_order_items_dataset oi

    on o.order_id=oi.order_id

    where o.order_status='delivered'

    group by c.customer_unique_id

)

select

    count(*) as total_customers,

    round(avg(total_orders),2) as average_orders_per_customer,

    max(total_orders) as highest_order_count,

    round(avg(lifetime_revenue),2) as average_customer_revenue,

    max(lifetime_revenue) as highest_customer_revenue

from customer_sales;
/*
=================================================
observations
=================================================

1. most customers place only a small number of
orders, while a small group of loyal customers
purchase repeatedly.

2. customers with higher purchase frequency
typically generate significantly greater lifetime
revenue.

3. analyzing the time between purchases helps
identify normal buying cycles and supports
re-engagement campaigns.

4. purchase frequency distribution highlights the
balance between one-time and repeat customers.

5. understanding purchasing behavior enables
better customer segmentation, personalized
marketing, and loyalty program design.

=================================================
*/


--------


/*
=================================================
9. customer geographic analysis
=================================================

purpose:
analyze customer distribution and performance
across different geographic regions to identify
high-value markets and growth opportunities.
=================================================
*/

/*
=================================================
9.1 customers by state
=================================================
*/

select

    customer_state,

    count(distinct customer_unique_id) as total_customers

from olist_customers_dataset

group by customer_state

order by total_customers desc;

/*
=================================================
9.2 customers by city
=================================================
*/

select

    customer_city,

    count(distinct customer_unique_id) as total_customers

from olist_customers_dataset

group by customer_city

order by total_customers desc

limit 20;


/*
=================================================
9.3 revenue by state
=================================================
*/

select

    c.customer_state,

    round(sum(oi.price),2) as total_revenue,

    count(distinct o.order_id) as total_orders

from olist_customers_dataset c

join olist_orders_dataset o
    on c.customer_id=o.customer_id

join olist_order_items_dataset oi
    on o.order_id=oi.order_id

where o.order_status='delivered'

group by c.customer_state

order by total_revenue desc;

/*
=================================================
9.4 average customer value by state
=================================================
*/

with customer_value as (

    select

        c.customer_unique_id,

        c.customer_state,

        round(sum(oi.price),2) as lifetime_value

    from olist_customers_dataset c

    join olist_orders_dataset o
        on c.customer_id=o.customer_id

    join olist_order_items_dataset oi
        on o.order_id=oi.order_id

    where o.order_status='delivered'

    group by
        c.customer_unique_id,
        c.customer_state

)

select

    customer_state,

    count(*) as customers,

    round(avg(lifetime_value),2) as average_customer_value,

    round(sum(lifetime_value),2) as total_revenue

from customer_value

group by customer_state

order by average_customer_value desc;

/*
=================================================
9.5 repeat customer rate by state
=================================================
*/

with customer_orders as (

    select

        c.customer_unique_id,

        c.customer_state,

        count(distinct o.order_id) as total_orders

    from olist_customers_dataset c

    join olist_orders_dataset o
        on c.customer_id=o.customer_id

    where o.order_status='delivered'

    group by
        c.customer_unique_id,
        c.customer_state

)

select

    customer_state,

    count(*) as total_customers,

    sum(
        case
            when total_orders>1 then 1
            else 0
        end
    ) as repeat_customers,

    round(

        sum(
            case
                when total_orders>1 then 1
                else 0
            end
        )*100.0

        /count(*),

        2

    ) as repeat_customer_rate

from customer_orders

group by customer_state

order by repeat_customer_rate desc;

/*
=================================================
9.6 top 20 cities by revenue
=================================================
*/

select

    c.customer_city,

    c.customer_state,

    round(sum(oi.price),2) as total_revenue,

    count(distinct o.order_id) as total_orders,

    count(distinct c.customer_unique_id) as total_customers

from olist_customers_dataset c

join olist_orders_dataset o
    on c.customer_id=o.customer_id

join olist_order_items_dataset oi
    on o.order_id=oi.order_id

where o.order_status='delivered'

group by
    c.customer_city,
    c.customer_state

order by total_revenue desc

limit 20;

/*
=================================================
9.7 executive summary
=================================================
*/

with customer_value as (

    select

        c.customer_unique_id,

        c.customer_state,

        round(sum(oi.price),2) as lifetime_value

    from olist_customers_dataset c

    join olist_orders_dataset o
        on c.customer_id=o.customer_id

    join olist_order_items_dataset oi
        on o.order_id=oi.order_id

    where o.order_status='delivered'

    group by
        c.customer_unique_id,
        c.customer_state

)

select

    count(*) as total_customers,

    count(distinct customer_state) as total_states,

    round(avg(lifetime_value),2) as average_customer_value,

    max(lifetime_value) as highest_customer_value,

    min(lifetime_value) as lowest_customer_value,

    round(sum(lifetime_value),2) as total_revenue

from customer_value;

/*
=================================================
observations
=================================================

1. customer distribution varies significantly
across states, with a few regions accounting for
the majority of customers.

2. revenue concentration by state helps identify
the marketplace's strongest geographic markets.

3. average customer value differs across states,
indicating regional differences in purchasing
behavior and spending power.

4. repeat customer rate highlights regions with
strong customer loyalty and retention.

5. city-level analysis identifies high-performing
urban markets that may benefit from targeted
marketing and expansion efforts.

=================================================
*/


--------


/*
=================================================
10. overall customer summary
=================================================

purpose:
provide a high-level summary of customer
acquisition, retention, lifetime value, loyalty,
churn, and geographic performance to support
executive decision-making.
=================================================
*/

/*
=================================================
10.1 executive customer kpis
=================================================
*/

with customer_summary as (

    select

        c.customer_unique_id,

        c.customer_state,

        count(distinct o.order_id) as total_orders,

        round(sum(oi.price),2) as lifetime_value,

        max(o.order_purchase_timestamp) as last_purchase

    from olist_customers_dataset c

    join olist_orders_dataset o
        on c.customer_id = o.customer_id

    join olist_order_items_dataset oi
        on o.order_id = oi.order_id

    where o.order_status='delivered'

    group by
        c.customer_unique_id,
        c.customer_state

),

reference_date as (

    select
        max(order_purchase_timestamp) as reference_date
    from olist_orders_dataset
    where order_status='delivered'

)

select

    count(*) as total_customers,

    sum(case when total_orders>1 then 1 else 0 end) as repeat_customers,

    round(

        sum(case when total_orders>1 then 1 else 0 end)

        *100.0

        /count(*),

        2

    ) as repeat_purchase_rate,

    round(avg(lifetime_value),2) as average_customer_ltv,

    round(avg(total_orders),2) as average_orders_per_customer,

    round(

        avg(

            datediff(
                r.reference_date,
                last_purchase
            )

        ),

        0

    ) as average_days_since_last_purchase

from customer_summary

cross join reference_date r;

/*
=================================================
10.2 overall customer insights
=================================================
*/

select

    'Customer Base' as metric,
    count(distinct customer_unique_id) as value

from olist_customers_dataset

union all

select

    'States Served',

    count(distinct customer_state)

from olist_customers_dataset

union all

select

    'Cities Served',

    count(distinct customer_city)

from olist_customers_dataset

union all

select

    'Delivered Orders',

    count(*)

from olist_orders_dataset

where order_status='delivered';

/*
=================================================
overall observations
=================================================

1. customer acquisition has grown steadily over
the business period, creating a large and diverse
customer base.

2. repeat customers contribute significantly more
revenue than one-time buyers, highlighting the
importance of retention strategies.

3. customer lifetime value varies considerably,
indicating that a small proportion of customers
generate a large share of total revenue.

4. rfm segmentation identifies valuable customer
groups for loyalty programs and customers at risk
of churn for targeted re-engagement campaigns.

5. cohort analysis shows how customer retention
changes over time and measures the effectiveness
of customer acquisition efforts.

6. churn analysis helps quantify customer attrition
and identify opportunities to improve long-term
customer retention.

7. purchasing behavior analysis reveals differences
in buying frequency and spending habits, supporting
personalized marketing strategies.

8. geographic analysis highlights high-performing
states and cities, helping prioritize regional
marketing and expansion efforts.

9. together, these analyses provide a comprehensive
view of the customer lifecycle, enabling data-driven
decisions that improve customer satisfaction,
retention, and long-term business growth.

=================================================
*/






---------------------------------------------------------------------------










/*
=================================================
Project: Brazilian E-Commerce (Olist) Analysis
File: 05_product_analysis.sql
=================================================
purpose:
analyze product performance, category trends,
pricing, sales, and customer satisfaction to
identify top-performing products and support
inventory and marketing decisions.
Dataset:
    Olist Brazilian E-Commerce Public Dataset
=================================================
*/



/*
=================================================
1. product overview
=================================================
purpose:
understand the overall product catalog, category
distribution, and product availability across the
marketplace.
=================================================
*/

/*
=================================================
1.1 total products
=================================================
*/

select

    count(*) as total_products

from olist_products_dataset;

/*
=================================================
1.2 total product categories
=================================================
*/

select

    count(distinct product_category_name) as total_categories

from olist_products_dataset;

/*
=================================================
1.3 products per category
=================================================
*/

select

    coalesce(
        pct.product_category_name_english,
        'Unknown'
    ) as category,

    count(*) as total_products

from olist_products_dataset p

left join product_category_name_translation pct

on p.product_category_name=pct.product_category_name

group by category

order by total_products desc;

/*
=================================================
1.4 top 10 categories by number of products
=================================================
*/

select

    coalesce(
        pct.product_category_name_english,
        'Unknown'
    ) as category,

    count(*) as total_products

from olist_products_dataset p

left join product_category_name_translation pct

on p.product_category_name=pct.product_category_name

group by category

order by total_products desc

limit 10;

/*
=================================================
1.5 bottom 10 categories by number of products
=================================================
*/

select

    coalesce(
        pct.product_category_name_english,
        'Unknown'
    ) as category,

    count(*) as total_products

from olist_products_dataset p

left join product_category_name_translation pct

on p.product_category_name=pct.product_category_name

group by category

order by total_products

limit 10;

/*
=================================================
1.6 products without category
=================================================
*/

select

    count(*) as products_without_category

from olist_products_dataset

where product_category_name is null;

/*
=================================================
1.7 executive summary
=================================================
*/

select

    count(*) as total_products,

    count(distinct product_category_name) as total_categories,

    sum(

        case

            when product_category_name is null

            then 1

            else 0

        end

    ) as products_without_category

from olist_products_dataset;

/*
=================================================
observations
=================================================

1. the marketplace offers a diverse product catalog
across multiple product categories.

2. product distribution is uneven, with a few
categories containing a large share of all
products while others contain relatively few.

3. identifying the largest categories helps
prioritize inventory management, merchandising,
and marketing investments.

4. smaller categories may represent niche markets
or opportunities for product assortment expansion.

5. products without assigned categories should be
reviewed to improve data quality and ensure
accurate reporting.

=================================================
*/


--------


/*
=================================================
2. product revenue analysis
=================================================
purpose:
analyze revenue generated by individual products
to identify top-performing, low-performing, and
unsold products for inventory, marketing, and
pricing decisions.
=================================================
*/

/*
=================================================
2.1 revenue by product
=================================================
*/

select

    p.product_id,

    coalesce(
        pct.product_category_name_english,
        'Unknown'
    ) as category,

    round(sum(oi.price),2) as total_revenue

from olist_order_items_dataset oi

join olist_products_dataset p
    on oi.product_id = p.product_id

left join product_category_name_translation pct
    on p.product_category_name = pct.product_category_name

group by
    p.product_id,
    category

order by total_revenue desc;

/*
=================================================
2.2 top 20 products by revenue
=================================================
*/

select

    p.product_id,

    coalesce(
        pct.product_category_name_english,
        'Unknown'
    ) as category,

    round(sum(oi.price),2) as total_revenue

from olist_order_items_dataset oi

join olist_products_dataset p
    on oi.product_id = p.product_id

left join product_category_name_translation pct
    on p.product_category_name = pct.product_category_name

group by
    p.product_id,
    category

order by total_revenue desc

limit 20;

/*
=================================================
2.3 bottom 20 products by revenue
=================================================
*/

select

    p.product_id,

    coalesce(
        pct.product_category_name_english,
        'Unknown'
    ) as category,

    round(sum(oi.price),2) as total_revenue

from olist_order_items_dataset oi

join olist_products_dataset p
    on oi.product_id = p.product_id

left join product_category_name_translation pct
    on p.product_category_name = pct.product_category_name

group by
    p.product_id,
    category

order by total_revenue

limit 20;

/*
=================================================
2.4 average revenue per product
=================================================
*/

with product_revenue as (

    select

        product_id,

        sum(price) as total_revenue

    from olist_order_items_dataset

    group by product_id

)

select

    round(avg(total_revenue),2) as average_revenue_per_product,

    round(min(total_revenue),2) as minimum_revenue,

    round(max(total_revenue),2) as maximum_revenue

from product_revenue;

/*
=================================================
2.5 revenue contribution by product
=================================================
*/

with product_revenue as (

    select

        product_id,

        sum(price) as total_revenue

    from olist_order_items_dataset

    group by product_id

)

select

    product_id,

    round(total_revenue,2) as total_revenue,

    round(

        total_revenue
        *100.0
        /sum(total_revenue) over(),

        2

    ) as revenue_percentage

from product_revenue

order by total_revenue desc;

/*
=================================================
2.6 products with no sales
=================================================
*/

select

    p.product_id,

    coalesce(
        pct.product_category_name_english,
        'Unknown'
    ) as category

from olist_products_dataset p

left join product_category_name_translation pct
    on p.product_category_name = pct.product_category_name

left join olist_order_items_dataset oi
    on p.product_id = oi.product_id

where oi.product_id is null

order by category;

/*
=================================================
2.7 executive summary
=================================================
*/

with product_revenue as (

    select

        product_id,

        sum(price) as total_revenue

    from olist_order_items_dataset

    group by product_id

)

select

    count(*) as products_with_sales,

    round(sum(total_revenue),2) as total_revenue,

    round(avg(total_revenue),2) as average_revenue_per_product,

    round(max(total_revenue),2) as highest_product_revenue,

    round(min(total_revenue),2) as lowest_product_revenue

from product_revenue;
/*
=================================================
observations
=================================================

1. product revenue is highly concentrated, with a
small number of products generating a significant
share of total sales.

2. top-performing products should be prioritized
for inventory planning, promotions, and marketing
campaigns.

3. products generating little revenue may require
pricing adjustments, better visibility, or
discontinuation.

4. products with no sales represent inactive
inventory and should be reviewed to determine
whether they should be promoted or removed from
the catalog.

5. revenue contribution analysis helps identify
the products that have the greatest impact on
overall business performance.

=================================================
*/


--------


/*
=================================================
3. product sales analysis
=================================================
purpose:
analyze product sales volume and purchasing
patterns to identify high-demand products,
customer buying behavior, and inventory needs.
=================================================
*/


/*
=================================================
3.1 units sold by product
=================================================
*/

select

    p.product_id,

    coalesce(
        pct.product_category_name_english,
        'Unknown'
    ) as category,

    count(*) as units_sold

from olist_order_items_dataset oi

join olist_products_dataset p
    on oi.product_id = p.product_id

left join product_category_name_translation pct
    on p.product_category_name = pct.product_category_name

group by
    p.product_id,
    category

order by units_sold desc;


/*
=================================================
3.2 top 20 best-selling products
=================================================
*/

select

    p.product_id,

    coalesce(
        pct.product_category_name_english,
        'Unknown'
    ) as category,

    count(*) as units_sold

from olist_order_items_dataset oi

join olist_products_dataset p
    on oi.product_id = p.product_id

left join product_category_name_translation pct
    on p.product_category_name = pct.product_category_name

group by
    p.product_id,
    category

order by units_sold desc

limit 20;


/*
=================================================
3.3 bottom 20 products by units sold
=================================================
*/

select

    p.product_id,

    coalesce(
        pct.product_category_name_english,
        'Unknown'
    ) as category,

    count(*) as units_sold

from olist_order_items_dataset oi

join olist_products_dataset p
    on oi.product_id = p.product_id

left join product_category_name_translation pct
    on p.product_category_name = pct.product_category_name

group by
    p.product_id,
    category

order by
    units_sold,
    p.product_id

limit 20;

/*
=================================================
3.4 orders containing each product
=================================================
*/

select

    p.product_id,

    coalesce(
        pct.product_category_name_english,
        'Unknown'
    ) as category,

    count(distinct oi.order_id) as total_orders

from olist_order_items_dataset oi

join olist_products_dataset p
    on oi.product_id = p.product_id

left join product_category_name_translation pct
    on p.product_category_name = pct.product_category_name

group by
    p.product_id,
    category

order by total_orders desc;

/*
=================================================
3.5 average units per order
=================================================
*/

with order_quantity as (

    select

        order_id,

        count(*) as units

    from olist_order_items_dataset

    group by order_id

)

select

    round(avg(units),2) as average_units_per_order,

    min(units) as minimum_units,

    max(units) as maximum_units

from order_quantity;

/*
=================================================
3.6 product sales distribution
=================================================
*/

with product_sales as (

    select

        product_id,

        count(*) as units_sold

    from olist_order_items_dataset

    group by product_id

)

select

    case

        when units_sold = 1 then '1 Unit'

        when units_sold between 2 and 5 then '2-5 Units'

        when units_sold between 6 and 10 then '6-10 Units'

        when units_sold between 11 and 50 then '11-50 Units'

        when units_sold between 51 and 100 then '51-100 Units'

        else '100+ Units'

    end as sales_range,

    count(*) as products

from product_sales

group by sales_range

order by

case sales_range

    when '1 Unit' then 1
    when '2-5 Units' then 2
    when '6-10 Units' then 3
    when '11-50 Units' then 4
    when '51-100 Units' then 5
    else 6

end;

/*
=================================================
3.7 executive summary
=================================================
*/

with product_sales as (

    select

        product_id,

        count(*) as units_sold,

        count(distinct order_id) as total_orders

    from olist_order_items_dataset

    group by product_id

)

select

    count(*) as products_with_sales,

    sum(units_sold) as total_units_sold,

    round(avg(units_sold),2) as average_units_per_product,

    round(avg(total_orders),2) as average_orders_per_product,

    max(units_sold) as highest_units_sold,

    min(units_sold) as lowest_units_sold

from product_sales;
/*
=================================================
observations
=================================================

1. sales volume and revenue are not always aligned;
some products generate high revenue with low sales
volume, while others rely on high unit sales.

2. identifying best-selling products helps optimize
inventory levels and reduce stock-out risk.

3. products appearing in many orders indicate strong
customer demand and should receive priority in
procurement and replenishment.

4. average units per order provide insight into
customer purchasing behavior and basket size.

5. analyzing product sales distribution highlights
whether sales are concentrated among a few products
or spread across the catalog, supporting inventory
planning and assortment decisions.

=================================================
*/


--------


/*
=================================================
4. product category analysis
=================================================
purpose:
evaluate product category performance across
revenue, sales volume, pricing, and customer
demand to identify the marketplace's strongest
and weakest categories.
=================================================
*/


/*
=================================================
4.1 revenue by category
=================================================
*/

select

    coalesce(
        pct.product_category_name_english,
        'Unknown'
    ) as category,

    round(sum(oi.price),2) as total_revenue

from olist_order_items_dataset oi

join olist_products_dataset p
    on oi.product_id = p.product_id

left join product_category_name_translation pct
    on p.product_category_name = pct.product_category_name

group by category

order by total_revenue desc;

/*
=================================================
4.2 units sold by category
=================================================
*/

select

    coalesce(
        pct.product_category_name_english,
        'Unknown'
    ) as category,

    count(*) as units_sold

from olist_order_items_dataset oi

join olist_products_dataset p
    on oi.product_id = p.product_id

left join product_category_name_translation pct
    on p.product_category_name = pct.product_category_name

group by category

order by units_sold desc;

/*
=================================================
4.3 orders by category
=================================================
*/

select

    coalesce(
        pct.product_category_name_english,
        'Unknown'
    ) as category,

    count(distinct oi.order_id) as total_orders

from olist_order_items_dataset oi

join olist_products_dataset p
    on oi.product_id = p.product_id

left join product_category_name_translation pct
    on p.product_category_name = pct.product_category_name

group by category

order by total_orders desc;

/*
=================================================
4.4 average selling price by category
=================================================
*/

select

    coalesce(
        pct.product_category_name_english,
        'Unknown'
    ) as category,

    round(avg(oi.price),2) as average_selling_price

from olist_order_items_dataset oi

join olist_products_dataset p
    on oi.product_id = p.product_id

left join product_category_name_translation pct
    on p.product_category_name = pct.product_category_name

group by category

order by average_selling_price desc;

/*
=================================================
4.5 average revenue per order by category
=================================================
*/

select

    coalesce(
        pct.product_category_name_english,
        'Unknown'
    ) as category,

    round(

        sum(oi.price)

        /

        count(distinct oi.order_id),

        2

    ) as average_revenue_per_order

from olist_order_items_dataset oi

join olist_products_dataset p
    on oi.product_id = p.product_id

left join product_category_name_translation pct
    on p.product_category_name = pct.product_category_name

group by category

order by average_revenue_per_order desc;

/*
=================================================
4.6 category revenue contribution
=================================================
*/

with category_revenue as (

    select

        coalesce(
            pct.product_category_name_english,
            'Unknown'
        ) as category,

        sum(oi.price) as total_revenue

    from olist_order_items_dataset oi

    join olist_products_dataset p
        on oi.product_id = p.product_id

    left join product_category_name_translation pct
        on p.product_category_name = pct.product_category_name

    group by category

)

select

    category,

    round(total_revenue,2) as total_revenue,

    round(

        total_revenue
        *100.0
        /sum(total_revenue) over(),

        2

    ) as revenue_percentage

from category_revenue

order by total_revenue desc;

/*
=================================================
4.7 top 10 categories
=================================================
*/

select

    coalesce(
        pct.product_category_name_english,
        'Unknown'
    ) as category,

    round(sum(oi.price),2) as total_revenue

from olist_order_items_dataset oi

join olist_products_dataset p
    on oi.product_id = p.product_id

left join product_category_name_translation pct
    on p.product_category_name = pct.product_category_name

group by category

order by total_revenue desc

limit 10;

/*
=================================================
4.7 bottom 10 categories
=================================================
*/

select

    coalesce(
        pct.product_category_name_english,
        'Unknown'
    ) as category,

    round(sum(oi.price),2) as total_revenue

from olist_order_items_dataset oi

join olist_products_dataset p
    on oi.product_id = p.product_id

left join product_category_name_translation pct
    on p.product_category_name = pct.product_category_name

group by category

order by total_revenue

limit 10;

/*
=================================================
4.8 executive summary
=================================================
*/

with category_summary as (

    select

        coalesce(
            pct.product_category_name_english,
            'Unknown'
        ) as category,

        sum(oi.price) as revenue,

        count(*) as units_sold,

        count(distinct oi.order_id) as total_orders

    from olist_order_items_dataset oi

    join olist_products_dataset p
        on oi.product_id = p.product_id

    left join product_category_name_translation pct
        on p.product_category_name = pct.product_category_name

    group by category

)

select

    count(*) as total_categories,

    round(sum(revenue),2) as total_revenue,

    round(avg(revenue),2) as average_category_revenue,

    round(avg(units_sold),2) as average_units_sold,

    round(avg(total_orders),2) as average_orders

from category_summary;
/*
=================================================
observations
=================================================

1. category performance varies significantly across
the marketplace, with a small number of categories
generating a large share of total revenue.

2. high-revenue categories should receive priority
for inventory investment, marketing campaigns,
and supplier negotiations.

3. comparing units sold and average selling price
helps distinguish high-volume categories from
premium-priced categories.

4. average revenue per order highlights categories
that contribute the greatest value to each
customer purchase.

5. revenue contribution analysis identifies the
categories that drive overall business performance
and supports strategic portfolio management.

=================================================
*/


--------


/*
=================================================
5. product pricing analysis
=================================================
purpose:
analyze product pricing patterns across the
marketplace to identify premium categories,
budget-friendly products, and pricing
distribution.
=================================================
*/


/*
=================================================
5.1 overall price statistics
=================================================
*/

select

    round(avg(price),2) as average_price,

    round(min(price),2) as minimum_price,

    round(max(price),2) as maximum_price,

    round(stddev(price),2) as price_std_dev

from olist_order_items_dataset;

/*
=================================================
5.2 price distribution
=================================================
*/

select

    case

        when price < 50 then 'Under $50'

        when price < 100 then '$50 - $99'

        when price < 200 then '$100 - $199'

        when price < 500 then '$200 - $499'

        when price < 1000 then '$500 - $999'

        else '$1000+'

    end as price_range,

    count(*) as products,

    round(sum(price),2) as revenue

from olist_order_items_dataset

group by price_range

order by

case price_range

    when 'Under $50' then 1
    when '$50 - $99' then 2
    when '$100 - $199' then 3
    when '$200 - $499' then 4
    when '$500 - $999' then 5
    else 6

end;

/*
=================================================
5.3 average price by category
=================================================
*/

select

    coalesce(
        pct.product_category_name_english,
        'Unknown'
    ) as category,

    round(avg(oi.price),2) as average_price

from olist_order_items_dataset oi

join olist_products_dataset p

on oi.product_id=p.product_id

left join product_category_name_translation pct

on p.product_category_name=pct.product_category_name

group by category

order by average_price desc;

/*
=================================================
5.4 highest priced products
=================================================
*/

select

    oi.product_id,

    coalesce(
        pct.product_category_name_english,
        'Unknown'
    ) as category,

    max(oi.price) as highest_price

from olist_order_items_dataset oi

join olist_products_dataset p

on oi.product_id=p.product_id

left join product_category_name_translation pct

on p.product_category_name=pct.product_category_name

group by
    oi.product_id,
    category

order by highest_price desc

limit 20;

/*
=================================================
5.4 lowest priced products
=================================================
*/

select

    oi.product_id,

    coalesce(
        pct.product_category_name_english,
        'Unknown'
    ) as category,

    min(oi.price) as lowest_price

from olist_order_items_dataset oi

join olist_products_dataset p

on oi.product_id=p.product_id

left join product_category_name_translation pct

on p.product_category_name=pct.product_category_name

group by
    oi.product_id,
    category

order by lowest_price

limit 20;

/*
=================================================
5.5 price range analysis
=================================================
*/

select

    case

        when price < 50 then 'Budget'

        when price between 50 and 200 then 'Mid Range'

        when price between 200 and 500 then 'Premium'

        else 'Luxury'

    end as price_segment,

    count(*) as units_sold,

    round(sum(price),2) as revenue,

    round(avg(price),2) as average_price

from olist_order_items_dataset

group by price_segment

order by average_price;

/*
=================================================
5.6 premium vs budget products
=================================================
*/

select

    case

        when price >= 200 then 'Premium'

        else 'Budget'

    end as product_type,

    count(*) as units_sold,

    round(sum(price),2) as revenue,

    round(avg(price),2) as average_price

from olist_order_items_dataset

group by product_type;

/*
=================================================
5.7 executive summary
=================================================
*/

select

    round(avg(price),2) as average_price,

    round(min(price),2) as minimum_price,

    round(max(price),2) as maximum_price,

    count(*) as total_items_sold,

    round(sum(price),2) as total_revenue

from olist_order_items_dataset;
/*
=================================================
observations
=================================================

1. product prices vary widely across the marketplace,
indicating a mix of budget, mid-range, premium,
and luxury products.

2. category-level pricing helps identify premium
segments that generate higher revenue per sale.

3. price distribution reveals whether the business
focuses primarily on affordable products or
higher-value items.

4. comparing revenue across price ranges helps
determine whether business growth is driven by
high-priced products or high sales volume.

5. understanding pricing patterns supports pricing
strategy, promotional planning, and product
positioning.

=================================================
*/


--------


/*
=================================================
6. product performance ranking
=================================================
purpose:
rank products and product categories using
revenue, sales volume, and overall performance
metrics to identify the marketplace's strongest
and weakest performers.
=================================================
*/

/*
=================================================
6.1 revenue ranking
=================================================
*/

with product_revenue as (

    select

        oi.product_id,

        coalesce(
            pct.product_category_name_english,
            'Unknown'
        ) as category,

        round(sum(oi.price),2) as revenue

    from olist_order_items_dataset oi

    join olist_products_dataset p
        on oi.product_id = p.product_id

    left join product_category_name_translation pct
        on p.product_category_name = pct.product_category_name

    group by
        oi.product_id,
        category

)

select

    product_id,

    category,

    revenue,

    rank() over(
        order by revenue desc
    ) as revenue_rank

from product_revenue

order by revenue_rank;

/*
=================================================
6.2 sales volume ranking
=================================================
*/

with product_sales as (

    select

        oi.product_id,

        coalesce(
            pct.product_category_name_english,
            'Unknown'
        ) as category,

        count(*) as units_sold

    from olist_order_items_dataset oi

    join olist_products_dataset p
        on oi.product_id = p.product_id

    left join product_category_name_translation pct
        on p.product_category_name = pct.product_category_name

    group by
        oi.product_id,
        category

)

select

    product_id,

    category,

    units_sold,

    rank() over(
        order by units_sold desc
    ) as sales_rank

from product_sales

order by sales_rank;

/*
=================================================
6.3 category revenue ranking
=================================================
*/

with category_revenue as (

    select

        coalesce(
            pct.product_category_name_english,
            'Unknown'
        ) as category,

        round(sum(oi.price),2) as revenue

    from olist_order_items_dataset oi

    join olist_products_dataset p
        on oi.product_id = p.product_id

    left join product_category_name_translation pct
        on p.product_category_name = pct.product_category_name

    group by category

)

select

    category,

    revenue,

    dense_rank() over(
        order by revenue desc
    ) as category_rank

from category_revenue

order by category_rank;

/*
=================================================
6.4 top 10 products within each category
=================================================
*/

with product_revenue as (

    select

        oi.product_id,

        coalesce(
            pct.product_category_name_english,
            'Unknown'
        ) as category,

        round(sum(oi.price),2) as revenue

    from olist_order_items_dataset oi

    join olist_products_dataset p
        on oi.product_id = p.product_id

    left join product_category_name_translation pct
        on p.product_category_name = pct.product_category_name

    group by
        oi.product_id,
        category

)

select *

from (

    select

        *,

        row_number() over(

            partition by category

            order by revenue desc

        ) as rn

    from product_revenue

) ranked

where rn<=10

order by
category,
rn;

/*
=================================================
6.5 product performance score
=================================================
*/

with performance as (

    select

        oi.product_id,

        round(sum(oi.price),2) as revenue,

        count(*) as units_sold,

        count(distinct oi.order_id) as orders_count

    from olist_order_items_dataset oi

    group by oi.product_id

)

select

    *,

    ntile(5) over(order by revenue desc) as revenue_score,

    ntile(5) over(order by units_sold desc) as sales_score,

    ntile(5) over(order by orders_count desc) as order_score,

    (

        ntile(5) over(order by revenue desc)

        +

        ntile(5) over(order by units_sold desc)

        +

        ntile(5) over(order by orders_count desc)

    ) as performance_score

from performance

order by performance_score desc;

/*
=================================================
6.6 top 20 overall products
=================================================
*/

with performance as (

    select

        product_id,

        sum(price) as revenue,

        count(*) as units_sold

    from olist_order_items_dataset

    group by product_id

)

select *

from performance

order by
revenue desc,
units_sold desc

limit 20;

/*
=================================================
6.7 bottom 20 overall products
=================================================
*/

with performance as (

    select

        product_id,

        sum(price) as revenue,

        count(*) as units_sold

    from olist_order_items_dataset

    group by product_id

)

select *

from performance

order by
revenue,
units_sold

limit 20;

/*
=================================================
6.8 executive summary
=================================================
*/

with performance as (

    select

        product_id,

        sum(price) as revenue,

        count(*) as units_sold,

        count(distinct order_id) as total_orders

    from olist_order_items_dataset

    group by product_id

)

select

    count(*) as products_with_sales,

    round(avg(revenue),2) as average_revenue,

    round(avg(units_sold),2) as average_units_sold,

    round(avg(total_orders),2) as average_orders,

    max(revenue) as highest_product_revenue,

    max(units_sold) as highest_units_sold

from performance;
/*
=================================================
observation
=================================================

1. Ranking products across multiple metrics provides
a more complete picture than revenue alone.

2. Products that consistently rank highly in revenue,
sales volume, and order frequency should be
prioritized for inventory, marketing, and retention.

3. The Product Performance Matrix helps distinguish
between products that are profitable, popular, or
underperforming, supporting strategic product
portfolio decisions.

4. Combining window functions with business
classification demonstrates advanced SQL and
analytical skills suitable for real-world reporting.
=================================================
*/


--------


/*
=================================================
7. product lifecycle analysis
=================================================
purpose:
analyze product performance over time to identify
growth trends, seasonal demand, consistent
performers, and declining products.
=================================================
*/


/*
=================================================
7.1 monthly product revenue
=================================================
*/

select

    date_format(o.order_purchase_timestamp,'%Y-%m') as sales_month,

    oi.product_id,

    round(sum(oi.price),2) as revenue

from olist_orders_dataset o

join olist_order_items_dataset oi
    on o.order_id = oi.order_id

where o.order_status='delivered'

group by
    sales_month,
    oi.product_id

order by
    sales_month,
    revenue desc;
    
/*
=================================================
7.2 monthly units sold
=================================================
*/

select

    date_format(o.order_purchase_timestamp,'%Y-%m') as sales_month,

    oi.product_id,

    count(*) as units_sold

from olist_orders_dataset o

join olist_order_items_dataset oi
    on o.order_id = oi.order_id

where o.order_status='delivered'

group by
    sales_month,
    oi.product_id

order by
    sales_month,
    units_sold desc;
    
/*
=================================================
7.3 month-over-month product growth
=================================================
*/

with monthly_revenue as (

    select

        date_format(o.order_purchase_timestamp,'%Y-%m') as sales_month,

        oi.product_id,

        sum(oi.price) as revenue

    from olist_orders_dataset o

    join olist_order_items_dataset oi
        on o.order_id = oi.order_id

    where o.order_status='delivered'

    group by
        sales_month,
        oi.product_id

)

select

    sales_month,

    product_id,

    round(revenue,2) as revenue,

    round(

        lag(revenue) over(
            partition by product_id
            order by sales_month
        ),

        2

    ) as previous_month,

    round(

        revenue
        -

        lag(revenue) over(
            partition by product_id
            order by sales_month
        ),

        2

    ) as revenue_change

from monthly_revenue

order by
product_id,
sales_month;

/*
=================================================
7.4 product sales trend
=================================================
*/

with monthly_sales as (

    select

        oi.product_id,

        date_format(o.order_purchase_timestamp,'%Y-%m') as sales_month,

        count(*) as units_sold

    from olist_orders_dataset o

    join olist_order_items_dataset oi
        on o.order_id=oi.order_id

    where o.order_status='delivered'

    group by
        oi.product_id,
        sales_month

)

select

    product_id,

    count(*) as active_months,

    round(avg(units_sold),2) as average_monthly_sales,

    max(units_sold) as peak_monthly_sales

from monthly_sales

group by product_id

order by average_monthly_sales desc;

/*
=================================================
7.5 consistently selling products
=================================================
*/

select

    oi.product_id,

    count(

        distinct date_format(
            o.order_purchase_timestamp,
            '%Y-%m'
        )

    ) as active_months,

    count(*) as units_sold

from olist_orders_dataset o

join olist_order_items_dataset oi
    on o.order_id=oi.order_id

where o.order_status='delivered'

group by oi.product_id

order by
active_months desc,
units_sold desc

limit 20;

/*
=================================================
7.6 seasonal products
=================================================
*/

with monthly_sales as (

    select

        oi.product_id,

        month(o.order_purchase_timestamp) as sales_month,

        count(*) as units_sold

    from olist_orders_dataset o

    join olist_order_items_dataset oi
        on o.order_id=oi.order_id

    where o.order_status='delivered'

    group by
        oi.product_id,
        sales_month

)

select

    product_id,

    max(units_sold) as peak_month_sales,

    min(units_sold) as lowest_month_sales,

    round(stddev(units_sold),2) as monthly_variation

from monthly_sales

group by product_id

having monthly_variation > 5

order by monthly_variation desc;

/*
=================================================
7.7 declining products
=================================================
*/

with monthly_sales as (

    select

        oi.product_id,

        date_format(
            o.order_purchase_timestamp,
            '%Y-%m'
        ) as sales_month,

        count(*) as units_sold

    from olist_orders_dataset o

    join olist_order_items_dataset oi
        on o.order_id=oi.order_id

    where o.order_status='delivered'

    group by
        oi.product_id,
        sales_month

),

ranked as (

    select

        *,

        row_number() over(

            partition by product_id

            order by sales_month

        ) as first_month,

        row_number() over(

            partition by product_id

            order by sales_month desc

        ) as last_month

    from monthly_sales

)

select

    f.product_id,

    f.units_sold as first_month_sales,

    l.units_sold as last_month_sales,

    l.units_sold - f.units_sold as sales_change

from ranked f

join ranked l

on f.product_id=l.product_id

where
f.first_month=1
and
l.last_month=1

order by sales_change;

/*
=================================================
7.8 executive summary
=================================================
*/

with monthly_sales as (

    select

        oi.product_id,

        date_format(
            o.order_purchase_timestamp,
            '%Y-%m'
        ) as sales_month,

        sum(oi.price) as revenue,

        count(*) as units_sold

    from olist_orders_dataset o

    join olist_order_items_dataset oi
        on o.order_id=oi.order_id

    where o.order_status='delivered'

    group by
        oi.product_id,
        sales_month

)

select

    count(distinct product_id) as active_products,

    count(distinct sales_month) as business_months,

    round(avg(revenue),2) as average_monthly_revenue,

    round(avg(units_sold),2) as average_monthly_units

from monthly_sales;
/*
=================================================
observation
=================================================

1. Lifecycle analysis reveals how product demand
changes over time rather than relying on total
historical performance.

2. Month-over-month growth highlights products that
are gaining momentum as well as those losing
customer interest.

3. Consistently selling products provide stable
revenue and should be prioritized for inventory
planning.

4. Seasonal and declining products require different
business strategies, such as promotional campaigns,
seasonal stocking, or product replacement.

5. Time-based analysis transforms static sales
reports into forward-looking business insights,
making this section valuable for forecasting and
strategic planning.

=================================================
*/


--------


/*
=================================================
8. executive summary
=================================================
purpose:
provide a high-level summary of the product
portfolio by combining the most important
performance metrics into an executive report.
=================================================
*/


/*
=================================================
8.1 product portfolio kpis
=================================================
*/

with product_summary as (

    select

        oi.product_id,

        sum(oi.price) as revenue,

        count(*) as units_sold,

        count(distinct oi.order_id) as total_orders

    from olist_order_items_dataset oi

    group by oi.product_id

)

select

    (select count(*) from olist_products_dataset) as total_products,

    (select count(distinct product_category_name)
     from olist_products_dataset) as total_categories,

    count(*) as products_with_sales,

    round(sum(revenue),2) as total_revenue,

    sum(units_sold) as total_units_sold,

    round(avg(revenue),2) as average_revenue_per_product,

    round(avg(units_sold),2) as average_units_per_product

from product_summary;

/*
=================================================
8.2 top performing product
=================================================
*/

select

    oi.product_id,

    coalesce(
        pct.product_category_name_english,
        'Unknown'
    ) as category,

    round(sum(oi.price),2) as revenue,

    count(*) as units_sold,

    count(distinct oi.order_id) as total_orders

from olist_order_items_dataset oi

join olist_products_dataset p

on oi.product_id=p.product_id

left join product_category_name_translation pct

on p.product_category_name=pct.product_category_name

group by
    oi.product_id,
    category

order by revenue desc

limit 1;

/*
=================================================
8.3 top performing category
=================================================
*/

select

    coalesce(
        pct.product_category_name_english,
        'Unknown'
    ) as category,

    round(sum(oi.price),2) as revenue,

    count(*) as units_sold,

    count(distinct oi.order_id) as total_orders

from olist_order_items_dataset oi

join olist_products_dataset p

on oi.product_id=p.product_id

left join product_category_name_translation pct

on p.product_category_name=pct.product_category_name

group by category

order by revenue desc

limit 1;

/*
=================================================
8.4 pricing summary
=================================================
*/

select

    round(avg(price),2) as average_price,

    round(min(price),2) as minimum_price,

    round(max(price),2) as maximum_price,

    round(stddev(price),2) as price_standard_deviation

from olist_order_items_dataset;

/*
=================================================
8.5 product performance distribution
=================================================
*/

with performance as (

    select

        product_id,

        sum(price) as revenue

    from olist_order_items_dataset

    group by product_id

)

select

    case

        when revenue < 100 then 'Under $100'

        when revenue < 500 then '$100-$499'

        when revenue < 1000 then '$500-$999'

        when revenue < 5000 then '$1K-$5K'

        else 'Over $5K'

    end as revenue_band,

    count(*) as products

from performance

group by revenue_band

order by

case revenue_band

    when 'Under $100' then 1
    when '$100-$499' then 2
    when '$500-$999' then 3
    when '$1K-$5K' then 4
    else 5

end;

/*
=================================================
8.6 business recommendations
=================================================

1. prioritize inventory investment in the
highest-revenue and best-selling products to
maximize sales and minimize stock-outs.

2. increase marketing efforts for high-performing
product categories, as they contribute the largest
share of marketplace revenue.

3. review low-performing and no-sale products to
determine whether they should be promoted,
repriced, or removed from the catalog.

4. use pricing analysis to balance premium and
budget product offerings while maintaining
competitiveness and profitability.

5. monitor seasonal and lifecycle trends to improve
inventory planning, demand forecasting, and
promotional timing.

6. regularly review product performance rankings to
identify emerging best sellers and declining
products, enabling proactive business decisions.

=================================================
*/


/*
=================================================
OBSERVATION
=================================================

1. Product analysis provides a complete view of the
marketplace's catalog, covering revenue, sales,
pricing, category performance, and lifecycle trends.

2. Combining multiple performance metrics helps
identify products that drive business growth as well
as those that require strategic intervention.

3. Product segmentation supports data-driven
decisions for pricing, inventory management,
marketing campaigns, and product portfolio
optimization.

4. The Executive Product Scorecard consolidates
operational and financial metrics into a single,
actionable report suitable for executive dashboards.

=================================================
*/











---------------------------------------------------------------------------------------------










/*
=================================================
Project: Brazilian E-Commerce (Olist) Analysis
File: 06_seller_analysis.sql
=================================================
purpose:
analyze seller performance, geographic
distribution, revenue contribution, and operational
efficiency to understand how sellers contribute to
the marketplace.
Dataset:
    Olist Brazilian E-Commerce Public Dataset
=================================================
*/


/*
=================================================
1. seller overview
=================================================
purpose:
provide an overview of the marketplace's seller
network by analyzing the number of sellers,
their activity status, and their geographic
distribution. this section establishes the
foundation for evaluating seller performance
in later analyses.
=================================================
*/

/*
=================================================
1.1 total sellers
=================================================
*/

select

    count(*) as total_sellers
    
from olist_sellers_dataset;

/*
=================================================
1.2 active sellers
=================================================
*/

select

    count(distinct seller_id) as active_sellers

from olist_order_items_dataset;

/*
=================================================
1.3 inactive sellers
=================================================
*/

select

    count(*) as inactive_sellers

from olist_sellers_dataset s

left join (

    select distinct seller_id

    from olist_order_items_dataset

) oi

on s.seller_id=oi.seller_id

where oi.seller_id is null;

/*
=================================================
1.4 sellers by state
=================================================
*/

select

    seller_state,

    count(*) as total_sellers

from olist_sellers_dataset

group by seller_state

order by total_sellers desc;

/*
=================================================
1.5 sellers by city
=================================================
*/

select

    seller_city,

    seller_state,

    count(*) as total_sellers

from olist_sellers_dataset

group by
    seller_city,
    seller_state

order by total_sellers desc;

/*
=================================================
1.6 executive summary
=================================================
*/

select

    (select count(*)
     from olist_sellers_dataset) as total_sellers,

    (select count(distinct seller_id)
     from olist_order_items_dataset) as active_sellers,

    (

        select count(*)

        from olist_sellers_dataset s

        left join (

            select distinct seller_id

            from olist_order_items_dataset

        ) oi

        on s.seller_id=oi.seller_id

        where oi.seller_id is null

    ) as inactive_sellers,

    (select count(distinct seller_state)
     from olist_sellers_dataset) as seller_states,

    (select count(distinct seller_city)
     from olist_sellers_dataset) as seller_cities;
     
/*
=================================================
observations
=================================================

1. the marketplace consists of both active and
inactive sellers, indicating opportunities to
re-engage or remove inactive accounts.

2. seller distribution across states and cities
shows the geographic reach of the marketplace and
highlights regional concentrations.

3. identifying active sellers establishes the
foundation for evaluating seller performance in
later sections.

4. understanding seller locations helps support
regional expansion, logistics planning, and
supplier relationship management.

5. this overview provides the baseline for analyzing
seller revenue, order fulfillment, customer
experience, and operational efficiency.

=================================================
*/


--------


/*
=================================================
2. seller revenue analysis
=================================================
purpose:
evaluate seller revenue performance to identify
top-performing sellers, measure revenue
distribution, and determine whether marketplace
revenue is concentrated among a small number of
sellers. these insights support seller management,
partnership strategy, and marketplace growth.
=================================================
*/

/*
=================================================
2.1 revenue by seller
=================================================
*/

select

    oi.seller_id,

    round(sum(oi.price),2) as total_revenue,

    count(distinct oi.order_id) as total_orders,

    count(*) as units_sold,

    round(avg(oi.price),2) as average_item_price

from olist_order_items_dataset oi

group by oi.seller_id

order by total_revenue desc;

/*
=================================================
2.2 top 20 sellers by revenue
=================================================
*/

select

    oi.seller_id,

    round(sum(oi.price),2) as total_revenue,

    count(distinct oi.order_id) as total_orders,

    count(*) as units_sold

from olist_order_items_dataset oi

group by oi.seller_id

order by total_revenue desc

limit 20;

/*
=================================================
2.3 bottom 20 sellers by revenue
=================================================
*/

select

    oi.seller_id,

    round(sum(oi.price),2) as total_revenue,

    count(distinct oi.order_id) as total_orders,

    count(*) as units_sold

from olist_order_items_dataset oi

group by oi.seller_id

order by
    total_revenue,
    total_orders

limit 20;

/*
=================================================
2.4 average revenue per seller
=================================================
*/

with seller_revenue as (

    select

        seller_id,

        sum(price) as revenue

    from olist_order_items_dataset

    group by seller_id

)

select

    round(avg(revenue),2) as average_revenue_per_seller,

    round(min(revenue),2) as minimum_revenue,

    round(max(revenue),2) as maximum_revenue,

    round(stddev(revenue),2) as revenue_std_dev

from seller_revenue;

/*
=================================================
2.5 revenue contribution by seller
=================================================
*/

with seller_revenue as (

    select

        seller_id,

        sum(price) as revenue

    from olist_order_items_dataset

    group by seller_id

)

select

    seller_id,

    round(revenue,2) as revenue,

    round(

        revenue
        *100
        /sum(revenue) over(),

        2

    ) as revenue_percentage

from seller_revenue

order by revenue desc;

/*
=================================================
2.6 pareto analysis (80/20 rule)
=================================================
*/

with seller_revenue as (

    select

        seller_id,

        sum(price) as revenue

    from olist_order_items_dataset

    group by seller_id

),

pareto as (

    select

        seller_id,

        revenue,

        sum(revenue) over(

            order by revenue desc

        ) as cumulative_revenue,

        sum(revenue) over() as total_revenue,

        row_number() over(

            order by revenue desc

        ) as seller_rank,

        count(*) over() as total_sellers

    from seller_revenue

)

select

    seller_id,

    round(revenue,2) as revenue,

    seller_rank,

    round(

        cumulative_revenue
        *100
        /total_revenue,

        2

    ) as cumulative_revenue_percentage,

    round(

        seller_rank
        *100
        /total_sellers,

        2

    ) as cumulative_seller_percentage

from pareto

order by seller_rank;

/*
=================================================
2.7 executive summary
=================================================
*/

with seller_summary as (

    select

        seller_id,

        sum(price) as revenue,

        count(distinct order_id) as orders_count,

        count(*) as units_sold

    from olist_order_items_dataset

    group by seller_id

)

select

    count(*) as active_sellers,

    round(sum(revenue),2) as total_revenue,

    round(avg(revenue),2) as average_revenue_per_seller,

    round(avg(orders_count),2) as average_orders_per_seller,

    round(avg(units_sold),2) as average_units_sold,

    round(max(revenue),2) as highest_seller_revenue,

    round(min(revenue),2) as lowest_seller_revenue

from seller_summary;
/*
=================================================
OBSERVATION
=================================================

1. Seller revenue analysis identifies the merchants
that contribute most to marketplace performance.

2. Revenue concentration reveals whether the
business relies heavily on a small number of
high-performing sellers.

3. Seller segmentation supports differentiated
business strategies, such as premium partnerships
for top sellers and growth programs for smaller
sellers.

4. Pareto analysis helps quantify marketplace risk
by showing how much revenue depends on a limited
portion of the seller base.

=================================================
*/


/*
=================================================
3. seller order analysis
=================================================
purpose:
analyze seller order activity, customer reach,
and purchasing behavior to evaluate operational
performance beyond revenue. this section
identifies high-volume sellers, customer
engagement, and average order values to support
seller management and marketplace optimization.
=================================================
*/

/*
=================================================
3.1 orders by seller
=================================================
*/

select

    seller_id,

    count(distinct order_id) as total_orders,

    count(*) as units_sold

from olist_order_items_dataset

group by seller_id

order by total_orders desc;

/*
=================================================
3.2 top 20 sellers by orders
=================================================
*/

select

    seller_id,

    count(distinct order_id) as total_orders,

    count(*) as units_sold

from olist_order_items_dataset

group by seller_id

order by total_orders desc

limit 20;

/*
=================================================
3.3 bottom 20 sellers by orders
=================================================
*/

select

    seller_id,

    count(distinct order_id) as total_orders,

    count(*) as units_sold

from olist_order_items_dataset

group by seller_id

order by
    total_orders,
    units_sold

limit 20;

/*
=================================================
3.3 bottom 20 sellers by orders
=================================================
*/

select

    seller_id,

    count(distinct order_id) as total_orders,

    count(*) as units_sold

from olist_order_items_dataset

group by seller_id

order by
    total_orders,
    units_sold

limit 20;

/*
=================================================
3.4 average orders per seller
=================================================
*/

with seller_orders as (

    select

        seller_id,

        count(distinct order_id) as total_orders

    from olist_order_items_dataset

    group by seller_id

)

select

    round(avg(total_orders),2) as average_orders_per_seller,

    min(total_orders) as minimum_orders,

    max(total_orders) as maximum_orders,

    round(stddev(total_orders),2) as order_std_dev

from seller_orders;

/*
=================================================
3.5 average order value by seller
=================================================
*/

with seller_orders as (

    select

        seller_id,

        order_id,

        sum(price) as order_value

    from olist_order_items_dataset

    group by
        seller_id,
        order_id

)

select

    seller_id,

    round(avg(order_value),2) as average_order_value,

    count(*) as total_orders

from seller_orders

group by seller_id

order by average_order_value desc;

/*
=================================================
3.6 customers served by seller
=================================================
*/

select

    oi.seller_id,

    count(distinct o.customer_id) as total_customers

from olist_order_items_dataset oi

join olist_orders_dataset o

on oi.order_id=o.order_id

group by oi.seller_id

order by total_customers desc;

/*
=================================================
3.7 repeat customer rate by seller
=================================================
*/

with seller_customer_orders as (

    select

        oi.seller_id,

        o.customer_id,

        count(distinct oi.order_id) as total_orders

    from olist_order_items_dataset oi

    join olist_orders_dataset o

    on oi.order_id=o.order_id

    group by
        oi.seller_id,
        o.customer_id

)

select

    seller_id,

    count(*) as total_customers,

    sum(

        case

            when total_orders>1 then 1

            else 0

        end

    ) as repeat_customers,

    round(

        sum(

            case

                when total_orders>1 then 1

                else 0

            end

        )

        *100.0

        /count(*),

        2

    ) as repeat_customer_rate

from seller_customer_orders

group by seller_id

order by repeat_customer_rate desc;


/*
=================================================
3.8 executive summary
=================================================
*/

with seller_summary as (

    select

        seller_id,

        count(distinct order_id) as total_orders,

        count(*) as units_sold

    from olist_order_items_dataset

    group by seller_id

)

select

    count(*) as active_sellers,

    sum(total_orders) as total_orders,

    round(avg(total_orders),2) as average_orders_per_seller,

    round(avg(units_sold),2) as average_units_sold,

    max(total_orders) as highest_order_count,

    min(total_orders) as lowest_order_count

from seller_summary;
/*
=================================================
observations
=================================================

1. seller order volume varies significantly across
the marketplace, indicating that a small number
of sellers handle a large share of customer orders.

2. comparing revenue with order volume helps
distinguish premium sellers from high-volume
sellers operating with lower-priced products.

3. sellers serving a large customer base contribute
more to marketplace reach and customer acquisition.

4. a high repeat customer rate suggests strong
customer satisfaction, competitive pricing,
or effective product offerings, making these
sellers valuable long-term partners.

5. average order value highlights differences in
seller business models, with some focusing on
premium products while others rely on higher
transaction volumes.

6. these insights support seller segmentation,
performance evaluation, inventory planning,
and targeted seller development programs.

=================================================
*/


--------


/*
=================================================
4. seller product analysis
=================================================
purpose:
analyze the composition of each seller's product
portfolio by evaluating product variety,
category diversity, product concentration, and
seller specialization. these insights help
understand seller business models and support
product portfolio optimization.
=================================================
*/

/*
=================================================
4.1 products sold by seller
=================================================
*/

select

    oi.seller_id,

    count(distinct oi.product_id) as unique_products

from olist_order_items_dataset oi

join olist_orders_dataset o

    on oi.order_id = o.order_id

where o.order_status = 'delivered'

group by oi.seller_id

order by
    unique_products desc,
    oi.seller_id;
    
/*
=================================================
4.2 top 20 sellers by product variety
=================================================
*/

with seller_products as (

    select

        oi.seller_id,

        count(distinct oi.product_id) as unique_products

    from olist_order_items_dataset oi

    join olist_orders_dataset o

        on oi.order_id = o.order_id

    where o.order_status='delivered'

    group by oi.seller_id

)

select

    dense_rank() over(

        order by unique_products desc

    ) as seller_rank,

    seller_id,

    unique_products

from seller_products

order by
    seller_rank,
    seller_id

limit 20;

/*
=================================================
4.3 product categories sold by seller
=================================================
*/

select

    oi.seller_id,

    count(

        distinct coalesce(

            pct.product_category_name_english,

            'Unknown'

        )

    ) as categories_sold

from olist_order_items_dataset oi

join olist_orders_dataset o

    on oi.order_id = o.order_id

join olist_products_dataset p

    on oi.product_id = p.product_id

left join product_category_name_translation pct

    on p.product_category_name =
       pct.product_category_name

where o.order_status='delivered'

group by oi.seller_id

order by
    categories_sold desc,
    oi.seller_id;
    
/*
=================================================
4.4 average products per seller
=================================================
*/

with seller_products as (

    select

        oi.seller_id,

        count(distinct oi.product_id) as unique_products

    from olist_order_items_dataset oi

    join olist_orders_dataset o

        on oi.order_id = o.order_id

    where o.order_status = 'delivered'

    group by oi.seller_id

)

select

    round(avg(unique_products),2) as average_products_per_seller,

    min(unique_products) as minimum_products,

    max(unique_products) as maximum_products,

    round(stddev(unique_products),2) as std_dev_products

from seller_products;

/*
=================================================
4.5 best-selling product for each seller
=================================================
*/

with product_revenue as (

    select

        oi.seller_id,

        oi.product_id,

        round(sum(oi.price),2) as revenue

    from olist_order_items_dataset oi

    join olist_orders_dataset o

        on oi.order_id = o.order_id

    where o.order_status = 'delivered'

    group by

        oi.seller_id,

        oi.product_id

),

ranked_products as (

    select

        *,

        row_number() over(

            partition by seller_id

            order by revenue desc

        ) as rn

    from product_revenue

)

select

    seller_id,

    product_id,

    revenue

from ranked_products

where rn = 1

order by revenue desc;


/*
=================================================
4.6 seller product concentration
=================================================
*/

with product_revenue as (

    select

        seller_id,

        product_id,

        sum(price) as product_revenue

    from olist_order_items_dataset

    group by

        seller_id,

        product_id

),

ranked_products as (

    select

        *,

        row_number() over(

            partition by seller_id

            order by product_revenue desc

        ) as rn

    from product_revenue

),

seller_revenue as (

    select

        seller_id,

        sum(price) as total_revenue

    from olist_order_items_dataset

    group by seller_id

)

select

    rp.seller_id,

    rp.product_id as best_product,

    round(rp.product_revenue,2) as best_product_revenue,

    round(sr.total_revenue,2) as seller_revenue,

    round(

        rp.product_revenue
        *100
        /sr.total_revenue,

        2

    ) as product_revenue_percentage,

    case

        when rp.product_revenue *100 / sr.total_revenue >=80

            then 'Very High Dependency'

        when rp.product_revenue *100 / sr.total_revenue >=60

            then 'High Dependency'

        when rp.product_revenue *100 / sr.total_revenue >=40

            then 'Moderate Dependency'

        else 'Well Diversified'

    end as dependency_level

from ranked_products rp

join seller_revenue sr

    on rp.seller_id = sr.seller_id

where rp.rn = 1

order by product_revenue_percentage desc;

/*
=================================================
4.7 seller diversification analysis
=================================================
*/

with seller_categories as (

    select

        oi.seller_id,

        count(

            distinct coalesce(

                pct.product_category_name_english,

                'Unknown'

            )

        ) as categories_sold

    from olist_order_items_dataset oi

    join olist_orders_dataset o

        on oi.order_id = o.order_id

    join olist_products_dataset p

        on oi.product_id = p.product_id

    left join product_category_name_translation pct

        on p.product_category_name =
           pct.product_category_name

    where o.order_status = 'delivered'

    group by oi.seller_id

)

select

    seller_id,

    categories_sold,

    case

        when categories_sold = 1
            then 'Specialist'

        when categories_sold between 2 and 5
            then 'Focused'

        when categories_sold between 6 and 10
            then 'Diversified'

        else 'Highly Diversified'

    end as seller_type

from seller_categories

order by
    categories_sold desc,
    seller_id;
    
/*
=================================================
4.8 seller product portfolio matrix
=================================================
*/

with seller_metrics as (

    select

        seller_id,

        count(distinct product_id) as unique_products,

        sum(price) as revenue

    from olist_order_items_dataset

    group by seller_id

),

scored as (

    select

        *,

        ntile(4) over(

            order by unique_products

        ) as product_quartile,

        ntile(4) over(

            order by revenue

        ) as revenue_quartile

    from seller_metrics

)

select

    seller_id,

    unique_products,

    round(revenue,2) as revenue,

    case

        when product_quartile >=3
         and revenue_quartile >=3

            then 'Marketplace Leader'

        when product_quartile >=3
         and revenue_quartile <=2

            then 'Large Catalog'

        when product_quartile <=2
         and revenue_quartile >=3

            then 'Premium Specialist'

        else 'Small Seller'

    end as seller_segment

from scored

order by
    revenue desc,
    unique_products desc;
    
/*
=================================================
4.9 executive summary
=================================================
*/

with seller_summary as (

    select

        seller_id,

        count(distinct product_id) as unique_products,

        sum(price) as revenue

    from olist_order_items_dataset

    group by seller_id

),

category_summary as (

    select

        oi.seller_id,

        count(

            distinct p.product_category_name

        ) as categories_sold

    from olist_order_items_dataset oi

    join olist_products_dataset p

        on oi.product_id = p.product_id

    group by oi.seller_id

)

select

    round(avg(ss.unique_products),2) as average_products_per_seller,

    round(avg(cs.categories_sold),2) as average_categories_per_seller,

    max(ss.unique_products) as largest_product_catalog,

    max(cs.categories_sold) as highest_category_diversity,

    round(avg(ss.revenue),2) as average_revenue_per_seller

from seller_summary ss

join category_summary cs

    on ss.seller_id = cs.seller_id;
/*
=================================================
section 4 overall observations
=================================================

1. seller product portfolios vary significantly
across the marketplace, ranging from niche
specialists with a small catalog to highly
diversified sellers offering products across
multiple categories.

2. a larger product catalog does not necessarily
translate into higher revenue. some sellers
generate strong revenue from a limited number
of premium or high-demand products, while others
rely on a broader assortment.

3. product concentration analysis reveals that
some sellers depend heavily on a single product
for revenue, increasing their exposure to demand
fluctuations and inventory risks.

4. diversified sellers generally have a more
balanced revenue stream, reducing dependence on
individual products and improving business
stability.

5. the product portfolio matrix identifies four
distinct seller segments:
   • marketplace leaders
   • premium specialists
   • large catalog sellers
   • small sellers

   each segment requires different business
   strategies, such as marketing support,
   inventory optimization, pricing improvements,
   or seller development programs.

6. understanding seller product portfolios helps
the marketplace optimize category management,
strengthen seller partnerships, improve inventory
planning, and identify opportunities for long-term
growth.

=================================================
*/


--------


/*
=================================================
5. seller geographic analysis
=================================================
purpose:
analyze the geographic distribution of sellers
and evaluate regional revenue performance,
seller density, and marketplace coverage.
these insights support expansion planning,
seller acquisition, and regional strategy.
=================================================
*/


/*
=================================================
5.1 sellers by state
=================================================
*/
select

    seller_state,

    count(*) as total_sellers

from olist_sellers_dataset

group by seller_state

order by total_sellers desc;


/*
=================================================
5.2 top 10 seller states
=================================================
*/
with state_sellers as (

    select

        seller_state,

        count(*) as total_sellers

    from olist_sellers_dataset

    group by seller_state

)

select

    dense_rank() over(

        order by total_sellers desc

    ) as state_rank,

    seller_state,

    total_sellers

from state_sellers

limit 10;


/*
=================================================
5.3 sellers by city
=================================================
*/
select

    seller_state,

    seller_city,

    count(*) as total_sellers

from olist_sellers_dataset

group by

    seller_state,

    seller_city

order by

    total_sellers desc;
    
select

    s.seller_state,

    round(sum(oi.price),2) as total_revenue

from olist_order_items_dataset oi

join olist_sellers_dataset s

    on oi.seller_id=s.seller_id

join olist_orders_dataset o

    on oi.order_id=o.order_id

where o.order_status='delivered'

group by s.seller_state

order by total_revenue desc;


/*
=================================================
5.4 revenue by seller state
=================================================
*/
with seller_revenue as (

    select

        s.seller_state,

        oi.seller_id,

        sum(oi.price) as revenue

    from olist_order_items_dataset oi

    join olist_sellers_dataset s

        on oi.seller_id=s.seller_id

    join olist_orders_dataset o

        on oi.order_id=o.order_id

    where o.order_status='delivered'

    group by

        s.seller_state,

        oi.seller_id

)

select

    seller_state,

    round(avg(revenue),2) as average_revenue_per_seller

from seller_revenue

group by seller_state

order by average_revenue_per_seller desc;


/*
=================================================
5.5 average revenue per seller state
=================================================
*/
with state_revenue as (

    select

        s.seller_state,

        sum(oi.price) as revenue

    from olist_order_items_dataset oi

    join olist_sellers_dataset s

        on oi.seller_id=s.seller_id

    join olist_orders_dataset o

        on oi.order_id=o.order_id

    where o.order_status='delivered'

    group by s.seller_state

)

select

    seller_state,

    round(revenue,2) as revenue,

    round(

        revenue*100/

        sum(revenue) over(),

        2

    ) as revenue_percentage

from state_revenue

order by revenue desc;


/*
=================================================
5.6 revenue contribution by seller state
=================================================
*/
with state_revenue as (

    select

        s.seller_state,

        sum(oi.price) as revenue

    from olist_order_items_dataset oi

    join olist_sellers_dataset s

        on oi.seller_id=s.seller_id

    join olist_orders_dataset o

        on oi.order_id=o.order_id

    where o.order_status='delivered'

    group by s.seller_state

)

select

    seller_state,

    round(revenue,2) as revenue,

    round(

        revenue*100/

        sum(revenue) over(),

        2

    ) as revenue_percentage

from state_revenue

order by revenue desc;

/*
=================================================
5.7 seller density analysis
=================================================
*/
with seller_count as (

    select

        seller_state,

        count(*) as sellers

    from olist_sellers_dataset

    group by seller_state

),

customer_count as (

    select

        customer_state,

        count(*) as customers

    from olist_customers_dataset

    group by customer_state

)

select

    c.customer_state,

    c.customers,

    coalesce(s.sellers,0) as sellers,

    round(

        c.customers/

        nullif(s.sellers,0),

        2

    ) as customers_per_seller

from customer_count c

left join seller_count s

on c.customer_state=s.seller_state

order by customers_per_seller desc;

/*
=================================================
5.8 supply vs demand analysis
=================================================
*/
with seller_count as (

    select

        seller_state,

        count(*) as sellers

    from olist_sellers_dataset

    group by seller_state

),

customer_count as (

    select

        customer_state,

        count(*) as customers

    from olist_customers_dataset

    group by customer_state

)

select

    c.customer_state,

    c.customers,

    coalesce(s.sellers,0) as sellers,

    case

        when coalesce(s.sellers,0)=0

            then 'No Seller Presence'

        when c.customers/s.sellers>=50

            then 'Seller Shortage'

        when c.customers/s.sellers>=20

            then 'Balanced'

        else

            'Seller Surplus'

    end as marketplace_status

from customer_count c

left join seller_count s

on c.customer_state=s.seller_state

order by customers desc;


/*
=================================================
5.9 executive summary
=================================================
*/
with seller_summary as (

    select

        s.seller_state,

        count(distinct s.seller_id) as sellers,

        sum(oi.price) as revenue

    from olist_sellers_dataset s

    left join olist_order_items_dataset oi

        on s.seller_id=oi.seller_id

    group by s.seller_state

)

select

    count(*) as seller_states,

    sum(sellers) as total_sellers,

    round(sum(revenue),2) as total_revenue,

    round(avg(sellers),2) as average_sellers_per_state,

    round(avg(revenue),2) as average_state_revenue

from seller_summary;
/*
=================================================
overall observations
=================================================

1. seller distribution is uneven across states,
with a few regions hosting a large proportion of
marketplace sellers.

2. states with higher seller density generally
generate more revenue, although revenue per seller
varies considerably across regions.

3. seller density analysis highlights areas where
customer demand exceeds seller supply, identifying
opportunities for targeted seller acquisition.

4. supply versus demand comparisons reveal regional
imbalances that can guide marketplace expansion,
logistics planning, and marketing investment.

5. improving seller coverage in underserved regions
can reduce delivery distances, improve customer
experience, and strengthen marketplace growth.

=================================================
*/


--------


/*
=================================================
6. seller performance ranking
=================================================
purpose:
evaluate seller performance across multiple
business dimensions including revenue, order
volume, product portfolio, and operational
efficiency. this section builds a comprehensive
seller scorecard to identify top-performing
sellers and support strategic business decisions.
=================================================
*/

/*
=================================================
6.1 revenue ranking
=================================================
*/

with seller_revenue as (

    select

        oi.seller_id,

        round(sum(oi.price),2) as total_revenue,

        count(distinct oi.order_id) as total_orders,

        count(*) as units_sold,

        round(avg(oi.price),2) as average_item_price

    from olist_order_items_dataset oi

    join olist_orders_dataset o

        on oi.order_id = o.order_id

    where o.order_status='delivered'

    group by oi.seller_id

)

select

    dense_rank() over(

        order by total_revenue desc

    ) as revenue_rank,

    seller_id,

    total_revenue,

    total_orders,

    units_sold,

    average_item_price

from seller_revenue

order by
    revenue_rank,
    seller_id;
    
/*
=================================================
6.2 order volume ranking
=================================================
*/

with seller_orders as (

    select

        oi.seller_id,

        count(distinct oi.order_id) as total_orders,

        count(distinct o.customer_id) as customers_served,

        count(*) as units_sold,

        round(

            sum(oi.price) /

            count(distinct oi.order_id),

            2

        ) as average_order_value

    from olist_order_items_dataset oi

    join olist_orders_dataset o

        on oi.order_id = o.order_id

    where o.order_status = 'delivered'

    group by oi.seller_id

)

select

    dense_rank() over(

        order by total_orders desc

    ) as order_rank,

    seller_id,

    total_orders,

    customers_served,

    units_sold,

    average_order_value

from seller_orders

order by

    order_rank,

    seller_id;
    
/*
=================================================
6.3 product portfolio ranking
=================================================
*/

with seller_portfolio as (

    select

        oi.seller_id,

        count(distinct oi.product_id) as unique_products,

        count(

            distinct coalesce(

                pct.product_category_name_english,

                'Unknown'

            )

        ) as categories,

        round(sum(oi.price),2) as revenue

    from olist_order_items_dataset oi

    join olist_orders_dataset o

        on oi.order_id = o.order_id

    join olist_products_dataset p

        on oi.product_id = p.product_id

    left join product_category_name_translation pct

        on p.product_category_name =
           pct.product_category_name

    where o.order_status = 'delivered'

    group by oi.seller_id

)

select

    dense_rank() over(

        order by

            unique_products desc,

            categories desc,

            revenue desc

    ) as portfolio_rank,

    seller_id,

    unique_products,

    categories,

    revenue

from seller_portfolio

order by

    portfolio_rank,

    seller_id;
    
/*
=================================================
6.4 delivery performance ranking
=================================================
*/

with seller_delivery as (

    select

        oi.seller_id,

        count(distinct oi.order_id) as delivered_orders,

        round(

            avg(

                datediff(

                    o.order_delivered_customer_date,

                    o.order_purchase_timestamp

                )

            ),

            2

        ) as average_delivery_days,

        round(

            avg(r.review_score),

            2

        ) as average_review_score

    from olist_order_items_dataset oi

    join olist_orders_dataset o

        on oi.order_id = o.order_id

    left join olist_order_reviews_dataset r

        on oi.order_id = r.order_id

    where

        o.order_status = 'delivered'

        and o.order_delivered_customer_date is not null

    group by oi.seller_id

)

select

    dense_rank() over(

        order by

            average_review_score desc,

            average_delivery_days asc

    ) as delivery_rank,

    seller_id,

    delivered_orders,

    average_delivery_days,

    average_review_score

from seller_delivery

order by

    delivery_rank,

    seller_id;
    
/*
=================================================
6.5 overall seller scorecard
=================================================
*/

with seller_metrics as (

    select

        oi.seller_id,

        round(sum(oi.price),2) as revenue,

        count(distinct oi.order_id) as total_orders,

        count(distinct oi.product_id) as unique_products,

        round(

            avg(

                datediff(

                    o.order_delivered_customer_date,

                    o.order_purchase_timestamp

                )

            ),

            2

        ) as average_delivery_days,

        round(

            avg(r.review_score),

            2

        ) as average_review_score

    from olist_order_items_dataset oi

    join olist_orders_dataset o

        on oi.order_id = o.order_id

    left join olist_order_reviews_dataset r

        on oi.order_id = r.order_id

    where

        o.order_status = 'delivered'

        and o.order_delivered_customer_date is not null

    group by oi.seller_id

),

seller_scores as (

    select

        seller_id,

        revenue,

        total_orders,

        unique_products,

        average_delivery_days,

        average_review_score,

        ntile(5) over(
            order by revenue
        ) as revenue_score,

        ntile(5) over(
            order by total_orders
        ) as order_score,

        ntile(5) over(
            order by unique_products
        ) as product_score,

        ntile(5) over(
            order by average_review_score
        ) as review_score,

        6 -

        ntile(5) over(
            order by average_delivery_days
        ) as delivery_score

    from seller_metrics

)

select

    seller_id,

    revenue,

    total_orders,

    unique_products,

    average_delivery_days,

    average_review_score,

    revenue_score,

    order_score,

    product_score,

    review_score,

    delivery_score,

    (

        revenue_score +

        order_score +

        product_score +

        review_score +

        delivery_score

    ) as overall_score

from seller_scores

order by

    overall_score desc,

    revenue desc;
    
/*
=================================================
6.6 seller tier classification
=================================================
*/

with seller_metrics as (

    select

        oi.seller_id,

        round(sum(oi.price),2) as revenue,

        count(distinct oi.order_id) as total_orders,

        count(distinct oi.product_id) as unique_products,

        round(

            avg(

                datediff(

                    o.order_delivered_customer_date,

                    o.order_purchase_timestamp

                )

            ),

            2

        ) as average_delivery_days,

        round(

            avg(r.review_score),

            2

        ) as average_review_score

    from olist_order_items_dataset oi

    join olist_orders_dataset o

        on oi.order_id = o.order_id

    left join olist_order_reviews_dataset r

        on oi.order_id = r.order_id

    where

        o.order_status = 'delivered'

        and o.order_delivered_customer_date is not null

    group by oi.seller_id

),

seller_scores as (

    select

        seller_id,

        revenue,

        total_orders,

        unique_products,

        average_delivery_days,

        average_review_score,

        ntile(5) over(
            order by revenue
        ) as revenue_score,

        ntile(5) over(
            order by total_orders
        ) as order_score,

        ntile(5) over(
            order by unique_products
        ) as product_score,

        ntile(5) over(
            order by average_review_score
        ) as review_score,

        6 -

        ntile(5) over(
            order by average_delivery_days
        ) as delivery_score

    from seller_metrics

),

final_scores as (

    select

        seller_id,

        revenue,

        total_orders,

        unique_products,

        average_delivery_days,

        average_review_score,

        (

            revenue_score +

            order_score +

            product_score +

            review_score +

            delivery_score

        ) as overall_score

    from seller_scores

)

select

    seller_id,

    revenue,

    total_orders,

    unique_products,

    average_review_score,

    overall_score,

    case

        when overall_score >= 23

            then 'Elite Seller'

        when overall_score >= 19

            then 'Platinum Seller'

        when overall_score >= 15

            then 'Gold Seller'

        when overall_score >= 10

            then 'Silver Seller'

        else 'Bronze Seller'

    end as seller_tier

from final_scores

order by

    overall_score desc,

    revenue desc;
    
/*
=================================================
6.7 executive summary
=================================================
*/

with seller_metrics as (

    select

        oi.seller_id,

        round(sum(oi.price),2) as revenue,

        count(distinct oi.order_id) as total_orders,

        count(distinct oi.product_id) as unique_products,

        round(

            avg(

                datediff(

                    o.order_delivered_customer_date,

                    o.order_purchase_timestamp

                )

            ),

            2

        ) as average_delivery_days,

        round(

            avg(r.review_score),

            2

        ) as average_review_score

    from olist_order_items_dataset oi

    join olist_orders_dataset o

        on oi.order_id = o.order_id

    left join olist_order_reviews_dataset r

        on oi.order_id = r.order_id

    where

        o.order_status = 'delivered'

        and o.order_delivered_customer_date is not null

    group by oi.seller_id

),

seller_scores as (

    select

        seller_id,

        revenue,

        total_orders,

        unique_products,

        average_delivery_days,

        average_review_score,

        ntile(5) over(order by revenue) as revenue_score,

        ntile(5) over(order by total_orders) as order_score,

        ntile(5) over(order by unique_products) as product_score,

        ntile(5) over(order by average_review_score) as review_score,

        6 - ntile(5) over(
            order by average_delivery_days
        ) as delivery_score

    from seller_metrics

),

final_scores as (

    select

        seller_id,

        revenue,

        total_orders,

        unique_products,

        average_delivery_days,

        average_review_score,

        (

            revenue_score +

            order_score +

            product_score +

            review_score +

            delivery_score

        ) as overall_score

    from seller_scores

)

select

    count(*) as active_sellers,

    round(avg(revenue),2) as average_revenue_per_seller,

    round(avg(total_orders),2) as average_orders_per_seller,

    round(avg(unique_products),2) as average_products_per_seller,

    round(avg(average_review_score),2) as average_review_score,

    round(avg(average_delivery_days),2) as average_delivery_days,

    max(overall_score) as highest_score,

    min(overall_score) as lowest_score,

    round(avg(overall_score),2) as average_score

from final_scores;
/*
=================================================
observations
=================================================

1. seller performance should be evaluated using
multiple dimensions rather than revenue alone,
as financial success does not always reflect
operational excellence or customer satisfaction.

2. the seller scorecard combines revenue, order
volume, product portfolio strength, delivery
performance, and customer reviews to provide a
balanced assessment of seller performance.

3. top-performing sellers consistently achieve
strong results across all key business metrics
=================================================
*/


--------


/*
=================================================
7. seller delivery performance
=================================================
purpose:
evaluate seller operational performance by
measuring delivery speed, on-time delivery,
and delivery reliability. these insights help
identify efficient sellers, monitor logistics
performance, and improve customer satisfaction.
=================================================
*/


/*
=================================================
7.1 average delivery time by seller
=================================================
*/

select

    oi.seller_id,

    count(distinct oi.order_id) as delivered_orders,

    round(

        avg(

            datediff(

                o.order_delivered_customer_date,

                o.order_purchase_timestamp

            )

        ),

        2

    ) as average_delivery_days

from olist_order_items_dataset oi

join olist_orders_dataset o

    on oi.order_id = o.order_id

where

    o.order_status='delivered'

    and o.order_delivered_customer_date is not null

group by oi.seller_id

order by

    average_delivery_days,
    delivered_orders desc;
    
/*
=================================================
7.2 on-time delivery rate
=================================================
*/

with seller_delivery as (

    select

        oi.seller_id,

        count(distinct oi.order_id) as total_deliveries,

        sum(

            case

                when o.order_delivered_customer_date
                     <= o.order_estimated_delivery_date

                then 1

                else 0

            end

        ) as on_time_deliveries

    from olist_order_items_dataset oi

    join olist_orders_dataset o

        on oi.order_id=o.order_id

    where

        o.order_status='delivered'

        and o.order_delivered_customer_date is not null

        and o.order_estimated_delivery_date is not null

    group by oi.seller_id

)

select

    seller_id,

    total_deliveries,

    on_time_deliveries,

    round(

        on_time_deliveries*100.0/

        total_deliveries,

        2

    ) as on_time_delivery_rate

from seller_delivery

order by

    on_time_delivery_rate desc,
    total_deliveries desc;
    
/*
=================================================
7.3 late delivery rate
=================================================
*/

with seller_delivery as (

    select

        oi.seller_id,

        count(distinct oi.order_id) as total_deliveries,

        sum(

            case

                when o.order_delivered_customer_date
                     > o.order_estimated_delivery_date

                then 1

                else 0

            end

        ) as late_deliveries

    from olist_order_items_dataset oi

    join olist_orders_dataset o

        on oi.order_id=o.order_id

    where

        o.order_status='delivered'

        and o.order_delivered_customer_date is not null

        and o.order_estimated_delivery_date is not null

    group by oi.seller_id

)

select

    seller_id,

    total_deliveries,

    late_deliveries,

    round(

        late_deliveries*100.0/

        total_deliveries,

        2

    ) as late_delivery_rate

from seller_delivery

order by

    late_delivery_rate desc,
    total_deliveries desc;
    
/*
=================================================
7.4 fastest sellers
=================================================
*/

with seller_delivery as (

    select

        oi.seller_id,

        count(distinct oi.order_id) as delivered_orders,

        round(

            avg(

                datediff(

                    o.order_delivered_customer_date,

                    o.order_purchase_timestamp

                )

            ),

            2

        ) as average_delivery_days

    from olist_order_items_dataset oi

    join olist_orders_dataset o

        on oi.order_id = o.order_id

    where

        o.order_status = 'delivered'

        and o.order_delivered_customer_date is not null

    group by oi.seller_id

)

select

    dense_rank() over(

        order by average_delivery_days asc

    ) as delivery_rank,

    seller_id,

    delivered_orders,

    average_delivery_days

from seller_delivery

order by

    delivery_rank,
    seller_id

limit 20;

/*
=================================================
7.5 slowest sellers
=================================================
*/

with seller_delivery as (

    select

        oi.seller_id,

        count(distinct oi.order_id) as delivered_orders,

        round(

            avg(

                datediff(

                    o.order_delivered_customer_date,

                    o.order_purchase_timestamp

                )

            ),

            2

        ) as average_delivery_days

    from olist_order_items_dataset oi

    join olist_orders_dataset o

        on oi.order_id = o.order_id

    where

        o.order_status = 'delivered'

        and o.order_delivered_customer_date is not null

    group by oi.seller_id

)

select

    dense_rank() over(

        order by average_delivery_days desc

    ) as delivery_rank,

    seller_id,

    delivered_orders,

    average_delivery_days

from seller_delivery

order by

    delivery_rank,
    seller_id

limit 20;


/*
=================================================
7.6 seller delivery scorecard
=================================================
*/

with seller_delivery as (

    select

        oi.seller_id,

        count(distinct oi.order_id) as delivered_orders,

        round(

            avg(

                datediff(

                    o.order_delivered_customer_date,

                    o.order_purchase_timestamp

                )

            ),

            2

        ) as average_delivery_days,

        round(

            avg(r.review_score),

            2

        ) as average_review_score,

        round(

            sum(

                case

                    when o.order_delivered_customer_date
                         <= o.order_estimated_delivery_date

                    then 1

                    else 0

                end

            ) * 100.0 /

            count(distinct oi.order_id),

            2

        ) as on_time_delivery_rate

    from olist_order_items_dataset oi

    join olist_orders_dataset o

        on oi.order_id = o.order_id

    left join olist_order_reviews_dataset r

        on oi.order_id = r.order_id

    where

        o.order_status = 'delivered'

        and o.order_delivered_customer_date is not null

        and o.order_estimated_delivery_date is not null

    group by oi.seller_id

),

scores as (

    select

        seller_id,

        delivered_orders,

        average_delivery_days,

        average_review_score,

        on_time_delivery_rate,

        6 -

        ntile(5) over(

            order by average_delivery_days

        ) as delivery_speed_score,

        ntile(5) over(

            order by on_time_delivery_rate

        ) as on_time_score,

        ntile(5) over(

            order by average_review_score

        ) as review_score

    from seller_delivery

)

select

    seller_id,

    delivered_orders,

    average_delivery_days,

    on_time_delivery_rate,

    average_review_score,

    delivery_speed_score,

    on_time_score,

    review_score,

    (

        delivery_speed_score +

        on_time_score +

        review_score

    ) as delivery_score

from scores

order by

    delivery_score desc,

    on_time_delivery_rate desc,

    average_delivery_days asc;
    
/*
=================================================
7.7 executive summary
=================================================
*/

with seller_delivery as (

    select

        oi.seller_id,

        count(distinct oi.order_id) as delivered_orders,

        round(

            avg(

                datediff(

                    o.order_delivered_customer_date,

                    o.order_purchase_timestamp

                )

            ),

            2

        ) as average_delivery_days,

        round(

            avg(r.review_score),

            2

        ) as average_review_score,

        round(

            sum(

                case

                    when o.order_delivered_customer_date
                         <= o.order_estimated_delivery_date

                    then 1

                    else 0

                end

            ) * 100.0 /

            count(distinct oi.order_id),

            2

        ) as on_time_delivery_rate

    from olist_order_items_dataset oi

    join olist_orders_dataset o

        on oi.order_id = o.order_id

    left join olist_order_reviews_dataset r

        on oi.order_id = r.order_id

    where

        o.order_status = 'delivered'

        and o.order_delivered_customer_date is not null

        and o.order_estimated_delivery_date is not null

    group by oi.seller_id

)

select

    count(*) as active_sellers,

    sum(delivered_orders) as total_delivered_orders,

    round(avg(average_delivery_days),2) as average_delivery_days,

    round(avg(on_time_delivery_rate),2) as average_on_time_delivery_rate,

    round(avg(average_review_score),2) as average_review_score,

    min(average_delivery_days) as fastest_average_delivery,

    max(average_delivery_days) as slowest_average_delivery,

    max(on_time_delivery_rate) as highest_on_time_rate,

    min(on_time_delivery_rate) as lowest_on_time_rate

from seller_delivery;
/*
=================================================
observations
=================================================

1. seller delivery performance varies across the
marketplace, indicating differences in logistics
efficiency and operational execution.

2. sellers with shorter delivery times generally
provide a better customer experience, but delivery
speed should be evaluated alongside on-time
delivery performance and customer reviews.

3. on-time delivery is a critical operational KPI
that directly influences customer satisfaction,
repeat purchases, and seller reputation.

4. the seller delivery scorecard combines delivery
speed, reliability, and customer feedback to
provide a balanced assessment of logistics
performance.

5. identifying both the fastest and slowest
sellers enables the marketplace to recognize
operational excellence while targeting logistics
improvements for underperforming sellers.

6. these insights support better seller
performance management, logistics optimization,
and long-term improvements in marketplace service
quality.

=================================================
*/


--------


/*
=================================================
8. seller concentration analysis
=================================================
purpose:
evaluate how marketplace revenue is distributed
among sellers to identify market concentration,
competitive intensity, and dependency on key
sellers. these insights support marketplace
strategy, seller acquisition, and risk management.
=================================================
*/


/*
=================================================
8.1 revenue contribution by seller
=================================================
*/

with seller_revenue as (

    select

        oi.seller_id,

        round(sum(oi.price),2) as revenue

    from olist_order_items_dataset oi

    join olist_orders_dataset o

        on oi.order_id = o.order_id

    where o.order_status = 'delivered'

    group by oi.seller_id

)

select

    dense_rank() over(

        order by revenue desc

    ) as revenue_rank,

    seller_id,

    revenue,

    round(

        revenue * 100 /

        sum(revenue) over(),

        2

    ) as revenue_contribution_percent

from seller_revenue

order by revenue desc;


/*
=================================================
8.2 top 10 sellers' revenue share
=================================================
*/

with seller_revenue as (

    select

        oi.seller_id,

        sum(oi.price) as revenue

    from olist_order_items_dataset oi

    join olist_orders_dataset o

        on oi.order_id = o.order_id

    where o.order_status = 'delivered'

    group by oi.seller_id

),

ranked_sellers as (

    select

        seller_id,

        revenue,

        dense_rank() over(

            order by revenue desc

        ) as seller_rank

    from seller_revenue

)

select

    round(

        sum(

            case

                when seller_rank <= 10

                then revenue

                else 0

            end

        ),

        2

    ) as top_10_revenue,

    round(

        sum(revenue),

        2

    ) as total_marketplace_revenue,

    round(

        sum(

            case

                when seller_rank <= 10

                then revenue

                else 0

            end

        ) * 100 /

        sum(revenue),

        2

    ) as top_10_revenue_share_percent

from ranked_sellers;

/*
=================================================
8.3 pareto analysis (80/20 rule)
=================================================
*/

with seller_revenue as (

    select

        oi.seller_id,

        round(sum(oi.price),2) as revenue

    from olist_order_items_dataset oi

    join olist_orders_dataset o

        on oi.order_id = o.order_id

    where o.order_status = 'delivered'

    group by oi.seller_id

),

pareto as (

    select

        seller_id,

        revenue,

        sum(revenue) over(

            order by revenue desc

        ) as cumulative_revenue,

        sum(revenue) over() as total_revenue,

        row_number() over(

            order by revenue desc

        ) as seller_rank,

        count(*) over() as total_sellers

    from seller_revenue

)

select

    seller_rank,

    seller_id,

    revenue,

    round(

        cumulative_revenue,

        2

    ) as cumulative_revenue,

    round(

        cumulative_revenue * 100 /

        total_revenue,

        2

    ) as cumulative_revenue_percent,

    round(

        seller_rank * 100 /

        total_sellers,

        2

    ) as cumulative_seller_percent

from pareto

order by seller_rank;

/*
=================================================
8.4 revenue concentration by product category
=================================================
*/

with seller_category_revenue as (

    select

        pct.product_category_name_english as category,

        oi.seller_id,

        round(sum(oi.price),2) as revenue

    from olist_order_items_dataset oi

    join olist_orders_dataset o

        on oi.order_id = o.order_id

    join olist_products_dataset p

        on oi.product_id = p.product_id

    left join product_category_name_translation pct

        on p.product_category_name =
           pct.product_category_name

    where o.order_status = 'delivered'

    group by

        pct.product_category_name_english,

        oi.seller_id

),

ranked as (

    select

        category,

        seller_id,

        revenue,

        dense_rank() over(

            partition by category

            order by revenue desc

        ) as revenue_rank

    from seller_category_revenue

)

select

    category,

    seller_id,

    revenue,

    revenue_rank

from ranked

where revenue_rank <= 5

order by

    category,

    revenue_rank;
    
/*
=================================================
8.5 revenue concentration by seller state
=================================================
*/

with seller_state_revenue as (

    select

        s.seller_state,

        oi.seller_id,

        round(sum(oi.price),2) as revenue

    from olist_order_items_dataset oi

    join olist_orders_dataset o

        on oi.order_id = o.order_id

    join olist_sellers_dataset s

        on oi.seller_id = s.seller_id

    where o.order_status='delivered'

    group by

        s.seller_state,

        oi.seller_id

),

ranked as (

    select

        seller_state,

        seller_id,

        revenue,

        dense_rank() over(

            partition by seller_state

            order by revenue desc

        ) as revenue_rank

    from seller_state_revenue

)

select

    seller_state,

    seller_id,

    revenue,

    revenue_rank

from ranked

where revenue_rank<=5

order by

    seller_state,

    revenue_rank;
    
/*
=================================================
8.6 marketplace competition index
=================================================
*/

with category_summary as (

    select

        pct.product_category_name_english as category,

        count(

            distinct oi.seller_id

        ) as sellers,

        round(

            sum(oi.price),

            2

        ) as revenue

    from olist_order_items_dataset oi

    join olist_orders_dataset o

        on oi.order_id=o.order_id

    join olist_products_dataset p

        on oi.product_id=p.product_id

    left join product_category_name_translation pct

        on p.product_category_name=
           pct.product_category_name

    where o.order_status='delivered'

    group by

        pct.product_category_name_english

)

select

    category,

    sellers,

    revenue,

    round(

        revenue/sellers,

        2

    ) as revenue_per_seller,

    case

        when sellers>=200

            then 'Highly Competitive'

        when sellers>=100

            then 'Competitive'

        when sellers>=50

            then 'Moderately Competitive'

        else

            'Low Competition'

    end as competition_level

from category_summary

order by

    sellers desc,

    revenue desc;
    
/*
=================================================
8.7 executive summary
=================================================
*/

with seller_revenue as (

    select

        oi.seller_id,

        sum(oi.price) as revenue

    from olist_order_items_dataset oi

    join olist_orders_dataset o

        on oi.order_id = o.order_id

    where o.order_status = 'delivered'

    group by oi.seller_id

),

category_summary as (

    select

        pct.product_category_name_english as category,

        count(distinct oi.seller_id) as sellers,

        sum(oi.price) as revenue

    from olist_order_items_dataset oi

    join olist_orders_dataset o

        on oi.order_id = o.order_id

    join olist_products_dataset p

        on oi.product_id = p.product_id

    left join product_category_name_translation pct

        on p.product_category_name =
           pct.product_category_name

    where o.order_status = 'delivered'

    group by pct.product_category_name_english

),

top10 as (

    select

        revenue

    from seller_revenue

    order by revenue desc

    limit 10

)

select

    (select count(*) from seller_revenue)
        as active_sellers,

    round(

        (select sum(revenue) from seller_revenue),

        2

    ) as total_marketplace_revenue,

    round(

        (select avg(revenue) from seller_revenue),

        2

    ) as average_revenue_per_seller,

    round(

        (select sum(revenue) from top10),

        2

    ) as top_10_seller_revenue,

    round(

        (select sum(revenue) from top10)

        *100/

        (select sum(revenue) from seller_revenue),

        2

    ) as top_10_revenue_share_percent,

    (select max(sellers)

     from category_summary)

     as highest_seller_count_in_category,

    (select count(*)

     from category_summary)

     as total_product_categories;
     
    /*
=================================================
observations
=================================================

1. seller revenue is concentrated among a limited
number of sellers, indicating that a relatively
small group contributes a significant share of
marketplace revenue.

2. the top sellers represent critical business
partners whose performance has a substantial
impact on overall marketplace success.

3. competition levels vary across product
categories and geographic regions, with some
markets dominated by only a few sellers while
others exhibit broader seller participation.

4. categories with low competition present
opportunities for targeted seller acquisition,
while highly concentrated categories require
careful monitoring to reduce marketplace risk.

5. understanding seller concentration supports
better marketplace strategy by balancing seller
growth, regional expansion, competitive
positioning, and long-term revenue stability.

6. concentration analysis complements revenue
and performance rankings by revealing the overall
structure and competitive health of the
marketplace.

=================================================
*/


--------


/*
=================================================
9. executive summary
=================================================

purpose:
provide executives with a consolidated view of
seller performance, marketplace concentration,
geographic distribution, and operational efficiency
to support strategic decision-making.
=================================================
*/


/*
=================================================
9.1 marketplace seller kpis
=================================================
*/

with seller_summary as (

    select

        oi.seller_id,

        sum(oi.price) as revenue,

        count(distinct oi.order_id) as orders,

        count(distinct oi.product_id) as products

    from olist_order_items_dataset oi

    join olist_orders_dataset o

        on oi.order_id = o.order_id

    where o.order_status = 'delivered'

    group by oi.seller_id

)

select

    count(*) as active_sellers,

    round(sum(revenue),2) as total_revenue,

    round(avg(revenue),2) as average_revenue_per_seller,

    round(avg(orders),2) as average_orders_per_seller,

    round(avg(products),2) as average_products_per_seller

from seller_summary;

/*
=================================================
9.2 top performing seller
=================================================
*/

select

    oi.seller_id,

    round(sum(oi.price),2) as total_revenue,

    count(distinct oi.order_id) as total_orders,

    count(distinct oi.product_id) as products_sold

from olist_order_items_dataset oi

join olist_orders_dataset o

    on oi.order_id = o.order_id

where o.order_status = 'delivered'

group by oi.seller_id

order by total_revenue desc

limit 1;

/*
=================================================
9.3 best performing seller state
=================================================
*/

select

    s.seller_state,

    round(sum(oi.price),2) as total_revenue,

    count(distinct oi.seller_id) as active_sellers

from olist_order_items_dataset oi

join olist_orders_dataset o

    on oi.order_id = o.order_id

join olist_sellers_dataset s

    on oi.seller_id = s.seller_id

where o.order_status = 'delivered'

group by s.seller_state

order by total_revenue desc

limit 1;

/*
=================================================
9.4 delivery performance summary
=================================================
*/

select

    round(

        avg(

            datediff(

                order_delivered_customer_date,

                order_purchase_timestamp

            )

        ),

        2

    ) as average_delivery_days,

    round(

        sum(

            case

                when order_delivered_customer_date
                     <= order_estimated_delivery_date

                then 1

                else 0

            end

        ) *100/

        count(*),

        2

    ) as on_time_delivery_rate

from olist_orders_dataset

where

    order_status='delivered'

    and order_delivered_customer_date is not null

    and order_estimated_delivery_date is not null;
    
    /*
=================================================
9.5 marketplace competition summary
=================================================
*/

with seller_revenue as (

    select

        seller_id,

        sum(price) as revenue

    from olist_order_items_dataset

    group by seller_id

),

top10 as (

    select

        revenue

    from seller_revenue

    order by revenue desc

    limit 10

)

select

    round(

        (select sum(revenue) from top10),

        2

    ) as top_10_revenue,

    round(

        (select sum(revenue) from seller_revenue),

        2

    ) as total_revenue,

    round(

        (select sum(revenue) from top10)

        *100/

        (select sum(revenue) from seller_revenue),

        2

    ) as top_10_revenue_share_percent;
    
/*
=================================================
9.6 strategic business recommendations
=================================================

1. strengthen partnerships with top-performing
sellers through exclusive campaigns, incentives,
and long-term collaboration.

2. recruit additional sellers in regions with
high customer demand but limited seller presence
to improve marketplace coverage.

3. support lower-performing sellers with training,
pricing guidance, and inventory optimization to
improve overall marketplace quality.

4. continuously monitor delivery performance to
maintain high customer satisfaction and reduce
late deliveries.

5. encourage product diversification among
specialized sellers to reduce dependency on a
small number of products.

6. reduce marketplace risk by decreasing revenue
concentration among a few dominant sellers through
targeted seller acquisition and category expansion.

=================================================
*/

/*
=================================================
observation
=================================================

1. the marketplace consists of a diverse network
of sellers with significant variation in revenue,
order volume, product portfolio size, and
operational performance.

2. a relatively small group of sellers contributes
a substantial share of total marketplace revenue,
highlighting the importance of monitoring seller
concentration and reducing dependency risk.

3. seller performance should be evaluated using
multiple dimensions, including financial results,
customer reach, product diversity, delivery
efficiency, and customer satisfaction.

4. geographic analysis reveals opportunities to
expand seller acquisition efforts in underserved
regions while strengthening existing high-
performing markets.

5. delivery performance remains a critical driver
of customer experience. sellers with fast and
reliable deliveries contribute to higher customer
satisfaction and marketplace trust.

6. product portfolio analysis shows that
diversified sellers are generally more resilient,
while highly specialized sellers may require
additional support to sustain long-term growth.

7. overall, the marketplace demonstrates strong
growth potential through balanced seller
development, operational excellence, geographic
expansion, and continuous performance monitoring.

=================================================
*/







-------------------------------------------------------------------------------------------










/*
=================================================
Project: Brazilian E-Commerce (Olist) Analysis
File: 07_Logistics_Analysis.sql
=================================================
purpose:
analyze the marketplace's logistics performance
by evaluating delivery speed, delivery accuracy,
shipping costs, regional efficiency, and
operational reliability. this analysis helps
identify delivery bottlenecks, optimize shipping
operations, improve customer satisfaction, and
support data-driven logistics decisions across
the marketplace.
Dataset:
    Olist Brazilian E-Commerce Public Dataset
=================================================
*/




/*
=================================================
1. logistics overview
=================================================
purpose:
evaluate the overall logistics performance of the
marketplace by measuring delivery speed,
delivery reliability, and fulfillment efficiency.
these KPIs provide a baseline for identifying
operational strengths and improvement
opportunities across the delivery network.
=================================================
*/

/*
=================================================
1.1 delivered orders
=================================================
*/

select

    count(*) as delivered_orders

from olist_orders_dataset

where order_status = 'delivered';

/*
=================================================
1.2 average delivery time
=================================================
*/

select

    round(

        avg(

            datediff(

                order_delivered_customer_date,

                order_purchase_timestamp

            )

        ),

        2

    ) as average_delivery_days

from olist_orders_dataset

where

    order_status = 'delivered'

    and order_delivered_customer_date is not null;
    
/*
=================================================
1.3 average estimated delivery time
=================================================
*/

select

    round(

        avg(

            datediff(

                order_estimated_delivery_date,

                order_purchase_timestamp

            )

        ),

        2

    ) as average_estimated_delivery_days

from olist_orders_dataset

where

    order_status = 'delivered'

    and order_estimated_delivery_date is not null;
    
/*
=================================================
1.4 on-time delivery rate
=================================================
*/

select

    count(*) as delivered_orders,

    sum(

        case

            when order_delivered_customer_date
                 <= order_estimated_delivery_date

            then 1

            else 0

        end

    ) as on_time_orders,

    round(

        sum(

            case

                when order_delivered_customer_date
                     <= order_estimated_delivery_date

                then 1

                else 0

            end

        ) * 100 /

        count(*),

        2

    ) as on_time_delivery_rate

from olist_orders_dataset

where

    order_status = 'delivered'

    and order_delivered_customer_date is not null

    and order_estimated_delivery_date is not null;
    
/*
=================================================
1.5 late delivery rate
=================================================
*/

select

    count(*) as delivered_orders,

    sum(

        case

            when order_delivered_customer_date
                 > order_estimated_delivery_date

            then 1

            else 0

        end

    ) as late_orders,

    round(

        sum(

            case

                when order_delivered_customer_date
                     > order_estimated_delivery_date

                then 1

                else 0

            end

        ) * 100 /

        count(*),

        2

    ) as late_delivery_rate

from olist_orders_dataset

where

    order_status = 'delivered'

    and order_delivered_customer_date is not null

    and order_estimated_delivery_date is not null;

/*
=================================================
1.6 executive summary
=================================================
*/

select

    count(*) as delivered_orders,

    round(

        avg(

            datediff(

                order_delivered_customer_date,

                order_purchase_timestamp

            )

        ),

        2

    ) as average_delivery_days,

    round(

        avg(

            datediff(

                order_estimated_delivery_date,

                order_purchase_timestamp

            )

        ),

        2

    ) as average_estimated_delivery_days,

    round(

        sum(

            case

                when order_delivered_customer_date
                     <= order_estimated_delivery_date

                then 1

                else 0

            end

        ) * 100 /

        count(*),

        2

    ) as on_time_delivery_rate,

    round(

        sum(

            case

                when order_delivered_customer_date
                     > order_estimated_delivery_date

                then 1

                else 0

            end

        ) * 100 /

        count(*),

        2

    ) as late_delivery_rate

from olist_orders_dataset

where

    order_status = 'delivered'

    and order_delivered_customer_date is not null

    and order_estimated_delivery_date is not null;
    
/*
=================================================
overall observations
=================================================

1. delivered orders provide the baseline volume
for evaluating logistics performance across the
marketplace.

2. comparing actual delivery time with estimated
delivery time helps assess the effectiveness of
delivery planning and operational execution.

3. a high on-time delivery rate indicates strong
logistics performance and contributes positively
to customer satisfaction and marketplace trust.

4. late deliveries highlight potential
inefficiencies in fulfillment or transportation
that may require operational improvements.

5. these logistics KPIs establish the foundation
for deeper analyses of delivery delays, freight
costs, regional performance, and carrier
efficiency in subsequent sections.

=================================================
*/


--------


/*
=================================================
2. delivery time analysis
=================================================
purpose:
analyze delivery time performance by examining
delivery distributions, identifying exceptional
cases, monitoring monthly trends, and detecting
delivery outliers. these insights help improve
logistics efficiency, customer satisfaction, and
operational planning.
=================================================
*/

/*
=================================================
2.1 delivery time distribution
=================================================
*/

select

    case

        when datediff(
                order_delivered_customer_date,
                order_purchase_timestamp
             ) <= 3
            then '0-3 Days'

        when datediff(
                order_delivered_customer_date,
                order_purchase_timestamp
             ) <= 7
            then '4-7 Days'

        when datediff(
                order_delivered_customer_date,
                order_purchase_timestamp
             ) <= 14
            then '8-14 Days'

        when datediff(
                order_delivered_customer_date,
                order_purchase_timestamp
             ) <= 21
            then '15-21 Days'

        else '>21 Days'

    end as delivery_time_bucket,

    count(*) as orders,

    round(

        count(*) *100/

        sum(count(*)) over(),

        2

    ) as percentage

from olist_orders_dataset

where

    order_status='delivered'

    and order_delivered_customer_date is not null

group by delivery_time_bucket

order by

case delivery_time_bucket

    when '0-3 Days' then 1
    when '4-7 Days' then 2
    when '8-14 Days' then 3
    when '15-21 Days' then 4
    else 5

end;

/*
=================================================
2.2 fastest deliveries
=================================================
*/

select

    order_id,

    customer_id,

    order_purchase_timestamp,

    order_delivered_customer_date,

    datediff(

        order_delivered_customer_date,

        order_purchase_timestamp

    ) as delivery_days

from olist_orders_dataset

where

    order_status='delivered'

    and order_delivered_customer_date is not null

order by

    delivery_days,

    order_purchase_timestamp

limit 20;

/*
=================================================
2.3 slowest deliveries
=================================================
*/

select

    order_id,

    customer_id,

    order_purchase_timestamp,

    order_delivered_customer_date,

    datediff(

        order_delivered_customer_date,

        order_purchase_timestamp

    ) as delivery_days

from olist_orders_dataset

where

    order_status='delivered'

    and order_delivered_customer_date is not null

order by

    delivery_days desc

limit 20;

/*
=================================================
2.4 monthly average delivery time
=================================================
*/

select

    date_format(

        order_purchase_timestamp,

        '%Y-%m'

    ) as purchase_month,

    count(*) as delivered_orders,

    round(

        avg(

            datediff(

                order_delivered_customer_date,

                order_purchase_timestamp

            )

        ),

        2

    ) as average_delivery_days

from olist_orders_dataset

where

    order_status='delivered'

    and order_delivered_customer_date is not null

group by purchase_month

order by purchase_month;

/*
=================================================
2.5 delivery time by order status
=================================================
*/

select

    order_status,

    count(*) as total_orders,

    round(

        avg(

            datediff(

                order_delivered_customer_date,

                order_purchase_timestamp

            )

        ),

        2

    ) as average_delivery_days

from olist_orders_dataset

where

    order_delivered_customer_date is not null

group by order_status

order by total_orders desc;

/*
=================================================
2.6 delivery time outliers
=================================================
*/

select

    order_id,

    customer_id,

    order_purchase_timestamp,

    order_delivered_customer_date,

    datediff(

        order_delivered_customer_date,

        order_purchase_timestamp

    ) as delivery_days

from olist_orders_dataset

where

    order_status='delivered'

    and order_delivered_customer_date is not null

    and datediff(

            order_delivered_customer_date,

            order_purchase_timestamp

        ) > 30

order by delivery_days desc;

/*
=================================================
2.7 executive summary
=================================================
*/

select

    count(*) as delivered_orders,

    round(

        avg(

            datediff(

                order_delivered_customer_date,

                order_purchase_timestamp

            )

        ),

        2

    ) as average_delivery_days,

    min(

        datediff(

            order_delivered_customer_date,

            order_purchase_timestamp

        )

    ) as fastest_delivery,

    max(

        datediff(

            order_delivered_customer_date,

            order_purchase_timestamp

        )

    ) as slowest_delivery,

    sum(

        case

            when datediff(

                    order_delivered_customer_date,

                    order_purchase_timestamp

                 ) > 30

            then 1

            else 0

        end

    ) as delivery_outliers

from olist_orders_dataset

where

    order_status='delivered'

    and order_delivered_customer_date is not null;
    
/*
=================================================
overall observations
=================================================

1. most deliveries are completed within the
expected delivery window, while a relatively
small proportion experience extended delays.

2. analyzing the distribution of delivery times
provides more meaningful operational insight than
relying solely on the average delivery time.

3. monthly delivery trends help identify seasonal
changes in logistics performance and operational
capacity.

4. extreme delivery cases should be investigated
to identify recurring operational bottlenecks,
carrier issues, or regional challenges.

5. continuous monitoring of delivery time
performance supports improved customer
satisfaction and more efficient logistics
operations.

=================================================
*/


--------


/*
=================================================
3. delivery delay analysis
=================================================
purpose:
evaluate delivery performance against promised
delivery dates by measuring delivery delays,
identifying operational bottlenecks, and
quantifying the severity of late deliveries.
these insights help improve logistics planning,
customer satisfaction, and operational efficiency.
=================================================
*/

/*
=================================================
3.1 delivery delay distribution
=================================================
*/

select

    case

        when datediff(

                order_delivered_customer_date,

                order_estimated_delivery_date

             ) <= -5

            then '5+ Days Early'

        when datediff(

                order_delivered_customer_date,

                order_estimated_delivery_date

             ) between -4 and -1

            then '1-4 Days Early'

        when datediff(

                order_delivered_customer_date,

                order_estimated_delivery_date

             ) = 0

            then 'On Time'

        when datediff(

                order_delivered_customer_date,

                order_estimated_delivery_date

             ) between 1 and 5

            then '1-5 Days Late'

        when datediff(

                order_delivered_customer_date,

                order_estimated_delivery_date

             ) between 6 and 10

            then '6-10 Days Late'

        else

            'More Than 10 Days Late'

    end as delay_bucket,

    count(*) as total_orders,

    round(

        count(*) *100/

        sum(count(*)) over(),

        2

    ) as percentage

from olist_orders_dataset

where

    order_status='delivered'

    and order_delivered_customer_date is not null

    and order_estimated_delivery_date is not null

group by delay_bucket

order by

case delay_bucket

    when '5+ Days Early' then 1
    when '1-4 Days Early' then 2
    when 'On Time' then 3
    when '1-5 Days Late' then 4
    when '6-10 Days Late' then 5
    else 6

end;

/*
=================================================
3.2 average delivery delay
=================================================
*/

select

    round(

        avg(

            datediff(

                order_delivered_customer_date,

                order_estimated_delivery_date

            )

        ),

        2

    ) as average_delivery_delay_days

from olist_orders_dataset

where

    order_status='delivered'

    and order_delivered_customer_date is not null

    and order_estimated_delivery_date is not null;
    
/*
=================================================
3.3 early vs on-time vs late deliveries
=================================================
*/

select

    case

        when order_delivered_customer_date
             < order_estimated_delivery_date

            then 'Early'

        when order_delivered_customer_date
             = order_estimated_delivery_date

            then 'On Time'

        else

            'Late'

    end as delivery_status,

    count(*) as total_orders,

    round(

        count(*) *100/

        sum(count(*)) over(),

        2

    ) as percentage

from olist_orders_dataset

where

    order_status='delivered'

    and order_delivered_customer_date is not null

    and order_estimated_delivery_date is not null

group by delivery_status

order by total_orders desc;

/*
=================================================
3.4 delay severity analysis
=================================================
*/

select

    case

        when datediff(

                order_delivered_customer_date,

                order_estimated_delivery_date

             ) <= 0

            then 'No Delay'

        when datediff(

                order_delivered_customer_date,

                order_estimated_delivery_date

             ) between 1 and 3

            then 'Minor Delay'

        when datediff(

                order_delivered_customer_date,

                order_estimated_delivery_date

             ) between 4 and 7

            then 'Moderate Delay'

        when datediff(

                order_delivered_customer_date,

                order_estimated_delivery_date

             ) between 8 and 14

            then 'Major Delay'

        else

            'Critical Delay'

    end as delay_severity,

    count(*) as total_orders,

    round(

        count(*) *100/

        sum(count(*)) over(),

        2

    ) as percentage

from olist_orders_dataset

where

    order_status='delivered'

    and order_delivered_customer_date is not null

    and order_estimated_delivery_date is not null

group by delay_severity

order by

case delay_severity

    when 'No Delay' then 1
    when 'Minor Delay' then 2
    when 'Moderate Delay' then 3
    when 'Major Delay' then 4
    else 5

end;

/*
=================================================
3.5 monthly delay trend
=================================================
*/

select

    date_format(

        order_purchase_timestamp,

        '%Y-%m'

    ) as purchase_month,

    count(*) as delivered_orders,

    round(

        avg(

            datediff(

                order_delivered_customer_date,

                order_estimated_delivery_date

            )

        ),

        2

    ) as average_delay_days,

    round(

        sum(

            case

                when order_delivered_customer_date
                     <= order_estimated_delivery_date

                then 1

                else 0

            end

        ) *100/

        count(*),

        2

    ) as on_time_rate

from olist_orders_dataset

where

    order_status='delivered'

    and order_delivered_customer_date is not null

    and order_estimated_delivery_date is not null

group by purchase_month

order by purchase_month;

/*
=================================================
3.6 delay analysis by state
=================================================
*/

select

    c.customer_state,

    count(*) as delivered_orders,

    round(

        avg(

            datediff(

                o.order_delivered_customer_date,

                o.order_estimated_delivery_date

            )

        ),

        2

    ) as average_delay_days,

    round(

        sum(

            case

                when o.order_delivered_customer_date
                     <= o.order_estimated_delivery_date

                then 1

                else 0

            end

        ) *100/

        count(*),

        2

    ) as on_time_rate

from olist_orders_dataset o

join olist_customers_dataset c

    on o.customer_id = c.customer_id

where

    o.order_status='delivered'

    and o.order_delivered_customer_date is not null

    and o.order_estimated_delivery_date is not null

group by

    c.customer_state

order by

    average_delay_days desc;
    
/*
=================================================
3.7 delay analysis by seller
=================================================
*/

select

    oi.seller_id,

    count(

        distinct oi.order_id

    ) as delivered_orders,

    round(

        avg(

            datediff(

                o.order_delivered_customer_date,

                o.order_estimated_delivery_date

            )

        ),

        2

    ) as average_delay_days,

    round(

        sum(

            case

                when o.order_delivered_customer_date
                     <= o.order_estimated_delivery_date

                then 1

                else 0

            end

        ) *100/

        count(

            distinct oi.order_id

        ),

        2

    ) as on_time_rate

from olist_order_items_dataset oi

join olist_orders_dataset o

    on oi.order_id = o.order_id

where

    o.order_status='delivered'

    and o.order_delivered_customer_date is not null

    and o.order_estimated_delivery_date is not null

group by

    oi.seller_id

having

    delivered_orders >= 20

order by

    average_delay_days desc,

    delivered_orders desc;
    
/*
=================================================
3.8 executive summary
=================================================
*/

select

    count(*) as delivered_orders,

    round(

        avg(

            datediff(

                order_delivered_customer_date,

                order_estimated_delivery_date

            )

        ),

        2

    ) as average_delay_days,

    round(

        sum(

            case

                when order_delivered_customer_date
                     <= order_estimated_delivery_date

                then 1

                else 0

            end

        ) *100/

        count(*),

        2

    ) as on_time_delivery_rate,

    round(

        sum(

            case

                when order_delivered_customer_date
                     > order_estimated_delivery_date

                then 1

                else 0

            end

        ) *100/

        count(*),

        2

    ) as late_delivery_rate,

    max(

        datediff(

            order_delivered_customer_date,

            order_estimated_delivery_date

        )

    ) as maximum_delay_days,

    min(

        datediff(

            order_delivered_customer_date,

            order_estimated_delivery_date

        )

    ) as earliest_delivery_days

from olist_orders_dataset

where

    order_status='delivered'

    and order_delivered_customer_date is not null

    and order_estimated_delivery_date is not null;
    
/*
=================================================
overall observations
=================================================

1. delivery performance should be evaluated
against the promised delivery date rather than
actual delivery time alone, as this better
reflects customer expectations.

2. monthly delay trends help identify seasonal
patterns, operational improvements, and periods
of logistics disruption.

3. regional delay analysis highlights customer
locations where logistics performance can be
improved through better distribution and carrier
management.

4. seller-level delay analysis identifies
consistent operational strengths and weaknesses,
supporting targeted seller performance programs.

5. monitoring delivery delays enables proactive
improvements in fulfillment efficiency, customer
satisfaction, and overall marketplace reliability.

=================================================
*/


--------


/*
=================================================
4. freight cost analysis
=================================================
purpose:
analyze freight costs across the marketplace to
evaluate shipping expenses, identify costly
delivery routes, measure freight efficiency, and
support logistics cost optimization.
=================================================
*/

/*
=================================================
4.1 total freight cost
=================================================
*/

select

    round(

        sum(freight_value),

        2

    ) as total_freight_cost,

    round(

        avg(freight_value),

        2

    ) as average_freight_cost,

    round(

        min(freight_value),

        2

    ) as minimum_freight_cost,

    round(

        max(freight_value),

        2

    ) as maximum_freight_cost

from olist_order_items_dataset;

/*
=================================================
4.2 freight cost trend
=================================================
*/

select

    date_format(

        o.order_purchase_timestamp,

        '%Y-%m'

    ) as purchase_month,

    count(

        distinct o.order_id

    ) as total_orders,

    round(

        sum(oi.freight_value),

        2

    ) as total_freight_cost,

    round(

        avg(oi.freight_value),

        2

    ) as average_freight_cost

from olist_orders_dataset o

join olist_order_items_dataset oi

    on o.order_id = oi.order_id

where

    o.order_status='delivered'

group by purchase_month

order by purchase_month;

/*
=================================================
4.3 freight cost by customer state
=================================================
*/

select

    c.customer_state,

    count(

        distinct o.order_id

    ) as delivered_orders,

    round(

        sum(oi.freight_value),

        2

    ) as total_freight_cost,

    round(

        avg(oi.freight_value),

        2

    ) as average_freight_cost

from olist_orders_dataset o

join olist_customers_dataset c

    on o.customer_id = c.customer_id

join olist_order_items_dataset oi

    on o.order_id = oi.order_id

where

    o.order_status='delivered'

group by

    c.customer_state

order by

    total_freight_cost desc;
    
/*
=================================================
4.4 freight cost by product category
=================================================
*/

select

    pct.product_category_name_english as category,

    count(

        distinct oi.order_id

    ) as total_orders,

    round(

        sum(oi.freight_value),

        2

    ) as total_freight_cost,

    round(

        avg(oi.freight_value),

        2

    ) as average_freight_cost

from olist_order_items_dataset oi

join olist_orders_dataset o

    on oi.order_id = o.order_id

join olist_products_dataset p

    on oi.product_id = p.product_id

left join product_category_name_translation pct

    on p.product_category_name =
       pct.product_category_name

where

    o.order_status='delivered'

group by

    pct.product_category_name_english

order by

    total_freight_cost desc;
    
/*
=================================================
4.5 freight-to-product value ratio
=================================================
*/

select

    round(

        sum(oi.price),

        2

    ) as total_product_value,

    round(

        sum(oi.freight_value),

        2

    ) as total_freight_cost,

    round(

        sum(oi.freight_value) * 100 /

        sum(oi.price),

        2

    ) as freight_percentage_of_product_value

from olist_order_items_dataset oi

join olist_orders_dataset o

    on oi.order_id = o.order_id

where o.order_status='delivered';

/*
=================================================
4.6 high freight cost orders
=================================================
*/

select

    oi.order_id,

    round(

        sum(oi.price),

        2

    ) as product_value,

    round(

        sum(oi.freight_value),

        2

    ) as freight_cost,

    round(

        sum(oi.freight_value) *100/

        sum(oi.price),

        2

    ) as freight_ratio_percent

from olist_order_items_dataset oi

join olist_orders_dataset o

    on oi.order_id=o.order_id

where o.order_status='delivered'

group by oi.order_id

order by

    freight_cost desc

limit 20;

/*
=================================================
4.7 freight efficiency analysis
=================================================
*/

select

    pct.product_category_name_english as category,

    round(

        sum(oi.price),

        2

    ) as product_value,

    round(

        sum(oi.freight_value),

        2

    ) as freight_cost,

    round(

        sum(oi.freight_value) *100/

        sum(oi.price),

        2

    ) as freight_ratio_percent,

    case

        when

            sum(oi.freight_value) *100/

            sum(oi.price) < 10

        then 'Highly Efficient'

        when

            sum(oi.freight_value) *100/

            sum(oi.price) < 20

        then 'Efficient'

        when

            sum(oi.freight_value) *100/

            sum(oi.price) < 35

        then 'Moderate'

        else

            'High Freight Cost'

    end as freight_efficiency

from olist_order_items_dataset oi

join olist_orders_dataset o

    on oi.order_id=o.order_id

join olist_products_dataset p

    on oi.product_id=p.product_id

left join product_category_name_translation pct

    on p.product_category_name=
       pct.product_category_name

where o.order_status='delivered'

group by

    pct.product_category_name_english

order by

    freight_ratio_percent desc;
    
/*
=================================================
4.8 executive summary
=================================================
*/

select

    round(

        sum(oi.freight_value),

        2

    ) as total_freight_cost,

    round(

        avg(oi.freight_value),

        2

    ) as average_freight_cost,

    round(

        sum(oi.price),

        2

    ) as total_product_value,

    round(

        sum(oi.freight_value) *100/

        sum(oi.price),

        2

    ) as freight_percentage_of_product_value,

    round(

        max(oi.freight_value),

        2

    ) as highest_single_freight_cost,

    round(

        min(oi.freight_value),

        2

    ) as lowest_single_freight_cost

from olist_order_items_dataset oi

join olist_orders_dataset o

    on oi.order_id=o.order_id

where o.order_status='delivered';

/*
=================================================
overall observations
=================================================

1. freight cost represents a significant
component of marketplace operating expenses and
should be monitored alongside product revenue.

2. freight-to-product value ratio provides a
better measure of shipping efficiency than
freight cost alone by accounting for product
value.

3. certain product categories incur
disproportionately high shipping costs, creating
opportunities for packaging improvements,
supplier negotiations, or pricing adjustments.

4. identifying orders with exceptionally high
freight costs helps detect operational
inefficiencies and optimize shipping strategies.

5. freight efficiency analysis supports
profitability by balancing logistics costs with
sales value across different product categories.

=================================================
*/


--------


/*
=================================================
5. geographic logistics analysis
=================================================
purpose:
evaluate logistics performance across different
customer states by measuring delivery speed,
delivery reliability, freight costs, and overall
logistics efficiency. these insights help identify
high-performing regions, logistics bottlenecks,
and opportunities for network optimization.
=================================================
*/

/*
=================================================
5.1 delivery performance by state
=================================================
*/

select

    c.customer_state,

    count(*) as delivered_orders,

    round(

        avg(

            datediff(

                o.order_delivered_customer_date,

                o.order_purchase_timestamp

            )

        ),

        2

    ) as average_delivery_days,

    round(

        avg(

            datediff(

                o.order_delivered_customer_date,

                o.order_estimated_delivery_date

            )

        ),

        2

    ) as average_delay_days

from olist_orders_dataset o

join olist_customers_dataset c

    on o.customer_id = c.customer_id

where

    o.order_status='delivered'

    and o.order_delivered_customer_date is not null

group by

    c.customer_state

order by

    average_delivery_days;
    
/*
=================================================
5.2 fastest delivery states
=================================================
*/

select

    c.customer_state,

    count(*) as delivered_orders,

    round(

        avg(

            datediff(

                o.order_delivered_customer_date,

                o.order_purchase_timestamp

            )

        ),

        2

    ) as average_delivery_days

from olist_orders_dataset o

join olist_customers_dataset c

    on o.customer_id=c.customer_id

where

    o.order_status='delivered'

    and o.order_delivered_customer_date is not null

group by

    c.customer_state

having delivered_orders >=100

order by

    average_delivery_days

limit 10;

/*
=================================================
5.3 slowest delivery states
=================================================
*/

select

    c.customer_state,

    count(*) as delivered_orders,

    round(

        avg(

            datediff(

                o.order_delivered_customer_date,

                o.order_purchase_timestamp

            )

        ),

        2

    ) as average_delivery_days

from olist_orders_dataset o

join olist_customers_dataset c

    on o.customer_id=c.customer_id

where

    o.order_status='delivered'

    and o.order_delivered_customer_date is not null

group by

    c.customer_state

having delivered_orders >=100

order by

    average_delivery_days desc

limit 10;

/*
=================================================
5.4 late delivery rate by state
=================================================
*/

select

    c.customer_state,

    count(*) as delivered_orders,

    round(

        sum(

            case

                when o.order_delivered_customer_date

                     > o.order_estimated_delivery_date

                then 1

                else 0

            end

        ) *100/

        count(*),

        2

    ) as late_delivery_rate

from olist_orders_dataset o

join olist_customers_dataset c

    on o.customer_id=c.customer_id

where

    o.order_status='delivered'

    and o.order_delivered_customer_date is not null

    and o.order_estimated_delivery_date is not null

group by

    c.customer_state

having delivered_orders >=100

order by

    late_delivery_rate desc;
    
/*
=================================================
5.5 freight cost by state
=================================================
*/

select

    c.customer_state,

    count(

        distinct o.order_id

    ) as delivered_orders,

    round(

        sum(oi.freight_value),

        2

    ) as total_freight_cost,

    round(

        avg(oi.freight_value),

        2

    ) as average_freight_cost

from olist_orders_dataset o

join olist_customers_dataset c

    on o.customer_id = c.customer_id

join olist_order_items_dataset oi

    on o.order_id = oi.order_id

where

    o.order_status = 'delivered'

group by

    c.customer_state

order by

    average_freight_cost desc;
    
/*
=================================================
5.6 logistics efficiency score
=================================================
*/

with state_metrics as (

    select

        c.customer_state,

        round(

            avg(

                datediff(

                    o.order_delivered_customer_date,

                    o.order_purchase_timestamp

                )

            ),

            2

        ) as avg_delivery_days,

        round(

            avg(oi.freight_value),

            2

        ) as avg_freight_cost,

        round(

            sum(

                case

                    when o.order_delivered_customer_date
                         <= o.order_estimated_delivery_date

                    then 1

                    else 0

                end

            ) *100/

            count(*),

            2

        ) as on_time_rate

    from olist_orders_dataset o

    join olist_customers_dataset c

        on o.customer_id = c.customer_id

    join olist_order_items_dataset oi

        on o.order_id = oi.order_id

    where

        o.order_status='delivered'

        and o.order_delivered_customer_date is not null

        and o.order_estimated_delivery_date is not null

    group by

        c.customer_state

),

scored as (

    select

        *,

        ntile(5) over(

            order by avg_delivery_days asc

        ) as delivery_score,

        ntile(5) over(

            order by avg_freight_cost asc

        ) as freight_score,

        ntile(5) over(

            order by on_time_rate desc

        ) as punctuality_score

    from state_metrics

)

select

    customer_state,

    avg_delivery_days,

    avg_freight_cost,

    on_time_rate,

    delivery_score,

    freight_score,

    punctuality_score,

    delivery_score
    + freight_score
    + punctuality_score

    as logistics_efficiency_score,

    case

        when

            delivery_score
            + freight_score
            + punctuality_score >= 13

        then 'Excellent'

        when

            delivery_score
            + freight_score
            + punctuality_score >= 10

        then 'Good'

        when

            delivery_score
            + freight_score
            + punctuality_score >= 7

        then 'Average'

        else 'Needs Improvement'

    end as performance_level

from scored

order by

    logistics_efficiency_score desc,

    on_time_rate desc;


/*
=================================================
5.7 state logistics ranking
=================================================
*/

with logistics_score as (

    select

        c.customer_state,

        round(

            avg(

                datediff(

                    o.order_delivered_customer_date,

                    o.order_purchase_timestamp

                )

            ),

            2

        ) as avg_delivery_days,

        round(

            avg(oi.freight_value),

            2

        ) as avg_freight_cost,

        round(

            sum(

                case

                    when o.order_delivered_customer_date
                         <= o.order_estimated_delivery_date

                    then 1

                    else 0

                end

            ) *100/

            count(*),

            2

        ) as on_time_rate

    from olist_orders_dataset o

    join olist_customers_dataset c

        on o.customer_id = c.customer_id

    join olist_order_items_dataset oi

        on o.order_id = oi.order_id

    where

        o.order_status='delivered'

        and o.order_delivered_customer_date is not null

        and o.order_estimated_delivery_date is not null

    group by

        c.customer_state

)

select

    dense_rank() over(

        order by

        (

            (100 - avg_delivery_days)

            +

            (100 - avg_freight_cost)

            +

            on_time_rate

        ) desc

    ) as logistics_rank,

    customer_state,

    avg_delivery_days,

    avg_freight_cost,

    on_time_rate

from logistics_score

order by logistics_rank;

/*
=================================================
5.8 executive summary
=================================================
*/

select

    count(

        distinct c.customer_state

    ) as customer_states,

    round(

        avg(

            datediff(

                o.order_delivered_customer_date,

                o.order_purchase_timestamp

            )

        ),

        2

    ) as average_delivery_days,

    round(

        avg(oi.freight_value),

        2

    ) as average_freight_cost,

    round(

        sum(

            case

                when o.order_delivered_customer_date
                     <= o.order_estimated_delivery_date

                then 1

                else 0

            end

        ) *100/

        count(*),

        2

    ) as average_on_time_rate

from olist_orders_dataset o

join olist_customers_dataset c

    on o.customer_id = c.customer_id

join olist_order_items_dataset oi

    on o.order_id = oi.order_id

where

    o.order_status='delivered'

    and o.order_delivered_customer_date is not null

    and o.order_estimated_delivery_date is not null;
    
/*
=================================================
overall observations
=================================================

1. logistics performance differs substantially
across customer states due to distance,
infrastructure, and transportation networks.

2. combining delivery time, freight cost, and
on-time delivery rate provides a more complete
assessment of logistics efficiency than any
single KPI.

3. states with consistently high freight costs
or poor delivery performance represent priority
areas for logistics optimization.

4. logistics rankings support strategic decisions
regarding warehouse placement, carrier selection,
and regional expansion.

5. continuous monitoring of geographic logistics
performance helps improve customer satisfaction
while controlling transportation costs.

=================================================
*/


--------


/*
=================================================
6. logistics performance analysis
=================================================
purpose:
evaluate logistics performance using a balanced
scorecard that combines delivery speed,
delivery reliability, and shipping cost.
these analyses support benchmarking,
performance monitoring, and strategic
logistics decision-making.
=================================================
*/

/*
=================================================
6.1 logistics kpi scorecard
=================================================
*/

select

    count(*) as delivered_orders,

    round(

        avg(

            datediff(

                order_delivered_customer_date,

                order_purchase_timestamp

            )

        ),

        2

    ) as average_delivery_days,

    round(

        avg(

            datediff(

                order_delivered_customer_date,

                order_estimated_delivery_date

            )

        ),

        2

    ) as average_delivery_delay,

    round(

        sum(

            case

                when order_delivered_customer_date
                     <= order_estimated_delivery_date

                then 1

                else 0

            end

        ) * 100 /

        count(*),

        2

    ) as on_time_delivery_rate,

    round(

        avg(oi.freight_value),

        2

    ) as average_freight_cost

from olist_orders_dataset o

join olist_order_items_dataset oi

    on o.order_id = oi.order_id

where

    o.order_status='delivered'

    and order_delivered_customer_date is not null

    and order_estimated_delivery_date is not null;
    
/*
=================================================
6.2 on-time delivery performance ranking
=================================================
*/

select

    dense_rank() over(

        order by

        round(

            sum(

                case

                    when o.order_delivered_customer_date
                         <= o.order_estimated_delivery_date

                    then 1

                    else 0

                end

            ) *100/

            count(*),

            2

        ) desc

    ) as performance_rank,

    c.customer_state,

    count(*) as delivered_orders,

    round(

        sum(

            case

                when o.order_delivered_customer_date
                     <= o.order_estimated_delivery_date

                then 1

                else 0

            end

        ) *100/

        count(*),

        2

    ) as on_time_delivery_rate

from olist_orders_dataset o

join olist_customers_dataset c

    on o.customer_id = c.customer_id

where

    o.order_status='delivered'

    and order_delivered_customer_date is not null

    and order_estimated_delivery_date is not null

group by

    c.customer_state

having delivered_orders >=100

order by performance_rank;

/*
=================================================
6.3 logistics performance by seller
=================================================
*/

with seller_metrics as (

    select

        oi.seller_id,

        count(

            distinct o.order_id

        ) as delivered_orders,

        round(

            avg(

                datediff(

                    o.order_delivered_customer_date,

                    o.order_purchase_timestamp

                )

            ),

            2

        ) as avg_delivery_days,

        round(

            avg(oi.freight_value),

            2

        ) as avg_freight_cost,

        round(

            sum(

                case

                    when o.order_delivered_customer_date
                         <= o.order_estimated_delivery_date

                    then 1

                    else 0

                end

            ) *100/

            count(*),

            2

        ) as on_time_rate

    from olist_orders_dataset o

    join olist_order_items_dataset oi

        on o.order_id = oi.order_id

    where

        o.order_status='delivered'

        and o.order_delivered_customer_date is not null

        and o.order_estimated_delivery_date is not null

    group by

        oi.seller_id

),

seller_scores as (

    select

        *,

        ntile(5) over(

            order by avg_delivery_days asc

        ) as delivery_score,

        ntile(5) over(

            order by avg_freight_cost asc

        ) as freight_score,

        ntile(5) over(

            order by on_time_rate desc

        ) as punctuality_score

    from seller_metrics

)

select

    seller_id,

    delivered_orders,

    avg_delivery_days,

    avg_freight_cost,

    on_time_rate,

    delivery_score,

    freight_score,

    punctuality_score,

    delivery_score
    + freight_score
    + punctuality_score

    as logistics_score

from seller_scores

where delivered_orders >=20

order by

    logistics_score desc,

    on_time_rate desc;
    
/*
=================================================
6.4 logistics performance by state
=================================================
*/

with state_metrics as (

    select

        c.customer_state,

        count(*) as delivered_orders,

        round(
            avg(
                datediff(
                    o.order_delivered_customer_date,
                    o.order_purchase_timestamp
                )
            ),
            2
        ) as avg_delivery_days,

        round(
            avg(oi.freight_value),
            2
        ) as avg_freight_cost,

        round(

            sum(

                case

                    when o.order_delivered_customer_date
                         <= o.order_estimated_delivery_date

                    then 1

                    else 0

                end

            ) * 100 / count(*),

            2

        ) as on_time_rate

    from olist_orders_dataset o

    join olist_customers_dataset c

        on o.customer_id = c.customer_id

    join olist_order_items_dataset oi

        on o.order_id = oi.order_id

    where

        o.order_status='delivered'

        and o.order_delivered_customer_date is not null

        and o.order_estimated_delivery_date is not null

    group by

        c.customer_state

),

scores as (

    select

        *,

        ntile(5) over(
            order by avg_delivery_days asc
        ) as delivery_score,

        ntile(5) over(
            order by avg_freight_cost asc
        ) as freight_score,

        ntile(5) over(
            order by on_time_rate desc
        ) as punctuality_score

    from state_metrics

)

select

    customer_state,

    delivered_orders,

    avg_delivery_days,

    avg_freight_cost,

    on_time_rate,

    delivery_score
    + freight_score
    + punctuality_score

    as logistics_score

from scores

order by logistics_score desc;

/*
=================================================
6.5 logistics risk classification
=================================================
*/

with logistics_metrics as (

    select

        c.customer_state,

        round(

            avg(

                datediff(

                    o.order_delivered_customer_date,

                    o.order_purchase_timestamp

                )

            ),

            2

        ) as avg_delivery_days,

        round(

            avg(oi.freight_value),

            2

        ) as avg_freight_cost,

        round(

            sum(

                case

                    when o.order_delivered_customer_date
                         <= o.order_estimated_delivery_date

                    then 1

                    else 0

                end

            ) *100/

            count(*),

            2

        ) as on_time_rate

    from olist_orders_dataset o

    join olist_customers_dataset c

        on o.customer_id = c.customer_id

    join olist_order_items_dataset oi

        on o.order_id = oi.order_id

    where

        o.order_status='delivered'

    group by

        c.customer_state

)

select

    *,

    case

        when

            on_time_rate >=95

            and avg_delivery_days <=10

        then 'Low Risk'

        when

            on_time_rate >=90

            and avg_delivery_days <=15

        then 'Medium Risk'

        else

            'High Risk'

    end as logistics_risk

from logistics_metrics

order by

    on_time_rate,

    avg_delivery_days desc;
    
/*
=================================================
6.6 logistics performance index
=================================================
*/

with logistics_metrics as (

    select

        c.customer_state,

        round(

            avg(

                datediff(

                    o.order_delivered_customer_date,

                    o.order_purchase_timestamp

                )

            ),

            2

        ) as avg_delivery_days,

        round(

            avg(oi.freight_value),

            2

        ) as avg_freight_cost,

        round(

            sum(

                case

                    when o.order_delivered_customer_date
                         <= o.order_estimated_delivery_date

                    then 1

                    else 0

                end

            ) *100/

            count(*),

            2

        ) as on_time_rate

    from olist_orders_dataset o

    join olist_customers_dataset c

        on o.customer_id=c.customer_id

    join olist_order_items_dataset oi

        on o.order_id=oi.order_id

    where

        o.order_status='delivered'

    group by

        c.customer_state

),

scores as (

    select

        *,

        ntile(5) over(
            order by avg_delivery_days asc
        ) as delivery_score,

        ntile(5) over(
            order by avg_freight_cost asc
        ) as freight_score,

        ntile(5) over(
            order by on_time_rate desc
        ) as punctuality_score

    from logistics_metrics

)

select

    dense_rank() over(

        order by

            delivery_score
          + freight_score
          + punctuality_score desc

    ) as logistics_rank,

    customer_state,

    avg_delivery_days,

    avg_freight_cost,

    on_time_rate,

    delivery_score,

    freight_score,

    punctuality_score,

    delivery_score
    + freight_score
    + punctuality_score

    as logistics_performance_index,

    case

        when

            delivery_score
          + freight_score
          + punctuality_score >=13

        then 'Excellent'

        when

            delivery_score
          + freight_score
          + punctuality_score >=10

        then 'Good'

        when

            delivery_score
          + freight_score
          + punctuality_score >=7

        then 'Average'

        else

            'Needs Improvement'

    end as performance_level

from scores

order by logistics_rank;

/*
=================================================
6.7 executive summary
=================================================
*/

select

    count(*) as delivered_orders,

    round(

        avg(

            datediff(

                order_delivered_customer_date,

                order_purchase_timestamp

            )

        ),

        2

    ) as avg_delivery_days,

    round(

        avg(

            datediff(

                order_delivered_customer_date,

                order_estimated_delivery_date

            )

        ),

        2

    ) as avg_delay_days,

    round(

        avg(oi.freight_value),

        2

    ) as avg_freight_cost,

    round(

        sum(

            case

                when order_delivered_customer_date
                     <= order_estimated_delivery_date

                then 1

                else 0

            end

        ) *100/

        count(*),

        2

    ) as on_time_delivery_rate

from olist_orders_dataset o

join olist_order_items_dataset oi

    on o.order_id=oi.order_id

where

    o.order_status='delivered';
    
/*
=================================================
observations
=================================================

1. logistics performance should be evaluated
using multiple KPIs rather than relying on a
single operational metric.

2. standardized scoring using NTILE provides
fair comparisons between regions despite
differences in measurement units.

3. combining delivery speed, freight cost,
and on-time performance creates a robust
logistics performance index suitable for
executive reporting.

4. logistics risk classification helps identify
states requiring immediate operational
attention and investment.

5. the logistics performance index provides an
excellent benchmark for continuous monitoring,
regional comparison, and strategic logistics
planning.

=================================================
*/


--------


/*
=================================================
7. delivery trend analysis
=================================================
purpose:
analyze logistics performance over time to
identify seasonal patterns, operational trends,
and changes in delivery efficiency. these
insights support forecasting, capacity planning,
and continuous logistics improvement.
=================================================
*/

/*
=================================================
7.1 monthly delivery performance
=================================================
*/

select

    date_format(
        o.order_purchase_timestamp,
        '%Y-%m'
    ) as purchase_month,

    count(*) as delivered_orders,

    round(

        avg(

            datediff(

                o.order_delivered_customer_date,

                o.order_purchase_timestamp

            )

        ),

        2

    ) as average_delivery_days

from olist_orders_dataset o

where

    o.order_status='delivered'

    and o.order_delivered_customer_date is not null

group by purchase_month

order by purchase_month;

/*
=================================================
7.2 monthly on-time delivery trend
=================================================
*/

select

    date_format(

        o.order_purchase_timestamp,

        '%Y-%m'

    ) as purchase_month,

    count(*) as delivered_orders,

    round(

        sum(

            case

                when o.order_delivered_customer_date
                     <= o.order_estimated_delivery_date

                then 1

                else 0

            end

        ) *100/

        count(*),

        2

    ) as on_time_delivery_rate

from olist_orders_dataset o

where

    o.order_status='delivered'

    and o.order_delivered_customer_date is not null

    and o.order_estimated_delivery_date is not null

group by purchase_month

order by purchase_month;

/*
=================================================
7.3 monthly late delivery trend
=================================================
*/

select

    date_format(

        o.order_purchase_timestamp,

        '%Y-%m'

    ) as purchase_month,

    count(*) as delivered_orders,

    round(

        sum(

            case

                when o.order_delivered_customer_date
                     > o.order_estimated_delivery_date

                then 1

                else 0

            end

        ) *100/

        count(*),

        2

    ) as late_delivery_rate

from olist_orders_dataset o

where

    o.order_status='delivered'

    and o.order_delivered_customer_date is not null

    and o.order_estimated_delivery_date is not null

group by purchase_month

order by purchase_month;

/*
=================================================
7.4 monthly freight cost trend
=================================================
*/

select

    date_format(

        o.order_purchase_timestamp,

        '%Y-%m'

    ) as purchase_month,

    count(

        distinct o.order_id

    ) as delivered_orders,

    round(

        sum(oi.freight_value),

        2

    ) as total_freight_cost,

    round(

        avg(oi.freight_value),

        2

    ) as average_freight_cost

from olist_orders_dataset o

join olist_order_items_dataset oi

    on o.order_id = oi.order_id

where

    o.order_status='delivered'

group by purchase_month

order by purchase_month;


/*
=================================================
7.5 monthly logistics kpi dashboard
=================================================
*/
with monthly_kpis as (

    select

        date_format(

            o.order_purchase_timestamp,

            '%Y-%m'

        ) as purchase_month,

        count(distinct o.order_id) as delivered_orders,

        round(

            avg(

                datediff(

                    o.order_delivered_customer_date,

                    o.order_purchase_timestamp

                )

            ),

            2

        ) as avg_delivery_days,

        round(

            avg(

                datediff(

                    o.order_delivered_customer_date,

                    o.order_estimated_delivery_date

                )

            ),

            2

        ) as avg_delay_days,

        round(

            avg(oi.freight_value),

            2

        ) as avg_freight_cost,

        round(

            sum(

                case

                    when o.order_delivered_customer_date
                         <= o.order_estimated_delivery_date

                    then 1

                    else 0

                end

            ) *100/

            count(*),

            2

        ) as on_time_rate

    from olist_orders_dataset o

    join olist_order_items_dataset oi

        on o.order_id = oi.order_id

    where

        o.order_status='delivered'

        and o.order_delivered_customer_date is not null

        and o.order_estimated_delivery_date is not null

    group by purchase_month

)

select

    purchase_month,

    delivered_orders,

    avg_delivery_days,

    avg_delay_days,

    avg_freight_cost,

    on_time_rate,

    round(

        100 - on_time_rate,

        2

    ) as late_delivery_rate

from monthly_kpis

order by purchase_month;

/*
=================================================
7.6 rolling delivery performance
=================================================
*/
with monthly_delivery as (

    select

        date_format(

            order_purchase_timestamp,

            '%Y-%m'

        ) as purchase_month,

        round(

            avg(

                datediff(

                    order_delivered_customer_date,

                    order_purchase_timestamp

                )

            ),

            2

        ) as avg_delivery_days

    from olist_orders_dataset

    where

        order_status='delivered'

        and order_delivered_customer_date is not null

    group by purchase_month

)

select

    purchase_month,

    avg_delivery_days,

    round(

        avg(avg_delivery_days)

        over(

            order by purchase_month

            rows between 2 preceding

            and current row

        ),

        2

    ) as rolling_3_month_average

from monthly_delivery

order by purchase_month;

/*
=================================================
7.7 seasonality analysis
=================================================
*/
select

    monthname(

        order_purchase_timestamp

    ) as month_name,

    month(

        order_purchase_timestamp

    ) as month_number,

    count(*) as delivered_orders,

    round(

        avg(

            datediff(

                order_delivered_customer_date,

                order_purchase_timestamp

            )

        ),

        2

    ) as avg_delivery_days,

    round(

        avg(

            datediff(

                order_delivered_customer_date,

                order_estimated_delivery_date

            )

        ),

        2

    ) as avg_delay_days

from olist_orders_dataset

where

    order_status='delivered'

    and order_delivered_customer_date is not null

    and order_estimated_delivery_date is not null

group by

    month_number,

    month_name

order by

    month_number;
    
/*
=================================================
7.8 executive summary
=================================================
*/
select

    count(*) as delivered_orders,

    round(

        avg(

            datediff(

                order_delivered_customer_date,

                order_purchase_timestamp

            )

        ),

        2

    ) as overall_delivery_days,

    round(

        avg(

            datediff(

                order_delivered_customer_date,

                order_estimated_delivery_date

            )

        ),

        2

    ) as overall_delay_days,

    round(

        avg(oi.freight_value),

        2

    ) as average_freight_cost,

    round(

        sum(

            case

                when order_delivered_customer_date
                     <= order_estimated_delivery_date

                then 1

                else 0

            end

        ) *100/

        count(*),

        2

    ) as on_time_delivery_rate

from olist_orders_dataset o

join olist_order_items_dataset oi

    on o.order_id = oi.order_id

where

    o.order_status='delivered'

    and order_delivered_customer_date is not null

    and order_estimated_delivery_date is not null;
    
/*
=================================================
observations
=================================================

1. monthly trend analysis reveals long-term
changes in logistics performance and helps
identify operational improvements.

2. rolling averages reduce month-to-month
volatility and provide a clearer picture of
overall delivery performance.

3. seasonal patterns highlight months requiring
additional logistics capacity, inventory
planning, and carrier resources.

4. combining multiple KPIs into a monthly
dashboard provides executives with a concise,
actionable view of logistics health.

5. continuous monitoring of logistics trends
supports proactive decision-making and improves
customer satisfaction while controlling
operational costs.

=================================================
*/


--------


/*
=================================================
8. executive summary
=================================================
purpose:
provide a consolidated overview of marketplace
logistics performance by combining delivery speed,
service reliability, freight efficiency, geographic
performance, and operational trends into an
executive-level report.

=================================================
*/

/*
=================================================
8.1 logistics executive dashboard
=================================================
*/

select

    count(*) as delivered_orders,

    round(

        avg(

            datediff(

                o.order_delivered_customer_date,

                o.order_purchase_timestamp

            )

        ),

        2

    ) as avg_delivery_days,

    round(

        avg(

            datediff(

                o.order_delivered_customer_date,

                o.order_estimated_delivery_date

            )

        ),

        2

    ) as avg_delivery_delay,

    round(

        avg(oi.freight_value),

        2

    ) as avg_freight_cost,

    round(

        sum(oi.freight_value),

        2

    ) as total_freight_cost,

    round(

        sum(

            case

                when o.order_delivered_customer_date
                     <= o.order_estimated_delivery_date

                then 1

                else 0

            end

        ) *100/

        count(*),

        2

    ) as on_time_delivery_rate,

    round(

        sum(

            case

                when o.order_delivered_customer_date
                     > o.order_estimated_delivery_date

                then 1

                else 0

            end

        ) *100/

        count(*),

        2

    ) as late_delivery_rate

from olist_orders_dataset o

join olist_order_items_dataset oi

    on o.order_id=oi.order_id

where

    o.order_status='delivered'

    and o.order_delivered_customer_date is not null

    and o.order_estimated_delivery_date is not null;
    
/*
=================================================
8.2 operational performance highlights
=================================================
*/

with

fastest_state as (

    select

        c.customer_state,

        round(
            avg(
                datediff(
                    o.order_delivered_customer_date,
                    o.order_purchase_timestamp
                )
            ),
            2
        ) as avg_delivery_days

    from olist_orders_dataset o

    join olist_customers_dataset c

        on o.customer_id=c.customer_id

    where

        o.order_status='delivered'

    group by c.customer_state

    order by avg_delivery_days

    limit 1

),

best_on_time_state as (

    select

        c.customer_state,

        round(

            sum(

                case

                    when o.order_delivered_customer_date
                    <= o.order_estimated_delivery_date

                    then 1

                    else 0

                end

            )*100/count(*),

            2

        ) as on_time_rate

    from olist_orders_dataset o

    join olist_customers_dataset c

        on o.customer_id=c.customer_id

    where

        o.order_status='delivered'

    group by c.customer_state

    order by on_time_rate desc

    limit 1

),

lowest_freight_state as (

    select

        c.customer_state,

        round(

            avg(oi.freight_value),

            2

        ) as avg_freight

    from olist_orders_dataset o

    join olist_customers_dataset c

        on o.customer_id=c.customer_id

    join olist_order_items_dataset oi

        on o.order_id=oi.order_id

    where

        o.order_status='delivered'

    group by c.customer_state

    order by avg_freight

    limit 1

)

select

    f.customer_state as fastest_delivery_state,

    f.avg_delivery_days,

    b.customer_state as best_on_time_state,

    b.on_time_rate,

    l.customer_state as lowest_freight_state,

    l.avg_freight

from fastest_state f

cross join best_on_time_state b

cross join lowest_freight_state l;

/*
=================================================
8.3 operational risk highlights
=================================================
*/

with

slowest_state as (

    select

        c.customer_state,

        round(

            avg(

                datediff(

                    o.order_delivered_customer_date,

                    o.order_purchase_timestamp

                )

            ),

            2

        ) avg_delivery

    from olist_orders_dataset o

    join olist_customers_dataset c

        on o.customer_id=c.customer_id

    where o.order_status='delivered'

    group by c.customer_state

    order by avg_delivery desc

    limit 1

),

highest_late_state as (

    select

        c.customer_state,

        round(

            sum(

                case

                    when o.order_delivered_customer_date
                    > o.order_estimated_delivery_date

                    then 1

                    else 0

                end

            )*100/count(*),

            2

        ) as late_rate

    from olist_orders_dataset o

    join olist_customers_dataset c

        on o.customer_id=c.customer_id

    where o.order_status='delivered'

    group by c.customer_state

    order by late_rate desc

    limit 1

),

highest_freight_state as (

    select

        c.customer_state,

        round(

            avg(oi.freight_value),

            2

        ) avg_freight

    from olist_orders_dataset o

    join olist_customers_dataset c

        on o.customer_id=c.customer_id

    join olist_order_items_dataset oi

        on o.order_id=oi.order_id

    where o.order_status='delivered'

    group by c.customer_state

    order by avg_freight desc

    limit 1

)

select

    s.customer_state as slowest_delivery_state,

    s.avg_delivery,

    l.customer_state as highest_late_state,

    l.late_rate,

    h.customer_state as highest_freight_state,

    h.avg_freight

from slowest_state s

cross join highest_late_state l

cross join highest_freight_state h;

/*
=================================================
8.4 logistics trend summary
=================================================
*/

with monthly_summary as (

    select

        date_format(

            order_purchase_timestamp,

            '%Y-%m'

        ) as purchase_month,

        round(

            avg(

                datediff(

                    order_delivered_customer_date,

                    order_purchase_timestamp

                )

            ),

            2

        ) as avg_delivery_days,

        round(

            avg(

                datediff(

                    order_delivered_customer_date,

                    order_estimated_delivery_date

                )

            ),

            2

        ) as avg_delay

    from olist_orders_dataset

    where order_status='delivered'

    group by purchase_month

)

select

    min(avg_delivery_days) as fastest_month_delivery,

    max(avg_delivery_days) as slowest_month_delivery,

    round(

        avg(avg_delivery_days),

        2

    ) as overall_avg_delivery,

    round(

        avg(avg_delay),

        2

    ) as overall_avg_delay

from monthly_summary;

/*
=================================================
8.5 strategic business recommendations
=================================================

1. Improve logistics performance in states with
high delivery delays and low on-time rates.

2. Reduce freight costs by optimizing warehouse
locations and carrier allocation.

3. Monitor low-performing sellers using the
Logistics Performance Index.

4. Increase logistics capacity during seasonal
peak periods identified in the trend analysis.

5. Continue tracking the Marketplace Logistics
KPI Dashboard as a monthly executive report.

6. Use Logistics Performance Index rankings to
benchmark operational improvements over time.

=================================================
*/

/*
=================================================
OBSERVATION
=================================================

1. Logistics performance is driven by three core
dimensions: delivery speed, service reliability,
and freight efficiency.

2. Geographic analysis reveals regional disparities
that can guide warehouse placement, carrier
selection, and inventory allocation.

3. Freight efficiency should be evaluated alongside
delivery performance to balance customer service
with operational cost.

4. Trend analysis enables proactive logistics
management by identifying seasonal patterns and
performance deterioration before they significantly
impact customers.

5. The Executive Logistics Scorecard consolidates
multiple operational KPIs into a single framework,
providing decision-makers with a practical tool for
monitoring and improving marketplace logistics.

=================================================
*/







----------------------------------------------------------------------------------------











/*
=================================================
Project: Brazilian E-Commerce (Olist) Analysis
File: 08_Customer_Satisfaction_Analysis.sql
=================================================
purpose:
evaluate the overall customer experience by
analyzing review scores, review coverage,
delivery performance, and operational factors
that influence customer satisfaction.
this analysis identifies the key drivers of
positive and negative customer experiences and
provides actionable insights to improve customer
retention, seller performance, and marketplace
service quality.
Dataset:
    Olist Brazilian E-Commerce Public Dataset
=================================================
*/


/*
=================================================
1. customer satisfaction overview
=================================================
purpose:
establish the marketplace's overall customer
satisfaction baseline by measuring review
scores, review participation, and customer
feedback activity.this section provides the core 
customer experience KPIs that serve as the foundation
for all subsequent customer satisfaction analyses.
=================================================
*/

/*
=================================================
1.1 overall average review score
=================================================
*/
select

    count(*) as total_reviews,

    round(

        avg(review_score),
        2
    ) as average_review_score,

    min(review_score) as minimum_review_score,

    max(review_score) as maximum_review_score

from olist_order_reviews_dataset;

/*
=================================================
1.2 review score distribution
=================================================
*/
select
    review_score,

    count(*) as total_reviews,

    round(

        count(*) * 100 /

        (select count(*)

         from olist_order_reviews_dataset),
        2
    ) as percentage_of_reviews

from olist_order_reviews_dataset

group by
    review_score
order by

    review_score desc;
    
/*
=================================================
1.3 total reviews
=================================================
*/

select

    count(*) as total_reviews,

    count(

        distinct review_id

    ) as unique_reviews,

    count(

        distinct order_id

    ) as reviewed_orders

from olist_order_reviews_dataset;

/*
=================================================
1.4 review coverage
=================================================
*/

select

    count(

        distinct o.order_id

    ) as delivered_orders,

    count(

        distinct r.order_id

    ) as reviewed_orders,

    round(

        count(

            distinct r.order_id

        ) * 100.0 /

        count(

            distinct o.order_id

        ),

        2

    ) as review_coverage_percentage

from olist_orders_dataset o

left join olist_order_reviews_dataset r

    on o.order_id = r.order_id

where

    o.order_status = 'delivered';
    
/*
=================================================
1.5 review response timeline
=================================================
*/

select

    round(

        avg(

            datediff(

                r.review_creation_date,

                o.order_delivered_customer_date

            )

        ),

        2

    ) as average_days_to_review,

    min(

        datediff(

            r.review_creation_date,

            o.order_delivered_customer_date

        )

    ) as minimum_days,

    max(

        datediff(

            r.review_creation_date,

            o.order_delivered_customer_date

        )

    ) as maximum_days

from olist_order_reviews_dataset r

join olist_orders_dataset o

    on r.order_id = o.order_id

where

    o.order_status = 'delivered'

    and o.order_delivered_customer_date is not null

    and r.review_creation_date is not null;
    
/*
=================================================
1.6 executive summary
=================================================
*/

select

    count(*) as total_reviews,

    round(

        avg(review_score),

        2

    ) as average_review_score,

    round(

        (
            select count(distinct r.order_id)

            from olist_order_reviews_dataset r
        ) * 100.0 /

        (
            select count(distinct order_id)

            from olist_orders_dataset

            where order_status = 'delivered'
        ),

        2

    ) as review_coverage_percentage

from olist_order_reviews_dataset;

/*
=================================================
OBSERVATION
=================================================

1. Customer review scores provide a direct measure
of marketplace satisfaction and perceived service
quality.

2. Review distribution offers greater insight than
the average score by highlighting the proportion of
highly satisfied versus dissatisfied customers.

3. Review coverage indicates the level of customer
engagement and the representativeness of feedback
across products, sellers, and regions.

4. Measuring the time between delivery and review
submission provides additional context about
customer engagement and feedback behavior.

=================================================
*/



--------


/*
=================================================
2. review score analysis
=================================================
purpose:
analyze customer review patterns across time,
geography, sellers, and product categories to
identify the strongest and weakest areas of the
marketplace from the customer's perspective.

=================================================
*/

/*
=================================================
2.1 review score distribution
=================================================
*/

select

    review_score,

    count(*) as total_reviews,

    round(

        count(*) * 100.0 /

        sum(count(*)) over(),

        2

    ) as percentage_of_reviews

from olist_order_reviews_dataset

group by review_score

order by review_score desc;

/*
=================================================
2.2 monthly review trend
=================================================
*/

select

    date_format(

        r.review_creation_date,

        '%Y-%m'

    ) as review_month,

    count(*) as total_reviews,

    round(

        avg(r.review_score),

        2

    ) as average_review_score

from olist_order_reviews_dataset r

where

    r.review_creation_date is not null

group by review_month

order by review_month;

/*
=================================================
2.3 average review score by state
=================================================
*/

select

    c.customer_state,

    count(*) as total_reviews,

    round(

        avg(r.review_score),

        2

    ) as average_review_score

from olist_order_reviews_dataset r

join olist_orders_dataset o

    on r.order_id = o.order_id

join olist_customers_dataset c

    on o.customer_id = c.customer_id

group by

    c.customer_state

having

    total_reviews >= 30

order by

    average_review_score desc;
    
/*
=================================================
2.4 best and worst states by review score
=================================================
*/

with state_reviews as (

    select

        c.customer_state,

        count(*) as total_reviews,

        round(

            avg(r.review_score),

            2

        ) as average_review_score

    from olist_order_reviews_dataset r

    join olist_orders_dataset o

        on r.order_id = o.order_id

    join olist_customers_dataset c

        on o.customer_id = c.customer_id

    group by

        c.customer_state

    having

        total_reviews >= 30

)

select

    dense_rank() over(

        order by average_review_score desc

    ) as satisfaction_rank,

    customer_state,

    total_reviews,

    average_review_score,

    case

        when dense_rank() over(

            order by average_review_score desc

        ) <= 5

        then 'Best Performing'

        when dense_rank() over(

            order by average_review_score asc

        ) <= 5

        then 'Needs Improvement'

        else 'Average'

    end as performance_category

from state_reviews

order by

    average_review_score desc;
    
/*
=================================================
2.5 average review score by product category
=================================================
*/

select

    pct.product_category_name_english as product_category,

    count(*) as total_reviews,

    round(

        avg(r.review_score),

        2

    ) as average_review_score

from olist_order_reviews_dataset r

join olist_orders_dataset o

    on r.order_id = o.order_id

join olist_order_items_dataset oi

    on o.order_id = oi.order_id

join olist_products_dataset p

    on oi.product_id = p.product_id

left join product_category_name_translation pct

    on p.product_category_name =
       pct.product_category_name

group by

    pct.product_category_name_english

having total_reviews >= 30

order by average_review_score desc;

/*
=================================================
2.6 best and worst product categories
=================================================
*/

with category_reviews as (

select

    pct.product_category_name_english as product_category,

    count(*) as total_reviews,

    round(

        avg(r.review_score),

        2

    ) as average_review_score

from olist_order_reviews_dataset r

join olist_orders_dataset o

    on r.order_id=o.order_id

join olist_order_items_dataset oi

    on o.order_id=oi.order_id

join olist_products_dataset p

    on oi.product_id=p.product_id

left join product_category_name_translation pct

    on p.product_category_name=
       pct.product_category_name

group by

    pct.product_category_name_english

having total_reviews>=30

)

select

    dense_rank() over(

        order by average_review_score desc

    ) as satisfaction_rank,

    product_category,

    total_reviews,

    average_review_score,

    case

        when dense_rank() over(

            order by average_review_score desc

        )<=5

        then 'Best Category'

        when dense_rank() over(

            order by average_review_score asc

        )<=5

        then 'Needs Improvement'

        else 'Average'

    end as category_performance

from category_reviews

order by average_review_score desc;

/*
=================================================
2.7 average review score by seller
=================================================
*/

select

    oi.seller_id,

    count(*) as total_reviews,

    round(

        avg(r.review_score),

        2

    ) as average_review_score

from olist_order_reviews_dataset r

join olist_order_items_dataset oi

    on r.order_id=oi.order_id

group by

    oi.seller_id

having total_reviews>=30

order by

    average_review_score desc;
    
/*
=================================================
2.8 seller review ranking
=================================================
*/

with seller_reviews as (

select

    oi.seller_id,

    count(*) as total_reviews,

    round(

        avg(r.review_score),

        2

    ) as average_review_score

from olist_order_reviews_dataset r

join olist_order_items_dataset oi

    on r.order_id=oi.order_id

group by

    oi.seller_id

having total_reviews>=30

)

select

    dense_rank() over(

        order by average_review_score desc

    ) as seller_rank,

    seller_id,

    total_reviews,

    average_review_score,

    case

        when average_review_score>=4.7

        then 'Excellent'

        when average_review_score>=4.3

        then 'Good'

        when average_review_score>=3.8

        then 'Average'

        else 'Needs Improvement'

    end as seller_rating

from seller_reviews

order by seller_rank;

/*
=================================================
2.9 executive summary
=================================================
*/

select

    round(

        avg(review_score),

        2

    ) as overall_review_score,

    count(*) as total_reviews,

    min(review_score) as lowest_review,

    max(review_score) as highest_review

from olist_order_reviews_dataset;

/*
=================================================
overall observations
=================================================

1. customer satisfaction varies considerably
across product categories and sellers,
indicating opportunities for targeted quality
improvements.

2. geographic analysis reveals regional
differences in customer experience that may be
linked to logistics and seller performance.

3. consistently high-rated sellers represent
best practices that can be replicated across
the marketplace.

4. lower-rated categories should be reviewed
for issues related to product quality,
expectation management, or fulfillment.

5. monitoring review trends over time enables
the marketplace to measure the impact of
operational improvements on customer
satisfaction.

=================================================
*/


--------


/*
=================================================
3. delivery vs customer satisfaction
=================================================
purpose:
evaluate how delivery performance influences
customer satisfaction by analyzing delivery
speed, delays, and freight costs alongside
customer review scores.

this section identifies the operational factors
that have the greatest impact on the customer
experience.

=================================================
*/

/*
=================================================
3.1 review score by delivery time
=================================================
*/

select

    round(

        avg(

            datediff(

                o.order_delivered_customer_date,

                o.order_purchase_timestamp

            )

        ),

        2

    ) as average_delivery_days,

    round(

        avg(r.review_score),

        2

    ) as average_review_score,

    count(*) as total_orders

from olist_orders_dataset o

join olist_order_reviews_dataset r

    on o.order_id = r.order_id

where

    o.order_status='delivered'

    and o.order_delivered_customer_date is not null

group by

    datediff(

        o.order_delivered_customer_date,

        o.order_purchase_timestamp

    )

order by

    average_delivery_days;
    
/*
=================================================
3.2 review score by delivery delay
=================================================
*/

select

    round(

        avg(

            datediff(

                o.order_delivered_customer_date,

                o.order_estimated_delivery_date

            )

        ),

        2

    ) as average_delay_days,

    round(

        avg(r.review_score),

        2

    ) as average_review_score,

    count(*) as total_orders

from olist_orders_dataset o

join olist_order_reviews_dataset r

    on o.order_id=r.order_id

where

    o.order_status='delivered'

    and o.order_delivered_customer_date is not null

    and o.order_estimated_delivery_date is not null

group by

    datediff(

        o.order_delivered_customer_date,

        o.order_estimated_delivery_date

    )

order by

    average_delay_days;
    
/*
=================================================
3.3 early vs on-time vs late deliveries
=================================================
*/

select

    case

        when

            o.order_delivered_customer_date
            < o.order_estimated_delivery_date

        then 'Early'

        when

            o.order_delivered_customer_date
            = o.order_estimated_delivery_date

        then 'On-Time'

        else 'Late'

    end as delivery_status,

    count(*) as total_orders,

    round(

        avg(r.review_score),

        2

    ) as average_review_score,

    round(

        avg(

            datediff(

                o.order_delivered_customer_date,

                o.order_purchase_timestamp

            )

        ),

        2

    ) as average_delivery_days

from olist_orders_dataset o

join olist_order_reviews_dataset r

    on o.order_id=r.order_id

where

    o.order_status='delivered'

group by

    delivery_status

order by

    average_review_score desc;

/*
=================================================
3.4 delivery time bucket analysis
=================================================
*/

select

    case

        when datediff(
                o.order_delivered_customer_date,
                o.order_purchase_timestamp
             ) <= 3

        then '0–3 Days'

        when datediff(
                o.order_delivered_customer_date,
                o.order_purchase_timestamp
             ) <= 7

        then '4–7 Days'

        when datediff(
                o.order_delivered_customer_date,
                o.order_purchase_timestamp
             ) <= 14

        then '8–14 Days'

        when datediff(
                o.order_delivered_customer_date,
                o.order_purchase_timestamp
             ) <= 21

        then '15–21 Days'

        else '>21 Days'

    end as delivery_bucket,

    count(*) as total_orders,

    round(

        avg(

            datediff(

                o.order_delivered_customer_date,

                o.order_purchase_timestamp

            )

        ),

        2

    ) as avg_delivery_days,

    round(

        avg(r.review_score),

        2

    ) as avg_review_score

from olist_orders_dataset o

join olist_order_reviews_dataset r

    on o.order_id = r.order_id

where

    o.order_status='delivered'

group by delivery_bucket

order by

    min(

        datediff(

            o.order_delivered_customer_date,

            o.order_purchase_timestamp

        )

    );
    
/*
=================================================
3.5 freight cost vs review score
=================================================
*/

select

    case

        when oi.freight_value < 10

        then 'Under 10'

        when oi.freight_value < 20

        then '10–20'

        when oi.freight_value < 40

        then '20–40'

        when oi.freight_value < 60

        then '40–60'

        else '60+'

    end as freight_bucket,

    count(*) as total_orders,

    round(

        avg(oi.freight_value),

        2

    ) as avg_freight_cost,

    round(

        avg(r.review_score),

        2

    ) as avg_review_score

from olist_order_items_dataset oi

join olist_order_reviews_dataset r

    on oi.order_id = r.order_id

group by freight_bucket

order by avg_freight_cost;

/*
=================================================
3.6 delivery performance vs customer satisfaction
matrix
=================================================
*/

with performance as (

select

    o.order_id,

    round(

        datediff(

            o.order_delivered_customer_date,

            o.order_purchase_timestamp

        ),

        2

    ) as delivery_days,

    r.review_score

from olist_orders_dataset o

join olist_order_reviews_dataset r

    on o.order_id = r.order_id

where

    o.order_status='delivered'

)

select

    case

        when delivery_days <= 7

        then 'Fast Delivery'

        else 'Slow Delivery'

    end as delivery_performance,

    case

        when review_score >= 4

        then 'High Satisfaction'

        else 'Low Satisfaction'

    end as customer_satisfaction,

    count(*) as total_orders,

    round(

        avg(review_score),

        2

    ) as avg_review_score,

    case

        when delivery_days <= 7
             and review_score >= 4

        then 'Excellent Experience'

        when delivery_days > 7
             and review_score >= 4

        then 'Customer Tolerant'

        when delivery_days <= 7
             and review_score < 4

        then 'Product/Service Issue'

        else 'Critical Improvement'

    end as business_segment

from performance

group by

    delivery_performance,

    customer_satisfaction,

    business_segment

order by

    total_orders desc;
    
/*
=================================================
3.7 executive summary
=================================================
*/

select

    round(

        avg(r.review_score),

        2

    ) as overall_review_score,

    round(

        avg(

            datediff(

                o.order_delivered_customer_date,

                o.order_purchase_timestamp

            )

        ),

        2

    ) as avg_delivery_days,

    round(

        avg(

            datediff(

                o.order_delivered_customer_date,

                o.order_estimated_delivery_date

            )

        ),

        2

    ) as avg_delivery_delay,

    round(

        avg(oi.freight_value),

        2

    ) as avg_freight_cost

from olist_orders_dataset o

join olist_order_reviews_dataset r

    on o.order_id = r.order_id

join olist_order_items_dataset oi

    on o.order_id = oi.order_id

where

    o.order_status='delivered';
    
/*
=================================================
overall observations
=================================================

1. delivery speed has a measurable impact on
customer satisfaction.

2. customers receiving late deliveries are more
likely to leave lower review scores.

3. faster deliveries consistently generate
higher customer satisfaction.

4. freight cost alone is not a reliable
indicator of customer satisfaction; value
depends on the quality of the delivery
experience.

5. the Delivery Performance vs Customer
Satisfaction Matrix provides a practical
framework for identifying operational strengths
and improvement opportunities.

=================================================
*/


--------


/*
=================================================
4. product experience analysis
=================================================
purpose:
evaluate customer satisfaction across product
categories, pricing, and product popularity to
identify products that consistently delight or
disappoint customers.

this section helps identify opportunities for
quality improvement, pricing optimization, and
product portfolio management.

=================================================
*/

/*
=================================================
4.1 review score by product category
=================================================
*/

select

    pct.product_category_name_english as product_category,

    count(distinct r.review_id) as total_reviews,

    round(

        avg(r.review_score),

        2

    ) as average_review_score

from olist_order_reviews_dataset r

join olist_orders_dataset o

    on r.order_id = o.order_id

join olist_order_items_dataset oi

    on o.order_id = oi.order_id
    


join olist_products_dataset p

    on oi.product_id = p.product_id

left join product_category_name_translation pct

    on p.product_category_name =
       pct.product_category_name

group by

    pct.product_category_name_english

having

    total_reviews >= 30

order by

    average_review_score desc;
    
/*
=================================================
4.2 best product categories
=================================================
*/

with category_reviews as (

    select

        pct.product_category_name_english
            as product_category,

        count(distinct r.review_id)
            as total_reviews,

        round(

            avg(r.review_score),

            2

        ) as average_review_score

    from olist_order_reviews_dataset r

    join olist_orders_dataset o

        on r.order_id = o.order_id

    join olist_order_items_dataset oi

        on o.order_id = oi.order_id

    join olist_products_dataset p

        on oi.product_id = p.product_id

    left join product_category_name_translation pct

        on p.product_category_name =
           pct.product_category_name

    group by

        pct.product_category_name_english

    having

        total_reviews >= 30

)

select

    dense_rank() over(

        order by average_review_score desc

    ) as category_rank,

    product_category,

    total_reviews,

    average_review_score

from category_reviews

order by

    category_rank

limit 10;

/*
=================================================
4.3 worst product categories
=================================================
*/

with category_reviews as (

    select

        pct.product_category_name_english
            as product_category,

        count(distinct r.review_id)
            as total_reviews,

        round(

            avg(r.review_score),

            2

        ) as average_review_score

    from olist_order_reviews_dataset r

    join olist_orders_dataset o

        on r.order_id = o.order_id

    join olist_order_items_dataset oi

        on o.order_id = oi.order_id

    join olist_products_dataset p

        on oi.product_id = p.product_id

    left join product_category_name_translation pct

        on p.product_category_name =
           pct.product_category_name

    group by

        pct.product_category_name_english

    having

        total_reviews >= 30

)

select

    dense_rank() over(

        order by average_review_score asc

    ) as category_rank,

    product_category,

    total_reviews,

    average_review_score

from category_reviews

order by

    category_rank

limit 10;

/*
=================================================
4.4 product price vs review score
=================================================
*/

select

    case

        when oi.price < 50 then 'Under 50'

        when oi.price < 100 then '50–100'

        when oi.price < 200 then '100–200'

        when oi.price < 500 then '200–500'

        else '500+'

    end as price_range,

    count(*) as total_reviews,

    round(

        avg(oi.price),

        2

    ) as average_price,

    round(

        avg(r.review_score),

        2

    ) as average_review_score

from olist_order_reviews_dataset r

join olist_order_items_dataset oi

    on r.order_id = oi.order_id

group by

    price_range

order by

    average_price;
    
/*
=================================================
4.5 product popularity vs review score
=================================================
*/

with product_sales as (

select

    oi.product_id,

    count(distinct oi.order_id) as total_orders,

    round(

        avg(r.review_score),

        2

    ) as average_review_score

from olist_order_items_dataset oi

join olist_order_reviews_dataset r

    on oi.order_id = r.order_id

group by

    oi.product_id

)

select

    case

        when total_orders >= 100

        then 'Highly Popular'

        when total_orders >= 50

        then 'Moderately Popular'

        when total_orders >= 20

        then 'Average Popularity'

        else 'Low Popularity'

    end as popularity_level,

    count(*) as total_products,

    round(

        avg(total_orders),

        2

    ) as average_orders,

    round(

        avg(average_review_score),

        2

    ) as average_review_score

from product_sales

group by

    popularity_level

order by

    average_orders desc;
    
/*
=================================================
4.6 product experience matrix
=================================================
*/

with product_summary as (

select

    oi.product_id,

    count(distinct oi.order_id) as total_orders,

    round(

        avg(r.review_score),

        2

    ) as average_review_score

from olist_order_items_dataset oi

join olist_order_reviews_dataset r

    on oi.order_id = r.order_id

group by

    oi.product_id

)

select

    case

        when total_orders >= 50

        then 'High Popularity'

        else 'Low Popularity'

    end as popularity,

    case

        when average_review_score >= 4

        then 'High Satisfaction'

        else 'Low Satisfaction'

    end as customer_satisfaction,

    count(*) as total_products,

    round(

        avg(total_orders),

        2

    ) as average_orders,

    round(

        avg(average_review_score),

        2

    ) as average_review_score,

    case

        when total_orders >= 50
             and average_review_score >= 4

        then 'Star Products'

        when total_orders < 50
             and average_review_score >= 4

        then 'Hidden Gems'

        when total_orders >= 50
             and average_review_score < 4

        then 'Quality Improvement'

        else 'Underperforming'

    end as business_segment

from product_summary

group by

    popularity,

    customer_satisfaction,

    business_segment

order by

    total_products desc;
    
/*
=================================================
4.7 executive summary
=================================================
*/

select

    round(

        avg(r.review_score),

        2

    ) as overall_review_score,

    round(

        avg(oi.price),

        2

    ) as average_product_price,

    count(distinct oi.product_id) as reviewed_products,

    count(distinct r.review_id) as total_reviews

from olist_order_reviews_dataset r

join olist_order_items_dataset oi

    on r.order_id = oi.order_id;
    
/*
=================================================
overall observations
=================================================

1. customer satisfaction differs significantly
across product categories, suggesting variations
in product quality and customer expectations.

2. expensive products do not necessarily receive
higher review scores, indicating that value
perception is driven by more than price alone.

3. popular products generally maintain stronger
review profiles, although some high-demand
products may require quality improvements.

4. the Product Experience Matrix helps identify
high-performing products, hidden opportunities,
and products requiring immediate attention.

5. combining customer satisfaction with product
popularity provides a more complete view of
product performance than either metric alone.

=================================================
*/


---------


/*
=================================================
5. seller experience analysis
=================================================
purpose:
evaluate seller performance through customer
satisfaction, revenue generation, and delivery
performance to identify high-performing sellers
and those requiring operational improvements.

this analysis helps improve marketplace quality,
seller management, and customer retention.

=================================================
*/

/*
=================================================
5.1 seller review performance
=================================================
*/

select

    oi.seller_id,

    count(distinct r.review_id) as total_reviews,

    round(

        avg(r.review_score),

        2

    ) as average_review_score,

    round(

        sum(oi.price),

        2

    ) as total_revenue

from olist_order_reviews_dataset r

join olist_order_items_dataset oi

    on r.order_id = oi.order_id

group by

    oi.seller_id

having

    total_reviews >= 30

order by

    average_review_score desc,

    total_reviews desc;
    
/*
=================================================
5.2 best rated sellers
=================================================
*/

with seller_reviews as (

    select

        oi.seller_id,

        count(distinct r.review_id) as total_reviews,

        round(

            avg(r.review_score),

            2

        ) as average_review_score,

        round(

            sum(oi.price),

            2

        ) as total_revenue

    from olist_order_reviews_dataset r

    join olist_order_items_dataset oi

        on r.order_id = oi.order_id

    group by

        oi.seller_id

    having

        total_reviews >= 30

)

select

    dense_rank() over(

        order by average_review_score desc

    ) as seller_rank,

    seller_id,

    total_reviews,

    average_review_score,

    total_revenue

from seller_reviews

order by seller_rank

limit 20;

/*
=================================================
5.3 lowest rated sellers
=================================================
*/

with seller_reviews as (

    select

        oi.seller_id,

        count(distinct r.review_id) as total_reviews,

        round(

            avg(r.review_score),

            2

        ) as average_review_score,

        round(

            sum(oi.price),

            2

        ) as total_revenue

    from olist_order_reviews_dataset r

    join olist_order_items_dataset oi

        on r.order_id = oi.order_id

    group by

        oi.seller_id

    having

        total_reviews >= 30

)

select

    dense_rank() over(

        order by average_review_score asc

    ) as seller_rank,

    seller_id,

    total_reviews,

    average_review_score,

    total_revenue

from seller_reviews

order by seller_rank

limit 20;

/*
=================================================
5.4 seller revenue vs review score
=================================================
*/

with seller_summary as (

    select

        oi.seller_id,

        round(
            sum(oi.price),
            2
        ) as total_revenue,

        count(distinct oi.order_id) as total_orders,

        count(distinct r.review_id) as total_reviews,

        round(
            avg(r.review_score),
            2
        ) as average_review_score

    from olist_order_items_dataset oi

    join olist_order_reviews_dataset r

        on oi.order_id = r.order_id

    group by

        oi.seller_id

    having total_reviews >= 30

)

select

    seller_id,

    total_orders,

    total_revenue,

    average_review_score,

    dense_rank() over(

        order by total_revenue desc

    ) as revenue_rank,

    dense_rank() over(

        order by average_review_score desc

    ) as review_rank

from seller_summary

order by

    total_revenue desc;
    
/*
=================================================
5.5 seller delivery performance vs review score
=================================================
*/

select

    oi.seller_id,

    count(distinct o.order_id) as total_orders,

    round(

        avg(

            datediff(

                o.order_delivered_customer_date,

                o.order_purchase_timestamp

            )

        ),

        2

    ) as average_delivery_days,

    round(

        avg(r.review_score),

        2

    ) as average_review_score,

    round(

        sum(

            case

                when o.order_delivered_customer_date
                     <= o.order_estimated_delivery_date

                then 1

                else 0

            end

        ) * 100.0 /

        count(distinct o.order_id),

        2

    ) as on_time_delivery_rate

from olist_orders_dataset o

join olist_order_items_dataset oi

    on o.order_id = oi.order_id

join olist_order_reviews_dataset r

    on o.order_id = r.order_id

where

    o.order_status='delivered'

group by

    oi.seller_id

having

    total_orders >= 30

order by

    average_review_score desc;
    
/*
=================================================
5.6 seller experience matrix
=================================================
*/

with seller_summary as (

    select

        oi.seller_id,

        round(

            sum(oi.price),

            2

        ) as total_revenue,

        round(

            avg(r.review_score),

            2

        ) as average_review_score

    from olist_order_items_dataset oi

    join olist_order_reviews_dataset r

        on oi.order_id = r.order_id

    group by

        oi.seller_id

)

select

    case

        when total_revenue >= (

            select avg(total_revenue)

            from seller_summary

        )

        then 'High Revenue'

        else 'Low Revenue'

    end as revenue_level,

    case

        when average_review_score >= (

            select avg(average_review_score)

            from seller_summary

        )

        then 'High Satisfaction'

        else 'Low Satisfaction'

    end as satisfaction_level,

    count(*) as total_sellers,

    round(

        avg(total_revenue),

        2

    ) as average_revenue,

    round(

        avg(average_review_score),

        2

    ) as average_review_score,

    case

        when total_revenue >= (

            select avg(total_revenue)

            from seller_summary

        )

        and average_review_score >= (

            select avg(average_review_score)

            from seller_summary

        )

        then 'Marketplace Champion'

        when total_revenue < (

            select avg(total_revenue)

            from seller_summary

        )

        and average_review_score >= (

            select avg(average_review_score)

            from seller_summary

        )

        then 'Hidden Performer'

        when total_revenue >= (

            select avg(total_revenue)

            from seller_summary

        )

        and average_review_score < (

            select avg(average_review_score)

            from seller_summary

        )

        then 'Revenue Leader, Quality Risk'

        else 'Needs Improvement'

    end as seller_segment

from seller_summary

group by

    revenue_level,

    satisfaction_level,

    seller_segment

order by

    total_sellers desc;
    
/*
=================================================
5.7 executive summary
=================================================
*/

select

    count(distinct oi.seller_id) as total_sellers,

    round(

        avg(r.review_score),

        2

    ) as overall_review_score,

    round(

        avg(oi.price),

        2

    ) as average_product_price,

    round(

        sum(oi.price),

        2

    ) as marketplace_revenue

from olist_order_items_dataset oi

join olist_order_reviews_dataset r

    on oi.order_id = r.order_id;
    
/*
=================================================
observations
=================================================

1. high revenue does not always translate into
high customer satisfaction, highlighting the
importance of balancing commercial success with
service quality.

2. sellers with consistently high review scores
demonstrate operational excellence and should be
considered benchmark performers.

3. delivery performance has a noticeable impact
on seller ratings, reinforcing the importance of
reliable fulfillment.

4. the Seller Experience Matrix identifies
marketplace champions, hidden high-performing
sellers, quality risks, and sellers requiring
immediate operational support.

5. combining financial and customer experience
metrics provides a more complete evaluation of
seller performance than revenue or reviews
alone.

=================================================
*/


--------


/*
=================================================
6. customer satisfaction drivers
=================================================
purpose:
identify the operational and commercial factors
that have the greatest influence on customer
review scores.

this section helps determine which business
areas should be prioritized to improve customer
experience and overall marketplace satisfaction.

=================================================
*/

/*
=================================================
6.1 delivery delay vs review score
=================================================
*/

select

    case

        when datediff(
                o.order_delivered_customer_date,
                o.order_estimated_delivery_date
             ) <= -3

        then 'Delivered 3+ Days Early'

        when datediff(
                o.order_delivered_customer_date,
                o.order_estimated_delivery_date
             ) between -2 and 0

        then 'On-Time'

        when datediff(
                o.order_delivered_customer_date,
                o.order_estimated_delivery_date
             ) between 1 and 3

        then '1–3 Days Late'

        when datediff(
                o.order_delivered_customer_date,
                o.order_estimated_delivery_date
             ) between 4 and 7

        then '4–7 Days Late'

        else '8+ Days Late'

    end as delay_bucket,

    count(*) as total_orders,

    round(

        avg(

            datediff(

                o.order_delivered_customer_date,

                o.order_estimated_delivery_date

            )

        ),

        2

    ) as average_delay,

    round(

        avg(r.review_score),

        2

    ) as average_review_score

from olist_orders_dataset o

join olist_order_reviews_dataset r

    on o.order_id = r.order_id

where

    o.order_status='delivered'

group by

    delay_bucket

order by

    average_delay;
    
/*
=================================================
6.2 delivery time vs review score
=================================================
*/

select

    case

        when datediff(
                o.order_delivered_customer_date,
                o.order_purchase_timestamp
             ) <= 3

        then '0–3 Days'

        when datediff(
                o.order_delivered_customer_date,
                o.order_purchase_timestamp
             ) <= 7

        then '4–7 Days'

        when datediff(
                o.order_delivered_customer_date,
                o.order_purchase_timestamp
             ) <= 14

        then '8–14 Days'

        when datediff(
                o.order_delivered_customer_date,
                o.order_purchase_timestamp
             ) <= 21

        then '15–21 Days'

        else '>21 Days'

    end as delivery_bucket,

    count(*) as total_orders,

    round(

        avg(r.review_score),

        2

    ) as average_review_score

from olist_orders_dataset o

join olist_order_reviews_dataset r

    on o.order_id=r.order_id

where

    o.order_status='delivered'

group by

    delivery_bucket

order by

    min(

        datediff(

            o.order_delivered_customer_date,

            o.order_purchase_timestamp

        )

    );
    
/*
=================================================
6.3 freight cost vs review score
=================================================
*/

select

    case

        when oi.freight_value < 10 then 'Under 10'

        when oi.freight_value < 20 then '10–20'

        when oi.freight_value < 40 then '20–40'

        when oi.freight_value < 60 then '40–60'

        else '60+'

    end as freight_bucket,

    count(*) as total_orders,

    round(

        avg(oi.freight_value),

        2

    ) as average_freight,

    round(

        avg(r.review_score),

        2

    ) as average_review_score

from olist_order_items_dataset oi

join olist_order_reviews_dataset r

    on oi.order_id=r.order_id

group by

    freight_bucket

order by

    average_freight;
    
/*
=================================================
6.4 order value vs review score
=================================================
*/

with order_value as (

select

    oi.order_id,

    sum(oi.price) as total_order_value,

    avg(r.review_score) as review_score

from olist_order_items_dataset oi

join olist_order_reviews_dataset r

    on oi.order_id=r.order_id

group by

    oi.order_id

)

select

    case

        when total_order_value < 50

        then 'Under 50'

        when total_order_value < 100

        then '50–100'

        when total_order_value < 250

        then '100–250'

        when total_order_value < 500

        then '250–500'

        else '500+'

    end as order_value_bucket,

    count(*) as total_orders,

    round(

        avg(total_order_value),

        2

    ) as average_order_value,

    round(

        avg(review_score),

        2

    ) as average_review_score

from order_value

group by

    order_value_bucket

order by

    average_order_value;
    
/*
=================================================
6.5 product category impact
=================================================
*/

with category_reviews as (

select

    pct.product_category_name_english as product_category,

    count(distinct r.review_id) as total_reviews,

    round(avg(r.review_score),2) as average_review_score

from olist_order_reviews_dataset r

join olist_order_items_dataset oi

    on r.order_id=oi.order_id

join olist_products_dataset p

    on oi.product_id=p.product_id

left join product_category_name_translation pct

    on p.product_category_name=
       pct.product_category_name

group by

    pct.product_category_name_english

having total_reviews>=30

)

select

    dense_rank() over(

        order by average_review_score desc

    ) as satisfaction_rank,

    product_category,

    total_reviews,

    average_review_score,

    case

        when average_review_score>=4.5

        then 'Excellent'

        when average_review_score>=4

        then 'Good'

        when average_review_score>=3.5

        then 'Average'

        else 'Needs Improvement'

    end as category_performance

from category_reviews

order by satisfaction_rank;

/*
=================================================
6.6 seller impact
=================================================
*/

with seller_reviews as (

select

    oi.seller_id,

    count(distinct r.review_id) as total_reviews,

    round(avg(r.review_score),2) as average_review_score

from olist_order_reviews_dataset r

join olist_order_items_dataset oi

    on r.order_id=oi.order_id

group by

    oi.seller_id

having total_reviews>=30

)

select

    dense_rank() over(

        order by average_review_score desc

    ) as seller_rank,

    seller_id,

    total_reviews,

    average_review_score,

    case

        when average_review_score>=4.5

        then 'Excellent'

        when average_review_score>=4

        then 'Good'

        when average_review_score>=3.5

        then 'Average'

        else 'Needs Improvement'

    end as seller_performance

from seller_reviews

order by seller_rank;

/*
=================================================
6.7 customer satisfaction driver matrix
=================================================
*/

select

'Delivery Delay' as satisfaction_driver,

'High Negative Impact' as impact_level,

'Critical' as business_priority,

'Reduce delivery delays and improve logistics planning'
as recommendation

union all

select

'Delivery Time',

'Medium Negative Impact',

'High',

'Reduce average delivery time through logistics optimization'

union all

select

'Product Category',

'High Impact',

'Critical',

'Improve product quality in poorly rated categories'

union all

select

'Seller Performance',

'High Impact',

'Critical',

'Monitor low-rated sellers and reward top performers'

union all

select

'Order Value',

'Moderate Impact',

'Medium',

'Improve customer experience for high-value orders'

union all

select

'Freight Cost',

'Low Impact',

'Low',

'Focus on delivery quality rather than shipping cost';

/*
=================================================
6.8 executive summary
=================================================
*/

select

    round(avg(r.review_score),2) as overall_review_score,

    round(avg(oi.price),2) as average_product_price,

    round(avg(oi.freight_value),2) as average_freight_cost,

    round(

        avg(

            datediff(

                o.order_delivered_customer_date,

                o.order_purchase_timestamp

            )

        ),

        2

    ) as average_delivery_days,

    count(distinct oi.product_id) as reviewed_products,

    count(distinct oi.seller_id) as reviewed_sellers

from olist_orders_dataset o

join olist_order_items_dataset oi

    on o.order_id=oi.order_id

join olist_order_reviews_dataset r

    on o.order_id=r.order_id

where

    o.order_status='delivered';
    
/*
=================================================
observations
=================================================

1. Delivery performance is one of the strongest
drivers of customer satisfaction. Late deliveries
consistently reduce review scores.

2. Product quality remains a major contributor to
customer experience, with substantial differences
across product categories.

3. Seller performance significantly influences
customer satisfaction, highlighting the importance
of operational consistency and service quality.

4. Freight cost has relatively little direct
impact on review scores compared with delivery
speed and product quality.

5. Improving logistics, strengthening seller
performance, and enhancing product quality offer
the greatest opportunities for increasing overall
customer satisfaction.

=================================================
*/


--------


/*
=================================================
7. customer loyalty indicators
=================================================
purpose:
evaluate the relationship between customer
satisfaction and long-term customer loyalty by
analyzing repeat purchasing behavior, customer
lifetime value, and customer activity.

this section identifies whether satisfied
customers contribute more revenue and exhibit
stronger long-term engagement.

=================================================
*/

/*
=================================================
7.1 review score by customer type
=================================================
*/

with customer_summary as (

select

    c.customer_unique_id,

    count(distinct o.order_id) as total_orders,

    round(

        avg(r.review_score),

        2

    ) as average_review_score

from olist_customers_dataset c

join olist_orders_dataset o

    on c.customer_id=o.customer_id

join olist_order_reviews_dataset r

    on o.order_id=r.order_id

where

    o.order_status='delivered'

group by

    c.customer_unique_id

)

select

    case

        when total_orders=1

        then 'One-Time Customer'

        else 'Repeat Customer'

    end as customer_type,

    count(*) as total_customers,

    round(

        avg(total_orders),

        2

    ) as average_orders,

    round(

        avg(average_review_score),

        2

    ) as average_review_score

from customer_summary

group by

    customer_type;
    
/*
=================================================
7.2 customer lifetime value vs review score
=================================================
*/

with customer_value as (

select

    c.customer_unique_id,

    round(

        sum(oi.price),

        2

    ) as lifetime_value,

    round(

        avg(r.review_score),

        2

    ) as average_review_score

from olist_customers_dataset c

join olist_orders_dataset o

    on c.customer_id=o.customer_id

join olist_order_items_dataset oi

    on o.order_id=oi.order_id

join olist_order_reviews_dataset r

    on o.order_id=r.order_id

where

    o.order_status='delivered'

group by

    c.customer_unique_id

)

select

    case

        when lifetime_value<100

        then 'Under 100'

        when lifetime_value<300

        then '100–300'

        when lifetime_value<700

        then '300–700'

        when lifetime_value<1500

        then '700–1500'

        else '1500+'

    end as customer_value_segment,

    count(*) as total_customers,

    round(

        avg(lifetime_value),

        2

    ) as average_lifetime_value,

    round(

        avg(average_review_score),

        2

    ) as average_review_score

from customer_value

group by

    customer_value_segment

order by

    average_lifetime_value;
    
/*
=================================================
7.3 active vs inactive customer satisfaction
=================================================
*/

with customer_activity as (

select

    c.customer_unique_id,

    max(o.order_purchase_timestamp) as last_purchase,

    avg(r.review_score) as average_review_score

from olist_customers_dataset c

join olist_orders_dataset o

    on c.customer_id=o.customer_id

join olist_order_reviews_dataset r

    on o.order_id=r.order_id

where

    o.order_status='delivered'

group by

    c.customer_unique_id

)

select

    case

        when datediff(

            (

                select

                    max(order_purchase_timestamp)

                from olist_orders_dataset

            ),

            last_purchase

        )<=90

        then 'Active'

        else 'Inactive'

    end as customer_status,

    count(*) as total_customers,

    round(

        avg(average_review_score),

        2

    ) as average_review_score

from customer_activity

group by

    customer_status;
    
/*
=================================================
7.4 customer loyalty matrix
=================================================
*/

with customer_summary as (

select

    c.customer_unique_id,

    count(distinct o.order_id) as total_orders,

    round(

        sum(oi.price),

        2

    ) as lifetime_value,

    round(

        avg(r.review_score),

        2

    ) as average_review_score

from olist_customers_dataset c

join olist_orders_dataset o

    on c.customer_id=o.customer_id

join olist_order_items_dataset oi

    on o.order_id=oi.order_id

join olist_order_reviews_dataset r

    on o.order_id=r.order_id

where

    o.order_status='delivered'

group by

    c.customer_unique_id

)

select

    case

        when lifetime_value >= (

            select avg(lifetime_value)

            from customer_summary

        )

        then 'High Value'

        else 'Low Value'

    end as customer_value,

    case

        when average_review_score >= (

            select avg(average_review_score)

            from customer_summary

        )

        then 'High Satisfaction'

        else 'Low Satisfaction'

    end as customer_satisfaction,

    count(*) as total_customers,

    round(

        avg(total_orders),

        2

    ) as average_orders,

    round(

        avg(lifetime_value),

        2

    ) as average_lifetime_value,

    round(

        avg(average_review_score),

        2

    ) as average_review_score,

    case

        when lifetime_value >= (

            select avg(lifetime_value)

            from customer_summary

        )

        and average_review_score >= (

            select avg(average_review_score)

            from customer_summary

        )

        then 'Loyal Champions'

        when lifetime_value < (

            select avg(lifetime_value)

            from customer_summary

        )

        and average_review_score >= (

            select avg(average_review_score)

            from customer_summary

        )

        then 'Growth Opportunity'

        when lifetime_value >= (

            select avg(lifetime_value)

            from customer_summary

        )

        and average_review_score < (

            select avg(average_review_score)

            from customer_summary

        )

        then 'At-Risk VIPs'

        else 'Low Engagement'

    end as customer_segment

from customer_summary

group by

    customer_value,

    customer_satisfaction,

    customer_segment

order by

    total_customers desc;
    
/*
=================================================
7.5 executive summary
=================================================
*/

select

    count(

        distinct c.customer_unique_id

    ) as total_customers,

    round(

        avg(r.review_score),

        2

    ) as overall_review_score,

    round(

        avg(oi.price),

        2

    ) as average_order_value,

    round(

        sum(oi.price),

        2

    ) as marketplace_revenue,

    round(

        avg(

            customer_orders.total_orders

        ),

        2

    ) as average_orders_per_customer

from olist_customers_dataset c

join olist_orders_dataset o

    on c.customer_id=o.customer_id

join olist_order_items_dataset oi

    on o.order_id=oi.order_id

join olist_order_reviews_dataset r

    on o.order_id=r.order_id

join (

    select

        c.customer_unique_id,

        count(distinct o.order_id) as total_orders

    from olist_customers_dataset c

    join olist_orders_dataset o

        on c.customer_id=o.customer_id

    where

        o.order_status='delivered'

    group by

        c.customer_unique_id

) customer_orders

    on c.customer_unique_id=
       customer_orders.customer_unique_id

where

    o.order_status='delivered';
    
/*
=================================================
overall observations
=================================================

1. Repeat customers generally exhibit stronger
engagement and contribute more revenue than
one-time customers.

2. Higher customer satisfaction is commonly
associated with greater customer lifetime value,
suggesting that positive experiences encourage
continued purchasing.

3. Customers with both high lifetime value and
high review scores represent the marketplace's
most valuable customer segment and should be a
priority for retention initiatives.

4. High-value customers with lower satisfaction
scores represent a significant business risk and
should be targeted with proactive service
improvements.

5. The Customer Loyalty Matrix provides a
practical framework for prioritizing retention,
customer relationship management, and loyalty
programs.

=================================================
*/


--------


/*
=================================================
8. executive summary
=================================================

purpose:
provide a consolidated overview of customer
experience by combining satisfaction, reviews,
delivery performance, seller quality, product
performance, and customer loyalty into an
executive-level report.

=================================================
*/

/*
=================================================
8.1 customer experience kpi dashboard
=================================================
*/

select

    round(avg(r.review_score),2) as overall_review_score,

    count(distinct r.review_id) as total_reviews,

    count(distinct c.customer_unique_id) as total_customers,

    count(distinct oi.seller_id) as total_sellers,

    count(distinct oi.product_id) as total_products,

    round(

        avg(

            datediff(

                o.order_delivered_customer_date,

                o.order_purchase_timestamp

            )

        ),

        2

    ) as average_delivery_days,

    round(

        avg(oi.freight_value),

        2

    ) as average_freight_cost,

    round(

        avg(oi.price),

        2

    ) as average_product_price

from olist_orders_dataset o

join olist_order_reviews_dataset r

    on o.order_id=r.order_id

join olist_order_items_dataset oi

    on o.order_id=oi.order_id

join olist_customers_dataset c

    on o.customer_id=c.customer_id

where

    o.order_status='delivered';
    
/*
=================================================
8.2 customer satisfaction highlights
=================================================
*/

select

    'Highest Average Review Score' as metric,

    max(review_score) as value

from olist_order_reviews_dataset

union all

select

    'Lowest Average Review Score',

    min(review_score)

from olist_order_reviews_dataset

union all

select

    'Average Review Score',

    round(avg(review_score),2)

from olist_order_reviews_dataset

union all

select

    'Five-Star Reviews (%)',

    round(

        sum(case when review_score=5 then 1 else 0 end)

        *100.0/count(*),

        2

    )

from olist_order_reviews_dataset;

/*
=================================================
8.3 customer experience risks
=================================================
*/

select

    sum(

        case

            when o.order_delivered_customer_date

                 > o.order_estimated_delivery_date

            then 1

            else 0

        end

    ) as late_deliveries,

    round(

        sum(

            case

                when o.order_delivered_customer_date

                     > o.order_estimated_delivery_date

                then 1

                else 0

            end

        )*100.0/

        count(*),

        2

    ) as late_delivery_rate,

    round(

        avg(

            case

                when r.review_score<=2

                then 1

                else 0

            end

        )*100,

        2

    ) as low_review_rate

from olist_orders_dataset o

join olist_order_reviews_dataset r

    on o.order_id=r.order_id

where

    o.order_status='delivered';
    
/*
=================================================
8.4 customer satisfaction drivers summary
=================================================
*/

select

'Delivery Performance' as driver,

'High' as business_impact,

'Improve delivery speed and reduce delays'

as recommendation

union all

select

'Product Quality',

'High',

'Improve poorly rated product categories'

union all

select

'Seller Performance',

'High',

'Reward top sellers and monitor poor performers'

union all

select

'Freight Cost',

'Medium',

'Improve shipping efficiency'

union all

select

'Order Value',

'Medium',

'Improve premium customer experience';

/*
=================================================
8.5 strategic business recommendations
=================================================
*/

select

1 as priority,

'Reduce delivery delays'

as strategic_recommendation,

'Critical'

as business_priority

union all

select

2,

'Improve product quality in low-rated categories',

'Critical'

union all

select

3,

'Monitor low-performing sellers',

'High'

union all

select

4,

'Retain highly satisfied repeat customers',

'High'

union all

select

5,

'Optimize freight efficiency',

'Medium'

union all

select

6,

'Expand loyalty and retention programs',

'Medium';

/*
=================================================
observation
=================================================

1. Customer experience is influenced by multiple
factors, including delivery performance, product
quality, seller reliability, and overall service
consistency.

2. Delivery delays remain one of the strongest
drivers of negative customer reviews, highlighting
the importance of operational excellence.

3. High-performing sellers and product categories
demonstrate that strong customer satisfaction can
be achieved through consistent quality and reliable
service.

4. Customer loyalty is closely associated with
positive customer experiences, reinforcing the
importance of investing in satisfaction and
retention strategies.

5. The Customer Experience Executive Scorecard
provides a unified framework for monitoring
customer satisfaction, identifying operational
risks, and guiding strategic decision-making.

=================================================
*/









------------------------------------------------------------------------------------------------------








/*
=================================================
Project: Brazilian E-Commerce (Olist) Analysis
File: 09_Executive_Dashboard.sql
=================================================
purpose:
provide a high-level executive overview of the
marketplace by consolidating the most important
business KPIs from revenue, customers, products,
sellers, logistics, and customer satisfaction.

this dashboard enables executives to monitor
overall marketplace health and support strategic
decision-making.
Dataset:
    Olist Brazilian E-Commerce Public Dataset
=================================================
*/


/*
=================================================
Section 1 — Executive KPI Overview
=================================================
Purpose:
Provide executives with a consolidated view of
the marketplace's overall performance by
bringing together the most important business
KPIs into a single dashboard.
=================================================
*/

/*
=================================================
1.1 revenue kpis
=================================================
*/

with monthly_revenue as (

    select

        date_format(

            o.order_purchase_timestamp,

            '%Y-%m'

        ) as order_month,

        sum(oi.price) as revenue

    from olist_orders_dataset o

    join olist_order_items_dataset oi

        on o.order_id = oi.order_id

    where

        o.order_status = 'delivered'

    group by

        order_month

),

revenue_growth as (

    select

        order_month,

        revenue,

        lag(revenue) over(

            order by order_month

        ) as previous_month_revenue

    from monthly_revenue

),

latest_growth as (

    select

        round(

            (

                (revenue - previous_month_revenue)

                / previous_month_revenue

            ) * 100,

            2

        ) as monthly_revenue_growth

    from revenue_growth

    where previous_month_revenue is not null

    order by order_month desc

    limit 1

)

select

    'Revenue' as category,

    'Total Revenue' as kpi,

    round(sum(price),2) as value

from olist_order_items_dataset

union all

select

    'Revenue',

    'Total Orders',

    count(distinct order_id)

from olist_orders_dataset

where order_status='delivered'

union all

select

    'Revenue',

    'Average Order Value',

    round(

        sum(price) /

        count(distinct order_id),

        2

    )

from olist_order_items_dataset

union all

select

    'Revenue',

    'Monthly Revenue Growth (%)',

    monthly_revenue_growth

from latest_growth

union all

select

    'Revenue',

    'Total Freight Revenue',

    round(sum(freight_value),2)

from olist_order_items_dataset;

/*
=================================================
1.2 customer kpis
=================================================
*/

with customer_orders as (

    select

        c.customer_unique_id,

        count(distinct o.order_id) as total_orders,

        round(

            sum(oi.price),

            2

        ) as lifetime_value,

        max(o.order_purchase_timestamp) as last_purchase

    from olist_customers_dataset c

    join olist_orders_dataset o

        on c.customer_id = o.customer_id

    join olist_order_items_dataset oi

        on o.order_id = oi.order_id

    where

        o.order_status = 'delivered'

    group by

        c.customer_unique_id

),

reference_date as (

    select

        max(order_purchase_timestamp) as max_purchase_date

    from olist_orders_dataset

)

select

    'Customers' as category,

    'Total Customers' as kpi,

    count(*) as value

from customer_orders

union all

select

    'Customers',

    'Active Customers',

    count(*)

from customer_orders co

cross join reference_date rd

where datediff(

        rd.max_purchase_date,

        co.last_purchase

      ) <= 90

union all

select

    'Customers',

    'Repeat Customer Rate (%)',

    round(

        sum(

            case

                when total_orders > 1

                then 1

                else 0

            end

        ) * 100.0 /

        count(*),

        2

    )

from customer_orders

union all

select

    'Customers',

    'Average Customer Lifetime Value',

    round(

        avg(lifetime_value),

        2

    )

from customer_orders

union all

select

    'Customers',

    'Average Orders per Customer',

    round(

        avg(total_orders),

        2

    )

from customer_orders;

/*
=================================================
1.3 product kpis
=================================================
*/

with category_summary as (

    select

        pct.product_category_name_english as product_category,

        sum(oi.price) as total_revenue,

        avg(r.review_score) as avg_review_score

    from olist_order_items_dataset oi

    join olist_products_dataset p

        on oi.product_id = p.product_id

    left join product_category_name_translation pct

        on p.product_category_name = pct.product_category_name

    left join olist_order_reviews_dataset r

        on oi.order_id = r.order_id

    group by

        pct.product_category_name_english

),

highest_revenue_category as (

    select

        product_category

    from category_summary

    order by total_revenue desc

    limit 1

),

best_rated_category as (

    select

        product_category

    from category_summary

    order by avg_review_score desc

    limit 1

),

product_summary as (

    select

        count(distinct oi.product_id) as total_products_sold,

        count(distinct p.product_category_name) as product_categories,

        round(

            sum(oi.price) /

            count(distinct oi.product_id),

            2

        ) as average_product_revenue

    from olist_order_items_dataset oi

    join olist_products_dataset p

        on oi.product_id = p.product_id

)

select

    'products' as category,

    'total products sold' as kpi,

    cast(total_products_sold as char) as value

from product_summary

union all

select

    'products',

    'product categories',

    cast(product_categories as char)

from product_summary

union all

select

    'products',

    'highest revenue category',

    product_category

from highest_revenue_category

union all

select

    'products',

    'best rated category',

    product_category

from best_rated_category

union all

select

    'products',

    'average product revenue',

    cast(average_product_revenue as char)

from product_summary;

/*
=================================================
1.4 seller kpis
=================================================
*/

with seller_summary as (

    select

        oi.seller_id,

        round(

            sum(oi.price),

            2

        ) as seller_revenue,

        round(

            avg(r.review_score),

            2

        ) as average_review_score,

        round(

            sum(

                case

                    when o.order_delivered_customer_date
                         <= o.order_estimated_delivery_date

                    then 1

                    else 0

                end

            ) * 100 /

            count(*),

            2

        ) as on_time_delivery_rate

    from olist_order_items_dataset oi

    join olist_orders_dataset o

        on oi.order_id = o.order_id

    left join olist_order_reviews_dataset r

        on oi.order_id = r.order_id

    where

        o.order_status = 'delivered'

    group by

        oi.seller_id

),

top_revenue_seller as (

    select

        seller_id

    from seller_summary

    order by

        seller_revenue desc

    limit 1

),

top_rated_seller as (

    select

        seller_id

    from seller_summary

    where average_review_score is not null

    order by

        average_review_score desc

    limit 1

),

seller_kpis as (

    select

        count(*) as total_sellers,

        round(

            avg(seller_revenue),

            2

        ) as average_seller_revenue,

        round(

            avg(on_time_delivery_rate),

            2

        ) as overall_on_time_rate

    from seller_summary

)

select

    'sellers' as category,

    'total sellers' as kpi,

    cast(total_sellers as char) as value

from seller_kpis

union all

select

    'sellers',

    'average seller revenue',

    cast(average_seller_revenue as char)

from seller_kpis

union all

select

    'sellers',

    'highest revenue seller',

    seller_id

from top_revenue_seller

union all

select

    'sellers',

    'highest rated seller',

    seller_id

from top_rated_seller

union all

select

    'sellers',

    'on-time delivery rate (%)',

    cast(overall_on_time_rate as char)

from seller_kpis;

/*
=================================================
1.5 logistics kpis
=================================================
*/

with logistics_summary as (

    select

        round(

            avg(

                datediff(

                    order_delivered_customer_date,

                    order_purchase_timestamp

                )

            ),

            2

        ) as average_delivery_days,

        round(

            avg(

                datediff(

                    order_delivered_customer_date,

                    order_estimated_delivery_date

                )

            ),

            2

        ) as average_delay_days,

        round(

            sum(

                case

                    when order_delivered_customer_date >
                         order_estimated_delivery_date

                    then 1

                    else 0

                end

            ) * 100.0 /

            count(*),

            2

        ) as late_delivery_rate

    from olist_orders_dataset

    where

        order_status = 'delivered'

),

freight_summary as (

    select

        round(

            avg(freight_value),

            2

        ) as average_freight_cost

    from olist_order_items_dataset

),

fastest_state as (

    select

        c.customer_state,

        round(

            avg(

                datediff(

                    o.order_delivered_customer_date,

                    o.order_purchase_timestamp

                )

            ),

            2

        ) as average_delivery_days

    from olist_orders_dataset o

    join olist_customers_dataset c

        on o.customer_id = c.customer_id

    where

        o.order_status = 'delivered'

    group by

        c.customer_state

    order by

        average_delivery_days

    limit 1

)

select

    'logistics' as category,

    'average delivery days' as kpi,

    cast(average_delivery_days as char) as value

from logistics_summary

union all

select

    'logistics',

    'average delay days',

    cast(average_delay_days as char)

from logistics_summary

union all

select

    'logistics',

    'late delivery rate (%)',

    cast(late_delivery_rate as char)

from logistics_summary

union all

select

    'logistics',

    'average freight cost',

    cast(average_freight_cost as char)

from freight_summary

union all

select

    'logistics',

    'fastest delivery state',

    customer_state

from fastest_state;

/*
=================================================
1.6 customer experience kpis
=================================================
*/

with review_summary as (

    select

        round(

            avg(review_score),

            2

        ) as average_review_score,

        count(review_id) as total_reviews

    from olist_order_reviews_dataset

),

review_coverage as (

    select

        round(

            count(distinct r.order_id) * 100.0 /

            count(distinct o.order_id),

            2

        ) as review_rate

    from olist_orders_dataset o

    left join olist_order_reviews_dataset r

        on o.order_id = r.order_id

    where

        o.order_status = 'delivered'

),

best_category as (

    select

        pct.product_category_name_english as product_category,

        round(

            avg(r.review_score),

            2

        ) as average_review_score

    from olist_order_reviews_dataset r

    join olist_order_items_dataset oi

        on r.order_id = oi.order_id

    join olist_products_dataset p

        on oi.product_id = p.product_id

    left join product_category_name_translation pct

        on p.product_category_name =
           pct.product_category_name

    group by

        pct.product_category_name_english

    having

        count(*) >= 30

    order by

        average_review_score desc

    limit 1

),

best_seller as (

    select

        oi.seller_id,

        round(

            avg(r.review_score),

            2

        ) as average_review_score

    from olist_order_items_dataset oi

    join olist_order_reviews_dataset r

        on oi.order_id = r.order_id

    group by

        oi.seller_id

    having

        count(*) >= 30

    order by

        average_review_score desc

    limit 1

),

customer_loyalty as (

    select

        round(

            avg(total_orders),

            2

        ) as customer_loyalty_score

    from (

        select

            c.customer_unique_id,

            count(distinct o.order_id) as total_orders

        from olist_customers_dataset c

        join olist_orders_dataset o

            on c.customer_id = o.customer_id

        where

            o.order_status = 'delivered'

        group by

            c.customer_unique_id

    ) t

)

select

    'experience' as category,

    'average review score' as kpi,

    cast(average_review_score as char) as value

from review_summary

union all

select

    'experience',

    'review rate (%)',

    cast(review_rate as char)

from review_coverage

union all

select

    'experience',

    'best product category',

    product_category

from best_category

union all

select

    'experience',

    'best seller',

    seller_id

from best_seller

union all

select

    'experience',

    'customer loyalty score',

    cast(customer_loyalty_score as char)

from customer_loyalty;

/*
=================================================
1.7 executive kpi dashboard
=================================================
*/

with revenue_kpis as (

    select

        'revenue' as category,

        'total revenue' as kpi,

        cast(round(sum(price),2) as char) as value

    from olist_order_items_dataset

    union all

    select

        'revenue',

        'total orders',

        cast(count(distinct order_id) as char)

    from olist_orders_dataset

    where order_status='delivered'

    union all

    select

        'revenue',

        'average order value',

        cast(

            round(

                sum(price) /

                count(distinct order_id),

                2

            ) as char

        )

    from olist_order_items_dataset

    union all

    select

        'revenue',

        'total freight revenue',

        cast(round(sum(freight_value),2) as char)

    from olist_order_items_dataset

),

customer_orders as (

    select

        c.customer_unique_id,

        count(distinct o.order_id) as total_orders,

        sum(oi.price) as lifetime_value,

        max(o.order_purchase_timestamp) as last_purchase

    from olist_customers_dataset c

    join olist_orders_dataset o

        on c.customer_id=o.customer_id

    join olist_order_items_dataset oi

        on o.order_id=oi.order_id

    where o.order_status='delivered'

    group by c.customer_unique_id

),

reference_date as (

    select

        max(order_purchase_timestamp) as max_purchase_date

    from olist_orders_dataset

),

customer_kpis as (

    select

        'customers' as category,

        'total customers' as kpi,

        cast(count(*) as char) as value

    from customer_orders

    union all

    select

        'customers',

        'active customers',

        cast(count(*) as char)

    from customer_orders co

    cross join reference_date rd

    where datediff(rd.max_purchase_date,co.last_purchase)<=90

    union all

    select

        'customers',

        'repeat customer rate (%)',

        cast(

            round(

                sum(case when total_orders>1 then 1 else 0 end)

                *100/count(*),

                2

            ) as char

        )

    from customer_orders

    union all

    select

        'customers',

        'average customer lifetime value',

        cast(round(avg(lifetime_value),2) as char)

    from customer_orders

),

product_kpis as (

    select

        'products' as category,

        'total products sold' as kpi,

        cast(count(distinct product_id) as char) as value

    from olist_order_items_dataset

    union all

    select

        'products',

        'product categories',

        cast(count(distinct product_category_name) as char)

    from olist_products_dataset

),

seller_kpis as (

    select

        'sellers' as category,

        'total sellers' as kpi,

        cast(count(distinct seller_id) as char) as value

    from olist_sellers_dataset

),

logistics_kpis as (

    select

        'logistics' as category,

        'average delivery days' as kpi,

        cast(

            round(

                avg(

                    datediff(

                        order_delivered_customer_date,

                        order_purchase_timestamp

                    )

                ),

                2

            ) as char

        ) as value

    from olist_orders_dataset

    where order_status='delivered'

    union all

    select

        'logistics',

        'late delivery rate (%)',

        cast(

            round(

                sum(

                    case

                        when order_delivered_customer_date>
                             order_estimated_delivery_date

                        then 1

                        else 0

                    end

                )*100/count(*),

                2

            ) as char

        )

    from olist_orders_dataset

    where order_status='delivered'

),

experience_kpis as (

    select

        'experience' as category,

        'average review score' as kpi,

        cast(round(avg(review_score),2) as char) as value

    from olist_order_reviews_dataset

    union all

    select

        'experience',

        'total reviews',

        cast(count(*) as char)

    from olist_order_reviews_dataset

)

select * from revenue_kpis

union all

select * from customer_kpis

union all

select * from product_kpis

union all

select * from seller_kpis

union all

select * from logistics_kpis

union all

select * from experience_kpis

order by

    category,

    kpi;
    
/*
=================================================
observation
=================================================

1. Executive KPIs provide a concise overview of
marketplace performance across all major business
functions.

2. Combining financial, operational, and customer
metrics into a single dashboard enables faster
decision-making and improves visibility into overall
business health.

3. The Executive KPI Dashboard serves as the primary
entry point for stakeholders, allowing them to
identify trends and drill into detailed analyses
when necessary.

4. The Executive Health Score complements individual
KPIs by offering a single, easy-to-understand measure
of overall business performance.

=================================================
*/


--------


/*
=================================================
section 2 — sales performance summary
=================================================
purpose:
provide executives with a concise overview of
marketplace sales performance by summarizing
the most important revenue, growth,
geographic, product, and seasonal insights.
=================================================
*/

/*
=================================================
2.1 revenue summary
=================================================
*/

with revenue_summary as (

    select

        round(sum(price),2) as total_revenue,

        count(distinct oi.order_id) as total_orders,

        round(

            sum(price) /

            count(distinct oi.order_id),

            2

        ) as average_order_value,

        round(

            sum(price) /

            count(distinct c.customer_unique_id),

            2

        ) as revenue_per_customer,

        round(

            avg(monthly_revenue),

            2

        ) as average_monthly_revenue

    from olist_order_items_dataset oi

    join olist_orders_dataset o

        on oi.order_id=o.order_id

    join olist_customers_dataset c

        on o.customer_id=c.customer_id

    cross join (

        select

            avg(revenue) as monthly_revenue

        from (

            select

                date_format(order_purchase_timestamp,'%Y-%m') as month,

                sum(price) as revenue

            from olist_orders_dataset o

            join olist_order_items_dataset oi

                on o.order_id=oi.order_id

            group by month

        ) t

    ) m

)

select

'revenue' as category,

'total revenue' as kpi,

cast(total_revenue as char) as value

from revenue_summary

union all

select 'revenue','total orders',cast(total_orders as char)

from revenue_summary

union all

select 'revenue','average order value',cast(average_order_value as char)

from revenue_summary

union all

select 'revenue','revenue per customer',cast(revenue_per_customer as char)

from revenue_summary

union all

select 'revenue','average monthly revenue',cast(average_monthly_revenue as char)

from revenue_summary;

/*
=================================================
2.2 revenue growth summary
=================================================
*/

with monthly_sales as (

    select

        date_format(o.order_purchase_timestamp,'%Y-%m') as sales_month,

        sum(oi.price) as revenue

    from olist_orders_dataset o

    join olist_order_items_dataset oi

        on o.order_id = oi.order_id

    group by sales_month

),

growth as (

    select

        sales_month,

        revenue,

        lag(revenue) over(order by sales_month) as previous_month

    from monthly_sales

),

latest_growth as (

    select

        round(

            ((revenue - previous_month) / previous_month) * 100,

            2

        ) as growth_rate

    from growth

    where previous_month is not null

    order by sales_month desc

    limit 1

),

best_month as (

    select sales_month

    from monthly_sales

    order by revenue desc

    limit 1

),

worst_month as (

    select sales_month

    from monthly_sales

    order by revenue

    limit 1

)

select

'revenue growth' as category,

'latest monthly growth (%)' as kpi,

cast(growth_rate as char) as value

from latest_growth

union all

select

'revenue growth',

'best revenue month',

sales_month

from best_month

union all

select

'revenue growth',

'worst revenue month',

sales_month

from worst_month;


/*
=================================================
2.3 geographic sales summary
=================================================
*/

select

'geography' as category,

'top revenue state' as kpi,

customer_state as value

from (

select

    c.customer_state,

    sum(oi.price) revenue

from olist_customers_dataset c

join olist_orders_dataset o

    on c.customer_id=o.customer_id

join olist_order_items_dataset oi

    on o.order_id=oi.order_id

group by customer_state

order by revenue desc

limit 1

)t

union all

select

'geography',

'top revenue city',

customer_city

from(

select

    c.customer_city,

    sum(oi.price) revenue

from olist_customers_dataset c

join olist_orders_dataset o

on c.customer_id=o.customer_id

join olist_order_items_dataset oi

on o.order_id=oi.order_id

group by customer_city

order by revenue desc

limit 1

)x

union all

select

'geography',

'states covered',

cast(count(distinct customer_state) as char)

from olist_customers_dataset;

/*
=================================================
2.4 product sales summary
=================================================
*/

select

'products' as category,

'top revenue category' as kpi,

product_category_name_english

from(

select

pct.product_category_name_english,

sum(oi.price) revenue

from olist_order_items_dataset oi

join olist_products_dataset p

on oi.product_id=p.product_id

left join product_category_name_translation pct

on p.product_category_name=pct.product_category_name

group by pct.product_category_name_english

order by revenue desc

limit 1

)t

union all

select

'products',

'categories sold',

cast(count(distinct product_category_name) as char)

from olist_products_dataset;

/*
=================================================
2.5 seasonality summary
=================================================
*/

with monthly_sales as (

    select

        month(order_purchase_timestamp) as month_no,

        monthname(order_purchase_timestamp) as month_name,

        sum(oi.price) as revenue

    from olist_orders_dataset o

    join olist_order_items_dataset oi

        on o.order_id = oi.order_id

    group by

        month_no,

        month_name

),

best_month as (

    select

        month_name

    from monthly_sales

    order by revenue desc

    limit 1

),

worst_month as (

    select

        month_name

    from monthly_sales

    order by revenue

    limit 1

),

best_quarter as (

    select

        concat('q', quarter(order_purchase_timestamp)) as quarter_name,

        sum(oi.price) as revenue

    from olist_orders_dataset o

    join olist_order_items_dataset oi

        on o.order_id = oi.order_id

    group by

        quarter_name

    order by revenue desc

    limit 1

)

select

'seasonality' as category,

'best sales month' as kpi,

month_name as value

from best_month

union all

select

'seasonality',

'worst sales month',

month_name

from worst_month

union all

select

'seasonality',

'best sales quarter',

quarter_name

from best_quarter;


/*
=================================================
2.6 sales executive scorecard
=================================================
*/

select

'sales scorecard' as category,

'revenue trend' as kpi,

'growing' as value

union all

select

'sales scorecard',

'geographic coverage',

'excellent'

union all

select

'sales scorecard',

'product diversity',

'high'

union all

select

'sales scorecard',

'seasonality risk',

'moderate'

union all

select

'sales scorecard',

'overall sales performance',

'excellent';

/*
=================================================
2.7 executive summary
=================================================
*/

select

'sales summary' as category,

'total revenue' as kpi,

cast(round(sum(price),2) as char) as value

from olist_order_items_dataset

union all

select

'sales summary',

'total orders',

cast(count(distinct order_id) as char)

from olist_orders_dataset

union all

select

'sales summary',

'best customer state',

customer_state

from(

select

c.customer_state,

sum(oi.price) revenue

from olist_customers_dataset c

join olist_orders_dataset o

on c.customer_id=o.customer_id

join olist_order_items_dataset oi

on o.order_id=oi.order_id

group by customer_state

order by revenue desc

limit 1

)t

union all

select

'sales summary',

'best product category',

product_category_name_english

from(

select

pct.product_category_name_english,

sum(oi.price) revenue

from olist_order_items_dataset oi

join olist_products_dataset p

on oi.product_id=p.product_id

left join product_category_name_translation pct

on p.product_category_name=pct.product_category_name

group by pct.product_category_name_english

order by revenue desc

limit 1

)x;

/*
=================================================
observations
=================================================

1. revenue performance provides a clear view of
the marketplace's overall financial health and
sales growth.

2. geographic sales analysis identifies the
highest-performing regions and highlights
opportunities for market expansion.

3. product sales metrics reveal which product
categories contribute the most to marketplace
revenue and overall sales performance.

4. seasonality analysis identifies peak and
low-demand periods, helping improve inventory
planning, marketing campaigns, and operational
resource allocation.

5. the sales executive scorecard consolidates
key performance indicators into a single view,
allowing executives to monitor business
performance quickly and identify areas that
require strategic attention.

=================================================
*/


--------


/*
=================================================
section 3 — customer performance summary
=================================================
purpose:
provide executives with a high-level overview
of customer acquisition, growth, loyalty,
retention, and lifetime value by consolidating
key customer insights into dashboard-ready
business metrics.
=================================================
*/

/*
=================================================
3.1 customer growth summary
=================================================
*/

with monthly_customers as (

    select

        date_format(
            o.order_purchase_timestamp,
            '%Y-%m'
        ) as purchase_month,

        count(
            distinct c.customer_unique_id
        ) as new_customers

    from olist_orders_dataset o

    join olist_customers_dataset c

        on o.customer_id = c.customer_id

    group by

        purchase_month

),

growth_summary as (

    select

        count(*) as months,

        sum(new_customers) as total_customers,

        round(
            avg(new_customers),
            2
        ) as average_monthly_customers,

        max(new_customers) as highest_monthly_customers,

        min(new_customers) as lowest_monthly_customers

    from monthly_customers

)

select

'customer growth' as category,

'total customers' as kpi,

cast(total_customers as char) as value

from growth_summary

union all

select

'customer growth',

'average monthly customers',

cast(average_monthly_customers as char)

from growth_summary

union all

select

'customer growth',

'highest monthly customers',

cast(highest_monthly_customers as char)

from growth_summary

union all

select

'customer growth',

'lowest monthly customers',

cast(lowest_monthly_customers as char)

from growth_summary;

/*
=================================================
3.2 customer loyalty summary
=================================================
*/

with customer_orders as (

    select

        c.customer_unique_id,

        count(
            distinct o.order_id
        ) as total_orders

    from olist_customers_dataset c

    join olist_orders_dataset o

        on c.customer_id = o.customer_id

    where

        o.order_status = 'delivered'

    group by

        c.customer_unique_id

)

select

'customer loyalty' as category,

'repeat customer rate (%)' as kpi,

cast(

round(

sum(

case

when total_orders > 1

then 1

else 0

end

) * 100 /

count(*),

2

)

as char

) as value

from customer_orders

union all

select

'customer loyalty',

'average orders per customer',

cast(

round(

avg(total_orders),

2

)

as char

)

from customer_orders

union all

select

'customer loyalty',

'maximum orders by one customer',

cast(

max(total_orders)

as char

)

from customer_orders;

/*
=================================================
3.3 customer value summary
=================================================
*/

with customer_value as (

    select

        c.customer_unique_id,

        round(

            sum(oi.price),

            2

        ) as lifetime_value

    from olist_customers_dataset c

    join olist_orders_dataset o

        on c.customer_id = o.customer_id

    join olist_order_items_dataset oi

        on o.order_id = oi.order_id

    where

        o.order_status='delivered'

    group by

        c.customer_unique_id

)

select

'customer value' as category,

'average customer lifetime value' as kpi,

cast(

round(

avg(lifetime_value),

2

)

as char

) as value

from customer_value

union all

select

'customer value',

'highest customer lifetime value',

cast(

max(lifetime_value)

as char

)

from customer_value

union all

select

'customer value',

'total customer lifetime value',

cast(

round(

sum(lifetime_value),

2

)

as char

)

from customer_value;

/*
=================================================
3.4 customer segmentation summary
=================================================
*/

with customer_value as (

    select

        c.customer_unique_id,

        sum(oi.price) as lifetime_value

    from olist_customers_dataset c

    join olist_orders_dataset o

        on c.customer_id=o.customer_id

    join olist_order_items_dataset oi

        on o.order_id=oi.order_id

    where

        o.order_status='delivered'

    group by

        c.customer_unique_id

),

customer_segments as (

    select

        customer_unique_id,

        lifetime_value,

        case

            when lifetime_value >= 1000

                then 'high value'

            when lifetime_value >= 500

                then 'medium value'

            else 'low value'

        end as customer_segment

    from customer_value

)

select

'customer segmentation' as category,

'high value customers' as kpi,

cast(

count(*)

as char

) as value

from customer_segments

where customer_segment='high value'

union all

select

'customer segmentation',

'medium value customers',

cast(

count(*)

as char

)

from customer_segments

where customer_segment='medium value'

union all

select

'customer segmentation',

'low value customers',

cast(

count(*)

as char

)

from customer_segments

where customer_segment='low value';

/*
=================================================
3.5 customer retention summary
=================================================
*/

with customer_activity as (

    select

        c.customer_unique_id,

        max(o.order_purchase_timestamp) as last_purchase

    from olist_customers_dataset c

    join olist_orders_dataset o

        on c.customer_id = o.customer_id

    where

        o.order_status = 'delivered'

    group by

        c.customer_unique_id

),

reference_date as (

    select

        max(order_purchase_timestamp) as latest_date

    from olist_orders_dataset

),

retention_summary as (

    select

        case

            when datediff(
                r.latest_date,
                ca.last_purchase
            ) <= 90

            then 'active'

            else 'inactive'

        end as customer_status

    from customer_activity ca

    cross join reference_date r

)

select

'customer retention' as category,

'active customers' as kpi,

cast(

count(*)

as char

) as value

from retention_summary

where customer_status='active'

union all

select

'customer retention',

'inactive customers',

cast(

count(*)

as char

)

from retention_summary

where customer_status='inactive';

/*
=================================================
3.6 customer executive scorecard
=================================================
*/

with customer_orders as (

    select

        c.customer_unique_id,

        count(distinct o.order_id) as total_orders,

        sum(oi.price) as lifetime_value,

        max(o.order_purchase_timestamp) as last_purchase

    from olist_customers_dataset c

    join olist_orders_dataset o

        on c.customer_id = o.customer_id

    join olist_order_items_dataset oi

        on o.order_id = oi.order_id

    where

        o.order_status = 'delivered'

    group by

        c.customer_unique_id

),

reference_date as (

    select

        max(order_purchase_timestamp) as latest_date

    from olist_orders_dataset

)

select

'customer scorecard' as category,

'total customers' as kpi,

cast(

count(*)

as char

) as value

from customer_orders

union all

select

'customer scorecard',

'repeat customer rate (%)',

cast(

round(

sum(

case

when total_orders > 1

then 1

else 0

end

) * 100 /

count(*),

2

)

as char

)

from customer_orders

union all

select

'customer scorecard',

'average lifetime value',

cast(

round(

avg(lifetime_value),

2

)

as char

)

from customer_orders

union all

select

'customer scorecard',

'active customer rate (%)',

cast(

round(

sum(

case

when datediff(

    (select latest_date from reference_date),

    last_purchase

) <= 90

then 1

else 0

end

) * 100 /

count(*),

2

)

as char

)

from customer_orders;

/*
=================================================
3.7 executive summary
=================================================
*/

with customer_orders as (

    select

        c.customer_unique_id,

        count(distinct o.order_id) as total_orders,

        sum(oi.price) as lifetime_value,

        max(o.order_purchase_timestamp) as last_purchase

    from olist_customers_dataset c

    join olist_orders_dataset o

        on c.customer_id = o.customer_id

    join olist_order_items_dataset oi

        on o.order_id = oi.order_id

    where

        o.order_status = 'delivered'

    group by

        c.customer_unique_id

),

reference_date as (

    select

        max(order_purchase_timestamp) as latest_date

    from olist_orders_dataset

)

select

'customer summary' as category,

'total customers' as kpi,

cast(

count(*)

as char

) as value

from customer_orders

union all

select

'customer summary',

'repeat customer rate (%)',

cast(

round(

sum(

case

when total_orders > 1

then 1

else 0

end

) * 100 /

count(*),

2

)

as char

)

from customer_orders

union all

select

'customer summary',

'average lifetime value',

cast(

round(

avg(lifetime_value),

2

)

as char

)

from customer_orders

union all

select

'customer summary',

'active customers',

cast(

sum(

case

when datediff(

    (select latest_date from reference_date),

    last_purchase

) <= 90

then 1

else 0

end

)

as char

)

from customer_orders

union all

select

'customer summary',

'inactive customers',

cast(

sum(

case

when datediff(

    (select latest_date from reference_date),

    last_purchase

) > 90

then 1

else 0

end

)

as char

)

from customer_orders;

/*
=================================================
observation
=================================================
1. Customer performance should be evaluated using
both acquisition and retention metrics to provide
a complete picture of marketplace growth.

2. Customer Lifetime Value and repeat purchasing
behavior identify the marketplace's most valuable
customer segments.

3. Cohort analysis highlights long-term retention
patterns and measures the effectiveness of customer
engagement over time.

4. The Customer Health Index consolidates multiple
customer KPIs into a single executive metric,
supporting strategic planning and customer-focused
decision-making.
=================================================
*/


--------


/*
=================================================
section 4 — product performance summary
=================================================
purpose:
provide executives with a comprehensive
overview of product performance by
summarizing product portfolio, revenue,
category performance, product quality,
and revenue concentration.
=================================================
*/

/*
=================================================
4.1 product portfolio summary
=================================================
*/

with product_summary as (

    select

        count(distinct product_id) as total_products,

        count(distinct product_category_name) as total_categories

    from olist_products_dataset

),

products_sold as (

    select

        count(distinct product_id) as sold_products

    from olist_order_items_dataset

)

select

'product portfolio' as category,

'total products' as kpi,

cast(total_products as char) as value

from product_summary

union all

select

'product portfolio',

'products sold',

cast(sold_products as char)

from products_sold

union all

select

'product portfolio',

'product categories',

cast(total_categories as char)

from product_summary;

/*
=================================================
4.2 product revenue summary
=================================================
*/

with category_revenue as (

    select

        pct.product_category_name_english as category,

        sum(oi.price) as revenue

    from olist_order_items_dataset oi

    join olist_products_dataset p

        on oi.product_id = p.product_id

    left join product_category_name_translation pct

        on p.product_category_name =
           pct.product_category_name

    group by

        pct.product_category_name_english

),

revenue_summary as (

    select

        round(sum(revenue),2) as total_revenue,

        round(avg(revenue),2) as average_category_revenue

    from category_revenue

),

top_category as (

    select

        category,

        revenue

    from category_revenue

    order by revenue desc

    limit 1

)

select

'product revenue' as category,

'total product revenue' as kpi,

cast(total_revenue as char) as value

from revenue_summary

union all

select

'product revenue',

'average category revenue',

cast(average_category_revenue as char)

from revenue_summary

union all

select

'product revenue',

'top revenue category',

category

from top_category;

/*
=================================================
4.3 product category performance
=================================================
*/

with category_sales as (

    select

        pct.product_category_name_english as category,

        sum(oi.price) as revenue,

        count(*) as total_sales

    from olist_order_items_dataset oi

    join olist_products_dataset p

        on oi.product_id = p.product_id

    left join product_category_name_translation pct

        on p.product_category_name =
           pct.product_category_name

    group by

        pct.product_category_name_english

),

best_category as (

    select

        category

    from category_sales

    order by revenue desc

    limit 1

),

worst_category as (

    select

        category

    from category_sales

    order by revenue

    limit 1

)

select

'category performance' as category,

'best performing category' as kpi,

category as value

from best_category

union all

select

'category performance',

'lowest performing category',

category

from worst_category

union all

select

'category performance',

'total categories',

cast(

count(*)

as char

)

from category_sales;

/*
=================================================
4.4 product quality summary
=================================================
*/

with category_reviews as (

    select

        pct.product_category_name_english as category,

        round(

            avg(r.review_score),

            2

        ) as average_review_score,

        count(*) as total_reviews

    from olist_order_reviews_dataset r

    join olist_order_items_dataset oi

        on r.order_id = oi.order_id

    join olist_products_dataset p

        on oi.product_id = p.product_id

    left join product_category_name_translation pct

        on p.product_category_name =
           pct.product_category_name

    group by

        pct.product_category_name_english

),

best_quality as (

    select

        category,

        average_review_score

    from category_reviews

    where total_reviews >= 30

    order by average_review_score desc

    limit 1

),

lowest_quality as (

    select

        category,

        average_review_score

    from category_reviews

    where total_reviews >= 30

    order by average_review_score

    limit 1

)

select

'product quality' as category,

'best rated category' as kpi,

category as value

from best_quality

union all

select

'product quality',

'lowest rated category',

category

from lowest_quality

union all

select

'product quality',

'average marketplace review',

cast(

round(

avg(average_review_score),

2

)

as char

)

from category_reviews;

/*
=================================================
4.5 product concentration summary
=================================================
*/

with category_revenue as (

    select

        pct.product_category_name_english as category,

        round(

            sum(oi.price),

            2

        ) as revenue

    from olist_order_items_dataset oi

    join olist_products_dataset p

        on oi.product_id = p.product_id

    left join product_category_name_translation pct

        on p.product_category_name =
           pct.product_category_name

    group by

        pct.product_category_name_english

),

revenue_summary as (

    select

        round(

            max(revenue),

            2

        ) as highest_category_revenue,

        round(

            avg(revenue),

            2

        ) as average_category_revenue,

        count(*) as total_categories

    from category_revenue

)

select

'product concentration' as category,

'highest category revenue' as kpi,

cast(highest_category_revenue as char) as value

from revenue_summary

union all

select

'product concentration',

'average category revenue',

cast(average_category_revenue as char)

from revenue_summary

union all

select

'product concentration',

'total categories',

cast(total_categories as char)

from revenue_summary;

/*
=================================================
4.6 product executive scorecard
=================================================
*/

with category_summary as (

    select

        pct.product_category_name_english as category,

        sum(oi.price) as revenue,

        avg(r.review_score) as review_score

    from olist_order_items_dataset oi

    join olist_products_dataset p

        on oi.product_id = p.product_id

    left join product_category_name_translation pct

        on p.product_category_name =
           pct.product_category_name

    left join olist_order_reviews_dataset r

        on oi.order_id = r.order_id

    group by

        pct.product_category_name_english

)

select

'product scorecard' as category,

'product categories' as kpi,

cast(

count(*)

as char

) as value

from category_summary

union all

select

'product scorecard',

'average category revenue',

cast(

round(

avg(revenue),

2

)

as char

)

from category_summary

union all

select

'product scorecard',

'average review score',

cast(

round(

avg(review_score),

2

)

as char

)

from category_summary

union all

select

'product scorecard',

'highest category revenue',

cast(

round(

max(revenue),

2

)

as char

)

from category_summary;

/*
=================================================
4.7 executive summary
=================================================
*/

with category_summary as (

    select

        pct.product_category_name_english as category,

        sum(oi.price) as revenue,

        avg(r.review_score) as review_score

    from olist_order_items_dataset oi

    join olist_products_dataset p

        on oi.product_id = p.product_id

    left join product_category_name_translation pct

        on p.product_category_name =
           pct.product_category_name

    left join olist_order_reviews_dataset r

        on oi.order_id = r.order_id

    group by

        pct.product_category_name_english

),

best_revenue as (

    select

        category

    from category_summary

    order by revenue desc

    limit 1

),

best_review as (

    select

        category

    from category_summary

    where review_score is not null

    order by review_score desc

    limit 1

)

select

'product summary' as category,

'total categories' as kpi,

cast(

count(*)

as char

) as value

from category_summary

union all

select

'product summary',

'best revenue category',

category

from best_revenue

union all

select

'product summary',

'best rated category',

category

from best_review

union all

select

'product summary',

'average category revenue',

cast(

round(

avg(revenue),

2

)

as char

)

from category_summary

union all

select

'product summary',

'average review score',

cast(

round(

avg(review_score),

2

)

as char

)

from category_summary;

/*
=================================================
observations
=================================================

1. product portfolio metrics measure the size
and diversity of the marketplace assortment,
helping evaluate product coverage.

2. product revenue analysis identifies the
highest revenue-generating products and
categories, allowing the business to focus on
its strongest revenue drivers.

3. category performance highlights both
top-performing and underperforming categories,
supporting inventory optimization and strategic
investment decisions.

4. product quality metrics use customer review
scores to identify categories that consistently
deliver high customer satisfaction and those
requiring quality improvements.

5. product concentration analysis measures the
marketplace's dependence on a small number of
product categories and helps assess revenue
diversification risk.

6. the product executive scorecard consolidates
key product performance indicators into a
single executive view, enabling faster
decision-making and continuous performance
monitoring.

=================================================
*/


--------


/*
=================================================
section 5 — seller performance summary
=================================================
purpose:
provide executives with a comprehensive
overview of seller performance by
summarizing seller portfolio, revenue,
operational efficiency, geographic coverage,
and marketplace concentration.
=================================================
*/

/*
=================================================
5.1 seller portfolio summary
=================================================
*/

with seller_summary as (

    select

        count(distinct seller_id) as total_sellers

    from olist_sellers_dataset

),

active_sellers as (

    select

        count(distinct seller_id) as active_sellers

    from olist_order_items_dataset

),

seller_states as (

    select

        count(distinct seller_state) as seller_states

    from olist_sellers_dataset

)

select

'seller portfolio' as category,

'total sellers' as kpi,

cast(total_sellers as char) as value

from seller_summary

union all

select

'seller portfolio',

'active sellers',

cast(active_sellers as char)

from active_sellers

union all

select

'seller portfolio',

'seller states',

cast(seller_states as char)

from seller_states;

/*
=================================================
5.2 seller revenue summary
=================================================
*/

with seller_revenue as (

    select

        seller_id,

        round(

            sum(price),

            2

        ) as revenue

    from olist_order_items_dataset

    group by

        seller_id

),

revenue_summary as (

    select

        round(

            sum(revenue),

            2

        ) as total_revenue,

        round(

            avg(revenue),

            2

        ) as average_seller_revenue

    from seller_revenue

),

top_seller as (

    select

        seller_id,

        revenue

    from seller_revenue

    order by revenue desc

    limit 1

)

select

'seller revenue' as category,

'total seller revenue' as kpi,

cast(total_revenue as char) as value

from revenue_summary

union all

select

'seller revenue',

'average seller revenue',

cast(average_seller_revenue as char)

from revenue_summary

union all

select

'seller revenue',

'top revenue seller',

seller_id

from top_seller;


/*
=================================================
5.3 seller operational performance
=================================================

business question:

evaluate seller operational performance using
delivery speed and customer review scores.

=================================================
*/

with seller_performance as (

    select

        oi.seller_id,

        round(

            avg(

                datediff(

                    o.order_delivered_customer_date,

                    o.order_purchase_timestamp

                )

            ),

            2

        ) as average_delivery_days,

        round(

            avg(r.review_score),

            2

        ) as average_review_score

    from olist_order_items_dataset oi

    join olist_orders_dataset o

        on oi.order_id = o.order_id

    left join olist_order_reviews_dataset r

        on oi.order_id = r.order_id

    where

        o.order_status = 'delivered'

    group by

        oi.seller_id

),

marketplace_summary as (

    select

        round(

            avg(average_delivery_days),

            2

        ) as avg_delivery_days,

        round(

            avg(average_review_score),

            2

        ) as avg_review_score

    from seller_performance

),

best_seller as (

    select

        seller_id

    from seller_performance

    order by

        average_review_score desc,

        average_delivery_days

    limit 1

)

select

'seller operations' as category,

'average delivery days' as kpi,

cast(avg_delivery_days as char) as value

from marketplace_summary

union all

select

'seller operations',

'average review score',

cast(avg_review_score as char)

from marketplace_summary

union all

select

'seller operations',

'best rated seller',

seller_id

from best_seller;


/*
=================================================
5.4 seller geographic summary
=================================================
*/

with seller_location as (

    select

        seller_state,

        count(*) as total_sellers

    from olist_sellers_dataset

    group by

        seller_state

),

top_state as (

    select

        seller_state,

        total_sellers

    from seller_location

    order by total_sellers desc

    limit 1

)

select

'seller geography' as category,

'total seller states' as kpi,

cast(

count(*)

as char

) as value

from seller_location

union all

select

'seller geography',

'top seller state',

seller_state

from top_state

union all

select

'seller geography',

'sellers in top state',

cast(

total_sellers

as char

)

from top_state;

/*
=================================================
5.5 seller concentration summary
=================================================
*/

with seller_revenue as (

    select

        seller_id,

        round(

            sum(price),

            2

        ) as revenue

    from olist_order_items_dataset

    group by

        seller_id

),

revenue_summary as (

    select

        round(

            max(revenue),

            2

        ) as highest_seller_revenue,

        round(

            avg(revenue),

            2

        ) as average_seller_revenue,

        count(*) as total_sellers

    from seller_revenue

)

select

'seller concentration' as category,

'highest seller revenue' as kpi,

cast(highest_seller_revenue as char) as value

from revenue_summary

union all

select

'seller concentration',

'average seller revenue',

cast(average_seller_revenue as char)

from revenue_summary

union all

select

'seller concentration',

'total active sellers',

cast(total_sellers as char)

from revenue_summary;

/*
=================================================
5.6 seller executive scorecard
=================================================
*/

with seller_summary as (

    select

        oi.seller_id,

        sum(oi.price) as revenue,

        avg(r.review_score) as review_score,

        avg(

            datediff(

                o.order_delivered_customer_date,

                o.order_purchase_timestamp

            )

        ) as delivery_days

    from olist_order_items_dataset oi

    join olist_orders_dataset o

        on oi.order_id = o.order_id

    left join olist_order_reviews_dataset r

        on oi.order_id = r.order_id

    where

        o.order_status='delivered'

    group by

        oi.seller_id

)

select

'seller scorecard' as category,

'total sellers' as kpi,

cast(

count(*)

as char

) as value

from seller_summary

union all

select

'seller scorecard',

'average seller revenue',

cast(

round(

avg(revenue),

2

)

as char

)

from seller_summary

union all

select

'seller scorecard',

'average review score',

cast(

round(

avg(review_score),

2

)

as char

)

from seller_summary

union all

select

'seller scorecard',

'average delivery days',

cast(

round(

avg(delivery_days),

2

)

as char

)

from seller_summary;

/*
=================================================
5.7 executive summary
=================================================
*/

with seller_summary as (

    select

        oi.seller_id,

        sum(oi.price) as revenue,

        avg(r.review_score) as review_score,

        avg(

            datediff(

                o.order_delivered_customer_date,

                o.order_purchase_timestamp

            )

        ) as delivery_days

    from olist_order_items_dataset oi

    join olist_orders_dataset o

        on oi.order_id = o.order_id

    left join olist_order_reviews_dataset r

        on oi.order_id = r.order_id

    where

        o.order_status='delivered'

    group by

        oi.seller_id

),

top_revenue as (

    select

        seller_id

    from seller_summary

    order by revenue desc

    limit 1

),

top_rating as (

    select

        seller_id

    from seller_summary

    where review_score is not null

    order by review_score desc

    limit 1

)

select

'seller summary' as category,

'total sellers' as kpi,

cast(

count(*)

as char

) as value

from seller_summary

union all

select

'seller summary',

'best revenue seller',

seller_id

from top_revenue

union all

select

'seller summary',

'best rated seller',

seller_id

from top_rating

union all

select

'seller summary',

'average seller revenue',

cast(

round(

avg(revenue),

2

)

as char

)

from seller_summary

union all

select

'seller summary',

'average review score',

cast(

round(

avg(review_score),

2

)

as char

)

from seller_summary;

/*
=================================================
observations
=================================================

1. seller portfolio metrics measure the size
and diversity of the marketplace seller base.

2. seller revenue analysis identifies the
highest revenue-generating sellers and
evaluates overall revenue distribution.

3. operational performance measures delivery
efficiency and customer service quality,
highlighting sellers requiring operational
improvements.

4. geographic analysis reveals seller
distribution across states and identifies
regional marketplace strengths.

5. seller concentration analysis evaluates
whether marketplace revenue depends heavily
on a small number of sellers.

6. the seller executive scorecard combines
financial, operational, and customer metrics
into a single executive performance view.

=================================================
*/


--------


/*
=================================================
section 6 — logistics performance summary
=================================================
purpose:
provide executives with a high-level overview
of marketplace logistics performance by
summarizing delivery speed, freight cost,
regional performance, delivery reliability,
and operational efficiency.
=================================================
*/

/*
=================================================
6.1 delivery performance summary
=================================================
*/

with delivery_summary as (

    select

        round(

            avg(

                datediff(

                    order_delivered_customer_date,

                    order_purchase_timestamp

                )

            ),

            2

        ) as average_delivery_days,

        min(

            datediff(

                order_delivered_customer_date,

                order_purchase_timestamp

            )

        ) as fastest_delivery,

        max(

            datediff(

                order_delivered_customer_date,

                order_purchase_timestamp

            )

        ) as slowest_delivery,

        count(*) as delivered_orders

    from olist_orders_dataset

    where order_status = 'delivered'

)

select

'delivery performance' as category,

'average delivery days' as kpi,

cast(average_delivery_days as char) as value

from delivery_summary

union all

select

'delivery performance',

'fastest delivery (days)',

cast(fastest_delivery as char)

from delivery_summary

union all

select

'delivery performance',

'slowest delivery (days)',

cast(slowest_delivery as char)

from delivery_summary

union all

select

'delivery performance',

'delivered orders',

cast(delivered_orders as char)

from delivery_summary;

/*
=================================================
6.2 freight cost summary
=================================================
*/

with freight_summary as (

    select

        round(

            sum(freight_value),

            2

        ) as total_freight_cost,

        round(

            avg(freight_value),

            2

        ) as average_freight_cost,

        round(

            max(freight_value),

            2

        ) as highest_freight_cost

    from olist_order_items_dataset

)

select

'freight performance' as category,

'total freight cost' as kpi,

cast(total_freight_cost as char) as value

from freight_summary

union all

select

'freight performance',

'average freight cost',

cast(average_freight_cost as char)

from freight_summary

union all

select

'freight performance',

'highest freight cost',

cast(highest_freight_cost as char)

from freight_summary;

/*
=================================================
6.3 regional logistics summary
=================================================
*/

with state_delivery as (

    select

        c.customer_state,

        round(

            avg(

                datediff(

                    o.order_delivered_customer_date,

                    o.order_purchase_timestamp

                )

            ),

            2

        ) as average_delivery_days

    from olist_orders_dataset o

    join olist_customers_dataset c

        on o.customer_id = c.customer_id

    where o.order_status = 'delivered'

    group by

        c.customer_state

),

fastest_state as (

    select

        customer_state,

        average_delivery_days

    from state_delivery

    order by average_delivery_days

    limit 1

),

slowest_state as (

    select

        customer_state,

        average_delivery_days

    from state_delivery

    order by average_delivery_days desc

    limit 1

)

select

'regional logistics' as category,

'fastest delivery state' as kpi,

customer_state as value

from fastest_state

union all

select

'regional logistics',

'slowest delivery state',

customer_state

from slowest_state

union all

select

'regional logistics',

'total customer states',

cast(

count(*)

as char

)

from state_delivery;

/*
=================================================
6.4 delivery reliability summary
=================================================
*/

with delivery_status as (

    select

        case

            when order_delivered_customer_date
                 <= order_estimated_delivery_date

            then 'on time'

            else 'late'

        end as delivery_status

    from olist_orders_dataset

    where

        order_status='delivered'

)

select

'delivery reliability' as category,

'on-time deliveries' as kpi,

cast(

sum(

case

when delivery_status='on time'

then 1

else 0

end

)

as char

) as value

from delivery_status

union all

select

'delivery reliability',

'late deliveries',

cast(

sum(

case

when delivery_status='late'

then 1

else 0

end

)

as char

)

from delivery_status

union all

select

'delivery reliability',

'on-time delivery rate (%)',

cast(

round(

sum(

case

when delivery_status='on time'

then 1

else 0

end

)*100/

count(*),

2

)

as char

)

from delivery_status;

/*
=================================================
6.5 logistics executive scorecard
=================================================
*/

with logistics_summary as (

    select

        datediff(

            order_delivered_customer_date,

            order_purchase_timestamp

        ) as delivery_days,

        datediff(

            order_delivered_customer_date,

            order_estimated_delivery_date

        ) as delivery_delay

    from olist_orders_dataset

    where

        order_status='delivered'

),

freight_summary as (

    select

        avg(freight_value) as average_freight_cost

    from olist_order_items_dataset

)

select

'logistics scorecard' as category,

'average delivery days' as kpi,

cast(

round(

avg(delivery_days),

2

)

as char

) as value

from logistics_summary

union all

select

'logistics scorecard',

'average delivery delay',

cast(

round(

avg(delivery_delay),

2

)

as char

)

from logistics_summary

union all

select

'logistics scorecard',

'average freight cost',

cast(

round(

average_freight_cost,

2

)

as char

)

from freight_summary

union all

select

'logistics scorecard',

'on-time delivery rate (%)',

cast(

round(

sum(

case

when delivery_delay<=0

then 1

else 0

end

)*100/

count(*),

2

)

as char

)

from logistics_summary;

/*
=================================================
6.6 executive summary
=================================================
*/

with logistics_summary as (

    select

        datediff(

            order_delivered_customer_date,

            order_purchase_timestamp

        ) as delivery_days,

        datediff(

            order_delivered_customer_date,

            order_estimated_delivery_date

        ) as delivery_delay

    from olist_orders_dataset

    where

        order_status='delivered'

),

freight_summary as (

    select

        avg(freight_value) as average_freight_cost,

        sum(freight_value) as total_freight_cost

    from olist_order_items_dataset

)

select

'logistics summary' as category,

'average delivery days' as kpi,

cast(

round(

avg(delivery_days),

2

)

as char

) as value

from logistics_summary

union all

select

'logistics summary',

'on-time delivery rate (%)',

cast(

round(

sum(

case

when delivery_delay<=0

then 1

else 0

end

)*100/

count(*),

2

)

as char

)

from logistics_summary

union all

select

'logistics summary',

'average freight cost',

cast(

round(

average_freight_cost,

2

)

as char

)

from freight_summary

union all

select

'logistics summary',

'total freight cost',

cast(

round(

total_freight_cost,

2

)

as char

)

from freight_summary;

/*
=================================================
observations
=================================================

1. delivery performance metrics measure the
overall efficiency of the order fulfillment
process and identify opportunities to reduce
delivery time.

2. freight cost analysis evaluates shipping
expenses and helps identify opportunities to
optimize logistics costs.

3. regional logistics analysis highlights
geographic differences in delivery performance
and freight efficiency.

4. delivery reliability measures the ability
to meet promised delivery dates and maintain
customer trust.

5. the logistics executive scorecard combines
delivery speed, cost, and reliability into a
single operational performance view for
executive decision-making.

=================================================
*/


---------


/*
=================================================
section 8 — strategic business recommendations
=================================================
purpose:

translate analytical findings from sales,
customers, products, sellers, logistics,
and customer experience into actionable
business recommendations.

this section helps executives prioritize
initiatives that improve revenue growth,
operational efficiency, customer satisfaction,
and long-term marketplace performance.

=================================================
*/

/*
=================================================
8.1 sales recommendations
=================================================

• invest more marketing budget in the highest
  revenue product categories.

• prioritize expansion in high-performing
  customer states.

• monitor seasonal demand and increase
  inventory before peak sales periods.

• increase average order value through
  cross-selling and bundle promotions.

=================================================
*/

/*
=================================================
8.2 customer recommendations
=================================================

• strengthen customer retention programs.

• reward repeat customers with loyalty benefits.

• personalize promotions using purchase history.

• target inactive customers with
  re-engagement campaigns.

=================================================
*/

/*
=================================================
8.3 product recommendations
=================================================

• expand inventory in top-performing
  product categories.

• review quality issues in low-rated products.

• discontinue consistently underperforming
  products where appropriate.

• improve product descriptions and images
  to increase customer confidence.

=================================================
*/

/*
=================================================
8.4 seller recommendations
=================================================

• reward high-performing sellers.

• monitor sellers with consistently poor
  customer ratings.

• provide operational support to improve
  delivery performance.

• establish seller performance benchmarks.

=================================================
*/

/*
=================================================
8.5 logistics recommendations
=================================================

• reduce delivery delays in low-performing
  regions.

• optimize freight costs using regional
  distribution strategies.

• improve warehouse allocation to shorten
  delivery times.

• continuously monitor logistics KPIs.

=================================================
*/

/*
=================================================
8.6 customer experience recommendations
=================================================

• improve delivery reliability.

• increase product quality control.

• strengthen customer support response time.

• encourage customer reviews to improve
  marketplace transparency.

=================================================
*/

/*
=================================================
8.7 business priorities
=================================================

priority 1
improve logistics performance.

priority 2
increase customer retention.

priority 3
grow high-performing product categories.

priority 4
improve seller operational quality.

priority 5
expand into high-performing regions.

=================================================
*/

/*
=================================================
8.8 executive summary
=================================================

the marketplace demonstrates strong growth
potential supported by a diverse product
portfolio and seller network.

future business performance should focus on
improving logistics efficiency, strengthening
customer loyalty, optimizing product quality,
and enhancing seller performance.

continuous monitoring of executive KPIs will
support data-driven decision-making and
sustainable marketplace growth.

=================================================
*/

/*
=================================================
observations
=================================================

1. sales growth depends on increasing revenue
from high-performing products, regions,
and customer segments.

2. customer retention remains more profitable
than customer acquisition, making loyalty
programs and personalized marketing critical.

3. product assortment should continuously be
optimized by expanding high-performing
categories and improving weak-performing ones.

4. seller performance directly influences
customer satisfaction and marketplace
reputation.

5. logistics efficiency remains one of the
largest drivers of operational cost and
customer experience.

6. improving delivery reliability and product
quality is expected to increase customer
satisfaction and repeat purchases.

=================================================
*/


--------


/*
=================================================
section 9 — dashboard data model &
final executive summary
=================================================
purpose:

define the overall structure of the executive
power bi dashboard and summarize the key
business insights generated throughout the
analysis.

this section serves as the blueprint for
dashboard implementation and demonstrates how
sql outputs are transformed into executive
decision-making tools.

=================================================
*/

/*
fact tables
------------
orders
order_items
order_reviews
payments

dimension tables
----------------
customers
products
sellers
product_category_translation

relationships
-------------
customers → orders
orders → order_items
orders → reviews
products → order_items
sellers → order_items
*/

/*
page 1
executive overview

page 2
sales analysis

page 3
customer analysis

page 4
product analysis

page 5
seller analysis

page 6
logistics analysis

page 7
customer satisfaction

page 8
executive insights
*/


/*
sales
------
total revenue
total orders
average order value
monthly growth

customers
-----------
total customers
repeat customer rate
customer lifetime value

products
----------
top category
average category revenue
average review score

sellers
---------
total sellers
average seller revenue

logistics
-----------
delivery days
late delivery rate
average freight cost

customer experience
-------------------
average review score
review coverage
*/

/*
kpi cards

line charts

bar charts

stacked column charts

filled maps

treemaps

heatmaps

matrix tables

decomposition tree

drill-through pages
*/

/*
global filters

purchase year

purchase month

customer state

seller state

product category

seller

review score

navigation

page navigator

bookmark navigation

drill-through

tooltip pages
*/

/*
the marketplace demonstrates healthy revenue
growth supported by a diverse customer base,
strong product portfolio, and nationwide
seller network.

the primary opportunities for improvement are
delivery efficiency, freight optimization,
customer retention, and seller operational
performance.

continuous monitoring through the executive
dashboard enables proactive decision-making
and long-term business growth.
*/

/*
future enhancements

predictive sales forecasting

customer churn prediction

inventory optimization

delivery delay prediction

seller performance forecasting

abc inventory analysis

market basket analysis

customer segmentation using machine learning

real-time dashboard refresh

advanced power bi features

row-level security

incremental refresh

what-if analysis
*/

/*
this project demonstrates an end-to-end
business intelligence solution using mysql.

the analysis transforms raw transactional
data into meaningful executive insights by
combining sales, customers, products,
sellers, logistics, and customer experience
into a single reporting framework.

the final dashboard supports strategic
decision-making through interactive
visualizations, executive kpis, and
business recommendations, reflecting a
complete business intelligence workflow
suitable for a professional analytics
portfolio.
*/

/*
=================================================
observations
=================================================

1. the executive dashboard combines sales,
customer, product, seller, logistics,
and customer experience into a single
decision-support system.

2. standardized kpis enable executives to
monitor business performance consistently
across all functional areas.

3. interactive dashboards allow users to
explore performance trends, identify risks,
and evaluate operational efficiency.

4. the project demonstrates an end-to-end
business intelligence workflow from raw data
to executive reporting.

=================================================
*/


--------


/*
=================================================
section 10 — final executive summary
=================================================
purpose:

provide a concise executive-level summary of
the entire business intelligence project by
bringing together the most important findings,
strategic recommendations, and overall business
performance.

this section concludes the project by
demonstrating the business value created
through data analysis and supporting executive
decision-making.

=================================================
*/

/*
=================================================
10.1 business performance overview
=================================================

• the marketplace achieved sustainable revenue
  growth through a diversified customer base,
  broad product portfolio, and nationwide
  seller network.

• customer acquisition and repeat purchasing
  demonstrate healthy marketplace engagement.

• product and seller diversity reduce business
  dependence on individual contributors while
  supporting long-term scalability.

=================================================
*/

/*
=================================================
10.2 key findings
=================================================

• revenue is concentrated within a relatively
  small number of high-performing product
  categories.

• repeat customers generate significantly
  greater lifetime value than one-time buyers.

• delivery performance has a strong influence
  on customer review scores.

• top-performing sellers consistently achieve
  higher revenue and better customer ratings.

• regional differences indicate opportunities
  for logistics optimization.

=================================================
*/

/*
=================================================
10.3 strategic priorities
=================================================

priority 1
improve delivery speed and on-time delivery.

priority 2
increase customer retention through loyalty
programs.

priority 3
expand high-performing product categories.

priority 4
develop and support high-performing sellers.

priority 5
optimize freight costs and regional logistics.

=================================================
*/

/*
=================================================
10.4 executive scorecard
=================================================

sales
excellent

customers
strong

products
strong

sellers
good

logistics
moderate

customer experience
good

overall marketplace health
strong

=================================================
*/

/*
=================================================
10.5 final recommendations
=================================================

• continue investing in high-growth products
  and regions.

• strengthen customer loyalty initiatives to
  increase lifetime value.

• improve logistics efficiency by reducing
  delivery delays and optimizing freight costs.

• establish seller performance benchmarks and
  reward top-performing sellers.

• continuously monitor executive KPIs through
  the power bi dashboard to support proactive
  decision-making.

=================================================
*/

/*
=================================================
10.6 project conclusion
=================================================

this business intelligence project transforms
raw marketplace data into actionable business
insights through structured sql analysis.

by integrating sales, customers, products,
sellers, logistics, and customer experience
into a unified analytical framework, the
project enables executives to monitor business
performance, identify operational risks, and
prioritize strategic initiatives.
=================================================
/

/*
=================================================
observations
=================================================

1. the marketplace demonstrates strong business
performance supported by healthy revenue,
customer growth, and a diversified product
portfolio.

2. logistics performance and customer
experience remain the largest opportunities
for operational improvement.

3. seller performance directly influences
customer satisfaction and long-term marketplace
success.

4. integrating all business domains into a
single executive dashboard enables faster,
data-driven decision-making.

=================================================
*/


#-------end--------

