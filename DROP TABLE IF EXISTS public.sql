DROP TABLE IF EXISTS public.facility_network_points_noded;

CREATE TABLE public.facility_network_points_noded AS
SELECT
    hf.id AS facility_id,
    -hf.id AS pid,
    r.id AS edge_id,
    ST_LineLocatePoint(r.geom, hf.geom) AS fraction,
    'b'::char AS side,
    ST_Distance(
        hf.geom,
        ST_ClosestPoint(r.geom, hf.geom)
    ) AS distance_to_road_m
FROM public.health_facilities hf
CROSS JOIN LATERAL (
    SELECT r.*
    FROM public.roads_noded_routing_fixed r
    ORDER BY hf.geom <-> r.geom
    LIMIT 1
) r
WHERE hf.id <> 73;