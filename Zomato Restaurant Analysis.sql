CREATE DATABASE zomato_restaurant_analysis;
use zomato_restaurant_analysis;

# Adding date column with fulldate
alter table main add column Date_opened date;
update main 
SET date_opesned= STR_TO_DATE(CONCAT(year, '-', LPAD(month, 2, '0'), '-', LPAD(day, 2, '0')), '%Y-%m-%d');

# calendar query with KPIs mentioned
create table calendar as(
select date_opened,year,month ,monthname(date_opened) as Monthname,quarter(date_opened) as Quarter,
concat(year,'-',LPAD(month, 2, '0')) as YYYY_MM,weekday(date_opened) as Weekday, dayname(date_opened) as weekday_name,
CASE WHEN MONTH(date_opened) >= 4 THEN MONTH(date_opened) - 3
ELSE MONTH(date_opened) + 9 
END AS financial_month,
CASE WHEN MONTH(date_opened) >= 4 THEN FLOOR((MONTH(date_opened) - 3) / 3) + 1
ELSE FLOOR((MONTH(date_opened) + 9) / 3) + 1
END AS financial_quarter
from main);

SELECT  
    COUNT(RestaurantID) AS Total_Restaurant,  
    COUNT(DISTINCT Cuisines) AS Total_Cuisines,  
    COUNT(DISTINCT CountryCode) AS Total_Country,  
    COUNT(DISTINCT City) AS Total_City,  
    CONCAT(ROUND(SUM(ROUND(Votes)) / 1000), 'K') AS Total_Votes,  
    AVG(Rating) AS Avg_Rating,  
    CONCAT(ROUND(SUM(ROUND(Indian_RupeesCost)) / 1000), 'K') AS Total_Cost_in_Rupees,  
    CONCAT(ROUND(SUM(ROUND(USDCost)) / 1000), '$') AS Total_Cost_in_USD  
FROM main;


# Convert the Average cost for 2 column into USD dollars and INR :
select m.restaurantname,round((m.average_cost_for_two*c.usd_rate),2) as avg_cost_in_usd, round(((m.average_cost_for_two*c.usd_rate)/.012),2) as avg_cost_in_inr
from main m join currency c
on m.currency=c.currency;

# Number of Restaurants Based on City and Country
create view Restaurant_count_by_city_and_country as(
SELECT 
    Country_Name,
    City,
    COUNT(RestaurantID) AS NumberOfRestaurants
FROM main
JOIN Country ON main.CountryCode = Country.CountryID
GROUP BY Country_Name, City
ORDER BY NumberOfRestaurants DESC);

select * from Restaurant_count_by_city_and_country;



# Count of Restaurants Based on Ratings
create view Restaurants_count_by_Ratings as(
select count(restaurantname) as rest_count,
case when rating<=1 then "0-1"
when rating>1 and rating<=2 then "1.1-2"
when rating>2 and rating<=3 then "2.1-3"
when rating>3 and rating<=4 then "3.1-4"
else "4.1-5"
end as rating_bucket
from main
group by 2
order by rating_bucket);

select * from Restaurants_count_by_Ratings;


# Create buckets based on Average Price of reasonable size and find out how many resturants falls in each buckets
create view bucket_cost_range_by_price as(
select count(m.restaurantname) as rest_count,
case when ((m.average_cost_for_two*c.usd_rate)/.012)<=300 then "0-300"
when ((m.average_cost_for_two*c.usd_rate)/.012)>300 and ((m.average_cost_for_two*c.usd_rate)/.012)<=600 then "301-600"
when ((m.average_cost_for_two*c.usd_rate)/.012)>600 and ((m.average_cost_for_two*c.usd_rate)/.012)<=1000 then "601-1000"
else "Above 1000"
end as cost_bucket
from main m join currency c 
on m.currency=c.currency
group by 2
order by cost_bucket);

select * from bucket_cost_range_by_price;


# Percentage of Restaurants with Table Booking
create view percentage_of_Table_Booking as (
SELECT 
    Has_Table_booking,
    COUNT(RestaurantID) AS CountOfRestaurants,
    ROUND(100.0 * COUNT(RestaurantID) / (SELECT COUNT(*) FROM Main), 2) AS Percentage
FROM Main
GROUP BY Has_Table_booking);

select * from percentage_of_Table_Booking;


# Percentage of Restaurants with Online Delivery
create view percentage_of_online_Booking as (
SELECT 
    Has_Online_delivery,
    COUNT(RestaurantID) AS CountOfRestaurants,
    ROUND(100.0 * COUNT(RestaurantID) / (SELECT COUNT(*) FROM Main), 2) AS Percentage
FROM Main
GROUP BY Has_Online_delivery);

select * from percentage_of_online_Booking;


# Most Popular Top 10 Cuisines
create view Top_10_Cuisines as (
SELECT Cuisines, COUNT(RestaurantID) AS Count,
dense_rank() over (order by count(restaurantid) desc) as ranks 
FROM Main 
GROUP BY Cuisines 
ORDER BY Count 
DESC LIMIT 10);

select * from Top_10_Cuisines;


# Top 10 Cities with Most Restaurants
create view Top_10_Cities as (
SELECT City, COUNT(RestaurantID) AS Count,
dense_rank() over (order by count(restaurantid) desc) as ranks 
FROM Main 
GROUP BY City
ORDER BY Count 
DESC LIMIT 10);

select * from Top_10_Cities;


# Top 10 Country with Most Restaurants
create view Top_10_Country as (
SELECT Country_Name, COUNT(RestaurantID) AS Total_restaurant,
dense_rank() over (order by count(restaurantid) desc) as ranks 
FROM Main 
GROUP BY Country_Name 
ORDER BY Total_restaurant
DESC LIMIT 10);

select * from Top_10_Country;


# Top 10 restaurants based on votes
select * from
(select restaurantname, sum(votes) as votes,
dense_rank() over (order by sum(votes) desc) as ranks
from main
group by 1) as votes
where ranks<=10;


# Count of Restaurants Based on Month
create view month_wise_restaurant_count as (
SELECT 
    Month, Month_Name,
    COUNT(RestaurantID) AS CountOfRestaurants
FROM Main
GROUP BY Month, Month_Name
ORDER BY Month);

select * from month_wise_restaurant_count;


# Bucket Cost Distribution Across Restaurants
create view bucket_cost_by_restaurant as (
SELECT Bucket_cost, COUNT(RestaurantID) as Total_restaurant
FROM Main 
GROUP BY Bucket_cost 
ORDER BY Bucket_cost);

select * from bucket_cost_by_restaurant;

# Count of Rating Distribution Across Restaurants
create view rating_range_by_restaurant as (
SELECT Rating_Range, count(RestaurantID) as Total_restaurant
FROM main 
GROUP BY Rating_Range 
ORDER BY Total_restaurant DESC);

select * from rating_range_by_restaurant;


# Restaurants Opened by Year, Quarter, and Month
select year,quarter,Month_Name,count(restaurantID) as Rest_count
from main
group by 1,2,3
order by 4 desc;



# Views
select * from Restaurant_count_by_city_and_country;
select * from Restaurants_count_by_Ratings;
select * from bucket_cost_range_by_price;
select * from percentage_of_Table_Booking;
select * from percentage_of_online_Booking;
select * from Top_10_Cuisines;
select * from Top_10_Cities;
select * from Top_10_Country;
select * from month_wise_restaurant_count;
select * from bucket_cost_by_restaurant;
select * from rating_range_by_restaurant;