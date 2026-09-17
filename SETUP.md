# Setup & Deployment Guide

This guide documents how to set up and run the authentic PC release of *Dune 2000* natively on Android using Termux.

---

## 1. Prerequisites & Termux Packages

Enable TUR (Termux User Repository) and install the native Wine and Box64 packages:

```bash
# Add repositories
pkg update -y
pkg install -y tur-repo x11-repo

# Install native ARM64 Wine and wowbox64 (Dynarec)
pkg install -y hangover-wine hangover-wowbox64 pulseaudio termux-x11-nightly mesa-zink
```

---

## 2. Directory Layout

The game is self-contained in `~/chat/dune`:

```
~/chat/dune/
├── play_dune2000.sh             # Main launcher script (aliased as 'dune')
├── ddraw.ini                    # Optimized cnc-ddraw configuration
├── westwood.reg                 # Windows registry keys for Westwood engine
└── prefix/                      # 64-bit Wine prefix
    ├── system.reg               # Wine system registry
    └── drive_c/Program Files (x86)/Gruntmods Studios/Dune 2000/
        ├── DUNE2000.DAT         # Main game executable
        ├── DUNE2000.EXE         # Westwood launcher
        ├── ddraw.ini            # DirectDraw renderer config
        ├── dune2000.ini         # Engine configuration (multi-core, resolution)
        ├── dune2000.cfg         # Player profile & volume configuration
        ├── resource.cfg         # Asset search paths
        ├── movies/              # 43 Westwood .VQA video files
        ├── music -> data/Music  # Symlink to soundtrack
        └── data/
            ├── Missions/        # Campaign mission scripts (.MIS, .MAP, .ini)
            ├── Music/           # 16 authentic .AUD soundtracks
            ├── UI_GFX/          # UI textures & territory map regions
            └── UI_DATA/         # Interface definitions
```

---

## 3. Configuration Reference

### `dune2000.ini` (Engine Settings)
Placed in the game root:
```ini
[Options]
GameWidth=640
GameHeight=400
GameBitsPerPixel=16
SingleProcessorAffinity=0
CutsceneChangeResolution=0
MoviesEnabled=1
SoundsEnabled=1
ForceNoCD=1
SlowSideBarScrolling=0
DisableMaxWindowedMode=0
UseHardwareCursor=0
MusicVolume=100
SFXVolume=100
PlayRandomSong=1
```

### `ddraw.ini` (DirectDraw to OpenGL)
Placed in the game root:
```ini
[ddraw]
renderer = opengl
fullscreen = true
windowed = false
borderless = true
maintas = true
boxing = false
maxfps = 60
minfps = -1
vsync = false
filter = linear
clipcursor = true
handlemouse = true
adjmouse = true
mousehook = 2
vhack = false
singlecpu = false
noactivateapp = true
nonexclusive = true
accuratetimers = true
```

### `westwood.reg` (Registry Keys)
Imported into the prefix:
```reg
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\Software\Westwood\Dune 2000]
"InstallPath"="C:\\Program Files (x86)\\Gruntmods Studios\\Dune 2000"
"Version"="1.06"
"FolderPath"="C:\\Program Files (x86)\\Gruntmods Studios\\Dune 2000"
"SKU"=dword:00000e00

[HKEY_LOCAL_MACHINE\Software\Wow6432Node\Westwood\Dune 2000]
"InstallPath"="C:\\Program Files (x86)\\Gruntmods Studios\\Dune 2000"
"Version"="1.06"
"FolderPath"="C:\\Program Files (x86)\\Gruntmods Studios\\Dune 2000"
"SKU"=dword:00000e00
```

---

## 4. Launcher Script (`play_dune2000.sh`)

```bash
#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# Native Dune 2000 Launcher for Termux on Snapdragon 870
# Multi-Core Enabled across Performance Cores 4, 5, 6, 7
# ==============================================================================

# 1. Kill any stuck instances
pkill -9 -f wineserver 2>/dev/null
pkill -9 -f Dune2000 2>/dev/null
pkill -9 -f DUNE2000 2>/dev/null
sleep 1

# 2. PulseAudio with TCP module
pulseaudio --start --exit-idle-time=-1 --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" 2>/dev/null
pactl load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1 2>/dev/null

# 3. Display server
if ! pgrep -f "termux-x11.*:0" >/dev/null; then
    rm -f /data/data/com.termux/files/usr/tmp/.X11-unix/X0
    termux-x11 :0 -ac &
    sleep 1
fi

am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1

# 4. Environment
export DISPLAY=:0
export WINEPREFIX="/data/data/com.termux/files/home/chat/dune/prefix"
export WINEDEBUG=-all
export PULSE_SERVER=127.0.0.1
export PULSE_LATENCY_MSEC=120

# Adreno GPU Acceleration (Turnip + Zink)
export MESA_LOADER_DRIVER_OVERRIDE=zink
export GALLIUM_DRIVER=zink
unset TU_DEBUG

# Box64 Dynarec
export BOX64_DYNAREC=1
export BOX64_DYNAREC_SAFEFLAGS=1
export BOX64_DYNAREC_FASTROUND=1
export BOX64_DYNAREC_FASTNAN=1
export BOX64_DYNAREC_STRONGMEM=0

GAME_DIR="/data/data/com.termux/files/home/chat/dune/prefix/drive_c/Program Files (x86)/Gruntmods Studios/Dune 2000"
cd "$GAME_DIR"
EXE=$(find "$GAME_DIR" -maxdepth 1 -iname "dune2000.exe" 2>/dev/null | head -n 1)

# Launch Wine directly pinned to Big/Prime cores (4-7)
exec taskset -c 4-7 hangover-wine "$EXE"
```
