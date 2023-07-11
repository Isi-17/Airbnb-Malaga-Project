-- SCHEMA: public

-- DROP SCHEMA IF EXISTS public ;

CREATE SCHEMA IF NOT EXISTS public
    AUTHORIZATION pg_database_owner;

COMMENT ON SCHEMA public
    IS 'standard public schema';

GRANT USAGE ON SCHEMA public TO PUBLIC;

GRANT ALL ON SCHEMA public TO pg_database_owner;

CREATE TABLE public.listings (
    id BIGINT PRIMARY KEY,
    listing_url TEXT NOT NULL,
    scrape_id BIGINT,
    last_scraped DATE,
    source TEXT,
    name TEXT,
    description TEXT,
    neighborhood_overview TEXT,
    picture_url TEXT,
    host_id BIGINT NOT NULL,
    host_url TEXT NOT NULL,
    host_name TEXT,
    host_since DATE,
    host_location TEXT,
    host_about TEXT,
    host_response_time TEXT,
    host_response_rate TEXT,
    host_acceptance_rate TEXT,
    host_is_superhost TEXT,
    host_thumbnail_url TEXT,
    host_picture_url TEXT,
    host_neighbourhood TEXT,
    host_listings_count INTEGER,
    host_total_listings_count INTEGER,
    host_verifications TEXT,
    host_has_profile_pic TEXT,
    host_identity_verified TEXT,
    neighbourhood TEXT,
    neighbourhood_cleansed TEXT,
    neighbourhood_group_cleansed TEXT,
    latitude FLOAT,
    longitude FLOAT,
    property_type TEXT,
    room_type TEXT,
    accommodates INTEGER,
    bathrooms FLOAT,
    bathrooms_text TEXT,
    bedrooms INTEGER,
    beds INTEGER,
    amenities TEXT,
    price TEXT,
    minimum_nights INTEGER,
    maximum_nights INTEGER,
    minimum_minimum_nights INTEGER,
    maximum_minimum_nights INTEGER,
    minimum_maximum_nights INTEGER,
    maximum_maximum_nights INTEGER,
    minimum_nights_avg_ntm FLOAT,
    maximum_nights_avg_ntm FLOAT,
    calendar_updated TEXT,
    has_availability TEXT,
    availability_30 INTEGER,
    availability_60 INTEGER,
    availability_90 INTEGER,
    availability_365 INTEGER,
    calendar_last_scraped DATE,
    number_of_reviews INTEGER,
    number_of_reviews_ltm INTEGER,
    number_of_reviews_l30d INTEGER,
    first_review DATE,
    last_review DATE,
    review_scores_rating FLOAT,
    review_scores_accuracy FLOAT,
    review_scores_cleanliness FLOAT,
    review_scores_checkin FLOAT,
    review_scores_communication FLOAT,
    review_scores_location FLOAT,
    review_scores_value FLOAT,
    license TEXT,
    instant_bookable TEXT,
    calculated_host_listings_count INTEGER,
    calculated_host_listings_count_entire_homes INTEGER,
    calculated_host_listings_count_private_rooms INTEGER,
    calculated_host_listings_count_shared_rooms INTEGER,
    reviews_per_month FLOAT
);

-- COPY listings FROM 'C:/listings.csv' DELIMITER ',' CSV HEADER;

CREATE TABLE public.reviews (
    listing_id BIGINT,
    id BIGINT,
    date DATE,
    reviewer_id BIGINT,
    reviewer_name TEXT,
    comments TEXT,
    PRIMARY KEY (listing_id, id),
    FOREIGN KEY (listing_id) REFERENCES listings (id)
);

-- COPY datos FROM 'C:/listings.csv' DELIMITER ',' CSV HEADER;

-- COPY reviews FROM 'C:/reviews.csv' DELIMITER ',' CSV HEADER;

CREATE TABLE public.calendar (
    listing_id BIGINT,
    date DATE,
    available CHAR(1),
    price VARCHAR(30),
    adjusted_price VARCHAR(30),
    minimum_nights INTEGER,
    maximum_nights INTEGER,
    PRIMARY KEY (listing_id, date),
    FOREIGN KEY (listing_id) REFERENCES listings (id)
);

