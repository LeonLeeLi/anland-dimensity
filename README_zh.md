# Anland Dimensity

[English](README.md)

Anland 将 Linux Wayland 桌面显示在 Android 上。本仓库基于 [SuperTurtleDev/anland 的 `legacy` 分支](https://github.com/SuperTurtleDev/anland/tree/236ae9c523c565a8b4dc21293e41288c44bd1591)，增加了面向天玑 Mali 设备的渲染支持。

## 项目架构

Android 应用（消费端）分配显示缓冲区并呈现画面，Linux 合成器（生产端）负责把桌面渲染到这些缓冲区。显示守护进程通过 Unix socket 配对两端，并传递共享缓冲区和通信通道的文件描述符。触控、键盘等输入由 Android 应用传回合成器。

## 相比上游的改动

- **Ubuntu 26.04 KDE** 在没有 DRM 渲染节点时可以继续初始化 surfaceless EGL，让只暴露 `/dev/mali0` 的设备有机会使用 Mesa 的 llvmpipe 软件渲染。
- **VirGL vtest** 支持 Ubuntu 26.04 KDE 和 Niri。合成器离屏渲染，再把 SDR 像素拷贝到 CPU 可映射的线性 DMA-BUF。KDE 已在 Mali-G715 上验证 VirGL 出帧，Niri 的拷贝路径已用 llvmpipe 验证。
- **各桌面启动脚本**只在适用设备上设置 KGSL 默认值，并保留显式指定的渲染节点。共用的 VirGL 启动器可以选择已有的 virtio-gpu 渲染节点。依赖 DRM/GBM 的桌面仍需要可用的设备和缓冲区导入，Gamescope 还需要支持外部 DMA-BUF 的 Vulkan 驱动。

## 目录结构

| 路径 | 内容 |
| --- | --- |
| [`consumers/anland_v5/`](consumers/anland_v5/) | Android 应用及原生消费端接入 |
| [`producers/`](producers/) | KDE、GNOME、Hyprland、Niri、Mango、Denial 和 Gamescope 后端，以及各发行版的构建和启动脚本 |
| [`producers/common/`](producers/common/) | 共用构建工具和 [VirGL 启动器](producers/common/anland-virgl.sh) |
| [`daemon/`](daemon/) 和 [`libdisplay_daemon/`](libdisplay_daemon/) | 显示守护进程入口和连接管理 |
| [`libdisplay_producer/`](libdisplay_producer/) 和 [`libdisplay_consumer/`](libdisplay_consumer/) | 生产端和消费端的共享显示与传输库 |
| [`common/`](common/) | 协议定义和 socket 工具 |
| [`magisk_module/`](magisk_module/) | Android 守护进程的 Magisk 打包文件 |
| [`doc/`](doc/) | [使用指南](doc/UserManual/anland_guide_zh.md)和[历史协议文档](doc/History/) |
