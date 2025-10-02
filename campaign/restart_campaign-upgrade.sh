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

# Delete existing activation
echo "🗑️  Deleting existing activation..."
HTTP_CODE=$(curl -s -w "%{http_code}" -X DELETE -H "Authorization: Bearer $TOKEN" "${SYMPHONY_API_URL}activations/registry/payload-campaign-activation-1" -o delete_response.json)

if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 204 ]; then
    echo "✅ Existing activation deleted successfully"
elif [ "$HTTP_CODE" -eq 404 ]; then
    echo "ℹ️  No existing activation found (this is fine)"
else
    echo "⚠️  Warning: Could not delete existing activation (HTTP: $HTTP_CODE)"
    cat delete_response.json
fi

rm -f delete_response.json

# Wait a moment for cleanup
sleep 2

# Create new activation
echo ""
echo "🚀 Creating new activation..."

cat > ./activation.json << 'EOF'
{
    "metadata": {
        "name": "payload-campaign-activation-1"
    },
    "spec": {
        "campaign": "payload-campaign-1-v-1",
        "stage": "",
        "inputs": {}
    }
}
EOF

HTTP_CODE=$(curl -s -w "%{http_code}" -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" --data @./activation.json "${SYMPHONY_API_URL}activations/registry/payload-campaign-activation-1" -o response.json)

echo "HTTP Status Code: $HTTP_CODE"
RESPONSE=$(cat response.json)
echo "Response: $RESPONSE"

if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 201 ]; then
    echo "✅ Campaign restarted successfully!"
    echo ""
    echo "🚀 Self-driving campaign flow:"
    echo "  1. Deploy to Fleet 1 (test-stage)"
    echo "  2. Wait 30 seconds (wait-stage)"
    echo "  3. HTTP validation (validation-stage) -> jsonplaceholder.typicode.com"
    echo "  4. Deploy to Fleet 2 (production-stage)"
    echo ""
    echo "📊 Monitor progress with: ./check_campaign_status.sh"
else
    echo "❌ Failed to restart campaign. HTTP Code: $HTTP_CODE"
    echo "Response: $RESPONSE"
fi

# Clean up
rm -f ./activation.json response.json

echo "Done!"
