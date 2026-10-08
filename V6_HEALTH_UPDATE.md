# CapJour 6.0 — Apple Health Intelligence update

Added `PersonalEnergyHealth.swift` and connected Personal Energy page to read-only HealthKit queries for heart rate, sleep and workouts. Heart-rate samples are matched to recent completed sessions; workout-overlap sessions are excluded from simple time-of-day comparisons. Missing readings and data insufficiency are disclosed. Sleep hours shown for last 24h; this is not a longitudinal sleep-performance correlation. No automatic rescheduling or stress diagnosis.

Status: Swift syntax parsing completed; no Xcode/iOS SDK compile or on-device test was performed. Other Version 6 requirements remain incomplete. This ZIP is NOT RELEASE READY.

HealthKit permissions: app already contains HealthKit entitlement. Main app provisioning profile must support it. User must approve reading heart rate, sleep and workouts. WHOOP data is only available if shared to Apple Health.
