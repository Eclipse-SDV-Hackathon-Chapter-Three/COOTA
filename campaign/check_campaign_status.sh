#!/bin/bash

# Symphony API configuration
export SYMPHONY_API_URL=http://localhost:8082/v1alpha2/

echo "Authenticating with Symphony..."
TOKEN=$(curl -s -X POST -H "Content-Type: application/json" -d '{"username":"admin","password":""}' "${SYMPHONY_API_URL}users/auth" | jq -r '.accessToken')

if [ "$TOKEN" = "null" ] || [ -z "$TOKEN" ]; then
    echo "Authentication failed!"
    exit 1
fi

echo "🔍 DETAILED CAMPAIGN STATUS CHECK"
echo "=================================="

# 1. Check activation details
echo "📋 ACTIVATION DETAILS:"
curl -s -H "Authorization: Bearer $TOKEN" "${SYMPHONY_API_URL}activations/registry/payload-campaign-activation" | jq '.' 2>/dev/null || echo "Failed to get activation details"

echo ""
curl -s -H "Authorization: Bearer $TOKEN" "${SYMPHONY_API_URL}activations/registry/payload-campaign-activation-1" | jq '.' 2>/dev/null || echo "Failed to get activation details"
echo ""

# 2. Check campaign status
echo "🚀 CAMPAIGN STATUS:"
curl -s -H "Authorization: Bearer $TOKEN" "${SYMPHONY_API_URL}campaigns/payload-campaign-v-1" | jq '.status // "No status available"' 2>/dev/null || echo "Failed to get campaign status"

echo ""

curl -s -H "Authorization: Bearer $TOKEN" "${SYMPHONY_API_URL}campaigns/payload-campaign-1-v-1" | jq '.status // "No status available"' 2>/dev/null || echo "Failed to get campaign status"

echo ""

# 3. Check instances (actual deployments)
echo "📦 DEPLOYMENT INSTANCES:"
INSTANCES=$(curl -s -H "Authorization: Bearer $TOKEN" "${SYMPHONY_API_URL}instances" 2>/dev/null)
if [ "$?" -eq 0 ] && [ "$INSTANCES" != "null" ] && [ "$INSTANCES" != "[]" ]; then
    echo "$INSTANCES" | jq -r '.[] | "  - \(.metadata.name) -> \(.spec.target.name) (Status: \(.status.provisioningStatus.status // "unknown"))"' 2>/dev/null || echo "  Error parsing instances"
else
    echo "  No deployment instances found"
fi

echo ""

# 4. Check vehicle workloads
echo "🚗 VEHICLE WORKLOAD STATUS:"
echo "Fleet 1 (vehicle-25555):"
if docker exec vehicle-25555 ank get workloads 2>/dev/null | grep -q "payload"; then
    docker exec vehicle-25555 ank get workloads 2>/dev/null | grep -A 5 -B 5 "payload"
    echo ""
    echo "Fleet 1 Logs:"
    docker exec vehicle-25555 ank logs payload 2>/dev/null | tail -10 || echo "  No logs available"
else
    echo "  No fleet-app workload found in Fleet 1"
fi

echo ""
echo "Fleet 2 (vehicles 25552, 25553, 25554):"
for port in 25552 25553 25554; do
    echo "  Vehicle $port:"
    if docker exec vehicle-$port ank get workloads 2>/dev/null | grep -q "payload"; then
        echo "    ✅ fleet-app workload found"
        docker exec vehicle-$port ank logs payload 2>/dev/null | tail -5 || echo "    No logs available"
    else
        echo "    ❌ No fleet-app workload found"
    fi
done

echo ""


echo ""
echo "=================================="
echo "✅ Status check complete!"
echo ""
echo "💡 TROUBLESHOOTING TIPS:"
echo "- Check Symphony container logs: docker logs symphony-api"
