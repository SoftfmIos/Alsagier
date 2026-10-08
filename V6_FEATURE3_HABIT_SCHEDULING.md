# Version 6.0 — Feature 3: Habit Scheduling

Source: CapJour-V6.0-Health-Intelligence-Source-NOT-RELEASE-READY.zip.

## Changed
- HabitDueEngine: anchored weekly, two-, three-, four-week and calendar-month eligibility.
- Flexible weekly target: deterministic, distributed due days, rather than every available day.
- Flexible multi-week/monthly: one selected due day per eligible cycle.
- Fixed monthly: selected weekday in the ordinal week, clamped when month has fewer occurrences.
- AppStore: due-only placement and skip previously completed occurrences; preserved slot allocator, calendar/prayer priority, Work End, existing source IDs and stored completion history.
- Habits editor: weekly count only shown for weekly flexible habits; other cycles explicitly display one occurrence.

## Important limitations
- Flexible dates are deterministic, not dynamically optimized by checking every future calendar/prayer conflict. If a due day has no available slot, the occurrence is not automatically moved to another day.
- Existing weekly habits retain weekly default. Old persisted flexible habits now follow deterministic weekly due dates; verify their expected cadence on device.
- Syntax parsing and archive validation do not prove iOS compilation or end-to-end Time Engine correctness.
- Other Version 6 features remain incomplete. Not release-ready.
