import Foundation
import Combine

@MainActor
final class AppStore: ObservableObject {
    @Published var projects: [Project] = []
    @Published var tasks: [ExecutiveTask] = []
    @Published var habits: [Habit] = []
    @Published var dayPlans: [DayPlan] = []
    @Published var insights: [WorkInsight] = []
    @Published var habitCompletions: [HabitCompletion] = []
    @Published var settings = AppSettings()

    private let defaults = UserDefaults.standard
    private let pKey = "alsagier.v5.projects"
    private let tKey = "alsagier.v5.tasks"
    private let hKey = "alsagier.v5.habits"
    private let dKey = "alsagier.v5.dayplans"
    private let sKey = "alsagier.v5.settings"
    private let iKey = "capjour.v5.insights"
    private let hcKey = "capjour.v5.habitCompletions"
    private let dadShownKey = "capjour.v5.dadJokes.shown"
    private let migrationKey = "alsagier.v5.migratedV43"

    init() {
        load()
        migrateV43IfNeeded()
        migrateReservedGreenProjects()
        autoCloseExpiredDay()
        removeDuplicateFixedBlocksFromStoredPlans()
        migrateHabitCompletionsFromPlans()
    }


    // Calendar/prayer inputs can receive fresh UUIDs on every refresh. Older builds could
    // therefore persist two visually identical fixed blocks. Normalize stored plans by
    // semantic identity (kind/title/start/end), so an already-saved duplicate is repaired
    // automatically on launch as well as during later refreshes.
    private func deduplicatedFixedBlocks(_ blocks: [ScheduleBlock]) -> [ScheduleBlock] {
        var result: [ScheduleBlock] = []
        for block in blocks.sorted(by: { $0.start < $1.start }) {
            if block.kind == .prayer || block.kind == .calendar {
                if let index = result.firstIndex(where: { existing in
                    existing.kind == block.kind &&
                    existing.title == block.title &&
                    abs(existing.start.timeIntervalSince(block.start)) < 60 &&
                    abs(existing.end.timeIntervalSince(block.end)) < 60
                }) {
                    // Preserve any state that may already have been recorded.
                    result[index].isCompleted = result[index].isCompleted || block.isCompleted
                    result[index].isSkipped = result[index].isSkipped || block.isSkipped
                    continue
                }
            }
            result.append(block)
        }
        return result
    }

