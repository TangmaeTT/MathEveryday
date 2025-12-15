import SwiftUI

struct LeaderboardView: View {
    @ObservedObject var vm: LeaderboardViewModel

    var body: some View {
        NavigationStack {
            VStack {
                Picker("Mode", selection: $vm.mode) {
                    ForEach(LeaderboardViewModel.Mode.allCases) { m in
                        Text(m.rawValue).tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .tint(.white)

                List(vm.entries) { entry in
                    HStack {
                        Text("#\(entry.rank ?? 0)")
                            .frame(width: 36)
                            .foregroundStyle(.white.opacity(0.95))
                        VStack(alignment: .leading) {
                            Text(entry.displayName).foregroundStyle(.black)
                            Text("@\(entry.username)").font(.footnote).foregroundStyle(.white.opacity(0.9))
                        }
                        Spacer()
                        Text("\(entry.score)")
                            .bold()
                            .foregroundStyle(.black)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .background(Color("AccentColor").ignoresSafeArea())
            .navigationTitle("Leaderboard")
            .onAppear { vm.load() }
            .onChange(of: vm.mode) { _ in vm.load() }
        }
        .tint(Color("AccentColor"))
    }
}
