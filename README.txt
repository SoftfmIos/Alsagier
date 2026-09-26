Alsagier V5 App Store validation fix

Replace these paths in the V5 repository:
1. /Info.plist
2. /AlsagierLiveActivity/Info.plist
3. /Assets.xcassets/AppIcon.appiconset/  (replace the entire folder)

This fixes:
- 90360: Live Activity extension missing CFBundleName
- 90713: Main app missing CFBundleIconName
- 90022: Required iPhone 120x120 icon not emitted

Do not change Bundle IDs, certificates, identifiers, provisioning profiles, project.yml, or codemagic.yaml for these errors.

BUILD 7 (5.1)
- Tasks: All / Active / Closed / Project filters.
- Today: custom swipe actions that work inside the Today ScrollView; swipe right Done, swipe left +15m / Skip, tap for action menu.
- Prayer reminders use PrayerChime.wav.
- Project editor uses color circles instead of color names.
- Apple Health walking tracking: consolidated steps plus walking-workout minutes; either target can auto-complete the habit; progress can exceed 100%; weekly completion count retained in day history.
- Smart flexible habits continue to use remaining weekly requirement and available days.
- Live Activity redesigned for clearer current item, countdown, four upcoming items, richer subtitles/progress and Lock Screen quick links for Done/+15/Skip.
- Version remains 5.1; build number is 7.

IMPORTANT BEFORE BUILDING BUILD 7:
Enable HealthKit for the main App ID com.softfm.alsagierapp in Apple Developer and regenerate/re-upload the main App Store provisioning profile. No change is required to the Live Activity App ID/profile for HealthKit.
