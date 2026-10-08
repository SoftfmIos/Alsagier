# Build 21 compiler fix

Corrected AppStore.swift fixed-habit filter nested closure: explicit `habit` and `completion` arguments replace invalid nested `$0`.

This is a source-only compiler correction; version remains 6.0 (21), with no scheduling-policy change.

The ZIP has been checked structurally, but requires Codemagic/Xcode compilation and on-device testing.
