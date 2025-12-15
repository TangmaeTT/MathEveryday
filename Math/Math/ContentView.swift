//
//  ContentView.swift
//  Math
//
//  Created by admin on 9/10/2568 BE.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authVM: AuthViewModel

    var body: some View {
        Group {
            if authVM.isSignedIn {
                MainTabView(authVM: authVM)
            } else {
                SignInView()
            }
        }
        .background(Color("AccentColor").ignoresSafeArea())
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}

