#!/bin/bash

# Symphony API configuration
export SYMPHONY_API_URL=http://localhost:8082/v1alpha2/

echo "Authenticating with Symphony..."
TOKEN=$(curl -s -X POST -H "Content-Type: application/json" -d '{"username":"admin","password":""}' "${SYMPHONY_API_URL}users/auth" | jq -r '.accessToken')

if [ "$TOKEN" = "null" ] || [ -z "$TOKEN" ]; then
    echo "Authentication failed!"
    exit 1
fi

echo "📊 Campaign Status Monitor"
echo "=========================="

# Get campaign activation status
echo "🔍 Checking activation status..."
HTTP_CODE=$(curl -s -w "%{http_code}" -H "Authorization: Bearer $TOKEN" "${SYMPHONY_API_URL}activations/fleet-app-campaign-v-1-activation" -o response.json)

if [ "$HTTP_CODE" -eq 200 ]; then
    ACTIVATION_STATUS=$(cat response.json | jq -r '.status.stage // "unknown"')
    echo "📋 Current Stage: $ACTIVATION_STATUS"
else
    echo "⚠️  No activation found or error occurred"
fi

echo ""

# Check instances (deployments)
echo "🚀 Active Deployments:"
curl -s -H "Authorization: Bearer $TOKEN" "${SYMPHONY_API_URL}instances" | jq -r '.[] | "  - \(.metadata.name) -> \(.spec.target.name) (\(.status.provisioningStatus.status // "unknown"))"' 2>/dev/null || echo "  No instances found"

echo ""

# Check vehicle workloads
echo "🚗 Vehicle Status:"
echo "Fleet 1 (VIN25555):"
docker exec vehicle-25555 ank get workloads 2>/dev/null | grep -E "(WORKLOAD NAME|fleet-)" || echo "  No fleet workloads found"

echo ""
echo "Fleet 2 (VIN25552, VIN25553, VIN25554):"
for port in 25552 25553 25554; do
    echo "  Vehicle $port:"
    docker exec vehicle-$port ank get workloads 2>/dev/null | grep -E "fleet-" || echo "    No fleet workloads found"
done

echo ""
echo "🔄 Run this script again to refresh status"
echo "✋ Use './advance_campaign.sh' to manually advance to next stage"

# Clean up
rm -f response.json
