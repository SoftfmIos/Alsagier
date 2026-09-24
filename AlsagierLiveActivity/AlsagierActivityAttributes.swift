import ActivityKit
import Foundation

struct AlsagierActivityAttributes: ActivityAttributes {
    struct RemainingItem: Codable, Hashable {
        var title: String
        var time: Date
        var colorName: String
        var kindName: String
    }

    struct ContentState: Codable, Hashable {
        var title: String
        var subtitle: String
        var start: Date
        var end: Date
        var isUpcoming: Bool
        var remaining: [RemainingItem]
        var remainingCount: Int
        var colorName: String
        var kindName: String
    }
    var dayID: String
}
