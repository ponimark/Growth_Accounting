select v.properties->>'player_name',
v2.properties->>'player_name',
coalesce(cast(v.properties->>'total_points' as real) /
cast(v.properties->>'number_of_games' as real), 0) career_points_x_games ,
coalesce(cast(e.properties->>'subject_points' as real) /
cast(e.properties->>'num_games' as real), 0) points_x_games ,
e.properties->>'subject_points' subject_points,
e.properties->>'num_games' num_games,
e.edge_type
from vertices v join edges e
on e.subject_identifier = v.identifier
and e.subject_type = v.type
join vertices v2 on 
v2.identifier = e.object_identifier
and e.subject_type = v2.type
where e.object_type = 'player'::vertex_type;