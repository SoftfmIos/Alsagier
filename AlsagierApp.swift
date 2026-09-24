import SwiftUI

@main
struct AlsagierApp: App {
    @StateObject private var store = AppStore()
    @StateObject private var calendar = CalendarManager()
    @StateObject private var notifications = NotificationManager()
    @StateObject private var prayers = PrayerManager()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(store)
                .environmentObject(calendar)
                .environmentObject(notifications)
                .environmentObject(prayers)
                .task {
                    await calendar.requestAccessAndLoad()
                    await notifications.requestAuthorization()
                }
        }
    }
}
