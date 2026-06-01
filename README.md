# MacOS-RobloxAccountManager

MacOS-RobloxAccountManager is a native macOS port of [Roblox Account Manager](https://github.com/ic3w0lf22/Roblox-Account-Manager). The goal is to preserve the original application's core workflow on macOS: keep a local list of accounts, search them, edit metadata, securely store local secrets, and launch Roblox for a selected account where macOS and Roblox allow it.

This is a GPL-3.0 project. The upstream Roblox Account Manager project is GPL-3.0, and this port keeps the same license. See [LICENSE](LICENSE) and [NOTICE.md](NOTICE.md).

This project is not affiliated with Roblox Corporation.

## Current Status

v0.1.0 is a functional, conservative macOS port. It intentionally does not copy Windows-only binaries or unsafe account-control features. Risky features are disabled by default and must be manually enabled.

## Upstream Analysis Summary

The original Windows project is a WinForms/.NET Framework application. Important upstream components reviewed for this port:

- UI: WinForms main account list, account context menu, settings form, server list, utilities, account control, theme editor.
- Storage: `AccountData.json`, `RecentGames.json`, `RAMSettings.ini`, `RAMTheme.ini`.
- Encryption: Windows DPAPI by default, optional password encryption through libsodium, and a risky plaintext escape hatch.
- Accounts: `.ROBLOSECURITY` cookie, username, alias, description, group, user ID, fields, password, last use, browser tracker ID.
- Launching: Roblox authentication ticket request followed by a `roblox-player:` launch URL or Windows executable launch.
- Multi-instance: Windows named mutex behavior around `ROBLOX_singletonMutex`.
- Developer API: optional local HTTP API with methods such as account listing, cookie retrieval, account launch, and account editing.
- Account Control/Nexus: websocket control path plus Lua helper scripts.
- Windows-only parts: registry checks, `.exe`/`.dll` resources, `handle.exe`, DWM/window positioning, process command-line inspection, embedded updater, CefSharp/Puppeteer browser helpers.

## Implemented Features

- Native SwiftUI macOS app.
- Account list with search/filter.
- Add, edit, and delete account records.
- Account metadata fields: username, alias, description, group, user ID, saved Place ID, saved Job ID/VIP code, last-used timestamp.
- Secure local secret storage using macOS Keychain.
- Optional password storage in Keychain, disabled by default.
- Metadata import/export as JSON.
- Metadata backup to Application Support.
- Settings view with clear risky-feature toggles.
- Logs with visible error messages.
- Guarded Roblox launch support using Roblox authentication ticket flow and `roblox-player:` URL handler.
- Tests for storage, import/export, and launch URL construction.
- GitHub Actions workflow for Swift build/test.

## Security Model

Stored locally:

- `~/Library/Application Support/MacOS-RobloxAccountManager/Accounts.json`
- `~/Library/Application Support/MacOS-RobloxAccountManager/Settings.json`
- `~/Library/Application Support/MacOS-RobloxAccountManager/Logs.txt`
- macOS Keychain items for `.ROBLOSECURITY` cookies and optional passwords

Not included:

- No telemetry.
- No hidden auto-updater.
- No obfuscated binaries.
- No bundled Windows executables or DLLs.
- No plaintext account secret export.
- No account-control websocket server.
- No Developer API server in v0.1.0.

Only use this tool with accounts you own. Never share `.ROBLOSECURITY` cookies, exported files containing secrets, or generated launch links.

## Risk Warnings

`rbx-player` launch links are risky. A launch link or authentication ticket can allow someone else to use a Roblox session if shared. For that reason, account launching and `rbx-player` URL launching are both disabled by default.

Multi-instance behavior is also risky and was disabled by default upstream. The Windows implementation depends on a Windows named mutex. This macOS port does not implement a bypass or unsupported replacement in v0.1.0.

Developer/API functionality is disabled and not implemented in v0.1.0. The upstream API can expose sensitive operations, including cookie retrieval and launching accounts, so it needs a separate hardened design before being enabled on macOS.

## Installation

Download the v0.1.0 release asset if available, unzip it, and run `MacOS-RobloxAccountManager.app`.

If macOS blocks the unsigned app, build from source or explicitly allow the app in System Settings. v0.1.0 release builds are unsigned unless stated otherwise.

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
- No macOS multi-instance implementation in v0.1.0.
- Import/export intentionally excludes cookies and passwords.
- Roblox launch depends on the installed Roblox macOS URL handler and a valid account cookie.
- Release artifacts are unsigned unless a signing identity is configured externally.

## Original Project

Original project: https://github.com/ic3w0lf22/Roblox-Account-Manager

Original license: GNU General Public License v3.0

This macOS port preserves the license and clearly marks the changed platform behavior.
