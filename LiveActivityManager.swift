import ActivityKit
import Foundation

@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()

    func refresh(blocks: [ScheduleBlock], dayActive: Bool = true) async {
        guard dayActive else { await end(); return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let now = Date()
        let open = blocks.filter { !$0.isCompleted && !$0.isSkipped && $0.end > now }.sorted { $0.start < $1.start }
        guard !open.isEmpty else { await end(); return }

        let current = open.first { $0.start <= now && $0.end > now }
        let primary = current ?? open[0]
        let upcoming = open.filter { $0.id != primary.id && $0.start >= (current?.end ?? now) }

        // Keep the ActivityKit payload small and the Lock Screen readable.
        let visible = Array(upcoming.prefix(8)).map {
            AlsagierActivityAttributes.RemainingItem(
                title: $0.title,
                subtitle: $0.subtitle ?? "",
                time: $0.start,
                end: $0.end,
                colorName: colorName(for: $0),
                kindName: $0.kind.rawValue
            )
        }

        let state = AlsagierActivityAttributes.ContentState(
            blockID: primary.id.uuidString,
            title: primary.title,
            subtitle: primary.subtitle ?? "",
            start: primary.start,
            end: current == nil ? primary.start : primary.end,
            isUpcoming: current == nil,
            remaining: visible,
            remainingCount: upcoming.count,
            colorName: colorName(for: primary),
            kindName: primary.kind.rawValue,
            actionable: primary.kind != .prayer && !primary.isLocked
        )
        let content = ActivityContent(state: state, staleDate: state.end)

        if let activity = Activity<AlsagierActivityAttributes>.activities.first {
            await activity.update(content)
        } else {
            let attributes = AlsagierActivityAttributes(dayID: Calendar.current.startOfDay(for: now).description)
            _ = try? Activity.request(attributes: attributes, content: content, pushType: nil)
        }
    }

    func end() async {
        for activity in Activity<AlsagierActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    private func colorName(for block: ScheduleBlock) -> String {
        block.projectColor?.rawValue ?? (block.kind == .prayer ? "green" : block.kind.fallbackColorName)
    }
}

private extension BlockKind {
    var fallbackColorName: String {
        switch self {
        case .calendar, .travel: return "gray"
        case .prayer: return "green"
        case .habit: return "orange"
        case .project, .task: return "blue"
        case .calls: return "purple"
        case .email: return "teal"
        }
    }
}
