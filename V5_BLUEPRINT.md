# Alsagier V5 — Approved Product Blueprint

## Product purpose
Alsagier is a personal executive assistant for time management, focus and productivity.
It should answer: What should I focus on now, for how long, and what is next?

## Daily lifecycle
- Start My Day can be pressed only once per day.
- Flexible work begins 10 minutes after Start My Day.
- The generated day persists; reopening the app does not require starting again.
- End My Day is manual. If not pressed, auto-close at the configured work-end time.
- Default work-end time: 4:00 PM; configurable.
- Personal routines may be scheduled after work, up to a configurable horizon (default 11:00 PM).
- Past days are frozen read-only snapshots.

## Today / focus
- Prominent WHAT NOW card: current project/task, remaining time, and NEXT block.
- Full colored timeline below.
- Calendar events are fixed.
- Prayer periods are fixed/protected and visually distinct with a tinted protected band.
- Project/task work never overlaps Calendar or prayer protection.
- Today Summary includes Calendar time, focus/project time, habits/routines, communication and remaining usable capacity.
- Day/evening visual divider, using sunset/prayer timing where available.
- Swipe a flexible block to Complete.
- +15 minutes action extends current work and rebalances only future flexible blocks.
- Completing early automatically pulls the next eligible work forward.
- Past and fixed blocks never move.

## Projects
- Projects are editable.
- Persistent project color is used strongly in project UI and all its task/focus blocks.
- Status: Active, Frozen, Closed.
- Frozen = retained but receives no scheduling.
- Priority: High, Normal, Low.
- Daily allocation/target: 15/30/45/60/90/120 minutes.
- Mode: Task-based or Continuous.
- Continuous projects do not require artificial tasks.
- Preferred focus-block size: 15/30/45/60/90 minutes.
- Continuous allocation may be split across the day and can continue another day.
- Minimize context switching; favor longer focus sessions when possible.

## Tasks
- Tasks persist until explicitly completed.
- Default duration: 15 minutes; selectable 15/30/45/60/90.
- Tasks can belong to a project and inherit project color.
- Multiple tasks from the same project can be used during its allocated project time.
- Completing a task should naturally move to the next task without rebuilding the whole day.
- Unfinished tasks carry forward.

## Adaptive scheduler
Priority order:
1. Fixed Calendar commitments
2. Prayer/protected periods
3. High-priority eligible work
4. Normal/Low eligible project allocation
5. Important habits/routines
6. Calls/email and small-gap work
Use small gaps for communication/small tasks and protect longer uninterrupted windows for deep work.
Do not mark an impossible overloaded day as failure; schedule realistic capacity.

## Habits / intelligent routines
- Habit duration: 15/30/45/60/90.
- Scheduling mode:
  - Fixed days: user selects weekdays.
  - Alsagier chooses: user chooses frequency per week; scheduler finds suitable days/times.
- Flexible frequency: 1–7 times/week.
- Earliest/latest allowed time.
- Preferred period: Anytime/Morning/Afternoon/Evening.
- Importance: High/Normal/Optional.
- Spread sessions through the week when practical.
- Gym is handled as a flexible habit, e.g. 4x/week, 30/45/60 minutes, schedulable up to 11 PM.
- Weekly progress shown, e.g. Gym 2/4.

## Calls and Email
- No person/name entry required.
- Settings choose Calls and Email block durations: Off/15/30/45/60.
- Prefer two sensible communication windows, morning and afternoon, using free/small gaps.
- Do not sacrifice protected or high-priority focus time when a reasonable alternative exists.

## Notifications
- Local reminder before each scheduled actionable block.
- Default: 2 minutes before.
- Setting: Off/2/5/10/15 minutes.
- When future schedule changes, cancel obsolete reminders and create updated reminders.
- Workday-end notification if auto-close occurs.

## Lock Screen / Dynamic Island
- Live Activity should show NOW, remaining time, and NEXT.
- Use the current project/block color as visual identity where Apple UI permits.
- Dynamic Island compact view stays minimal; expanded view shows current + next.
- Do not show the entire daily schedule on the Lock Screen.
- Live Activity is a separate WidgetKit/ActivityKit extension and therefore requires its own extension bundle ID/signing setup before TestFlight.

## Later / not required for first V5 build
- Apple Watch companion.
- Learning energy patterns automatically.
- Remote APNs backend.
- More advanced productivity insights.

## Branding
Alsagier By Softfm
Main bundle ID: com.softfm.alsagierapp
