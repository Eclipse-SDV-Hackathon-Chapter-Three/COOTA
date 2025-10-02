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

echo ""
echo "🚀 DEPLOYING SOLUTION TO BOTH FLEETS"
echo "===================================="

# Deploy to Fleet 1
echo "📦 Deploying to Fleet 1..."
cat > ./fleet1-instance.json << 'EOF'
{
    "metadata": {
        "name": "fleet-app-fleet1-instance"
    },
    "spec": {
        "solution": "fleet-app-v-1",
        "target": {
            "name": "fleet-1-target"
        }
    }
}
EOF

HTTP_CODE=$(curl -s -w "%{http_code}" -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" --data @./fleet1-instance.json "${SYMPHONY_API_URL}instances/fleet-app-fleet1-instance" -o response.json)

echo "Fleet 1 Instance - HTTP Code: $HTTP_CODE"
if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 201 ]; then
    echo "✅ Fleet 1 instance created successfully!"
elif [ "$HTTP_CODE" -eq 409 ]; then
    echo "⚠️  Fleet 1 instance already exists!"
else
    echo "❌ Fleet 1 instance failed!"
    cat response.json
fi

echo ""

# Deploy to Fleet 2
echo "📦 Deploying to Fleet 2..."
cat > ./fleet2-instance.json << 'EOF'
{
    "metadata": {
        "name": "fleet-app-fleet2-instance"
    },
    "spec": {
        "solution": "fleet-app-v-1",
        "target": {
            "name": "fleet-2-target"
        }
    }
}
EOF

HTTP_CODE=$(curl -s -w "%{http_code}" -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" --data @./fleet2-instance.json "${SYMPHONY_API_URL}instances/fleet-app-fleet2-instance" -o response.json)

echo "Fleet 2 Instance - HTTP Code: $HTTP_CODE"
if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 201 ]; then
    echo "✅ Fleet 2 instance created successfully!"
elif [ "$HTTP_CODE" -eq 409 ]; then
    echo "⚠️  Fleet 2 instance already exists!"
else
    echo "❌ Fleet 2 instance failed!"
    cat response.json
fi

echo ""
echo "⏳ Waiting 10 seconds for deployments..."
sleep 10

echo ""
echo "🔍 Checking deployment status..."
echo "Fleet 1 (vehicle-25555):"
docker exec vehicle-25555 ank get workloads | grep -E "(WORKLOAD|fleet-app)" || echo "  No fleet-app found"

echo ""
echo "Fleet 2 vehicles:"
for port in 25552 25553 25554; do
    echo "  Vehicle $port:"
    docker exec vehicle-$port ank get workloads | grep -E "(fleet-app)" || echo "    No fleet-app found"
done

# Clean up
rm -f ./fleet1-instance.json ./fleet2-instance.json response.json

echo ""
echo "=================================="
echo "✅ Deployment complete!"
echo ""
echo "💡 This should resolve the MQTT timeout by actually deploying workloads to Fleet 2"
