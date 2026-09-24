import ActivityKit
import WidgetKit
import SwiftUI

struct AlsagierLiveActivityWidget:Widget {
    var body:some WidgetConfiguration {
        ActivityConfiguration(for:AlsagierActivityAttributes.self) { context in
            VStack(alignment:.leading,spacing:5) {
                Text("ALSAGIER • NOW").font(.caption.bold())
                Text(context.state.title).font(.headline)
                if !context.state.subtitle.isEmpty {Text(context.state.subtitle).font(.subheadline)}
                Text(timerInterval:Date()...context.state.end,countsDown:true).font(.title3.monospacedDigit())
                Text("Next: \(context.state.next)").font(.caption)
            }.padding().activityBackgroundTint(tint(context.state.colorName).opacity(0.22))
        } dynamicIsland:{ context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading){Text(context.state.title).font(.headline)}
                DynamicIslandExpandedRegion(.trailing){Text(timerInterval:Date()...context.state.end,countsDown:true).monospacedDigit()}
                DynamicIslandExpandedRegion(.bottom){Text("Next: \(context.state.next)").font(.caption)}
            } compactLeading:{Circle().fill(tint(context.state.colorName)).frame(width:10,height:10)}
              compactTrailing:{Text(timerInterval:Date()...context.state.end,countsDown:true).monospacedDigit()}
              minimal:{Circle().fill(tint(context.state.colorName))}
        }
    }
    private func tint(_ name:String)->Color {
        switch name {
        case "green":return .green; case "orange":return .orange; case "purple":return .purple
        case "pink":return .pink; case "teal":return .teal; case "indigo":return .indigo
        case "red":return .red; default:return .blue
        }
    }
}
