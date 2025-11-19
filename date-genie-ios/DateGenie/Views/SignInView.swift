import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.canvas
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Logo Area
                VStack(spacing: 12) {
                    DateGenieHeader()
                    
                    Text("Curated date packs,\nready in seconds.")
                        .font(DesignSystem.Typography.headerMedium())
                        .foregroundColor(DesignSystem.Colors.ink)
                        .multilineTextAlignment(.center)
                }
                
                // Features
                VStack(alignment: .leading, spacing: 20) {
                    featureRow(icon: "sparkles", text: "Multi-stop itineraries", color: DesignSystem.Colors.magicGold)
                    featureRow(icon: "archivebox.fill", text: "Tap to add venues", color: DesignSystem.Colors.loveRed)
                    featureRow(icon: "calendar.badge.clock", text: "Track bookings", color: DesignSystem.Colors.freshTeal)
                }
                .padding(24)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(DesignSystem.Colors.ink, lineWidth: 3)
                )
                .cornerRadius(16)
                .shadow(color: DesignSystem.Colors.ink, radius: 0, x: 6, y: 6)
                
                Spacer()
                
                // Buttons
                VStack(spacing: 16) {
                    SignInWithAppleButton(.signIn, onRequest: configure, onCompletion: authManager.handleSignInResult)
                        .signInWithAppleButtonStyle(.white)
                        .frame(height: 55)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(DesignSystem.Colors.ink, lineWidth: 3)
                        )
                        .shadow(color: DesignSystem.Colors.ink, radius: 0, x: 4, y: 4)
                    
                    Button {
                        // TODO: Integrate Google Sign-In
                    } label: {
                        HStack {
                            Image(systemName: "globe")
                            Text("Continue with Google (soon)")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 55)
                        .background(Color.white)
                        .foregroundColor(DesignSystem.Colors.ink.opacity(0.5))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(DesignSystem.Colors.ink.opacity(0.3), lineWidth: 3)
                        )
                    }
                    .disabled(true)
                    
                    Button {
                        withAnimation {
                            authManager.currentUser = User(id: "guest")
                            authManager.isSignedIn = true
                        }
                    } label: {
                        Text("Continue without signing in")
                            .font(.footnote.bold())
                            .foregroundColor(DesignSystem.Colors.genieBlue)
                            .padding()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                
                if let message = authManager.errorMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundColor(DesignSystem.Colors.loveRed)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding()
        }
        .onAppear { isAnimating = true }
    }
    
    private func featureRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(DesignSystem.Colors.ink)
                .frame(width: 40, height: 40)
                .background(color)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(DesignSystem.Colors.ink, lineWidth: 2)
                )
            
            Text(text)
                .font(DesignSystem.Typography.body())
                .foregroundColor(DesignSystem.Colors.ink)
        }
    }
    
    private func configure(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView()
            .environmentObject(AuthenticationManager())
    }
}
