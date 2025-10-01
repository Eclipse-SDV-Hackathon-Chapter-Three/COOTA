# Multi-Vehicle Fleet Simulation

This setup creates a simulated fleet of 4 vehicles using Eclipse Symphony and Ankaios.

## Fleet Configuration

### Fleet 1 (1 vehicle)
- **Vehicle 1**: VIN25551, Agent: agent_A_25551
  - Ankaios: port 25551
  - Update Trigger: port 5500
  - Dashboard: port 5001

### Fleet 2 (3 vehicles)
- **Vehicle 2**: VIN25552, Agent: agent_A_25552
  - Ankaios: port 25552
  - Update Trigger: port 5502
  - Dashboard: port 5003

- **Vehicle 3**: VIN25553, Agent: agent_A_25553
  - Ankaios: port 25553
  - Update Trigger: port 5504
  - Dashboard: port 5005

- **Vehicle 4**: VIN25554, Agent: agent_A_25554
  - Ankaios: port 25554
  - Update Trigger: port 5506
  - Dashboard: port 5007

## Shared Services
- **Symphony API**: port 8082
- **Symphony Portal**: port 3000
- **MQTT Broker**: port 1883

## Usage

### Start the fleet
```bash
docker compose up -d
```

### Check vehicle status
```bash
# Check all containers
docker compose ps

# Check specific vehicle workloads
docker exec vehicle-25551 ank get workloads
docker exec vehicle-25552 ank get workloads
```

### Access vehicle dashboards
- Vehicle 1: http://localhost:5001
- Vehicle 2: http://localhost:5003
- Vehicle 3: http://localhost:5005
- Vehicle 4: http://localhost:5007

### Access update triggers
- Vehicle 1: http://localhost:5500
- Vehicle 2: http://localhost:5502
- Vehicle 3: http://localhost:5504
- Vehicle 4: http://localhost:5506

### Stop the fleet
```bash
docker compose down
```

## Vehicle Configuration

Each vehicle has its own configuration file in `configs/vehicle-XXXXX.json` containing:
- VIN (derived from port)
- FleetID (1 or 2)
- AgentName (unique per vehicle)
- Port mappings

The startup script dynamically generates Ankaios state.yaml files with vehicle-specific settings.
