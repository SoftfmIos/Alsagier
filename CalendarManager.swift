import Foundation
import EventKit
import Combine

@MainActor
final class CalendarManager: ObservableObject {
    @Published var authorized = false
    @Published var todayBlocks: [ScheduleBlock] = []

    private let store = EKEventStore()

    func requestAccessAndLoad() async {
        do {
            authorized = try await store.requestFullAccessToEvents()
            if authorized { loadToday() }
        } catch {
            authorized = false
            todayBlocks = []
        }
    }

    func loadToday() {
        guard authorized else { return }
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        guard let end = cal.date(byAdding: .day, value: 1, to: start) else { return }
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        todayBlocks = store.events(matching: predicate)
            .filter { !$0.isAllDay }
            .map {
                ScheduleBlock(
                    title: $0.title ?? "Calendar",
                    start: $0.startDate,
                    end: $0.endDate,
                    kind: .calendar,
                    isLocked: true
                )
            }
            .sorted { $0.start < $1.start }
    }
}
