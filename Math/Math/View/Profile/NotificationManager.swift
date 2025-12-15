import Foundation
import UserNotifications
import UIKit

actor NotificationManager {
    func getSettings() async -> UNNotificationSettings {
        await withCheckedContinuation { cont in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                cont.resume(returning: settings)
            }
        }
    }

    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        } catch {
            return false
        }
    }

    func scheduleDaily(hour: Int, minute: Int) async {
        let content = UNMutableNotificationContent()
        content.title = "ถึงเวลาเล่นคณิตแล้ว!"
        content.body = "มาทำโจทย์ประจำวันเพื่อรักษา streak กันเถอะ"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_reminder", content: content, trigger: trigger)

        let center = UNUserNotificationCenter.current()
        await center.removePendingNotificationRequests(withIdentifiers: ["daily_reminder"])
        await center.addRequest(request)
    }

    func cancelAll() async {
        let center = UNUserNotificationCenter.current()
        await center.removeAllPendingNotificationRequests()
        await center.removeAllDeliveredNotifications()
    }

    nonisolated func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        DispatchQueue.main.async {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}

private extension UNUserNotificationCenter {
    func addRequest(_ request: UNNotificationRequest) async {
        await withCheckedContinuation { cont in
            self.add(request) { _ in
                cont.resume()
            }
        }
    }
    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) async {
        await withCheckedContinuation { cont in
            self.removePendingNotificationRequests(withIdentifiers: identifiers)
            cont.resume()
        }
    }
    func removeAllPendingNotificationRequests() async {
        await withCheckedContinuation { cont in
            self.removeAllPendingNotificationRequests()
            cont.resume()
        }
    }
    func removeAllDeliveredNotifications() async {
        await withCheckedContinuation { cont in
            self.removeAllDeliveredNotifications()
            cont.resume()
        }
    }
}
