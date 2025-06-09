insert into edges
with deduped as(
select *,
row_number() over (partition by player_id,game_id) as rn
from game_details)
select 
		player_id as subject_identifier,
		'player'::vertex_type as subject_type,
		game_id as object_identifier,
		'game'::vertex_type as object_type,
		'plays_in'::edge_type as edge_type,
		json_build_object(
				'start_position',start_position,
				'pts',pts,
				'team_id',team_id,
				'team_abbreviation',team_abbreviation
		) as properties
from deduped where rn=1;


insert into edges
with deduped as(
select *,
row_number() over (partition by player_id,game_id) as rn
from game_details
),
filtered as(
select * from deduped
where rn=1
),
aggregated as(
select 
		f1.player_id as subject_player_id,
		f2.player_id as object_player_id,
		case when f1.team_abbreviation=f2.team_abbreviation 
		then 'shares_team'::edge_type
		else 'plays_against'::edge_type
		end as edge_type,
		max(f1.player_name) as subject_player_name,
	    max(f2.player_name) as object_player_name,
		count(1) as num_games,
		sum(f1.pts) as subject_points,
		sum(f2.pts) as object_points
		from filtered f1
join filtered f2
on f1.game_id=f2.game_id
and f1.player_name<>f2.player_name
where f1.player_id>f2.player_id
group by f1.player_id,
		f2.player_id,
		case when f1.team_abbreviation=f2.team_abbreviation 
		then 'shares_team'::edge_type
		else 'plays_against'::edge_type
		end
	)
	select 
	subject_player_id as subject_identifier,
	'player'::vertex_type as subject_type,
	object_player_id as object_identifier,
	'player'::vertex_type as object_type,
	edge_type as edge_type,
	json_build_object(
						'num_games',num_games,
						'subject_points',subject_points,
						'object_points',object_points
	)
	from aggregated