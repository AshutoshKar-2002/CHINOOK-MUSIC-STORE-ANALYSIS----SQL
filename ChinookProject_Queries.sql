use chinook
select database()
select * from employee
show tables from chinook
describe album
describe artist
describe customer

-- OBJECTIVE QUESTIONS
//Q1
select * from album;
select * from artist;
select * from customer;
select count(*) from customer -- 49 company values are null in the customer table
	where company is null;
select count(*) from customer -- 29 state values are null in the customer table
	where state is null;
select count(*) from customer -- 47 fax values are null in the customer table
	where fax is null;
select * from employee; -- 1 reports_to value is null in the employee table
select * from genre;
select * from invoice;
select * from invoice_line;
select * from media_type;
select * from playlist;
select * from playlist_track;
select * from track;
select count(*) from track -- 978 composer columns are null in the track table
where composer is null;


//Q2
with Result as 
(
	select t.name as Top_selling_track, a.name as Top_artist, g.name as Top_genre, 
	SUM(t.unit_price * il.quantity) as Total from track t
		left join invoice_line il on t.track_id = il.track_id
		left join invoice i on i.invoice_id = il.invoice_id
		left join album al on al.album_id = t.album_id
		left join artist a on a.artist_id = al.artist_id
		left join genre g on g.genre_id = t.genre_id
	where billing_country = "USA"
	group by t.name, a.name, g.name
	order by Total desc
	limit 10
)
select Top_selling_track,Top_artist,Top_genre
from Result

//Q3
select country, count(*) as TotalCustomers
from customer
group by country
order by TotalCustomers desc

select city, count(customer_id) as NumberOfCustomers
from customer
group by city
order by NumberOfCustomers desc

select count(distinct country)as TotalCountries 
from customer


//Q4
-- select c.country,
-- sum(il.unit_price * il.quantity) as Total_Revenue,
-- count(il.invoice_id) as NoOfInvoices
-- from invoice i join invoice_line il on il.invoice_id = i.invoice_id join customer c on c.customer_id = i.customer_id
-- group by c.country
-- order by total_revenue desc, NoOfInvoices desc
select billing_city, billing_state, billing_country, count(invoice_id) as NoOfInvoices, 
sum(total) as Total_Revenue
from invoice
group by billing_city, billing_state, billing_country
order by count(invoice_id) desc, sum(total) desc

//Q5
with Revenue as (
    select country, concat(first_name, " " ,last_name)as Customer_Name, sum(i.total) as Total_Revenue 
    from customer c
	left join invoice i on i.customer_id = c.customer_id
    group by country, first_name, last_name
    order by country
)
,Result as
(
	select *,
    rank() over(partition by country order by Total_Revenue desc)as rnk
    from  Revenue
)
select * from Result
where rnk <=5
order by Total_Revenue desc,rnk

//Q6
with ranked_tracks as (
    select
        c.customer_id,c.first_name,c.last_name,t.track_id,
        t.name as track_name,sum(il.quantity) as total_sales
    from customer c
    join invoice i on i.customer_id = c.customer_id
    join invoice_line il on il.invoice_id = i.invoice_id
    join track t on t.track_id = il.track_id
    group by c.customer_id,
        c.first_name,c.last_name,t.track_id,t.name
)
select first_name,last_name,track_name,total_sales
from ranked_tracks
order by total_sales desc

//Modified_One
with customertracksales as 
(
select i.customer_id, il.track_id, t.name as track_name,
sum(il.quantity) as total_quantity_sold
from invoice_line il
join invoice i on il.invoice_id = i.invoice_id
-- join customer c on i.customer_id = c.customer_id
join track t on il.track_id = t.track_id
group by i.customer_id, il.track_id, t.name
)
,rankedtracks as 
(
select customer_id, track_name, total_quantity_sold,
row_number() over (partition by customer_id order by total_quantity_sold desc) as row_num
from customertracksales
)
select customer_id, track_name, total_quantity_sold
from rankedtracks
where row_num = 1
-- order by customer_id asc



//Q7
-- 	Frequency of Purchases:
	select c.customer_id,concat(c.first_name, ' ', c.last_name) as customers,
    year(i.invoice_date) as year,count(i.invoice_id) as purchase_count
	from customer c
	inner join invoice i on c.customer_id = i.customer_id
	group by
    c.customer_id, customers, year(i.invoice_date)
	order by
    c.customer_id, customers, year(i.invoice_date)
    
    
