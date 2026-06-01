# MacOS-RobloxAccountManager

MacOS-RobloxAccountManager is a native macOS port of [Roblox Account Manager](https://github.com/ic3w0lf22/Roblox-Account-Manager). It keeps the same core workflow on macOS: store local account data, search and manage accounts, and launch Roblox for a selected account when macOS and Roblox allow it.

This is a GPL-3.0 project. The upstream Roblox Account Manager project is GPL-3.0, and this port keeps the same license. See [LICENSE](LICENSE) and [NOTICE.md](NOTICE.md).

This project is not affiliated with Roblox Corporation.

## Current Status

`v0.3.1` adds cleanup for temporary multi-instance Roblox app copies while keeping the app focused on local account management and a guarded Roblox launch flow.

## Upstream Analysis Summary

The original Windows project is a WinForms/.NET Framework application. Important upstream components reviewed for this port:

- UI: WinForms main account list, account context menu, settings form, server list, utilities, account control, theme editor.
- Storage: `AccountData.json`, `RecentGames.json`, `RAMSettings.ini`, `RAMTheme.ini`.
- Encryption: Windows DPAPI by default, optional password encryption through libsodium, and a risky plaintext escape hatch.
- Accounts: `.ROBLOSECURITY` token, username, description, group, saved game/place ID, saved job ID, password, last use, browser tracker ID.
- Launching: Roblox authentication ticket request followed by a `roblox-player:` launch URL or Windows executable launch.
- Multi-instance: Windows named mutex behavior around `ROBLOX_singletonMutex`.
- Developer API: optional local HTTP API with methods such as account listing, cookie retrieval, account launch, and account editing.
- Account Control/Nexus: websocket control path plus Lua helper scripts.
- Windows-only parts: registry checks, `.exe`/`.dll` resources, `handle.exe`, DWM/window positioning, process command-line inspection, embedded updater, CefSharp/Puppeteer browser helpers.

## How To Use It

1. Add an account.
2. Paste your own `.ROBLOSECURITY` token into the account form. Use a browser where you are already signed in to Roblox on your own account, then copy the token value from the site cookies.
3. Enter the Roblox game or place number into `Saved Game ID / Place ID`. Game ID is the saved place ID. Open the game page in your browser and copy the number from the address bar.
4. Optionally enter a saved job ID or VIP/private-server code.
5. Open Settings and enable `Allow account launching` and `Allow roblox-player launch URLs`.
6. Select the account and launch it.

## Implemented Features

- Native SwiftUI macOS app.
- Account list with search/filter.
- Add, edit, and delete account records.
- Account metadata fields: username, description, group, saved game/place ID, saved job ID/VIP code, last-used timestamp.
- Secure local secret storage using macOS Keychain.
- Optional password storage in Keychain, disabled by default.
- Metadata import/export as JSON.
- Metadata backup to Application Support.
- Settings view with normal launch toggles and advanced toggles separated out.
- Logs with visible error messages.
- Roblox launch support using Roblox authentication ticket flow and `roblox-player:` URL handler.
- Experimental native macOS multi-instance launching through managed Roblox app copies.
- Tests for storage, import/export, and launch URL construction.
- GitHub Actions workflow for Swift build/test.

## Security Model

Stored locally:

- `~/Library/Application Support/MacOS-RobloxAccountManager/Accounts.json`
- `~/Library/Application Support/MacOS-RobloxAccountManager/Settings.json`
- `~/Library/Application Support/MacOS-RobloxAccountManager/Logs.txt`
- macOS Keychain items for `.ROBLOSECURITY` tokens and optional passwords

Not included:

- No telemetry.
- No hidden auto-updater.
- No obfuscated binaries.
- No bundled Windows executables or DLLs.
- No plaintext account secret export.
- No account-control websocket server.
- No Developer API server in `v0.3.1`.

Only use this tool with accounts you own. Never share tokens, exported files containing secrets, or generated launch links.

## Launching

The `Allow account launching` and `Allow roblox-player launch URLs` options are normal launch settings. They are disabled by default because launch links depend on Roblox session state, but they are not hidden behind a special risk mode.

The app launches Roblox by requesting an authentication ticket for the selected account, building a `roblox-player:` URL, and handing it off to macOS.

## Multi-Instance

Multi-instance is an experimental advanced setting and is disabled by default.

When multi-instance is off, Roblox launches normally through the system `roblox-player:` URL handler.

When multi-instance is on, the app:

1. Locates the installed Roblox app in `/Applications/Roblox.app` or `~/Applications/Roblox.app`.
2. Creates a temporary managed copy under `~/Library/Application Support/MacOS-RobloxAccountManager/MultiInstanceCopies/`.
3. Updates only the copied app bundle's `Info.plist` so macOS does not prohibit multiple instances of that copy.
4. Ad-hoc signs the managed copy so macOS can launch the locally modified copy.
5. Performs a best-effort cleanup of Roblox's macOS single-instance semaphore.
6. Asks macOS to open the Roblox launch URL with the managed copy.

This does not modify the installed Roblox app. It does not require `sudo`, does not install a background service, and does not add telemetry. The app removes each managed copy after the launched Roblox instance exits.

Compatibility notes:

- Roblox updates may change its process locking behavior and break this feature.
- macOS Gatekeeper, Roblox updates, or a missing `/Applications/Roblox.app` can prevent a second instance from launching.
- Multiple Roblox clients may still share some Roblox-managed local state. The app stores account metadata separately and keeps account tokens in Keychain.
- Managed Roblox copies are temporary local app bundles. If a copy remains after a crash or forced quit, use Settings -> `Clean Multi-Instance Copies` after closing Roblox.
- If multi-instance launch fails, the app writes a clear error to the log and normal launching remains available after disabling the setting.

The project [Insadem/multi-roblox-macos](https://github.com/Insadem/multi-roblox-macos) was reviewed only as a technical reference for possible macOS approaches. No code, source files, or Go components from that project are copied or vendored here.

## Installation

Download the `v0.3.1` release asset, unzip it, and run `MacOS-RobloxAccountManager.app`. The release zip contains a universal `arm64` + `x86_64` app bundle.

If macOS blocks the app, build from source or explicitly allow the app in System Settings. `v0.3.1` release builds are ad-hoc signed but not notarized with an Apple Developer ID.

## Build Instructions

Requirements:

- macOS 14 or newer
- Xcode command line tools
- Swift 6.1 or compatible current Swift toolchain

Build:

```sh
swift build -c release
```

Run from source:

```sh
swift run MacOS-RobloxAccountManager
```

Test:

```sh
swift test
```

Create a local `.app` bundle:

```sh
Scripts/package_app.sh
```

The bundle is written to `dist/MacOS-RobloxAccountManager.app`.

## Known Limitations

- No Developer API server yet.
- No account-control websocket/Nexus port.
- No server browser, universe/outfit utilities, account utilities, Roblox watcher, browser automation, or FPS unlocker.
- Multi-instance is experimental and may break with Roblox or macOS updates.
- Import/export intentionally excludes tokens and passwords.
- Roblox launch depends on the installed Roblox macOS URL handler and a valid account token.
- Release artifacts are ad-hoc signed but not notarized unless a signing identity is configured externally.

## Manual Testing

1. Launch Roblox normally with multi-instance disabled.
2. Open Settings and enable `Multi-instance mode`.
3. Launch the first account from the app.
4. Launch a second account from the app.
5. Disable `Multi-instance mode`.
6. Confirm a normal launch still works.
7. Close Roblox and confirm the app removes the managed copy.
8. If a launch fails, confirm the app shows a clear log message and account data remains unchanged.
9. Use Settings -> `Clean Multi-Instance Copies` to remove any leftover copies after Roblox is closed.

## Original Project

Original project: https://github.com/ic3w0lf22/Roblox-Account-Manager

Original license: GNU General Public License v3.0

This macOS port preserves the license and clearly marks the changed platform behavior.
