import Foundation
import Combine

@MainActor
final class AppStore: ObservableObject {
    @Published var projects: [Project] = []
    @Published var tasks: [ExecutiveTask] = []
    @Published var habits: [Habit] = []
    @Published var vault: [VaultItem] = []
    @Published var schedule: [ScheduleBlock] = []

    private let projectsKey = "alsagier.projects"
    private let tasksKey = "alsagier.tasks"
    private let habitsKey = "alsagier.habits"
    private let vaultKey = "alsagier.vault"

    init() {
        projects = load(projectsKey) ?? []
        tasks = load(tasksKey) ?? []
        habits = load(habitsKey) ?? []
        vault = load(vaultKey) ?? []
    }

    func saveAll() {
        save(projects, projectsKey)
        save(tasks, tasksKey)
        save(habits, habitsKey)
        save(vault, vaultKey)
    }

    func addProject(_ project: Project) { projects.append(project); saveAll() }
    func deleteProject(_ project: Project) { projects.removeAll { $0.id == project.id }; saveAll() }
    func toggleProject(_ project: Project) {
        guard let i = projects.firstIndex(where: { $0.id == project.id }) else { return }
        projects[i].isClosed.toggle(); saveAll()
    }

    func addTask(_ task: ExecutiveTask) { tasks.append(task); saveAll() }
    func deleteTask(_ task: ExecutiveTask) { tasks.removeAll { $0.id == task.id }; saveAll() }
    func completeTask(_ task: ExecutiveTask) {
        guard let i = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[i].isCompleted = true; saveAll()
    }

    func addHabit(_ habit: Habit) { habits.append(habit); saveAll() }
    func deleteHabit(_ habit: Habit) { habits.removeAll { $0.id == habit.id }; saveAll() }
    func addVault(_ item: VaultItem) { vault.append(item); saveAll() }
    func deleteVault(_ item: VaultItem) { vault.removeAll { $0.id == item.id }; saveAll() }

    func generateDay(start: Date, calendarBlocks: [ScheduleBlock], prayerBlocks: [ScheduleBlock]) {
        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: start)
        let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart)!
        var fixed = (calendarBlocks + prayerBlocks)
            .filter { $0.end > start && $0.start < dayEnd }
            .sorted { $0.start < $1.start }

        var result = fixed
        var cursor = start
        var projectUsed: [UUID:Int] = [:]

        func nextFree(_ from: Date, minutes: Int) -> Date? {
            var candidate = from
            while candidate.addingTimeInterval(Double(minutes * 60)) <= dayEnd {
                if let collision = fixed.first(where: {
                    candidate < $0.end &&
                    candidate.addingTimeInterval(Double(minutes * 60)) > $0.start
                }) {
                    candidate = max(candidate, collision.end)
                } else {
                    return candidate
                }
            }
            return nil
        }

        let weekday = cal.component(.weekday, from: start)
        for habit in habits where habit.weekdays.contains(weekday) {
            guard let s = nextFree(cursor, minutes: habit.duration) else { continue }
            let e = s.addingTimeInterval(Double(habit.duration * 60))
            result.append(ScheduleBlock(title: habit.name, start: s, end: e, kind: .habit, color: .habit, isLocked: false))
            fixed.append(result.last!)
            fixed.sort { $0.start < $1.start }
            cursor = e
        }

        let activeTasks = tasks.filter { !$0.isCompleted }.sorted { $0.priority.weight > $1.priority.weight }
        for task in activeTasks {
            if let pid = task.projectID,
               let project = projects.first(where: { $0.id == pid && !$0.isClosed }) {
                let used = projectUsed[pid, default: 0]
                guard used + task.duration <= project.dailyMinutes else { continue }
                guard let s = nextFree(cursor, minutes: task.duration) else { continue }
                let e = s.addingTimeInterval(Double(task.duration * 60))
                result.append(ScheduleBlock(title: task.title, start: s, end: e, kind: .task, color: project.color, isLocked: false))
                projectUsed[pid] = used + task.duration
                fixed.append(result.last!)
                fixed.sort { $0.start < $1.start }
                cursor = e
            } else {
                guard let s = nextFree(cursor, minutes: task.duration) else { continue }
                let e = s.addingTimeInterval(Double(task.duration * 60))
                result.append(ScheduleBlock(title: task.title, start: s, end: e, kind: .task, color: .task, isLocked: false))
                fixed.append(result.last!)
                fixed.sort { $0.start < $1.start }
                cursor = e
            }
        }

        for item in vault {
            guard let s = nextFree(cursor, minutes: item.duration) else { continue }
            let e = s.addingTimeInterval(Double(item.duration * 60))
            result.append(ScheduleBlock(title: item.title, start: s, end: e, kind: item.kind, color: item.kind == .call ? .call : .email, isLocked: false))
            fixed.append(result.last!)
            fixed.sort { $0.start < $1.start }
            cursor = e
        }

        schedule = result.sorted { $0.start < $1.start }
    }

    func late15() {
        let now = Date()
        let fixed = schedule.filter { $0.isLocked || $0.end <= now }.sorted { $0.start < $1.start }
        let flexible = schedule.filter { !$0.isLocked && $0.end > now }.sorted { $0.start < $1.start }
        var result = fixed
        var cursor = now.addingTimeInterval(15 * 60)
        let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: now))!

        for block in flexible {
            let duration = Int(block.end.timeIntervalSince(block.start) / 60)
            var candidate = cursor
            while candidate.addingTimeInterval(Double(duration * 60)) <= dayEnd {
                if let collision = result.filter({ $0.isLocked }).first(where: {
                    candidate < $0.end && candidate.addingTimeInterval(Double(duration * 60)) > $0.start
                }) {
                    candidate = collision.end
                } else { break }
            }
            guard candidate.addingTimeInterval(Double(duration * 60)) <= dayEnd else { continue }
            var moved = block
            moved.start = candidate
            moved.end = candidate.addingTimeInterval(Double(duration * 60))
            result.append(moved)
            cursor = moved.end
        }
        schedule = result.sorted { $0.start < $1.start }
    }

    private func save<T: Encodable>(_ value: T, _ key: String) {
        if let data = try? JSONEncoder().encode(value) { UserDefaults.standard.set(data, forKey: key) }
    }

    private func load<T: Decodable>(_ key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
