# Changelog

## Unreleased

- Fixed Fedora KDE 6 polkit agent discovery in the session and doctor.
- Fixed the KWallet Manager settings action to use Fedora's executable name.
- Recognize the Brave Flatpak in the doctor and launch it for `BROWSER=brave`.
- Preserve the user's Plasma default browser and file associations on install.

## 1.1.0 - 2026-09-07

- Added the Fedora KDE Plasma base and SDDM integration.
- Replaced GNOME applications, portals, accounts, keyring and calendar APIs
  with Dolphin, Okular, Gwenview, Kate, KWallet, KAccounts and Akonadi.
- Added Merkuro integration for the bar calendar.
- Made VLC the default audio and video player.
- Kept dwl, Quickshell and all existing shell panels and visual behavior.

## 1.0.0 - 2026-09-05

- Reproducible Fedora 44 / GNOME 50 installation from a clean checkout.
- Pinned dwl, SceneFX and compositor-patch source revisions.
- Separate GDM session which leaves the GNOME desktop configuration intact.
- Complete Quickshell bar, launcher, panels, calendar, media and settings UI.
- Native Wayland touchpad gestures, SceneFX blur and XWayland support.
- Dedicated Kitty, Fastfetch, Starship and Zsh profiles.
- GNOME default applications plus Brave, Visual Studio Code and OnlyOffice.
- No passwords, accounts, histories, device profiles or personal files.
