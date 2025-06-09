-- create type film_stats as(
-- 							year integer,
-- 							film text,
-- 							filmid text,
-- 							votes integer,
-- 							rating real,
-- 							avg_rating real
-- )
-- drop type film_stats
-- create type quality as enum('star','good','avg','bad')
-- drop table actors
-- create table actors(
-- 					actor text,
-- 					actorid text,
-- 					film_stats film_stats[],
-- 					quality quality,
-- 					is_active boolean,
-- 					years_since_last_movie integer,
-- 					current_year integer,
-- 					primary key(actor,current_year)
-- )
 insert into actors
 with yesterday as(
select * from actors
where current_year=1969
),
today as(
select * from actor_films
where year=1970
) 
select 
	  coalesce(t.actor,y.actor) as actor,
	   coalesce(t.actorid,y.actorid) as actorid,
	   case 
	   		when y.film_stats is null
			   then
			   array[row(
						t.film,
						t.filmid,
						t.year,
						t.votes,
						t.rating
			   )::film_stats
					]
			when t.year is not null 
				then y.film_stats || row(
									t.film,
									t.filmid,
									t.year,
									t.votes,
									t.rating
								   )::film_stats
				else y.film_stats
				end as film_stats,

		case
			when t.year is not null
				then	
					case 
							when t.rating>8 then 'star'
							when t.rating>7 and t.rating<=8 then 'good'
							when t.rating>6 and t.rating<=7 then 'avg'
							when t.rating<6 then 'bad'
							end::quality
					else y.quality
					end as quality,

	CASE 
    	WHEN t.year IS NOT NULL THEN true
    	ELSE false
		END AS is_active,
		
		case when 
			 t.year is not null then 0
			else y.years_since_last_movie + 1
		end as years_since_last_movie,
		
		coalesce(t.year, y.current_year + 1) as current_year

from today t full outer join yesterday y
on t.actor=y.actor

				
