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

enum WorkPriority: String, Codable, CaseIterable, Identifiable {
    case high = "High", normal = "Normal", low = "Low"
    var id: String { rawValue }
    var rank: Int { self == .high ? 0 : (self == .normal ? 1 : 2) }
}

enum ProjectMode: String, Codable, CaseIterable, Identifiable {
    case taskBased = "Task-based", continuous = "Continuous"
    var id: String { rawValue }
}

enum ProjectStatus: String, Codable, CaseIterable, Identifiable {
    case active = "Active", frozen = "Frozen", closed = "Closed"
    var id: String { rawValue }
}

enum HabitScheduleMode: String, Codable, CaseIterable, Identifiable {
    case fixed = "Fixed days", flexible = "Alsagier chooses"
    var id: String { rawValue }
}

enum PreferredPeriod: String, Codable, CaseIterable, Identifiable {
    case anytime = "Anytime", morning = "Morning", afternoon = "Afternoon", evening = "Evening"
    var id: String { rawValue }
}

enum BlockKind: String, Codable {
    case calendar, prayer, habit, project, task, calls, email
    var icon: String {
        switch self {
        case .calendar: return "calendar"
        case .prayer: return "moon.stars.fill"
        case .habit: return "figure.run"
        case .project: return "folder.fill"
        case .task: return "checkmark.circle"
        case .calls: return "phone.fill"
        case .email: return "envelope.fill"
        }
    }
    var fallbackColor: Color {
        switch self {
        case .calendar: return .gray
        case .prayer: return .green
        case .habit: return .orange
        case .project, .task: return .blue
        case .calls: return .purple
        case .email: return .teal
        }
    }
}

struct Project: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var dailyMinutes: Int = 60
    var preferredBlockMinutes: Int = 30
    var color: ProjectColor = .blue
    var priority: WorkPriority = .normal
    var mode: ProjectMode = .taskBased
    var status: ProjectStatus = .active
}

struct ExecutiveTask: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var duration: Int = 15
    var projectID: UUID?
    var priority: WorkPriority = .normal
    var isCompleted = false
    var createdAt = Date()
}

struct Habit: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var duration: Int = 30
    var mode: HabitScheduleMode = .fixed
    var weekdays: Set<Int> = []
    var timesPerWeek: Int = 3
    var earliestHour: Int = 6
    var latestHour: Int = 23
    var preferredPeriod: PreferredPeriod = .anytime
    var priority: WorkPriority = .normal
    var isEnabled = true
}

struct ScheduleBlock: Identifiable, Codable, Equatable {
    var id = UUID()
    var sourceID: UUID?
    var title: String
    var subtitle: String?
    var start: Date
    var end: Date
    var kind: BlockKind
    var projectColor: ProjectColor?
    var isLocked: Bool
    var isCompleted = false
    var isSkipped = false

    var color: Color { projectColor?.color ?? kind.fallbackColor }
    var durationMinutes: Int { max(0, Int(end.timeIntervalSince(start) / 60)) }
}

struct DayPlan: Identifiable, Codable, Equatable {
    var id = UUID()
    var date: Date
    var startedAt: Date
    var endedAt: Date?
    var blocks: [ScheduleBlock]
    var isFrozen: Bool = false
}

struct AppSettings: Codable, Equatable {
    var workEndHour = 16
    var personalEndHour = 23
    var reminderMinutes = 2
    var callsMinutes = 30
    var emailMinutes = 30
}