    private func removeDuplicateFixedBlocksFromStoredPlans() {
        var changed = false
        for index in dayPlans.indices {
            let cleaned = deduplicatedFixedBlocks(dayPlans[index].blocks)
            if cleaned.count != dayPlans[index].blocks.count {
                dayPlans[index].blocks = cleaned
                changed = true
            }
        }
        if changed { save() }
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
    func updateTask(_ task: ExecutiveTask) {
        guard let i = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        var value = task
        value.title = value.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.title.isEmpty else { return }
        tasks[i] = value
        save()
    }
    func duplicateTask(_ task: ExecutiveTask) {
        var copy = task
        copy.id = UUID()
        copy.title = task.title + " Copy"
        copy.isCompleted = false
        copy.createdAt = Date()
        tasks.append(copy)
        save()
    }
    func deleteTask(_ task: ExecutiveTask) { tasks.removeAll {$0.id == task.id}; save() }

    // Switch only the selected flexible time block. The rest of today's plan is left alone.
    // If the user switches away from a task, that original task remains open for a later block/day.
    func switchWork(blockID: UUID, toTask task: ExecutiveTask) {
        guard let di = todayIndex,
              dayPlans[di].endedAt == nil,
              let bi = dayPlans[di].blocks.firstIndex(where: { $0.id == blockID }),
              !dayPlans[di].blocks[bi].isLocked else { return }
        let project = task.projectID.flatMap { id in projects.first(where: { $0.id == id }) }
        dayPlans[di].blocks[bi].sourceID = task.id
        dayPlans[di].blocks[bi].title = task.title
        dayPlans[di].blocks[bi].subtitle = project?.name ?? "Task"
        dayPlans[di].blocks[bi].kind = .task
        dayPlans[di].blocks[bi].projectColor = project?.color
        dayPlans[di].blocks[bi].isCompleted = false
        dayPlans[di].blocks[bi].isSkipped = false
        save()
    }

    func switchWork(blockID: UUID, toProject project: Project) {
        guard let di = todayIndex,
              dayPlans[di].endedAt == nil,
              let bi = dayPlans[di].blocks.firstIndex(where: { $0.id == blockID }),
              !dayPlans[di].blocks[bi].isLocked else { return }
        dayPlans[di].blocks[bi].sourceID = project.id
        dayPlans[di].blocks[bi].title = project.name
        dayPlans[di].blocks[bi].subtitle = "Project work"
        dayPlans[di].blocks[bi].kind = .project
        dayPlans[di].blocks[bi].projectColor = project.color
        dayPlans[di].blocks[bi].isCompleted = false
        dayPlans[di].blocks[bi].isSkipped = false
        save()
    }

    func addHabit(_ h: Habit) { habits.append(h); save() }
    func updateHabit(_ h: Habit) {
        if let i = habits.firstIndex(where: {$0.id == h.id}) { habits[i] = h; save() }
    }
    func deleteHabit(_ h: Habit) { habits.removeAll {$0.id == h.id}; save() }
    func toggleHabit(_ h: Habit) {
        if let i = habits.firstIndex(where: {$0.id == h.id}) { habits[i].isEnabled.toggle(); save() }
    }

    func weeklyHabitProgress(_ habit: Habit, on date: Date = Date()) -> (completed: Int, target: Int) {
        let interval = Calendar.current.dateInterval(of: .weekOfYear, for: date)
        return (completedHabitCount(habit, in: interval), habit.timesPerWeek)
    }

    func applyWalkingHealth(steps: Int, walkingMinutes: Int, calendar: [ScheduleBlock], prayers: [ScheduleBlock]) {
        guard let di = todayIndex, dayPlans[di].endedAt == nil else { return }
        var completedSomething = false
        var changed = false
        for habit in habits where habit.isEnabled && habit.tracksWalking {
            let stepDone = habit.stepTarget > 0 && steps >= habit.stepTarget
            let minuteDone = habit.walkingMinutesTarget > 0 && walkingMinutes >= habit.walkingMinutesTarget
            let matching = dayPlans[di].blocks.indices.filter {
                dayPlans[di].blocks[$0].kind == .habit && dayPlans[di].blocks[$0].sourceID == habit.id
            }
            for bi in matching {
                if (stepDone || minuteDone) && !dayPlans[di].blocks[bi].isCompleted {
                    dayPlans[di].blocks[bi].isCompleted = true
                    recordHabitCompletion(habitID: habit.id, source: "health")
                    completedSomething = true
                }
                let progress = weeklyHabitProgress(habit)
                let text = "\(steps.formatted())/\(habit.stepTarget.formatted()) steps • \(walkingMinutes)/\(habit.walkingMinutesTarget)m • \(progress.completed)/\(progress.target) this week"
                if dayPlans[di].blocks[bi].subtitle != text { dayPlans[di].blocks[bi].subtitle = text; changed = true }
            }
        }
        if completedSomething || changed { save() }
        if completedSomething { rebalanceFuture(calendar: calendar, prayers: prayers) }
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
        recordCompletionInsight(for: dayPlans[di].blocks[bi])
        if block.kind == .task, let source = block.sourceID,
           let ti = tasks.firstIndex(where: {$0.id == source}) { tasks[ti].isCompleted = true }
        if block.kind == .habit, let source = block.sourceID {
            recordHabitCompletion(habitID: source, date: dayPlans[di].date, source: "manual")
            for i in dayPlans[di].blocks.indices where dayPlans[di].blocks[i].sourceID == source && dayPlans[di].blocks[i].kind == .travel {
                dayPlans[di].blocks[i].isCompleted = true
            }
        }
        save()
        rebalanceFuture(calendar: calendar, prayers: prayers)
    }

    private func recordCompletionInsight(for block: ScheduleBlock) {
        guard block.kind == .task || block.kind == .project else { return }
        let project: Project?
        let task: ExecutiveTask?
        if block.kind == .task, let source = block.sourceID {
            task = tasks.first(where: { $0.id == source })
            project = task?.projectID.flatMap { pid in projects.first(where: { $0.id == pid }) }
        } else {
            task = nil
            project = block.sourceID.flatMap { pid in projects.first(where: { $0.id == pid }) }
        }
        let now = Date()
        let actualEnd = max(block.start, min(now, block.end))
        let actual = max(1, Int(ceil(actualEnd.timeIntervalSince(block.start) / 60)))
        insights.append(WorkInsight(projectID: project?.id, projectName: project?.name ?? block.title,
                                    taskID: task?.id, taskName: task?.title ?? block.subtitle, blockKind: block.kind,
                                    date: now, startedAt: block.start, plannedMinutes: block.durationMinutes, actualMinutes: actual, happiness: nil))
    }

    func setHappiness(for insightID: UUID, rating: Int) {
        guard (1...5).contains(rating), let i = insights.firstIndex(where: { $0.id == insightID }) else { return }
        insights[i].happiness = rating
        save()
    }

    func latestInsight(for taskID: UUID) -> WorkInsight? {
        insights.last(where: { $0.taskID == taskID })
    }

    func updateClosedTaskInsight(task: ExecutiveTask, actualMinutes: Int, happiness: Int?) {
        guard task.isCompleted else { return }
        let actual = max(1, actualMinutes)
        let rating = happiness.flatMap { (1...5).contains($0) ? $0 : nil }
        if let i = insights.lastIndex(where: { $0.taskID == task.id }) {
            insights[i].actualMinutes = actual
            insights[i].happiness = rating
            insights[i].taskName = task.title
            if let pid = task.projectID, let project = projects.first(where: { $0.id == pid }) {
                insights[i].projectID = pid
                insights[i].projectName = project.name
            }
        } else {
            let project = task.projectID.flatMap { pid in projects.first(where: { $0.id == pid }) }
            insights.append(WorkInsight(projectID: project?.id, projectName: project?.name ?? "Task",
                                        taskID: task.id, taskName: task.title, blockKind: .task,
                                        date: Date(), plannedMinutes: task.duration, actualMinutes: actual, happiness: rating))
        }
        save()
    }

    var latestUnratedInsight: WorkInsight? { insights.last(where: { $0.happiness == nil }) }

    func skip(_ block: ScheduleBlock, calendar: [ScheduleBlock], prayers: [ScheduleBlock]) {
        guard let di = todayIndex,
              let bi = dayPlans[di].blocks.firstIndex(where: {$0.id == block.id}),
              !block.isLocked else { return }
        dayPlans[di].blocks[bi].isSkipped = true
        if block.kind == .habit, let source = block.sourceID {
            for i in dayPlans[di].blocks.indices where dayPlans[di].blocks[i].sourceID == source && dayPlans[di].blocks[i].start >= Date() {
                dayPlans[di].blocks[i].isSkipped = true
            }
        }
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
        var plan = dayPlans[i]
        plan.endedAt = Date()
        plan.isFrozen = true
        dayPlans[i] = plan
        save()
    }

    // Re-open is intentionally state-only so the UI changes immediately.
    // TodayView refreshes Calendar/prayers and then calls refreshToday.
    func reopenDay() {
        guard let i = todayIndex, Calendar.current.isDateInToday(dayPlans[i].date) else { return }
        var plan = dayPlans[i]
        plan.endedAt = nil
        plan.isFrozen = false
        dayPlans[i] = plan
        save()
    }

    func refreshToday(calendar: [ScheduleBlock], prayers: [ScheduleBlock]) {
        guard isDayActive else { return }
        rebalanceFuture(calendar: calendar, prayers: prayers, after: Date())
    }

    func runningLate15(calendar: [ScheduleBlock], prayers: [ScheduleBlock]) {
        guard isDayActive else { return }
        let now = Date()
        rebalanceFuture(calendar: calendar, prayers: prayers,
                        after: now, scheduleFrom: now.addingTimeInterval(15 * 60))
    }

    func clearScheduleHistory() {
        dayPlans.removeAll { !Calendar.current.isDateInToday($0.date) }
        save()
    }

    func resetAllData() {
        projects = []
        tasks = []
        habits = []
        dayPlans = []
        insights = []
        habitCompletions = []
        settings = AppSettings()
        defaults.set(true, forKey: migrationKey) // never resurrect V4.3 test data after reset
        save()
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

    private func rebalanceFuture(calendar: [ScheduleBlock], prayers: [ScheduleBlock],
                                 after moment: Date = Date(), scheduleFrom: Date? = nil) {
        guard let di = todayIndex, dayPlans[di].endedAt == nil else { return }
        // Clean legacy/stored fixed duplicates before deciding what must be preserved.
        let existing = deduplicatedFixedBlocks(dayPlans[di].blocks)
        if existing.count != dayPlans[di].blocks.count { dayPlans[di].blocks = existing }

        // Preserve anything already started/closed. If travel or its habit has started,
        // preserve the whole travel+habit pair so a refresh/re-open can never add travel twice.
        var preserved = existing.filter { $0.start < moment || $0.isCompleted || $0.isSkipped }
        let activeHabitSources = Set(preserved.compactMap { block -> UUID? in
            guard block.kind == .travel || block.kind == .habit else { return nil }
            return block.sourceID
        })
        preserved += existing.filter { block in
            guard let source = block.sourceID, activeHabitSources.contains(source) else { return false }
            return (block.kind == .travel || block.kind == .habit) &&
                   !preserved.contains(where: { $0.id == block.id })
        }

        let closedSourceIDs = Set(preserved.filter {$0.isCompleted || $0.isSkipped}.compactMap(\.sourceID))
        let pairedHabitSources = Set(preserved.compactMap { block -> UUID? in
            guard block.kind == .travel || block.kind == .habit else { return nil }
            return block.sourceID
        })

        // A task has one source ID for the whole task. If that task is already in the
        // preserved part of today (for example it is currently running), do not let a
        // refresh/re-open create the same task again a minute later.
        let preservedTaskSources = Set(preserved.compactMap { block -> UUID? in
            guard block.kind == .task else { return nil }
            return block.sourceID
        })

        let rebuildStart = scheduleFrom ?? moment
        let rebuilt = buildSchedule(calendar: calendar, prayers: prayers, from: rebuildStart)
            .filter { candidate in
                if preserved.contains(where: {$0.id == candidate.id}) { return false }
                // Calendar and prayer blocks are regenerated with fresh UUIDs. Compare
                // their actual identity instead so Refresh/Re-open cannot duplicate a
                // prayer (for example Isha) or a fixed calendar event already preserved.
                if (candidate.kind == .prayer || candidate.kind == .calendar) &&
                   preserved.contains(where: { existing in
                       existing.kind == candidate.kind &&
                       existing.title == candidate.title &&
                       abs(existing.start.timeIntervalSince(candidate.start)) < 1 &&
                       abs(existing.end.timeIntervalSince(candidate.end)) < 1
                   }) { return false }
                if let source = candidate.sourceID, closedSourceIDs.contains(source) { return false }
                if let source = candidate.sourceID,
                   pairedHabitSources.contains(source),
                   candidate.kind == .travel || candidate.kind == .habit { return false }
                if let source = candidate.sourceID,
                   preservedTaskSources.contains(source),
                   candidate.kind == .task { return false }
                return true
            }
        dayPlans[di].blocks = deduplicatedFixedBlocks(preserved + rebuilt).sorted {$0.start < $1.start}
        save()
    }

    private func buildSchedule(calendar: [ScheduleBlock], prayers: [ScheduleBlock], from start: Date) -> [ScheduleBlock] {
        let cal = Calendar.current
        let day = cal.startOfDay(for: start)
        guard let workEnd = cal.date(bySettingHour: settings.workEndHour, minute: 0, second: 0, of: day),
              let personalEnd = cal.date(bySettingHour: settings.personalEndHour, minute: 0, second: 0, of: day) else { return [] }

        // Fixed inputs may be refreshed more than once and therefore carry new UUIDs.
        // Normalize them by kind/title/time before scheduling flexible work.
        var result: [ScheduleBlock] = []
        for fixed in (calendar + prayers).filter({$0.end > start && $0.start < personalEnd}).sorted(by: {$0.start < $1.start}) {
            let duplicate = result.contains { existing in
                existing.kind == fixed.kind &&
                existing.title == fixed.title &&
                abs(existing.start.timeIntervalSince(fixed.start)) < 1 &&
                abs(existing.end.timeIntervalSince(fixed.end)) < 1
            }
            if !duplicate { result.append(fixed) }
        }
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
            let progress = weeklyHabitProgress(habit, on: day)
            appendHabit(habit, preferred: max(start, earliest), latest: min(latest, personalEnd),
                        subtitle: "\(progress.completed)/\(progress.target) completed this week")
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
        let cal = Calendar.current
        let days = habitCompletions.filter { $0.habitID == habit.id && interval.contains($0.date) }
            .map { cal.startOfDay(for: $0.date) }
        return Set(days).count
    }

    private func recordHabitCompletion(habitID: UUID, date: Date = Date(), source: String = "manual") {
        let cal = Calendar.current
        let day = cal.startOfDay(for: date)
        guard !habitCompletions.contains(where: { $0.habitID == habitID && cal.isDate($0.date, inSameDayAs: day) }) else { return }
        habitCompletions.append(HabitCompletion(habitID: habitID, date: day, source: source))
    }

    private func migrateHabitCompletionsFromPlans() {
        var changed = false
        let cal = Calendar.current
        for plan in dayPlans {
            for block in plan.blocks where block.kind == .habit && block.isCompleted {
                guard let hid = block.sourceID else { continue }
                let day = cal.startOfDay(for: plan.date)
                if !habitCompletions.contains(where: { $0.habitID == hid && cal.isDate($0.date, inSameDayAs: day) }) {
                    habitCompletions.append(HabitCompletion(habitID: hid, date: day, source: "migration")); changed = true
                }
            }
        }
        if changed { save() }
    }

    func nextDadJoke() -> String? {
        guard settings.dadJokesEnabled, !DadJokes.all.isEmpty else { return nil }
        var shown = defaults.array(forKey: dadShownKey) as? [Int] ?? []
        shown = shown.filter { DadJokes.all.indices.contains($0) }
        if shown.count >= DadJokes.all.count { shown.removeAll() }
        let remaining = DadJokes.all.indices.filter { !shown.contains($0) }
        guard let idx = remaining.randomElement() else { return nil }
        shown.append(idx)
        defaults.set(shown, forKey: dadShownKey)
        return DadJokes.all[idx]
    }

    private func flexibleHabitAlreadyPlannedToday(_ habit: Habit) -> Bool {
        todayPlan?.blocks.contains(where: {$0.kind == .habit && $0.sourceID == habit.id}) ?? false
    }

    func makeBackup() -> AlsagierBackup {
        AlsagierBackup(projects: projects, tasks: tasks, habits: habits, dayPlans: dayPlans, insights: insights, habitCompletions: habitCompletions, settings: settings)
    }

    func restoreBackup(_ backup: AlsagierBackup) {
        projects = backup.projects
        tasks = backup.tasks
        habits = backup.habits
        dayPlans = backup.dayPlans
        insights = backup.insights
        habitCompletions = backup.habitCompletions
        settings = backup.settings
        removeDuplicateFixedBlocksFromStoredPlans()
        migrateHabitCompletionsFromPlans()
        save()
    }

    func save() {
        let enc = JSONEncoder()
        if let d = try? enc.encode(projects) { defaults.set(d, forKey: pKey) }
        if let d = try? enc.encode(tasks) { defaults.set(d, forKey: tKey) }
        if let d = try? enc.encode(habits) { defaults.set(d, forKey: hKey) }
        if let d = try? enc.encode(dayPlans) { defaults.set(d, forKey: dKey) }
        if let d = try? enc.encode(insights) { defaults.set(d, forKey: iKey) }
        if let d = try? enc.encode(habitCompletions) { defaults.set(d, forKey: hcKey) }
        if let d = try? enc.encode(settings) { defaults.set(d, forKey: sKey) }
    }

    private func load() {
        let dec = JSONDecoder()
        if let d=defaults.data(forKey:pKey), let x=try? dec.decode([Project].self,from:d){projects=x}
        if let d=defaults.data(forKey:tKey), let x=try? dec.decode([ExecutiveTask].self,from:d){tasks=x}
        if let d=defaults.data(forKey:hKey), let x=try? dec.decode([Habit].self,from:d){habits=x}
        if let d=defaults.data(forKey:dKey), let x=try? dec.decode([DayPlan].self,from:d){dayPlans=x}
        if let d=defaults.data(forKey:iKey), let x=try? dec.decode([WorkInsight].self,from:d){insights=x}
        if let d=defaults.data(forKey:hcKey), let x=try? dec.decode([HabitCompletion].self,from:d){habitCompletions=x}
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
        guard !defaults.bool(forKey: migrationKey) else { return }
        guard projects.isEmpty && tasks.isEmpty && habits.isEmpty else {
            defaults.set(true, forKey: migrationKey)
            return
        }
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
        defaults.set(true, forKey: migrationKey)
        save()
    }
}
