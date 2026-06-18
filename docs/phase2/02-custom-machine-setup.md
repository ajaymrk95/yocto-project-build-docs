---
title: "Custom Machine Setup"
description: "A detailed review of the abandoned Warrior branch path, the specific build and dependency issues encountered, and the ideal architecture for setting up a custom machine in Yocto."
---

#  Custom Machine Setup

<span class="phase-label">Phase 2 · Page 2 of 5</span>

!!! abstract "Page Goal"
    Document the technical process, failures, and build issues encountered when attempting a build on the Yocto Warrior branch, with a proof of concept on how to build such a machine, based on existing github repositories.

###  What is a `.bbappend` file?

A `.bbappend` file is a Yocto recipe append file. In Yocto, it is considered bad practice to directly modify `.bb` recipes provided by external layers (like `meta-tegra` or `meta-openembedded`). Instead, we use `.bbappend` files in our own custom layer to extend or override the functionality of those existing recipes. 

The build system automatically merges the base `.bb` file with any `.bbappend` files of the exact same name. This allows us to inject extra dependencies, add configuration files, or modify tasks without touching the original source. For example, we can specify custom code to run right before or right after an existing task using the `:prepend` or `:append` syntax (or `_prepend`/`_append` in older Yocto versions):
- `do_install:prepend() { ... }` runs our code *before* the original recipe's install task.
- `do_install:append() { ... }` runs our code *after* the original recipe's install task.

## Concept to adapt the Yocto Build

When adapting our Yocto build for the Connect Tech Elroy (ASG002) carrier board, the initial plan was to align the Yocto build branch with the existing available patched and updated BSP Layer Additions for a ConnectTech Based Carrier. 

## Theoretical Aspects and Full Process as per OE4T - Open Embedded for Tegra

- The meta-tegra layer includes MACHINE definitions for NVIDIA’s Jetson development kits. If you are developing a custom device using one of the Jetson modules with, for example, a custom carrier board, or you just want to modify the default boot-time configuration (pinmux, etc.) for an existing development kit as a separate MACHINE in your own metadata layer, you may need to supply a MACHINE-specific file for your builds.

## Jetson TX2i/TX2 Process - Consolidated

-  OE4T -  Open Embedded for Tegra 

- For the Jetson-TX2 family, there are several boot-time configuration files that are machine-specific. Be sure to follow the NVIDIA Platform Adaptation Guide documentation carefully so all of the necessary customizations for the BPMP device tree and the MB1 .cfg files for the pinmux, PMIC, PMC, boot ROM, and other on-module hardware get created properly. The basic steps are filling in the pinmux spreadsheet and generating the dtsi fragments, then converting those fragments to cfg files using the L4T pinmux-dts2cfg.py script.

- The recipes-bsp/tegra-binaries/tegra-flashvars_<bsp-version>.bb recipe installs a file called flashvars that identifies the boot-time configuration files that need to be processed by the tegra186-flash-helper script for feeding into NVIDIA’s flashing tools. With older OE4T branches, you need to supply a customized copy of the flashvars file in your BSP layer. With the latest branches, the flashvars file gets generated automatically from the variables listed in TEGRA_FLASHVARS. Check the recipe in meta-tegra to confirm which method you need to follow.

- The files listed in your flashvars file must be installed into ${datadir}/tegraflash in the build sysroot by another recipe. The simplest method is to create an overlay for the recipes-bsp/tegra-binaries/tegra-bootfiles recipe, as it already extracts the files for the Jetson development kits from the L4T BSP package.

```bitbake
# The fetch task is disabled on this recipe, but we need our files included in the task signature.
CUSTOM_DTSI_DIR := "${THISDIR}/${BPN}"
FILESEXTRAPATHS:prepend := "${CUSTOM_DTSI_DIR}:"

SRC_URI:append:${machine} = "\
    file://tegra19x-${machine}-padvoltage-default.cfg \
    file://tegra19x-${machine}-pinmux.cfg \
    "

# As the fetch task is disabled for this recipe, we access the files directly out of the layer.
do_install:append:${machine}() {
    install -m 0644 ${CUSTOM_DTSI_DIR}/tegra19x-${machine}-padvoltage-default.cfg ${D}${datadir}/tegraflash/
    install -m 0644 ${CUSTOM_DTSI_DIR}/tegra19x-${machine}-pinmux.cfg ${D}${datadir}/tegraflash/
}
```

