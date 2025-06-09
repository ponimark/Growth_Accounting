-- create type scdnew as(
-- 					quality quality,
-- 					is_active boolean,
-- 					first_year integer,
-- 					last_year integer
-- )
-- truncate table actor_scd
-- insert into actor_scd
with lst as(
select * from actor_scd 
where current_year=2019
and last_year=2019
),
hist as(
select 
		actor,
		quality,
		is_active,
		first_year,
		last_year
		from actor_scd 
where current_year=2019
and last_year<2019
),
nr as(
select * from actors
where current_year=2020
),
unchanged as(
select 
		n.actor,
		n.quality,
		n.is_active,
		l.first_year,
		n.current_year as last_year
		from nr n 
		join
		lst l on 
		n.actor=l.actor
		where n.is_active=l.is_active
		and
		n.quality=l.quality
),
nested as(
select 
		n.actor,
		unnest(array[row(
					l.quality,
					l.is_active,
					l.first_year,
					l.last_year
		)::scdnew,
		row(
			n.quality,
			n.is_active,
			n.current_year,
			n.current_year
		)::scdnew])
		as records
		from nr n 
		left join
		lst l on 
		n.actor=l.actor
		where n.is_active<>l.is_active
		or
		n.quality<>l.quality
),
unnested as(
select 
		actor,
		(records::scdnew).quality,
		(records::scdnew).is_active,
		(records::scdnew).first_year,
		(records::scdnew).last_year
		from nested
),
new_record as(
		select 
		n.actor,
		n.quality,
		n.is_active,
		n.current_year as first_year,
		n.current_year as last_year
		from nr n
		left join
		lst l on
		n.actor=l.actor
		where l.actor is null
)
select *,
	2020 as current_year from hist
union all
select *,
	2020 as current_year from unchanged
union all
select *,
2020 as current_year from unnested
union all
select *,
2020 as current_year from new_record
order by actor,first_year

