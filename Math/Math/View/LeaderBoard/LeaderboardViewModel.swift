import Foundation
import Combine

@MainActor
final class LeaderboardViewModel: ObservableObject {
    enum Mode: String, CaseIterable, Identifiable {
        case global = "Global"
        case friends = "Friends"
        var id: String { rawValue }
    }

    @Published var mode: Mode = .global
    @Published private(set) var entries: [LeaderboardEntry] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let repo = FirestoreLeaderboardRepository()
    private let authVM: AuthViewModel

    init(authVM: AuthViewModel) {
        self.authVM = authVM
    }

    func load() {
        Task { await reload() }
    }

    func reload() async {
        isLoading = true
        defer { isLoading = false }
        do {
            switch mode {
            case .global:
                entries = try await repo.globalTop()
            case .friends:
                guard let uid = authVM.currentUser?.id else { entries = []; return }
                entries = try await repo.friendsTop(selfId: uid)
            }
            errorMessage = nil
        } catch {
            entries = []
            errorMessage = "โหลดตารางผู้นำไม่สำเร็จ: \(error.localizedDescription)"
        }
    }
}
