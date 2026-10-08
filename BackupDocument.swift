import SwiftUI
import UniformTypeIdentifiers

struct AlsagierBackup: Codable {
    var version: Int = 1
    var createdAt: Date = Date()
    var projects: [Project]
    var tasks: [ExecutiveTask]
    var habits: [Habit]
    var dayPlans: [DayPlan]
    var insights: [WorkInsight] = []
    var habitCompletions: [HabitCompletion] = []
    var settings: AppSettings

    enum CodingKeys: String, CodingKey { case version, createdAt, projects, tasks, habits, dayPlans, insights, habitCompletions, settings }
    init(version: Int = 1, createdAt: Date = Date(), projects: [Project], tasks: [ExecutiveTask], habits: [Habit], dayPlans: [DayPlan], insights: [WorkInsight] = [], habitCompletions: [HabitCompletion] = [], settings: AppSettings) {
        self.version=version; self.createdAt=createdAt; self.projects=projects; self.tasks=tasks; self.habits=habits; self.dayPlans=dayPlans; self.insights=insights; self.habitCompletions=habitCompletions; self.settings=settings
    }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        version = try c.decodeIfPresent(Int.self, forKey:.version) ?? 1
        createdAt = try c.decodeIfPresent(Date.self, forKey:.createdAt) ?? Date()
        projects = try c.decode([Project].self, forKey:.projects); tasks = try c.decode([ExecutiveTask].self, forKey:.tasks)
        habits = try c.decode([Habit].self, forKey:.habits); dayPlans = try c.decode([DayPlan].self, forKey:.dayPlans)
        insights = try c.decodeIfPresent([WorkInsight].self, forKey:.insights) ?? []
        habitCompletions = try c.decodeIfPresent([HabitCompletion].self, forKey:.habitCompletions) ?? []
        settings = try c.decode(AppSettings.self, forKey:.settings)
    }
}

struct AlsagierBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var backup: AlsagierBackup

    init(backup: AlsagierBackup) { self.backup = backup }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else { throw CocoaError(.fileReadCorruptFile) }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        backup = try decoder.decode(AlsagierBackup.self, from: data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return FileWrapper(regularFileWithContents: try encoder.encode(backup))
    }
}
