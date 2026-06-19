---
title: "Yocto PREEMPT_RT Integration"
description: "Guide for integrating the PREEMPT_RT kernel patch into the Yocto Kirkstone build environment for the Jetson TX2i. Covers custom meta-layers, .bbappend files, and cleansstate tasks."
---

# Yocto PREEMPT_RT Integration

<span class="phase-label">Phase 3 · Page 2 of 5</span>

!!! abstract "Page Goal"
    - Configure the Yocto build environment on the Kirkstone branch to apply the real-time `PREEMPT_RT` patch to the Jetson TX2i kernel during compile time.
    - Set up a custom meta-layer to maintain workspace separation and version control hygiene.
    - Understand `.bbappend` structure and naming conventions to apply config fragments dynamically.
    - Execute a clean rebuild of the kernel to prevent task cache collisions.
    - Extract the Yocto build artifacts, configure the boot options, and flash the real-time image to the ConnectTech carrier board.

---

## 1. Yocto & PREEMPT_RT Branch Compatibility

The `meta-tegra` BSP layer includes native support for real-time kernel builds through specific helper configurations. It fetches the matching real-time kernel patch and configures the kernel recipe compile flags dynamically. 

This feature was historically supported on older Yocto branches (such as Dunfell) and has been s improved with modern syntax on newer releases like Kirkstone, Scarthgap.

