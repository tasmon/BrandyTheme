# BrandyTheme

Brand themes for Windows 10 and 11: wallpaper, lock screen, accent colour and system icon sets for
**HP, Lenovo, Samsung, Intel, AMD and Ryzen**.

## Install

1. Extract the release zip.
2. Right-click `Install-BrandyTheme.ps1` > *Run with PowerShell* (or run it from an admin PowerShell).
3. Open **BrandyTheme** from the Start menu. It appears in *Settings > Apps > Installed apps*.

Uninstall from Installed apps, or run `Install-BrandyTheme.ps1 -Uninstall`.

## Use

Pick a brand, tick what to apply, click **Apply theme**. **Restore Windows defaults** reverts every
value BrandyTheme changed (original values are saved to `C:\ProgramData\BrandyTheme\state.json`).

| Option | How it works |
|---|---|
| Wallpaper | Generated at your screen resolution, set with `SystemParametersInfo` (Fill) |
| Lock screen | `PersonalizationCSP` registry values (see limits) |
| Accent colour / dark mode | HKCU DWM, Explorer\Accent, Themes\Personalize |
| File/folder/drive/app icons | `HKLM\...\Explorer\Shell Icons` pointing to generated `.ico` files |
| Desktop icons | Per-user CLSID overrides: This PC, Recycle Bin, Network, User Files, Control Panel |
| Start menu folders | `desktop.ini` icon on Start menu program folders (existing ones are never touched) |

### Logos
No third-party logos are bundled. Themes use brand colours and a text wordmark. If you hold the rights
to official logos, save them as `HP.png`, `Lenovo.png`, `Samsung.png`, `Intel.png`, `AMD.png`,
`Ryzen.png` in `C:\ProgramData\BrandyTheme\Logos` (File > Open custom logos folder).

## Publishing an update (auto-update)

1. Increase `$script:AppVersion` in `BrandyTheme.ps1` (e.g. `1.1.0`).
2. Run `.\Build-Release.ps1`.
3. On GitHub create a release tagged `v1.1.0` and attach **both** `BrandyTheme-1.1.0.zip` and
   `BrandyTheme-1.1.0.zip.sha256` from `dist\`.

Running copies check `releases/latest` at start-up (toggle under *Help*), verify the SHA-256 and the
download host, then replace their files and restart. The repository name is set by
`$script:GitHubRepo` near the top of `BrandyTheme.ps1`.

## Known limits

- **Settings app, Start tiles and taskbar app icons** are packaged assets (MSIX/UWP) that Windows
  protects; they cannot be replaced safely. BrandyTheme themes Start and the taskbar with the accent
  colour (needs dark mode) and re-icons Start menu folders instead.
- **Lock screen** via `PersonalizationCSP` is officially for Pro/Enterprise/Education; Windows Home may ignore it.
  Windows Spotlight must not be selected as the lock screen type.
- Windows 11 may need a sign-out or restart before every icon refreshes.
- Settings are written to the **elevated account's** profile. If you elevate with a different admin
  account than the one you are logged in as, per-user items apply to that admin profile.
- Brand names and logos are trademarks of their owners; this project is not affiliated with them.
