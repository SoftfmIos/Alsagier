import Foundation
import Combine
import EventKit

@MainActor
final class CalendarManager: ObservableObject {
    private let store = EKEventStore()
    @Published var blocks: [ScheduleBlock] = []
    @Published var status = "Not requested"

    func request() async {
        do {
            let granted: Bool
            if #available(iOS 17.0, *) {
                granted = try await store.requestFullAccessToEvents()
            } else {
                granted = try await store.requestAccess(to: .event)
            }
            status = granted ? "Allowed" : "Not allowed"
            if granted { loadToday() }
        } catch {
            status = "Calendar error"
        }
    }

    func loadToday() {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end = cal.date(byAdding: .day, value: 1, to: start)!
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        blocks = store.events(matching: predicate)
            .filter { !$0.isAllDay }
            .map {
                ScheduleBlock(
                    title: $0.title ?? "Calendar",
                    start: $0.startDate,
                    end: $0.endDate,
                    kind: .calendar,
                    color: .calendar,
                    isLocked: true
                )
            }
            .sorted { $0.start < $1.start }
    }
}
