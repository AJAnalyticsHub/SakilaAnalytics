-- ------------------------------------ --
-- SAKILA DB practice questions (starter) --
-- ------------------------------------ --

USE sakila;

-- ------------------------------------------------------- --
-- Find the titles of all films that have a rating of 'PG' --
-- ------------------------------------------------------- --

SELECT title
FROM film
WHERE rating = 'PG'
ORDER BY title;

-- ------------------------------------------------------------------------------------- --
-- List the first and last names of all customers who live in the city of 'Southampton'. --
-- ------------------------------------------------------------------------------------- --

SELECT cus.first_name, cus.last_name
FROM customer AS cus
JOIN address AS a
ON cus.address_id = a.address_id
JOIN city AS c
ON a.city_id = c.city_id
WHERE c.city = 'Southampton'
ORDER BY cus.first_name;

-- --------------------------------------------------------- --
-- Retrieve the names of all films in the 'Comedy' category. --
-- --------------------------------------------------------- --

SELECT f.title
FROM film AS f
JOIN film_category AS fc
ON f.film_id = fc.film_id
JOIN category AS c
ON fc.category_id = c.category_id
WHERE c.name = 'Comedy'
ORDER BY f.title;

-- -------------------------------------------------------- --
-- Count the total number of rentals made by each customer. --
-- -------------------------------------------------------- --

SELECT c.customer_id, COUNT(r.rental_id) AS total_rentals
FROM customer AS c
JOIN rental AS r
ON c.customer_id = r.customer_id
GROUP BY c.customer_id
ORDER BY c.customer_id DESC;

-- ----------------------------------------------------------------------- --
-- Get the titles of all films that have a length greater than 120 minutes --
-- ----------------------------------------------------------------------- --

SELECT title, length
FROM film
WHERE length > 120
ORDER BY length DESC;

-- --------------------------------------------------------------------- --
-- List the names of all actors who have appeared in more than 20 films. --
-- --------------------------------------------------------------------- --

SELECT a.first_name, a.last_name, COUNT(fa.film_id) AS total_roles
FROM actor AS a
JOIN film_actor AS fa
ON a.actor_id = fa.actor_id
GROUP BY fa.actor_id
ORDER BY total_roles DESC;

-- --------------------------------------------------------------------------------------- --
-- Retrieve the email addresses of all customers who have rented a film in the last month. --
-- --------------------------------------------------------------------------------------- --

SELECT c.first_name, c.last_name, c.email
FROM customer AS c
JOIN rental AS r
ON c.customer_id = r.customer_id
WHERE TIMESTAMPDIFF(MONTH, r.last_update, r.rental_date) < 1
GROUP BY r.customer_id
ORDER BY c.first_name;

-- ---------------------------------------------------------- --
-- Get the total number of films available for each category. --
-- ---------------------------------------------------------- --

SELECT c.name, COUNT(f.film_id) AS total_titles
FROM category AS c
JOIN film_category AS fc
ON c.category_id = fc.category_id
JOIN film AS f
ON fc.film_id = f.film_id
GROUP BY c.name
ORDER BY c.name;

-- ------------------------------------------- --
-- Find the names and addresses of all stores. --
-- ------------------------------------------- --

SELECT s.store_id, CONCAT(a.address,',' ,a.district ,',',c.city) AS full_address 
FROM store AS s
JOIN address AS a
ON s.address_id = a.address_id
JOIN city AS c
ON a.city_id = c.city_id;