-- Avg Order Value By Cust_ID     
select customer_id, avg(total) as avg_order_value, count(invoice_id)as num_of_orders
from invoice
group by customer_id
order by customer_id,count(invoice_id),avg(total)

-- Monthly Invoice Count
with daily_counts as (
    select 
        date(invoice_date) as invoice_day,
        count(invoice_id) as daily_invoice_count,
        sum(total) as daily_sum_total
    from invoice
    group by date(invoice_date)
)

select 
    date_format(invoice_day, '%Y-%m') as YearMonth,
    avg(daily_invoice_count) as avg_daily_invoices,
    sum(daily_invoice_count) as total_invoices_in_month,
    avg(daily_sum_total) as avg_daily_total,
    sum(daily_sum_total) as monthly_sum_total
from daily_counts
group by date_format(invoice_day, '%Y-%m')
order by YearMonth;

//Q8
-- Churn Rate
with last_purchase as (
select customer_id, max(invoice_date) as last_order_date
from invoice
group by customer_id
),
churned_customers as (
select count(customer_id) as churned_count
from last_purchase
where last_order_date < date_sub('2020-12-30', interval 6 month)
),
total_customers as (
select count(distinct customer_id) as total_count from customer
)
select 
(c.churned_count / t.total_count) * 100 as churn_rate
from churned_customers c, total_customers t

--ModifiedOne
with last_purchase as (
    select 
        customer_id, 
        max(invoice_date) as last_order_date
    from invoice
    group by customer_id
)
,churned_customers as (
    select 
        count(customer_id) as churned_count
    from last_purchase
    where last_order_date < date_sub((select max(invoice_date) from invoice), interval 6 month)
),
total_customers as (
    select 
        count(distinct customer_id) as total_count
    from customer
)
select 
    c.churned_count as churned_customers,
    t.total_count as total_customers,
    round((c.churned_count / t.total_count) * 100, 2) as churn_rate_percentage
from churned_customers as c
cross join total_customers as t 

//Q9
-- Total Sales by each Genre in the USA
with genresales as (
    select 
        g.genre_id,
        g.name as genre_name,
        count(i.invoice_id)as TotalInvoices,
        sum(il.unit_price * il.quantity) as Total_Sales
    from invoice i
    join invoice_line il on i.invoice_id = il.invoice_id
    join track t on il.track_id = t.track_id
    join genre g on t.genre_id = g.genre_id
    join customer c on i.customer_id = c.customer_id
    where c.country = 'USA'
    group by g.genre_id, g.name
),
totalsales as (
    select sum(total_sales) as overall_sales from genresales
)
select 
    gs.genre_name,
    gs.TotalInvoices as GenreCount,
    gs.total_sales,
    round((gs.total_sales / ts.overall_sales) * 100, 2) as Sales_Percentage
from genresales gs
join totalsales ts
order by gs.total_sales desc;

-- best-selling artist in USA
with artistsales as (
select ar.artist_id,ar.name as Artist_Name,
sum(il.unit_price * il.quantity) as Total_Sales
from invoice i
join invoice_line il on i.invoice_id = il.invoice_id
join track t on il.track_id = t.track_id
join album al on t.album_id = al.album_id
join artist ar on al.artist_id = ar.artist_id
join customer c on i.customer_id = c.customer_id
where c.country = 'USA'
group by ar.artist_id, ar.name
)
select Artist_Name, Total_Sales
from artistsales
order by Total_Sales desc
limit 5


//Q10
select concat(c.first_name, " " ,c.last_name)as Customer_Name,
count(distinct g.name) as Genre_Count
from customer c
inner join invoice i on c.customer_id = i.customer_id
inner join invoice_line il on i.invoice_id = il.invoice_id
inner join track t on il.track_id = t.track_id
inner join genre g on t.genre_id = g.genre_id
group by Customer_Name
having count(distinct g.name) >= 3
order by Genre_Count desc

//Q11
select g.name,sum(i.total) as genre_sum, 
rank() over(order by sum(i.total) desc) as rnk
from customer c inner join invoice i on c.customer_id = i.customer_id 
join invoice_line il on i.invoice_id = il.invoice_id 
join track t on il.track_id = t.track_id
join genre g on t.genre_id = g.genre_id
where c.country = "USA"
group by g.name

