#!/bin/bash

# Read vehicle configuration
VEHICLE_CONFIG="/config/vehicle.json"
if [ ! -f "$VEHICLE_CONFIG" ]; then
    echo "Error: Vehicle config file not found at $VEHICLE_CONFIG"
    exit 1
fi

# Extract configuration values
VIN=$(jq -r '.VIN' $VEHICLE_CONFIG)
FLEET_ID=$(jq -r '.FleetID' $VEHICLE_CONFIG)
AGENT_NAME=$(jq -r '.AgentName' $VEHICLE_CONFIG)
ANKAIOS_PORT=$(jq -r '.Ports.ankaios' $VEHICLE_CONFIG)
UPDATE_TRIGGER_PORT=$(jq -r '.Ports.update_trigger' $VEHICLE_CONFIG)
DASHBOARD_PORT=$(jq -r '.Ports.dashboard' $VEHICLE_CONFIG)

echo "Starting vehicle: VIN=$VIN, FleetID=$FLEET_ID, Agent=$AGENT_NAME"

# Create ankaios directory
mkdir -p /ankaios

# Configure Ankaios server port
sed -i "s/# address = '127.0.0.1:25551'/address = '127.0.0.1:$ANKAIOS_PORT'/g" /etc/ankaios/ank-server.conf

# Configure Ankaios agent to connect to the correct server port
sed -i "s/# server_url = 'https:\/\/127.0.0.1:25551'/server_url = 'http:\/\/127.0.0.1:$ANKAIOS_PORT'/g" /etc/ankaios/ank-agent.conf

# Update Ankaios agent configuration with unique name
sed -i "s/agent_A/$AGENT_NAME/g" /etc/ankaios/ank-agent.conf

# Configure podman to allow insecure registry access
echo 'unqualified-search-registries = ["docker.io"]' > /etc/containers/registries.conf
echo '' >> /etc/containers/registries.conf
echo '[[registry]]' >> /etc/containers/registries.conf
echo 'location = "localhost:5000"' >> /etc/containers/registries.conf
echo 'insecure = true' >> /etc/containers/registries.conf

# Create VIN file for containers to read
echo "$VIN" > /tmp/vehicle-vin

# Configure Ankaios CLI to use the correct server port
mkdir -p /root/.config/ankaios
cat > /root/.config/ankaios/ank.conf << EOF
version = 'v1'

[default]
server_url = 'http://127.0.0.1:$ANKAIOS_PORT'
insecure = true
EOF

# Create dynamic state.yaml with vehicle-specific configuration
cat > /ankaios/state.yaml << EOF
apiVersion: v0.1
workloads:
  symphony:
    runtime: podman
    agent: $AGENT_NAME
    restartPolicy: NEVER    
    tags:
      - key: owner
        value: Symphony
      - key: VIN
        value: $VIN
      - key: FleetID
        value: "$FLEET_ID"
    configs:
      symphony_config: symphony_config
    controlInterfaceAccess:
      allowRules:
        - type: StateRule
          operation: ReadWrite
          filterMask:
            - "*"
    files:
      - mountPoint: "/symphony-agent.json"
        data: "{{symphony_config}}"
    runtimeConfig: |
      image: ghcr.io/eclipse-symphony/symphony-api:0.48-proxy.41
      commandOptions: ["-e","CONFIG=/symphony-agent.json", "--net=host"]
configs:
  symphony_config: |
    {
      "siteInfo": {
        "siteId": "$VIN",
        "currentSite": {
          "baseUrl": "",
          "username": "",
          "password": ""
        }
      },
      "api": {
        "pubsub": {
          "shared": true,
          "provider": {
            "type": "providers.pubsub.memory",
            "config": {}
          }
        },
        "keylock": {
          "shared": true,
          "provider": {      
            "type": "providers.keylock.memory",
            "config": {
              "mode": "Global",
              "cleanInterval" : 30,
              "purgeDuration" : 43200
            }
          }
        },
        "vendors": [
          {
            "type": "vendors.echo",
            "route": "greetings",
            "managers": []
          },
          {
            "type": "vendors.solution",
            "loopInterval": 15,
            "route": "solution",
            "managers": [
              {
                "name": "solution-manager",
                "type": "managers.symphony.solution",
                "properties": {
                  "providers.persistentstate": "mem-state",                
                  "providers.config": "mock-config",  
                  "providers.secret": "mock-secret",
                  "providers.keylock": "mem-keylock",
                  "isTarget": "true",
                  "targetNames": "fleet-$FLEET_ID-target",
                  "vehicleVIN": "$VIN",
                  "poll.enabled": "true"              
                },
                "providers": {
                  "mem-state": {
                    "type": "providers.state.memory",
                    "config": {}
                  },     
                  "mem-keylock": {
                    "type": "providers.keylock.memory",
                    "config": {
                      "mode" : "Shared"
                    }
                  },         
                  "mock-config": {
                    "type": "providers.config.mock",
                    "config": {}
                  },
                  "mock-secret": {
                    "type": "providers.secret.mock",
                    "config": {}
                  },
                  "ankaios":{
                    "type": "providers.target.rust",
                    "config": {
                      "name": "ankaios-type",
                      "libFile": "/extensions/libankaios.so",
                      "libHash": "b2ba99ce5fd88db4e8a7766241fe8fb585d9d85facb6fd7b8b70321b1219926d"
                    }
                  }
                }
              }
            ]
          }
        ]
      },
      "bindings": [
        {
          "type": "bindings.mqtt",
          "config": {
            "brokerAddress": "tcp://127.0.0.1:1883",
            "clientID": "$VIN",
            "requestTopic": "coa-request",
            "responseTopic": "coa-response"
          }
        }
      ]
    }
EOF

# Start Ankaios server and agent
ank-server &
ank-agent &

# Wait for services to start
sleep 5

# Apply the vehicle-specific state
ank apply /ankaios/state.yaml

# Keep container running
wait
