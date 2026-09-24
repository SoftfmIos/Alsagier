# Alsagier By Softfm — V5 Source

Main bundle: `com.softfm.alsagierapp`
Live Activity extension: `com.softfm.alsagierapp.liveactivity`

Implemented in this source package:
- once-per-day persisted DayPlan + read-only history
- manual End My Day and expired-day closing
- editable Active/Frozen/Closed projects
- Task-based and Continuous project modes
- persistent project colors
- multiple task blocks per project allocation
- What Now + Complete / Skip / +15 adaptive actions
- Calendar / Focus / Habits summary
- prayer visual protection
- flexible weekly habits (Gym is just a habit) with 1–7x/week, time window, period, importance
- Calls and Email automatic blocks
- default 4 PM work cutoff and 11 PM personal planning horizon
- configurable local block reminder, default 2 minutes
- Live Activity / Dynamic Island extension source

IMPORTANT SIGNING STEP:
Before Codemagic can archive V5 with the Live Activity extension, Apple needs an App ID/profile for:
`com.softfm.alsagierapp.liveactivity`

The main app's existing signing should not be changed.

Technical note:
iOS does not guarantee arbitrary background execution exactly at the work cutoff. Alsagier schedules a local end-of-work notification and finalizes stale day state when the app runs again.

Build validation:
This environment cannot run Apple's Xcode compiler. Static source/configuration checks were run here; Codemagic/Xcode is the authoritative compile/archive validation.
