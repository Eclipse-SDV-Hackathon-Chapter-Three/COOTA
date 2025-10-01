SELECT
    time AS "time",
    cpu  AS "value"
FROM "my_measurement"
WHERE $__timeFilter(time)
ORDER BY time;