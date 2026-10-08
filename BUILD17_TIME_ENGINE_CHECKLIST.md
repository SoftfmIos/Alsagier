# CapJour Build 17 — Time Engine Regression Gate

This checklist is a release gate. A later feature must not regress these behaviors.

## Hard constraints
- Calendar and prayer blocks never move or overlap flexible work.
- A prayer with the same name within five minutes is one semantic prayer, not two blocks.
- Project work never schedules after Work End unless the user changes Work End and refreshes.
- Re-open rebuilds unfinished flexible work from Now + 10 minutes.
- Completed history remains historical and consumes the project's daily allocation.
- The engine may intentionally leave buffer time.

## Personal learning
- Learning starts with every completed work insight and historical day plan.
- With low evidence, explicit settings dominate.
- With >=3 comparable observations, time-of-day history may influence placement.
- With >=4 project observations, learned block duration may influence safe splitting/continuous blocks.
- Splits remain one task and are labeled Part x/y • Split for your work pattern.
- Explicit Priority, Daily Allocation, preferred duration and Work End are never silently changed.
- High priority is considered first even when history prefers another time.
- Context grouping is influenced by the user's own stay-vs-switch completion history.

## Capacity honesty
- Never fill a slot merely because it is empty.
- Work that cannot fit remains unscheduled/carry-forward rather than being placed in the past or beyond Work End.

## Health
- Refresh shows progress while reading.
- Manual Refresh confirms the values actually read: steps, walking minutes and workout minutes/status.
- Walking completes when steps OR walking minutes reaches target.
- Gym Health data is informational; it does not silently mark Gym Done.

## Live Activity / fixed data
- Maghrib/Isha/etc. cannot appear twice because refreshed prayer times differ by one minute.
- Live Activity receives true start/end values; no zero-duration prayer.
- Lock Screen remains readable in system light/dark rendering.