-- COPY calendar FROM 'C:/calendar.csv' DELIMITER ',' CSV HEADER;

select * from calendar;

CREATE OR REPLACE VIEW public.top_earnings_popular_month AS
	SELECT
		id,
		listing_url,
		name,
		host_name,
		CAST(REGEXP_REPLACE(price, '[^\d.]', '', 'g') AS NUMERIC) AS price_numeric,
		(30 - availability_30) AS booked_out_30,
		CAST(REGEXP_REPLACE(price, '[^\d.]', '', 'g') AS NUMERIC) * (30 - availability_30) AS proj_rev_30
	FROM
		listings
	ORDER BY
		proj_rev_30 DESC
	LIMIT 30;

SELECT * FROM top_earnings_popular_month;

CREATE OR REPLACE VIEW public.top_earnings_popular_quarter AS
	SELECT
		id,
		listing_url,
		name,
		host_name,
		CAST(REGEXP_REPLACE(price, '[^\d.]', '', 'g') AS NUMERIC) AS price_numeric,
		(90 - availability_90) AS booked_out_90,
		CAST(REGEXP_REPLACE(price, '[^\d.]', '', 'g') AS NUMERIC) * (90 - availability_90) AS proj_rev_90
	FROM
		listings
	ORDER BY
		proj_rev_90 DESC
	LIMIT 30;

CREATE OR REPLACE VIEW public.top_earnings_popular_year AS
	SELECT
		id,
		listing_url,
		name,
		host_name,
		CAST(REGEXP_REPLACE(price, '[^\d.]', '', 'g') AS NUMERIC) AS price_numeric,
		(365 - availability_365) AS booked_out_365,
		CAST(REGEXP_REPLACE(price, '[^\d.]', '', 'g') AS NUMERIC) * (365 - availability_365) AS proj_rev_365
	FROM
		listings
	ORDER BY
		proj_rev_365 DESC
	LIMIT 30;


CREATE OR REPLACE VIEW public.top_earnings_popular_comparison AS
	SELECT
		id,
		listing_url,
		name,
		host_name,
		CAST(REGEXP_REPLACE(price, '[^\d.]', '', 'g') AS NUMERIC) AS price_numeric,
		30 - availability_30 AS booked_out_30,
		CAST(REGEXP_REPLACE(price, '[^\d.]', '', 'g') AS NUMERIC) * (30 - availability_30) AS proj_rev_30,
		90 - availability_90 AS booked_out_90,
		CAST(REGEXP_REPLACE(price, '[^\d.]', '', 'g') AS NUMERIC) * (90 - availability_90) AS proj_rev_90,
		365 - availability_365 AS booked_out_365,
		CAST(REGEXP_REPLACE(price, '[^\d.]', '', 'g') AS NUMERIC) * (365 - availability_365) AS proj_rev_365
	FROM
		listings
	ORDER BY
		proj_rev_30 DESC
	LIMIT 30;

-- Número total de alojamientos: 7534
SELECT COUNT(*) AS total_listings
FROM listings;

-- Nº alojamientos, porcentaje , precio promedio y duración promedio de la estancia de los alojamientos por tipo de propiedad:
SELECT property_type,  COUNT(*) AS count, 
    ROUND(AVG(CAST(REGEXP_REPLACE(listings.price, '[^\d.]', '', 'g') 
    AS NUMERIC))) AS avg_price, 
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM listings), 2) 
        AS percentage, 
ROUND(AVG(minimum_nights)) AS avg_minimum_nights
FROM listings
GROUP BY property_type 
ORDER BY count DESC;

-- Nº alojamientos, porcentaje, precio promedio y duración promedio de la estancia de los alojamientos por zona ordenados descendentemente:
SELECT neighbourhood_cleansed, COUNT(*) AS count, 
	ROUND(AVG(CAST(REGEXP_REPLACE(price, '[^\d.]', '', 'g') AS NUMERIC))) AS avg_price,
	ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM listings), 2) AS percentage,
        ROUND(AVG(minimum_nights)) AS avg_minimum_nights
