#!/usr/bin/env python3
import os, time, random, json, argparse
import paho.mqtt.client as mqtt

# -------------------------------
# Args from CLI
# -------------------------------

#0-70;70-120;120-150
parser = argparse.ArgumentParser(description="EV simulator with software version control")
parser.add_argument("--vehicle", type=str, default=os.getenv("VEHICLE_ID", "VIN0001"), help="Vehicle ID (e.g. EV-001)")
parser.add_argument("--min_value", type=float, default=os.getenv("MIN_MEASURED_VALUE", "70"), help="Lower bound of the value")
parser.add_argument("--max_value", type=float, default=os.getenv("MAX_MEASURED_VALUE", "120"), help="Upper bound of the value")
parser.add_argument("--host", default=os.getenv("MQTT_HOST", "localhost"), help="MQTT hostname")
parser.add_argument("--port", type=int, default=os.getenv("MQTT_PORT", "1883"), help="MQTT port")
parser.add_argument("--app", default=os.getenv("APP", "logger"), help="Topic prefix")
parser.add_argument("--app_version", default=os.getenv("APP_VERSION", "v1"), help="Version of the App")
parser.add_argument("--interval", type=int, default=1, help="Write interval in seconds")
args = parser.parse_args()

VEHICLE_ID = args.vehicle
MIN_VALUE = args.min_value
MAX_VALUE = args.max_value
MQTT_HOST = args.host
MQTT_PORT = args.port
APP = args.app
APP_VERSION = args.app_version
INTERVAL = args.interval

# Global state
running = True

def on_connect(client, userdata, flags, rc):
    global connected
    if rc == 0:
        connected = True
        print("Connected to MQTT Broker!")
    else:
        print(f"Failed to connect, return code {rc}")

def on_disconnect(client, userdata, rc):
    global connected
    connected = False
    print("⚠️ Disconnected from broker, trying to reconnect...")

# Create MQTT client
client = mqtt.Client()
client.on_connect = on_connect
client.on_disconnect = on_disconnect

def connect_mqtt():
    """Try connecting until success"""
    while True:
        try:
            client.connect(MQTT_HOST, MQTT_PORT, 60)
            break
        except Exception as e:
            print(f"Connection failed: {e}, retrying in 5s...")
            time.sleep(5)


def publish_random_data():
    while running:
        value = round(random.uniform(MIN_VALUE, MAX_VALUE), 2)

        payload = {
            "battery_consumption_per_hour": value
        }
        result = client.publish(f"{APP}/{APP_VERSION}/{VEHICLE_ID}", json.dumps(payload), qos=1)  # QoS=1 for reliability
        status = result[0]
        if status == mqtt.MQTT_ERR_SUCCESS:
            print(f"Sent to topic {APP}/{APP_VERSION}/{VEHICLE_ID}")
        else:
            print(f"Failed to send message, status={status}")
        
        time.sleep(1)

if __name__ == "__main__":
    connect_mqtt()
    client.loop_start()  # Keeps the connection alive
    publish_random_data()