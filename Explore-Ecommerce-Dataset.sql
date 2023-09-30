-- Big project for SQL

-- Query 01: calculate total visit, pageview, transaction and revenue for Jan, Feb and March 2017 order by month
#standardSQL
--SOLUTION

SELECT
  format_date("%Y%m", parse_date("%Y%m%d", date)) as month,
  SUM(totals.visits) AS visits,
  SUM(totals.pageviews) AS pageviews,
  SUM(totals.transactions) AS transactions,
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
WHERE _TABLE_SUFFIX BETWEEN '0101' AND '0331'
GROUP BY 1
ORDER BY 1

-- Query 02: Bounce rate per traffic source in July 2017 (Bounce_rate = num_bounce/total_visit) (order by total_visit DESC)
#standardSQL
-- SOLUTION
SELECT
    trafficSource.source as source,
    sum(totals.visits) as total_visits,
    sum(totals.Bounces) as total_no_of_bounces,
    (sum(totals.Bounces)/sum(totals.visits))* 100 as bounce_rate
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
GROUP BY source
ORDER BY total_visits DESC

-- Query 3: Revenue by traffic source by week, by month in June 2017
--SOLUTION 

with mth as (
select 
 'Month' as time_type
 ,format_timestamp("%Y%m",cast(date as date format 'YYYYMMDD')) as time
 ,trafficSource.source as source
 ,sum(product.productRevenue)/1000000 as revenue
from `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
,unnest(hits) hits
,unnest(hits.product) product
where _table_suffix between '0601' and '0630'
group by time, source
order by revenue desc
)
, wk as (
select 
 'Week' as time_type
 ,format_timestamp("%Y%W",cast(date as date format 'YYYYMMDD')) as time
 ,trafficSource.source as source
 ,sum(product.productRevenue)/1000000 as revenue
from `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
,unnest(hits) hits
,unnest(hits.product) product
where _table_suffix between '0601' and '0630'
group by time, source
order by revenue desc
)
select *
from (select *
      from mth
      union all
      select *
      from wk
    )
order by revenue desc

--Query 04: Average number of product pageviews by purchaser type (purchasers vs non-purchasers) in June, July 2017. Note: totals.transactions >=1 for purchaser and totals.transactions is null for non-purchaser
#standardSQL
--SOLUTION
  
with purchase as (
SELECT 
 substr(date,1,6) as month
 ,sum(totals.pageviews)/count(distinct fullVisitorId) as avg_pageviews_purchase
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
,unnest(hits) hits
,unnest(hits.product) product
where _table_suffix between '0601' and '0731'
and totals.transactions >=1
and product.productRevenue is not null
group by month
)
,non_purchase as (
SELECT 
 substr(date,1,6) as month
 ,sum(totals.pageviews)/count(distinct fullVisitorId) as avg_pageviews_non_purchase
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
,unnest(hits) hits
,unnest(hits.product) product
where _table_suffix between '0601' and '0731'
and totals.transactions is null
and product.productRevenue is null
group by month
)
select
 purchase.month
 ,avg_pageviews_purchase
 ,avg_pageviews_non_purchase
from purchase
left join non_purchase
on purchase.month = non_purchase.month
order by purchase.month asc

-- Query 05: Average number of transactions per user that made a purchase in July 2017
#standardSQL
-- SOLUTION

SELECT 
 substr(date,1,6) as month
 ,sum(totals.transactions)/count(distinct fullVisitorId) as Avg_total_transactions_per_user
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
,unnest(hits) hits
,unnest(hits.product) product
where _table_suffix between '0701' and '0731'
and totals.transactions >=1
and product.productRevenue is not null
group by month

-- Query 06: Average amount of money spent per session. Only include purchaser data in July 2017
#standardSQL
--SOLUTION
  
SELECT 
 substr(date,1,6) as month
 ,round((sum(product.productRevenue)/1000000)/sum(totals.visits),2) as avg_revenue_by_user_per_visit
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
,unnest(hits) hits
,unnest(hits.product) product
where _table_suffix between '0701' and '0731'
and totals.transactions is not null
and product.productRevenue is not null
group by month
  
-- Query 07: Other products purchased by customers who purchased product "YouTube Men's Vintage Henley" in July 2017. Output should show product name and the quantity was ordered.
#standardSQL
--SOLUTION
  
