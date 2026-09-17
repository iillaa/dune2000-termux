# Dune 2000 Native on Android (Termux)

Play the authentic 1998 Westwood PC RTS classic **Dune 2000** natively on Android devices (Qualcomm Snapdragon / Adreno GPUs) with hardware acceleration, 60 FPS gameplay, full live-action Westwood FMV cutscenes, and complete audio and music.

No virtual machines, no PC required, and no PRoot container overhead.

---

## Highlights

- **100% On-Device**: Runs inside standard Termux using native ARM64 Hangover Wine + Box64 Dynarec.
- **Hardware GPU Acceleration**: Adreno 650+ accelerated rendering via Turnip Vulkan driver and Mesa Zink OpenGL wrapper.
- **Multi-Core Performance**: Bypasses Westwood's 1998 single-core affinity lock to run across all Snapdragon Big & Prime Cores (up to 3.19 GHz).
- **Authentic Cutscenes**: Crystal-clear Westwood `.VQA` live-action video decoding without color banding or macroblock artifacts.
- **High-Fidelity Audio**: Full Frank Klepacki CD soundtrack, combat sound effects, and unit responses through low-latency PulseAudio.
- **Precision Input**: Full hardware mouse cursor locking and smooth edge-scrolling support for Bluetooth mice and keyboards.

---

## System Architecture

```
+-------------------------------------------------------------+
|               Android OS (Android 10 - 14)                  |
+-------------------------------------------------------------+
|                   Termux (Native ARM64)                     |
|                                                             |
|   +-------------------+              +------------------+   |
|   |    Termux-X11     |              |    PulseAudio    |   |
|   |  Display Server   |              |   Audio Server   |   |
|   +---------^---------+              +--------^---------+   |
|             |                                 |             |
|   +---------+---------------------------------+---------+   |
|   |                   Hangover Wine                     |   |
|   |               (ARM64 + WowBox64 x86)                |   |
|   |                                                     |   |
|   |   +---------------------------------------------+   |   |
|   |   |           Dune 2000 (DUNE2000.DAT)          |   |   |
|   |   |       - Community Patch v1.06p (Rev 42)     |   |   |
|   |   |       - cnc-ddraw DirectDraw to OpenGL      |   |   |
|   |   +---------------------------------------------+   |   |
|   +-----------------------------------------------------+   |
|                             |                               |
|        +--------------------+--------------------+          |
|        |                                         |          |
|   +----v---------------+               +---------v------+   |
|   |     Mesa Zink      |               |  Snapdragon    |   |
|   |  (OpenGL Wrapper)  |               | 870 Big Cores  |   |
|   +--------^-----------+               |    (Cores 4-7) |   |
|            |                           +----------------+   |
|   +--------v-----------+                                    |
|   |   Turnip Vulkan    |                                    |
|   |   (Adreno GPU)     |                                    |
|   +--------------------+                                    |
+-------------------------------------------------------------+
```

---

## Hardware Requirements

- **Processor**: Qualcomm Snapdragon 700 / 800 / 8-series recommended (e.g. Snapdragon 865, 870, 888, 8 Gen 1/2/3).
- **GPU**: Adreno 600 or 700 series with Turnip Vulkan driver support.
- **Memory**: Minimum 4 GB RAM (8 GB+ recommended).
- **Storage**: ~2.5 GB free internal storage for game assets, videos, and Wine prefix.
- **Input**: Bluetooth mouse + keyboard recommended for authentic RTS control.

---

## Repository Contents

- [`README.md`](README.md): Project overview and architecture.
- [`PROGRESS.md`](PROGRESS.md): Detailed diagnostic and engineering breakthrough log.
- [`TODO.md`](TODO.md): Remaining optimizations and roadmap for full automation.
- [`SETUP.md`](SETUP.md): Step-by-step setup guide and configuration reference.

---

## Status

- [x] Native Termux Hangover Wine execution
- [x] Adreno GPU acceleration (Turnip + Zink)
- [x] Multi-core CPU scheduling (Snapdragon Cores 4-7)
- [x] Westwood FMV cutscene decoding (`BOX64_DYNAREC_SAFEFLAGS=1`)
- [x] DirectSound audio & music unmuted
- [x] Case-folding filesystem fix (13,900+ symlinks)
- [x] Mission file prefix fix (844 un-underscored links)
- [x] Live Stage 1 battlefield gameplay verified
- [ ] Planetary territory scroll map transition under cnc-ddraw (Workaround: Select Mission)
- [ ] Automated 1-command installer script
