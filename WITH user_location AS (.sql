WITH user_location AS (
    SELECT geom
    FROM public.health_facilities
    WHERE id = 1
),

nearest_road AS (
    SELECT
        r.id,
        r.source,
        r.target
    FROM public.roads_noded_routing_fixed r
    CROSS JOIN user_location u
    ORDER BY u.geom <-> r.geom
    LIMIT 1
),

facility_nodes AS (
    SELECT DISTINCT
        fnp.facility_id,
        r.source AS network_node
    FROM public.facility_network_points_noded fnp
    JOIN public.roads_noded_routing_fixed r
        ON r.id = fnp.edge_id
)

SELECT
    hf.id AS facility_id,
    hf.name AS facility_name,
    ROUND(MAX(route.agg_cost)::numeric, 2) AS shortest_distance_m,
    ROUND((MAX(route.agg_cost) / 1000)::numeric, 3) AS shortest_distance_km
FROM pgr_dijkstra(
    'SELECT
        id,
        source,
        target,
        length_m AS cost,
        CASE
            WHEN LOWER(COALESCE(oneway, '''')) = ''yes''
                THEN -1
            ELSE length_m
        END AS reverse_cost
     FROM public.roads_noded_routing_fixed',

    (SELECT source FROM nearest_road),

    ARRAY(
        SELECT network_node
        FROM facility_nodes
    ),

    directed := true
) AS route

JOIN facility_nodes fn
    ON fn.network_node = route.end_vid

JOIN public.health_facilities hf
    ON hf.id = fn.facility_id

GROUP BY hf.id, hf.name
ORDER BY shortest_distance_m
LIMIT 10;