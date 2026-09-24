import ActivityKit
import Foundation

struct AlsagierActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var title: String
        var subtitle: String
        var end: Date
        var next: String
        var colorName: String
    }
    var dayID: String
}
