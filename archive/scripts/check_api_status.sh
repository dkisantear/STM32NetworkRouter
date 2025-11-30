#!/bin/bash
# Quick script to check if API is responding and if quota limits are hit

API_URL="https://blue-desert-0c2a27e1e.3.azurestaticapps.net/api/gateway-status"

echo "=========================================="
echo "Checking API Status"
echo "=========================================="
echo ""
echo "Testing GET request..."
echo ""

# Test GET request
response=$(curl -s -w "\nHTTP_STATUS:%{http_code}" "$API_URL" 2>&1)
http_code=$(echo "$response" | grep "HTTP_STATUS" | cut -d: -f2)
body=$(echo "$response" | sed '/HTTP_STATUS/d')

echo "HTTP Status Code: $http_code"
echo ""
echo "Response Body:"
echo "$body"
echo ""

# Check for quota/rate limit errors
if [ "$http_code" = "429" ]; then
    echo "❌ QUOTA LIMIT HIT: Too Many Requests (429)"
    echo "   Azure is rate-limiting your API requests."
elif [ "$http_code" = "403" ]; then
    echo "❌ ACCESS DENIED: Forbidden (403)"
    echo "   This might indicate quota limits or access issues."
elif [ "$http_code" = "200" ]; then
    echo "✅ API is responding normally (200 OK)"
    echo "   Quota limits are likely fine!"
else
    echo "⚠️  Unexpected status code: $http_code"
    echo "   Check Azure Portal for quota usage."
fi

echo ""
echo "=========================================="
echo ""
echo "To check quota usage:"
echo "1. Go to Azure Portal"
echo "2. Find your Static Web App"
echo "3. Check 'Usage' or 'Quota' section"
echo ""

