#!/bin/bash

export SYMPHONY_API_URL=http://localhost:8082/v1alpha2/

TOKEN=$(curl -X POST -H "Content-Type: application/json" -d '{"username":"admin","password":""}' "${SYMPHONY_API_URL}users/auth" | jq -r '.accessToken')

# Fleet 1 target configuration
cat > ./fleet-1-target.json << 'EOF'
{
    "metadata": {
        "name": "fleet-1-target"
    },
    "spec": {
        "forceRedeploy": true,
        "components": [
            {
                "name": "fleet-1-app",   
                "type": "ankaios",             
                "properties": {
                    "ankaios.runtime": "podman",
                    "ankaios.restartPolicy": "ALWAYS",
                    "ankaios.runtimeConfig": "image: localhost:5000/payload-1:latest\ncommandOptions: [\"-e\", \"VIN=VIN25555\"]"                   
                }
            }
        ],
        "topologies": [
            {
                "bindings": [
                    {
                        "role": "ankaios",
                        "provider": "providers.target.mqtt",
                        "config": {
                            "name": "proxy",
                            "brokerAddress": "tcp://127.0.0.1:1883",
                            "clientID": "symphony",
                            "requestTopic": "coa-request",
                            "responseTopic": "coa-response",
                            "timeoutSeconds": "30"
                        }
                    }
                ]
            }
        ]
    }
}
EOF

curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" --data @./fleet-1-target.json "${SYMPHONY_API_URL}targets/registry/fleet-1-target"

# Prompt user to press Enter to continue after the target has been registered
read -p "Fleet 1 target registered. Press Enter to remove..."

curl -s -X DELETE -H "Authorization: Bearer $TOKEN" "${SYMPHONY_API_URL}targets/registry/fleet-1-target"

# Clean up
rm -f ./fleet-1-target.json
