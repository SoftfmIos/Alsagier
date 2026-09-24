import Foundation
import Combine

@MainActor
final class AppStore: ObservableObject {
    @Published var projects: [Project] = []
    @Published var tasks: [ExecutiveTask] = []
    @Published var habits: [Habit] = []
    @Published var dayPlans: [DayPlan] = []
    @Published var settings = AppSettings()

    private let defaults = UserDefaults.standard
    private let pKey = "alsagier.v5.projects"
    private let tKey = "alsagier.v5.tasks"
    private let hKey = "alsagier.v5.habits"
    private let dKey = "alsagier.v5.dayplans"
    private let sKey = "alsagier.v5.settings"

    init() {
        load()
        migrateV43IfNeeded()
        migrateReservedGreenProjects()
        autoCloseExpiredDay()
    }

    var todayIndex: Int? {
        dayPlans.firstIndex { Calendar.current.isDateInToday($0.date) }
    }
    var todayPlan: DayPlan? { todayIndex.map { dayPlans[$0] } }
    var isDayActive: Bool { todayPlan?.endedAt == nil && todayPlan != nil }

    func addProject(_ p: Project) { projects.append(p); save() }
    func updateProject(_ p: Project) {
        if let i = projects.firstIndex(where: {$0.id == p.id}) { projects[i] = p; save() }
    }
    func deleteProject(_ p: Project) {
        projects.removeAll {$0.id == p.id}
        for i in tasks.indices where tasks[i].projectID == p.id { tasks[i].projectID = nil }
        save()
    }

    func addTask(title: String, duration: Int, projectID: UUID?, priority: WorkPriority) {
        let value = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        tasks.append(ExecutiveTask(title: value, duration: duration, projectID: projectID, priority: priority))
        save()
    }
    func toggleTask(_ task: ExecutiveTask) {
        if let i = tasks.firstIndex(where: {$0.id == task.id}) { tasks[i].isCompleted.toggle(); save() }
    }
    func deleteTask(_ task: ExecutiveTask) { tasks.removeAll {$0.id == task.id}; save() }

    func addHabit(_ h: Habit) { habits.append(h); save() }
    func updateHabit(_ h: Habit) {
        if let i = habits.firstIndex(where: {$0.id == h.id}) { habits[i] = h; save() }
    }
    func deleteHabit(_ h: Habit) { habits.removeAll {$0.id == h.id}; save() }
    func toggleHabit(_ h: Habit) {
        if let i = habits.firstIndex(where: {$0.id == h.id}) { habits[i].isEnabled.toggle(); save() }
    }

    func startDay(calendar: [ScheduleBlock], prayers: [ScheduleBlock]) {
        guard todayPlan == nil else { return }
        let now = Date()
        let firstFlexible = now.addingTimeInterval(10 * 60)
        let blocks = buildSchedule(calendar: calendar, prayers: prayers, from: firstFlexible)
        dayPlans.append(DayPlan(date: Calendar.current.startOfDay(for: now), startedAt: now, blocks: blocks))
        save()
    }

    func complete(_ block: ScheduleBlock, calendar: [ScheduleBlock], prayers: [ScheduleBlock]) {
        guard let di = todayIndex,
              let bi = dayPlans[di].blocks.firstIndex(where: {$0.id == block.id}) else { return }

        dayPlans[di].blocks[bi].isCompleted = true
        if block.kind == .task, let source = block.sourceID,
           let ti = tasks.firstIndex(where: {$0.id == source}) { tasks[ti].isCompleted = true }
        save()
        rebalanceFuture(calendar: calendar, prayers: prayers)
    }

    func skip(_ block: ScheduleBlock, calendar: [ScheduleBlock], prayers: [ScheduleBlock]) {
        guard let di = todayIndex,
              let bi = dayPlans[di].blocks.firstIndex(where: {$0.id == block.id}),
              !block.isLocked else { return }
        dayPlans[di].blocks[bi].isSkipped = true
        save()
        rebalanceFuture(calendar: calendar, prayers: prayers)
    }

    func extend15(_ block: ScheduleBlock, calendar: [ScheduleBlock], prayers: [ScheduleBlock]) {
        guard let di = todayIndex,
              let bi = dayPlans[di].blocks.firstIndex(where: {$0.id == block.id}),
              !block.isLocked else { return }
        dayPlans[di].blocks[bi].end = dayPlans[di].blocks[bi].end.addingTimeInterval(15 * 60)
        save()
        rebalanceFuture(calendar: calendar, prayers: prayers, after: dayPlans[di].blocks[bi].end)
    }

