#!/bin/bash

echo "🚀 DateGenie Full Stack Validation"
echo "=================================="

echo ""
echo "1. Testing backend health..."
if curl -s http://localhost:3000/api/search -X POST -H "Content-Type: application/json" -d '{"city":"NYC","query":"test","budget":100,"radius":10,"categories":["Food"],"userId":"test_123"}' > /dev/null; then
    echo "✅ Backend is responding"
else
    echo "❌ Backend not reachable. Run 'npm run dev' in backend folder."
    exit 1
fi

echo ""
echo "2. Validating API response..."
RESPONSE=$(curl -s http://localhost:3000/api/search -X POST -H "Content-Type: application/json" -d '{"city":"NYC","query":"date night","budget":100,"radius":10,"categories":["Food","Romantic"],"userId":"test_123"}')

if echo "$RESPONSE" | grep -q '"success":true'; then
    echo "✅ API returns correct format"
else
    echo "❌ API response invalid: $RESPONSE"
    exit 1
fi

VENUE_COUNT=$(echo "$RESPONSE" | grep -o '"id"' | wc -l)
if [ "$VENUE_COUNT" -gt 0 ]; then
    echo "✅ API returned $VENUE_COUNT venues"
else
    echo "❌ No venues returned"
    exit 1
fi

if echo "$RESPONSE" | grep -q '"dateabilityScore"'; then
    echo "✅ Dateability Score present"
else
    echo "❌ Missing Dateability Score"
    exit 1
fi

if echo "$RESPONSE" | grep -q '"aiPitch"'; then
    echo "✅ AI Pitch present"
else
    echo "❌ Missing AI Pitch"
    exit 1
fi

echo ""
echo "3. Testing Redis cache..."
FIRST=$(curl -s http://localhost:3000/api/search -X POST -H "Content-Type: application/json" -d '{"city":"NYC","query":"cache test","budget":50,"radius":5,"categories":["Fun"],"userId":"test_456"}' | grep -o '"source":"[^"]*"' | head -1)

SECOND=$(curl -s http://localhost:3000/api/search -X POST -H "Content-Type: application/json" -d '{"city":"NYC","query":"cache test","budget":50,"radius":5,"categories":["Fun"],"userId":"test_456"}' | grep -o '"source":"[^"]*"' | head -1)

if [ "$FIRST" = '"source":"api"' ] && [ "$SECOND" = '"source":"cache"' ]; then
    echo "✅ Redis caching works (first: api, second: cache)"
else
    echo "⚠️  Cache may not be working properly"
fi

echo ""
echo "4. Verifying PostHog configuration..."
if grep -q "phc_YOUR_API_KEY_HERE" DateGenie/Services/PostHogAnalytics.swift; then
    echo "⚠️  WARNING: PostHog API key not set. Get it from app.posthog.com"
else
    echo "✅ PostHog API key appears to be configured"
fi

echo ""
echo "=================================="
echo "✅ Stack validation complete!"
echo ""
echo "Next steps:"
echo "1. On a Mac, open date-genie-ios/Package.swift in Xcode"
echo "2. Build the project (Cmd+B)"
echo "3. Replace PostHog API key in PostHogAnalytics.swift"
echo "4. Run on simulator/device"
echo ""
echo "To publish to App Store:"
echo "- Set up Apple Developer account"
echo "- Configure signing in Xcode"
echo "- Archive and submit via App Store Connect"
