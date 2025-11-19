import SwiftUI
import PostHog

@main
struct DateGenieApp: App {
    @StateObject private var authManager = AuthenticationManager()
    
    init() {
        let config = PostHogConfig(
            apiKey: "phc_YOUR_API_KEY_HERE",
            host: "https://us.i.posthog.com"
        )
        PostHogSDK.shared.setup(config)
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isSignedIn {
                    ContentView()
                        .onAppear {
                            PostHogSDK.shared.capture("app_opened")
                        }
                } else {
                    SignInView()
                }
            }
            .environmentObject(authManager)
        }
    }
}

// MARK: - Design System

enum DesignSystem {
    
    // MARK: - Colors
    struct Colors {
        static let canvas = Color(hex: "FDFBF7") // Warm Cream
        static let ink = Color(hex: "121212") // Deep Black
        
        static let genieBlue = Color(hex: "2E3A8C") // Navy
        static let magicGold = Color(hex: "FFD700") // Gold
        static let loveRed = Color(hex: "FF4040") // Poppy Red
        static let freshTeal = Color(hex: "00CED1") // Teal
        
        static let primaryGradient = LinearGradient(
            colors: [genieBlue, freshTeal],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let textPrimary = ink
        static let textSecondary = ink.opacity(0.7)
        static let textInverted = Color.white
    }
    
    // MARK: - Typography
    struct Typography {
        static func headerLarge() -> Font {
            .system(size: 36, weight: .black, design: .serif)
        }
        
        static func headerMedium() -> Font {
            .system(size: 24, weight: .bold, design: .serif)
        }
        
        static func body() -> Font {
            .system(size: 17, weight: .medium, design: .rounded)
        }
        
        static func caption() -> Font {
            .system(size: 14, weight: .bold, design: .rounded)
        }
    }
    
    // MARK: - Constants
    struct Layout {
        static let cornerRadius: CGFloat = 16
        static let borderWidth: CGFloat = 3
        static let shadowOffset: CGFloat = 4
    }
}

// MARK: - Extensions

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct PopStyleModifier: ViewModifier {
    let backgroundColor: Color
    
    func body(content: Content) -> some View {
        content
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                    .stroke(DesignSystem.Colors.ink, lineWidth: DesignSystem.Layout.borderWidth)
            )
            .cornerRadius(DesignSystem.Layout.cornerRadius)
            .shadow(color: DesignSystem.Colors.ink, radius: 0, x: DesignSystem.Layout.shadowOffset, y: DesignSystem.Layout.shadowOffset)
    }
}

extension View {
    func popStyle() -> some View {
        self.modifier(PopStyleModifier(backgroundColor: .white)) // Assuming .white as default if no color is passed
    }
    
    func mainBackground() -> some View {
        self.background(DesignSystem.Colors.canvas.ignoresSafeArea())
    }
}

struct DateGenieHeader: View {
    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            Text("Date")
                .font(DesignSystem.Typography.headerLarge())
                .foregroundColor(DesignSystem.Colors.ink)
            
            Image("DateGenieIcon")
                .resizable()
                .scaledToFit()
                .frame(height: 50)
                .shadow(color: DesignSystem.Colors.magicGold, radius: 0, x: 3, y: 3)
            
            Text("Genie")
                .font(DesignSystem.Typography.headerLarge())
                .foregroundColor(DesignSystem.Colors.ink)
        }
        .padding(.top, 10)
        .padding(.bottom, 10)
    }
}
