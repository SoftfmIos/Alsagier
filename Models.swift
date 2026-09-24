import SwiftUI
import Foundation

enum ProjectColor: String, Codable, CaseIterable, Identifiable {
    case blue, green, orange, purple, pink, teal, indigo, red
    var id: String { rawValue }

    var color: Color {
        switch self {
        case .blue: return .blue
        case .green: return .green
        case .orange: return .orange
        case .purple: return .purple
        case .pink: return .pink
        case .teal: return .teal
        case .indigo: return .indigo
        case .red: return .red
        }
    }
}

enum TaskPriority: String, Codable, CaseIterable, Identifiable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
    var id: String { rawValue }
    var rank: Int {
        switch self { case .high: return 0; case .medium: return 1; case .low: return 2 }
    }
}

enum VaultKind: String, Codable, CaseIterable, Identifiable {
    case call = "Call"
    case email = "Email"
    var id: String { rawValue }
}

enum BlockKind: String, Codable {
    case calendar, prayer, habit, task, call, email

    var fallbackColor: Color {
        switch self {
        case .calendar: return .gray
        case .prayer: return .green
        case .habit: return .orange
        case .task: return .blue
        case .call: return .purple
        case .email: return .teal
        }
    }

    var icon: String {
        switch self {
        case .calendar: return "calendar"
        case .prayer: return "moon.stars.fill"
        case .habit: return "repeat"
        case .task: return "checkmark.circle"
        case .call: return "phone.fill"
        case .email: return "envelope.fill"
        }
    }
}

struct Project: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var dailyMinutes: Int
    var color: ProjectColor
    var isClosed = false
}

struct ExecutiveTask: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var duration: Int
    var projectID: UUID?
    var priority: TaskPriority
    var isCompleted = false
    var createdAt = Date()
}

struct Habit: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var duration: Int
    var weekdays: Set<Int>
    var isEnabled = true

    func occurs(on date: Date, calendar: Calendar = .current) -> Bool {
        weekdays.contains(calendar.component(.weekday, from: date))
    }
}

struct VaultItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var kind: VaultKind
    var duration: Int
    var isCompleted = false
    var createdAt = Date()
}

struct ScheduleBlock: Identifiable, Equatable {
    var id = UUID()
    var title: String
    var start: Date
    var end: Date
    var kind: BlockKind
    var projectColor: ProjectColor? = nil
    var isLocked: Bool

    var color: Color { projectColor?.color ?? kind.fallbackColor }
    var durationMinutes: Int { max(0, Int(end.timeIntervalSince(start) / 60)) }
}
