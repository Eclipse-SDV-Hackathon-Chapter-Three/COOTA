#!/usr/bin/env python3
from influxdb_client import InfluxDBClient, Point
from influxdb_client.client.write_api import SYNCHRONOUS
import psutil
import time

bucket = "grafana"

client = InfluxDBClient(url="http://localhost:8181", token="my-token", org="my-org")

write_api = client.write_api(write_options=SYNCHRONOUS)
query_api = client.query_api()
while True:
    cpu = psutil.cpu_percent()
    print(cpu)
    p = Point("my_measurement").tag("version", "1").field("cpu", cpu)
    write_api.write(bucket=bucket, record=p)
    p = Point("my_measurement").tag("version", "2").field("cpu", 100.0)
    write_api.write(bucket=bucket, record=p)
    
    time.sleep(5)