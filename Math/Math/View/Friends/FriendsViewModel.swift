import Foundation
import Combine

@MainActor
final class FriendsViewModel: ObservableObject {
    @Published private(set) var friends: [AppUser] = []
    @Published var searchText: String = ""
    @Published var searchResult: AppUser? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let repo = FirestoreFriendRepository()
    private let authVM: AuthViewModel

    init(authVM: AuthViewModel) {
        self.authVM = authVM
    }

    func refresh() {
        Task { await loadFriends() }
    }

    func loadFriends() async {
        guard let uid = authVM.currentUser?.id else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            friends = try await repo.listFriends(selfId: uid)
        } catch {
            errorMessage = "โหลดรายชื่อเพื่อนไม่สำเร็จ: \(error.localizedDescription)"
        }
    }

    func search() async {
        let term = searchText.trimmingCharacters(in: .whitespaces)
        guard !term.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await repo.search(username: term)
            searchResult = result
            errorMessage = result == nil ? "ไม่พบผู้ใช้ชื่อ \(term)" : nil
        } catch {
            errorMessage = "ค้นหาไม่สำเร็จ: \(error.localizedDescription)"
        }
    }

    func addFriend(_ user: AppUser) async {
        guard let uid = authVM.currentUser?.id else { return }
        do {
            try await repo.addFriend(selfId: uid, friendId: user.id)
            await loadFriends()
        } catch {
            errorMessage = "เพิ่มเพื่อนไม่สำเร็จ: \(error.localizedDescription)"
        }
    }

    func removeFriend(_ user: AppUser) async {
        guard let uid = authVM.currentUser?.id else { return }
        do {
            try await repo.removeFriend(selfId: uid, friendId: user.id)
            await loadFriends()
        } catch {
            errorMessage = "ลบเพื่อนไม่สำเร็จ: \(error.localizedDescription)"
        }
    }
}
