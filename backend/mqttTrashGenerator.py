#!/usr/bin/env python3
import paho.mqtt.client as mqtt
import random
import time
import json

# MQTT Broker settings
BROKER = "localhost"   # Public test broker
PORT = 1883
TOPIC = "logger/version/vin"     # Change this to your topic

# Connection flag
connected = False

def on_connect(client, userdata, flags, rc):
    global connected
    if rc == 0:
        connected = True
        print("✅ Connected to MQTT Broker!")
    else:
        print(f"❌ Failed to connect, return code {rc}")

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
            client.connect(BROKER, PORT, 60)
            break
        except Exception as e:
            print(f"🔄 Connection failed: {e}, retrying in 5s...")
            time.sleep(5)

def publish_random_data():
    """Publish random data safely"""
    while True:
        if connected:  # Only publish if connected
            payload = {
                "battery_consumption_per_hour": round(random.uniform(10.0, 30.0), 2)
            }
            message = json.dumps(payload)
            result = client.publish(TOPIC, message, qos=1)  # QoS=1 for reliability
            status = result[0]
            if status == mqtt.MQTT_ERR_SUCCESS:
                print(f"📤 Sent `{message}` to topic `{TOPIC}`")
            else:
                print(f"⚠️ Failed to send message, status={status}")
        else:
            print("⏳ Waiting for connection...")
        time.sleep(2)

if __name__ == "__main__":
    connect_mqtt()
    client.loop_start()  # Keeps the connection alive
    publish_random_data()