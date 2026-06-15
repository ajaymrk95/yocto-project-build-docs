---
title: "Deep Dive: local.conf"
description: "A complete guide to local.conf — the single most important configuration file in your Yocto build. Covers MACHINE, DISTRO, IMAGE_INSTALL, build tuning, and a full annotated config."
---

# Deep Dive: `local.conf`

<span class="phase-label">Phase 1 · Page 7 of 9</span>

!!! abstract "Page Goal"
    Understand  `local.conf` configuration, how to add packages and what does a full fledged local.conf look like.

---

## Where Is `local.conf`?

The `local.conf` file is the primary configuration file for your individual Yocto Project build environment. It is located inside the build directory:

```text
~/yocto/poky/build/conf/local.conf
```

---

## Setting the Target MACHINE

The `MACHINE` variable tells BitBake which hardware configuration to build for. Valid machine targets correspond to `.conf` configuration files inside your BSP layers.

### Finding Valid Machines
You can list the machine configurations supported by `meta-tegra` by browsing the layer:

```bash
ls ~/yocto/meta-tegra/conf/machine/
```

For the Jetson TX2i system-on-module mounted on the standard development board, the correct machine identifier is:

```bash
MACHINE = "jetson-tx2-devkit-tx2i"
```

!!! note "Note"
    Ensure the machine name exactly matches the filename in the BSP layer. An incorrect machine name will result in `Nothing PROVIDES 'virtual/kernel'` errors during the build initialization.

---

## Understanding BitBake Syntax: `+=` vs. `:append`

Editing list variables in Yocto requires understanding BitBake assignment operators:

- **`+=` (Append with Space)**: Adds a value to a list with an automatically prepended space. However, this is evaluated in-order during parsing and can be overridden or reset by subsequent direct assignments (`=`).
- **`:append` (Override Append)**: An override operator that is evaluated at the very end of the BitBake parsing cycle. It appends the string exactly as written (requires leading whitespace inside the quotes) and cannot be overridden by other assignments.
- **`:remove` (Override Remove)**: An override operator evaluated at the end of parsing that searches for and removes specific string values from a list.

!!! note "Kirkstone Override Syntax"
    In older Yocto releases (such as Dunfell), overrides used underscores (e.g. `IMAGE_INSTALL_append = " ..."`). Starting with the **Kirkstone** release, Yocto transitioned to colons (e.g. `IMAGE_INSTALL:append = " ..."`). Mixing syntax styles will cause parse failures.

---

## Variable Explanations

Here is a breakdown of the critical variables defined in `local.conf` (we are building for core-image-sato here):

### 1. Machine & Core Settings
- `MACHINE`: Sets the target machine (`jetson-tx2-devkit-tx2i`).
- `DISTRO`: Sets the target base distribution configuration (`poky`).
- `PACKAGE_CLASSES`: Selects the packaging format. We use `package_deb` to generate Debian packages, enabling `apt` package manager updates on the target.
- `SDKMACHINE`: Sets the host architecture configuration for SDK installers (`x86_64`).

### 2. Build Performance & Space Saving
- `BB_NUMBER_THREADS`: The maximum number of tasks BitBake can run concurrently. Set this to match your host machine's physical CPU cores.
- `PARALLEL_MAKE`: The `-j` compiler job flag passed to `make`.
- `rm_work` (optional): Inheriting this class via `INHERIT += "rm_work"` deletes intermediate build files (like unpacked source directories and object files) after each recipe finishes building, saving hundreds of gigabytes of disk space.

### 3. Image & Storage Configuration
- `IMAGE_CLASSES`: Adds helper classes for flashing. `image_types_tegra` enables NVIDIA Tegra-specific flashing image formats.
- `IMAGE_FSTYPES`: The formats of the root filesystem built (`tegraflash` for Tegra flash tool compatible formats, `tar.gz` for archives, and `ext4` for raw filesystem mounting).
- `ROOTFSPART_SIZE`: The exact size of the target system partition in bytes.
- `IMAGE_ROOTFS_EXTRA_SPACE`: Extra space buffer (in KB) added to the rootfs partition to ensure write capacity.

