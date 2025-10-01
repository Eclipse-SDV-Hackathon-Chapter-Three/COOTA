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

echo "🚀 Advancing campaign to production stage..."

# Update activation to production stage
cat > ./advance.json << 'EOF'
{
    "metadata": {
        "name": "fleet-app-campaign-v-1-activation"
    },
    "spec": {
        "campaign": "fleet-app-campaign-v-1",
        "stage": "production-stage"
    }
}
EOF

HTTP_CODE=$(curl -s -w "%{http_code}" -X PUT -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" --data @./advance.json "${SYMPHONY_API_URL}activations/fleet-app-campaign-v-1-activation" -o response.json)

echo "HTTP Status Code: $HTTP_CODE"
RESPONSE=$(cat response.json)
echo "Response: $RESPONSE"

if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 201 ]; then
    echo "✅ Campaign advanced to production stage successfully!"
    echo ""
    echo "🚀 Production stage deployment initiated to fleet-2-target"
    echo "📊 Use './monitor_campaign.sh' to track progress"
else
    echo "❌ Failed to advance campaign. HTTP Code: $HTTP_CODE"
    echo "Response: $RESPONSE"
fi

# Clean up
rm -f ./advance.json response.json

echo "Done!"
