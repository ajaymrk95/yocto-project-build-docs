---
title: "Native PREEMPT_RT Patching"
description: "Step-by-step instructions for manually applying the PREEMPT_RT patch, configuring the kernel in menuconfig, compiling it on an Ubuntu 18.04 host, and injecting the assets into the L4T flashing directory."
---

# Native PREEMPT_RT Patching

<span class="phase-label">Phase 3 · Page 1 of 6</span>

!!! abstract "Page Goal"
    - Provide step-by-step terminal instructions to natively configure, patch, and compile a real-time kernel on an Ubuntu 18.04 host system.
    - Inject the newly built RT kernel `Image` and kernel module supplements directly into the existing ConnectTech flashing environment.
    - Execute a recovery flash to boot the RT kernel on the Jetson TX2i.

!!! note "Primary Reference"
    For community context, patch validation, and discussion regarding L4T RT kernel patching, refer to the official [NVIDIA Developer Forum: Adding RT Patch to L4T 32.7.2](https://forums.developer.nvidia.com/t/adding-rt-patch-to-l4t-32-7-2/334702){:target="_blank"} thread.

---

## 1. Prerequisites and Host Setup

Manually compiling the NVIDIA real-time kernel requires cross-compilation packages on the host machine. Run these commands from an active terminal on your **Ubuntu 18.04 LTS** host system:

```bash
# Update repositories and install cross-compilation libraries
sudo apt-get update
sudo apt-get install -y libncurses5-dev build-essential bc lbzip2 qemu-user-static python checkpolicy libssl-dev
```

---

## 2. Directory Structure and Sourcing Files

Create a dedicated workspace folder to download the NVIDIA BSP driver files, sample root filesystem, public kernel sources, and the matching Linaro toolchain.

```bash
# Initialize workspace
mkdir -p ~/rt_workspace
cd ~/rt_workspace

# 1. Download L4T Jetson Driver Package (R32.7.6)
wget -O jetson_linux_r32.7.6_aarch64.tbz2 https://developer.nvidia.com/downloads/embedded/l4t/r32_release_v7.6/t186/jetson_linux_r32.7.6_aarch64.tbz2

# 2. Download L4T Sample Root File System (R32.7.6)
wget -O tegra_linux_sample-root-filesystem_r32.7.6_aarch64.tbz2 https://developer.nvidia.com/downloads/embedded/l4t/r32_release_v7.6/t186/tegra_linux_sample-root-filesystem_r32.7.6_aarch64.tbz2

# 3. Download L4T Kernel Sources (R32.7.6)
wget -O public_sources.tbz2 https://developer.nvidia.com/downloads/embedded/l4t/r32_release_v7.6/sources/t186/public_sources.tbz2

# 4. Download GCC Tool Chain for 64-bit BSP (Linaro 7.3)
wget -O gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu.tar.xz https://developer.nvidia.com/embedded/dlc/l4t-gcc-7-3-1-toolchain-64-bit
```

---

## 3. Extracting Packages & Sourcing Kernel Sources

Unpack the archives in order to isolate the raw kernel source code tree:

```bash
cd ~/rt_workspace

# Unpack L4T Base BSP
sudo tar xpf jetson_linux_r32.7.6_aarch64.tbz2

# Unpack Sample Root Filesystem directly into the generated structure
cd Linux_for_Tegra/rootfs/
sudo tar xpf ../../tegra_linux_sample-root-filesystem_r32.7.6_aarch64.tbz2

# Drop back out to the workspace root and extract tools
cd ~/rt_workspace/
tar -xvf gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu.tar.xz
sudo tar -xjf public_sources.tbz2

# Isolate and extract kernel source archive
cd Linux_for_Tegra/source/public/
tar -xjf kernel_src.tbz2

# Move the clean kernel source folder straight up to your workspace root
mv kernel ~/rt_workspace/
```

---

## 4. Applying the RT Patch Script

NVIDIA includes a helper script (`rt-patch.sh`) directly inside the kernel source folders. This script downloads and applies the corresponding real-time kernel patches matching the current kernel version (Linux 4.9.140 for this Tegra release):

```bash
cd ~/rt_workspace/kernel/kernel-4.9/
./scripts/rt-patch.sh apply-patches
```
*Note: The script outputs patch execution details. Ensure all hunks apply cleanly without error blocks.*

---

## 5. Kernel Configuration (`menuconfig`)

Create a target output directory to store the built artifacts and run the interactive configuration utility:

```bash
cd ~/rt_workspace/kernel/kernel-4.9/

# Initialize output folder
TEGRA_KERNEL_OUT=~/rt_workspace/jetson_tx2_kernel
mkdir -p $TEGRA_KERNEL_OUT

# Map cross-compilation tool paths explicitly
export CROSS_COMPILE=~/rt_workspace/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-

# Generate baseline config
make ARCH=arm64 O=$TEGRA_KERNEL_OUT tegra_defconfig

# Open interactive configuration utility
make ARCH=arm64 O=$TEGRA_KERNEL_OUT menuconfig
```

### Required Configuration Changes
Navigate the ncurses terminal interface and set the following parameters:

1. **Enable Tickless (Full dynticks) System**:
   - Path: `General setup` → `Timer subsystem` → `Timer tick handling`
   - Set to: `Full dynticks system (tickless)`
2. **Enable Fully Preemptible Preemption Model**:
   - Path: `Kernel Features` → `Preemption Model`
   - Set to: `Fully Preemptible Kernel (RT)`
3. **Set High-Resolution Timer Frequency**:
   - Path: `Kernel Features` → `Timer frequency`
   - Set to: `1000 HZ`
4. **Preserve CPU Idle Driver (Mandatory for Jetson Clocks Compatibility)**:
   - Path: `CPU Power Management` → `CPU idle` → `ARM CPU Idle Drivers`
   - Ensure `[*] CPU Idle Driver for NVIDIA Tegra 18x SoCs` stays checked. 
   - *Note: Sourcing the RT patch sometimes disables CPU Idle drivers. If this is disabled, running `jetson_clocks` on the target will crash the system. Re-enabling it here keeps the system stable.*

Save the configurations and exit.

---

## 6. Kernel Compilation

Compile the kernel Image, device trees, and module packages:

```bash
make ARCH=arm64 O=$TEGRA_KERNEL_OUT -j$(nproc)
```

---

## 7. Injecting RT Assets Safely into Flashing Folders

To boot our manual RT build, we must copy the kernel assets and modules directly into our existing ConnectTech Elroy flashing environment directory (`~/cti_elroy_flash/Linux_for_Tegra/`):

```bash
# 1. Overwrite the non-RT kernel Image in your flashing folder
sudo cp ~/rt_workspace/jetson_tx2_kernel/arch/arm64/boot/Image ~/cti_elroy_flash/Linux_for_Tegra/kernel/Image

# 2. Extract and mount the new RT kernel modules directly to the flashing rootfs
sudo make ARCH=arm64 O=~/rt_workspace/jetson_tx2_kernel modules_install INSTALL_MOD_PATH=~/cti_elroy_flash/Linux_for_Tegra/rootfs/

# 3. Create fresh kernel supplements archive
cd ~/cti_elroy_flash/Linux_for_Tegra/rootfs/
sudo tar --owner root --group root -cjf kernel_supplements.tbz2 lib/modules

# 4. Position the supplements package for flash.sh parsing
sudo mv kernel_supplements.tbz2 ../kernel/
```

!!! caution "Do Not Copy Device Tree Files"
    We deliberately **do not** copy any compiled `.dtb` device tree binaries from the native build output to the flashing folder. Copying these files will overwrite the custom ConnectTech Elroy serial, USB, and Ethernet layout files generated by the CTI installer overlay, breaking carrier board peripheral compatibility.

---

## 8. Applying Binaries & Recovery Flashing

Finalize the flashing package on the host and flash the target:

```bash
cd ~/cti_elroy_flash/Linux_for_Tegra/

# Apply standard NVIDIA libraries to rootfs
sudo ./apply_binaries.sh

# Connect USB cable, put board in Recovery Mode (short pins 6 and 20), and flash
sudo ./flash.sh jetson-tx2-devkit-tx2i mmcblk0p1
```

Once flashing finishes, the Jetson TX2i will reboot. Log in and run `uname -a` on the target terminal. The output should display the real-time identifier:
`SMP PREEMPT RT ...`

---

[← PREEMPT_RT Overview](index.md){ .md-button }
[Next: Yocto PREEMPT_RT Integration →](02-yocto-rt-integration.md){ .md-button .md-button--primary }
