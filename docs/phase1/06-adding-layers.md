---
title: "Adding Layers & Configuring bblayers.conf"
description: "A detailed walkthrough of every Yocto layer used in this build, how to add them, and how to configure bblayers.conf."
---

# Adding Layers & Configuring `bblayers.conf`

<span class="phase-label">Phase 1 · Page 6 of 9</span>

!!! abstract "Page Goal"
    - Now that we have cloned all the necessary repositories, we need to tell Yocto's build engine (BitBake) about them. This is done by editing a configuration file called `bblayers.conf`.
    - This page explains what each layer provides, how to register them, and how to verify your layer setup is correct.

---

## Page Process Overview

```mermaid
flowchart LR
    A["Understand\nLayer Anatomy"] --> B["Review Each\nLayer's Purpose"]
    B --> C["Add Layers via\nbitbake-layers"]
    C --> D["Validate with\nbitbake-layers\nshow-layers"]
    D --> E["Update\nbblayers.conf\n(next page)"]
```

---
## What Is a Yocto Layer?

A layer is simply a folder with a specific structure that contains recipes (build instructions) and configuration files. Every layer follows the same basic layout:

```text
meta-example/
├── conf/
│   └── layer.conf          ← Layer configuration (name, priority, compatibility)
├── recipes-core/           ← Recipe directories organized by category
│   └── example/
│       └── example_1.0.bb  ← A recipe
├── recipes-kernel/
│   └── linux/
│       └── linux-example.bbappend  ← Modifies an existing recipe
├── classes/                ← Shared build logic (.bbclass files)
└── README                  ← Layer documentation
```

### Key Concepts:
- **`layer.conf`**: Every layer has this file in its `conf/` folder. It declares the layer's name, its priority (which layer "wins" if two layers define the same recipe), and which Yocto releases it is compatible with.
- **Layer Dependencies**: A layer can require other layers to be present. BitBake checks these dependencies automatically and will warn you if something is missing.
- **Priority (`BBFILE_PRIORITY`)**: If two layers provide a recipe with the same name, the one with the higher priority number takes precedence.

---

## Sourcing the Build Environment

Before you can add or check layers, you need to activate the Yocto build environment. This is done by "sourcing" (running) a setup script that configures your terminal session:

```bash
cd ~/yocto/poky
source oe-init-build-env 
```

!!! note "The Build Directory Location"
    By passing `poky/build` to the initialization script, the build folder is created inside the `poky` directory. Sourcing the script automatically changes your working directory to `~/yocto/poky/build/`.

---

## Sourcing & Initial `bblayers.conf`

Sourcing the environment script generates a baseline configuration directory (`conf/`) containing the `bblayers.conf` file. This configuration tells BitBake which layers are active.

By default, the initial generated `build/conf/bblayers.conf` file includes only the core Poky distribution metadata:

```bash
# POKY_BBLAYERS_CONF_VERSION is increased each time build/conf/bblayers.conf
# changes incompatibly
POKY_BBLAYERS_CONF_VERSION = "2"

BBPATH = "${TOPDIR}"
BBFILES ?= ""

BBLAYERS ?= " \
  /home/yocto/recreate/poky/meta \
  /home/yocto/recreate/poky/meta-poky \
  /home/yocto/recreate/poky/meta-yocto-bsp \
  "
```

---

## How to Add Layers

There are two primary methods to add a new layer to your build environment:

### Method 1: Using the `bitbake-layers` CLI (Recommended)
You can use the `bitbake-layers add-layer` utility to automatically register layers in your config. The path can be absolute, or **relative to your build directory** (`~/yocto/poky/build`).

Since the build directory is nested two levels deep inside `poky/build`, a layer located at `~/yocto/meta-tegra` is represented relatively as `../../meta-tegra`.

```bash
bitbake-layers add-layer ../../meta-tegra
```

Using relative paths makes your build directory portable across host environments (e.g., if you share your build configuration with another developer whose home directory path differs).

