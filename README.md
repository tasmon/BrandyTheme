# BrandyTheme 1.3.2

Brand themes for Windows 10 and 11: wallpaper, lock screen, accent colour and icon sets for 40 brands
(HP, Lenovo, Samsung, Intel, AMD, Ryzen, Dell, ASUS, Acer, MSI, Microsoft, Apple, NVIDIA, GeForce, Radeon,
Razer, Alienware, Gigabyte, Logitech, Corsair, Sony, LG, Toshiba, Huawei, Xiaomi, Google, Qualcomm,
Snapdragon, Canon, Epson, Western Digital, Seagate, Kingston, ThinkPad, ROG, Legion, Predator, Xbox,
Surface, PlayStation).

## Install / update / uninstall
1. Extract the zip.
2. Double-click **Install BrandyTheme.cmd**, accept the UAC prompt and choose:
   **1** Install (or Update if already installed), **2** Uninstall, **3** Exit.
3. Open **BrandyTheme** from the Start menu.

Switches skip the menu: `/install`, `/update`, `/uninstall`, `/silent`.

## If something goes wrong
Problems are shown in a message and saved to `C:\ProgramData\BrandyTheme\error.log`
(`app.log` shows how far start-up got, `crash.log` is written by the launcher).

## Wallpapers and lock screens
Clean colour artwork only - no text, no logos. Each brand has 12 wallpapers and 12 lock screens built from
its own colours and 4 of 12 art styles, so no two brands look alike.

## Updates (version.txt)
Put these two files in the root of the `main` branch of github.com/tasmon/BrandyTheme:

| File | Content |
|---|---|
| `version.txt` | the latest version on the first line, e.g. `1.3.1` |
| `BrandyTheme.ps1` | the latest script |

To release an update: raise `$script:AppVersion` in `BrandyTheme.ps1`, set the same number in `version.txt`,
commit and push both. The app checks `version.txt` at start-up (toggle in the ••• menu), downloads
`BrandyTheme.ps1`, checks it is a valid script with the matching version, then restarts on the new version.
Optional: put the file's SHA-256 on line 2 of `version.txt` and the app will verify it too.

## Known limits
- The Settings app, Start tiles and taskbar app icons are protected by Windows and cannot be re-themed.
  The accent colour (with dark mode) colours Start and the taskbar; Start menu folders get themed icons.
- Lock screen theming works on Pro, Enterprise and Education; Windows Home may ignore it.
- A sign-out or restart may be needed before every icon refreshes.
- Brand names are trademarks of their owners; this project is not affiliated with them.
