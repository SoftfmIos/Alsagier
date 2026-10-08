# CapJour / Alsagier 6.0 — clean rebuild from V5.1 Build 20

Source: user-uploaded `CapJour-V5.1-Build20.zip`. No prior V6 checkpoint was used.

- Changed tab icons (Today time blocks, Projects stacked layers, Tasks checkmark, Habits repeat, More grid).
- Added cascading More entry view leading to the original fully functional settings/backup/permissions screen, Insights & History, About.
- Added deterministic weekly due-day calculation for flexible habits, respecting Calendar.firstWeekday.
- Prevented already-completed habits from being reinserted into today by scheduler.
- Added Next Due date to the Habits page (paused habits show Paused).
- Retained V5 stored settings keys, data models, bundle identifiers, engine structure, assets and Live Activity.
- Marketing version 6.0, build 21 (increment this build number for additional TestFlight uploads).

**NOT COMPILED ON XCODE:** This environment has no Apple iOS SDK or Xcode. Codemagic archive, signing, and device regression tests remain required before TestFlight distribution. No IPA is included.
