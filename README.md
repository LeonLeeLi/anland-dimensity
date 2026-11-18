# Anland Dimensity

[简体中文](README_zh.md)

Anland displays a Linux Wayland desktop on Android. This fork is based on the `legacy` branch of [SuperTurtleDev/anland](https://github.com/SuperTurtleDev/anland/tree/236ae9c523c565a8b4dc21293e41288c44bd1591) and adds rendering paths for Dimensity devices with Mali GPUs.

## Architecture

The Android app (consumer) allocates the display buffers and presents the finished frames. A Linux compositor (producer) renders the desktop into those buffers. The display daemon pairs the two processes over a Unix socket and passes file descriptors for shared buffers and communication channels. The Android app sends input back to the compositor.

## Changes from upstream

- **KDE on Ubuntu 26.04** can initialize surfaceless EGL without a DRM render node, allowing Mesa to fall back to llvmpipe on devices that only expose `/dev/mali0`.
- **VirGL vtest** is available for KDE on Ubuntu 26.04 and for Niri. They render offscreen and copy SDR pixels into linear DMA-BUFs that the CPU can map. KDE frame delivery was verified on a Mali-G715 with VirGL. Niri's copy path was verified with llvmpipe.
- **Producer launchers** apply KGSL defaults only on compatible devices and preserve an explicitly selected render node. The shared VirGL launcher can select an existing virtio-gpu render node. Producers that require DRM/GBM still need a compatible node and buffer import. Gamescope also requires Vulkan with external DMA-BUF support.

## Repository layout

| Path | Contents |
| --- | --- |
| [`consumers/anland_v5/`](consumers/anland_v5/) | Android app and native consumer integration |
| [`producers/`](producers/) | KDE, GNOME, Hyprland, Niri, Mango, Denial, and Gamescope backends and distribution recipes |
| [`producers/common/`](producers/common/) | Shared build helpers and the [VirGL launcher](producers/common/anland-virgl.sh) |
| [`daemon/`](daemon/) and [`libdisplay_daemon/`](libdisplay_daemon/) | Display daemon entry point and connection broker |
| [`libdisplay_producer/`](libdisplay_producer/) and [`libdisplay_consumer/`](libdisplay_consumer/) | Shared display and transport libraries for the two sides |
| [`common/`](common/) | Protocol definitions and socket helpers |
| [`magisk_module/`](magisk_module/) | Android daemon packaging |
| [`doc/`](doc/) | [User guide](doc/UserManual/anland_guide.md) and [archived protocol versions](doc/History/) |
