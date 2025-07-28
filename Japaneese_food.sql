

CREATE TABLE sales_table (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales_table
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  -- what is the total amount each customer spent at the restaurant?
  select s.customer_id,sum(price) as total_amount from sales_table s
  join menu m 
  on s.product_id = m.product_id
  group by customer_id
  order by total_amount desc;
  --how many days has each customer visited the restarunat
  select customer_id,count(*) as no_of_days from sales_table
  group by customer_id;
  -- what was the first item purchased by each customer
 with items as(
  select m.product_name,s.customer_id,
  rank() over(partition by customer_id order by order_date asc) as rn
  from sales_table s
  join menu m
  on s.product_id=m.product_id
  )
  select distinct
  product_name,customer_id
  from items
  where rn= 1;
--what is the most popular purchased item on the menu and how many times was it purchased by each customers
  WITH MostPopularProduct AS (
    SELECT top 1
        m.product_name,
        COUNT(*) AS total_purchases
    FROM 
        sales_table s
    JOIN 
        menu m 
    ON 
        s.product_id = m.product_id
    GROUP BY 
        m.product_name
    ORDER BY 
        total_purchases DESC
   
),
CustomerPurchases AS (
    SELECT 
        s.customer_id,
        m.product_name,
        COUNT(*) AS times_purchased
    FROM 
        sales_table s
    JOIN 
        menu m 
    ON 
        s.product_id = m.product_id
    GROUP BY 
        s.customer_id, m.product_name
)
SELECT 
    cp.customer_id, 
    cp.times_purchased
FROM 
    CustomerPurchases cp
JOIN 
    MostPopularProduct mp 
ON 
    cp.product_name = mp.product_name;
-- what is the most popular purchased item on the menu and how many times was it purchased by all customers
SELECT top 1
        m.product_name,
        COUNT(*) AS total_purchases
    FROM 
        sales_table s
    JOIN 
        menu m 
    ON 
        s.product_id = m.product_id
    GROUP BY 
        m.product_name
    ORDER BY 
        total_purchases DESC
   
-- which item was the most popular for each customer
with popular_items as(
	 select s.customer_id,
        m.product_name,
        COUNT(*) AS total_purchases,
		row_number() over(partition by customer_id order by count(*) desc) rn
    FROM 
        sales_table s
    JOIN 
        menu m 
    ON 
        s.product_id = m.product_id
    GROUP BY 
        m.product_name,s.customer_id
		)
	select product_name,customer_id from popular_items
	where rn =1
 --Which item was purchased first by the customer after they became a member? 
 SELECT 
    s.customer_id,
    m.product_name,
    s.order_date AS first_purchase_date
FROM 
    sales_table s
JOIN 
    members mem
ON 
    s.customer_id = mem.customer_id
JOIN 
    menu m
ON 
    s.product_id = m.product_id
WHERE 
    s.order_date >= mem.join_date
AND 
    s.order_date = (
        SELECT MIN(order_date)
        FROM sales
        WHERE customer_id = s.customer_id
          AND order_date >= mem.join_date
    )
ORDER BY 
    s.customer_id;
-- which item was purchased just before the customer became a member 
SELECT distinct
    s.customer_id,
    m.product_name,
    s.order_date AS last_purchase_date
FROM 
    sales_table s
JOIN 
    members mem
ON 
    s.customer_id = mem.customer_id
JOIN 
    menu m
ON 
    s.product_id = m.product_id
WHERE 
    s.order_date < mem.join_date
AND 
    s.order_date = (
        SELECT Max(order_date)
        FROM sales
        WHERE customer_id = s.customer_id
          AND order_date < mem.join_date
    )
ORDER BY 
    s.customer_id;
  
 -- What is the total items and amount spent for each member before they became a member?
  
  select  s.customer_id,
	  count(*) as total_items,
	  sum(m.price) as total_amount_spent
  from sales_table s
  JOIN 
    members mem
ON 
    s.customer_id = mem.customer_id
JOIN 
    menu m
ON 
    s.product_id = m.product_id
	WHERE 
    s.order_date < mem.join_date

group by 
	s.customer_id
ORDER BY 
    s.customer_id;
-- If each $1 spent equates to 10 points and sushi has a 2x points multiplier 
-- how many points would each customer have?
select  s.customer_id,
	  sum(CASE 
            WHEN m.product_name = 'sushi' THEN m.price * 10 * 2
            ELSE m.price * 10
        END) as total_amount
  from sales_table s
JOIN 
    menu m
ON 
    s.product_id = m.product_id

group by 
	s.customer_id
ORDER BY 
    s.customer_id;
-- In the first week after a customer joins the program (including their join date) 
-- they earn 2x points on all items, not just sushi - 
-- how many points do customer A and B have at the end of January?
select  s.customer_id,  MONTH(s.order_date) AS month,
	  sum(m.price *20) as total_amount
  from sales_table s
  JOIN 
    members mem
ON 
    s.customer_id = mem.customer_id
JOIN 
    menu m
ON 
    s.product_id = m.product_id
	WHERE 
    s.order_date >= mem.join_date and  MONTH(s.order_date)  =1

group by 
	s.customer_id, MONTH(s.order_date) 
ORDER BY 
    s.customer_id;
