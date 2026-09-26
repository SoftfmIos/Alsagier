import ActivityKit
import Foundation

struct AlsagierActivityAttributes: ActivityAttributes {
    struct RemainingItem: Codable, Hashable {
        var title: String; var subtitle: String; var time: Date; var end: Date; var colorName: String; var kindName: String
    }
    struct ContentState: Codable, Hashable {
        var blockID: String
        var title: String; var subtitle: String; var start: Date; var end: Date; var isUpcoming: Bool
        var remaining: [RemainingItem]; var remainingCount: Int; var colorName: String; var kindName: String; var actionable: Bool
    }
    var dayID: String
}
