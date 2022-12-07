--1. What is the total amount each customer spent at the restaurant?

SELECT s.customer_id
	, SUM(m.price)

FROM dannys_diner.menu m
JOIN dannys_diner.sales s
	ON s.product_id = m.product_id

GROUP BY s.customer_id
ORDER BY s.customer_id;

/*
| customer_id | sum |
| ----------- | --- |
| A           | 76  |
| B           | 74  |
| C           | 36  |
*/

--2. How many days has each customer visited the restaurant?

SELECT customer_id
	, COUNT(DISTINCT order_date)

FROM dannys_diner.sales

GROUP BY customer_id;

/*
| customer_id | count |
| ----------- | ----- |
| A           | 4     |
| B           | 6     |
| C           | 2     |
*/

--3. What was the first item from the menu purchased by each customer?

WITH rank AS (
  SELECT s.customer_id
	, s.order_date
	, m.product_id
	, m.product_name
	, DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS rank

FROM dannys_diner.menu m
JOIN dannys_diner.sales s
	ON s.product_id = m.product_id

GROUP BY s.customer_id
	, s.order_date
	, m.product_id
	, m.product_name
)
SELECT customer_id
	, product_name

FROM rank

WHERE rank = 1;

/*
| customer_id | product_name |
| ----------- | ------------ |
| A           | sushi        |
| A           | curry        |
| B           | curry        |
| C           | ramen        |
*/

--4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT m.product_name
	, COUNT(s.product_id)

FROM dannys_diner.sales s
JOIN dannys_diner.menu m
	ON m.product_id = s.product_id

GROUP BY m.product_name
ORDER BY COUNT(s.product_id) DESC
LIMIT 1

/*
| product_name | count |
| ------------ | ----- |
| ramen        | 8     |
*/

--5. Which item was the most popular for each customer?

SELECT s.customer_id
	, m.product_name

FROM dannys_diner.sales s
JOIN dannys_diner.menu m
	ON m.product_id = s.product_id

GROUP BY s.customer_id, m.product_name
ORDER BY COUNT(s.product_id) DESC
LIMIT 3

/*
| customer_id | product_name |
| ----------- | ------------ |
| C           | ramen        |
| A           | ramen        |
| B           | curry        |
*/

--6. Which item was purchased first by the customer after they became a member?

WITH rank AS (
  SELECT s.customer_id
  , mem.join_date
  , s.order_date
  , men.Product_id
  , men.product_name
  , DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS rank
  
	FROM dannys_diner.sales s
	JOIN dannys_diner.menu men
		ON men.product_id = s.product_id
	JOIN dannys_diner.members mem
		ON mem.customer_id = s.customer_id

 	 WHERE s.order_date >= mem.join_date
)
SELECT customer_id
, product_name

FROM rank

WHERE rank = 1

/*
| customer_id | product_name |
| ----------- | ------------ |
| A           | curry        |
| B           | sushi        |
*/

--7. Which item was purchased just before the customer became a member?

WITH rank AS (
	SELECT s.customer_id
	, mem.join_date
	, s.order_date
	, men.Product_id
	, men.product_name
	, DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS rank

	FROM dannys_diner.sales s
	JOIN dannys_diner.menu men
		ON men.product_id = s.product_id
	JOIN dannys_diner.members mem
		ON mem.customer_id = s.customer_id

	WHERE s.order_date < mem.join_date
)
SELECT customer_id
	, product_name

FROM rank

WHERE rank = 1

/*
| customer_id | product_name |
| ----------- | ------------ |
| A           | sushi        |
| A           | curry        |
| B           | sushi        |
*/

--8. What is the total items and amount spent for each member before they became a member?

SELECT s.customer_id
	, SUM(men.price)
	, COUNT(s.product_id)

FROM dannys_diner.sales s
JOIN dannys_diner.menu men
	ON men.product_id = s.product_id
JOIN dannys_diner.members as mem
	ON mem.customer_id = s.customer_id

WHERE s.order_date < mem.join_date
GROUP BY s.customer_id

/*
| customer_id | sum | count |
| ----------- | --- | ----- |
| B           | 40  | 3     |
| A           | 25  | 2     |
*/

--9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

WITH points AS (
  SELECT *
  , CASE WHEN s.product_id = 1 THEN men.price * 20 
		ELSE men.price * 10 
		END AS points

	FROM dannys_diner.sales s
	JOIN dannys_diner.menu men
		ON men.product_id = s.product_id
  )
SELECT customer_id
	, SUM(points) AS total_points

FROM points

GROUP BY customer_id

/*
| customer_id | total_points |
| ----------- | ------------ |
| B           | 940          |
| C           | 360          |
| A           | 860          |
*/

--10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

WITH mem_date AS (
	SELECT *
	, m.join_date + 6 AS valid_date
	, CAST('2021-01-31' AS DATE) AS eomonth

	FROM dannys_diner.members m
)
SELECT s.customer_id
	, SUM(CASE WHEN s.product_id = 1 THEN men.price * 20 
			WHEN s.order_date BETWEEN md.join_date AND md.valid_date THEN men.price * 20
			ELSE men.price * 10 
			END ) AS points

