```
# Fleet Health API

A simple API to check the health of a fleet based on CPU metrics in InfluxDB.

---

## Setup

1. Install dependencies:

pip install influxdb-client-3 flask

2. Optional environment variables (defaults are used if not set):

export INFLUXDB_HOST="http://localhost:8181"
export INFLUXDB_DATABASE="grafana"

3. Run the API:

python campaignManager.py

---

## Endpoint

GET /fleet/healthy

Checks if the CPU of a given version is within an acceptable threshold compared to other versions during a certain time window.

Query Parameters:

- currVersion (string, required) — Version to check
- threshold (float, required) — Maximum allowed % of current vs other versions
- time_window (float, optional, default 3600) — Time window in seconds

Responses:

- 200 OK — version metric is healthy
- 406 NOT_ACCEPTABLE — version metric exceeds threshold

Example:

GET /fleet/healthy?currVersion=1.2.0&threshold=120&time_window=3600

Response:

OK

or

NOT_ACCEPTABLE

---

Notes:

- Metric currently checked: cpu from measurement my_measurement
- Environment variables allow easy switching between local and production setups
- You can extend is_metric_relatively_ok to check other metrics
```
