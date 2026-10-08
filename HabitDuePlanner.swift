import Foundation

/// Stable, repeatable due dates. Does not persist or change existing Habit data.
enum HabitDuePlanner {
    static func isScheduled(_ habit: Habit, on date: Date, calendar: Calendar = .current) -> Bool {
        guard habit.isEnabled else { return false }
        if habit.mode == .fixed { return habit.weekdays.contains(calendar.component(.weekday, from: date)) }
        let count = min(7, max(0, habit.timesPerWeek))
        guard count > 0 else { return false }
        // The calendar's firstWeekday is respected (Saudi / device locale).
        let weekday = calendar.component(.weekday, from: date)
        let offset = (weekday - calendar.firstWeekday + 7) % 7
        let dueOffsets = Set((0..<count).map { ($0 * 7) / count })
        return dueOffsets.contains(offset)
    }

    static func nextDue(_ habit: Habit, after date: Date = Date(), calendar: Calendar = .current) -> Date? {
        guard habit.isEnabled else { return nil }
        let today = calendar.startOfDay(for: date)
        for step in 0..<15 {
            guard let candidate = calendar.date(byAdding: .day, value: step, to: today) else { continue }
            if isScheduled(habit, on: candidate, calendar: calendar) { return candidate }
        }
        return nil
    }
}
