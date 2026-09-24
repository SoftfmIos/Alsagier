import Foundation
import Combine

@MainActor
final class AppStore: ObservableObject {
    @Published var projects: [Project] = []
    @Published var tasks: [ExecutiveTask] = []
    @Published var habits: [Habit] = []
    @Published var vault: [VaultItem] = []
    @Published var schedule: [ScheduleBlock] = []

    private let defaults = UserDefaults.standard
    private let projectsKey = "alsagier.v43.projects"
    private let tasksKey = "alsagier.v43.tasks"
    private let habitsKey = "alsagier.v43.habits"
    private let vaultKey = "alsagier.v43.vault"

    init() { load() }

    func addProject(name: String, minutes: Int, color: ProjectColor) {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        projects.append(Project(name: clean, dailyMinutes: minutes, color: color))
        save()
    }

    func toggleProject(_ project: Project) {
        guard let i = projects.firstIndex(where: { $0.id == project.id }) else { return }
        projects[i].isClosed.toggle()
        save()
    }

    func deleteProject(_ project: Project) {
        projects.removeAll { $0.id == project.id }
        for i in tasks.indices where tasks[i].projectID == project.id { tasks[i].projectID = nil }
        save()
    }

    func addTask(title: String, duration: Int, projectID: UUID?, priority: TaskPriority) {
        let clean = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        tasks.append(ExecutiveTask(title: clean, duration: duration, projectID: projectID, priority: priority))
        save()
    }

    func toggleTask(_ task: ExecutiveTask) {
        guard let i = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[i].isCompleted.toggle()
        save()
    }

    func deleteTask(_ task: ExecutiveTask) {
        tasks.removeAll { $0.id == task.id }
        save()
    }

    func addHabit(name: String, duration: Int, weekdays: Set<Int>) {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty, !weekdays.isEmpty else { return }
        habits.append(Habit(name: clean, duration: duration, weekdays: weekdays))
        save()
    }

    func toggleHabit(_ habit: Habit) {
        guard let i = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        habits[i].isEnabled.toggle()
        save()
    }

    func deleteHabit(_ habit: Habit) {
        habits.removeAll { $0.id == habit.id }
        save()
    }

    func addVault(title: String, kind: VaultKind, duration: Int = 15) {
        let clean = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        vault.append(VaultItem(title: clean, kind: kind, duration: duration))
        save()
    }

    func toggleVault(_ item: VaultItem) {
        guard let i = vault.firstIndex(where: { $0.id == item.id }) else { return }
        vault[i].isCompleted.toggle()
        save()
    }

    func deleteVault(_ item: VaultItem) {
        vault.removeAll { $0.id == item.id }
        save()
    }

