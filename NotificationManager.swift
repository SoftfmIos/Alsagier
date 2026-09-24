import Foundation
import UserNotifications
import Combine

@MainActor
final class NotificationManager: ObservableObject {
    @Published var authorized = false
    private let center = UNUserNotificationCenter.current()

    func requestAuthorization() async {
        do {
            authorized = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            authorized = false
        }
    }

    func schedule(_ blocks: [ScheduleBlock]) async {
        center.removeAllPendingNotificationRequests()
        guard authorized else { return }

        for block in blocks where block.start > Date() {
            let reminder = block.start.addingTimeInterval(-10 * 60)
            guard reminder > Date() else { continue }

            let content = UNMutableNotificationContent()
            content.title = "Alsagier"
            content.body = "\(block.title) starts in 10 minutes."
            content.sound = .default

            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminder)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: "alsagier-\(block.id.uuidString)", content: content, trigger: trigger)
            try? await center.add(request)
        }
    }
}
