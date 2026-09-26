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
                .onOpenURL { url in
                    Task { await handleLiveAction(url) }
                }
        }
    }

    @MainActor private func handleLiveAction(_ url: URL) async {
        guard url.scheme == "alsagier",
              let parts = URLComponents(url:url,resolvingAgainstBaseURL:false),
              let action = parts.queryItems?.first(where:{$0.name=="action"})?.value,
              let raw = parts.queryItems?.first(where:{$0.name=="block"})?.value,
              let id = UUID(uuidString:raw),
              let block = store.todayPlan?.blocks.first(where:{$0.id==id}) else { return }
        calendar.loadToday(); await prayers.refresh()
        switch action {
        case "done": store.complete(block,calendar:calendar.todayBlocks,prayers:prayers.blocks)
        case "extend": store.extend15(block,calendar:calendar.todayBlocks,prayers:prayers.blocks)
        case "skip": store.skip(block,calendar:calendar.todayBlocks,prayers:prayers.blocks)
        default: return
        }
        await notifications.refresh(for:store.todayPlan?.blocks ?? [],minutesBefore:store.settings.reminderMinutes)
        await LiveActivityManager.shared.refresh(blocks:store.todayPlan?.blocks ?? [],dayActive:store.isDayActive)
    }
}
