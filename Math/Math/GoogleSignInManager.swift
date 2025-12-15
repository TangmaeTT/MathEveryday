import Foundation
import FirebaseCore
import GoogleSignIn
import UIKit

final class GoogleSignInManager {
    func startSignIn(presenting viewController: UIViewController) async -> (idToken: String, accessToken: String)? {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return nil }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        return await withCheckedContinuation { continuation in
            GIDSignIn.sharedInstance.signIn(withPresenting: viewController) { result, error in
                if let user = result?.user,
                   let idToken = user.idToken?.tokenString {
                    let accessToken = user.accessToken.tokenString
                    continuation.resume(returning: (idToken, accessToken))
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