!!! warning "OE4T Guide for Custom Machine Setup - Orin as an example"
    The following is a configuration reference for the Jetson Orin - a newer device released by NVIDIA. The underlying concepts remain the same for other Tegra platforms like the Jetson TX2i, though filenames and architecture paths will differ.

### 1. Create a New Machine Config
Create a new Machine configuration at `conf/machine/${machine}.conf` in your layer. For guidance on what it should contain, look at any of the machine configurations in `meta-tegra`.

### 2. Create a New Flash Config
Create a new flash configuration `recipes-bsp/tegra-binaries/tegra-flashvars/${machine}/flashvars`. You can start by copying one of the `flashvars` files in `meta-tegra`. To use the newly created `flashvars` file, create the following `recipes-bsp/tegra-binaries/tegra-flashvars_35.4.1.bbappend`:

```bitbake
FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"
```

### 3. Add Pinmux DTSI Files
Generate the pinmux DTSI files with the NVIDIA pinmux Excel sheet (or the one for Orin AGX). Rename the resulting files to start with `tegra234-` (otherwise `meta-tegra` has issues handling them) and convert line endings to Unix using `dos2unix`. Copy the files to `recipes-bsp/tegra-binaries/tegra-flashvars`.

!!! note
    If you manually rename your generated DTSI files, you may need to modify the `#include` statement on line 35 of your `-pinmux.dtsi` file, as it has the original filename for the `-gpio-default.dtsi` file hardcoded.

### 4. Install the Pinmux Files
Install the files with the following `tegra-bootfiles_35.4.1.bbappend`:

```bitbake
# Hack: The fetch task is disabled on this recipe, so the following is just for the task signature.
FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"
SRC_URI:append:${machine} = "\
    file://tegra234-${machine}-gpio-default.dtsi \
    file://tegra234-${machine}-padvoltage-default.dtsi \
    file://tegra234-${machine}-pinmux.dtsi \
"

# Hack: As the fetch task is disabled for this recipe, we have to directly access the files.
CUSTOM_DTSI_DIR := "${THISDIR}/${BPN}"
do_install:append:${machine}() {
    install -m 0644 ${CUSTOM_DTSI_DIR}/tegra234-${machine}-gpio-default.dtsi ${D}${datadir}/tegraflash/
    install -m 0644 ${CUSTOM_DTSI_DIR}/tegra234-${machine}-padvoltage-default.dtsi ${D}${datadir}/tegraflash/
    install -m 0644 ${CUSTOM_DTSI_DIR}/tegra234-${machine}-pinmux.dtsi ${D}${datadir}/tegraflash/
}
```
*(Remember to replace `${machine}` with your machine name.)*

### 5. Modify Flashvars
Then modify `flashvars` to use the files:
- `PINMUX_CONFIG` should be set to your `tegra234-${machine}-pinmux.dtsi`
- `PMC_CONFIG` should be set to your `tegra234-${machine}-padvoltage-default.dtsi`
- In case of the TX2i Device Series tegracode is tegra186.

### 6. (Optionally) Disable Board EEPROM Usage
As explained in the *Platform Adaptation and Bring-Up Guide* by NVIDIA, you might want to disable the usage of the board EEPROM. For that, create a copy of the file used in `flashvars` for `MB2BCT_CFG` and modify it according to the NVIDIA guide. Include this new file in Yocto the same way as explained in **Add Pinmux DTSI Files** and update `MB2BCT_CFG` in `flashvars` with the new file name.

### 7. Use a Custom Device Tree
See the custom device tree documentation and apply the described changes to your `${machine}.conf`.

### 8. Customizing the Kernel
For custom hardware, you'll probably need to modify the kernel in at least one of the following ways:
- Custom kernel configuration
- Custom device tree
- Adding patches

Starting with L4T R32.3.1-based branches, you can use the Yocto Linux tools to apply patches and configuration changes during the build, although it may be simpler to fork the `linux-tegra-4.9` repository to apply patches and supply your own `defconfig` file for the kernel configuration. Having your own fork of the kernel sources should also be easier for creating a custom device tree (you should also set the `KERNEL_DEVICETREE` variable in your machine configuration file appropriately).

## Part 2 - Identify and attempt to use existing work - The meta-cti layer

!!! note "Acknowledgement - Damien LeFevre - contributor of the meta-cti layer on Github, whose work was primaily adapted and extended to the TX2i."

    - https://github.com/lfdmn/meta-cti/tree/l4t-r32.2-cti-v126 

    - This repository puts into practice the above listed steps to support a custom carrier board -ConnectTech Astro and Elroy for the TX2 - NVIDIA Reference Number P3310.
    
    - Cloning this repository and adding a custom machine configuration can enable this extension to most CTI DTB based boards.


