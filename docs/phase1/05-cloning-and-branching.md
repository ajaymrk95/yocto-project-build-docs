---
title: "Cloning the Necessary Repositories and Folder Structure"
description: "Clone all required repositories, align on the Kirkstone branch, and set up the project workspace for the Jetson TX2i Yocto build."
---

# Cloning the Necessary Repositories and Folder Structure

<span class="phase-label">Phase 1 · Page 5 of 9</span>

!!! abstract "Page Goal"
    - Building up from the quick build setup on Page 1 - Page 4, add Yocto Layers that allow us to build a Linux Image that runs on Specific Target Hardware - The Jetson TX2i with the TX2 Developer Kit.

    - This document also explains some other important layers which are necessary to provide additional software functionality and importance of maintaining a consistent branch/release accross all layers.

---

!!! info "Generalised Example — Customizing a Build for Specific Hardware"
    The official Yocto Project Quick Build guide includes a concise walkthrough of how to add a hardware layer and target a specific machine in its
    [**Customizing Your Build for Specific Hardware**](https://docs.yoctoproject.org/kirkstone/brief-yoctoprojectqs/index.html#customizing-your-build-for-specific-hardware){:target="_blank"} section.

    That example uses the **meta-altera** BSP layer and the **cyclone5** machine as a minimal demonstration of:

    1. **Finding and cloning a hardware layer** (e.g. `git clone` of `meta-altera` into the Poky directory).
    2. **Setting the `MACHINE` variable** in `local.conf` to target the new hardware.
    3. **Registering the layer** using `bitbake-layers add-layer`.

    It is a great starting point if you want to understand the general workflow before diving into the project-specific setup below, where we apply the same concepts to build for the **NVIDIA Jetson TX2i** using the **meta-tegra** BSP layer and multiple companion layers.

---



## Project Workspace Layout

Before cloning, establish a parent folder, this is a simple way to keep the project organised. The parent folder contains all the cloned layers including poky. This way the `build` directory is 2 levels below all the cloned layers and running bitbake to add layers is straightforward. 

```bash
mkdir -p ~/yocto && cd ~/yocto
```

## Metadata vs. Build Data

!!! note "Understanding Yocto Metadata"
    Yocto layers contain *metadata* (recipes `.bb`, appends `.bbappend`, classes `.bbclass`, and configurations `.conf`). Simply cloning these repositories onto your host system does **not** add their data, packages, or configurations to the final build image.

    To use these layers in your build, you must:
    1. Explicitly register them in your build configuration file (`build/conf/bblayers.conf`).
    2. Explicitly request the packages you want to install in the final image (e.g., using `IMAGE_INSTALL:append` in `local.conf` or referencing them in your custom image recipe).

---

## What is a BSP Layer?

A **BSP (Board Support Package) Layer** is a collection of hardware-specific recipe metadata, configuration files, and software tools required to enable a specific physical target hardware platform to boot and run Linux. 

In a Yocto Project environment, a BSP layer sits near the bottom of the layer stack and translates generic OS packages into machine-usable binaries. It typically supplies:
- Bootloader configuration and build files (e.g., U-Boot, CBoot, coreboot).
- Target-specific kernel versions, patches, and configurations.
- Device tree sources (DTS) and binaries (DTB) representing the board layout.
- Hardware-accelerated drivers (such as GPU, display, and multimedia decoders).

---

## Active Branches & Hardware Support Strategy

To support target devices using the **meta-tegra** BSP layer (the official community-driven Yocto layer for NVIDIA Jetson platforms), we look to the official documentation at [oe4t.github.io](https://oe4t.github.io). 

As of the latest updates (May 2026), the active branches for the meta-tegra layer correspond to specific hardware generations and L4T (Linux for Tegra) versions:

| Branch Name | Stability | L4T / JetPack Release | Supported Platforms |
|---|---|---|---|
| `master` | Unstable | L4T R36.5.0 / JetPack 6.2.2 | AGX Orin, Orin NX, Orin Nano |
| `master-l4t-r38.4.x` | Unstable | L4T R38.4.0 / JetPack 7.1 | AGX Thor |
| `wrynose` | Stable | L4T R36.5.0 / JetPack 6.2.2 | AGX Orin, Orin NX, Orin Nano |
| `whinlatter` | Stable | L4T R36.4.4 / JetPack 6.2.1 | AGX Orin, Orin NX, Orin Nano |
| `scarthgap` | Stable | L4T R36.5.0 / JetPack 6.2.2 | AGX Orin, Orin NX, Orin Nano |
| `scarthgap-l4t-r35.x` | Stable | L4T R35.6.4 / JetPack 5.1.6 | AGX Xavier, Xavier NX, AGX Orin, Orin NX, Orin Nano |
| `kirkstone` | Stable | L4T R35.6.4 / JetPack 5.1.6 | AGX Xavier, Xavier NX, AGX Orin, Orin NX, Orin Nano |
| **`kirkstone-l4t-r32.7.x`** | **Stable** | **L4T R32.7.6 / JetPack 4.6.6** | **TX1, TX2, TX2-NX, Xavier, Xavier-NX, Nano, Nano-2GB** |

!!! note "Hardware Compatibility Limitation"
    Because we are building for the **Jetson TX2i** (a TX2-series module), the regular `kirkstone` branch of `meta-tegra` does not support our target platform. We **must** use the specialized **`kirkstone-l4t-r32.7.x`** branch of `meta-tegra` to maintain support for TX2-series hardware while aligning with the stable Kirkstone environment.

---

## Why Branch Alignment is Critical

`kirkstone` is a stable release of the Yocto Project. To ensure a successful build, all companion layers must remain aligned to the `kirkstone` release cycle.

!!! warning "The Danger of Mixing Branches"
    Mixing branches (e.g., using `kirkstone` for Poky and `dunfell - an older yocto release` for OpenEmbedded/ROS layers) will introduce severe underlying conflicts in:
    - **Git links and source endpoints**: Repositories constantly change URLs, hashes, and tag schemes between releases, leading to build-time fetcher errors.
    - **BitBake syntax and API changes**: Internal variables, override character syntax (e.g., the transition from underscore `_` to colon `:` overrides), and Python class APIs change, causing syntax/parsing errors.
    - **Package dependency issues**: Mixing branches leads to package name mismatches, mismatched library versions, and missing packages.

---

## Cloning the Necessary Layers (HTTPS)

Execute these commands to clone the correct branches of each layer into your project parent directory:

### 1. Poky (Reference Distribution)
The main reference build system framework.
```bash
git clone -b kirkstone https://git.yoctoproject.org/git/poky
```

### 2. meta-tegra (NVIDIA BSP Layer)
Provides the specific board support files, flashing scripts, and kernel drivers for Tegra modules.
```bash
git clone -b kirkstone-l4t-r32.7.x https://github.com/OE4T/meta-tegra.git
```

### 3. meta-openembedded (Main System Utilities)
The primary collection of metadata layers providing a wide array of system software, Python runtimes, GNU/GCC tooling, networking utilities, and graphical user interfaces.
```bash
git clone -b kirkstone https://github.com/openembedded/meta-openembedded.git
```
### 4. meta-ros (Robot Operating System Layer)
Brings ROS/ROS 2 libraries, build systems (like `catkin` and `ament`), and packages to the Yocto platform for edge robotic operations.
```bash
git clone -b kirkstone https://github.com/ros/meta-ros.git
```

---

## Workspace Folder Structure

After cloning, your project folder should look like the tree below. Take a moment to verify your layout matches — if folders are in the wrong place, later steps will fail:

```text
~/yocto/                          ← Project Workspace Root
├── poky/                         ← Reference Distribution Repo
│   ├── bitbake/                  ← BitBake engine files
│   ├── meta/                     ← OpenEmbedded Core metadata
│   ├── meta-poky/                ← Poky distribution configurations
│   ├── meta-selftest/            ← Poky test suites
│   ├── meta-yocto-bsp/           ← Reference hardware board support
│   ├── oe-init-build-env         ← Initialization script
│   └── build/                    ← Active Build Directory (created by oe-init-build-env)
│       ├── conf/                 ← Environment Configuration
│       │   ├── bblayers.conf     ← Layer path registration
│       │   └── local.conf        ← Machine, package, and distribution settings
│       │
│       ├── downloads/            ← Downloaded source tarballs & git checkouts
│       ├── sstate-cache/         ← Shared state cache for build speedup
│       └── tmp/                  ← Compiler outputs, rootfs, and final images
│
├── meta-tegra/                   ← NVIDIA Jetson BSP Layer Repo
│   ├── classes/                  ← Tegra-specific helper classes
│   ├── conf/                     ← Machine/layer configuration files
│   ├── recipes-bsp/              ← Bootloader, flash scripts, device tree recipes
│   ├── recipes-devtools/         ← Flash tools and host utilities
│   └── recipes-kernel/           ← NVIDIA L4T Linux kernel recipes & patches
│
├── meta-openembedded/            ← Multi-utility Core Layers Repo
│   ├── meta-filesystems/         ← Ext4, XFS, and network filesystem recipes
│   ├── meta-gnome/               ← GNOME environment software
│   ├── meta-multimedia/          ← Audio and video codecs/libraries
│   ├── meta-networking/          ← Networking daemons, tools, and libraries
│   ├── meta-oe/                  ← Core system software, libraries, and Python
│   ├── meta-perl/                ← Perl language dependencies
│   ├── meta-python/              ← Additional Python 3 modules
│   └── meta-xfce/                ← XFCE desktop packages
│
└── meta-ros/                     ← ROS/ROS 2 Layer Repo
    ├── meta-ros-common/          ← Common ROS infrastructure
    ├── meta-ros1/                ← ROS 1 (Noetic) recipes
    ├── meta-ros1-noetic/         ← Specific Noetic packages
    ├── meta-ros2/                ← ROS 2 recipes
    └── meta-ros2-humble/         ← Specific Humble packages
```

---

[← Quick Build](04-quick-build.md){ .md-button }
[Next: Adding Layers →](06-adding-layers.md){ .md-button .md-button--primary }
