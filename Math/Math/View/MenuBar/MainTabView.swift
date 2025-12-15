import SwiftUI

struct MainTabView: View {
    enum Tab {
        case play, friends, leaderboard, profile
    }

    @State private var selection: Tab = .play

    // เก็บอ้างอิง AuthViewModel จากภายนอก เพื่อให้สร้าง VM อื่นๆ ได้ครั้งเดียว
    private let authVM: AuthViewModel

    // เก็บ ViewModel เป็น @StateObject เพื่อไม่ให้รีเซ็ตเมื่อ View ถูกสร้างใหม่
    @StateObject private var gameVM: GameViewModel
    @StateObject private var friendsVM: FriendsViewModel
    @StateObject private var leaderboardVM: LeaderboardViewModel
    @StateObject private var profileVM: ProfileViewModel

    // Initializer รับ AuthViewModel แล้วสร้าง VM ทั้งหมดครั้งเดียว
    init(authVM: AuthViewModel) {
        self.authVM = authVM
        _gameVM = StateObject(wrappedValue: GameViewModel(authVM: authVM))
        _friendsVM = StateObject(wrappedValue: FriendsViewModel(authVM: authVM))
        _leaderboardVM = StateObject(wrappedValue: LeaderboardViewModel(authVM: authVM))
        _profileVM = StateObject(wrappedValue: ProfileViewModel(authVM: authVM))
    }

    var body: some View {
        ZStack {
            Color("AccentColor").ignoresSafeArea()

            TabView(selection: $selection) {
                PlayView(vm: gameVM)
                    .tabItem { Label("Play", systemImage: "gamecontroller") }
                    .tag(Tab.play)

                FriendsView(vm: friendsVM)
                    .tabItem { Label("Friends", systemImage: "person.2") }
                    .tag(Tab.friends)

                LeaderboardView(vm: leaderboardVM)
                    .tabItem { Label("Leaders", systemImage: "trophy") }
                    .tag(Tab.leaderboard)

                ProfileView(vm: profileVM)
                    .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                    .tag(Tab.profile)
            }
            .tint(Color("AccentColor"))
        }
    }
}