//Q12
with last_3_months as
(
select * from invoice
where invoice_date > (select max(invoice_date) from invoice) - interval 3 month
)
select concat(c.first_name, ' ', c.last_name) as CustomerName
from customer c
left join last_3_months lm on lm.customer_id = c.customer_id
where invoice_id is null       --     who had no invoice in the last 3 months

//Modified_One
with last_3_months as 
(
    select * 
    from invoice
    where invoice_date > (select max(invoice_date) from invoice) - interval 3 month
),
last_purchase as (
    select c.customer_id,concat(c.first_name, ' ', c.last_name) as customer_name,
	max(i.invoice_date) as last_purchase_date
    from customer c
    left join invoice i on c.customer_id = i.customer_id
    group by c.customer_id, c.first_name, c.last_name
)
select lp.customer_name,date(lp.last_purchase_date)as last_purchase_date,
timestampdiff(month, lp.last_purchase_date, (select max(invoice_date) from invoice)) as months_since_last_purchase
from last_purchase lp
left join last_3_months lm on lp.customer_id = lm.customer_id
where lm.invoice_id is null
order by months_since_last_purchase desc;

//SUBJECTIVE QUESTIONS
//Q1
with Result as 
(
	select g.name as GenreName, a.title as AlbumName,
	sum(il.unit_price * il.quantity) as TotalSales
	from invoice i
	join invoice_line il on i.invoice_id = il.invoice_id
	join track t on il.track_id = t.track_id
	join album a on t.album_id = a.album_id
	join genre g on t.genre_id = g.genre_id
	where i.billing_country = 'USA'
	group by 
	g.name, a.title
	order by 
	TotalSales desc
)
select *,
dense_rank()over(order by TotalSales desc)as rnk
from Result
-- limit 3

//Q2
select g.name,
sum(il.unit_price * il.quantity) as total_sales
from invoice_line il
join track t on t.track_id = il.track_id
join genre g on g.genre_id = t.genre_id
join invoice i on i.invoice_id = il.invoice_id
where billing_country != 'USA'
group by g.name
order by total_sales desc

//	Q3
with cte as (
    select
        i.customer_id,
        max(invoice_date) as last_purchase_date,
        min(invoice_date) as first_purchase_date,
        sum(total) as total_spent,
        sum(quantity) as items_bought,
        count(i.customer_id) as frequency,
        abs(timestampdiff(day, max(invoice_date), min(invoice_date))) as customer_since_days
    from invoice i
    left join invoice_line il on il.invoice_id = i.invoice_id
    left join customer c on c.customer_id = i.customer_id
    group by i.customer_id
)
-- CTE to classify customers into 'Long Term' or 'Short Term' based on their active days 
-- compared to the average customer active days.
,long_short_term as (
select total_spent,items_bought,frequency,customer_since_days,
	case
		when customer_since_days > (select avg(customer_since_days) as average_days from cte)
		then 'Long Term'
		else 'Short Term'
	end as Term
from cte
)
-- select avg(customer_since_days) as average_days from cte
-- Final selection of the sum of total spent, items bought, and the count of customers, 
-- grouped by the classification of 'Long Term' or 'Short Term'.
select Term,sum(total_spent)as Total_Spent,
sum(items_bought)as Total_Items_Bought,count(frequency)as Number_Of_Customers
from long_short_term
group by Term


//Q4
with track_combinations as (
select il1.track_id as track_id_1,
il2.track_id as track_id_2,
count(*) as times_purchased_together
from invoice_line il1
join invoice_line il2 on il1.invoice_id = il2.invoice_id
and il1.track_id < il2.track_id
group by il1.track_id, il2.track_id
)
,genre_combinations as (
select t1.genre_id as genre_id_1,t2.genre_id as genre_id_2,
count(*) as times_purchased_together
from track_combinations tc
join track t1 on tc.track_id_1 = t1.track_id
join track t2 on tc.track_id_2 = t2.track_id
where t1.genre_id != t2.genre_id
group by t1.genre_id, t2.genre_id
)
select g1.name as genre_1,g2.name as genre_2,
gc.times_purchased_together
from genre_combinations gc
join genre g1 on gc.genre_id_1 = g1.genre_id
join genre g2 on gc.genre_id_2 = g2.genre_id
order by gc.times_purchased_together desc

