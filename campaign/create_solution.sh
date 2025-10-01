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

# Create solution container
echo "Creating solution container..."

# Check if solution.json exists
if [ ! -f "./solution.json" ]; then
    echo "❌ Error: solution.json file not found!"
    echo "Please create solution.json file in the same directory."
    exit 1
fi

echo "Loading solution from solution.json..."

# Post solution to Symphony
echo "Posting solution to Symphony API..."
HTTP_CODE=$(curl -s -w "%{http_code}" -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" --data @./solution.json "${SYMPHONY_API_URL}solutions/fleet-app-v-1" -o response.json)

echo "HTTP Status Code: $HTTP_CODE"
RESPONSE=$(cat response.json)
echo "Response: $RESPONSE"

# Check if solution was created successfully
if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 201 ]; then
    echo "✅ Solution 'fleet-app-v-1' created successfully!"
elif [ "$HTTP_CODE" -eq 409 ]; then
    echo "⚠️  Solution 'fleet-app-v-1' already exists!"
else
    echo "❌ Failed to create solution. HTTP Code: $HTTP_CODE"
    echo "Response: $RESPONSE"
fi

# Clean up
rm -f response.json

echo "Done!"
