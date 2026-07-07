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