FROM dannys_diner.sales s
JOIN dannys_diner.menu men
	ON men.product_id = s.product_id
JOIN mem_date md
	ON md.customer_id = s.customer_id

WHERE s.order_date < md.eomonth
GROUP BY s.customer_id

/*
| customer_id | points |
| ----------- | ------ |
| A           | 1370   |
| B           | 820    |
*/

--**BONUS QUESTION**

--Join All The Things

SELECT s.customer_id
	, s.order_date
	, men.product_name
	, men.price
	, CASE WHEN s.customer_id = mem.customer_id AND s.order_date >= mem.join_date THEN 'Y' 
		ELSE 'N' 
		END AS member

FROM dannys_diner.sales s
JOIN dannys_diner.menu men
	ON men.product_id = s.product_id
LEFT JOIN dannys_Diner.members mem
	ON mem.customer_id = s.customer_id

ORDER BY customer_id
	, order_date

/*
| customer_id | order_date               | product_name | price | member |
| ----------- | ------------------------ | ------------ | ----- | ------ |
| A           | 2021-01-01T00:00:00.000Z | sushi        | 10    | N      |
| A           | 2021-01-01T00:00:00.000Z | curry        | 15    | N      |
| A           | 2021-01-07T00:00:00.000Z | curry        | 15    | Y      |
| A           | 2021-01-10T00:00:00.000Z | ramen        | 12    | Y      |
| A           | 2021-01-11T00:00:00.000Z | ramen        | 12    | Y      |
| A           | 2021-01-11T00:00:00.000Z | ramen        | 12    | Y      |
| B           | 2021-01-01T00:00:00.000Z | curry        | 15    | N      |
| B           | 2021-01-02T00:00:00.000Z | curry        | 15    | N      |
| B           | 2021-01-04T00:00:00.000Z | sushi        | 10    | N      |
| B           | 2021-01-11T00:00:00.000Z | sushi        | 10    | Y      |
| B           | 2021-01-16T00:00:00.000Z | ramen        | 12    | Y      |
| B           | 2021-02-01T00:00:00.000Z | ramen        | 12    | Y      |
| C           | 2021-01-01T00:00:00.000Z | ramen        | 12    | N      |
| C           | 2021-01-01T00:00:00.000Z | ramen        | 12    | N      |
| C           | 2021-01-07T00:00:00.000Z | ramen        | 12    | N      |
*/

--Rank All The Things

WITH ranking AS (
	SELECT s.customer_id
	, s.order_date
	, men.product_name
	, men.price
	, CASE WHEN s.customer_id = mem.customer_id AND s.order_date >= mem.join_date THEN 'Y' 
		ELSE 'N' 
		END AS member

	FROM dannys_diner.sales s
	 JOIN dannys_diner.menu men
		ON men.product_id = s.product_id
	LEFT JOIN dannys_Diner.members mem
		ON mem.customer_id = s.customer_id
 )
SELECT *
	, CASE WHEN member  = 'Y' THEN RANK() OVER (PARTITION BY customer_id, member ORDER BY order_date)
		END AS ranking

FROM ranking

ORDER BY customer_id
	, order_date

/*
| customer_id | order_date               | product_name | price | member | ranking |
| ----------- | ------------------------ | ------------ | ----- | ------ | ------- |
| A           | 2021-01-01T00:00:00.000Z | sushi        | 10    | N      |         |
| A           | 2021-01-01T00:00:00.000Z | curry        | 15    | N      |         |
| A           | 2021-01-07T00:00:00.000Z | curry        | 15    | Y      | 1       |
| A           | 2021-01-10T00:00:00.000Z | ramen        | 12    | Y      | 2       |
| A           | 2021-01-11T00:00:00.000Z | ramen        | 12    | Y      | 3       |
| A           | 2021-01-11T00:00:00.000Z | ramen        | 12    | Y      | 3       |
| B           | 2021-01-01T00:00:00.000Z | curry        | 15    | N      |         |
| B           | 2021-01-02T00:00:00.000Z | curry        | 15    | N      |         |
| B           | 2021-01-04T00:00:00.000Z | sushi        | 10    | N      |         |
| B           | 2021-01-11T00:00:00.000Z | sushi        | 10    | Y      | 1       |
| B           | 2021-01-16T00:00:00.000Z | ramen        | 12    | Y      | 2       |
| B           | 2021-02-01T00:00:00.000Z | ramen        | 12    | Y      | 3       |
| C           | 2021-01-01T00:00:00.000Z | ramen        | 12    | N      |         |
| C           | 2021-01-01T00:00:00.000Z | ramen        | 12    | N      |         |
| C           | 2021-01-07T00:00:00.000Z | ramen        | 12    | N      |         |
*/