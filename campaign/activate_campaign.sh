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

# Activate campaign
echo "Creating activation to execute campaign..."

# Create activation object using the registry endpoint (like targets)
cat > ./activation.json << 'EOF'
{
    "metadata": {
        "name": "fleet-app-campaign-activation"
    },
    "spec": {
        "campaign": "fleet-app-campaign-v-1",
        "stage": "",
        "inputs": {}
    }
}
EOF

HTTP_CODE=$(curl -s -w "%{http_code}" -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" --data @./activation.json "${SYMPHONY_API_URL}activations/registry/fleet-app-campaign-activation" -o response.json)

echo "HTTP Status Code: $HTTP_CODE"
RESPONSE=$(cat response.json)
echo "Response: $RESPONSE"

if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 201 ]; then
    echo "✅ Campaign activation created successfully!"
    echo ""
    echo "🚀 Self-driving campaign should start automatically"
    echo "📊 Use './monitor_campaign.sh' to track progress"
    echo ""
    echo "Expected flow:"
    echo "  1. Deploy to Fleet 1 (test-stage)"
    echo "  2. Wait 30 seconds (wait-stage)"
    echo "  3. HTTP validation (validation-stage)"
    echo "  4. Deploy to Fleet 2 (production-stage)"
elif [ "$HTTP_CODE" -eq 409 ]; then
    echo "⚠️  Campaign activation already exists!"
    echo "📊 Use './monitor_campaign.sh' to check status"
else
    echo "❌ Failed to create campaign activation. HTTP Code: $HTTP_CODE"
    echo "Response: $RESPONSE"
fi

# Clean up
rm -f ./activation.json response.json

echo "Done!"
