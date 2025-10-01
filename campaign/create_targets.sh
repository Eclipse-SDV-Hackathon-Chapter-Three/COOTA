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

# Create Fleet 1 Target
echo "Creating Fleet 1 target..."

# Check if fleet-1-target.json exists
if [ ! -f "./fleet-1-target.json" ]; then
    echo "❌ Error: fleet-1-target.json file not found!"
    exit 1
fi

echo "Loading Fleet 1 target from fleet-1-target.json..."
HTTP_CODE=$(curl -s -w "%{http_code}" -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" --data @./fleet-1-target.json "${SYMPHONY_API_URL}targets/registry/fleet-1-target" -o response.json)
RESPONSE=$(cat response.json)
echo "Fleet 1 Target - HTTP Code: $HTTP_CODE"

if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 201 ]; then
    echo "✅ Fleet 1 target created successfully!"
elif [ "$HTTP_CODE" -eq 409 ]; then
    echo "⚠️  Fleet 1 target already exists!"
else
    echo "❌ Failed to create Fleet 1 target. Response: $RESPONSE"
fi

# Create Fleet 2 Target
echo "Creating Fleet 2 target..."

# Check if fleet-2-target.json exists
if [ ! -f "./fleet-2-target.json" ]; then
    echo "❌ Error: fleet-2-target.json file not found!"
    exit 1
fi

echo "Loading Fleet 2 target from fleet-2-target.json..."
HTTP_CODE=$(curl -s -w "%{http_code}" -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" --data @./fleet-2-target.json "${SYMPHONY_API_URL}targets/registry/fleet-2-target" -o response.json)
RESPONSE=$(cat response.json)
echo "Fleet 2 Target - HTTP Code: $HTTP_CODE"

if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 201 ]; then
    echo "✅ Fleet 2 target created successfully!"
elif [ "$HTTP_CODE" -eq 409 ]; then
    echo "⚠️  Fleet 2 target already exists!"
else
    echo "❌ Failed to create Fleet 2 target. Response: $RESPONSE"
fi

# Clean up
rm -f response.json

echo ""
echo "🎯 Target registration complete!"
echo "Targets are now available for deployments but no workloads have been deployed yet."
echo "Use create_instance.sh to deploy solutions to these targets."
