import ActivityKit
import WidgetKit
import SwiftUI

struct AlsagierLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlsagierActivityAttributes.self) { context in
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Text(context.state.isUpcoming ? "CAPJOUR • NEXT" : "CAPJOUR • NOW")
                        .font(.caption2.bold()).foregroundStyle(.secondary)
                    Spacer()
                    if context.state.isUpcoming {
                        Text(context.state.start, style: .time).font(.headline.monospacedDigit())
                    } else {
                        Text("until ") + Text(context.state.end, style: .time)
                            .font(.headline.monospacedDigit())
                    }
                }

                HStack(alignment: .center, spacing: 11) {
                    Image(systemName: icon(context.state.kindName))
                        .font(.title3.bold()).foregroundStyle(tint(context.state.colorName))
                        .frame(width: 26)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(context.state.title).font(.title3.bold())
                            .foregroundStyle(tint(context.state.colorName)).lineLimit(1)
                        if !context.state.subtitle.isEmpty {
                            Text(context.state.subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                        }
                        Text("\(context.state.start.formatted(date: .omitted, time: .shortened)) – \(context.state.end.formatted(date: .omitted, time: .shortened))")
                            .font(.caption2.monospacedDigit()).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
                .padding(10)
                .background(tint(context.state.colorName).opacity(context.state.kindName == "travel" ? 0.05 : 0.12),
                            in: RoundedRectangle(cornerRadius: 12))

                if context.state.actionable && !context.state.isUpcoming {
                    HStack(spacing: 8) {
                        action("Done", "checkmark", type: "done", id: context.state.blockID)
                        action("+15", "clock.badge.plus", type: "extend", id: context.state.blockID)
                        action("Skip", "forward", type: "skip", id: context.state.blockID)
                    }
                }

                if !context.state.remaining.isEmpty {
                    HStack {
                        Text("UP NEXT").font(.caption2.bold()).foregroundStyle(.secondary)
                        Spacer()
                        Text("\(context.state.remainingCount) remaining").font(.caption2).foregroundStyle(.secondary)
                    }
                    ForEach(Array(context.state.remaining.prefix(1).enumerated()), id: \.offset) { _, item in
                        HStack(spacing: 8) {
                            Text(item.time, style: .time).font(.caption2.monospacedDigit())
                                .frame(width: 52, alignment: .leading)
                            Image(systemName: icon(item.kindName)).font(.caption2.bold())
                                .foregroundStyle(tint(item.colorName)).frame(width: 13)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(item.title).font(.caption.bold()).lineLimit(1)
                                if !item.subtitle.isEmpty {
                                    Text(item.subtitle).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                                }
                            }
                            Spacer(minLength: 0)
                        }
                    }
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
            .activityBackgroundTint(Color(.systemBackground))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: icon(context.state.kindName)).foregroundStyle(tint(context.state.colorName))
                        Text(context.state.title).font(.headline).lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.isUpcoming {
                        Text(context.state.start, style: .time).monospacedDigit()
                    } else {
                        Text(context.state.end, style: .time).monospacedDigit()
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 5) {
                        if !context.state.subtitle.isEmpty {
                            Text(context.state.subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                        }
                        ForEach(Array(context.state.remaining.prefix(1).enumerated()), id: \.offset) { _, item in
                            HStack(spacing: 6) {
                                Text(item.time, style: .time).font(.caption2.monospacedDigit())
                                Image(systemName: icon(item.kindName)).font(.caption2)
                                    .foregroundStyle(tint(item.colorName))
                                Text(item.title).font(.caption2).lineLimit(1)
                                Spacer()
                            }
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: icon(context.state.kindName)).foregroundStyle(tint(context.state.colorName))
            } compactTrailing: {
                if context.state.isUpcoming {
                    Text(context.state.start, style: .time).monospacedDigit()
                } else {
                    Text(context.state.end, style: .time).monospacedDigit()
                }
            } minimal: {
                Image(systemName: icon(context.state.kindName)).foregroundStyle(tint(context.state.colorName))
            }
        }
    }

    private func action(_ title: String, _ symbol: String, type: String, id: String) -> some View {
        Link(destination: URL(string: "alsagier://schedule?action=\(type)&block=\(id)")!) {
            Label(title, systemImage: symbol).font(.caption.bold()).frame(maxWidth: .infinity).padding(.vertical, 5)
                .background(Color.primary.opacity(0.08), in: Capsule())
        }.buttonStyle(.plain)
    }

    private func icon(_ kind: String) -> String {
        switch kind {
        case "travel": return "car.fill"
        case "prayer": return "moon.stars.fill"
        case "habit": return "figure.run"
        case "calendar": return "calendar"
        case "task": return "checkmark.circle"
        case "calls": return "phone.fill"
        case "email": return "envelope.fill"
        default: return "folder.fill"
        }
    }

    private func tint(_ name: String) -> Color {
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
        case "gold": return Color(red: 0.72, green: 0.48, blue: 0.02)
        case "gray": return .gray
        default: return .blue
        }
    }
}
