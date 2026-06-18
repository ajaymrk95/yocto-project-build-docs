---
title: "Yocto PREEMPT_RT Integration"
description: "Instructions for integrating the PREEMPT_RT kernel patch into the Yocto build system on the Kirkstone branch. Covers recipe configurations, build cleaning, and flashing target images."
---

# Yocto PREEMPT_RT Integration

<span class="phase-label">Phase 3 · Page 2 of 6</span>

!!! abstract "Page Goal"
    - Configure the Yocto build environment on the Kirkstone branch to apply the real-time `PREEMPT_RT` patch to the Jetson TX2i kernel during compile time.
    - Execute a clean rebuild of the kernel to prevent task cache collisions.
    - Extract the Yocto build artifacts and flash the real-time image to the ConnectTech board.

---

## 1. Yocto & PREEMPT_RT Class Integration

The `meta-tegra` BSP layer includes native support for real-time kernel builds through specific helper configurations. It fetches the matching real-time kernel patch from kernel.org and configures the kernel recipe compile flags dynamically.

To activate the real-time kernel build globally, you must add the following variable definition to your Yocto build configuration:

### Step 1: Update `local.conf`
Open your `poky/build/conf/local.conf` configuration file and append the following flag at the bottom:

```bash
# Enable the real-time kernel configuration in the meta-tegra BSP layer
TEGRA_PREEMPT_RT = "1"
```

---

## 2. Behind the Scenes: How Yocto Applies the Patch

When `TEGRA_PREEMPT_RT = "1"` is defined:
1. **Recipe Redirection**: The build system redirects the kernel provider to use the RT variant configuration.
2. **Patch Retrieval**: The fetcher pulls the `patch-4.9.140-rt115.patch.gz` (or corresponding RT patch) file from kernel.org.
3. **Patch Application**: The patch task applies the RT patch directly to the downloaded Linux sources inside the work directory (`tmp/work/`).
4. **Configuration Check**: The build configures `CONFIG_PREEMPT_RT=y` and disables incompatible options (such as CPU Idle constraints if needed).

---

## 3. Cleaning the Kernel Recipe (Cleansstate)

Because you previously compiled a standard non-RT kernel for the Jetson TX2i, Yocto's internal caching mechanism (shared state / sstate) may attempt to reuse previously compiled files. This will lead to build failures or output kernel mismatches.

You **must** force the build system to delete the standard kernel's compilation states, build folders, and package logs:

### Step 2: Clean the Kernel Build States
Run the cleansstate command from the build directory inside your Yocto terminal/Docker container:

```bash
# Force-remove all cached tasks for the kernel
bitbake -c cleansstate virtual/kernel
```
*Alternatively, you can run `bitbake -c cleanall virtual/kernel` to force-remove downloaded kernel sources and cache files.*

---

## 4. Building the Real-Time Image

With the cache cleared and the configuration flag set, compile your target system image:

### Step 3: Run the BitBake Compilation
```bash
bitbake core-image-sato
```

During this compilation, you will notice that BitBake:
- Re-downloads the kernel sources and fetches the real-time patch.
- Re-configures the kernel via `do_configure`.
- Compiles the real-time kernel (`do_compile`) and builds the matching real-time modules (`lib/modules/<kernel-version>-rt`).
- Assemble the root filesystem image `.ext4` under `tmp/deploy/images/jetson-tx2-devkit-tx2i/`.

---

## 5. Extracting and Flashing the RT Image

Once the build finishes successfully, we extract and flash the real-time image using the hybrid flashing pipeline detailed in Phase 2.

### Step 4: Mount the Rootfs and Swap the Device Trees
Mount the new Yocto-built `.ext4` rootfs, copy the custom ConnectTech Elroy Device Tree Binary (`tegra186-tx2i-cti-ASG002-revF+.dtb`) into the `/boot/` folder of the mount, and configure `/boot/extlinux/extlinux.conf` to point to the RT kernel image and carrier DTB.

### Step 5: Convert the raw ext4 to Sparse Image
Convert the raw `.ext4` into a sparse `system.img` file:

```bash
# Convert to sparse image
./bootloader/mksparse -v --fillpattern=0 ~/yocto/poky/build/tmp/deploy/images/jetson-tx2-devkit-tx2i/core-image-sato-jetson-tx2-devkit-tx2i.ext4 bootloader/system.img
```

### Step 6: Flash the Target
Connect the board, short pins 6 and 20 to trigger Recovery Mode, and run:

```bash
# Flash the custom Yocto real-time image, reusing the system.img
sudo ./flash.sh -r elroy-tx2i mmcblk0p1
```

---

## 6. Verifying the Real-Time Kernel on Target

Boot the board and check that the real-time kernel is active:

```bash
uname -a
```
Expected output:
```text
Linux jetson-tx2i 4.9.140-rt115 #1 SMP PREEMPT RT ... aarch64 GNU/Linux
```
The **`PREEMPT RT`** token confirms that the kernel is fully preemptible and deterministic.

---

[← Native PREEMPT_RT Patching](01-native-rt-patching.md){ .md-button }
[Next: Real-Time Scheduling Concepts →](03-real-time-scheduling.md){ .md-button .md-button--primary }
