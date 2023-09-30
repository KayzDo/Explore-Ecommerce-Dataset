# Explore-Ecommerce-Dataset
Utilized SQL in Google BigQuery to write and execute queries to find the desired data
# [SQL] Explore Ecommerce Dataset
## I. Introduction
This project contains an eCommerce dataset that I will explore using SQL on [Google BigQuery](https://cloud.google.com/bigquery). The dataset is based on the Google Analytics public dataset and contains data from an eCommerce website.
## II. Requirements
* [Google Cloud Platform account](https://cloud.google.com)
* Project on Google Cloud Platform
* [Google BigQuery API](https://cloud.google.com/bigquery/docs/enable-transfer-service#:~:text=Enable%20the%20BigQuery%20Data%20Transfer%20Service,-Before%20you%20can&text=Open%20the%20BigQuery%20Data%20Transfer,Click%20the%20ENABLE%20button.) enabled
* [SQL query editor](https://cloud.google.com/monitoring/mql/query-editor) or IDE
## III. Dataset Access
The eCommerce dataset is stored in a public Google BigQuery dataset. To access the dataset, follow these steps:
* Log in to your Google Cloud Platform account and create a new project.
* Navigate to the BigQuery console and select your newly created project.
* In the navigation panel, select "Add Data" and then "Search a project".
* Enter the project ID **"bigquery-public-data.google_analytics_sample.ga_sessions"** and click "Enter".
* Click on the **"ga_sessions_"** table to open it.
## IV. Exploring the Dataset
In this project, I will write 08 query in Bigquery base on Google Analytics dataset
### Query 01: Calculate total visit, pageview, transaction and revenue for January, February and March 2017 order by month
* SQL code

```
SELECT
  format_date("%Y%m", parse_date("%Y%m%d", date)) as month,
  SUM(totals.visits) AS visits,
  SUM(totals.pageviews) AS pageviews,
  SUM(totals.transactions) AS transactions,
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
WHERE _TABLE_SUFFIX BETWEEN '0101' AND '0331'
GROUP BY 1
ORDER BY 1
```
* Query results

![image](https://user-images.githubusercontent.com/101726623/235141359-1648197b-6339-42ca-b2a2-3dce9f39283b.png)

### Query 02: Bounce rate per traffic source in July 2017 (Bounce_rate = num_bounce/total_visit) (order by total_visit DESC)
* SQL code

```
SELECT
    trafficSource.source as source,
    sum(totals.visits) as total_visits,
    sum(totals.Bounces) as total_no_of_bounces,
    (sum(totals.Bounces)/sum(totals.visits))* 100 as bounce_rate
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
GROUP BY source
ORDER BY total_visits DESC

```
* Query results

![image](https://user-images.githubusercontent.com/101726623/235142182-87c47ea0-4cae-41b8-8204-f17d774914d3.png)

### Query 3: Revenue by traffic source by week, by month in June 2017
* SQL code

```
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
```
* Query results

![image](https://user-images.githubusercontent.com/101726623/235142590-e0fec692-794c-4247-a659-433ce605c158.png)

### Query 04: Average number of product pageviews by purchaser type (purchasers vs non-purchasers) in June, July 2017
* SQL code

```
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
```
* Query results

![image](https://user-images.githubusercontent.com/101726623/235143315-8d87f354-351b-4218-ac77-bf8c0f9e716b.png)

### Query 05: Average number of transactions per user that made a purchase in July 2017
* SQL code

```
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
```
* Query results

![image](https://user-images.githubusercontent.com/101726623/235143708-06c7b447-5c1e-44bb-89ae-c5fed537bd92.png)

### Query 06: Average amount of money spent per session. Only include purchaser data in July 2017
* SQL code

```
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
```
* Query results

![image](https://user-images.githubusercontent.com/101726623/235144083-3499b416-0388-46ea-850f-30006e1b4ede.png)

### Query 07: Other products purchased by customers who purchased product "YouTube Men's Vintage Henley" in July 2017. Output should show product name and the quantity was ordered.
* SQL code

```
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
```
* Query results

![image](https://user-images.githubusercontent.com/101726623/235146847-e367b16c-38f0-484e-8c89-85dfa1b69499.png)

### Query 08: Calculate cohort map from pageview to addtocart to purchase in last 3 month.
* SQL code

```
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
```
* Query results

![image](https://user-images.githubusercontent.com/101726623/235148311-a2d83174-9bf3-43e3-aed1-47030af40b3b.png)

## V. Conclusion
* In conclusion, my exploration of the eCommerce dataset using SQL on Google BigQuery based on the Google Analytics dataset has revealed several interesting insights.
* By exploring eCommerce dataset, I have gained valuable information about total visits, pageview, transactions, bounce rate, and revenue per traffic source,.... which could inform future business decisions.
* To deep dive into the insights and key trends, the next step will visualize the data with some software like Power BI,Tableau,...
* **Overall**, this project has demonstrated the power of using SQL and big data tools like Google BigQuery to gain insights into large datasets.