    func endDay() {
        guard let i = todayIndex, dayPlans[i].endedAt == nil else { return }
        dayPlans[i].endedAt = Date()
        dayPlans[i].isFrozen = true
        save()
    }

    func reopenDay(calendar: [ScheduleBlock], prayers: [ScheduleBlock]) {
        guard let i = todayIndex, Calendar.current.isDateInToday(dayPlans[i].date) else { return }
        dayPlans[i].endedAt = nil
        dayPlans[i].isFrozen = false
        save()
        rebalanceFuture(calendar: calendar, prayers: prayers, after: Date())
    }

    func autoCloseExpiredDay() {
        let cal = Calendar.current
        let now = Date()
        for i in dayPlans.indices where dayPlans[i].endedAt == nil {
            guard let cutoff = cal.date(bySettingHour: settings.workEndHour, minute: 0, second: 0, of: dayPlans[i].date) else { continue }
            if now >= cutoff && !cal.isDateInToday(dayPlans[i].date) {
                dayPlans[i].endedAt = cutoff
                dayPlans[i].isFrozen = true
            }
        }
        save()
    }

    func updateSettings(_ newValue: AppSettings) { settings = newValue; save() }

    private func rebalanceFuture(calendar: [ScheduleBlock], prayers: [ScheduleBlock], after moment: Date = Date()) {
        guard let di = todayIndex, dayPlans[di].endedAt == nil else { return }
        let past = dayPlans[di].blocks.filter { $0.start < moment || $0.isCompleted || $0.isSkipped }
        let closedSourceIDs = Set(past.filter {$0.isCompleted || $0.isSkipped}.compactMap(\.sourceID))
        let rebuilt = buildSchedule(calendar: calendar, prayers: prayers, from: moment)
            .filter { candidate in
                !past.contains(where: {$0.id == candidate.id}) &&
                (candidate.sourceID == nil || !closedSourceIDs.contains(candidate.sourceID!))
            }
        dayPlans[di].blocks = (past + rebuilt).sorted {$0.start < $1.start}
        save()
    }

