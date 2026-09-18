# Development & Diagnostic Progress Log

This document records the exact reverse-engineering findings, root-cause analyses, environment configurations, and solutions developed to run *Dune 2000* natively on Android via Termux.

---

## Architecture & File Reference

### 1. File & Directory Index

| Component | Absolute Path | Purpose |
| :--- | :--- | :--- |
| **Git Repository** | `~/chat/dune2000-termux/` | Version-controlled configuration, scripts, and documentation |
| **Active Game Root** | `~/chat/dune/prefix/drive_c/Program Files (x86)/Gruntmods Studios/Dune 2000/` | Main game assets, binaries, and local configs |
| **Wine Prefix** | `~/chat/dune/prefix/` | 64-bit Wine prefix for `hangover-wine` |
| **Launcher Script** | `~/chat/dune/play_dune2000.sh` | Main launch script with CPU affinity, X11, and audio setup |
| **Stop Script** | `~/chat/dune/stop_dune2000.sh` | Gracefully terminates Wine, X11, and orphaned processes |
| **Master ddraw.ini** | `~/chat/dune/ddraw.ini` | Master `cnc-ddraw` config copied to game root on launch |
| **Game Executable** | `.../Dune 2000/DUNE2000.DAT` | 32-bit x86 Westwood engine binary (executed by Wine via Box64) |
| **Sound System** | `.../Dune 2000/MSS32.DLL` | Miles Sound System 32-bit audio library |
| **Music Tracks** | `.../Dune 2000/data/Music/*.aud` | Authentic Frank Klepacki CD soundtrack (symlinked to `music/`) |
| **Sound Effects** | `.../Dune 2000/data/GAMESFX/*.aud` | Authentic Westwood combat & UI sound effects |
| **Voice Lines** | `.../Dune 2000/data/GAMESFXEng/*.aud`| English spoken unit announcements and responses |
| **Campaign Missions**| `.../Dune 2000/data/Missions/` | Mission files (`H1V1.mis`, `H1V1.map`, `H1V1.ini`, etc.) |
| **FMV Cutscenes** | `.../Dune 2000/movies/*.VQA` | Westwood Vector Quantized Animation cutscenes |
| **Widget Shortcuts** | `~/.shortcuts/Dune2000_Start.sh` | Android home screen launcher via Termux:Widget |

### 2. Environment Variables Reference

```bash
DISPLAY=:0                                              # Termux-X11 display socket
WINEPREFIX="/data/data/com.termux/files/home/chat/dune/prefix"
WINEDEBUG=-all                                          # Suppress noisy Wine debug logs for performance
PULSE_SERVER="unix:/data/data/com.termux/files/usr/tmp/pulse-native"  # Low-latency UNIX domain socket
PULSE_LATENCY_MSEC=60                                   # Audio buffer latency target
MESA_LOADER_DRIVER_OVERRIDE=zink                        # Vulkan to OpenGL translation
GALLIUM_DRIVER=zink                                     # Adreno 650 hardware acceleration
BOX64_DYNAREC=1                                         # Enable dynamic recompiler
BOX64_DYNAREC_SAFEFLAGS=1                               # Accurate arithmetic flags for VQA video decoding
BOX64_DYNAREC_FASTROUND=1
BOX64_DYNAREC_FASTNAN=1
BOX64_DYNAREC_STRONGMEM=0
```

---

## Chronological Progress & Diagnostic Findings

### Phase 1: Environment & Execution Model
1. **Eliminated PRoot Overhead**: Native ARM64 `hangover-wine` and `hangover-wowbox64` running directly in Termux user-space without PRoot containers.
2. **Eliminated Zombie Electron Processes**: Found and killed 5 hidden instances of `New Spice Launcher.exe` consuming 700 MB RAM, restoring free memory to 2.6 GB.

### Phase 2: Video Decoding & Graphics
3. **VQA Video Macroblock Corruption**: Box64 flag optimization (`BOX64_DYNAREC_SAFEFLAGS=0`) corrupted Westwood vector quantization decoding. Fixed with `BOX64_DYNAREC_SAFEFLAGS=1`.
4. **Horizontal Scanline Shearing**: Emulated CRT sync (`vhack = true`) in `cnc-ddraw` conflicted with Wayland compositor. Fixed with `vhack = false`.
5. **Renderer Optimization**: `renderer = gdi` with `filter = nearest` eliminates CPU bilinear filter overhead over 5.1M pixels (`2944x1725`), maintaining locked 60 FPS.

### Phase 3: CPU Multi-Core Scaling
6. **Single-Core Affinity Lock**: Disassembled `DUNE2000.DAT` at `0x8fef89` and discovered `SingleProcessorAffinity=1` locks process to CPU 0. Set `SingleProcessorAffinity=0` and pinned to Snapdragon 870 Big Cores (`taskset -c 4-7`).

### Phase 4: Filesystem Case-Sensitivity & Asset Resolving
7. **The Mission Underscore Bug**: Community installer extracted 844 mission files as `_H1V1.MIS`, whereas the engine looks for `H1V1.mis`. Generated un-underscored symlinks.
8. **Case Sensitivity**: Generated 13,900+ case-folding symlinks so the engine can locate assets regardless of uppercase/lowercase.

### Phase 5: Audio Diagnostics & Findings
9. **Reverse-Engineered Music Loading**:
   - Disassembly at `0x6fd5f` showed `CUIManager()` constructs `%smusic` using `InstallPath` from `HKLM\Software\Westwood\Dune 2000`.
   - Lacking a trailing backslash produced `.../Dune 2000music`, which failed `FindFirstFileA`.
   - Fixed by adding trailing backslashes in registry and adding fallback symlinks.
10. **Audio Looping Root-Cause Analysis**:
   - Symptoms: Mouse hover over menu buttons creates a "tek" sound that gets trapped in the buffer and loops every 1–2s. Combat SFX (gunshots) also loop endlessly.
   - Mechanism: DirectSound circular mixing buffers under Miles Sound System (`mss32.dll`) encounter an uncleared ring buffer in Termux PulseAudio's `module-sles-sink` (OpenSL ES) on Android 14.
   - Wine DirectSound switched to `HardwareAcceleration=Emulation` to force software mixing.
   - PulseAudio switched to direct UNIX domain socket (`PULSE_SERVER=unix:.../pulse-native`).

### Phase 6: Mission End Hard Crash (New Finding)
11. **Mission 1 Victory Crash**:
   - Upon completing the objective in Mission 1 (Harkonnen), the game abruptly exits.
   - Immediate suspects: Post-mission cutscene lookup, victory fanfare audio crash, or territory map transition.
