import SwiftUI

struct FriendsView: View {
    @ObservedObject var vm: FriendsViewModel

    var body: some View {
        NavigationStack {
            List {
                Section("ค้นหาเพื่อนด้วย Username") {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.white.opacity(0.9))
                        TextField("username", text: $vm.searchText)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .textFieldStyle(.roundedBorder)
                        Button {
                            Task { await vm.search() }
                        } label: {
                            Text("ค้นหา")
                        }
                        .buttonStyle(.bordered)
                        .tint(.white)
                    }
                    if let result = vm.searchResult {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(result.displayName)
                                    .fontWeight(.semibold)
                                Text("@\(result.username)")
                                    .font(.footnote)
                                    .foregroundStyle(.white.opacity(0.9))
                            }
                            Spacer()
                            Button {
                                Task { await vm.addFriend(result) }
                            } label: {
                                Label("เพิ่มเพื่อน", systemImage: "person.badge.plus")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.white)
                        }
                        .padding(.vertical, 4)
                    }
                    if let msg = vm.errorMessage {
                        Text(msg).foregroundStyle(.white.opacity(0.9))
                    }
                }

                Section("เพื่อนของฉัน") {
                    ForEach(vm.friends, id: \.id) { friend in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(friend.displayName)
                                    .fontWeight(.semibold)
                                Text("@\(friend.username)")
                                    .font(.footnote)
                                    .foregroundStyle(.white.opacity(0.9))
                            }
                            Spacer()
                            Button(role: .destructive) {
                                Task { await vm.removeFriend(friend) }
                            } label: {
                                Label("ลบ", systemImage: "trash")
                            }
                            .buttonStyle(.bordered)
                            .tint(.white)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color("AccentColor").ignoresSafeArea())
            .navigationTitle("Friends")
            .refreshable {
                await vm.loadFriends()
            }
            .onAppear {
                vm.refresh()
            }
        }
        .tint(Color("AccentColor"))
    }
}
