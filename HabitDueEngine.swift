import Foundation

/// Determines occurrence dates independently from the Time Engine's free-slot search.
/// Existing saved habits remain weekly by default; calendar months are not four-week periods.
enum HabitDueEngine {
    static func cycleInterval(for habit: Habit, on date: Date, calendar: Calendar = .current) -> DateInterval? {
        let day = calendar.startOfDay(for: date)
        let anchor = calendar.startOfDay(for: habit.recurrenceAnchor)
        guard day >= anchor else { return nil }
        if habit.recurrence == .monthly {
            guard let month = calendar.dateInterval(of: .month, for: day),
                  let anchorMonth = calendar.dateInterval(of: .month, for: anchor),
                  month.start >= anchorMonth.start else { return nil }
            return month
        }
        guard let anchorWeek = calendar.dateInterval(of: .weekOfYear, for: anchor),
              let currentWeek = calendar.dateInterval(of: .weekOfYear, for: day) else { return nil }
        let elapsed = calendar.dateComponents([.weekOfYear], from: anchorWeek.start, to: currentWeek.start).weekOfYear ?? -1
        let weeks: Int
        switch habit.recurrence {
        case .weekly: weeks = 1
        case .everyTwoWeeks: weeks = 2
        case .everyThreeWeeks: weeks = 3
        case .everyFourWeeks: weeks = 4
        case .monthly: weeks = 1
        }
        guard elapsed >= 0 && elapsed % weeks == 0 else { return nil }
        // One eligible week per multi-week cycle; not every week in that cycle.
        return currentWeek
    }

    static func cycleStart(for habit: Habit, on date: Date, calendar: Calendar = .current) -> Date? {
        cycleInterval(for: habit, on: date, calendar: calendar)?.start
    }

    static func isDue(_ habit: Habit, on date: Date, calendar: Calendar = .current) -> Bool {
        guard habit.isEnabled, let interval = cycleInterval(for: habit, on: date, calendar: calendar) else { return false }
        let day = calendar.startOfDay(for: date)
        if habit.mode == .fixed {
            guard habit.weekdays.contains(calendar.component(.weekday, from: day)) else { return false }
            if habit.recurrence == .monthly {
                // Match the selected weekday's ordinal week; clamp to the last occurrence if needed.
                let anchor = calendar.startOfDay(for: habit.recurrenceAnchor)
                let ordinal = (calendar.component(.day, from: anchor) - 1) / 7
                let weekday = calendar.component(.weekday, from: day)
                let first = interval.start
                let firstWeekday = calendar.component(.weekday, from: first)
                let offset = (weekday - firstWeekday + 7) % 7
                guard let initial = calendar.date(byAdding: .day, value: offset, to: first) else { return false }
                var selected = calendar.date(byAdding: .day, value: ordinal * 7, to: initial) ?? initial
                if selected >= interval.end { selected = calendar.date(byAdding: .day, value: -7, to: selected) ?? initial }
                return calendar.isDate(selected, inSameDayAs: day)
            }
            return true
        }
        // Flexible means one *chosen date*, not every free time slot or every day.
        // Weekly targets can have several distinct due days, distributed through the week.
        if habit.recurrence == .weekly {
            let target = max(1, min(7, habit.timesPerWeek))
            let days = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: interval.start) }
            let offsets = (0..<target).map { ($0 * 7) / target }
            return offsets.contains { calendar.isDate(days[$0], inSameDayAs: day) }
        }
        if habit.recurrence == .monthly {
            let anchorDay = calendar.component(.day, from: habit.recurrenceAnchor)
            let lastDay = calendar.range(of: .day, in: .month, for: day)?.count ?? 28
            let selected = calendar.date(byAdding: .day, value: min(anchorDay, lastDay) - 1, to: interval.start) ?? interval.start
            return calendar.isDate(selected, inSameDayAs: day)
        }
        // For a multi-week cycle, prefer the anchor weekday in the eligible week.
        let weekday = calendar.component(.weekday, from: habit.recurrenceAnchor)
        return calendar.component(.weekday, from: day) == weekday
    }

    static func nextDue(_ habit: Habit, after date: Date = Date(), calendar: Calendar = .current) -> Date? {
        let today = calendar.startOfDay(for: date)
        for offset in 0..<400 {
            guard let candidate = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            if isDue(habit, on: candidate, calendar: calendar) { return candidate }
        }
        return nil
    }
}