FROM listings
GROUP BY neighbourhood_cleansed
ORDER BY avg_price DESC;


--Función para calcular el promedio de puntajes de revisión:
CREATE OR REPLACE FUNCTION calculate_average_rating()
RETURNS FLOAT AS $$
DECLARE
  avg_rating FLOAT;
BEGIN
  SELECT AVG(review_scores_rating) INTO avg_rating
  FROM listings;
  RETURN avg_rating;
END;
$$ LANGUAGE plpgsql;


-- Promedio de las calificaciones: 4.6136581898594216
SELECT calculate_average_rating() AS average_rating;

--Obtener los que tienen más comentarios junto con su valoración
SELECT li.listing_url, li.name, li.review_scores_rating, COUNT(*) AS comment_count
	FROM reviews
	JOIN listings li ON li.id = reviews.listing_id
	GROUP BY li.listing_url, li.name, li.review_scores_rating
	ORDER BY comment_count DESC;

-- Vista para mostrar la disponibilidad y el precio diario de los listados:
CREATE OR REPLACE VIEW listing_availability_price AS
SELECT c.listing_id, c.date, c.available, c.price, l.name
FROM calendar c
JOIN listings l ON c.listing_id = l.id;

SELECT * FROM listing_availability_price;

-- Funcion para calcular el numero minimo de noches
CREATE OR REPLACE FUNCTION calculate_max_minimum_nights()
  RETURNS INTEGER AS $$
DECLARE
  max_min_nights INTEGER;
BEGIN
  SELECT MAX(minimum_nights) INTO max_min_nights
  FROM calendar
  GROUP BY listing_id
  ORDER BY max_min_nights DESC
  LIMIT 1;

  RETURN max_min_nights;
END;
$$ LANGUAGE plpgsql;

-- El numero minimo de noches es 3 (la duración en días de la cantidad mínima de noches para alojarte)
SELECT calculate_max_minimum_nights() AS max_minimum_nights;

-- Alojamientos mejor valorados por categoría de propiedad.	
CREATE OR REPLACE VIEW top_rated_listings AS
	SELECT listing_url, property_type, name, review_scores_rating
	FROM listings
	WHERE review_scores_rating IS NOT NULL
	ORDER BY review_scores_rating DESC;

SELECT * FROM top_rated_listings;

-- Alojamientos peor valorados por categoría de propiedad.	
CREATE OR REPLACE VIEW least_rated_listings AS
	SELECT  listing_url, property_type, name, review_scores_rating
	FROM listings
	WHERE review_scores_rating IS NOT NULL
	ORDER BY review_scores_rating ASC;

SELECT * FROM least_rated_listings;

	
--Anfitriones más activos y su relación con las revisiones.	
SELECT host_id, host_name, host_url, host_listings_count, number_of_reviews
FROM (
    SELECT DISTINCT ON (host_id, host_name, host_url)
           host_id, host_name, host_url, host_listings_count, number_of_reviews
    FROM listings
    ORDER BY host_id, host_name, host_url, number_of_reviews DESC
) AS subquery
ORDER BY number_of_reviews DESC;

-- Relación entre el precio y el número de habitaciones: Precio medio por nº camas/habitaciones 
CREATE OR REPLACE VIEW price_by_bedrooms AS 
	SELECT bedrooms, ROUND(AVG(CAST(REGEXP_REPLACE(price, '[^\d.]', '', 'g') AS NUMERIC))) AS avg_price 
	FROM listings 
	GROUP BY bedrooms 
	ORDER BY avg_price DESC;

SELECT * FROM price_by_bedrooms;

 -- Tendencias de precios a lo largo del tiempo: precio medio segun la fecha
CREATE OR REPLACE VIEW price_trends AS 
	SELECT date, ROUND(AVG(CAST(REGEXP_REPLACE(price, '[^\d.]', '', 'g') AS NUMERIC))) AS avg_price 
	FROM calendar 
	GROUP BY date 
	ORDER BY date;

SELECT * FROM price_trends;

