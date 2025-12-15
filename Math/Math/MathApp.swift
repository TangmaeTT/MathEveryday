//
//  MathApp.swift
//  Math
//
//  Created by admin on 9/10/2568 BE.
//

import SwiftUI
import FirebaseCore

@main
struct MathApp: App {
    @StateObject private var authVM = AuthViewModel()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authVM)
                .tint(Color("AccentColor"))
                .background(Color("AccentColor").ignoresSafeArea())
        }
    }
}
