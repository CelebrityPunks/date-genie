import Foundation
import AuthenticationServices
import Combine

@MainActor
class AuthenticationManager: NSObject, ObservableObject {
    @Published var isSignedIn = false
    @Published var userIdentifier: String?
    @Published var userEmail: String?
    @Published var userName: String?
    @Published var currentUser: User?
    @Published var errorMessage: String?
    
    override init() {
        super.init()
        checkSignInStatus()
    }
    
    func handleSignInResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                // Store user identifier
                userIdentifier = appleIDCredential.user
                
                // Store email and name if provided (only on first sign-in)
                if let email = appleIDCredential.email {
                    userEmail = email
                }
                
                var fullNameString: String?
                if let fullName = appleIDCredential.fullName {
                    let formatter = PersonNameComponentsFormatter()
                    fullNameString = formatter.string(from: fullName)
                    userName = fullNameString
                }
                
                // Create User model
                let user = User(
                    id: appleIDCredential.user,
                    email: appleIDCredential.email,
                    name: fullNameString
                )
                currentUser = user
                
                // Save user data
                saveUserData(user)
                
                // Save credential state
                UserDefaults.standard.set(appleIDCredential.user, forKey: "appleIDCredential")
                
                isSignedIn = true
                errorMessage = nil
                
                // Track analytics event
                trackSignUpEvent(provider: "apple")
            }
            
        case .failure(let error):
            errorMessage = error.localizedDescription
            print("Apple Sign-In failed: \(error.localizedDescription)")
        }
    }
    
    private func saveUserData(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: "currentUser")
        }
    }
    
    private func loadUserData() -> User? {
        guard let data = UserDefaults.standard.data(forKey: "currentUser"),
              let user = try? JSONDecoder().decode(User.self, from: data) else {
            return nil
        }
        return user
    }
    
    func checkSignInStatus() {
        // Check if user is already signed in
        if let userID = UserDefaults.standard.string(forKey: "appleIDCredential") {
            userIdentifier = userID
            
            // Load user data if available
            if let user = loadUserData() {
                currentUser = user
                userEmail = user.email
                userName = user.name
            }
            
            // Verify credential status
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            appleIDProvider.getCredentialState(forUserID: userID) { [weak self] credentialState, error in
                DispatchQueue.main.async {
                    switch credentialState {
                    case .authorized:
                        self?.isSignedIn = true
                    case .revoked, .notFound:
                        self?.isSignedIn = false
                        self?.currentUser = nil
                        UserDefaults.standard.removeObject(forKey: "appleIDCredential")
                        UserDefaults.standard.removeObject(forKey: "currentUser")
                    default:
                        break
                    }
                }
            }
        }
    }
    
    func signOut() {
        isSignedIn = false
        userIdentifier = nil
        userEmail = nil
        userName = nil
        currentUser = nil
        UserDefaults.standard.removeObject(forKey: "appleIDCredential")
        UserDefaults.standard.removeObject(forKey: "currentUser")
    }
    
    // Analytics tracking (to be integrated with PostHog)
    private func trackSignUpEvent(provider: String) {
        // TODO: Integrate with PostHog SDK
        // PostHog.shared.capture("user_signed_up", properties: ["auth_provider": provider])
        print("📊 Analytics: user_signed_up with provider: \(provider)")
    }
}

