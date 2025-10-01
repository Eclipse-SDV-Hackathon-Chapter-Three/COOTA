#!/usr/bin/env python3
from influxdb_client_3 import InfluxDBClient3
from flask import Flask, Response, request
import os

host = os.getenv("INFLUXDB_HOST", "http://localhost:8181")
database = os.getenv("INFLUXDB_DATABASE", "grafana")

client = InfluxDBClient3(host=host, database=database)


app = Flask(__name__)

def is_metric_relatively_ok(metric, table, version, threshold, time_window):
    query = f"""
    WITH avg_versions AS (
    SELECT
        CASE WHEN version = $version THEN 'current' ELSE 'others' END AS ver_group,
        AVG({metric}) AS avg_value
    FROM {table}
    WHERE time >= now() - INTERVAL '{time_window} seconds'
    GROUP BY ver_group
    )
    SELECT
    (MAX(CASE WHEN ver_group = 'current' THEN avg_value END) /
    MAX(CASE WHEN ver_group = 'others' THEN avg_value END)) * 100 AS pct_curr_vs_others
    FROM avg_versions
    """

    response = client.query(query, query_parameters={
        "version": version
    })

    return response[0][0].as_py() < threshold
    

@app.route('/fleet/healthy', methods=['GET'])
def check_if_healthy():
    currVersion = request.args.get('currVersion')
    threshold = float(request.args.get('threshold'))

    time_window = request.args.get('time_window')
    if time_window is None:
        time_window = 60 * 60
    else:
        time_window = float(time_window)

    if not is_metric_relatively_ok("battery_consumption_per_hour", 'ev', currVersion, threshold, time_window):
        return Response("NOT_ACCEPTABLE", status=406)

    return Response("OK", status=200)

if __name__ == '__main__':
    app.run(host="0.0.0.0", debug=True)