//Q5
-- determine last purchase date per customer
with customeractivity as (
select c.customer_id,c.country,count(i.invoice_id) as total_purchases,
sum(i.total) as total_spent,max(i.invoice_date) as last_purchase_date
from customer c
join invoice i on c.customer_id = i.customer_id
group by c.customer_id, c.country
)
-- identify customers who have not purchased in the last 12 months from the latest invoice date
,churnedcustomers as (
select country, count(customer_id) as churned_customers
from customeractivity
where last_purchase_date < date_sub((select max(invoice_date) from invoice), interval 12 month)
group by country
)
select ca.country, count(ca.customer_id) as total_customers,
sum(ca.total_purchases) as total_transactions,
round(avg(ca.total_spent), 2) as avg_spending_per_customer,
coalesce(cc.churned_customers, 0) as churned_customers,
round((coalesce(cc.churned_customers, 0) / nullif(count(ca.customer_id), 0)) * 100, 2) as churn_rate_percentage
from customeractivity ca
left join churnedcustomers cc on ca.country = cc.country
group by ca.country, cc.churned_customers
order by churn_rate_percentage desc


//Q6
-- determine each customer's total purchases, total amount spent, and last purchase date
with customeractivity as (
select c.customer_id, c.country,count(i.invoice_id) as total_purchases, 
sum(i.total) as total_spent,max(i.invoice_date) as last_purchase_date
from customer c
join invoice i on c.customer_id = i.customer_id
group by c.customer_id, c.country
)
-- categorize customers into high-risk, medium-risk, and low-risk based on purchase activity
,churnrisk as (
select customer_id, country, total_purchases, total_spent,last_purchase_date,
case
	when last_purchase_date < date_sub((select max(invoice_date) from invoice), interval 12 month)
	then 'high risk'  -- no purchase in the last 12 months
	when total_purchases <= 3 or total_spent < 50
	then 'medium risk' -- low purchase frequency or spending
	else 'low risk'  -- regular customers
end as risk_category
from customeractivity
)
-- final aggregation: risk distribution by country
select country,
sum(case when risk_category = 'high risk' then 1 else 0 end) as high_risk_customers,
sum(case when risk_category = 'medium risk' then 1 else 0 end) as medium_risk_customers,
sum(case when risk_category = 'low risk' then 1 else 0 end) as low_risk_customers,
count(customer_id) as total_customers,
round((sum(case when risk_category = 'high risk' then 1 else 0 end) / count(customer_id)) * 100, 2) as high_risk_percentage
from churnrisk
group by country
order by high_risk_percentage desc

//Q7

with customertenure as (
select c.customer_id, concat(c.first_name,' ', c.last_name) as customer_name,
min(i.invoice_date) as first_purchase_date,max(i.invoice_date) as last_purchase_date,
datediff(max(i.invoice_date), min(i.invoice_date)) as tenure_days,
count(i.invoice_id) as purchase_frequency,sum(i.total) as total_spent
from customer c
join invoice i on c.customer_id = i.customer_id
group by c.customer_id
)
select customer_id,customer_name,tenure_days,purchase_frequency,
total_spent,round(total_spent / purchase_frequency, 2) as avg_order_value,
datediff(current_date, last_purchase_date) as days_since_last_purchase
from customertenure
order by days_since_last_purchase desc


//Q10
alter table album
add column release_year int
desc album

//Q11
select billing_country, 
count(distinct customer_id) as num_of_customers, 
avg(total) as average_total_amount, 
count(track_id) as num_of_tracks 
from invoice i
left join invoice_line il on il.invoice_id = i.invoice_id
group by billing_country

//Q11 Modified

with customer_spending as 
(
	select i.customer_id,c.country,sum(i.total) as total_spent_by_customer
	from invoice i
	join customer c on i.customer_id = c.customer_id
	group by i.customer_id, c.country
)
,country_inf as 
(
    select country,count(distinct customer_id) as total_customers,
	avg(total_spent_by_customer) as avg_spent_per_customer
    from customer_spending
    group by country
)
select ci.country,ci.total_customers,
(count(il.track_id) / ci.total_customers) as avg_tracks_purchased_per_customer,
ci.avg_spent_per_customer
from country_inf ci
join invoice i on ci.country = i.billing_country
join invoice_line il on i.invoice_id = il.invoice_id
group by ci.country, ci.total_customers, ci.avg_spent_per_customer














































