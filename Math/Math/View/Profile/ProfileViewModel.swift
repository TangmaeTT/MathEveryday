import Foundation
import Combine
import UserNotifications

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published private(set) var user: AppUser?
    @Published var scheduledTime: Date = {
        var comp = DateComponents()
        comp.hour = 20
        comp.minute = 0
        return Calendar.current.date(from: comp) ?? Date()
    }()
    @Published var notificationAuthorized: Bool = false

    // NEW
    @Published var isUploading: Bool = false
    private let storage = StorageService()

    private let userRepo = FirestoreUserRepository()
    private let notification = NotificationManager()
    private let authVM: AuthViewModel

    init(authVM: AuthViewModel) {
        self.authVM = authVM
        self.user = nil
    }

    func load() {
        Task {
            await refreshUser()
            await refreshNotificationStatus()
        }
    }

    func refreshUser() async {
        guard let uid = authVM.currentUser?.id else { return }
        do {
            self.user = try await userRepo.get(uid: uid)
        } catch {
            print("Load user failed: \(error)")
        }
    }

    func refreshNotificationStatus() async {
        let settings = await notification.getSettings()
        let status = settings.authorizationStatus
        notificationAuthorized = (status == UNAuthorizationStatus.authorized || status == UNAuthorizationStatus.provisional)
    }

    func requestNotificationPermission() async {
        let granted = await notification.requestAuthorization()
        await refreshNotificationStatus()
        if !granted {
            // Optionally guide user to Settings
            print("Notification permission not granted.")
        }
    }

    func scheduleDailyNotification() async {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: scheduledTime)
        let hour = comps.hour ?? 20
        let minute = comps.minute ?? 0
        await notification.scheduleDaily(hour: hour, minute: minute)
    }

    func cancelNotifications() async {
        await notification.cancelAll()
    }

    func openSettings() {
        notification.openSettings()
    }

    // NEW: อัปโหลดรูปและอัปเดต Firestore
    func uploadProfileImage(_ data: Data) async {
        guard let uid = authVM.currentUser?.id else { return }
        isUploading = true
        defer { isUploading = false }
        do {
            // อัปโหลดไป Storage
            let url = try await storage.uploadProfileImage(uid: uid, data: data)
            // อัปเดต Firestore
            try await userRepo.updatePhotoURL(uid: uid, url: url)
            // รีเฟรช user
            await refreshUser()
        } catch {
            print("Upload profile image failed: \(error)")
        }
    }
}
