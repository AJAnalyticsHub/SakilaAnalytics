-- SAKILA QUESTIONS (CASES AND STORED PROCEDURES/FUNCTIONS) --

-- ------------------------------------------------------------------------------- --
-- Group and count films into 'Short', 'Medium', and 'Long' based on their length. --
-- ------------------------------------------------------------------------------- --

SELECT 
CASE
WHEN length < 60 THEN 'Short'
WHEN length BETWEEN 60 AND 120 THEN 'Medium'
ELSE 'Long'
END AS film_length,
COUNT(film_id) AS count
FROM film
GROUP BY film_length
ORDER BY count DESC;

-- ---------------------------------------------------------------------------------------------------------------------------------------- --
-- Group and count customers based on the total amount they have spent on rentals into 'Low Spender', 'Medium Spender', and 'High Spender'. --
-- ---------------------------------------------------------------------------------------------------------------------------------------- --

SELECT 
    spending_profile, COUNT(*) AS customer_count
FROM
    (SELECT customer_id,
            CASE
                WHEN SUM(amount) < 75 THEN 'Low Spender'
                WHEN SUM(amount) BETWEEN 75 AND 150 THEN 'Medium Spender'
                ELSE 'High Spender'
            END AS spending_profile
    FROM payment
    GROUP BY customer_id) AS customer_spending_categorisation
GROUP BY spending_profile;

-- ------------------------------------------------------------------------------- --
-- Find the names and email addresses of customers in the 'High Spender' category. --
-- ------------------------------------------------------------------------------- --

SELECT c.first_name, c.last_name, c.email
FROM (SELECT customer_id,
            CASE
                WHEN SUM(amount) < 75 THEN 'Low Spender'
                WHEN SUM(amount) BETWEEN 75 AND 150 THEN 'Medium Spender'
                ELSE 'High Spender'
            END AS spending_profile
    FROM payment
    GROUP BY customer_id) AS customer_spending_categorisation
    JOIN customer AS c
    ON customer_spending_categorisation.customer_id = c.customer_id
    WHERE spending_profile = 'High Spender'
    ORDER BY c.last_name, c.first_name;
  
-- ---------------------------------------------------------------------------------------------------------------------------------- --
-- Create a report showing each film's title and categorize them based on their rental rate into 'Budget', 'Standard', and 'Premium'. --
-- ---------------------------------------------------------------------------------------------------------------------------------- --

SELECT title,
CASE 
WHEN rental_rate < 2 THEN 'Budget'
WHEN rental_rate BETWEEN 2 AND 4 THEN 'Standard'
ELSE 'Premium'
END AS rental_category
FROM film;

-- --------------------------------------------------------------------------------------------------------------- --
-- Generate a report that shows the name of each city along with a classification of 'Small', 'Medium', or 'Large' --
-- ------------------------- based on the number of customers in each city. -------------------------------------- --
-- --------------------------------------------------------------------------------------------------------------- --

SELECT
    c.city,
    CASE
        WHEN COUNT(cus.customer_id) < 2 THEN 'Small'
        WHEN COUNT(cus.customer_id) BETWEEN 2 AND 3 THEN 'Medium'
        ELSE 'Large'
    END AS city_size
FROM city AS c
JOIN address AS a
ON c.city_id = a.city_id
JOIN customer AS cus 
ON a.address_id = cus.address_id
GROUP BY c.city;

-- --------------------------------------------------------------------------------------------------- --
-- ------------------------ Create a stored procedure "rental_history". ------------------------------ --
-- ---------------- Inputs will be customer_first_name and customer_last_name. ----------------------- --
-- The procedure should return a result set with the titles of all films that the customer has rented. --
-- ------------------------- Include the rental date in the result set. ------------------------------ --
-- --------------------------------------------------------------------------------------------------- --

DELIMITER //

CREATE PROCEDURE rental_history(
    IN customer_first_name VARCHAR(45),
    IN customer_last_name VARCHAR(45)
)
BEGIN
    SELECT f.title, r.rental_date
    FROM customer AS c
    JOIN rental AS r
    ON c.customer_id = r.customer_id
    JOIN inventory AS i 
    ON r.inventory_id = i.inventory_id
    JOIN film AS f
    ON  i.film_id = f.film_id
    WHERE c.first_name = customer_first_name
      AND c.last_name = customer_last_name
    ORDER BY r.rental_date DESC;
END //

DELIMITER ;


-- ------------------------------------------------- --
-- Find the rental history of customer Mabel Holland --
-- ------------------------------------------------- --

CALL rental_history('Mabel','Holland');

-- -------------------------------------------------------------------------------- --
-- ------------ Create a stored procedure named "staff_sales". -------------------- --
-- ------------------- Input parameter will be staffID. --------------------------- --
-- The procedure should return the total amount of sales made by that staff member. --
-- -------------------------------------------------------------------------------- --

DELIMITER //

CREATE PROCEDURE staff_sales(
IN staffID TINYINT
)
BEGIN
SELECT s.staff_id, SUM(p.amount) AS total_sales
FROM staff AS s
JOIN payment AS p
ON  s.staff_id = p.staff_id
WHERE s.staff_id = staffID
GROUP BY s.staff_id;
END //

DELIMITER ;

-- ---------------------------------------------------------- --
-- Find the total sales of the member of staff with staffID 1 --
-- ---------------------------------------------------------- --

CALL staff_sales(1);

-- ------------------------------------------------------ --
-- Create a stored function named 'get_last_rental_date'. --
-- ------ Input parameter will be customer ID.----------- --
-- Return the date of the customer's most recent rental.  --
-- ------------------------------------------------------ --

DELIMITER //

CREATE FUNCTION discount_available(
customerID INT
)
RETURNS DECIMAL(3,2)
DETERMINISTIC
BEGIN
DECLARE film_count INT;
DECLARE discount DECIMAL(3,2);
SELECT COUNT(*)
INTO film_count
FROM rental 
WHERE customer_id = customerID
AND MONTH(rental_date) = MONTH(last_update)
AND YEAR(rental_date) = YEAR(last_update);
SET discount = CASE
WHEN film_count < 5 THEN 1.00
WHEN film_count BETWEEN 5 AND 10 THEN 0.90
ELSE 0.80
END;
RETURN discount;
END //

DELIMITER ;

-- ------------------------------------------------------------------------- --
-- -------- Create a stored procedure named "total_after_discount" --------- --
-- ----------- Input parameter will be customer ID and discount. ----------- --
-- The procedure should return a result set with total amount after discount --
-- ------------------------------------------------------------------------- --

DELIMITER //

CREATE PROCEDURE total_after_discount(
IN customerID INT,
OUT amount_with_discount DEC(4,2)
)
BEGIN
DECLARE discount DEC(3,2);
DECLARE total_amount DEC(4,2);
SET discount = discount_available(customerID);
 SELECT SUM(amount)
    INTO total_amount
    FROM payment
    WHERE customer_id = customerID
    AND rental_date = curdate();
 SET amount_with_discount = total_amount * discount;
END //

DELIMITER ;

-- ----------------------------------------------------------- --
-- Calculate the grand total of sales for a customer with ID 4 --
-- ----------------------------------------------------------- --

SET @total_after_discount = 0;

CALL total_after_discount(4, @total_after_discount);

SELECT @total_after_discount AS amount_with_discount;
