# Attribution Notice

MacOS-RobloxAccountManager is a macOS port inspired by and functionally modeled after Roblox Account Manager:

https://github.com/ic3w0lf22/Roblox-Account-Manager

The original project is licensed under the GNU General Public License version 3. This repository is also distributed under GPL-3.0 and preserves the same license terms.

This port is not affiliated with Roblox Corporation and is not endorsed by the original Roblox Account Manager maintainers unless explicitly stated by them.

## Porting Notes

The upstream Windows project uses WinForms, .NET Framework, DPAPI, libsodium, Windows process APIs, `handle.exe`, a Windows named mutex for multi-instance behavior, a local web API, and websocket-based account control. This macOS port replaces the UI with SwiftUI and stores secrets in the macOS Keychain.

Windows-only binaries, DLLs, registry checks, process-window manipulation, auto-updater logic, browser automation, account-control websockets, and unsafe or unimplemented network APIs were not copied into this repository.

## Icon Attribution

The macOS app icon is based on the `RBX Alt Manager/Resources/team_KX4_icon.ico` icon asset from the original GPL-3.0 upstream project:

https://github.com/ic3w0lf22/Roblox-Account-Manager

The icon asset is included under the same GPL-3.0 terms as the upstream project and this macOS port.