    private func buildSchedule(calendar: [ScheduleBlock], prayers: [ScheduleBlock], from start: Date) -> [ScheduleBlock] {
        let cal = Calendar.current
        let day = cal.startOfDay(for: start)
        guard let workEnd = cal.date(bySettingHour: settings.workEndHour, minute: 0, second: 0, of: day),
              let personalEnd = cal.date(bySettingHour: settings.personalEndHour, minute: 0, second: 0, of: day) else { return [] }

        var result = (calendar + prayers).filter {$0.end > start && $0.start < personalEnd}
        var cursor = start

        func slot(after proposed: Date, minutes: Int, limit: Date, blocks: [ScheduleBlock]) -> Date? {
            var s = proposed
            let length = TimeInterval(minutes * 60)
            while s.addingTimeInterval(length) <= limit {
                let e = s.addingTimeInterval(length)
                if let conflict = blocks.filter({s < $0.end && e > $0.start}).sorted(by: {$0.end < $1.end}).first {
                    s = conflict.end
                } else { return s }
            }
            return nil
        }

        let active = projects.filter {$0.status == .active}.sorted {
            $0.priority.rank == $1.priority.rank ? $0.name < $1.name : $0.priority.rank < $1.priority.rank
        }

        // Keep a project together where possible to reduce context switching.
        for project in active {
            var used = 0
            if project.mode == .taskBased {
                let pending = tasks.filter {!$0.isCompleted && $0.projectID == project.id}.sorted {
                    $0.priority.rank == $1.priority.rank ? $0.createdAt < $1.createdAt : $0.priority.rank < $1.priority.rank
                }
                for task in pending where used < project.dailyMinutes {
                    let minutes = min(task.duration, project.dailyMinutes - used)
                    guard minutes > 0, let s = slot(after: cursor, minutes: minutes, limit: workEnd, blocks: result) else { continue }
                    let e = s.addingTimeInterval(TimeInterval(minutes * 60))
                    result.append(ScheduleBlock(sourceID: task.id, title: project.name, subtitle: task.title,
                                                start: s, end: e, kind: .task, projectColor: project.color, isLocked: false))
                    cursor = e; used += minutes
                }
            } else {
                var remaining = project.dailyMinutes
                while remaining > 0 {
                    let minutes = min(project.preferredBlockMinutes, remaining)
                    guard let s = slot(after: cursor, minutes: minutes, limit: workEnd, blocks: result) else { break }
                    let e = s.addingTimeInterval(TimeInterval(minutes * 60))
                    result.append(ScheduleBlock(sourceID: project.id, title: project.name, subtitle: "Focus session",
                                                start: s, end: e, kind: .project, projectColor: project.color, isLocked: false))
                    cursor = e; remaining -= minutes
                }
            }
        }

        func appendHabit(_ habit: Habit, preferred: Date, latest: Date, subtitle: String) {
            let travel = max(0, habit.travelMinutes)
            let total = travel + habit.duration
            guard let reservedStart = slot(after: preferred, minutes: total, limit: latest, blocks: result) else { return }
            let habitStart = reservedStart.addingTimeInterval(TimeInterval(travel * 60))
            if travel > 0 {
                result.append(ScheduleBlock(sourceID: habit.id, title: "Travel to \(habit.name)",
                                            subtitle: "\(travel) min road time", start: reservedStart, end: habitStart,
                                            kind: .travel, projectColor: nil, isLocked: false))
            }
            result.append(ScheduleBlock(sourceID: habit.id, title: habit.name, subtitle: subtitle,
                                        start: habitStart, end: habitStart.addingTimeInterval(TimeInterval(habit.duration * 60)),
                                        kind: .habit, projectColor: nil, isLocked: false))
        }

        // Fixed habits.
        let weekday = cal.component(.weekday, from: day)
        for habit in habits.filter({$0.isEnabled && $0.mode == .fixed && $0.weekdays.contains(weekday)}) {
            let earliest = cal.date(bySettingHour: habit.earliestHour, minute: 0, second: 0, of: day) ?? start
            let latest = cal.date(bySettingHour: habit.latestHour, minute: 0, second: 0, of: day) ?? personalEnd
            appendHabit(habit, preferred: max(start, earliest), latest: min(latest, personalEnd), subtitle: "Habit")
        }

        // Flexible weekly habits. Schedule today when remaining sessions need available days.
        let interval = cal.dateInterval(of: .weekOfYear, for: day)
        for habit in habits.filter({$0.isEnabled && $0.mode == .flexible}) {
            let completed = completedHabitCount(habit, in: interval)
            let remaining = max(0, habit.timesPerWeek - completed)
            guard remaining > 0 else { continue }

            let daysLeft = max(1, 8 - cal.component(.weekday, from: day))
            let shouldUseToday = remaining >= daysLeft || flexibleHabitAlreadyPlannedToday(habit) == false
            guard shouldUseToday else { continue }

            let earliest = cal.date(bySettingHour: habit.earliestHour, minute: 0, second: 0, of: day) ?? start
            let latest = cal.date(bySettingHour: habit.latestHour, minute: 0, second: 0, of: day) ?? personalEnd
            let preferred = preferredStart(for: habit, day: day, fallback: max(start, earliest))
            appendHabit(habit, preferred: max(preferred, earliest), latest: min(latest, personalEnd),
                        subtitle: "\(completed)/\(habit.timesPerWeek) completed this week")
        }

        // Communication windows.
        if settings.callsMinutes > 0 {
            let preferred = cal.date(bySettingHour: 10, minute: 0, second: 0, of: day) ?? start
            if let s = slot(after: max(start, preferred), minutes: settings.callsMinutes, limit: workEnd, blocks: result) {
                result.append(ScheduleBlock(title: "Calls", subtitle: "Communication window", start: s,
                    end: s.addingTimeInterval(TimeInterval(settings.callsMinutes*60)), kind: .calls, projectColor: nil, isLocked: false))
            }
        }
        if settings.emailMinutes > 0 {
            let preferred = cal.date(bySettingHour: 14, minute: 0, second: 0, of: day) ?? start
            if let s = slot(after: max(start, preferred), minutes: settings.emailMinutes, limit: workEnd, blocks: result) {
                result.append(ScheduleBlock(title: "Email", subtitle: "Communication window", start: s,
                    end: s.addingTimeInterval(TimeInterval(settings.emailMinutes*60)), kind: .email, projectColor: nil, isLocked: false))
            }
        }

        return result.sorted {$0.start < $1.start}
    }

