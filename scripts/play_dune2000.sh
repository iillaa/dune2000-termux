#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# Native Dune 2000 Launcher for Termux on Snapdragon 870
# Multi-Core Enabled across Performance Cores 4, 5, 6, 7
# ==============================================================================

# 1. Kill any stuck wineserver / game instances
pkill -9 -f wineserver 2>/dev/null
pkill -9 -f Dune2000 2>/dev/null
pkill -9 -f DUNE2000 2>/dev/null
sleep 1

# 2. Ensure PulseAudio daemon is running with TCP module for Wine
pulseaudio --start --exit-idle-time=-1 --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" 2>/dev/null
pactl load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1 2>/dev/null

# 3. Ensure Termux-X11 display server is running
if ! pgrep -f "termux-x11.*:0" >/dev/null; then
    rm -f /data/data/com.termux/files/usr/tmp/.X11-unix/X0
    termux-x11 :0 -ac &
    sleep 1
fi

# 4. Bring Termux-X11 window to front on Android
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1

# 5. Environment variables
export DISPLAY=:0
export WINEPREFIX="/data/data/com.termux/files/home/chat/dune/prefix"
export WINEDEBUG=-all
export PULSE_SERVER=127.0.0.1
export PULSE_LATENCY_MSEC=120

# Adreno 650 Hardware GPU Acceleration (Turnip Vulkan + Zink OpenGL)
export MESA_LOADER_DRIVER_OVERRIDE=zink
export GALLIUM_DRIVER=zink
unset TU_DEBUG

# Box64 Dynarec performance optimizations for Snapdragon 870
export BOX64_DYNAREC=1
export BOX64_DYNAREC_SAFEFLAGS=1
export BOX64_DYNAREC_FASTROUND=1
export BOX64_DYNAREC_FASTNAN=1
export BOX64_DYNAREC_STRONGMEM=0

# 6. Locate game directory
GAME_DIR="/data/data/com.termux/files/home/chat/dune/prefix/drive_c/Program Files (x86)/Gruntmods Studios/Dune 2000"
if [ ! -d "$GAME_DIR" ]; then
    FOUND=$(find "/data/data/com.termux/files/home/chat/dune/prefix/drive_c" -iname "dune2000.exe" 2>/dev/null | head -n 1)
    if [ -n "$FOUND" ]; then
        GAME_DIR=$(dirname "$FOUND")
    fi
fi

if [ -d "$GAME_DIR" ]; then
    cp -f /data/data/com.termux/files/home/chat/dune/ddraw.ini "$GAME_DIR/ddraw.ini" 2>/dev/null
    cd "$GAME_DIR"
    EXE=$(find "$GAME_DIR" -maxdepth 1 -iname "dune2000.exe" 2>/dev/null | head -n 1)
    echo "Starting Dune 2000 PC Edition across Snapdragon 870 Big Cores (4, 5, 6, 7)..."

    # Launch Wine directly pinned to Big/Prime cores (4-7)
    # SingleProcessorAffinity=0 in dune2000.ini ensures the engine keeps all cores
    exec taskset -c 4-7 hangover-wine "$EXE"
else
    echo "Game folder not found in prefix. Please verify installation."
fi
