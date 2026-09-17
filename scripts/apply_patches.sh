#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# Dune 2000 Termux Compatibility & Configuration Installer
# ==============================================================================
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
CONFIGS_DIR="$REPO_DIR/configs"

echo "=========================================================="
echo " Dune 2000 Termux Compatibility Patch & Config Installer "
echo "=========================================================="

# 1. Detect Game Directory
if [ -n "$1" ] && [ -d "$1" ]; then
    GAME_DIR="$1"
else
    CANDIDATES=(
        "$HOME/chat/dune/prefix/drive_c/Program Files (x86)/Gruntmods Studios/Dune 2000"
        "$HOME/dune/prefix/drive_c/Program Files (x86)/Gruntmods Studios/Dune 2000"
        "$HOME/.wine/drive_c/Program Files (x86)/Gruntmods Studios/Dune 2000"
    )
    for cand in "${CANDIDATES[@]}"; do
        if [ -d "$cand" ]; then GAME_DIR="$cand"; break; fi
    done
fi

if [ -z "$GAME_DIR" ] || [ ! -d "$GAME_DIR" ]; then
    echo "[-] Error: Could not locate Dune 2000 directory."
    echo "    Usage: $0 /path/to/Dune2000/folder"
    exit 1
fi
echo "[+] Game dir: $GAME_DIR"

# 2. Deploy config files
echo ""
echo "[1/3] Deploying configurations..."
cp -v "$CONFIGS_DIR/dune2000.ini" "$GAME_DIR/dune2000.ini"
cp -v "$CONFIGS_DIR/ddraw.ini"    "$GAME_DIR/ddraw.ini"

# 3. Import registry keys
echo ""
echo "[2/3] Importing Westwood registry keys..."
WINEPREFIX="${WINEPREFIX:-$(echo "$GAME_DIR" | awk -F'/drive_c' '{print $1}')}"
if [ -d "$WINEPREFIX" ] && [ -f "$CONFIGS_DIR/westwood.reg" ]; then
    WINE_CMD="hangover-wine"
    command -v hangover-wine >/dev/null 2>&1 || WINE_CMD="wine"
    WINEPREFIX="$WINEPREFIX" WINEDEBUG=-all $WINE_CMD regedit "$CONFIGS_DIR/westwood.reg" 2>/dev/null && echo "  Registry keys imported." || echo "  Registry import skipped."
fi

# 4. Run symlink patch
echo ""
echo "[3/3] Running filesystem compatibility patch..."
python3 "$SCRIPT_DIR/patch_symlinks.py" "$GAME_DIR"

echo ""
echo "Done! Launch with: bash $SCRIPT_DIR/play_dune2000.sh"
