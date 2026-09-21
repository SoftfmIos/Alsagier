import Foundation
import EventKit

@MainActor
final class CalendarManager: ObservableObject {
    @Published var events: [EKEvent] = []
    @Published var statusText = "Calendar not connected"
    @Published var isLoading = false

    private let store = EKEventStore()

    func requestAndLoadToday() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let granted: Bool
            if #available(iOS 17.0, *) {
                granted = try await store.requestFullAccessToEvents()
            } else {
                granted = try await withCheckedThrowingContinuation { continuation in
                    store.requestAccess(to: .event) { allowed, error in
                        if let error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume(returning: allowed)
                        }
                    }
                }
            }

            guard granted else {
                statusText = "Calendar access was not allowed"
                events = []
                return
            }

            loadToday()
        } catch {
            statusText = "Calendar error: \(error.localizedDescription)"
            events = []
        }
    }

    func loadToday() {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return }

        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        events = store.events(matching: predicate)
            .filter { !$0.isAllDay }
            .sorted { $0.startDate < $1.startDate }

        statusText = events.isEmpty
            ? "Connected — no timed events today"
            : "Connected — \(events.count) event\(events.count == 1 ? "" : "s") today"
    }
}
