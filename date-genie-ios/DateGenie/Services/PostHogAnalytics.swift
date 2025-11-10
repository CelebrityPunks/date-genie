import Foundation
import PostHog

// Manifesto Rule #9: Analytics wrapper
class PostHogAnalytics {
    static let shared = PostHogAnalytics()
    
    private init() {
        let config = PostHogConfig(
            apiKey: "phc_YOUR_API_KEY_HERE",
            host: "https://us.i.posthog.com"
        )
        PostHogSDK.shared.setup(config)
    }
    
    func capture(_ event: String, properties: [String: Any] = [:]) {
        PostHogSDK.shared.capture(event, properties: properties)
    }
    
    func identify(userId: String) {
        PostHogSDK.shared.identify(userId)
    }
}
