import ActivityKit
import WidgetKit
import SwiftUI

struct AlsagierLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlsagierActivityAttributes.self) { context in
            VStack(alignment:.leading, spacing:10) {
                HStack {
                    Text(context.state.isUpcoming ? "CAPJOUR • NEXT" : "CAPJOUR • NOW")
                        .font(.caption2.bold()).foregroundStyle(.white.opacity(0.72))
                    Spacer()
                    Text(context.state.isUpcoming ? context.state.start : context.state.end, style:.time)
                        .font(.subheadline.bold().monospacedDigit()).foregroundStyle(.white)
                }

                HStack(spacing:10) {
                    Image(systemName:icon(context.state.kindName))
                        .font(.title3.bold()).foregroundStyle(accent(context.state.colorName)).frame(width:26)
                    VStack(alignment:.leading,spacing:2) {
                        Text(context.state.title).font(.headline.bold()).foregroundStyle(.white).lineLimit(1)
                        if !context.state.subtitle.isEmpty {
                            Text(context.state.subtitle).font(.caption).foregroundStyle(.white.opacity(0.70)).lineLimit(1)
                        }
                        Text("\(context.state.start.formatted(date:.omitted,time:.shortened)) – \(context.state.end.formatted(date:.omitted,time:.shortened))")
                            .font(.caption2.monospacedDigit()).foregroundStyle(.white.opacity(0.65))
                    }
                    Spacer(minLength:0)
                }

                if let next=context.state.remaining.first {
                    Divider().overlay(.white.opacity(0.18))
                    HStack(spacing:9) {
                        Text("NEXT").font(.caption2.bold()).foregroundStyle(.white.opacity(0.58)).frame(width:34,alignment:.leading)
                        Text(next.time,style:.time).font(.caption.bold().monospacedDigit()).foregroundStyle(.white.opacity(0.75))
                        Image(systemName:icon(next.kindName)).font(.caption.bold()).foregroundStyle(accent(next.colorName))
                        Text(next.title).font(.caption.bold()).foregroundStyle(.white).lineLimit(1)
                        Spacer(minLength:0)
                    }
                }
            }
            .padding(.horizontal,14).padding(.vertical,12)
            .activityBackgroundTint(Color(red:0.035,green:0.075,blue:0.13))
            .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing:6) { Image(systemName:icon(context.state.kindName)).foregroundStyle(accent(context.state.colorName)); Text(context.state.title).font(.headline).lineLimit(1) }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.isUpcoming ? context.state.start : context.state.end,style:.time).monospacedDigit()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if let next=context.state.remaining.first {
                        HStack(spacing:6) { Text("Next").foregroundStyle(.secondary); Text(next.time,style:.time).monospacedDigit(); Image(systemName:icon(next.kindName)).foregroundStyle(accent(next.colorName)); Text(next.title).lineLimit(1); Spacer() }.font(.caption)
                    }
                }
            } compactLeading: {
                Image(systemName:icon(context.state.kindName)).foregroundStyle(accent(context.state.colorName))
            } compactTrailing: {
                Text(context.state.isUpcoming ? context.state.start : context.state.end,style:.time).monospacedDigit()
            } minimal: {
                Image(systemName:icon(context.state.kindName)).foregroundStyle(accent(context.state.colorName))
            }
        }
    }

    private func icon(_ kind:String)->String {
        switch kind { case "travel":return "car.fill"; case "prayer":return "moon.stars.fill"; case "habit":return "figure.walk"; case "calendar":return "calendar"; case "task":return "checkmark.circle.fill"; case "calls":return "phone.fill"; case "email":return "envelope.fill"; default:return "folder.fill" }
    }
    private func accent(_ name:String)->Color {
        switch name { case "green":return .green; case "orange":return .orange; case "purple":return .purple; case "pink":return .pink; case "teal":return .teal; case "indigo":return .indigo; case "red":return .red; case "cyan":return .cyan; case "brown":return .brown; case "gold":return Color(red:0.95,green:0.68,blue:0.18); case "gray":return .gray; default:return .cyan }
    }
}
