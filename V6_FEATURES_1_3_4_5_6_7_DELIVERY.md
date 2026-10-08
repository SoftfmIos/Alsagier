# CapJour 6.0 — Features 1, 3, 4, 5, 6, 7 development source

Based on the most recent Feature 3 habit scheduling source (including Health Intelligence).

## Changes in this source
- Feature 1: missed flexible habits may roll forward to later dates within the eligible cycle, if no earlier occurrence was scheduled or completed; due-day constraints retained.
- Feature 3: explicit historical completion correction UI and persisted correction audit log, without rebuilding past days.
- Feature 4: new completion insights carry a stable scheduleBlockID; Undo removes the exact corresponding insight instead of matching by task and date. Legacy insights decode with absent IDs.
- Feature 5: Apple Health sleep samples retrieved for the reporting period; overlapping asleep stages are merged; per-session preceding-night sleep and a cautious emotion comparison are displayed when enough observations exist.
- Feature 6: duration suggestions based on at least three historical sessions; changes require explicit Apply in Weekly Review.
- Feature 7: Weekly Review now reports recorded habit completions and distinct habits, and offers duration suggestions.

## Important limitations / follow-up
- **Not an iOS SDK compilation**: swiftc -frontend -parse checks grammar only, and no Xcode or iOS SDK is available here.
- A prior-day correction is deliberately recorded, but correction logs are saved locally and are not yet part of the existing manual backup export format.
- For legacy insight records without scheduleBlockID, precise linkage to an old block cannot be guaranteed. The new precise Undo linkage applies to new completions.
- Flexible rollover can only be evaluated when the user opens/builds a later day; it is not a background multi-day scheduler and does not guarantee placement if every later day is full.
- Sleep comparison is observational and requires at least eight rated sessions with sufficient sleep data. No stress diagnosis is made.
- Full Arabic/English localization (previous feature 2) is not included in this requested update.
- Full Codemagic compilation, regression tests, data migration and iPhone testing remain necessary.
- Marketing version 6.0; build 21 unchanged. If Build 21 has already been uploaded to App Store Connect, increment build number before uploading a new binary.

DO NOT REPRESENT THIS SOURCE AS A TESTFLIGHT-READY RELEASE WITHOUT A SUCCESSFUL IOS BUILD AND REGRESSION TESTS.
