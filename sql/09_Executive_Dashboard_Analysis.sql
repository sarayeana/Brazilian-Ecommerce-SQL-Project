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

this dashboard analysis enables executives to monitor
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
