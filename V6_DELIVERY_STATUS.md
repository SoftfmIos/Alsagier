# CapJour 6.0 source — development checkpoint 4

Base: CapJour-V6.0-Build21-Integration-INCOMPLETE.zip
Version remains 6.0 / Build 21, bundle com.softfm.alsagierapp.

New changes in this checkpoint:
- Undo for completed blocks in the current active day, including a visible Undo control and correction via completed timeline cards.
- Undo updates task status, removes the matching completion insight, reverses manually recorded habit completion and travel completion, and rebalances future blocks.
- Weekly Review page with seven-day session totals, recorded focus time, missing emotion counts, emotion average and duration accuracy.
- Personal Energy page with time-of-day/emotion patterns and explicit data sufficiency caveats. It does not yet correlate heart rate or sleep.

Previously present: navigation colors, cascading More, task counters and filters, language preference, recurrence groundwork, emotion check-in.

Not completed or validated:
- Full translation of all user-facing text and RTL review.
- Timestamped HealthKit heart rate/sleep correlation and evidence/confidence framework.
- Flexible habit recurrence edge-case tests, especially historic dates and monthly cycles.
- Persistent provenance linking insights to each block; undo matches the latest same-day session and must be tested with repeated task sessions.
- Historical correction workflow and comprehensive migration/regression tests.
- Xcode iOS SDK typechecking, device testing, and Codemagic compilation.

This is not a complete release. Do not upload as final TestFlight build.
