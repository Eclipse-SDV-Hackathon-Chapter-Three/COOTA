#!/bin/bash

# Symphony API configuration
export SYMPHONY_API_URL=http://localhost:8082/v1alpha2/

echo "Authenticating with Symphony..."
TOKEN=$(curl -s -X POST -H "Content-Type: application/json" -d '{"username":"admin","password":""}' "${SYMPHONY_API_URL}users/auth" | jq -r '.accessToken')

echo $TOKEN

if [ "$TOKEN" = "null" ] || [ -z "$TOKEN" ]; then
    echo "Authentication failed!"
    exit 1
fi

echo "Authentication successful."
echo "=================================="

# List Solutions
echo "📦 SOLUTIONS:"
SOLUTIONS=$(curl -s -H "Authorization: Bearer $TOKEN" "${SYMPHONY_API_URL}solutions" 2>/dev/null)
if [ "$?" -eq 0 ] && [ "$SOLUTIONS" != "null" ] && [ "$SOLUTIONS" != "[]" ]; then
    echo "$SOLUTIONS" | jq -r '.[] | "  - \(.metadata.name) (v\(.spec.version // "unknown"))"' 2>/dev/null || echo "  Error parsing solutions"
    
    echo ""
    echo "📦 SOLUTION DETAILS:"
    echo "$SOLUTIONS" | jq -r '.[] | "  🔧 \(.metadata.name):", "    Root Resource: \(.spec.rootResource // "unknown")", "    Version: \(.spec.version // "unknown")", "    Components: \(.spec.components | length) component(s)", "    Display Name: \(.spec.displayName // "N/A")"' 2>/dev/null || echo "  Error displaying solution details"
    
    # Show component details
    echo ""
    echo "🧩 SOLUTION COMPONENTS:"
    echo "$SOLUTIONS" | jq -r '.[] | .spec.components[]? | "  - \(.name) (Type: \(.type), Runtime: \(.properties."ankaios.runtime" // "unknown"))"' 2>/dev/null || echo "  No components found"
else
    echo "  No solutions found or error occurred"
fi

echo ""

# List Targets
echo "🎯 TARGETS:"
curl -s -H "Authorization: Bearer $TOKEN" "${SYMPHONY_API_URL}targets/registry" | jq -r '.[] | "  - \(.metadata.name)"' 2>/dev/null || echo "  No targets found or error occurred"

echo ""

# List Instances (deployments)
echo "🚀 INSTANCES (Active Deployments):"
curl -s -H "Authorization: Bearer $TOKEN" "${SYMPHONY_API_URL}instances" | jq -r '.[] | "  - \(.metadata.name) -> \(.spec.target.name)"' 2>/dev/null || echo "  No instances found or error occurred"

echo ""

# List Campaigns
echo "📋 CAMPAIGNS:"
CAMPAIGNS=$(curl -s -H "Authorization: Bearer $TOKEN" "${SYMPHONY_API_URL}campaigns" 2>/dev/null)
if [ "$?" -eq 0 ] && [ "$CAMPAIGNS" != "null" ] && [ "$CAMPAIGNS" != "[]" ]; then
    echo "$CAMPAIGNS" | jq -r '.[] | "  - \(.metadata.name)"' 2>/dev/null || echo "  Error parsing campaigns"
    
    echo ""
    echo "📋 CAMPAIGN DETAILS:"
    echo "$CAMPAIGNS" | jq '.' 2>/dev/null || echo "  Error displaying campaign JSON"
else
    echo "  No campaigns found or error occurred"
fi

echo ""

# List Activations
echo "⚡ CAMPAIGN ACTIVATIONS:"
ACTIVATIONS=$(curl -s -H "Authorization: Bearer $TOKEN" "${SYMPHONY_API_URL}activations/registry" 2>/dev/null)
if [ "$?" -eq 0 ] && [ "$ACTIVATIONS" != "null" ] && [ "$ACTIVATIONS" != "[]" ]; then
    echo "$ACTIVATIONS" | jq -r '.[] | "  - \(.metadata.name) (Campaign: \(.spec.campaign // "unknown"), Status: \(.status.status // "unknown"))"' 2>/dev/null || echo "  Error parsing activations"
    
    echo ""
    echo "📊 DETAILED ACTIVATION STATUS:"
    # Get detailed status for each activation
    echo "$ACTIVATIONS" | jq -r '.[].metadata.name' 2>/dev/null | while read activation_name; do
        if [ ! -z "$activation_name" ]; then
            echo "  🔍 $activation_name:"
            STAGE_STATUS=$(curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
                --data "{\"campaign\": \"fleet-app-campaign-v-1\", \"activation\": \"$activation_name\"}" \
                "${SYMPHONY_API_URL}stage/activations" 2>/dev/null)
            
            if [ "$?" -eq 0 ] && [ "$STAGE_STATUS" != "null" ]; then
                echo "$STAGE_STATUS" | jq -r '    "    Current Stage: \(.currentStage // "unknown")"' 2>/dev/null || echo "    Status: Available"
                echo "$STAGE_STATUS" | jq -r '    "    Progress: \(.progress // "unknown")"' 2>/dev/null || true
                echo "$STAGE_STATUS" | jq -r '    "    Last Update: \(.lastUpdate // "unknown")"' 2>/dev/null || true
            else
                echo "    Status: No detailed status available"
            fi
        fi
    done
else
    echo "  No activations found or error occurred"
fi

echo ""
echo "=================================="
echo "✅ Resource listing complete!"
