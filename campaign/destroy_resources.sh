#!/bin/bash

# Symphony API configuration
export SYMPHONY_API_URL=http://localhost:8082/v1alpha2/

echo "Authenticating with Symphony..."
TOKEN=$(curl -s -X POST -H "Content-Type: application/json" -d '{"username":"admin","password":""}' "${SYMPHONY_API_URL}users/auth" | jq -r '.accessToken')

if [ "$TOKEN" = "null" ] || [ -z "$TOKEN" ]; then
    echo "Authentication failed!"
    exit 1
fi

echo "Authentication successful. Token: ${TOKEN:0:20}..."

# Delete solution
echo "Deleting solution 'fleet-app-v-1'..."
HTTP_CODE=$(curl -s -w "%{http_code}" -X DELETE -H "Authorization: Bearer $TOKEN" "${SYMPHONY_API_URL}solutions/fleet-app-v-1" -o response.json)
RESPONSE=$(cat response.json)
echo "HTTP Code: $HTTP_CODE, Response: $RESPONSE"
rm -f response.json

# Delete campaign
echo "Deleting campaign 'fleet-app-campaign-v-1'..."
HTTP_CODE=$(curl -s -w "%{http_code}" -X DELETE -H "Authorization: Bearer $TOKEN" "${SYMPHONY_API_URL}campaigns/fleet-app-campaign-v-1" -o response.json)
RESPONSE=$(cat response.json)
echo "HTTP Code: $HTTP_CODE, Response: $RESPONSE"
rm -f response.json

# Delete targets
echo "Deleting fleet targets..."

echo "Deleting fleet-1-target..."
HTTP_CODE=$(curl -s -w "%{http_code}" -X DELETE -H "Authorization: Bearer $TOKEN" "${SYMPHONY_API_URL}targets/registry/fleet-1-target" -o response.json)
RESPONSE=$(cat response.json)
echo "HTTP Code: $HTTP_CODE, Response: $RESPONSE"
rm -f response.json

echo "Deleting fleet-2-target..."
HTTP_CODE=$(curl -s -w "%{http_code}" -X DELETE -H "Authorization: Bearer $TOKEN" "${SYMPHONY_API_URL}targets/registry/fleet-2-target" -o response.json)
RESPONSE=$(cat response.json)
echo "HTTP Code: $HTTP_CODE, Response: $RESPONSE"
rm -f response.json

# Optional: Delete original ankaios-target
read -p "Delete original ankaios-target as well? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Deleting ankaios-target..."
    HTTP_CODE=$(curl -s -w "%{http_code}" -X DELETE -H "Authorization: Bearer $TOKEN" "${SYMPHONY_API_URL}targets/registry/ankaios-target" -o response.json)
    RESPONSE=$(cat response.json)
    echo "HTTP Code: $HTTP_CODE, Response: $RESPONSE"
    rm -f response.json
fi

echo "✅ Resource cleanup completed!"
echo "Note: Vehicle containers are still running. Stop them with 'docker compose down' if needed."
