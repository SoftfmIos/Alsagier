import Foundation
import UserNotifications
import Combine

@MainActor
final class NotificationManager: ObservableObject {
    @Published var authorized = false
    private let center = UNUserNotificationCenter.current()

    func requestAuthorization() async {
        do { authorized = try await center.requestAuthorization(options: [.alert, .sound, .badge]) }
        catch { authorized = false }
    }

    func refresh(for blocks: [ScheduleBlock], minutesBefore: Int) async {
        center.removeAllPendingNotificationRequests()
        guard authorized, minutesBefore > 0 else { return }
        for block in blocks where block.start > Date() && !block.isCompleted && !block.isSkipped {
            let fire = block.start.addingTimeInterval(TimeInterval(-minutesBefore * 60))
            guard fire > Date() else { continue }
            let content = UNMutableNotificationContent()
            content.title = "Next in \(minutesBefore) minutes"
            content.body = block.subtitle.map {"\(block.title) — \($0)"} ?? block.title
            content.sound = block.kind == .prayer ? UNNotificationSound(named:UNNotificationSoundName("PrayerChime.wav")) : .default
            let parts = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute,.second], from: fire)
            let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
            try? await center.add(UNNotificationRequest(identifier:"alsagier.block.\(block.id.uuidString)",content:content,trigger:trigger))
        }
    }

    func scheduleWorkdayEnd(at date: Date) async {
        guard authorized, date > Date() else { return }
        let content=UNMutableNotificationContent()
        content.title="Workday complete"
        content.body="Alsagier has reached your configured work-end time."
        content.sound = .default
        let parts=Calendar.current.dateComponents([.year,.month,.day,.hour,.minute],from:date)
        try? await center.add(UNNotificationRequest(identifier:"alsagier.workday.end",
            content:content,trigger:UNCalendarNotificationTrigger(dateMatching:parts,repeats:false)))
    }
}
