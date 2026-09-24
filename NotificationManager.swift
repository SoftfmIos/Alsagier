import Foundation
import Combine
import UserNotifications

@MainActor
final class NotificationManager: ObservableObject {
    @Published var status = "Not requested"

    func request() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            status = granted ? "Allowed" : "Not allowed"
        } catch {
            status = "Notification error"
        }
    }

    func schedule(for blocks: [ScheduleBlock]) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        for block in blocks where block.start > Date().addingTimeInterval(10 * 60) {
            let content = UNMutableNotificationContent()
            content.title = "Alsagier"
            content.body = "\(block.title) starts in 10 minutes."
            content.sound = .default

            let fire = block.start.addingTimeInterval(-10 * 60)
            let components = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute], from: fire)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            center.add(UNNotificationRequest(identifier: block.id.uuidString, content: content, trigger: trigger))
        }
    }
}