### `meta-cti` Layer Structure

```text
meta-cti
|   LICENSE
|   README.md
+---conf
|   |   layer.conf
|   +---distro
|   |   \---include
|   |           astro-tx2.conf
|   |           elroy-mpcie-tx2.conf
|   |           elroy-tx2.conf
|   |           rudi-tx2.conf
|   \---machine
|           astro-tx2.conf
|           elroy-mpcie-tx2.conf
|           elroy-tx2.conf
|           rudi-tx2.conf
+---recipes-bsp
|   \---tegra-binaries
|       |   tegra-flashvars_32.2.0.bbappend
|       \---files
|           |   flashvars
|           +---astro-tx2
|           |       flashvars
|           +---elroy-mpcie-tx2.conf
|           |       flashvars
|           +---elroy-tx2
|           |       flashvars
|           \---rudi-tx2
|                   flashvars
\---recipes-kernel
    \---linux
        |   linux-tegra_4.9.bbappend
        \---files
            \---tegra186
                    tegra186_cti_defconfig
```

### Detailed Explanation of the Configuration

- **Layer Configuration (`conf/layer.conf`)**: This file integrates the custom layer into the Yocto environment, indicating it targets the `warrior` series and has a priority dependency on the `meta-tegra` layer.

- **Machine Configuration (`conf/machine/elroy-tx2.conf`)**: The layer defines custom hardware configurations. For example, `elroy-tx2.conf` uses the base SoC configuration (`require conf/machine/include/tegra186.inc`) from `meta-tegra`. Here, the layer specifically sets the `KERNEL_DEVICETREE` variable:
  ```bitbake
  KERNEL_DEVICETREE ?= "_ddot_/_ddot_/_ddot_/_ddot_/nvidia/platform/t18x/quill/kernel-dts/tegra186-tx2-cti-ASG002-revF+.dtb"
  ```
  This explicit assignment overrides the default device tree and forces the Yocto kernel build system to compile and deploy the exact `.dtb` required for the ConnectTech Elroy carrier board.

- **Flashvars and DTBs (`recipes-bsp/tegra-binaries`)**: *Flashvars* define the specific boot-time and early-boot hardware configuration files that NVIDIA's flashing tools (`tegra186-flash-helper`) use to initialize the hardware before the kernel boots. 
  
  The layer uses a `tegra-flashvars_32.2.0.bbappend` recipe to prepend its own `files/` directory to the search path:
  ```bitbake
  FILESEXTRAPATHS_prepend := "${THISDIR}/files/:"
  ```
  Because of this prepend, when Yocto processes the `elroy-tx2` machine, it finds and uses the custom flashvars file at `files/elroy-tx2/flashvars` instead of the default NVIDIA one. 

  Inside `files/elroy-tx2/flashvars`, the layer sets the following crucial variables:
  ```bash
  FLASHVARS="BPFDTB_FILE PINMUX_CONFIG PMIC_CONFIG PMC_CONFIG PROD_CONFIG BOOTROM_CONFIG MISC_CONFIG SCR_CONFIG SCR_COLD_BOOT_CONFIG DEV_PARAMS"
  BPFDTB_FILE=tegra186-a02-bpmp-quill-p3310-1000-@BPFDTBREV@-00-te770d-ucm2.dtb
  PINMUX_CONFIG=tegra186-mb1-bct-pinmux-quill-p3310-1000-@BOARDREV@.cfg
  PMIC_CONFIG=tegra186-mb1-bct-pmic-quill-p3310-1000-@PMICREV@.cfg
  PMC_CONFIG=tegra186-mb1-bct-pad-quill-p3310-1000-@BOARDREV@.cfg
  PROD_CONFIG=tegra186-mb1-bct-prod-quill-p3310-1000-@BOARDREV@.cfg
  BOOTROM_CONFIG=tegra186-mb1-bct-bootrom-quill-p3310-1000-@BOARDREV@.cfg
  MISC_CONFIG=tegra186-mb1-bct-misc-si-l4t.cfg
  SCR_CONFIG=minimal_scr.cfg
  SCR_COLD_BOOT_CONFIG=mobile_scr.cfg
  DEV_PARAMS=emmc.cfg
  ```
  **What these variables mean:**
  - `BPFDTB_FILE`: The Boot and Power Management Processor (BPMP) device tree. It controls low-level clocks and power domains.
  - `PINMUX_CONFIG`: Pin multiplexing configuration file, defining how the SoC pins are electrically routed (GPIO vs. I2C vs. SPI).
  - `PMIC_CONFIG`: Power Management IC configuration, defining voltage rails and sequencing.
  - `PMC_CONFIG`: Power Management Controller pad configurations.
  - `PROD_CONFIG`: Production configuration and tuning values for the SoC components.
  - `BOOTROM_CONFIG`: Early boot ROM configuration settings.
  - `MISC_CONFIG` / `SCR_CONFIG` / `DEV_PARAMS`: Miscellaneous security parameters, cold boot constraints, and eMMC storage configurations.

