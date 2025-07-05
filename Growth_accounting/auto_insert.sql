-- insert into growth_accounting
with dates as(
select * from generate_series(DATE '2023-01-01', DATE '2023-01-31', interval '1 day') as date
),
first_data as(
select 
user_id,
min(date(event_time)) as first_active
from events
where user_id is not null
group by 1
),
merged as(
select f.user_id,
		f.first_active,
		date(d.date) as date
from first_data f 
join dates d on f.first_active<=d.date
),
duplicate as(
select 
		m.*,
		date(e.event_time) as event_date
from merged m 
left join events e on m.date=date(e.event_time)
				  and m.user_id=e.user_id
),
deduped as(
select *,
row_number() over(partition by user_id,date) as rn
from duplicate
),
non_dupli as(
select user_id,
		first_active,
		max(event_date) over
		(partition by user_id order by date rows between unbounded preceding and current row) as last_active,
		date,
		event_date
		from deduped where rn=1 
),
prev as(
select *,
	  lag(last_active) over (partition by user_id order by date) as prev_active
		 from non_dupli
)
select user_id,
	   first_active,
	   last_active,
		case when 
					date=first_active then 'New'
			 when
			 		event_date is not null and date - prev_active = 1 then 'Retained'
			 when 
					event_date is not null and date - prev_active > 1 then 'Resurrected'
			 when 
			 		event_date is null and date - prev_active = 1 then 'Churned'
			 
			 else 'Stale'
			 end as daily_active,
			 case when 
					  date=first_active then 'New'
			 when
			 		event_date is not null and date - prev_active <= 7 then 'Retained'
			 when 
					event_date is not null and date - prev_active > 7 then 'Resurrected'
			 when 
			 		event_date is null and date - prev_active <= 7 then 'Churned'
			 
			 else 'Stale'
			 end as weekly_active,
			 array_remove(
  					array_agg(
    				CASE 
					      WHEN event_date IS NOT NULL THEN date
					      	ELSE NULL
					   			 END
					 		 ) OVER (PARTITION BY user_id
							  order by date),
					 		 NULL
							) AS date_active, 
			 date
		 from prev