    func generateDay(calendarBlocks: [ScheduleBlock], prayerBlocks: [ScheduleBlock], start: Date = Date().addingTimeInterval(10 * 60)) {
        let calendar = Calendar.current
        let dayEnd = calendar.date(bySettingHour: 23, minute: 59, second: 0, of: start) ?? start.addingTimeInterval(12 * 3600)

        var result = (calendarBlocks + prayerBlocks)
            .filter { calendar.isDate($0.start, inSameDayAs: start) || calendar.isDate($0.end, inSameDayAs: start) }
            .sorted { $0.start < $1.start }

        func overlaps(_ s: Date, _ e: Date, blocks: [ScheduleBlock]) -> Bool {
            blocks.contains { s < $0.end && e > $0.start }
        }

        func nextFree(from proposed: Date, minutes: Int, blocks: [ScheduleBlock]) -> Date? {
            var candidate = max(proposed, start)
            let length = TimeInterval(minutes * 60)
            while candidate.addingTimeInterval(length) <= dayEnd {
                let end = candidate.addingTimeInterval(length)
                if let conflict = blocks
                    .filter({ candidate < $0.end && end > $0.start })
                    .sorted(by: { $0.end < $1.end }).first {
                    candidate = max(candidate.addingTimeInterval(60), conflict.end)
                } else {
                    return candidate
                }
            }
            return nil
        }

        var cursor = start

        for habit in habits.filter({ $0.isEnabled && $0.occurs(on: start) }) {
            if let s = nextFree(from: cursor, minutes: habit.duration, blocks: result) {
                let e = s.addingTimeInterval(TimeInterval(habit.duration * 60))
                result.append(ScheduleBlock(title: habit.name, start: s, end: e, kind: .habit, isLocked: false))
                cursor = e
            }
        }

        var projectUsed: [UUID: Int] = [:]
        let activeProjects = Dictionary(uniqueKeysWithValues: projects.filter { !$0.isClosed }.map { ($0.id, $0) })
        let pendingTasks = tasks.filter { !$0.isCompleted }.sorted {
            if $0.priority.rank != $1.priority.rank { return $0.priority.rank < $1.priority.rank }
            return $0.createdAt < $1.createdAt
        }

        for task in pendingTasks {
            var projectColor: ProjectColor? = nil
            if let pid = task.projectID {
                guard let project = activeProjects[pid] else { continue }
                let used = projectUsed[pid, default: 0]
                guard used + task.duration <= project.dailyMinutes else { continue }
                projectUsed[pid] = used + task.duration
                projectColor = project.color
            }

            if let s = nextFree(from: cursor, minutes: task.duration, blocks: result) {
                let e = s.addingTimeInterval(TimeInterval(task.duration * 60))
                result.append(ScheduleBlock(title: task.title, start: s, end: e, kind: .task, projectColor: projectColor, isLocked: false))
                cursor = e
            }
        }

        for item in vault.filter({ !$0.isCompleted }).sorted(by: { $0.createdAt < $1.createdAt }) {
            if let s = nextFree(from: cursor, minutes: item.duration, blocks: result) {
                let e = s.addingTimeInterval(TimeInterval(item.duration * 60))
                let blockKind: BlockKind = item.kind == .call ? .call : .email
                result.append(ScheduleBlock(title: item.title, start: s, end: e, kind: blockKind, isLocked: false))
                cursor = e
            }
        }

        schedule = result.sorted { $0.start < $1.start }
    }

    func late15() {
        let now = Date()
        let shift = TimeInterval(15 * 60)
        let immovable = schedule.filter { $0.isLocked || $0.end <= now }
        let futureFlexible = schedule.filter { !$0.isLocked && $0.end > now }.sorted { $0.start < $1.start }
        var rebuilt = immovable
        var cursor = max(now.addingTimeInterval(shift), futureFlexible.first?.start.addingTimeInterval(shift) ?? now.addingTimeInterval(shift))

        for block in futureFlexible {
            let minutes = max(1, block.durationMinutes)
            var candidate = cursor
            while true {
                let end = candidate.addingTimeInterval(TimeInterval(minutes * 60))
                if let conflict = rebuilt.filter({ $0.isLocked && candidate < $0.end && end > $0.start }).sorted(by: { $0.end < $1.end }).first {
                    candidate = conflict.end
                } else {
                    var moved = block
                    moved.start = candidate
                    moved.end = end
                    rebuilt.append(moved)
                    cursor = end
                    break
                }
            }
        }
        schedule = rebuilt.sorted { $0.start < $1.start }
    }

    var todaySummary: (done: Int, total: Int, minutes: Int) {
        let total = schedule.filter { !$0.isLocked }.count
        let minutes = schedule.filter { !$0.isLocked }.reduce(0) { $0 + $1.durationMinutes }
        let doneTaskIDs = tasks.filter(\.isCompleted).count + vault.filter(\.isCompleted).count
        return (min(doneTaskIDs, total), total, minutes)
    }

    private func save() {
        let encoder = JSONEncoder()
        if let d = try? encoder.encode(projects) { defaults.set(d, forKey: projectsKey) }
        if let d = try? encoder.encode(tasks) { defaults.set(d, forKey: tasksKey) }
        if let d = try? encoder.encode(habits) { defaults.set(d, forKey: habitsKey) }
        if let d = try? encoder.encode(vault) { defaults.set(d, forKey: vaultKey) }
    }

    private func load() {
        let decoder = JSONDecoder()
        if let d = defaults.data(forKey: projectsKey), let x = try? decoder.decode([Project].self, from: d) { projects = x }
        if let d = defaults.data(forKey: tasksKey), let x = try? decoder.decode([ExecutiveTask].self, from: d) { tasks = x }
        if let d = defaults.data(forKey: habitsKey), let x = try? decoder.decode([Habit].self, from: d) { habits = x }
        if let d = defaults.data(forKey: vaultKey), let x = try? decoder.decode([VaultItem].self, from: d) { vault = x }
    }
}
