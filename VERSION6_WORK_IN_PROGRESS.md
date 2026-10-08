# CapJour 6.0 — Source checkpoint, NOT a TestFlight release

Source baseline: CapJour 5.1 Build 20. Existing signing, identifiers, and persistent storage keys are retained.

Implemented or present in the working source:
- Version 6.0 / build 21 metadata.
- Colored selected bottom navigation, including Repeat for Habits.
- Tasks: Active default and Total/Active/Closed counts.
- Card-game habit icon recognition and editable 120-minute suggestion.
- Cascading More navigation and Emotion Check-in prototype.
- Recurrence schema backward-compatible with existing habits; new weekly/2/3/4-week/calendar-month choices, anchor date, next due labels, and due gating for nonweekly fixed and flexible habits.

Known limitation: Existing weekly flexible multi-session scheduler is preserved rather than rewritten. Nonweekly flexible cycles currently select a deterministic day, not an adaptive free-day choice. Calendar-month fixed recurrence uses the anchor's week ordinal. These behaviors need product validation and tests.

Not complete:
- Full Arabic/English localization and RTL verification.
- Robust undo of task/habit completions and historical corrections.
- Apple Health heart-rate and sleep analysis, confidence explanations and weekly review.
- Full integration tests, Xcode compilation and physical iPhone validation.

`swiftc -frontend -parse` is syntax-only and does not establish a successful iOS build. DO NOT UPLOAD THIS CHECKPOINT TO TESTFLIGHT.

Checkpoint 3: Added persisted interface-language preference (Automatic/English/Arabic), locale and layout direction injection at app root. This is infrastructure only: not a complete translation of all user-visible strings and not RTL visual QA. Swift frontend parsing passed; iOS compilation not available in this Linux environment.
