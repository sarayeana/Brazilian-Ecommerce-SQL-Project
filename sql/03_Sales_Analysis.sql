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
10.5 hourly shopping pattern
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
