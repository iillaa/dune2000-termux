# Development & Diagnostic Progress Log

This document records the exact reverse-engineering findings, root-cause analyses, and solutions developed to get *Dune 2000* running at full speed on Android via Termux.

---

## Phase 1: Environment & Execution Model

### 1. Eliminating PRoot Overhead
- **Problem**: Running Windows games through PRoot containers adds severe syscall translation latency, breaks GPU shared memory mappings, and degrades frame rates.
- **Solution**: Deployed native ARM64 `hangover-wine` and `hangover-wowbox64` directly in Termux user-space.

### 2. Eliminating Ghost Processes & Freeing Memory
- **Problem**: Available RAM dropped to 1.7 GB, causing out-of-memory killed processes.
- **Root Cause**: Discovered an Electron/Chromium installer process (`New Spice Launcher.exe`) running 5 hidden child processes in the background consuming 700 MB RAM.
- **Solution**: Terminated all orphan installer processes, immediately restoring free RAM from 1.7 GB to 2.6 GB.

---

## Phase 2: Video Decoding & Graphics Acceleration

### 3. Westwood VQA Macroblock Corruption
- **Problem**: Cutscenes suffered heavy macroblock decoding artifacts, square pixel noise, and distorted colors.
- **Root Cause**: Box64's Dynarec had aggressive arithmetic flag optimizations enabled (`BOX64_DYNAREC_SAFEFLAGS=0`), which incorrectly calculated carry flags during Westwood's vector quantization video decoding.
- **Solution**: Set `BOX64_DYNAREC_SAFEFLAGS=1`. VQA playback rendered pixel-perfect.

### 4. Horizontal Scanline Tearing
- **Problem**: In-game menus and video had subtle horizontal scanline shearing.
- **Root Cause**: The `vhack` option in `cnc-ddraw` attempted to emulate CRT scanline vertical blank synchronization, conflicting with Android's Wayland surface compositor.
- **Solution**: Set `vhack = false` in `ddraw.ini`.

### 5. Display Aspect Ratio & Centering
- **Problem**: Initial display was confined to a small 640x400 box in the screen corner.
- **Solution**: Set `boxing = false` and `maintas = true` with `renderer = opengl` in `ddraw.ini`. Scaled the display vertically to 1150px while maintaining the authentic 4:3 Westwood aspect ratio.

---

## Phase 3: CPU Multi-Core Performance

### 6. Single-Core Bottleneck Lock
- **Problem**: Frame rates dropped during gameplay, and threads stayed pinned to CPU 0 (1.8 GHz Little core).
- **Reverse-Engineering**: Disassembled `DUNE2000.DAT` at `0x8fef89`. Found that the engine checks `SingleProcessorAffinity` in `dune2000.ini`, and defaults to `1`, calling `SetProcessAffinityMask(1)`.
- **Solution**: Added `SingleProcessorAffinity=0` to `dune2000.ini`. Pinned Wine execution to Snapdragon 870 Big Cores (4, 5, 6, 7) via `taskset -c 4-7`. CPU usage scaled past 100% across multi-core.

---

## Phase 4: Mission Loading & Filesystem Fixes

### 7. Missing Westwood Windows Registry Keys
- **Problem**: Transitioning from House Selection to Mission Briefing locked up with `NO_REGISTRY` errors.
- **Root Cause**: Engine queries `HKEY_LOCAL_MACHINE\Software\Westwood\Dune 2000\InstallPath` to locate assets. No Westwood keys existed in the Wine prefix.
- **Solution**: Injected `Software\Westwood\Dune 2000` and `Software\Wow6432Node\Westwood\Dune 2000` keys into `system.reg`.

### 8. The Missing Mission Files Prefix Bug
- **Problem**: The game froze indefinitely on the territory map screen, unable to load Mission 1.
- **Root Cause**: Disassembled `DUNE2000.DAT` at `0x4708e0` / `0xe1690` and found the format string `%c%dV%d.mis`. The engine explicitly looks for `H1V1.mis`. However, the community installer extracted all 844 mission files with a leading underscore (e.g. `_H1V1.MIS`). Because Linux filesystems are case-sensitive, file lookups failed completely.
- **Solution**: Wrote a script creating 844 un-underscored symlinks (e.g. `H1V1.mis -> _H1V1.MIS`), resolving the mission loading freeze.

### 9. Linux Case-Sensitivity across 13,900+ Game Assets
- **Problem**: The game failed to load UI regions (`h1.bmp` vs `H1.BMP`), fonts, and sounds.
- **Solution**: Built a recursive case-folding mapper generating 13,947 lowercase and canonical symlinks across `data/`, `movies/`, and the prefix.

---

## Phase 5: Audio & Sound Effects

### 10. The "Harkonen... Harkonen" Loop Bug
- **Problem**: Audio stuttered and repeated the last spoken word in an infinite loop.
- **Root Cause**: DirectSound Circular Ring Buffer Underrun. When the engine thread stalled waiting for missing mission files, it stopped feeding new audio chunks. The audio driver kept playing the remaining buffer cyclically.

### 11. Silent Music in Battles
- **Problem**: Stage 1 battlefield had sound effects but zero background music.
- **Root Cause 1**: In `dune2000.cfg`, Byte 0 (Music Volume) was initialized to `0` (muted).
- **Root Cause 2**: At engine boot, `_findfirst("music")` checks the root game directory. Gruntmods stored files in `data/Music/`. Because `music` didn't exist in root, the engine disabled the music subsystem.
- **Solution**: Unmuted Byte 0 to `10` in `dune2000.cfg`, configured `MusicVolume=100` and `PlayRandomSong=1` in `dune2000.ini`, and symlinked `music -> data/Music`.

### 12. Machine-Gun Looping SFX Fix
- **Problem**: Sound effects repeated rapidly during combat like gunfire.
- **Root Cause 1**: `PULSE_LATENCY_MSEC=60` was too low for Android TCP loopback, triggering secondary buffer underruns.
- **Root Cause 2**: A background polling daemon was running `taskset -pc` across all 25 threads every second, context-switching the CPU and interrupting the real-time audio thread.
- **Solution**: Removed the thread watcher daemon and raised `PULSE_LATENCY_MSEC` to `120ms`.