According to the official [OE4T Branch Usage Guidelines](https://oe4t.github.io/master/Which-branch-should-I-use.html){:target="_blank"}:
- **`kirkstone`**: Supports L4T R35.6.4 / JetPack 5.1.6 for modern architectures (AGX Xavier, Xavier NX, AGX Orin, Orin NX, and Orin Nano).
- **`kirkstone-l4t-r32.7.x`**: Community backpatch supporting L4T R32.7.6 / JetPack 4.6.6 for older architectures (TX1, TX2, TX2-NX, Xavier, Xavier-NX, Nano, and Nano-2GB).

For the Jetson TX2i, we build using the **`kirkstone-l4t-r32.7.x`** branch. This community-maintained branch backports support for our hardware while using newer bitbake syntax like kirkstone.

Implementing this configuration utilizes Yocto's `.bbappend` mechanism, which we first explored in Phase 2 during the setup of the older Warrior branch.
*Reference:* Learn more about the append concepts in [Custom Machine Setup: What is a .bbappend file?](../phase2/02-custom-machine-setup.md#what-is-a-bbappend-file).

---

## 2. Why We Create a Custom Meta-Layer

Before adding our RT changes, we must set up a custom Yocto meta-layer (e.g., `meta-rt-patch`). 

* **Modular Modifications**: Yocto follows a modular, layer-based approach. Any modifications introduced via `.bbappend` files are best isolated in a dedicated custom layer rather than edited directly in upstream folders.
* **Git Cleanliness**: Modifying cloned upstream layers (like `meta-tegra` or `poky`) directly pollutes the workspace and complicates repository version control.
* **Upstream Conflict Avoidance**: 
  Upstream Yocto layers are actively maintained by original creators. If you edit upstream files directly, any subsequent `git pull` will trigger merge conflicts, potentially overwriting your changes or causing compilation failures. A custom layer sits cleanly on top of unmodified official layers, allowing you to pull upstream updates without changing your overriding functionality.

---

## 3. Directory Setup & Layer Creation

Follow these steps to initialize your Yocto build environment and create the custom layer.

### Step 1: Initialize the BitBake Environment
Navigate to the root directory of your Yocto workspace, enter the `poky` folder, and source the environment script to initialize build variables:
```bash
cd ~/yocto/poky
source oe-init-build-env
```
*Remember: This command sets your working directory to the Yocto `build/` folder and starts the command line bitbake tools*

### Step 2: Create and Add the Custom Layer
Run the following commands to generate a new layer named `meta-rt-patch` and register it with your configuration:
```bash
# Create the layer structure 2 directories up from the build folder
bitbake-layers create-layer ../../meta-rt-patch

# Add the layer to the bblayers.conf configuration
bitbake-layers add-layer ../../meta-rt-patch
```
*Note: The `meta-` prefix is the standard naming convention for Yocto layers (especially BSP layers) to identify them instantly in file structures.*

### Validating the Added Layer
Verify that the custom layer has been correctly registered and inserted into the active layer stack:
```bash
bitbake-layers show-layers
```

#### Expected Output
The console will display the registered layers, including the newly created `meta-rt-patch` (which is assigned a default priority of `6` to just override meta-tegra):
```text 
layer                 path                                                 priority
====================================================================================
meta                  /home/yocto/poky/meta                                5
meta-poky             /home/yocto/poky/meta-poky                            5
meta-yocto-bsp        /home/yocto/poky/meta-yocto-bsp                       5
meta-oe               /home/yocto/meta-openembedded/meta-oe                 6
meta-python           /home/yocto/meta-openembedded/meta-python             7
meta-networking       /home/yocto/meta-openembedded/meta-networking         5
meta-multimedia       /home/yocto/meta-openembedded/meta-multimedia         5
meta-gnome            /home/yocto/meta-openembedded/meta-gnome              5
meta-xfce             /home/yocto/meta-openembedded/meta-xfce               7
meta-ros-common       /home/yocto/meta-ros/meta-ros-common                  10
meta-ros2             /home/yocto/meta-ros/meta-ros2                       11
meta-ros2-humble      /home/yocto/meta-ros/meta-ros2-humble                 12
meta-qt5              /home/yocto/meta-qt5                                  7
meta-tegra            /home/yocto/meta-tegra                                5
meta-rt-patch         /home/yocto/meta-rt-patch                             6
```

### Workspace Folder Structure
After creation, configure the layer files. Your workspace layout should look like this:
```text
yocto/
├── meta-openembedded/
├── meta-tegra/
├── meta-rt-patch/               <-- Custom Layer for PREEMPT_RT Patching
│   ├── conf/
│   │   └── layer.conf           <-- Layer priority and compatibility settings
│   └── recipes-kernel/
│       └── linux/
│           ├── files/
│           │   └── rt-enable.cfg <-- Kernel configuration fragment
│           └── linux-tegra_4.9.bbappend <-- Kernel build append recipe
└── poky/
    ├── build/
    │   └── conf/
    │       ├── bblayers.conf    <-- Automatically lists ../meta-rt-patch
    │       └── local.conf
    └── meta/
```

---

## 4. Dynamically Applying the RT Patches to Kirkstone

We modify the kernel build process by adding a recipe append (`.bbappend`) and a configuration fragment.

### Step 3: Create the Kernel Configuration Fragment
Create `recipes-kernel/linux/files/rt-enable.cfg` inside the `meta-rt-patch` layer to define the real-time configuration flags:

```config
CONFIG_PREEMPT_RT_FULL=y
CONFIG_PREEMPT=y
# CONFIG_PREEMPT_NONE is not set
# CONFIG_PREEMPT_VOLUNTARY is not set
```
* **`CONFIG_PREEMPT_RT_FULL=y`**: Enforces full preemptive real-time operation, transforming spinlocks into sleeping mutexes.
* **`CONFIG_PREEMPT=y`**: Activates core kernel preemption capabilities.
* **`CONFIG_PREEMPT_NONE` / `CONFIG_PREEMPT_VOLUNTARY`**: Explicitly disabled to ensure no lower-priority preemption models override real-time tasks.

### Step 4: Create the Kernel Recipe Append
Create `recipes-kernel/linux/linux-tegra_4.9.bbappend` inside your `meta-rt-patch` layer to apply the configurations and patches dynamically:

```bitbake
# Tell Yocto to look inside your 'files' folder
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Add the configuration fragment to the build pipeline
SRC_URI += "file://rt-enable.cfg"

# Force network access for the patch download step
do_patch[network] = "1"

do_patch:prepend() {
    oldwd=$PWD
    cd ${S}/scripts
    
    bbnote "Executing NVIDIA rt-patch.sh script..."
    chmod +x ./rt-patch.sh
    ./rt-patch.sh apply-patches
    
    cd ${S}
    bbnote "Committing RT patch modifications to local workspace git..."
    git add . && git commit -m 'Apply PREEMPT_RT patches'
    
    cd $oldwd
}
```

### Append Logic 
* **`FILESEXTRAPATHS:prepend`**: Tells BitBake to prioritize search directory `files/` inside the current recipe folder when resolving local files.
* **`SRC_URI += "file://rt-enable.cfg"`**: Instructs the build system to merge the real-time configuration fragment into the kernel's `.config`.
* **`do_patch[network] = "1"`**: By default, Yocto builds execute in a sandboxed offline state. However, because NVIDIA's `rt-patch.sh` script queries kernel.org dynamically via `wget`/`curl` to fetch the real-time patch file, we must explicitly enable network access during the `do_patch` task.
* **`do_patch:prepend()`**: Before applying standard patches, BitBake changes directory to the kernel source scripts, gets and runs rt-patch.sh script additionally, and registers a local Git commit. This git commit is required because subsequent compilation steps inside Yocto monitor the source tree status.

---

## 5. Cleaning the Cache and Building the Image

Testing for the RT patch needs a few packages - which have to be added inside the build/conf/local.conf

Paste this block at the end of your local.conf-

#11. Adding RT Patch Testkit. Pre-RT Evaluation to be done prior to adding the RT Patch
IMAGE_INSTALL:append = " rt-tests stress-ng trace-cmd numactl"

Because you previously compiled a standard non-RT kernel for the Jetson TX2i, Yocto's internal caching mechanism (shared state / sstate) may attempt to reuse previously compiled files. This will lead to build failures or output kernel mismatches.

### Step 5: Clean the Kernel Build States
Force-remove all cached states and temporary files of the current kernel compilation:
```bash
bitbake -c cleansstate virtual/kernel
```
*Note: This deletes target cached binaries and output objects, and starts the kernel build process from the do:fetch() step.

### Step 6: Run the BitBake Compilation
Compile the target system image:
```bash
bitbake core-image-sato
```
During this compilation, you will notice that BitBake:
- Re-downloads the kernel sources and fetches the real-time patch over the network.
- Re-configures the kernel using `do_configure`, merging the `rt-enable.cfg` configurations.
- Re-compiles the real-time kernel (`do_compile`) and builds the matching real-time modules (`lib/modules/<kernel-version>-rt`).
- Outputs the customized root filesystem image (`.ext4`) under `tmp/deploy/images/jetson-tx2-devkit-tx2i/`.

!!! tip "Check Build Logs"
    To confirm the patch was applied successfully, check the BitBake build logs. You should see the custom commit message: `Apply PREEMPT_RT patches`.

---

## 6. Extracting, Configuring, and Flashing the Image

Once the build finishes successfully, we extract and flash the real-time image using the flashing method detailed in Phase 2 - Adapting to a Custom Carrier - Pages 4 and 5 specifically.

### Step 7: Flash the Target via `cti-flash.sh`
Rather than flashing a devkit, we use ConnectTech's menu-driven flash script to register custom carrier board pins:

1. Connect the board and short pins 6 and 20 to trigger recovery mode.
2. Run the flash installer tool:
   ```bash
   sudo ./cti-flash.sh
   ```
3. Select option `2` (Elroy Carrier), option `1` (Revision F+), and target version `2` (TX2i). The script automatically flashes the Yocto real-time image using the custom carrier parameters.

---

## 7. Verifying the Real-Time Kernel on Target

Boot the Jetson TX2i board, open a terminal, and run:
```bash
uname -a
```
Expected output:
```text
Linux jetson-tx2i 4.9.337-rt197 #1 SMP PREEMPT RT ... aarch64 GNU/Linux
```

### Key Verification Markers
* **`SMP PREEMPT RT`**: Proves that the real-time scheduling hooks are active, replacing normal multitasking locks with fully preemptible threads.
* **`4.9.337-rt197`**: Shows the latest corresponding real-time patch applied successfully on top of the standard Yocto kernel build.

---

[← Native PREEMPT_RT Patching](01-native-rt-patching.md){ .md-button }
[Next: Real-Time Scheduling Concepts →](03-real-time-scheduling.md){ .md-button .md-button--primary }
