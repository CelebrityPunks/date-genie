#!/bin/bash

# Test the search API endpoint
echo "Testing /api/search endpoint..."
echo ""

# Make the API request
response=$(curl -s -X POST http://localhost:3000/api/search \
  -H "Content-Type: application/json" \
  -d '{"city": "San Diego", "radius": 10, "budget": 80, "category": "restaurant"}')

# Check if jq is installed
if command -v jq &> /dev/null; then
    echo "$response" | jq .
else
    echo "jq not found, displaying raw JSON:"
    echo "$response" | python -m json.tool 2>/dev/null || echo "$response"
fi

echo ""
echo "---"
echo "Test complete!"