-- Tendencias de disponibilidad a lo largo del tiempo:
CREATE OR REPLACE VIEW availability_trends AS 
	SELECT	date, 
			SUM(CASE WHEN available = 't' THEN 1 ELSE 0 END) AS available_listings, 
			SUM(CASE WHEN available = 'f' THEN 1 ELSE 0 END) AS unavailable_listings 
	FROM calendar 
	GROUP BY date 
	ORDER BY date;

SELECT * FROM availability_trends;

-- Alojamiento con comentarios negativos: sucio, desordenado, ruidoso.
CREATE OR REPLACE VIEW negative_reviews AS
    SELECT li.id, li.listing_url, li.name, li.host_id, li.host_name, li.host_url, r.comments
    FROM reviews r
    JOIN listings li ON r.listing_id = li.id
    WHERE r.comments LIKE '%sucio%' OR
          r.comments LIKE '%desordenado%' OR
          r.comments LIKE '%ruidoso%'
    ORDER BY li.id;

SELECT * FROM negative_reviews;


--Alojamientos con mayor disponibilidad anual:
CREATE OR REPLACE VIEW year_availability AS
	SELECT name, availability_365
	FROM listings
	ORDER BY availability_365 DESC

SELECT * FROM year_availability;


-- Propietarios con más reseñas con comentarios negativos
CREATE OR REPLACE VIEW owner_negative_reviews AS
    SELECT li.host_name, li.host_id, li.host_url, COUNT(*) AS negative_review_count
    FROM reviews r
    JOIN listings li ON r.listing_id = li.id
    WHERE r.comments LIKE '%sucio%' OR
          r.comments LIKE '%desordenado%' OR
          r.comments LIKE '%ruidoso%'
    GROUP BY li.host_name, li.host_id, li.host_url
    ORDER BY negative_review_count DESC;

SELECT * FROM owner_negative_reviews;

--Porcentaje de alojamientos que tienen algún comentario negativo
SELECT COUNT(DISTINCT listing_id) AS total_listings,
       COUNT(DISTINCT CASE WHEN comments LIKE '%dirty%' 
			 OR comments LIKE '%sucio%' 
			 OR comments LIKE '%desordenado%' 
			 OR comments LIKE '%ruidoso%' THEN listing_id END) AS listings_with_dirty_comments,
       ROUND(COUNT(DISTINCT CASE WHEN comments LIKE '%dirty%' 
			 OR comments LIKE '%sucio%' 
			 OR comments LIKE '%desordenado%' 
			 OR comments LIKE '%ruidoso%'  THEN listing_id END) * 100.0 / COUNT(DISTINCT listing_id), 2) AS percentage
FROM reviews;


-- Alojamientos según la proximidad al centro de Málaga (36.718437, -4.419820)
SELECT
	id,
	listing_url,
	name,
	latitude,
	longitude,
	sqrt(pow(69.1 * (latitude - 36.718437), 2) + pow(69.1 * (longitude - -4.419820) * cos(latitude / 57.3), 2)) AS distance
	FROM
		listings
	ORDER BY
		distance;

-- Alojamientos según la proximidad al centro de Málaga (36.718437, -4.419820) ordenados de mejor a peor valoración en función de la distancia.
SELECT
	id,
	listing_url,
	name,
	latitude,
	longitude,
	sqrt(pow(69.1 * (latitude - 36.718437), 2) + pow(69.1 * (longitude - -4.419820) * cos(latitude / 57.3), 2)) AS distance,
	review_scores_rating
	FROM
		listings
	ORDER BY
		distance, review_scores_rating;

-- Porcentaje de propietarios con más de una propiedad.
CREATE OR REPLACE FUNCTION calculate_multiple_properties_percentage()
  RETURNS FLOAT AS $$
DECLARE
  total_hosts INTEGER;
  hosts_with_multiple_properties INTEGER;
  percentage FLOAT;
