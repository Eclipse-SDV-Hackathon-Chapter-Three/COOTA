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
echo "🚀 COMPLETE OTA DEPLOYMENT WORKFLOW"
echo "===================================="

# Step 1: Start campaign for orchestration
echo "📋 Step 1: Starting campaign orchestration..."
./restart_campaign.sh

# Step 2: Wait for campaign to reach test stage
echo ""
echo "⏳ Step 2: Waiting for campaign test stage..."
sleep 5

# Step 3: Deploy to Fleet 1 (Test Stage)
echo ""
echo "📦 Step 3: Deploying to Fleet 1 (Test Stage)..."

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

# Step 4: Wait for campaign validation stages
echo ""
echo "⏳ Step 4: Waiting for campaign validation (30s delay + HTTP check)..."
sleep 35

# Step 5: Check campaign status
echo ""
echo "🔍 Step 5: Checking campaign validation status..."
CAMPAIGN_STATUS=$(curl -s -H "Authorization: Bearer $TOKEN" "${SYMPHONY_API_URL}activations/registry/fleet-app-campaign-activation" | jq -r '.status.status')

if [ "$CAMPAIGN_STATUS" = "200" ] || [ "$CAMPAIGN_STATUS" = "9996" ]; then
    echo "✅ Campaign validation successful! Proceeding to production..."
    
    # Step 6: Deploy to Fleet 2 (Production Stage)
    echo ""
    echo "📦 Step 6: Deploying to Fleet 2 (Production Stage)..."
    
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
        echo "   - Campaign: ✅ Orchestrated validation flow"
        echo "   - Fleet 1: ✅ Deployed and validated"
        echo "   - Fleet 2: ✅ Deployed to production"
    elif [ "$HTTP_CODE" -eq 409 ]; then
        echo "⚠️  Fleet 2 deployment already exists!"
    else
        echo "❌ Fleet 2 deployment failed!"
        cat response.json
    fi
else
    echo "❌ Campaign validation failed! Status: $CAMPAIGN_STATUS"
    echo "Aborting production deployment for safety."
fi

# Step 7: Final status check
echo ""
echo "📊 Step 7: Final deployment status..."
./check_campaign_status.sh

# Clean up
rm -f ./test-instance.json ./prod-instance.json response.json

echo ""
echo "=================================="
echo "✅ OTA deployment workflow complete!"
echo ""
echo "🔍 WHAT HAPPENED:"
echo "1. Campaign orchestrated the validation flow (test → wait → validate → production)"
echo "2. Manual instance creation deployed actual workloads to vehicles"
echo "3. This simulates a real OTA system with safety gates and staged rollouts"
