/*
===========================================
Brazilian E-Commerce Dataset
SQL Project
===========================================
Author : Sara Yeana
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

Author: Sara Yeana
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
