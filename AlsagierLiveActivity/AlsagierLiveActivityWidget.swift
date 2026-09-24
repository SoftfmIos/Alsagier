import ActivityKit
import WidgetKit
import SwiftUI

struct AlsagierLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlsagierActivityAttributes.self) { context in
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(context.state.isUpcoming ? "ALSAGIER • NEXT" : "ALSAGIER • NOW")
                        .font(.caption.bold())
                    Spacer()
                    Text(timerInterval: Date()...context.state.end, countsDown: true)
                        .font(.caption.monospacedDigit())
                }
                Text(context.state.title)
                    .font(.headline)
                    .foregroundStyle(tint(context.state.colorName))
                if !context.state.subtitle.isEmpty {
                    Text(context.state.subtitle).font(.caption).lineLimit(1)
                }

                if !context.state.remaining.isEmpty {
                    Divider()
                    Text("REST OF TODAY").font(.caption2.bold()).foregroundStyle(.secondary)
                    ForEach(Array(context.state.remaining.prefix(5).enumerated()), id: \.offset) { _, item in
                        HStack(spacing: 6) {
                            Circle().fill(tint(item.colorName)).frame(width: 6, height: 6)
                            Text(item.time, style: .time).font(.caption2).frame(width: 52, alignment: .leading)
                            Text(item.title).font(.caption2).lineLimit(1)
                            Spacer(minLength: 0)
                        }
                    }
                    let hidden = max(0, context.state.remainingCount - min(5, context.state.remaining.count))
                    if hidden > 0 {
                        Text("+ \(hidden) more today").font(.caption2.bold()).foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .activityBackgroundTint(Color(.secondarySystemBackground))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.state.title).font(.headline).lineLimit(1)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: Date()...context.state.end, countsDown: true).monospacedDigit()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment:.leading, spacing:3) {
                        ForEach(Array(context.state.remaining.prefix(3).enumerated()), id:\.offset) { _, item in
                            Text("\(item.time.formatted(date:.omitted,time:.shortened))  \(item.title)")
                                .font(.caption2).lineLimit(1)
                        }
                        if context.state.remainingCount > 3 {
                            Text("+ \(context.state.remainingCount - 3) more").font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            } compactLeading: {
                Circle().fill(tint(context.state.colorName)).frame(width:10,height:10)
            } compactTrailing: {
                Text(timerInterval: Date()...context.state.end, countsDown:true).monospacedDigit()
            } minimal: {
                Circle().fill(tint(context.state.colorName))
            }
        }
    }

    private func tint(_ name:String) -> Color {
        switch name {
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "teal": return .teal
        case "indigo": return .indigo
        case "red": return .red
        case "cyan": return .cyan
        case "brown": return .brown
        case "gold": return Color(red:0.72,green:0.48,blue:0.02)
        case "gray": return .gray
        default: return .blue
        }
    }
}
