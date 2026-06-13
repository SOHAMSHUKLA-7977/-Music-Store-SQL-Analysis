USE music_store;
USE music_store;

-- =========================================
-- EASY LEVEL QUERIES
-- =========================================

-- Q1. Find the most senior employee based on job title

SELECT employee_id,
       first_name,
       last_name,
       title,
       levels
FROM employee
ORDER BY levels DESC
LIMIT 1;


-- Q2. Determine which countries have the most invoices

SELECT billing_country,
       COUNT(*) AS invoice_count
FROM invoice
GROUP BY billing_country
ORDER BY invoice_count DESC;


-- Q3. Identify the top 3 invoice totals

SELECT total
FROM invoice
ORDER BY total DESC
LIMIT 3;


-- Q4. Find the city with the highest total invoice amount

SELECT billing_city,
       SUM(total) AS total_invoice_amount
FROM invoice
GROUP BY billing_city
ORDER BY total_invoice_amount DESC
LIMIT 1;


-- Q5. Identify the customer who has spent the most money

SELECT c.customer_id,
       c.first_name,
       c.last_name,
       SUM(i.total) AS total_spent
FROM customer c
JOIN invoice i
ON c.customer_id = i.customer_id
GROUP BY c.customer_id,
         c.first_name,
         c.last_name
ORDER BY total_spent DESC
LIMIT 1;


-- =========================================
-- MODERATE LEVEL QUERIES
-- =========================================

-- Q1. Find the email, first name, and last name of customers who listen to Rock music

SELECT DISTINCT
       c.email,
       c.first_name,
       c.last_name
FROM customer c
JOIN invoice i
ON c.customer_id = i.customer_id
JOIN invoice_line il
ON i.invoice_id = il.invoice_id
JOIN track t
ON il.track_id = t.track_id
JOIN genre g
ON t.genre_id = g.genre_id
WHERE g.name = 'Rock'
ORDER BY c.email;


-- Q2. Identify the top 10 rock artists based on track count

SELECT a.name AS artist_name,
       COUNT(t.track_id) AS track_count
FROM artist a
JOIN album al
ON a.artist_id = al.artist_id
JOIN track t
ON al.album_id = t.album_id
JOIN genre g
ON t.genre_id = g.genre_id
WHERE g.name = 'Rock'
GROUP BY a.artist_id,
         a.name
ORDER BY track_count DESC
LIMIT 10;


-- Q3. Find all track names that are longer than the average track length

SELECT name,
       milliseconds
FROM track
WHERE milliseconds >
(
    SELECT AVG(milliseconds)
    FROM track
)
ORDER BY milliseconds DESC;


-- =========================================
-- ADVANCED LEVEL QUERIES
-- =========================================

-- Q1. Calculate how much each customer has spent on each artist

WITH customer_artist_spending AS
(
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        a.name AS artist_name,
        SUM(il.unit_price * il.quantity) AS total_spent
    FROM customer c
    JOIN invoice i
        ON c.customer_id = i.customer_id
    JOIN invoice_line il
        ON i.invoice_id = il.invoice_id
    JOIN track t
        ON il.track_id = t.track_id
    JOIN album al
        ON t.album_id = al.album_id
    JOIN artist a
        ON al.artist_id = a.artist_id
    GROUP BY
        c.customer_id,
        c.first_name,
        c.last_name,
        a.name
)
SELECT *
FROM customer_artist_spending
ORDER BY total_spent DESC;


-- Q2. Determine the most popular music genre for each country

WITH genre_purchases AS
(
    SELECT
        i.billing_country,
        g.name AS genre_name,
        COUNT(*) AS purchases,
        RANK() OVER
        (
            PARTITION BY i.billing_country
            ORDER BY COUNT(*) DESC
        ) AS genre_rank
    FROM invoice i
    JOIN invoice_line il
        ON i.invoice_id = il.invoice_id
    JOIN track t
        ON il.track_id = t.track_id
    JOIN genre g
        ON t.genre_id = g.genre_id
    GROUP BY
        i.billing_country,
        g.name
)
SELECT
    billing_country,
    genre_name,
    purchases
FROM genre_purchases
WHERE genre_rank = 1
ORDER BY billing_country;


-- Q3. Identify the top-spending customer for each country

WITH customer_spending AS
(
    SELECT
        i.billing_country,
        c.customer_id,
        c.first_name,
        c.last_name,
        SUM(i.total) AS total_spent,
        RANK() OVER
        (
            PARTITION BY i.billing_country
            ORDER BY SUM(i.total) DESC
        ) AS spending_rank
    FROM customer c
    JOIN invoice i
        ON c.customer_id = i.customer_id
    GROUP BY
        i.billing_country,
        c.customer_id,
        c.first_name,
        c.last_name
)
SELECT
    billing_country,
    customer_id,
    first_name,
    last_name,
    total_spent
FROM customer_spending
WHERE spending_rank = 1
ORDER BY billing_country;