    private func preferredStart(for habit: Habit, day: Date, fallback: Date) -> Date {
        let cal = Calendar.current
        let hour: Int
        switch habit.preferredPeriod {
        case .morning: hour = 8
        case .afternoon: hour = 14
        case .evening: hour = 18
        case .anytime: return fallback
        }
        return cal.date(bySettingHour: hour, minute: 0, second: 0, of: day) ?? fallback
    }

    private func completedHabitCount(_ habit: Habit, in interval: DateInterval?) -> Int {
        guard let interval else { return 0 }
        return dayPlans.filter { interval.contains($0.date) }.flatMap(\.blocks)
            .filter {$0.kind == .habit && $0.sourceID == habit.id && $0.isCompleted}.count
    }

    private func flexibleHabitAlreadyPlannedToday(_ habit: Habit) -> Bool {
        todayPlan?.blocks.contains(where: {$0.kind == .habit && $0.sourceID == habit.id}) ?? false
    }

    func save() {
        let enc = JSONEncoder()
        if let d = try? enc.encode(projects) { defaults.set(d, forKey: pKey) }
        if let d = try? enc.encode(tasks) { defaults.set(d, forKey: tKey) }
        if let d = try? enc.encode(habits) { defaults.set(d, forKey: hKey) }
        if let d = try? enc.encode(dayPlans) { defaults.set(d, forKey: dKey) }
        if let d = try? enc.encode(settings) { defaults.set(d, forKey: sKey) }
    }

    private func load() {
        let dec = JSONDecoder()
        if let d=defaults.data(forKey:pKey), let x=try? dec.decode([Project].self,from:d){projects=x}
        if let d=defaults.data(forKey:tKey), let x=try? dec.decode([ExecutiveTask].self,from:d){tasks=x}
        if let d=defaults.data(forKey:hKey), let x=try? dec.decode([Habit].self,from:d){habits=x}
        if let d=defaults.data(forKey:dKey), let x=try? dec.decode([DayPlan].self,from:d){dayPlans=x}
        if let d=defaults.data(forKey:sKey), let x=try? dec.decode(AppSettings.self,from:d){settings=x}
    }

    private func migrateReservedGreenProjects() {
        var changed = false
        for i in projects.indices where projects[i].color == .green {
            projects[i].color = .blue
            changed = true
        }
        if changed { save() }
    }

    // Preserve existing V4.3 data on first V5 launch.
    private func migrateV43IfNeeded() {
        guard projects.isEmpty && tasks.isEmpty && habits.isEmpty else { return }
        struct OldProject: Codable { var id:UUID; var name:String; var dailyMinutes:Int; var color:ProjectColor; var isClosed:Bool }
        struct OldTask: Codable { var id:UUID; var title:String; var duration:Int; var projectID:UUID?; var priority:String; var isCompleted:Bool; var createdAt:Date }
        struct OldHabit: Codable { var id:UUID; var name:String; var duration:Int; var weekdays:Set<Int>; var isEnabled:Bool }
        let dec=JSONDecoder()
        if let d=defaults.data(forKey:"alsagier.v43.projects"), let old=try? dec.decode([OldProject].self,from:d) {
            projects=old.map{Project(id:$0.id,name:$0.name,dailyMinutes:$0.dailyMinutes,preferredBlockMinutes:30,color:$0.color,priority:.normal,mode:.taskBased,status:$0.isClosed ? .closed:.active)}
        }
        if let d=defaults.data(forKey:"alsagier.v43.tasks"), let old=try? dec.decode([OldTask].self,from:d) {
            tasks=old.map{ExecutiveTask(id:$0.id,title:$0.title,duration:$0.duration,projectID:$0.projectID,priority:WorkPriority(rawValue:$0.priority.capitalized) ?? .normal,isCompleted:$0.isCompleted,createdAt:$0.createdAt)}
        }
        if let d=defaults.data(forKey:"alsagier.v43.habits"), let old=try? dec.decode([OldHabit].self,from:d) {
            habits=old.map{Habit(id:$0.id,name:$0.name,duration:$0.duration,mode:.fixed,weekdays:$0.weekdays,isEnabled:$0.isEnabled)}
        }
        save()
    }
}