### 4. System Features & Init Manager
- `DISTRO_FEATURES`: Global features to include in the OS. We append `systemd`, `opengl`, and `x11` to support hardware graphics and desktop integration, and explicitly remove `wayland` and `connman` to avoid conflicts.
- `VIRTUAL-RUNTIME_init_manager`: Configures Systemd as the active initialization manager and adds sysvinit as the fallback system manager.
- `IMAGE_FEATURES`: Specifies high-level package features (switches) to include in the target image. It allows bringing in pre-grouped sets of packages. In `local.conf`, developers typically use `EXTRA_IMAGE_FEATURES` to add features globally without modifying image recipes, but `IMAGE_FEATURES` can also be modified directly.
  - `debug-tweaks`: Bypasses post-installation check blockers, enables empty root passwords, and configures the system for quick debugging.
  - `tools-sdk`: Adds development tools (headers, make, compilers) directly to the target system.
  - `allow-root-login`: Configures the SSH and PAM modules to allow logging in directly as the `root` user.
  - `dev-pkgs`: Installs development headers (`-dev` packages) for every package compiled into the root filesystem. This is for native compilation on the Jetson.

### 5. ROS 2 Humble Integration
- `ROS_OE_RELEASE_SERIES`: Pins the ROS OpenEmbedded compatibility metadata to `kirkstone`.
- `ROS_DISTRO`: Selects the ROS distribution (`humble`).
- `IMAGE_INSTALL:append`: Registers ROS 2 CLI utilities, parameters, node management tools, client libraries (`rclcpp`, `rclpy`), messages, and the CMake build compiler (`ament-cmake`).

### 6. NVIDIA Accelerated Drivers & CUDA
- `PREFERRED_PROVIDER`: Configures the build to use NVIDIA Tegra hardware accelerated GL and EGL libraries (`libgles-nvidia-tegra`) instead of generic software equivalents.
- `LICENSE_FLAGS_ACCEPTED`: Accepting `commercial` is required to allow Yocto to fetch and build packages with restricted licensing terms.
- `cuda-toolkit` & `tensorrt`: Installs NVIDIA CUDA compiler tools (`nvcc`), system telemetry tools (`tegrastats`), neural network runtimes (`cudnn`), and TensorRT plugins directly to the target system image.

### 7. Localization, QA, & Network Manager Overrides
- `ERROR_QA:remove` & `WARN_QA:remove`: Suppresses specific Quality Assurance checks performed by BitBake during packaging:
  - `version-going-backwards`: Bypasses version validation checks, useful when incorporating third-party layers or pre-built binary layers where strict incrementing isn't followed.
  - `build-deps`: Suppresses warnings about undeclared build dependencies that are satisfied by the host system.
- `PACKAGECONFIG:append:pn-qemu-system-native = " sdl"`: Enables SDL support for the native QEMU package to allow graphical emulation of display outputs on the host system.
- `PACKAGE_FEED_SKIP_HTTP_PROXY = "1"`: Instructs the package manager (`apt`/`dpkg`) on the target to bypass configured HTTP proxies when pulling updates from the local build's package feed.
- `BAD_RECOMMENDATIONS`: Prevents recommended packages from being automatically pulled in as dependencies. We list `connman` and `connman-gnome` to ensure they are never installed.
- `PACKAGECONFIG:remove:pn-packagegroup-core-x11-sato = "connman"`: Strips Connman support out of the sato core X11 packagegroup configuration.
- `NETWORK_MANAGER = "networkmanager"`: Sets the global network manager system variable to `"networkmanager"`.

---

## Adding Individual Packages via OpenEmbedded Layer Index

When customizing the base Linux image, you will inevitably need to add additional third-party software packages or libraries. 

