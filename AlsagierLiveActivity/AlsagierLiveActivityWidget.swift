import ActivityKit
import WidgetKit
import SwiftUI

struct AlsagierLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlsagierActivityAttributes.self) { context in
            VStack(alignment:.leading,spacing:7) {
                HStack {
                    Text(context.state.isUpcoming ? "CAPJOUR • NEXT" : "CAPJOUR • NOW").font(.caption2.bold())
                    Spacer()
                    if !context.state.isUpcoming {
                        Text(timerInterval: Date()...context.state.end, countsDown:true).font(.caption.bold().monospacedDigit())
                    } else { Text(context.state.start,style:.time).font(.caption.bold()) }
                }

                HStack(alignment:.top,spacing:9) {
                    Image(systemName:icon(context.state.kindName)).foregroundStyle(tint(context.state.colorName)).frame(width:18)
                    VStack(alignment:.leading,spacing:2) {
                        Text(context.state.title).font(.headline).foregroundStyle(tint(context.state.colorName)).lineLimit(1)
                        if !context.state.subtitle.isEmpty { Text(context.state.subtitle).font(.caption).lineLimit(1) }
                        Text("\(context.state.start.formatted(date:.omitted,time:.shortened)) – \(context.state.end.formatted(date:.omitted,time:.shortened))")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(8).background(tint(context.state.colorName).opacity(context.state.kindName == "travel" ? 0.06 : 0.14),in:RoundedRectangle(cornerRadius:10))

                if context.state.actionable {
                    HStack(spacing:8) {
                        action("Done","checkmark",type:"done",id:context.state.blockID)
                        action("+15","clock.badge.plus",type:"extend",id:context.state.blockID)
                        action("Skip","forward",type:"skip",id:context.state.blockID)
                    }
                }

                if !context.state.remaining.isEmpty {
                    HStack { Text("REST OF TODAY").font(.caption2.bold()).foregroundStyle(.secondary); Spacer(); Text("\(context.state.remainingCount) remaining").font(.caption2).foregroundStyle(.secondary) }
                    ForEach(Array(context.state.remaining.prefix(4).enumerated()), id:\.offset) { _, item in
                        HStack(spacing:7) {
                            Text(item.time,style:.time).font(.caption2.monospacedDigit()).frame(width:50,alignment:.leading)
                            Circle().fill(tint(item.colorName)).frame(width:7,height:7)
                            VStack(alignment:.leading,spacing:0) {
                                Text(item.title).font(.caption.bold()).lineLimit(1)
                                if !item.subtitle.isEmpty { Text(item.subtitle).font(.caption2).foregroundStyle(.secondary).lineLimit(1) }
                            }
                            Spacer(minLength:0)
                        }
                    }
                    if context.state.remainingCount > 4 { Text("+ \(context.state.remainingCount-4) more").font(.caption2.bold()).foregroundStyle(.secondary) }
                }
            }.padding(.horizontal,12).padding(.vertical,10).activityBackgroundTint(Color(.secondarySystemBackground))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) { Text(context.state.title).font(.headline).foregroundStyle(tint(context.state.colorName)).lineLimit(2) }
                DynamicIslandExpandedRegion(.trailing) { Text(timerInterval:Date()...context.state.end,countsDown:true).monospacedDigit() }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment:.leading,spacing:4) {
                        if !context.state.subtitle.isEmpty { Text(context.state.subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(1) }
                        ForEach(Array(context.state.remaining.prefix(3).enumerated()),id:\.offset){_,item in
                            HStack{Text(item.time,style:.time).font(.caption2);Circle().fill(tint(item.colorName)).frame(width:6,height:6);Text(item.title).font(.caption2).lineLimit(1);Spacer()}
                        }
                    }
                }
            } compactLeading:{Image(systemName:icon(context.state.kindName)).foregroundStyle(tint(context.state.colorName))}
              compactTrailing:{Text(timerInterval:Date()...context.state.end,countsDown:true).monospacedDigit()}
              minimal:{Circle().fill(tint(context.state.colorName))}
        }
    }

    private func action(_ title:String,_ symbol:String,type:String,id:String)->some View {
        Link(destination:URL(string:"alsagier://schedule?action=\(type)&block=\(id)")!) {
            Label(title,systemImage:symbol).font(.caption.bold()).frame(maxWidth:.infinity).padding(.vertical,5)
                .background(Color.primary.opacity(0.08),in:Capsule())
        }.buttonStyle(.plain)
    }
    private func icon(_ kind:String)->String { switch kind {case "travel":return "car.fill";case "prayer":return "moon.stars.fill";case "habit":return "figure.run";case "calendar":return "calendar";case "task":return "checkmark.circle";default:return "folder.fill"} }
    private func tint(_ name:String)->Color { switch name {case "green":return .green;case "orange":return .orange;case "purple":return .purple;case "pink":return .pink;case "teal":return .teal;case "indigo":return .indigo;case "red":return .red;case "cyan":return .cyan;case "brown":return .brown;case "gold":return Color(red:0.72,green:0.48,blue:0.02);case "gray":return .gray;default:return .blue} }
}
