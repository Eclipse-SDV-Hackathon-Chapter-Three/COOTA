# MQTT → InfluxDB Bridge

This Python script subscribes to an MQTT broker, listens for JSON messages, and writes numeric fields into **InfluxDB**.  

- **Tags:** Extracted from the MQTT topic (`logger/<version>/<vin>`).  
- **Fields:** All numeric values from the JSON payload.  
- **Measurement:** `battery_usage` (configurable in the script).  

## 🔧 Requirements

- Python 3.8+
- paho-mqtt
- influxdb-client

Install dependencies:

`pip install paho-mqtt influxdb-client`

## ⚙️ Configuration

The script uses environment variables for flexibility:

Variable            | Default                  | Description
------------------- | ----------------------- | --------------------------------
MQTT_BROKER         | localhost               | MQTT broker host
MQTT_PORT           | 1883                    | MQTT broker port
MQTT_TOPIC          | logger/#                | MQTT subscription topic (wildcards supported)
INFLUXDB_HOST       | http://localhost:8181   | InfluxDB server URL
INFLUXDB_DATABASE   | grafana                 | InfluxDB bucket name
INFLUXDB_ORG        | my_org (hardcoded)      | InfluxDB organization name

Example (Linux/macOS):

```
export MQTT_BROKER=localhost
export MQTT_PORT=1883
export MQTT_TOPIC="logger/#"
export INFLUXDB_HOST=http://localhost:8086
export INFLUXDB_DATABASE=my_bucket
````

## ▶️ Running the Script

`python mqtt_to_influx.py`

## 📥 Example Flow

- **MQTT Topic:** 

`logger/v1/ABC123`

- **MQTT Message:** 
```json
{
  "battery_consumption_per_hour": 23.5,
  "temperature": 27.8
}
```

- **Result in InfluxDB:**  
  - Measurement: battery_usage  
  - Tags: vin=ABC123, version=v1  
  - Fields: battery_consumption_per_hour=23.5, temperature=27.8  

## Notes

- Topics must follow the structure: `<MQTT_TOPIC>/<version>/<vin>`
- If the payload contains no numeric fields, nothing will be written.
- The measurement name (battery_usage) is fixed in the script but can be changed.
