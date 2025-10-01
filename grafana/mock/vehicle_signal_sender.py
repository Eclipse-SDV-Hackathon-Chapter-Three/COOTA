#!/usr/bin/env python3
from influxdb_client import InfluxDBClient, Point
from influxdb_client.client.write_api import SYNCHRONOUS
import psutil
import time
import os, time, random, threading, sys, termios, tty

HOST = os.getenv("INFLUX_HOST", "http://localhost:8181")
DB   = os.getenv("INFLUX_DB", "signals")
# VEHICLE_ID = "EV-001"
VEHICLE_ID = os.getenv("VEHICLE_ID", "EV-001")
# version = 1
VERSION = os.getenv("VERSION", "1")
bucket = "signals"

# Global state

running = True

print(f"\n[INFO] Software version {VERSION}")
def key_listener():
    """Listens for key presses to change version"""
    global VERSION, running
    fd = sys.stdin.fileno()
    old_settings = termios.tcgetattr(fd)
    try:
        tty.setcbreak(fd)
        while running:
            ch = sys.stdin.read(1)
            if ch == "q":
                running = False
            elif ch == "1":
                VERSION = 1
                print("\n[INFO] Software updated to VERSION 1")
            elif ch == "2":
                VERSION = 2
                print("\n[INFO] Software updated to VERSION 2")
            elif ch == "3":
                VERSION = 3
                print("\n[INFO] Software updated to VERSION 3")
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)

# Start keyboard listener in background
threading.Thread(target=key_listener, daemon=True).start()

# InfluxDB client
client = InfluxDBClient(url="http://localhost:8181", token="my-token", org="my-org")
write_api = client.write_api(write_options=SYNCHRONOUS)
query_api = client.query_api()


print(f"Simulating {VEHICLE_ID}. Press 1, 2, or 3 to change VERSION. Press q to quit.")

while running:
    if VERSION == 1:
        value = random.uniform(70, 120)
    elif VERSION == 2:
        value = random.uniform(120, 150)
    elif VERSION == 3:
        value = random.uniform(10, 69)  # always below 70
    else:
        value = random.uniform(50, 100)

    p = (
        Point("ev")
        .tag("vehicle_id", VEHICLE_ID)
        .tag("VERSION", f"v{VERSION}")
        .field("battery_consumption_per_hour", round(value, 2))
    )
    write_api.write(bucket=bucket, record=p)
    print(f"[v{VERSION}] wrote {value:.2f} kW")
    time.sleep(5)

print("Stopped.")