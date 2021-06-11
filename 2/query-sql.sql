-- Example Query:
SELECT
	runners.runner_id,
    runners.registration_date,
	COUNT(DISTINCT runner_orders.order_id) AS orders
FROM runners
INNER JOIN runner_orders
	ON runners.runner_id = runner_orders.runner_id
WHERE runner_orders.cancellation IS NOT NULL
GROUP BY
	runners.runner_id,
    runners.registration_date;

-- Check all query
select * from customer_orders
select * from pizza_names
select * from pizza_recipes
select * from pizza_toppings
select * from runner_orders
select * from runners

-- Update customer_orders and runner_orders 'null'
update customer_orders
set exclusions=NULL
where exclusions='null' or exclusions='';
--
update customer_orders
set extras=NULL
where extras='null' or extras='';
--
update runner_orders
set pickup_time=NULL
where pickup_time='null';
--
update runner_orders
set distance=NULL
where distance='null';
--
update runner_orders
set duration=NULL
where duration='null';
--
update runner_orders
set cancellation=NULL
where cancellation='null' or cancellation='';
--
update runner_orders
set duration=dbo.mtb_GetNumbers(duration)
where duration is not null;
--
update runner_orders
set distance=dbo.mtb_GetNumbers(distance)
where distance is not null;
--
update runner_orders
set distance=replace(distance,',','.')
where distance is not null;

-- PIZZA METRICS
-- 1. How many pizzas were ordered?
select COUNT(customer_orders.order_id) as PizzasOrdered
from customer_orders;
-- 2. How many unique customer orders were made?
select COUNT(distinct customer_orders.order_id) as UniqueCustomer
from customer_orders;
-- 3. How many successful orders were delivered by each runner?
select COUNT(*) - COUNT(runner_orders.cancellation) as SuccessfulOrder
from runner_orders;
-- 4. How many of each type of pizza was delivered?
select cast(pizza_names.pizza_name as varchar(max)) as PizzaName, COUNT(customer_orders.pizza_id) as NumberOfPizza
from customer_orders
join runner_orders on customer_orders.order_id=runner_orders.order_id
join pizza_names on customer_orders.pizza_id=pizza_names.pizza_id
where runner_orders.cancellation is null
group by cast(pizza_names.pizza_name as varchar(max));
-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
select customer_orders.customer_id, cast(pizza_names.pizza_name as varchar(max)) as PizzaName, COUNT(customer_orders.pizza_id) as TotalOrdered
from customer_orders
inner join pizza_names on customer_orders.pizza_id=pizza_names.pizza_id
group by customer_orders.customer_id, cast(pizza_names.pizza_name as varchar(max))
order by customer_orders.customer_id asc;
-- 6. What was the maximum number of pizzas delivered in a single order?
with MyRowSet as
(
	select customer_orders.order_id, COUNT(customer_orders.order_id) as MaxPizza
	from customer_orders
	join runner_orders on customer_orders.order_id=runner_orders.order_id
	where runner_orders.cancellation is null
	group by customer_orders.order_id
)
select top 1 MyRowSet.MaxPizza
from MyRowSet
order by MyRowSet.MaxPizza desc;
-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
select customer_orders.customer_id, SUM(IIF(customer_orders.exclusions is null and customer_orders.extras is null,0,1)) as Change,
SUM(IIF(customer_orders.exclusions is null and customer_orders.extras is null,1,0)) as NoChange
from customer_orders
join runner_orders on customer_orders.order_id=runner_orders.order_id
where runner_orders.cancellation is null
group by customer_orders.customer_id;
-- 8. How many pizzas were delivered that had both exclusions and extras?
select customer_orders.customer_id, SUM(IIF(customer_orders.exclusions is null and customer_orders.extras is null,0,1)) as ExcclusionAndExtras
from customer_orders
join runner_orders on customer_orders.order_id=runner_orders.order_id
where runner_orders.cancellation is null
group by customer_orders.customer_id;
-- 9. What was the total volume of pizzas ordered for each hour of the day?
select dateadd(hour, datediff(hour, 0, customer_orders.order_time), 0) as TimeStampHour, Count(*) as VolumeOrdered
from customer_orders
group by dateadd(hour, datediff(hour, 0, customer_orders.order_time), 0)
order by dateadd(hour, datediff(hour, 0, customer_orders.order_time), 0);
-- 10. What was the volume of orders for each day of the week?
select FORMAT(dateadd(DAY, datediff(DAY, 0, customer_orders.order_time), 0),'yyyy-mm-dd') as TimeStampDay, Count(*) as VolumeOrdered
from customer_orders
group by dateadd(DAY, datediff(DAY, 0, customer_orders.order_time), 0)
order by dateadd(DAY, datediff(DAY, 0, customer_orders.order_time), 0);

