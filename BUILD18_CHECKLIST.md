# CapJour Build 18 regression checklist

Golden baseline: Build 17 TIME ENGINE. Do not replace scheduler semantics.

## Build/version
- Marketing 5.1; build 18.
- Bundle IDs unchanged.

## Scheduler hard rules
- Calendar and prayer blocks remain locked.
- Work End is absolute.
- Project priority and Daily Allocation semantics unchanged.
- No completed/skipped source is resurrected.
- Re-open/Refresh never schedules flexible work in the past.

## Smart Habits
- Arabic/English title classification is local and automatic.
- No icon/category picker.
- Reading uses book; relaxation uses mind/body/relax; walking uses walk; workout uses dumbbell.
- Tennis/Padel/Squash share racket icon; Football uses soccer ball.
- Explicit title duration overrides category default.
- Walking uses HealthKit and >=75% of steps OR walking minutes = Achieved; >=100% = Completed.
- Weekly count persists through HabitCompletion.

## Insights/History
- Dashboard has 7/30/All Time and Completion/Time Accuracy/Emotion.
- Main Insights does not render raw unbounded history.
- History lists days; tap opens final timeline details.
- Existing WorkInsight and DayPlan data decode without migration loss.

## Live Activity
- High-contrast system background.
- Stable time display (no expired countdown spinner).
- Current/primary plus one Up Next only.
- App foreground/actions refresh ActivityKit state.

## Existing features
- Dad Jokes remain offline and settings preserved.
- Backup/restore remains compatible with new optional HabitCompletion fields.
- HealthKit, Calendar, Prayer, notifications, Projects, Tasks compile and retain behavior.