BEGIN
  SELECT COUNT(DISTINCT host_id) INTO total_hosts
  FROM listings;

  SELECT COUNT(*) INTO hosts_with_multiple_properties
  FROM (
    SELECT host_id
    FROM listings
    GROUP BY host_id
    HAVING COUNT(*) > 1
  ) AS multiple_properties;

  percentage := (hosts_with_multiple_properties::FLOAT / total_hosts::FLOAT) * 100;

  RETURN ROUND(percentage);
END;
$$ LANGUAGE plpgsql;

-- Ejecutar la función
SELECT calculate_multiple_properties_percentage() AS percentage;

-- Cuántos hosts se unen cada año
SELECT EXTRACT(YEAR FROM host_since) AS joined_year, COUNT(DISTINCT host_id) AS new_hosts
	FROM listings
	GROUP BY joined_year
	ORDER BY joined_year;

-- Media de precios de alojamiento en función de su valoracion
SELECT
  rating_range,
  ROUND(AVG(CAST(REGEXP_REPLACE(price, '[^\d.]', '', 'g') AS NUMERIC)), 2) AS average_price
FROM (
  SELECT
	CASE
	  WHEN review_scores_rating BETWEEN 0 AND 1 THEN '0-1'
	  WHEN review_scores_rating > 1 AND review_scores_rating <= 2 THEN '1-2'
	  WHEN review_scores_rating > 2 AND review_scores_rating <= 3 THEN '2-3'
	  WHEN review_scores_rating > 3 AND review_scores_rating <= 4 THEN '3-4'
	  WHEN review_scores_rating > 4 AND review_scores_rating <= 5 THEN '4-5'
	END AS rating_range,
	price
  FROM listings
  WHERE review_scores_rating IS NOT NULL
) AS subquery
GROUP BY rating_range
ORDER BY rating_range;


--Porcentaje de tipos de habitaciones y valoracion promedia del alojamiento en función del tipo de habitación de alojamiento. Vemos que las shared room tienen media 4 frente al resto 5.
SELECT room_type, COUNT(*) AS count, ROUND(AVG(review_scores_rating)) AS avg_rating, ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM listings), 2) AS percentage
FROM listings
WHERE review_scores_rating IS NOT NULL
GROUP BY room_type
ORDER BY avg_rating DESC;

-- Porcentaje y nº camas por alojamiento
SELECT beds, COUNT(*) AS count, ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM listings), 2) AS percentage
FROM listings
GROUP BY beds
ORDER BY percentage DESC;


--Porcentaje de precio. Podemos ver el precio modal.
SELECT price, COUNT(*) AS count, ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM listings), 2) AS percentage
FROM listings
GROUP BY price
ORDER BY percentage DESC;

--Porcentaje de minimo numero de noches.
SELECT minimum_nights, COUNT(*) AS count, ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM listings), 2) AS percentage
FROM listings
GROUP BY minimum_nights
ORDER BY percentage DESC;

--Porcentaje de puntuaciones
SELECT review_scores_rating, COUNT(*) AS count, ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM listings), 2) AS percentage
FROM listings
GROUP BY review_scores_rating
ORDER BY percentage DESC;


--Crear índices para mejorar la velocidad de búsqueda: 
-- Tabla "listings"
CREATE INDEX idx_listings_id ON listings (id);
CREATE INDEX idx_listings_host_id ON listings (host_id);
CREATE INDEX idx_listings_host_id_property_type ON listings (host_id, property_type);
CREATE INDEX idx_listings_location ON listings USING gist (point(latitude, longitude));
CREATE INDEX idx_listings_distance ON listings (sqrt(pow(69.1 * (latitude - 36.718437), 2) + pow(69.1 * (longitude - -4.419820) * cos(latitude / 57.3), 2)));

-- Tabla "reviews"	
CREATE INDEX idx_reviews_listing_id ON reviews (listing_id);
CREATE INDEX idx_listings_review ON reviews USING gin(to_tsvector('spanish', comments));

-- Tabla "calendar"
CREATE INDEX idx_calendar_listing_id_date ON calendar (listing_id, date);
CREATE INDEX idx_calendar_availability ON calendar (available);
CREATE INDEX idx_calendar_listing_id ON calendar (listing_id);


	
