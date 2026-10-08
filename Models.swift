import SwiftUI
import Foundation

enum ProjectColor: String, Codable, CaseIterable, Identifiable {
    // green is retained only so existing V5 data can still decode. It is not selectable for projects.
    case blue, green, orange, purple, pink, teal, indigo, red, cyan, brown, gold, emerald, burgundy, olive, charcoal, coral
    var id: String { rawValue }

    static var projectChoices: [ProjectColor] {
        [.blue, .orange, .purple, .pink, .teal, .indigo, .red, .cyan, .brown, .gold, .emerald, .burgundy, .olive, .charcoal, .coral]
    }

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
        case .cyan: return .cyan
        case .brown: return .brown
        case .gold: return Color(red: 0.72, green: 0.48, blue: 0.02)
        case .emerald: return Color(red: 22/255, green: 139/255, blue: 82/255)
        case .burgundy: return Color(red: 135/255, green: 48/255, blue: 77/255)
        case .olive: return Color(red: 119/255, green: 133/255, blue: 43/255)
        case .charcoal: return Color(red: 71/255, green: 85/255, blue: 105/255)
        case .coral: return Color(red: 233/255, green: 120/255, blue: 98/255)
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
    case fixed = "Fixed days", flexible = "Random"
    var id: String { rawValue }

    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        switch value {
        case "Fixed days": self = .fixed
        case "Random", "Alsagier chooses": self = .flexible
        default: self = .fixed
        }
    }
}

enum HabitRecurrence: String, Codable, CaseIterable, Identifiable {
    case weekly = "Weekly"
    case everyTwoWeeks = "Every 2 weeks"
    case everyThreeWeeks = "Every 3 weeks"
    case everyFourWeeks = "Every 4 weeks"
    case monthly = "Every calendar month"
    var id: String { rawValue }
}

enum PreferredPeriod: String, Codable, CaseIterable, Identifiable {
    case anytime = "Anytime", morning = "Morning", afternoon = "Afternoon", evening = "Evening"
    var id: String { rawValue }
}

