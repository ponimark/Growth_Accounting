-- delete from growth_accounting
-- insert into growth_accounting
with yesterday as(
select * from growth_accounting
where date=date('2023-01-09')
),
today as(
select 
	user_id,
	date(event_time) as today_date,
	count(1)
from events
where date(event_time)=date('2023-01-10') and user_id is not null
group by 1,2
)
select 
		coalesce(cast(t.user_id as text),y.user_id) as user_id,
		coalesce(y.first_active,t.today_date) as first_active,
		coalesce(t.today_date,y.date) as last_active,
		case when 
					y.user_id is null then 'New'
			 when
			 		y.last_active = t.today_date - Interval '1 day' then 'Retained'
			 when 
					y.last_active < t.today_date - Interval '1 day' then 'Resurrected'
			 when 
			 		t.today_date is null and y.last_active = y.date then 'Churned'
			 
			 else 'Stale'
			 end as daily_active,
			 
			 case when 
			 y.user_id is null then 'New'
			 when
			 		y.last_active >= t.today_date - Interval '6 day' then 'Retained'
			 when 
					y.last_active < t.today_date - Interval '6 day' then 'Resurrected'
			 when 
			 		t.today_date is null and y.last_active < (y.date + interval '1 day') - interval '7 day' then 'Churned'
			 else 'Stale'
			 end as weekly_active,
		
		case when
					y.dates_active is null 
											then array[t.today_date]
			 when t.today_date is null then y.dates_active
			 else array[t.today_date]|| y.dates_active
			 end as dates_active,
			 coalesce(date(t.today_date),date(y.date + interval '1 day')) as date
			 from today t full outer join yesterday y on
			 cast(t.user_id as text)=y.user_id
			 
select *
from growth_accounting
where user_id='137925124111668560'

