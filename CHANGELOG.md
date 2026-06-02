# Changelog

## v0.4.0 - Local Test Build

- Added a macOS app icon based on the original GPL-3.0 Windows icon asset from ic3w0lf22/Roblox-Account-Manager.
- Added DMG packaging with an Applications shortcut for easier installation.
- Added a polished DMG Finder layout with a compact window and drag-to-Applications arrow background.
- Moved Game ID / Place ID and Job ID / VIP code from per-account fields to global Settings launch fields.
- Moved the global launch target fields into the account detail view directly above the Launch Roblox button.
- Updated launch behavior so every selected account uses the shared launch target.
- Removed GitHub Actions workflow so repository pushes do not consume CI minutes.

## v0.3.1 - Multi-Instance Cleanup

- Reworked multi-instance copies to be temporary per-launch app copies.
- Added automatic cleanup after the launched Roblox instance exits.
- Added a Settings button to clean leftover multi-instance copies manually.
- Documented cleanup behavior and manual cleanup steps.

## v0.3.0 - Experimental Multi-Instance

- Added experimental native macOS multi-instance launch support.
- Added a Swift `MultiInstanceService` that creates managed Roblox app copies and patches only those copies.
- Added ad-hoc signing for managed Roblox app copies after plist patching.
- Added automatic cleanup of managed Roblox app copies after the launched instance exits.
- Added a Settings button to clean leftover multi-instance copies.
- Added best-effort Roblox single-instance semaphore cleanup for multi-instance launches.
- Enabled the multi-instance setting with an in-app warning.
- Added README documentation and manual testing steps for multi-instance behavior.
- Added tests for managed Roblox app copy preparation.

## v0.2.0 - Launch Flow Cleanup

- Removed `Alias` and `User ID` fields from the macOS app.
- Reworded the account secret field to `.ROBLOSECURITY` token.
- Moved `Allow account launching` and `Allow roblox-player launch URLs` into normal launch settings.
- Added a usage guide to the README that explains the saved game/place ID and token flow.
- Bumped bundle metadata and release packaging to `0.2.0`.

## v0.1.0 - Initial macOS Port

- Added native SwiftUI macOS account manager UI.
- Added account list, account search, add/edit/delete, settings, logs, and metadata backup/export/import.
- Added macOS Keychain storage for Roblox cookies and optional passwords.
- Added guarded Roblox launch support using the macOS `roblox-player:` URL handler when explicitly enabled.
- Added GPL-3.0 license, attribution notice, README, tests, and GitHub Actions build/test workflow.
- Documented unsupported Windows-only upstream features and risky features disabled by default.
- Packaged release app as a universal `arm64` + `x86_64` bundle with ad-hoc signing.
