-- create table actor_scd(
-- 		actor text,
-- 		quality quality,
-- 		is_active boolean,
-- 		first_year integer,
-- 		last_year integer,
-- 		current_year integer,
-- 		primary key(actor,first_year)
-- )
-- truncate table actor_scd
-- insert into actor_scd
with previous as(
select
		actor,
		current_year,
		quality,
		is_active,
		lag(quality) over (partition by actor order by current_year) as previous_quality,
		lag(is_active) over (partition by actor order by current_year) as previous_is_active
		from actors
		where current_year<=2020
),
change_indicator as(
select *,
		case
			when quality<>previous_quality then 1
			when is_active<>previous_is_active then 1
			else 0
			end as change_indicator
			from previous
),
cumulative as(
select *,
sum(change_indicator) over (partition by actor order by current_year) as streak
from change_indicator
)
select actor,
		quality,
		is_active,
		min(current_year) as first_year,
		max(current_year) as last_year,
		 2020 as current_year
		from cumulative
		group by actor,quality,is_active,streak
		order by actor,first_year