- **Kernel Defconfig (`recipes-kernel/linux/linux-tegra_4.9.bbappend`)**: To configure the kernel properly for the Elroy board, the layer provides a custom `tegra186_cti_defconfig` file inside `recipes-kernel/linux/files/tegra186/`. 
  
  The `.bbappend` uses the `SRC_URI` variable to pull both the modified kernel source from a GitHub fork and this local physical defconfig file:
  ```bitbake
  KERNEL_REPO = "git@github.com:lfdmn/linux-tegra-4.9.git"
  SRC_URI = "git://${KERNEL_REPO};protocol=ssh;branch=${SRCBRANCH} \
            file://tegra186_cti_defconfig \
  "
  ```
  During the `do_configure_prepend()` task, the `.bbappend` script moves the pulled `tegra186_cti_defconfig` directly to `${WORKDIR}/defconfig`:
  ```bitbake
  do_configure_prepend(){
      mv ${WORKDIR}/tegra186_cti_defconfig ${WORKDIR}/defconfig
  }
  ```
  Because Yocto's kernel build system inherently looks for a file named `defconfig` in the work directory to initialize the kernel configuration (`.config`), this simple rename forces the entire build to compile against the custom ConnectTech hardware settings instead of NVIDIA's defaults.


## Part 3 : Adding the TX2i Machine 

```

### 1. Define the Machine Configuration (`elroy-tx2i.conf`)

Inside the custom layer, the machine configuration file is created at `conf/machine/elroy-tx2i.conf`. This configuration represents the target hardware combo, explicitly specifying the TX2i board ID (`3489`):

```text
#@TYPE: Machine
#@NAME: Nvidia Elroy TX2i
#@DESCRIPTION: Nvidia Jetson TX2i on ConnectTech Elroy (ASG002)

# TX2i uses P3489 module (storm) instead of P3310 (quill)
TEGRA_BOARDID = "3489"
TEGRA_FAB ?= "A00"

# Comes from meta-tegra
require conf/machine/include/tegra186.inc

KERNEL_DEVICETREE ?= "_ddot_/_ddot_/_ddot_/_ddot_/nvidia/platform/t18x/quill/kernel-dts/tegra186-tx2i-cti-ASG002-revF+.dtb"
KERNEL_ARGS ?= "console=ttyS0,115200 console=tty0 OS=l4t fbcon=map:0"

MACHINE_FEATURES += "ext2 ext3 vfat"

UBOOT_MACHINE = "p2771-0000-500_defconfig"

