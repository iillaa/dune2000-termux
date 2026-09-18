#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# Stop Dune 2000 and Clean Up Background Services
# ==============================================================================

echo "Stopping Dune 2000 and Wine processes..."
pkill -9 -f Dune2000 2>/dev/null
pkill -9 -f DUNE2000 2>/dev/null
pkill -9 -f wineserver 2>/dev/null
pkill -9 -f winedevice 2>/dev/null

echo "Stopping Termux-X11 display server..."
pkill -9 -f "termux-x11.*:0" 2>/dev/null
rm -f /data/data/com.termux/files/usr/tmp/.X11-unix/X0

echo "Stopping PulseAudio..."
pulseaudio --kill 2>/dev/null

echo "All Dune 2000 services stopped cleanly."
