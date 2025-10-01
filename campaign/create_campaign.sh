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

# Delete existing campaign if it exists
echo "Checking for existing campaign..."
HTTP_CODE=$(curl -s -w "%{http_code}" -X DELETE -H "Authorization: Bearer $TOKEN" "${SYMPHONY_API_URL}campaigns/fleet-app-campaign-v-1" -o delete_response.json)

if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 204 ]; then
    echo "✅ Existing campaign deleted successfully"
elif [ "$HTTP_CODE" -eq 404 ]; then
    echo "ℹ️  No existing campaign found (this is fine)"
else
    echo "⚠️  Warning: Could not delete existing campaign (HTTP: $HTTP_CODE)"
fi

rm -f delete_response.json

# Create staged deployment campaign
echo "Creating staged deployment campaign..."

# Check if campaign.json exists
if [ ! -f "./campaign.json" ]; then
    echo "❌ Error: campaign.json file not found!"
    echo "Please create campaign.json file in the same directory."
    exit 1
fi

echo "Loading campaign from campaign.json..."

# Post campaign to Symphony
echo "Posting campaign to Symphony API..."
HTTP_CODE=$(curl -s -w "%{http_code}" -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" --data @./campaign.json "${SYMPHONY_API_URL}campaigns/fleet-app-campaign-v-1" -o response.json)

echo "HTTP Status Code: $HTTP_CODE"
RESPONSE=$(cat response.json)
echo "Response: $RESPONSE"

# Check if campaign was created successfully
if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 201 ]; then
    echo "✅ Campaign 'fleet-app-campaign-v-1' created successfully!"
    echo ""
    echo "📋 Campaign Stages:"
    echo "  1. Test Stage: Deploy to fleet-1-target (1 vehicle)"
    echo "  2. Production Stage: Deploy to fleet-2-target (3 vehicles)"
    echo ""
    echo "🚀 To execute the campaign, use the Symphony Portal or create an activation script."
elif [ "$HTTP_CODE" -eq 409 ]; then
    echo "⚠️  Campaign 'fleet-app-campaign-v-1' already exists!"
else
    echo "❌ Failed to create campaign. HTTP Code: $HTTP_CODE"
    echo "Response: $RESPONSE"
fi

# Clean up
rm -f response.json

echo "Done!"
