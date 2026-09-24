import ActivityKit
import Foundation

@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()

    func refresh(blocks:[ScheduleBlock]) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let now=Date()
        guard let current=blocks.first(where:{$0.start <= now && $0.end > now && !$0.isCompleted && !$0.isSkipped}) else {
            await end(); return
        }
        let next=blocks.first(where:{$0.start >= current.end && !$0.isCompleted && !$0.isSkipped})
        let state=AlsagierActivityAttributes.ContentState(
            title:current.title,subtitle:current.subtitle ?? "",end:current.end,
            next:next?.title ?? "Day complete",
            colorName:current.projectColor?.rawValue ?? (current.kind == .prayer ? "green":"blue"))
        let content=ActivityContent(state:state,staleDate:current.end)
        if let activity=Activity<AlsagierActivityAttributes>.activities.first {
            await activity.update(content)
        } else {
            let attributes=AlsagierActivityAttributes(dayID:Calendar.current.startOfDay(for:now).description)
            _ = try? Activity.request(attributes:attributes,content:content,pushType:nil)
        }
    }

    func end() async {
        for activity in Activity<AlsagierActivityAttributes>.activities {
            await activity.end(nil,dismissalPolicy:.immediate)
        }
    }
}
