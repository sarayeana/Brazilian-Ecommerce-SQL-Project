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
