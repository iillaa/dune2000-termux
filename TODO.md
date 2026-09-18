# Roadmap & Known Issues (TODO)

This document tracks all active bugs, root causes, diagnostic findings, and tasks for running *Dune 2000* natively on Android (Snapdragon 870 / Termux / hangover-wine).

---

## 🔴 Critical Bugs to Resolve

### 1. Audio Looping / Buffer Repeat Bug (Menu "tek-tek" & Combat SFX)
* **Symptom**: 
  - Hovering mouse over main menu buttons plays a short ~50ms click ("tek"). Instead of stopping, this sound gets trapped in an audio buffer and repeats in an endless 1–2 second loop.
  - When units engage in combat, gunshots and voice lines get layered into the same circular buffer, repeating indefinitely.
* **Technical Details**:
  - DirectSound / Miles Sound System (`mss32.dll`) writes PCM samples to a circular mixing buffer.
  - On Android 14, Termux PulseAudio's default `module-sles-sink` (OpenSL ES) does not flush or zero-fill ring buffers when idle, causing Android's audio hardware to repeatedly replay uncleared memory blocks.
* **Relevant Files**:
  - Launcher: `~/chat/dune/play_dune2000.sh` (controls PulseAudio startup and `PULSE_SERVER`)
  - PulseAudio config: `/data/data/com.termux/files/usr/etc/pulse/default.pa`
  - Wine DirectSound registry: `HKCU\Software\Wine\DirectSound` (`HardwareAcceleration=Emulation`)
* **Next Steps**:
  - [ ] Switch PulseAudio sink from legacy OpenSL ES (`module-sles-sink`) to native Android 14 low-latency API (`module-aaudio-sink`).
  - [ ] Configure PulseAudio daemon (`~/.config/pulse/daemon.conf`) with `default-fragments` and `default-fragment-size-msec` to force buffer clearing on idle.
  - [ ] Test Wine ALSA driver fallback (`winealsa.drv`) vs `winepulse.so`.

---

### 2. Silent Battle Music (No Frank Klepacki CD Soundtrack)
* **Symptom**:
  - In-game battles have sound effects, but Frank Klepacki's authentic industrial soundtrack never plays.
* **Technical Details**:
  - Disassembly of `DUNE2000.DAT` at `0x6fd5f` showed `CUIManager()` loads music via `sprintf(buf, "%smusic", InstallPath)`.
  - InstallPath was updated in registry to end with a trailing backslash `C:\Program Files (x86)\Gruntmods Studios\Dune 2000\`, and fallback symlinks `Dune 2000music -> Dune 2000/music` were created.
  - `dune2000.cfg` bytes 0 & 1 are set to `100` (`0x64`).
* **Relevant Files**:
  - Audio tracks: `.../Dune 2000/data/Music/*.aud` (symlinked from `.../Dune 2000/music`)
  - Config: `.../Dune 2000/dune2000.cfg` (Byte 0 = SFX Vol, Byte 1 = Music Vol)
  - Engine INI: `.../Dune 2000/dune2000.ini` (`MusicVolume=100`, `PlayRandomSong=1`, `ForceNoCD=1`)
* **Next Steps**:
  - [ ] Check if `ForceNoCD=1` in `dune2000.ini` bypasses CD audio or if the engine expects a virtual CD-ROM drive mapping (`dosdevices/d:` in Wine).
  - [ ] Verify if music files require 8.3 uppercase filenames (`AMBUSH.AUD` vs `ambush.aud`) or specific AUD format decoding.
  - [ ] Check `WINEDEBUG=+mci,+mcicda,+dsound` to see which API the engine calls to start music streams.

---

### 3. Mission 1 Victory / Mission End Hard Crash
* **Symptom**:
  - Playing Mission 1 (Harkonnen) works until the mission objective is achieved. The moment the mission ends with victory, the game crashes completely back to the desktop/terminal.
* **Technical Details & Suspected Culprits**:
  1. **Victory Cutscene / FMV (`.VQA`)**: Post-mission movie playback may fail to find the video file or fail during video/audio decompression.
  2. **Territory Map Transition**: After victory, Dune 2000 tries to return to the planetary campaign map (`G_MAPS_E.VQA`), which has a known palette/page-flip lockup.
  3. **Score Screen Audio**: The game tries to play `SCORE.AUD` or `AI_WIN.AUD` at mission end; if the audio handle crashes, the engine exits.
  4. **Savegame / Statistics File Write**: The engine attempts to write campaign progress to `GameSave/` or `dune2000.cfg`, which may encounter permission or path errors.
* **Relevant Files**:
  - Mission scripts: `.../Dune 2000/data/Missions/` (`H1V1.mis`, `H1V1.map`, `H1V1.ini`)
  - Movies: `.../Dune 2000/movies/` (`*.VQA`)
  - Game executable: `.../Dune 2000/DUNE2000.DAT`
* **Next Steps**:
  - [ ] Run `hangover-wine` with `WINEDEBUG=+seh,+relay` captured to a log file during mission victory to capture the exact crash backtrace.
  - [ ] Verify existence and permissions of `GameSave/` folder in the game directory.
  - [ ] Check if post-mission movie files exist for Harkonnen Mission 1.

---

### 4. Incomplete Sound Effects (Missing Voice Lines & Announcer)
* **Symptom**:
  - Some combat SFX and UI clicks play, but many voice announcements (e.g. "Harvester deployed", "Building complete", "Enemy approaching") are absent.
* **Relevant Files**:
  - Sound directory: `.../Dune 2000/data/GAMESFX/` and `.../Dune 2000/data/GAMESFXEng/`
* **Next Steps**:
  - [ ] Verify if symlinks `gamesfx` and `gamesfxeng` in root and `data/` resolve both uppercase and lowercase `.AUD` files.
  - [ ] Check language setting in `dune2000.ini` or registry (defaults to English).

---

## 🟡 Lower Priority / Polish Tasks

### 5. Planetary Campaign Map Direct Access
- The 1998 campaign map (`G_MAPS_E.VQA`) crashes when clicked directly due to hybrid 8-bit palette page-flipping.
- *Workaround in place*: Launching missions via "Select Mission" works directly.

### 6. Automated 1-Click Installer (`install.sh`)
- Create a single script to automate package installs, wineprefix initialization, and asset linking for new users.
