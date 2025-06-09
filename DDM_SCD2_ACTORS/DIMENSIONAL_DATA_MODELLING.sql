-- select actor,
-- 		(unnest(film_stats)::film_stats).rating
-- 		from actors
-- 		where
-- 		current_year=2018
-- insert into actors
WITH year AS (
  SELECT * FROM generate_series(1970, 2019) AS years
),
a AS (
  SELECT actor, actorid, MIN(year) AS first_year
  FROM actor_films
  GROUP BY actor, actorid
),
actor_year AS (
  SELECT * FROM a
  JOIN year y ON a.first_year <= y.years
),
avg_rating AS (
  SELECT *,
    AVG(rating) OVER (PARTITION BY actor, year) AS ar
  FROM actor_films
),
windowed AS (
  SELECT 
    ay.actor,
    ay.actorid,
    ay.years,
    ARRAY_REMOVE(
      ARRAY_AGG(
        CASE 
          WHEN r.year IS NOT NULL THEN
            CAST(ROW(r.year, r.film, r.filmid, r.votes, r.rating,r.ar) AS film_stats)
          ELSE NULL
        END
      ) OVER (PARTITION BY ay.actor ORDER BY ay.years),
      NULL
    ) AS stats
  FROM actor_year ay
  LEFT JOIN avg_rating r
    ON ay.actor = r.actor AND ay.years = r.year
),
rnk as(

  SELECT 
  *,
  row_number() over(partition by actor,years order by years) as rn
  from windowed
)

select actor,
	   actorid,
	   stats,
	   case
	   		when  (stats[Cardinality(stats)]).avg_rating>8 then 'star' 
			when  (stats[Cardinality(stats)]).avg_rating>7  and (stats[Cardinality(stats)]).avg_rating<=8 then 'good' 
			when  (stats[Cardinality(stats)]).avg_rating>6  and (stats[Cardinality(stats)]).avg_rating<=7 then 'avg'
			when  (stats[Cardinality(stats)]).avg_rating<=6 then 'bad'
			end::quality as quality, 
			years=(stats[Cardinality(stats)]).year as is_active,
			years-(stats[Cardinality(stats)]).year as years_since_last_movie,
			years as current_year
			from rnk
			where rn=1 and years=2019
			
		


   
