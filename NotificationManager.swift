import Foundation
import UserNotifications
@MainActor final class NotificationManager:ObservableObject {
 @Published var authorized=false
 func requestAuthorization() async {authorized=(try? await UNUserNotificationCenter.current().requestAuthorization(options:[.alert,.badge,.sound])) ?? false}
 func schedule(_ blocks:[ScheduleBlock]) async {let c=UNUserNotificationCenter.current();c.removeAllPendingNotificationRequests();for b in blocks where b.start>Date(){let x=UNMutableNotificationContent();x.title="Alsagier";x.body="\(b.title) starts soon.";x.sound=.default;let fire=max(Date().addingTimeInterval(1),b.start.addingTimeInterval(-600));let comps=Calendar.current.dateComponents([.year,.month,.day,.hour,.minute,.second],from:fire);try? await c.add(UNNotificationRequest(identifier:"alsagier.\(b.id)",content:x,trigger:UNCalendarNotificationTrigger(dateMatching:comps,repeats:false))) }}
}