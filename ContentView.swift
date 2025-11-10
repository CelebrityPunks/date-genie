import SwiftUI
import AuthenticationServices

struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var isSigningIn = false
    
    var body: some View {
        Group {
            if authManager.isSignedIn {
                // Signed-in view (placeholder for main app)
                SignedInView()
            } else {
                // Sign-in view
                SignInView(isSigningIn: $isSigningIn)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authManager.isSignedIn)
    }
}

struct SignInView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Binding var isSigningIn: Bool
    
    init(isSigningIn: Binding<Bool>) {
        _isSigningIn = isSigningIn
    }
    
    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                colors: [Color(red: 0.4, green: 0.5, blue: 0.92), Color(red: 0.46, green: 0.29, blue: 0.64)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // App Header
                VStack(spacing: 12) {
                    Text("DateGenie")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Eliminate date-planning anxiety")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Apple Sign-In Button
                SignInWithAppleButton(
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                        triggerHaptic()
                        isSigningIn = true
                    },
                    onCompletion: { result in
                        isSigningIn = false
                        triggerHaptic()
                        authManager.handleSignInResult(result)
                    }
                )
                .signInWithAppleButtonStyle(.white)
                .frame(height: 56)
                .padding(.horizontal, 40)
                .cornerRadius(12)
                .disabled(isSigningIn)
                .opacity(isSigningIn ? 0.6 : 1.0)
                
                if isSigningIn {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding(.top, 8)
                }
                
                Spacer()
                    .frame(height: 60)
            }
            .padding()
        }
    }
}

struct SignedInView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Welcome Header
                    VStack(spacing: 12) {
                        Text("Welcome to DateGenie!")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        if let userName = authManager.userName {
                            Text("Hello, \(userName)!")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Let's plan your perfect date")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 40)
                    
                    Spacer()
                    
                    // Placeholder for main app features
                    VStack(spacing: 16) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.pink)
                            .padding(.bottom, 8)
                        
                        Text("Coming Soon")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Search for date ideas, swipe through venues, and build your perfect date pack")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Sign Out Button
                    Button(action: {
                        triggerHaptic()
                        authManager.signOut()
                    }) {
                        Text("Sign Out")
                            .font(.headline)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationManager())
}

