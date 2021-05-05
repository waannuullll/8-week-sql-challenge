/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
-- 2. How many days has each customer visited the restaurant?
-- 3. What was the first item from the menu purchased by each customer?
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
-- not just sushi - how many points do customer A and B have at the end of January?

-- 8 Week SQL Challenge
-- Ikhwanul Muslimin/20210505

select * from members
select * from menu
select * from sales

-- 1. What is the total amount each customer spent at the restaurant?
select sales.customer_id, SUM(menu.price) as AmountSpent
from sales
join menu on sales.product_id=menu.product_id
group by sales.customer_id;

-- 2. How many days has each customer visited the restaurant?
select sales.customer_id, COUNT(distinct sales.order_date) as DaysVisited
from sales
group by sales.customer_id;

-- 3. What was the first item from the menu purchased by each customer?
with MyRowSet
as 
(
	select sales.customer_id, menu.product_name, 
	ROW_NUMBER() over (partition by sales.customer_id order by sales.customer_id, sales.order_date asc) as RowNum
	from sales
	join menu on sales.product_id=menu.product_id
)
select MyRowSet.customer_id, MyRowSet.product_name as FirstPurchased
from MyRowSet
where MyRowSet.RowNum < 2

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
with MyRowSet as
(
	select menu.product_name, count(sales.product_id) as TotalPurchased
	from sales
	join menu on sales.product_id=menu.product_id
	group by menu.product_name
	
)
select top 1 *
from MyRowSet
order by TotalPurchased desc

-- 5. Which item was the most popular for each customer?
with MyRowSet as
(
	select sales.customer_id, menu.product_name, count(sales.product_id) as TotalPurchased,
	ROW_NUMBER() over(partition by sales.customer_id order by count(sales.product_id) desc) as RowNum
	from sales
	inner join menu on sales.product_id=menu.product_id
	group by sales.customer_id, menu.product_name
)
select MyRowSet.customer_id, MyRowSet.product_name as PopularMenu
from MyRowSet
where RowNum = 1

-- 6. Which item was purchased first by the customer after they became a member?
with MyRowSet as
(
	select sales.customer_id, members.join_date, sales.order_date, menu.product_name,
	ROW_NUMBER() over(partition by sales.customer_id order by sales.order_date desc) as RowNum
	from sales
	inner join menu on sales.product_id=menu.product_id
	inner join members on sales.customer_id=members.customer_id
	where sales.order_date >= members.join_date
)
select MyRowSet.customer_id, MyRowSet.product_name as FirstPurchased
from MyRowSet
where RowNum = 1

-- 7. Which item was purchased just before the customer became a member?
with MyRowSet as
(
	select sales.customer_id, members.join_date, sales.order_date, menu.product_name,
	ROW_NUMBER() over(partition by sales.customer_id order by sales.order_date desc) as RowNum
	from sales
	inner join menu on sales.product_id=menu.product_id
	inner join members on sales.customer_id=members.customer_id
	where sales.order_date < members.join_date
)
select MyRowSet.customer_id, MyRowSet.product_name as FirstPurchased
from MyRowSet
where RowNum = 1

-- 8. What is the total items and amount spent for each member before they became a member?
select sales.customer_id, COUNT(sales.customer_id) as TotalItem, SUM(menu.price) as TotalAmount
from sales
inner join menu on sales.product_id=menu.product_id
inner join members on sales.customer_id=members.customer_id
where sales.order_date < members.join_date
group by sales.customer_id

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
select sales.customer_id, SUM(IIF(sales.product_id = 1, menu.price*20, menu.price*10)) as TotalPoints
from sales
inner join menu on sales.product_id=menu.product_id
group by sales.customer_id

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
-- not just sushi - how many points do customer A and B have at the end of January?
select sales.customer_id, 
SUM(IIF(sales.order_date >= DATEADD(DAY,7,members.join_date) and sales.order_date <= DATEADD(DAY,7,members.join_date), menu.price*20, menu.price*10)) as TotalPoints
from sales
inner join menu on sales.product_id=menu.product_id
inner join members on sales.customer_id=members.customer_id
group by sales.customer_id

-- Bonus Question - Join All The Things
select sales.customer_id, sales.order_date, menu.product_name, menu.price, 
IIF(sales.customer_id = 'C', 'N', IIF(sales.order_date < members.join_date, 'N', 'Y')) as member
from sales
inner join menu on sales.product_id=menu.product_id
left join members on sales.customer_id=members.customer_id