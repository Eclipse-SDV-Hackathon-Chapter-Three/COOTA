import json
import os
import paho.mqtt.client as mqtt
from influxdb_client import InfluxDBClient, Point
from influxdb_client.client.write_api import SYNCHRONOUS


# MQTT settings
MQTT_BROKER = os.getenv("MQTT_BROKER", "localhost")
MQTT_PORT = int(os.getenv("MQTT_PORT", "1883"))
MQTT_TOPIC = os.getenv("MQTT_TOPIC", "logger/#")

# INFLUX settings
INFLUXDB_URL = os.getenv("INFLUXDB_HOST", "http://localhost:8181")
INFLUXDB_BUCKET = os.getenv("INFLUXDB_DATABASE", "grafana")

# InfluxDB 3 settings
INFLUXDB_ORG = "my_org"

# Create global client references
mqtt_client = None

client = InfluxDBClient(url=INFLUXDB_URL, org=INFLUXDB_ORG)
write_api = client.write_api(write_options=SYNCHRONOUS)
query_api = client.query_api()

def on_connect(client, userdata, flags, rc):
    if rc == 0:
        print("MQTT connected")
        client.subscribe(MQTT_TOPIC)
    else:
        print(f"MQTT connection failed, rc = {rc}")

def on_message(client, userdata, msg):
    try:
        payload_text = msg.payload.decode("utf-8")
        data = json.loads(payload_text)
    except Exception as e:
        print("Failed to parse JSON:", e, msg.payload)
        return


    parts = msg.topic.split("/")
    
    if len(parts) >= 3:
        version = parts[1]
        vin = parts[2]
    else:
        print("Wrong topic structure")
        return

    
    # Build a Point
    p = Point("battery_usage") \
        .tag("vin", vin) \
        .tag("version", version)

    # Add all numeric fields as metrics
    for key, value in data.items():
        if isinstance(value, (int, float)):
            p = p.field(key, value)

    try:
        write_api.write(bucket=INFLUXDB_BUCKET, record=p)
        print(f"Wrote to InfluxDB: vin={vin}, version={version}")
    except Exception as e:
        print("Failed to write to InfluxDB:", e)

def run():
    global mqtt_client

    mqtt_client = mqtt.Client()
    mqtt_client.on_connect = on_connect
    mqtt_client.on_message = on_message

    mqtt_client.connect(MQTT_BROKER, MQTT_PORT, 60)
    mqtt_client.loop_forever()

if __name__ == "__main__":
    run()