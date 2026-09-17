# Roadmap & TODO

This document outlines the remaining engineering objectives to achieve 100% perfection before publishing the public release.

---

## 1. Planetary Territory Map Screen Compatibility
- [ ] **Investigate cnc-ddraw Palette Page Flip**:
  - The 1998 campaign territory selection map screen (`G_MAPS_E.VQA`) uses a hybrid 8-bit palette switch with 16-bit video overlay.
  - Under `cnc-ddraw` with OpenGL on Android Wayland, the page-flip event sometimes does not signal the main game thread to advance.
  - *Current Workaround*: Launching via "Select Mission" on the main menu bypasses the broken map screen and loads the briefing FMV and mission battlefield directly.
  - *Goal*: Test `renderer = gdi` or patch cnc-ddraw's flip-sync timing to enable smooth transition through the original territory map.

---

## 2. Automated 1-Click Installer Script (`install.sh`)
- [ ] Write an automated bash installer that performs end-to-end setup in one command:
  - Detect Termux environment and install required packages (`tur-repo`, `hangover-wine`, `hangover-wowbox64`, `pulseaudio`, `termux-x11-nightly`).
  - Set up Wine prefix in `~/dune/prefix`.
  - Download and extract authentic game assets and Westwood movies.
  - Apply `dune2000.ini`, `ddraw.ini`, `westwood.reg`, and volume-unmuted `dune2000.cfg`.
  - Execute the recursive case-folding and un-underscoring symlink generators.
  - Create the `dune` alias in `~/.bashrc`.

---

## 3. Campaign & Mission Verification
- [x] House Harkonnen - Mission 1 (Tested & Verified Live)
- [ ] House Atreides - Mission 1 & Briefing FMVs
- [ ] House Ordos - Mission 1 & Briefing FMVs
- [ ] Mid-game missions with Sandworms, Harvesters, Carryalls, and Palace superweapons
- [ ] Custom missions and Skirmish mode stability

---

## 4. Input & Control Refinements
- [ ] Optimize Bluetooth mouse cursor responsiveness:
  - Test `adjmouse = true` vs `false` for raw hardware DPI tracking.
  - Validate touch-to-mouse mapping when a physical mouse is unavailable.
- [ ] Keyboard shortcut bindings verification (Space to center, H to harvest, repair/sell hotkeys).

---

## 5. Public GitHub Release Preparation
- [ ] Clean up repository structure and add license information.
- [ ] Add screenshots and gameplay videos of native Android execution.
- [ ] Write clear troubleshooting FAQ for common Android/Termux issues.
