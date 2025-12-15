import Foundation
import FirebaseAuth
import AuthenticationServices
import GoogleSignIn

actor FirebaseAuthService {
    nonisolated static let shared = FirebaseAuthService()

    private init() {}

    func currentUser() -> User? {
        Auth.auth().currentUser
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    // MARK: Google
    func signInWithGoogle(idToken: String, accessToken: String) async throws -> AuthDataResult {
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        return try await Auth.auth().signIn(with: credential)
    }

    // Observe auth changes (bridge to async)
    func addAuthStateDidChangeListener(_ block: @escaping (User?) -> Void) -> AuthStateDidChangeListenerHandle {
        Auth.auth().addStateDidChangeListener { _, user in
            block(user)
        }
    }

    func removeAuthStateDidChangeListener(_ handle: AuthStateDidChangeListenerHandle) {
        Auth.auth().removeStateDidChangeListener(handle)
    }
}
