#!/usr/bin/env python3
"""
patch_symlinks.py - Automated Filesystem Compatibility Patch for Dune 2000 on Linux / Termux

Solves:
1. Linux case-sensitivity issues across 13,900+ game assets.
2. The Gruntmods underscore bug where 844 mission files were extracted as _H1V1.MIS while the engine looks for H1V1.mis.
3. Missing root directory symlinks for music, UI_GFX, UI_DATA, and bin.
"""

import os
import sys

def patch_game_directory(game_dir):
    if not os.path.isdir(game_dir):
        print(f"Error: Directory not found: {game_dir}")
        sys.exit(1)

    print(f"Patching Dune 2000 installation at: {game_dir}")

    # 1. Root-level compatibility symlinks
    root_links = {
        "music": "data/Music",
        "Music": "data/Music",
        "movies": "movies",
        "Movies": "movies",
        "data": "data",
        "Data": "data",
        "DATA": "data",
        "UI_GFX": "data/UI_GFX",
        "UI_gfx": "data/UI_GFX",
        "ui_gfx": "data/UI_GFX",
        "UI_DATA": "data/UI_DATA",
        "UI_data": "data/UI_DATA",
        "ui_data": "data/UI_DATA",
        "bin": "data/bin",
        "GAMESFX": "data/GAMESFX",
        "gamesfx": "data/GAMESFX",
        "GAMESFXEng": "data/GAMESFXEng",
    }

    print("\n[1/3] Creating root folder symlinks...")
    for link_name, target in root_links.items():
        link_path = os.path.join(game_dir, link_name)
        target_path = os.path.join(game_dir, target)
        if os.path.exists(target_path) and not os.path.exists(link_path):
            try:
                os.symlink(target, link_path)
                print(f"  Linked: {link_name} -> {target}")
            except OSError as e:
                print(f"  Warning linking {link_name}: {e}")

    # 2. Case-folding symlinks (lowercase versions of all files & folders)
    print("\n[2/3] Generating case-folding symlinks...")
    case_created = 0
    for root, dirs, files in os.walk(game_dir):
        for d in list(dirs):
            low_d = d.lower()
            if low_d != d:
                target = os.path.join(root, low_d)
                if not os.path.exists(target):
                    try:
                        os.symlink(d, target)
                        case_created += 1
                    except OSError:
                        pass
        for f in files:
            low_f = f.lower()
            if low_f != f:
                target = os.path.join(root, low_f)
                if not os.path.exists(target):
                    try:
                        os.symlink(f, target)
                        case_created += 1
                    except OSError:
                        pass
    print(f"  Generated {case_created} case-folding symlinks.")

    # 3. Un-underscore mission files (_H1V1.MIS -> H1V1.mis)
    print("\n[3/3] Generating un-underscored mission symlinks...")
    mission_created = 0
    for root, dirs, files in os.walk(game_dir):
        for f in files:
            if f.startswith('_'):
                clean = f[1:]
                for variant in [clean, clean.lower(), clean.upper()]:
                    target = os.path.join(root, variant)
                    if not os.path.exists(target):
                        try:
                            os.symlink(f, target)
                            mission_created += 1
                        except OSError:
                            pass
    # 4. Unmute music volume in dune2000.cfg if byte 0 is 0
    print("\n[4/4] Checking dune2000.cfg volume settings...")
    cfg_path = os.path.join(game_dir, "dune2000.cfg")
    if os.path.isfile(cfg_path):
        try:
            with open(cfg_path, "rb") as f:
                cfg_data = bytearray(f.read())
            if len(cfg_data) > 0 and cfg_data[0] == 0:
                cfg_data[0] = 10
                with open(cfg_path, "wb") as f:
                    f.write(cfg_data)
                print("  Unmuted Byte 0 (Music Volume) from 0 to 10 in dune2000.cfg.")
            else:
                print("  dune2000.cfg volume is already configured.")
        except Exception as e:
            print(f"  Warning checking dune2000.cfg: {e}")
    else:
        print("  dune2000.cfg not found (will be created on first game launch).")

    print("\nCompatibility patching complete! All assets are now resolvable by Westwood engine.")

if __name__ == "__main__":
    target_dir = sys.argv[1] if len(sys.argv) > 1 else os.getcwd()
    patch_game_directory(target_dir)