EMMC_SIZE ?= "31276924928"
EMMC_DEVSECT_SIZE ?= "512"
BOOTPART_SIZE ?= "8388608"
BOOTPART_LIMIT ?= "10485760"
ROOTFSPART_SIZE ?= "30064771072"
ODMDATA ?= "0x1090000"
EMMC_BCT ?= "P3489_A00_8GB_Samsung_8GB_lpddr4_204Mhz_P134_A02_ECC_en_l4t.cfg"
NVIDIA_BOARD ?= "t186ref"
TEGRA186_REDUNDANT_BOOT ?= "0"
PARTITION_LAYOUT_TEMPLATE ?= "flash_l4t_t186.xml"
```
> **Note on ODMDATA**: The `ODMDATA` defines low-level hardware muxing (such as PCIe lanes and USB ports). This value (`0x1090000` for Elroy) remains the same for both the TX2 and the TX2i on this carrier board, as the base carrier board hardware does not change.

### 2. Configure the Flashvars for the TX2i (`elroy-tx2i/flashvars`)

To ensure NVIDIA's flashing tools configure the early-boot hardware properly, we must override the flashvars. The standard TX2 uses the **P3310** module, but the **TX2i** uses the **P3489** module. 

The `flashvars` file is placed at `recipes-bsp/tegra-binaries/files/elroy-tx2i/flashvars` to map the ConnectTech-specific TX2i configurations:

```bash
FLASHVARS="BPFDTB_FILE PINMUX_CONFIG PMIC_CONFIG PMC_CONFIG PROD_CONFIG BOOTROM_CONFIG MISC_CONFIG SCR_CONFIG SCR_COLD_BOOT_CONFIG DEV_PARAMS"
BPFDTB_FILE=tegra186-a02-bpmp-storm-p3489-@BPFDTBREV@-00-ta795sa-ucm1.dtb
PINMUX_CONFIG=tegra186-mb1-bct-pinmux-quill-p3489-1000-@BOARDREV@.cfg
PMIC_CONFIG=tegra186-mb1-bct-pmic-quill-p3489-1000-@PMICREV@.cfg
PMC_CONFIG=tegra186-mb1-bct-pad-quill-p3489-1000-@BOARDREV@.cfg
PROD_CONFIG=tegra186-mb1-bct-prod-storm-p3489-1000-@BOARDREV@.cfg
BOOTROM_CONFIG=tegra186-mb1-bct-bootrom-quill-p3489-1000-@BOARDREV@.cfg
MISC_CONFIG=tegra186-mb1-bct-misc-si-l4t.cfg
SCR_CONFIG=minimal_scr.cfg
SCR_COLD_BOOT_CONFIG=mobile_scr.cfg
DEV_PARAMS=emmc.cfg
```
*Notice how the BPFDTB file specifically references the `storm` module code alongside `p3489`, indicating the industrial TX2i variant.*

### 3. Injecting Files via `.bbappend`

To force the build to use our new `elroy-tx2i/flashvars` file and our custom kernel modifications, two `.bbappend` files are added:

**A. Flashvars bbappend (`tegra-flashvars_32.2.0.bbappend`)**:
```bitbake
FILESEXTRAPATHS_prepend := "${THISDIR}/files/:"
```
This prepend ensures that when Yocto processes the `elroy-tx2i` machine, it finds and bundles our `p3489`-specific flashvars file into the final flash package.

**B. Kernel bbappend (`linux-tegra_4.9.bbappend`)**:
```bitbake
FILESEXTRAPATHS_prepend := "${THISDIR}/files/tegra186:"
SRCBRANCH = "patches-${L4T_VERSION}-cti-v126"

SRCREV = "92f5594641f58e1f7ff9e1813dc0fd6803b25149"

KERNEL_REPO = "github.com/lfdmn/linux-tegra-4.9.git"
SRC_URI = "git://${KERNEL_REPO};protocol=https;branch=${SRCBRANCH} \
          file://tegra186_cti_defconfig \
"

KERNEL_ROOTSPEC = "root=/dev/mmcblk${@uboot_var('devnum')}p${@uboot_var('distro_bootpart')} rw rootwait"

do_configure_prepend(){
    mv ${WORKDIR}/tegra186_cti_defconfig ${WORKDIR}/defconfig
}
```
This forces the build to fetch Damien Lefevre's patched kernel branch, pulls in the `tegra186_cti_defconfig` file from our local layer, and renames it to `defconfig` so the Yocto kernel system builds against it.

### 4. Final Layer Directory Structure Checklist

Here is the exact layout of the custom `meta-cti` layer, highlighting specifically where the new files were added to support the `elroy-tx2i`:

```text
meta-cti/
├── conf/
│   ├── layer.conf
│   └── machine/
│       ├── astro-tx2.conf
│       ├── elroy-tx2.conf
│       └── elroy-tx2i.conf                          <-- [ADDED] TX2i Machine config
├── recipes-bsp/
│   └── tegra-binaries/
│       ├── tegra-flashvars_32.2.0.bbappend          <-- [ADDED] Injects flashvars paths
│       └── files/
│           ├── astro-tx2/
│           │   └── flashvars
│           ├── elroy-tx2/
│           │   └── flashvars
│           └── elroy-tx2i/                          <-- [ADDED] TX2i specific folder
│               └── flashvars                        <-- [ADDED] TX2i (P3489) flashvars
└── recipes-kernel/
    └── linux/
        ├── linux-tegra_4.9.bbappend                 <-- [ADDED] Injects defconfig & repo
        └── files/
            └── tegra186/
                └── tegra186_cti_defconfig           <-- [ADDED] Custom Elroy kernel config
```

This structure cleanly adapts the existing ConnectTech support (which was originally just for the TX2) to the TX2i.



---

[← Device Trees & Configuration](01-device-trees-and-configuration.md){ .md-button }
[Next: Executing the Build →](03-executing-the-build.md){ .md-button .md-button--primary }
