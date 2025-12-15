import Foundation
import SwiftUI
import Combine
import FirebaseAuth

@MainActor
final class AuthViewModel: ObservableObject {
    enum Provider {
        case google
        case guest
    }

    @Published private(set) var currentUser: AppUser? = nil
    var isSignedIn: Bool { currentUser != nil }

    // Services
    private let authService = FirebaseAuthService.shared
    private let googleManager = GoogleSignInManager()
    private let userRepo = FirestoreUserRepository()

    private var authHandle: AuthStateDidChangeListenerHandle?

    deinit {
        if let h = authHandle {
            // deinit is nonisolated; hop to the authService actor
            Task {
                await authService.removeAuthStateDidChangeListener(h)
            }
            authHandle = nil
        }
    }

    init() {
        // Observe auth state: hop to the authService actor to add the listener,
        // then store the handle back on the main actor.
        Task {
            let handle = await authService.addAuthStateDidChangeListener { [weak self] user in
                Task { await self?.handleAuthChange(user: user) }
            }
            await MainActor.run {
                self.authHandle = handle
            }
        }
    }

    private func handleAuthChange(user: FirebaseAuth.User?) async {
        if let u = user {
            do {
                let appUser = try await userRepo.createIfMissing(
                    uid: u.uid,
                    displayName: u.safeDisplayName,
                    photoURL: u.photoURL
                )
                self.currentUser = appUser
            } catch {
                print("Failed to create/fetch user: \(error)")
                self.currentUser = nil
            }
        } else {
            self.currentUser = nil
        }
    }

    func signIn(with provider: Provider) async {
        do {
            switch provider {
            case .google:
                // Need a presenting view controller
                guard let root = await topMostViewController() else { return }
                if let (idToken, accessToken) = await googleManager.startSignIn(presenting: root) {
                    _ = try await authService.signInWithGoogle(idToken: idToken, accessToken: accessToken)
                }
            case .guest:
                // Anonymous sign-in to keep flow simple
                let result = try await Auth.auth().signInAnonymously()
                _ = try await userRepo.createIfMissing(uid: result.user.uid, displayName: "Guest", photoURL: nil)
            }
        } catch {
            print("Sign-in error: \(error)")
        }
    }

    func signOut() {
        // Hop to the authService actor to perform sign out.
        Task {
            do {
                try await authService.signOut()
                await MainActor.run {
                    self.currentUser = nil
                }
            } catch {
                print("Sign-out error: \(error)")
            }
        }
    }

    // Helper to get top-most view controller for GoogleSignIn
    private func topMostViewController() async -> UIViewController? {
        await MainActor.run {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let root = scene.keyWindow?.rootViewController else { return nil }
            var top = root
            while let presented = top.presentedViewController {
                top = presented
            }
            return top
        }
    }
}

private extension User {
    // Avoid name collision with FirebaseAuth.User.displayName
    var safeDisplayName: String {
        if let name = self.displayName, !name.isEmpty { return name }
        if let email = self.email, !email.isEmpty { return email }
        return "User"
    }
}

private extension UIWindowScene {
    var keyWindow: UIWindow? {
        windows.first { $0.isKeyWindow }
    }
}