SELECT 
 product.v2ProductName as other_purchased_products
 ,sum(product.productQuantity) as quantity
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
,unnest(hits) hits
,unnest(hits.product) product
where _table_suffix between '0701' and '0731'
and product.productRevenue is not null
and product.v2ProductName <> "YouTube Men's Vintage Henley"
and fullVisitorId in (
  SELECT 
 fullVisitorId
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
,unnest(hits) hits
,unnest(hits.product) product
where _table_suffix between '0701' and '0731'
and product.productRevenue is not null
and product.v2ProductName = "YouTube Men's Vintage Henley"
group by fullVisitorId
) 
group by product.v2ProductName
order by quantity desc

--Query 08: Calculate cohort map from pageview to addtocart to purchase in last 3 month. For example, 100% pageview then 40% add_to_cart and 10% purchase.
#standardSQL
--SOLUTION 

-- Solution 1: Use CTE
with get_1month_cohort as (SELECT  
  CASE WHEN 1 = 1 THEN "201701" END AS month,
  COUNT(CASE WHEN hits.eCommerceAction.action_type = "2" AND product.isImpression IS NULL THEN fullVisitorId END) AS 
num_product_view,
  COUNT(CASE WHEN hits.eCommerceAction.action_type = "3" AND product.isImpression IS NULL THEN fullVisitorId END) AS 
num_addtocart,
  COUNT(CASE WHEN hits.eCommerceAction.action_type = "6" AND product.isImpression IS NULL THEN fullVisitorId END) AS 
num_purchase,
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201701*` ,
UNNEST(hits) as hits,
UNNEST(hits.product) as product),

get_2month_cohort as (SELECT  
  CASE WHEN 1 = 1 THEN "201702" END AS month,
  COUNT(CASE WHEN hits.eCommerceAction.action_type = "2" AND product.isImpression IS NULL THEN fullVisitorId END) AS 
num_product_view,
  COUNT(CASE WHEN hits.eCommerceAction.action_type = "3" AND product.isImpression IS NULL THEN fullVisitorId END) AS 
num_addtocart,
  COUNT(CASE WHEN hits.eCommerceAction.action_type = "6" AND product.isImpression IS NULL THEN fullVisitorId END) AS 
num_purchase,
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201702*` ,
UNNEST(hits) as hits,
UNNEST(hits.product) as product),

get_3month_cohort as (SELECT  
  CASE WHEN 1 = 1 THEN "201703" END AS month,
  COUNT(CASE WHEN hits.eCommerceAction.action_type = "2" AND product.isImpression IS NULL THEN fullVisitorId END) AS 
num_product_view,
  COUNT(CASE WHEN hits.eCommerceAction.action_type = "3" AND product.isImpression IS NULL THEN fullVisitorId END) AS 
num_addtocart,
  COUNT(CASE WHEN hits.eCommerceAction.action_type = "6" AND product.isImpression IS NULL THEN fullVisitorId END) AS 
num_purchase,
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201703*` ,
UNNEST(hits) as hits,
UNNEST(hits.product) as product)

select 
month,
num_product_view,
num_addtocart,
num_purchase,
ROUND(num_addtocart/num_product_view*100,2) as add_to_cart_rate,
ROUND(num_purchase/num_product_view*100,2) as purchase_rate
from 
(SELECT * FROM get_1month_cohort
UNION ALL 
SELECT * FROM get_2month_cohort
UNION ALL
SELECT * FROM get_3month_cohort)
ORDER BY month;

-- Solution 2: Use Count(when) or Sum(when)
select
    format_date('%Y%m', parse_date('%Y%m%d',date)) as month,
    count(CASE WHEN eCommerceAction.action_type = '2' THEN product.v2ProductName END) as num_product_view,
    count(CASE WHEN eCommerceAction.action_type = '3' THEN product.v2ProductName END) as num_add_to_cart,
    count(CASE WHEN eCommerceAction.action_type = '6' and product.productRevenue is not null THEN product.v2ProductName END) as num_purchase
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
,UNNEST(hits) as hits
,UNNEST (hits.product) as product
where _table_suffix between '20170101' and '20170331'
and eCommerceAction.action_type in ('2','3','6')
group by month
order by month
)

select
    *,
    round(num_add_to_cart/num_product_view * 100, 2) as add_to_cart_rate,
    round(num_purchase/num_product_view * 100, 2) as purchase_rate
from product_data; 
