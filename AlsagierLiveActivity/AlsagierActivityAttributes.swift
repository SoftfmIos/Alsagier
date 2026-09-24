import ActivityKit
import Foundation

struct AlsagierActivityAttributes: ActivityAttributes {
    struct RemainingItem: Codable, Hashable {
        var title: String
        var time: Date
        var colorName: String
    }

    struct ContentState: Codable, Hashable {
        var title: String
        var subtitle: String
        var end: Date
        var isUpcoming: Bool
        var remaining: [RemainingItem]
        var remainingCount: Int
        var colorName: String
    }
    var dayID: String
}
