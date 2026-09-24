import ActivityKit
import WidgetKit
import SwiftUI

struct AlsagierLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlsagierActivityAttributes.self) { context in
            VStack(alignment:.leading,spacing:5) {
                HStack {
                    Text(context.state.isUpcoming ? "ALSAGIER • NEXT" : "ALSAGIER • NOW")
                        .font(.caption2.bold())
                    Spacer()
                    Text(timerInterval: Date()...context.state.end, countsDown:true)
                        .font(.caption.monospacedDigit())
                }

                currentBrick(context.state)

                if !context.state.remaining.isEmpty {
                    Text("REST OF TODAY").font(.caption2.bold()).foregroundStyle(.secondary)
                    ForEach(Array(context.state.remaining.prefix(3).enumerated()), id:\.offset) { _, item in
                        remainingBrick(item)
                    }
                    let hidden = max(0, context.state.remainingCount - min(3, context.state.remaining.count))
                    if hidden > 0 {
                        Text("+ \(hidden) more today").font(.caption2.bold()).foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal,12)
            .padding(.vertical,10)
            .activityBackgroundTint(Color(.secondarySystemBackground))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.state.title)
                        .font(.headline)
                        .foregroundStyle(tint(context.state.colorName))
                        .lineLimit(2)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: Date()...context.state.end, countsDown:true)
                        .monospacedDigit()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment:.leading,spacing:3) {
                        ForEach(Array(context.state.remaining.prefix(3).enumerated()), id:\.offset) { _, item in
                            HStack(spacing:5) {
                                if item.kindName != "travel" {
                                    RoundedRectangle(cornerRadius:2)
                                        .fill(tint(item.colorName).opacity(0.75))
                                        .frame(width:5,height:14)
                                } else {
                                    Image(systemName:"car.fill").font(.caption2).foregroundStyle(.secondary)
                                }
                                Text(item.time,style:.time).font(.caption2)
                                Text(item.title).font(.caption2).lineLimit(1)
                                Spacer(minLength:0)
                            }
                        }
                        if context.state.remainingCount > 3 {
                            Text("+ \(context.state.remainingCount - 3) more")
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            } compactLeading: {
                RoundedRectangle(cornerRadius:3).fill(tint(context.state.colorName)).frame(width:11,height:11)
            } compactTrailing: {
                Text(timerInterval: Date()...context.state.end, countsDown:true).monospacedDigit()
            } minimal: {
                RoundedRectangle(cornerRadius:3).fill(tint(context.state.colorName))
            }
        }
    }

    @ViewBuilder
    private func currentBrick(_ state: AlsagierActivityAttributes.ContentState) -> some View {
        if state.kindName == "travel" {
            HStack(alignment:.top,spacing:7) {
                Image(systemName:"car.fill").font(.caption).foregroundStyle(.secondary)
                VStack(alignment:.leading,spacing:0) {
                    Text(state.title).font(.caption.bold()).foregroundStyle(.secondary).lineLimit(1)
                    Text("\(state.start.formatted(date:.omitted,time:.shortened)) – \(state.end.formatted(date:.omitted,time:.shortened))")
                        .font(.caption2).foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.vertical,3)
        } else {
            VStack(alignment:.leading,spacing:2) {
                Text(state.title)
                    .font(.headline)
                    .foregroundStyle(tint(state.colorName))
                    .lineLimit(2)
                    .fixedSize(horizontal:false,vertical:true)
                if !state.subtitle.isEmpty {
                    Text(state.subtitle).font(.caption2).lineLimit(1)
                }
                Text("\(state.start.formatted(date:.omitted,time:.shortened)) – \(state.end.formatted(date:.omitted,time:.shortened))")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            .frame(maxWidth:.infinity,alignment:.leading)
            .padding(.horizontal,9)
            .padding(.vertical,6)
            .background(tint(state.colorName).opacity(0.16),in:RoundedRectangle(cornerRadius:9))
        }
    }

    @ViewBuilder
    private func remainingBrick(_ item: AlsagierActivityAttributes.RemainingItem) -> some View {
        if item.kindName == "travel" {
            HStack(alignment:.top,spacing:6) {
                Image(systemName:"car.fill").font(.caption2).foregroundStyle(.secondary).frame(width:12)
                VStack(alignment:.leading,spacing:0) {
                    Text(item.title).font(.caption2.bold()).foregroundStyle(.secondary).lineLimit(1)
                    Text(item.time,style:.time).font(.caption2).foregroundStyle(.secondary)
                }
                Spacer(minLength:0)
            }
            .padding(.vertical,1)
        } else {
            HStack(spacing:6) {
                Text(item.time,style:.time).font(.caption2).frame(width:50,alignment:.leading)
                Text(item.title).font(.caption2.bold()).foregroundStyle(tint(item.colorName)).lineLimit(1)
                Spacer(minLength:0)
            }
            .padding(.horizontal,7)
            .padding(.vertical,4)
            .background(tint(item.colorName).opacity(0.16),in:RoundedRectangle(cornerRadius:6))
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
