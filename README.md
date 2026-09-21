# Alsagier V3 — Native iPhone Calendar Test

Developer branding: **Alsagier By Softfm**

This is the first native iOS milestone. It intentionally focuses on one job:
request Apple Calendar permission with EventKit and display today's timed events.

## What V3 does
- Native SwiftUI interface
- Uses Apple's EventKit
- Requests full Calendar event access on iOS 17+
- Reads today's timed events
- Displays event title, start/end time, calendar name
- Treats displayed appointments visually as locked/fixed blocks

## Windows + Codemagic
You do not need Xcode on Windows.

1. Create a PRIVATE GitHub repository.
2. Put all files from this folder in the repository.
3. Connect the repository to Codemagic.
4. Codemagic detects `codemagic.yaml`.
5. Run `Alsagier V3 iOS Build`.

The included first workflow compiles a simulator build WITHOUT Apple signing.
This proves the source compiles on a real macOS/Xcode build machine.

## Important: installing on your real iPhone
A simulator build cannot be installed on an iPhone.

To test real Calendar permission on your iPhone, the next step is Apple code
signing/provisioning. Codemagic can build a signed IPA after your Apple
Developer/App Store Connect signing configuration is connected.

Do NOT commit certificates, private keys, passwords, API keys, or App Store
Connect private keys into GitHub.

## Xcode project generation
This repository uses XcodeGen. `project.yml` generates `AlsagierV3.xcodeproj`
on the Mac build machine, so a Windows user can maintain the project without
running Xcode locally.