### Method 2: Manually Editing `bblayers.conf`
You can open `build/conf/bblayers.conf` in a text editor and add the absolute or relative path directly to the `BBLAYERS` list:

```bash
BBLAYERS ?= " \
  /home/yocto/recreate/poky/meta \
  /home/yocto/recreate/poky/meta-poky \
  /home/yocto/recreate/poky/meta-yocto-bsp \
  /home/yocto/recreate/meta-tegra \
  "
```

---

## Cloning the Optional `meta-qt5` Layer

If you plan to build graphical applications (GUIs) that run directly on the target device, you can add the Qt5 layer. Qt5 is a popular framework for building user interfaces.

!!! info "Status Note"
    Although `meta-qt5` packages are available in the recipe configuration, GUI components and real-time GUI plots are not actively tested in the core flight build image. 

Run the following command from the workspace parent directory (`~/yocto`) to clone `meta-qt5`:

```bash
git clone -b kirkstone https://github.com/meta-qt5/meta-qt5.git
```

---

## Detailed Build Layer Summary

| Layer | Repository Path | What It Provides |
|---|---|---|
| **meta** | `poky/meta` | Core OS components, systemd, compiler tools. |
| **meta-poky** | `poky/meta-poky` | Reference distribution configurations. |
| **meta-yocto-bsp** | `poky/meta-yocto-bsp` | Reference board support package configs. |
| **meta-tegra** | `meta-tegra` | NVIDIA Tegra L4T kernel, bootloader, and flashing scripts. |
| **meta-oe** | `meta-openembedded/meta-oe` | General utility packages (dependency for other sub-layers). |
| **meta-python** | `meta-openembedded/meta-python` | Python modules and utilities. |
| **meta-networking** | `meta-openembedded/meta-networking` | Network protocol utilities, SSH, and firewalls. |
| **meta-multimedia** | `meta-openembedded/meta-multimedia` | Audio/video processing tools. |
| **meta-gnome** | `meta-openembedded/meta-gnome` | GNOME desktop and library components. |
| **meta-xfce** | `meta-openembedded/meta-xfce` | Lightweight XFCE Desktop recipes. |
| **meta-ros-common** | `meta-ros/meta-ros-common` | Core ROS utilities and common build helpers. |
| **meta-ros2** | `meta-ros/meta-ros2` | Generic ROS 2 metadata recipes. |
| **meta-ros2-humble** | `meta-ros/meta-ros2-humble` | Specific ROS 2 Humble packages. |
| **meta-qt5** | `meta-qt5` | Qt5 applications, modules, and platform support. |

---

## Adding All Layers (Step-by-Step Commands)

Run these relative-path commands sequentially from the build directory (`~/yocto/poky/build`) to add the required layers in the correct dependency order:

```bash
# 1. Add NVIDIA BSP Layer
bitbake-layers add-layer ../../meta-tegra

# 2. Add OpenEmbedded Sub-Layers
bitbake-layers add-layer ../../meta-openembedded/meta-oe
bitbake-layers add-layer ../../meta-openembedded/meta-python
bitbake-layers add-layer ../../meta-openembedded/meta-networking
bitbake-layers add-layer ../../meta-openembedded/meta-multimedia
bitbake-layers add-layer ../../meta-openembedded/meta-gnome
bitbake-layers add-layer ../../meta-openembedded/meta-xfce

# 3. Add ROS and ROS 2 Layers
bitbake-layers add-layer ../../meta-ros/meta-ros-common
bitbake-layers add-layer ../../meta-ros/meta-ros2
bitbake-layers add-layer ../../meta-ros/meta-ros2-humble

# 4. Add Qt5 Layer (optional GUI libraries)
bitbake-layers add-layer ../../meta-qt5
```

---

## Final `bblayers.conf`

After adding all layers, your `bblayers.conf` file should list every layer path. Here are two ways it might look:

