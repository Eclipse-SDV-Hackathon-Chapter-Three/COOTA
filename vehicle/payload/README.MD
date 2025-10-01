# EV Simulator MQTT Publisher

This Python script simulates an Electric Vehicle (EV) sending telemetry data (e.g., battery consumption) to an MQTT broker. It supports **configurable vehicle ID, measurement range, MQTT broker settings, topic structure, app version, and publishing interval**.

---

## 🔧 Requirements

- Python 3.8+
- paho-mqtt

Install dependencies:

pip install paho-mqtt

---

## ⚙️ Configuration

The script accepts both **command-line arguments** and **environment variables**:

| Argument / Env Variable       | Default       | Description |
|-------------------------------|---------------|-------------|
| `--vehicle` / `VEHICLE_ID`    | VIN0001       | Vehicle ID (e.g., EV-001) |
| `--min_value` / `MIN_MEASURED_VALUE` | 70        | Lower bound of the simulated measurement |
| `--max_value` / `MAX_MEASURED_VALUE` | 120       | Upper bound of the simulated measurement |
| `--host` / `MQTT_HOST`        | localhost     | MQTT broker hostname |
| `--port` / `MQTT_PORT`        | 1883          | MQTT broker port |
| `--app` / `APP`               | logger        | Topic prefix |
| `--app_version` / `APP_VERSION` | v1          | Version of the App for the topic |
| `--interval`                  | 1             | Publish interval in seconds |

---

## ▶️ Running the Script

### Example using defaults:

python ev_simulator.py

### Example with custom arguments:

python ev_simulator.py --vehicle EV-123 --min_value 50 --max_value 100 --app telemetry --app_version v2 --interval 2

You can also set environment variables instead of using CLI arguments:

export VEHICLE_ID=EV-123  
export MIN_MEASURED_VALUE=50  
export MAX_MEASURED_VALUE=100  
export MQTT_HOST=localhost  
export MQTT_PORT=1883  
export APP=telemetry  
export APP_VERSION=v2  

python ev_simulator.py

---

## 📥 MQTT Topic Structure

The script publishes data to:

`<APP>/<APP_VERSION>/<VEHICLE_ID>`

**Example:** `logger/v1/VIN0001`


---

## ▶️ Build the Docker Image

`docker build -t ev-simulator .`

You can also pass build-time environment variables:

`docker build --build-arg VEHICLE_ID="EV-001" --build-arg APP_VERSION="v2" -t ev-simulator .`

---

## ▶️ Run the Container

docker run -d --name ev1 \
  -e VEHICLE_ID="EV-001" \
  -e APP="telemetry" \
  -e APP_VERSION="v2" \
  -e MIN_MEASURED_VALUE="50" \
  -e MAX_MEASURED_VALUE="100" \
  ev-simulator

- `-d` runs the container in the background.
- Environment variables override defaults inside the container.
- Each container publishes telemetry to the topic `<APP>/<APP_VERSION>/<VEHICLE_ID>`.

---

## 📊 Payload Example

```json
{
  "battery_consumption_per_hour": 85.72
}
```