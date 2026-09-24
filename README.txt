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
