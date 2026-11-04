drop table if exists spice_orders;

-- Creating Schema
create table spice_orders (
    order_id varchar(20) primary key,
    customer_id varchar(20) not null,
    category varchar(50) not null,
    item varchar(100) not null,
    price numeric(10, 2) not null,
    quantity int not null check (quantity > 0),
    order_total numeric(10, 2) not null,
    order_date date not null,
    payment_method varchar(50),
    year int not null,
    month int not null,
    day_name varchar(15) not null,
    quarter int not null
);
-- Changing the date format from yyyy-mm-dd to dd-mm-yyy
set datestyle = 'ISO, DMY';

-- Copy Data from CSV into PostgreSQL
copy spice_orders(order_id, customer_id, category, item, price, quantity, order_total, order_date, payment_method, year, month, day_name, quarter)
from 'D:\Data Analytics Projects\Self - Project\spice_data.csv'
delimiter ','
csv header;

select * from spice_orders;

-- 1. Key business KPI'S: Total Revenue, Total Orders, Total items sold, Total customers, avg order value

select 
	sum(order_total) as Total_revenue,
	count(distinct(order_id)) as Total_orders,
	count(quantity) as Total_items_sold, 
	count(distinct(customer_id)) as Total_customers,
	round(avg(order_total),2) as avg_order_value
from spice_orders;

-- 2. Category wise revenue breakdown, total order count, items sold and avg basket value

select category, 
	count(distinct(order_id)) as order_count,
	sum(quantity) as items_sold,
	sum(order_total) as Total_revenue, 
	round(avg(order_total),2) as avg_order_value
from spice_orders
group by category
order by total_revenue desc;

-- 3. Top 5 best selling menue items by revenue

select 
	item, 
	sum(order_total) as Total_revenue
from spice_orders
group by item
order by total_revenue desc
limit 5;

-- 4. Month-over-Month (MoM) Growth Analysis

select 
	year, 
	month, 
	TO_CHAR(TO_DATE(month::text, 'MM'), 'Month') AS month_name,
	sum(order_total) as monthly_revenue,
    lag(sum(order_total)) over (order by year, month) as prev_month_revenue,
    round(
        (sum(order_total) - lag(sum(order_total)) over (order by year, month)) * 100.0 / 
        nullif(lag(sum(order_total)) over (order by year, month), 0), 2
    ) as mom_growth_percentage
from spice_orders 
group by year, month
order by year, month asc;
	
-- 5. Year-over-Year (YoY) Growth Analysis

select 
    year,
    month,
    to_char(to_date(month::text, 'mm'), 'month') as month_name,
    sum(order_total) as monthly_revenue,
    -- Look back 12 rows to get the exact same month from the previous year
    lag(sum(order_total), 12) over (order by year, month) as same_month_prev_year_revenue,
    round(
        (sum(order_total) - lag(sum(order_total), 12) over (order by year, month)) * 100.0 / 
        nullif(lag(sum(order_total), 12) over (order by year, month), 0), 2
    ) as yoy_growth_pct
from spice_orders
group by year, month
order by year, month asc;

-- 6. Top 10 High-Value Customers:

select customer_id, 
    count(order_id) as total_orders,
	sum(order_total) as total_spent,
	round(avg(order_total), 2) as avg_order_value
from spice_orders
group by customer_id
order by total_spent desc limit 10;

-- 7. Payment Method Preference & Missing Value Impact

SELECT 
    COALESCE(payment_method, 'Unspecified / Cash On Delivery') AS payment_channel,
    COUNT(order_id) AS order_count,
    SUM(order_total) AS total_sales,
    ROUND(COUNT(order_id) * 100.0 / (SELECT COUNT(*) FROM spice_orders), 2) AS order_pct
FROM spice_orders
GROUP BY payment_method
ORDER BY total_sales DESC;

--8. Day of Week Peak Volume Analysis

select day_name,  
count(distinct order_id) as total_orders, 
sum(order_total) as total_revenue,
round(avg(order_total), 2) as avg_order_value
from spice_orders
group by day_name
order by total_revenue desc;