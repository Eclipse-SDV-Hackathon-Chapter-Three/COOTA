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

echo "🚀 MANUAL OTA DEPLOYMENT SIMULATION"
echo "===================================="

# Step 1: Deploy to Fleet 1 (Test Stage)
echo "📦 Step 1: Deploying to Fleet 1 (Test Stage)..."

cat > ./test-instance.json << 'EOF'
{
    "metadata": {
        "name": "fleet-app-test-instance"
    },
    "spec": {
        "solution": "fleet-app-v-1",
        "target": {
            "name": "fleet-1-target"
        }
    }
}
EOF

HTTP_CODE=$(curl -s -w "%{http_code}" -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" --data @./test-instance.json "${SYMPHONY_API_URL}instances/fleet-app-test-instance" -o response.json)

echo "Fleet 1 Deployment - HTTP Code: $HTTP_CODE"
if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 201 ]; then
    echo "✅ Fleet 1 deployment successful!"
elif [ "$HTTP_CODE" -eq 409 ]; then
    echo "⚠️  Fleet 1 deployment already exists!"
else
    echo "❌ Fleet 1 deployment failed!"
    cat response.json
fi

# Step 2: Wait (simulating campaign wait stage)
echo ""
echo "⏳ Step 2: Waiting 30 seconds (simulating campaign wait stage)..."
sleep 30

# Step 3: HTTP Validation
echo ""
echo "🔍 Step 3: HTTP Validation..."
VALIDATION_CODE=$(curl -s -w "%{http_code}" "https://jsonplaceholder.typicode.com/posts/1" -o validation_response.json)
echo "Validation HTTP Code: $VALIDATION_CODE"

if [ "$VALIDATION_CODE" -eq 200 ]; then
    echo "✅ Validation successful! Proceeding to production deployment..."
    
    # Step 4: Deploy to Fleet 2 (Production Stage)
    echo ""
    echo "📦 Step 4: Deploying to Fleet 2 (Production Stage)..."
    
    cat > ./prod-instance.json << 'EOF'
{
    "metadata": {
        "name": "fleet-app-prod-instance"
    },
    "spec": {
        "solution": "fleet-app-v-1",
        "target": {
            "name": "fleet-2-target"
        }
    }
}
EOF

    HTTP_CODE=$(curl -s -w "%{http_code}" -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" --data @./prod-instance.json "${SYMPHONY_API_URL}instances/fleet-app-prod-instance" -o response.json)
    
    echo "Fleet 2 Deployment - HTTP Code: $HTTP_CODE"
    if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 201 ]; then
        echo "✅ Fleet 2 deployment successful!"
        echo ""
        echo "🎉 OTA DEPLOYMENT COMPLETE!"
        echo "   - Fleet 1: ✅ Deployed"
        echo "   - Fleet 2: ✅ Deployed"
    elif [ "$HTTP_CODE" -eq 409 ]; then
        echo "⚠️  Fleet 2 deployment already exists!"
    else
        echo "❌ Fleet 2 deployment failed!"
        cat response.json
    fi
else
    echo "❌ Validation failed! Aborting production deployment."
fi

# Clean up
rm -f ./test-instance.json ./prod-instance.json response.json validation_response.json

echo ""
echo "📊 Check deployment status with: ./check_campaign_status.sh"
