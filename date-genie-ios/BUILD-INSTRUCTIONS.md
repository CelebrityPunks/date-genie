# DateGenie iOS Build & Deployment Guide

## Prerequisites
- Mac with Xcode 15.0+
- Apple Developer Account ($99/year)
- iOS 16.0+ device or simulator

## Step 1: Prepare Backend
1. Ensure backend is running: `cd date-genie-backend && npm run dev`
2. Verify API: `node test-quick.js` should return venues
3. Get PostHog API key from app.posthog.com

## Step 2: Open Project on Mac
1. Copy `date-genie-ios` folder to Mac
2. Open `Package.swift` in Xcode
3. Xcode will resolve Kingfisher & PostHog dependencies automatically

## Step 3: Configure
1. Open `DateGenie/Services/PostHogAnalytics.swift`
2. Replace `phc_YOUR_API_KEY_HERE` with real key
3. Open `DateGenie/Info.plist`
4. Update `CFBundleIdentifier` if needed

## Step 4: Build & Test
1. Select target: iPhone 15 Pro Simulator
2. Press Cmd+R to build and run
3. You should see swipeable venue cards
4. Test swipes: check PostHog dashboard for events

## Step 5: Archive for App Store
1. Select "Any iOS Device" as target
2. Product → Archive
3. Distribute App → App Store Connect
4. Submit for review

## Notes
- Backend must be deployed before App Store release (use Vercel/Render)
- Update API base URL in APIService.swift for production
- Configure App Store privacy policy for PostHog analytics
