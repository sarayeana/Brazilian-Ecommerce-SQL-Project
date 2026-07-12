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
