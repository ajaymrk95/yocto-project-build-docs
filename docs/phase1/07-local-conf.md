---
title: "Deep Dive: local.conf"
description: "A complete guide to local.conf — the single most important configuration file in your Yocto build. Covers MACHINE, DISTRO, IMAGE_INSTALL, build tuning, and a full annotated config."
---

# Deep Dive: `local.conf`

<span class="phase-label">Phase 1 · Page 7 of 9</span>

!!! abstract "Page Goal"
    Understand `local.conf` — the single most important configuration file in your Yocto build. This is where you tell Yocto what hardware to target, what software to include, and how to optimise the build. By the end of this page, you will have a complete, ready-to-use `local.conf` file.

---

## Where Is `local.conf`?

The `local.conf` file lives inside your build directory. It is the main file you edit to control what your custom OS looks like:

```text
~/yocto/poky/build/conf/local.conf
```

---

## Setting the Target Machine

The `MACHINE` variable tells BitBake which board you are building for. Each supported board has a matching `.conf` file inside the BSP layer.

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

## What Each Variable Does

Here is a plain-English breakdown of every important variable in `local.conf`. We are building for the `core-image-sato` image (a basic Linux image with a graphical desktop):

### 1. Machine & Core Settings
- `MACHINE`: Which board to build for (`jetson-tx2-devkit-tx2i` — our NVIDIA Jetson TX2i).
- `DISTRO`: The base distribution template. We use `poky` (the Yocto default).
- `PACKAGE_CLASSES`: How to package software. We use `package_deb` (Debian `.deb` packages), which lets us use the `apt` package manager on the device later.
- `SDKMACHINE`: Architecture of your build computer. Almost always `x86_64` for modern desktops.

### 2. Build Performance & Disk Space
- `BB_NUMBER_THREADS`: How many build tasks to run at the same time. Set this to match your CPU core count (e.g., 20 for a 20-core processor).
- `PARALLEL_MAKE`: How many compiler jobs to run in parallel within each task. Similar to `BB_NUMBER_THREADS` but controls the `make -j` flag.
- `rm_work` (optional): If you are low on disk space, enabling this class (`INHERIT += "rm_work"`) tells Yocto to delete temporary build files after each package finishes. This can save hundreds of gigabytes.

### 3. Image & Storage Configuration
- `IMAGE_CLASSES`: Adds helper classes needed for specific image formats. `image_types_tegra` enables NVIDIA's special flash image format.
- `IMAGE_FSTYPES`: The output file formats for your OS image. `tegraflash` is needed to flash NVIDIA boards, `tar.gz` for archives, and `ext4` for a standard Linux filesystem.
- `ROOTFSPART_SIZE`: How big to make the root filesystem partition on the device (in bytes). This must be large enough to hold all your software.
- `IMAGE_ROOTFS_EXTRA_SPACE`: Extra free space (in KB) added to the root partition as a buffer so the device does not run out of storage.

### 4. System Features & Startup Manager
- `DISTRO_FEATURES`: Global features to include in the OS. We add `systemd` (modern startup manager), `opengl` (3D graphics support), and `x11` (windowing system for the desktop). We remove `wayland` and `connman` to avoid conflicts with our chosen alternatives.
- `VIRTUAL-RUNTIME_init_manager`: Which program manages system startup. We use `systemd` (the modern default on most Linux distributions).
- `IMAGE_FEATURES`: Pre-grouped sets of packages that can be toggled on or off:
  - `debug-tweaks`: Makes the device easier to work with during development (empty root password, no lockouts).
  - `tools-sdk`: Installs compilers and development tools directly on the device, so you can compile code on it.
  - `allow-root-login`: Lets you log in as the administrator (`root`) user via SSH.
  - `dev-pkgs`: Installs development header files for every package, useful if you want to compile software directly on the device.

### 5. ROS 2 Humble (Robotics Software)
- `ROS_OE_RELEASE_SERIES`: Tells the ROS layer which Yocto release we are using (`kirkstone`).
- `ROS_DISTRO`: Which version of ROS to install. We use `humble` (ROS 2 Humble).
- `IMAGE_INSTALL:append`: The list of specific ROS packages to include — command-line tools, client libraries for writing robot programs in C++ and Python, message types, and the CMake build tool.

### 6. NVIDIA GPU Drivers & CUDA
- `PREFERRED_PROVIDER`: Tells Yocto to use NVIDIA's proprietary (hardware-accelerated) graphics drivers instead of the generic open-source ones. This is required for GPU compute and display output on the Jetson.
- `LICENSE_FLAGS_ACCEPTED`: Some NVIDIA packages have commercial licenses. This setting tells Yocto it is OK to download and use them.
- `cuda-toolkit` & `tensorrt`: Installs NVIDIA's GPU computing tools (CUDA compiler, cuDNN deep learning library, TensorRT inference engine) so you can run AI workloads on the device.

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

## Adding Extra Packages

You will often want to add software packages beyond what is listed above. Here is how to find and add them safely:

### Finding Available Packages
1. **Go to the OpenEmbedded Layer Index**: Visit [layers.openembedded.org](https://layers.openembedded.org/). This is the official search engine for all available Yocto recipes.
2. **Search for what you need**: Type the name of the tool or library. The results will show you which layer provides it and whether it is available for the `kirkstone` branch.
3. **Check that you have the layer**: Before adding a package name to `IMAGE_INSTALL:append`, make sure the layer that provides it is already registered in your `bblayers.conf`.

### Using AI Tools to Help
- AI assistants can suggest package names and configuration snippets, which can speed up your work.
- **Always double-check** AI suggestions against the OpenEmbedded Layer Index or the actual recipe files (`.bb` files in your layers). Package names sometimes differ between Yocto branches (e.g., `python3-numpy` vs `python-numpy`), and a wrong name will cause the build to fail.

---

## Complete `local.conf` (Ready to Copy)

Below is the full `local.conf` file. Copy and paste it into `poky/build/conf/local.conf`, replacing the existing contents:

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