### Sourcing Packages Safely
1. **Visit the OpenEmbedded Layer Index**: Go to [OpenEmbedded Layer Index](https://layers.openembedded.org/) (layers.openembedded.org). This is the official database for Yocto and OpenEmbedded.
2. **Search for Recipes**: Search for the utility or library you need. The index will show you which layer provides the recipe (e.g., `meta-oe`, `meta-python`, or `meta-networking`) and its availability across Yocto branches (like `kirkstone`).
3. **Verify Dependencies**: Make sure you have already cloned and registered the layer that provides the recipe (e.g. in your `bblayers.conf`) before adding the package name to `IMAGE_INSTALL:append` in `local.conf`.

### Using AI Helpers
- You can use AI to speed up this process by generating package sections or recommendations.
- **Important**: You must cross-reference and validate all AI-suggested package names against the OpenEmbedded Layer Index or the actual recipe files (`.bb`). Package names can differ slightly between Yocto branches (e.g., Python packages prefixed with `python3-` vs `python-`), and incorrect entries will trigger compile-time parse errors or build-time dependency conflicts that must be resolved during compilation.

---

## Copy-Pasteable `local.conf`

Replace the contents of `poky/build/conf/local.conf` with this verified configuration:

```bash
# 1. Machine & Core Settings
# Target hardware configuration matching meta-tegra
MACHINE = "jetson-tx2-devkit-tx2i"
# Target base distribution
DISTRO ?= "poky"
# Target packaging format (enables apt on device)
PACKAGE_CLASSES ?= "package_deb"
# Host SDK compilation target
SDKMACHINE ?= "x86_64"

# 2. Build Performance & Space Saving
# Multi-threaded BitBake tasks (adjust to match host CPU)
BB_NUMBER_THREADS = "20"
# Parallel compilation make jobs
PARALLEL_MAKE = "-j 16"
# Remove intermediate work files to save space (uncomment to enable)
#INHERIT += "rm_work"

# 3. Image & Storage Configuration
# Tegra flash image helper classes
IMAGE_CLASSES += "image_types_tegra"
# Target partition formats generated
IMAGE_FSTYPES = "tegraflash tar.gz ext4"
# Size of the root filesystem partition on the module
ROOTFSPART_SIZE = "14000000000"
# Extra filesystem padding in kilobytes
IMAGE_ROOTFS_EXTRA_SPACE = "1048576"

# 4. System Features & Init Manager (Required for X11 & XFCE Integration)
# Enable graphic libraries and NetworkManager services
DISTRO_FEATURES:append = " x11 opengl systemd polkit gobject-introspection-data networkmanager"                        
# Remove unneeded display servers and network managers
DISTRO_FEATURES:remove = "wayland connman"

# Configure root access and development libraries
IMAGE_FEATURES += "debug-tweaks tools-sdk allow-root-login dev-pkgs"
USER_CLASSES ?= "buildstats"

# Select Systemd as default system init manager
VIRTUAL-RUNTIME_init_manager = "systemd"
DISTRO_FEATURES_BACKFILL_CONSIDERED += "sysvinit"
VIRTUAL-RUNTIME_initscripts = "systemd-compat-units"

# 5. Base Software & Exclusive Networking
# Base firmware, drivers, Python interpreter, and CLI utility packages
IMAGE_INSTALL:append = " \
    linux-firmware-bcm4354 kernel-modules \
    python3 python3-modules python3-pip \
    pciutils usbutils htop ethtool i2c-tools \
    gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-tegra \
    avahi-daemon libnss-mdns net-tools iproute2 tmux apt dpkg systemd-extra-utils \
"

# NetworkManager tools for network control
IMAGE_INSTALL:append = " \
    networkmanager \
    networkmanager-nmcli \
    networkmanager-nmtui \
    network-manager-applet \
"
# Exclude Connman packages to prevent service conflicts
PACKAGE_EXCLUDE = "connman connman-gnome connman-client"

# 6. Complete XFCE4 Desktop Environment
# Desktop interface packages (uncommented to enable graphic interface)
IMAGE_INSTALL:append = " \
    packagegroup-core-x11-xserver \
    packagegroup-xfce-base \
    xfce4-screenshooter \
    xfwm4 \
    xfce4-panel \
    xfdesktop \
    xfce4-settings \
    xfce4-terminal \
    thunar \
    thunar-volman \
    garcon \
    exo \
    xfconf \
    xinit \
"

# 7. ROS 2 Humble Core & Native Python Compilation Stack
# Pin ROS distribution variables
ROS_OE_RELEASE_SERIES = "kirkstone" 
ROS_DISTRO = "humble"

# ROS client libraries, CLI nodes, build tools, and numpy compilation stack
IMAGE_INSTALL:append = " \
    ros-environment \
    packagegroup-core-buildessential \
    ros2run \
    ros2topic \
    ros2node \
    ros2pkg \
    ros2interface \
    ros2param \
    rclcpp \
    rclpy \
    std-msgs \
    sensor-msgs \
    geometry-msgs \
    nav-msgs \
    pluginlib \
    class-loader \
    rosidl-default-generators \
    rosidl-default-runtime \
    cmake \
    python3-six \
    python3-setuptools \
    python3-netifaces \
    python3-numpy \
    ros-workspace \
    ament-cmake \
    ament-cmake-python \
    python3-colcon-core \
    python3-colcon-common-extensions \
    python3-colcon-ros \
    python3-colcon-cmake \
    python3-colcon-bash \
"

# 8. NVIDIA Driver Overrides & Qt5 HW Acceleration
# Override standard mesa packages with proprietary NVIDIA drivers
PREFERRED_PROVIDER_virtual/libgles1 = "libgles-nvidia-tegra"
PREFERRED_PROVIDER_virtual/libgles2 = "libgles-nvidia-tegra"
PREFERRED_PROVIDER_virtual/egl = "libegl-nvidia-tegra"
PREFERRED_VERSION_libglvnd = "1.4.0"

# Accept commercial license constraints for hardware decoding
LICENSE_FLAGS_ACCEPTED += "commercial"
# Qt5 configuration flags for graphics rendering
PACKAGECONFIG:append:pn-qtbase = " gles2 eglfs x11 libinput gl"
PACKAGECONFIG:remove:pn-qtbase = "wayland"
PACKAGECONFIG:append:pn-qtmultimedia = " gstreamer"

IMAGE_INSTALL:append = " qtbase qtbase-plugins"
PACKAGECONFIG:append:pn-gstreamer1.0-plugins-bad = " vulkan"

# 9. Localization & QA Fixes
# Glibc locales for UTF-8 compatibility
IMAGE_INSTALL:append = " glibc-utils localedef"
GLIBC_GENERATE_LOCALES = "en_US.UTF-8"
IMAGE_LINGUAS = "en-us"
ENABLE_BINARY_LOCALE_GENERATION = "1"

# Suppress QA checks for backward versioning and build dependencies
ERROR_QA:remove = "version-going-backwards build-deps"
WARN_QA:remove = "build-deps"
PACKAGECONFIG:append:pn-qemu-system-native = " sdl"

# Network manager overrides
PACKAGE_FEED_SKIP_HTTP_PROXY = "1"
BAD_RECOMMENDATIONS += "connman-gnome connman"

PACKAGECONFIG:remove:pn-packagegroup-core-x11-sato = "connman"
NETWORK_MANAGER = "networkmanager"

# 10. NVIDIA CUDA Toolkit & TensorRT Acceleration
# CUDA compiler utilities
IMAGE_INSTALL:append = " \
    cuda-toolkit \
    cuda-nvcc \
    tegra-tools-tegrastats \
    tegra-tools-jetson-clocks \
"

# TensorRT neural runtimes and plugins
IMAGE_INSTALL:append = " \
    cudnn \
    tensorrt-core \
    tensorrt-plugins \
    tensorrt-trtexec \
"
```

---

[← Adding Layers & bblayers.conf](06-adding-layers.md){ .md-button }
[Next: The Build Process Explained →](08-build-process.md){ .md-button .md-button--primary }
