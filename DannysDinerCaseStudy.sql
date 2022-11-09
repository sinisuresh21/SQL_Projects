-- Danny's Diner Case Study with SQL based on the following link:
-- https://8weeksqlchallenge.com/case-study-1/

-- 1. What is the total amount each customer spent at the restaurant?

SELECT customer_id, SUM(price) as total_amount
FROM dannys_diner.sales, dannys_diner.menu
WHERE sales.product_id=menu.product_id
GROUP BY customer_id
ORDER BY total_amount DESC;

-- 2. How many days has each customer visited the restaurant?

SELECT customer_id, COUNT(DISTINCT(order_date))
FROM dannys_diner.sales
GROUP BY customer_id
ORDER BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?

WITH first_order as
(SELECT customer_id, order_date, product_name,
 DENSE_RANK() OVER (PARTITION BY sales.customer_id
                    ORDER BY sales.order_date) AS RANK
 FROM dannys_diner.sales
 JOIN dannys_diner.menu
 ON sales.product_id = menu.product_id)
 
 SELECT customer_id, product_name
 FROM first_order
 WHERE RANK = 1
 GROUP BY customer_id, product_name;
 
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT product_name, COUNT(sales.product_id) as number_of_times
FROM dannys_diner.sales, dannys_diner.menu
WHERE sales.product_id = menu.product_id
GROUP BY sales.product_id, product_name
ORDER BY number_of_times DESC
LIMIT 1;

-- 5. Which item was the most popular for each customer?

WITH popular AS 
(
SELECT customer_id, product_name, COUNT(sales.product_id) as order_count, 
DENSE_RANK() OVER (PARTITION BY sales.customer_id
                    ORDER BY COUNT(customer_id) DESC) AS RANK
FROM dannys_diner.sales, dannys_diner.menu
WHERE sales.product_id = menu.product_id
GROUP BY product_name, customer_id
)

SELECT customer_id, product_name, order_count
FROM popular
WHERE RANK = 1;

-- 6. Which item was purchased first by the customer after they became a member?

WITH first_purchase AS
(
SELECT s.customer_id, s.order_date, m.join_date, s.product_id,
DENSE_RANK() OVER (PARTITION BY s.customer_id
                   ORDER BY order_date) AS Rank
FROM dannys_diner.sales s, dannys_diner.members m
WHERE s.customer_id = m.customer_id
	AND order_date >= join_date
)

SELECT customer_id, order_date, product_name
FROM first_purchase, dannys_diner.menu
WHERE first_purchase.product_id = menu.product_id
AND Rank = 1
ORDER BY customer_id;

-- 7. Which item was purchased just before the customer became a member?

WITH just_prev_purchase AS
(
SELECT s.customer_id, s.order_date, m.join_date, s.product_id,
DENSE_RANK() OVER (PARTITION BY s.customer_id
                   ORDER BY order_date DESC) AS Rank
FROM dannys_diner.sales s, dannys_diner.members m
WHERE s.customer_id = m.customer_id
	AND order_date < join_date
)

SELECT customer_id, order_date, product_name
FROM just_prev_purchase, dannys_diner.menu
WHERE just_prev_purchase.product_id = menu.product_id
AND Rank = 1
ORDER BY customer_id;

-- 8. What is the total items and amount spent for each member before they became a member?

WITH just_prev_purchase AS
(
SELECT s.customer_id, s.order_date, m.join_date, 
  COUNT(s.product_id) AS total_items, SUM(menu.price) as amt,
DENSE_RANK() OVER (PARTITION BY s.customer_id
                   ORDER BY order_date DESC) AS Rank
FROM dannys_diner.sales s, dannys_diner.members m, dannys_diner.menu
WHERE s.customer_id = m.customer_id
  	AND s.product_id = menu.product_id
	AND order_date < join_date
GROUP BY s.customer_id, order_date, join_date
)

SELECT customer_id, total_items, SUM(amt)
FROM just_prev_purchase
GROUP BY customer_id, total_items
ORDER BY customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

WITH price_points AS
(
  SELECT * ,
  CASE WHEN product_name = 'sushi' THEN price * 20
  ELSE price * 10
  END AS price_points
  FROM dannys_diner.menu
)

SELECT customer_id, SUM(price_points) as total_points
FROM dannys_diner.sales s, price_points p
WHERE s.product_id = p.product_id
GROUP BY customer_id
ORDER BY customer_id;
  
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?


