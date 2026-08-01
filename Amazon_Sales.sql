CREATE DATABASE amazon_sales;
USE amazon_sales;

CREATE TABLE sales_data (
    `index` INT,
    `Order ID` VARCHAR(30),
    `Date` VARCHAR(20),
    `Status` VARCHAR(50),
    `Fulfilment` VARCHAR(20),
    `Sales Channel` VARCHAR(20),
    `ship-service-level` VARCHAR(20),
    `Style` VARCHAR(20),
    `SKU` VARCHAR(50),
    `Category` VARCHAR(30),
    `Size` VARCHAR(15),
    `ASIN` VARCHAR(20),
    `Courier Status` VARCHAR(25),
    `Qty` INT,
    `currency` VARCHAR(10),
    `Amount` VARCHAR(20),
    `ship-city` VARCHAR(75),
    `ship-state` VARCHAR(50),
    `ship-postal-code` VARCHAR(30),
    `ship-country` VARCHAR(10),
    `promotion-ids` TEXT,
    `B2B` VARCHAR(10),
    `fulfilled-by` VARCHAR(25),
    `Amount_Status` VARCHAR(50),
    `Amount_Clean` DECIMAL(12,2),
    `Status_Group` VARCHAR(40)
);

SET GLOBAL local_infile = 1;

 -- USING "LOAD DATA LOCAL INFILE" Method because it is the absolute fastest way to ingest bulk data into a MySQL database. -- 
LOAD DATA LOCAL INFILE 'C:/Users/Prateek/OneDrive/Desktop/Sales_clean.csv'
INTO TABLE sales_data
CHARACTER SET latin1
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

select count(*) from sales_data;

-- changing data type of date column from text to date type -- 
UPDATE sales_data
SET  `Date` = STR_TO_DATE(`Date`,'%d-%m-%Y');

 -- Dropped Amount since it has around 8000 blank cells and we already have another amount column  where blank cells has "0" -- 
alter table sales_data
drop column Amount;

  -- KPIs (Total Revenue, Average Order Value, Cancellation Rate) -- 
  
select sum(amount_clean) as total_revenue,
       sum(amount_clean)/count('Order ID') as Avg_order_value,
       sum(status = 'Cancelled')*100/count('Order ID') as Cancellation_rate
from sales_data;

-- Revenue By Order -- 
select Category,
       sum(amount_clean) as revenue_by_category
       from sales_data
	   group by category
       order by revenue_by_category DESC;
       
	-- Monthly Revenue -- 
SELECT DATE_FORMAT(`Date`,'%b %Y') as Month_,
	   sum(amount_clean) as monthly_trend
FROM sales_data
GROUP BY DATE_FORMAT(`Date`, '%b %Y')
ORDER BY monthly_trend DESC;

  -- Revenue By Status -- 
SELECT `STATUS_Group`,
	   COUNT(`Order ID`) as Orders,
       SUM(Amount_Clean) as Revenue
FROM sales_data
GROUP BY `status_group`
ORDER BY Revenue DESC;

 -- B2B V/S B2C -- 
SELECT 
	  CASE 
         WHEN `B2B` = "False" THEN "B2C" 
         ELSE "B2B" 
         END AS B2B,
         SUM(Amount_clean) as Revenue,
         COUNT(`Order ID`) as Orders,
         AVG(amount_clean) as AVG_rev
FROM sales_data
GROUP BY B2B
ORDER BY Revenue DESC;
 
 -- Rank states by revenue within each category (window function) -- 
SELECT
	  Category,
      `SHIP-STATE` as States,
      SUM(Amount_clean) as revenue,
      RANK() OVER(partition by Category order by sum(Amount_clean) DESC) as state_rank
FROM sales_data
GROUP BY Category, `ship-state`
ORDER BY Category, state_rank;


 -- Top 3 states per category only (CTE + window function combined) --
WITH TOP_3 AS (
SELECT Category,
       `ship-state` as States,
       sum(amount_clean) as revenue,
       RANK() OVER(partition by category ORDER BY sum(amount_clean) DESC) as state_rank
FROM sales_data
GROUP BY Category, `ship-state`
)
SELECT *
FROM TOP_3
WHERE state_rank <=3
ORDER BY Category, state_rank;

 -- % of Total Revenue by Category -- 
SELECT 
      Category,
      Sum(amount_clean) as revenue,
      ROUND(SUM(Amount_clean)*100/ SUM(SUM(AMOUNT_CLEAN)) OVER(), 2) pct_of_total
FROM sales_data
GROUP BY Category
ORDER BY Revenue DESC;

 -- CASE WHEN - recreating  Status_Group Power Query logic -- 
SELECT 
    CASE 
        WHEN Status LIKE '%Cancelled%' THEN 'Cancelled'
        WHEN Status LIKE '%Pending%' THEN 'Pending'
        WHEN Status = 'Shipped' OR Status LIKE '%Delivered%' 
             OR Status LIKE '%Picked Up%' OR Status LIKE '%Out for Delivery%' 
             THEN 'Shipped - Success'
        ELSE 'Returned / Issue'
    END AS Status_Groupp,
    COUNT(*) AS order_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_total
FROM sales_data
GROUP BY Status_Groupp
ORDER BY order_count DESC;


		