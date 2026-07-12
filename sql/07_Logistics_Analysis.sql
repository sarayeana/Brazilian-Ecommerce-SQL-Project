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