### Option A: Using Absolute Workspace Paths
This configuration maps to a static folder layout on the target build machine (using `/home/raigyocto` as an example):

```bash
# POKY_BBLAYERS_CONF_VERSION is increased each time build/conf/bblayers.conf
# changes incompatibly
POKY_BBLAYERS_CONF_VERSION = "2"

BBPATH = "${TOPDIR}"
BBFILES ?= ""

BBLAYERS ?= " \
  /home/yocto/poky/meta \
  /home/yocto/poky/meta-poky \
  /home/yocto/poky/meta-yocto-bsp \
  /home/yocto/meta-openembedded/meta-oe \
  /home/yocto/meta-openembedded/meta-python \
  /home/yocto/meta-openembedded/meta-networking \
  /home/yocto/meta-openembedded/meta-multimedia \
  /home/yocto/meta-openembedded/meta-gnome \
  /home/yocto/meta-openembedded/meta-xfce \
  /home/yocto/meta-ros/meta-ros-common \
  /home/yocto/meta-ros/meta-ros2 \
  /home/yocto/meta-ros/meta-ros2-humble \
  /home/yocto/meta-qt5 \
  /home/yocto/meta-tegra \
  "
```

### Option B: Using Relative Workspace Paths
This layout utilizes `../` and `../../` relative paths from the build environment context. It is the preferred method for sharing build directories:

```bash
# POKY_BBLAYERS_CONF_VERSION is increased each time build/conf/bblayers.conf
# changes incompatibly
POKY_BBLAYERS_CONF_VERSION = "2"


BBFILES ?= ""

BBLAYERS ?= " \
  /../meta \
  /../meta-poky \
  /../meta-yocto-bsp \
  /../../meta-openembedded/meta-oe \
  /../../meta-openembedded/meta-python \
  /../../meta-openembedded/meta-networking \
  /../../meta-openembedded/meta-multimedia \
  /../../meta-openembedded/meta-gnome \
  /../../meta-openembedded/meta-xfce \
  /../../meta-ros/meta-ros-common \
  /../../meta-ros/meta-ros2 \
  /../../meta-ros/meta-ros2-humble \
  /../../meta-qt5 \
  /../../meta-tegra \
  "
```

---

## Validating Layers

After adding all layers, verify the layer stack configuration by running the following command from your build directory:

```bash
bitbake-layers show-layers
```

### Expected Output
This command prints each registered layer, its file path, and its priority number. Higher priority layers override lower ones when recipes conflict:

```text
layer                 path                                                 priority
====================================================================================
meta                  /home/raigyocto/yocto/poky/meta                      5
meta-poky             /home/raigyocto/yocto/poky/meta-poky                 5
meta-yocto-bsp        /home/raigyocto/yocto/poky/meta-yocto-bsp             5
meta-oe               /home/raigyocto/yocto/meta-openembedded/meta-oe      5
meta-python           /home/raigyocto/yocto/meta-openembedded/meta-python  5
meta-networking       /home/raigyocto/yocto/meta-openembedded/meta-net...  5
meta-multimedia       /home/raigyocto/yocto/meta-openembedded/meta-mul...  5
meta-gnome            /home/raigyocto/yocto/meta-openembedded/meta-gnome   5
meta-xfce             /home/raigyocto/yocto/meta-openembedded/meta-xfce    6
meta-ros-common       /home/raigyocto/yocto/meta-ros/meta-ros-common       10
meta-ros2             /home/raigyocto/yocto/meta-ros/meta-ros2            11
meta-ros2-humble      /home/raigyocto/yocto/meta-ros/meta-ros2-humble      12
meta-qt5              /home/raigyocto/yocto/meta-qt5                       5
meta-tegra            /home/raigyocto/yocto/meta-tegra                     5
```

---

[← Cloning & Branching](05-cloning-and-branching.md){ .md-button }
[Next: Deep Dive — local.conf →](07-local-conf.md){ .md-button .md-button--primary }
