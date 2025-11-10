import SwiftUI
import PostHog

@main
struct DateGenieApp: App {
    init() {
        let config = PostHogConfig(
            apiKey: "phc_YOUR_API_KEY_HERE",
            host: "https://us.i.posthog.com"
        )
        PostHogSDK.shared.setup(config)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    PostHogSDK.shared.capture("app_opened")
                }
        }
    }
}