enum BlockKind: String, Codable {
    case calendar, prayer, habit, travel, project, task, calls, email
    var icon: String {
        switch self {
        case .calendar: return "calendar"
        case .prayer: return "moon.stars.fill"
        case .habit: return "figure.run"
        case .travel: return "car.fill"
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
        case .travel: return .gray
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

// Administrative closure is not a worked session or an emotion rating.
struct AdministrativeProjectClosure: Identifiable, Codable, Equatable {
    var id = UUID()
    var projectID: UUID
    var date: Date = Date()
    var taskIDs: [UUID]
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
    var travelMinutes: Int = 0
    var tracksWalking: Bool = false
    var recurrence: HabitRecurrence = .weekly
    var recurrenceAnchor: Date = Calendar.current.startOfDay(for: Date())
    var stepTarget: Int = 10000
    var walkingMinutesTarget: Int = 60

    enum CodingKeys: String, CodingKey {
        case id, name, duration, mode, weekdays, timesPerWeek, earliestHour, latestHour
        case preferredPeriod, priority, isEnabled, travelMinutes, tracksWalking, stepTarget, walkingMinutesTarget, recurrence, recurrenceAnchor
    }

    init(id: UUID = UUID(), name: String, duration: Int = 30, mode: HabitScheduleMode = .fixed,
         weekdays: Set<Int> = [], timesPerWeek: Int = 3, earliestHour: Int = 6, latestHour: Int = 23,
         preferredPeriod: PreferredPeriod = .anytime, priority: WorkPriority = .normal,
         isEnabled: Bool = true, travelMinutes: Int? = nil, tracksWalking: Bool? = nil,
         stepTarget: Int = 10000, walkingMinutesTarget: Int = 60,
         recurrence: HabitRecurrence = .weekly, recurrenceAnchor: Date = Date()) {
        self.id=id; self.name=name; self.duration=duration; self.mode=mode; self.weekdays=weekdays
        self.timesPerWeek=timesPerWeek; self.earliestHour=earliestHour; self.latestHour=latestHour
        self.preferredPeriod=preferredPeriod; self.priority=priority; self.isEnabled=isEnabled
        self.travelMinutes = travelMinutes ?? (name.localizedCaseInsensitiveContains("gym") ? 30 : 0)
        self.tracksWalking = tracksWalking ?? name.localizedCaseInsensitiveContains("walk")
        self.stepTarget = stepTarget; self.walkingMinutesTarget = walkingMinutesTarget
        self.recurrence = recurrence; self.recurrenceAnchor = Calendar.current.startOfDay(for: recurrenceAnchor)
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey:.id) ?? UUID()
        name = try c.decode(String.self, forKey:.name)
        duration = try c.decodeIfPresent(Int.self, forKey:.duration) ?? 30
        mode = try c.decodeIfPresent(HabitScheduleMode.self, forKey:.mode) ?? .fixed
        weekdays = try c.decodeIfPresent(Set<Int>.self, forKey:.weekdays) ?? []
        timesPerWeek = try c.decodeIfPresent(Int.self, forKey:.timesPerWeek) ?? 3
        earliestHour = try c.decodeIfPresent(Int.self, forKey:.earliestHour) ?? 6
        latestHour = try c.decodeIfPresent(Int.self, forKey:.latestHour) ?? 23
        preferredPeriod = try c.decodeIfPresent(PreferredPeriod.self, forKey:.preferredPeriod) ?? .anytime
        priority = try c.decodeIfPresent(WorkPriority.self, forKey:.priority) ?? .normal
        isEnabled = try c.decodeIfPresent(Bool.self, forKey:.isEnabled) ?? true
        travelMinutes = try c.decodeIfPresent(Int.self, forKey:.travelMinutes) ?? (name.localizedCaseInsensitiveContains("gym") ? 30 : 0)
        tracksWalking = try c.decodeIfPresent(Bool.self, forKey:.tracksWalking) ?? name.localizedCaseInsensitiveContains("walk")
        stepTarget = try c.decodeIfPresent(Int.self, forKey:.stepTarget) ?? 10000
        walkingMinutesTarget = try c.decodeIfPresent(Int.self, forKey:.walkingMinutesTarget) ?? 60
        recurrence = try c.decodeIfPresent(HabitRecurrence.self, forKey:.recurrence) ?? .weekly
        recurrenceAnchor = try c.decodeIfPresent(Date.self, forKey:.recurrenceAnchor) ?? Calendar.current.startOfDay(for: Date())
    }
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

struct HabitCompletion: Identifiable, Codable, Equatable {
    var id = UUID()
    var habitID: UUID
    var date: Date
    var source: String = "manual"
    var progressPercent: Double? = nil
    var status: String? = nil
}

struct WorkInsight: Identifiable, Codable, Equatable {
    var id = UUID()
    var projectID: UUID?
    var projectName: String
    var taskID: UUID?
    var taskName: String?
    var blockKind: BlockKind
    var date: Date
    var startedAt: Date? = nil
    var plannedMinutes: Int
    var actualMinutes: Int
    var happiness: Int?
    var scheduleBlockID: UUID? = nil

    enum CodingKeys: String, CodingKey {
        case id, projectID, projectName, taskID, taskName, blockKind, date, startedAt,
             plannedMinutes, actualMinutes, happiness, scheduleBlockID
    }
    init(id: UUID = UUID(), projectID: UUID?, projectName: String, taskID: UUID?, taskName: String?,
         blockKind: BlockKind, date: Date, startedAt: Date? = nil, plannedMinutes: Int,
         actualMinutes: Int, happiness: Int?, scheduleBlockID: UUID? = nil) {
        self.id = id; self.projectID = projectID; self.projectName = projectName
        self.taskID = taskID; self.taskName = taskName; self.blockKind = blockKind
        self.date = date; self.startedAt = startedAt; self.plannedMinutes = plannedMinutes
        self.actualMinutes = actualMinutes; self.happiness = happiness; self.scheduleBlockID = scheduleBlockID
    }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        projectID = try c.decodeIfPresent(UUID.self, forKey: .projectID)
        projectName = try c.decode(String.self, forKey: .projectName)
        taskID = try c.decodeIfPresent(UUID.self, forKey: .taskID)
        taskName = try c.decodeIfPresent(String.self, forKey: .taskName)
        blockKind = try c.decode(BlockKind.self, forKey: .blockKind)
        date = try c.decode(Date.self, forKey: .date)
        startedAt = try c.decodeIfPresent(Date.self, forKey: .startedAt)
        plannedMinutes = try c.decode(Int.self, forKey: .plannedMinutes)
        actualMinutes = try c.decode(Int.self, forKey: .actualMinutes)
        happiness = try c.decodeIfPresent(Int.self, forKey: .happiness)
        scheduleBlockID = try c.decodeIfPresent(UUID.self, forKey: .scheduleBlockID)
    }
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
    var dadJokesEnabled = true

    enum CodingKeys: String, CodingKey { case workEndHour, personalEndHour, reminderMinutes, callsMinutes, emailMinutes, dadJokesEnabled }
    init() {}
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        workEndHour = try c.decodeIfPresent(Int.self, forKey:.workEndHour) ?? 16
        personalEndHour = try c.decodeIfPresent(Int.self, forKey:.personalEndHour) ?? 23
        reminderMinutes = try c.decodeIfPresent(Int.self, forKey:.reminderMinutes) ?? 2
        callsMinutes = try c.decodeIfPresent(Int.self, forKey:.callsMinutes) ?? 30
        emailMinutes = try c.decodeIfPresent(Int.self, forKey:.emailMinutes) ?? 30
        dadJokesEnabled = try c.decodeIfPresent(Bool.self, forKey:.dadJokesEnabled) ?? true
    }
}

struct CompletionCorrection: Identifiable, Codable, Equatable {
    var id = UUID()
    var planID: UUID
    var blockID: UUID
    var correctedAt: Date
    var reason: String
}
