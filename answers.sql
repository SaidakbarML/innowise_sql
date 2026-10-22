--1 Output the number of movies in each category, sorted descending.
SELECT
    c.category_id,
    COUNT(fc.film_id)
FROM film_category fc
JOIN category c
    ON c.category_id = fc.category_id
GROUP BY c.category_id
ORDER BY c.category_id;


--2 Output the top 10 actors whose movies were rented the most, sorted in descending order.
SELECT
    a.actor_id,
    a.first_name,
    a.last_name,
    COUNT(r.rental_id) AS rentals
FROM film_actor fa
JOIN inventory i
    ON i.film_id = fa.film_id
JOIN rental r
    ON r.inventory_id = i.inventory_id
JOIN actor a
    ON a.actor_id = fa.actor_id
GROUP BY a.actor_id, a.first_name, a.last_name
ORDER BY rentals DESC
LIMIT 10;

--3 Output the category of movies on which the most money was spent.
SELECT
    c.name,
    SUM(p.amount)
FROM payment p
JOIN rental r
    ON p.rental_id = r.rental_id
JOIN inventory i
    ON i.inventory_id = r.inventory_id
JOIN film f
    ON f.film_id = i.film_id
JOIN film_category fc
    ON fc.film_id = f.film_id
JOIN category c
    ON c.category_id = fc.category_id
GROUP BY c.name
ORDER BY SUM(p.amount) DESC
LIMIT 1;


--4 Print the names of movies that are not in the inventory. Write a query without using the IN operator.
SELECT f.title
FROM film f
LEFT JOIN inventory i
    ON i.film_id = f.film_id
WHERE i.inventory_id IS NULL;


--5 Output the top 3 actors who have appeared the most in movies in the “Children” category. If several actors have the same number of movies, output all of them.
WITH temp_table AS (
    SELECT
        a.first_name AS actor_name,
        COUNT(c.name) AS category_count,
        DENSE_RANK() OVER (ORDER BY COUNT(c.name) DESC) AS ranking
    FROM actor a
    JOIN film_actor fa
        ON fa.actor_id = a.actor_id
    JOIN film f
        ON f.film_id = fa.film_id
    JOIN film_category fc
        ON fc.film_id = f.film_id
    JOIN category c
        ON c.category_id = fc.category_id
    WHERE c.name = 'Children'
    GROUP BY a.first_name
    ORDER BY category_count DESC
)
SELECT
    actor_name,
    category_count AS count_children_play
FROM temp_table
WHERE ranking <= 3;


--6 Output cities with the number of active and inactive customers (active - customer.active = 1). Sort by the number of inactive customers in descending order.
SELECT
    c.city,
    SUM(CASE WHEN c2.active = 1 THEN 1 ELSE 0 END) AS active_users,
    SUM(CASE WHEN c2.active = 0 THEN 1 ELSE 0 END) AS inactive_user
FROM city c
JOIN address a
    ON a.city_id = c.city_id
JOIN customer c2
    ON c2.address_id = a.address_id
GROUP BY c.city
ORDER BY inactive_user DESC;


--7 Output the category of movies that have the highest number of total rental hours in the city (customer.address_id in this city) and that start with the letter “a”. Do the same for cities that have a “-” in them. Write everything in one query.
WITH temp_table AS (
    SELECT
        c.city,
        c.city_id,
        fc.category_id,
        EXTRACT(EPOCH FROM (r.return_date - r.rental_date)) / 3600 AS rental_hour
    FROM city c
    JOIN address a
        ON a.city_id = c.city_id
    JOIN customer c2
        ON c2.address_id = a.address_id
    JOIN rental r
        ON c2.customer_id = r.customer_id
    JOIN inventory i
        ON i.inventory_id = r.inventory_id
    JOIN film f
        ON f.film_id = i.film_id
    JOIN film_category fc
        ON fc.film_id = f.film_id
),
ranked AS (
    SELECT
        city,
        city_id,
        category_id,
        SUM(rental_hour) AS rental_hours,
        RANK() OVER (PARTITION BY city_id ORDER BY SUM(rental_hour) DESC) AS rnk
    FROM temp_table
    GROUP BY city_id, city, category_id
    ORDER BY city_id, SUM(rental_hour) DESC
)
SELECT
    r.city,
    cat.name AS category,
    r.rental_hours
FROM ranked r
JOIN category cat
    ON cat.category_id = r.category_id
WHERE r.rnk = 1
  AND (r.city ILIKE 'a%' OR r.city LIKE '%-%')
ORDER BY r.city;