-- RUNNER AND CUSTOMER EXPERIENCE
-- 1. How many runners signed up for each 1 week period?
select DATEPART(week,runner_orders.pickup_time) as Week, COUNT(*) as NumRunners
from runner_orders
where runner_orders.cancellation is null
group by DATEPART(week,runner_orders.pickup_time)
order by DATEPART(week,runner_orders.pickup_time);
-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
select runner_orders.runner_id, AVG(DATEPART(MINUTE,runner_orders.pickup_time - customer_orders.order_time)) as AvgTimeMin
from runner_orders
join customer_orders on runner_orders.order_id=customer_orders.order_id
group by runner_orders.runner_id;
-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
-- We can see the trend that the more the pizzas ordered, the more time needed to prepare that order.
select COUNT(runner_orders.order_id) as NumPizza, SUM(DATEPART(MINUTE,runner_orders.pickup_time - customer_orders.order_time)) as TotalTimeMin
from runner_orders
join customer_orders on runner_orders.order_id=customer_orders.order_id
where runner_orders.pickup_time is not null
group by runner_orders.order_id, runner_orders.runner_id
order by NumPizza desc;
-- 4. What was the average distance travelled for each customer?
select customer_orders.customer_id, AVG(CAST(runner_orders.distance as float)) as Distance_km
from runner_orders
join customer_orders on runner_orders.order_id=customer_orders.order_id
where runner_orders.cancellation is null
group by customer_orders.customer_id
order by customer_orders.customer_id asc
-- 5. What was the difference between the longest and shortest delivery times for all orders?
select MAX(CAST(runner_orders.duration as int)) - MIN(CAST(runner_orders.duration as int)) as DiffDuration_mins
from runner_orders
where runner_orders.duration is not null
-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
select runner_orders.order_id, runner_orders.distance, (CAST(runner_orders.distance as float)/CAST(runner_orders.duration as float)) as AvgSpd
from runner_orders
where runner_orders.cancellation is null
order by runner_orders.distance asc
-- 7. What is the successful delivery percentage for each runner?
select runner_orders.runner_id, (COUNT(*) - COUNT(runner_orders.cancellation))*100/(COUNT(*)) as SuccessDeliv_percent
from runner_orders
group by runner_orders.runner_id;

-- Ingredient Optimisation
-- 1. What are the standard ingredients for each pizza?
select pizza_recipes.pizza_id, pizza_toppings.topping_name
from pizza_recipes cross apply string_split(toppings,',')
join pizza_toppings on pizza_toppings.topping_id=CAST(REPLACE(value,' ','') as int);
-- 2. What was the most commonly added extra?
select pizza_toppings.topping_name, COUNT(CAST(REPLACE(value,' ','') as int)) as NumExtras
from customer_orders cross apply string_split(extras,',')
join pizza_toppings on pizza_toppings.topping_id=CAST(REPLACE(value,' ','') as int)
where customer_orders.extras is not null
group by pizza_toppings.topping_name
order by COUNT(CAST(REPLACE(value,' ','') as int)) desc;
-- 3. What was the most common exclusion?
select pizza_toppings.topping_name, COUNT(CAST(REPLACE(value,' ','') as int)) as NumExclusion
from customer_orders cross apply string_split(exclusions,',')
join pizza_toppings on pizza_toppings.topping_id=CAST(REPLACE(value,' ','') as int)
where customer_orders.exclusions is not null
group by pizza_toppings.topping_name
order by COUNT(CAST(REPLACE(value,' ','') as int)) desc;
-- 4.
-- 5.
-- 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
with MyRowSet as
(
	select pizza_recipes.pizza_id, pizza_toppings.topping_id, pizza_toppings.topping_name
	from pizza_recipes cross apply string_split(toppings,',')
	join pizza_toppings on pizza_toppings.topping_id=CAST(REPLACE(value,' ','') as int)
)
select MyRowSet.topping_id
from MyRowSet
join customer_orders on MyRowSet.pizza_id=customer_orders.pizza_id
order by customer_orders.order_id asc

-- PRICING AND RATINGS
-- 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes 
-- how much money has Pizza Runner made so far if there are no delivery fees?
select SUM(IIF(customer_orders.pizza_id=1,12,10)) as MoneyMade
from customer_orders
join pizza_names on customer_orders.pizza_id=pizza_names.pizza_id
join runner_orders on customer_orders.order_id=runner_orders.order_id
where runner_orders.cancellation is null;