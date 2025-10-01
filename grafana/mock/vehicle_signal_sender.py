#!/usr/bin/env python3
from influxdb_client import InfluxDBClient, Point
from influxdb_client.client.write_api import SYNCHRONOUS
import psutil
import time
import os, time, random

# ---- Config (env overrides) ----
INFLUX_HOST = os.getenv("INFLUX_HOST", "http://localhost:8181")  # or http://influxdb3-core:8181 from another container
INFLUX_DB = os.getenv("INFLUX_DB", "signals")
VEHICLE_ID = os.getenv("VEHICLE_ID", "EV-001")
INTERVAL_S = int(os.getenv("INTERVAL_S", "4"))  # send every 5s
bucket = "signals"

# ---- Client (no token because you run --without-auth) ----
# client = InfluxDBClient(host=INFLUX_HOST, token="my-token", org="my-org", database=INFLUX_DB)
client = InfluxDBClient(url="http://localhost:8181", token="my-token", org="my-org", database=INFLUX_DB)
write_api = client.write_api(write_options=SYNCHRONOUS)
query_api = client.query_api()

# ---- Simple EV load model (kW): random walk with bounds ----
value = 12.0  # start around 12 kW
MIN_KW, MAX_KW = 2.0, 80.0

print(f"Sending battery_consumption_per_hour (kW) to database '{INFLUX_DB}' every {INTERVAL_S}s… Ctrl+C to stop.")
while True:
    # random walk + occasional spikes
    value += random.uniform(-1.5, 1.5)
    if random.random() < 0.05:
        value += random.uniform(5, 15)
    value = max(MIN_KW, min(MAX_KW, value))

    p = (
        Point("ev")  # measurement/table
        .tag("vehicle_id", VEHICLE_ID)
        .tag("unit", "kW")
        .field("battery_consumption_per_hour", float(round(value, 3)))
    )
    write_api.write(bucket=bucket, record=p)
    print(f"wrote {value:.2f} kW")
    time.sleep(INTERVAL_S)