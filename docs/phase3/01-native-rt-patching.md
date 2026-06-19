---
title: "Native PREEMPT_RT Patching"
description: "Step-by-step instructions for manually applying the PREEMPT_RT patch, configuring the kernel in menuconfig, compiling it on an Ubuntu 18.04 host, and injecting the assets into the L4T flashing directory."
---

# Native PREEMPT_RT Patching

<span class="phase-label">Phase 3 · Page 1 of 5</span>

!!! abstract "Page Goal"
    - Provide step-by-step terminal instructions to natively configure, patch, and compile a real-time kernel on an Ubuntu 18.04 host system.
    - Inject the newly built RT kernel `Image` and kernel module supplements directly into the existing ConnectTech flashing environment.
    - Execute a recovery flash to boot the RT kernel on the Jetson TX2i.

!!! note "Primary Reference"
    - This guide refers to the official [NVIDIA Developer Forum: Adding RT Patch to L4T 32.7.2](https://forums.developer.nvidia.com/t/adding-rt-patch-to-l4t-32-7-2/334702){:target="_blank"} thread from May 2025 - July 2025.
    - The implementation has been slightly modified just to target the latest l4t-32.7.6 version, keeping rest of the steps identical.
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
   - Ensure `[*] CPU Idle Driver for NVIDIA Tegra 18x SoCs` stays checked by pressing space bar to toggle it. 
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
cd ~/Linux_for_Tegra/

# Apply standard NVIDIA libraries to rootfs
sudo ./apply_binaries.sh

# Connect USB cable, put board in Recovery Mode (short pins 6 and 20), and flash
sudo ./cti-flash.sh (since we need to flash to the connecttech carrier board, and we can choose to rebuild the entire system.img and inject the kernel from our correct Linux_for_Tegra/kernel folder.)


```

??? info "Click to view the menu-driven `cti-flash.sh` script"
    ```bash
    #!/bin/bash

    NOCOLOR='\033[0m'
    GREEN='\033[0;32m'
    RED='\033[0;41m'
    STD='\033[0;0;39m'

    flash(){
        ./flash.sh cti/$2/$BOARD_TYPE/$1 mmcblk0p1
        exit 0
    }

    menu() {
        clear
        echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~"  
        echo "         CTI FLASH         "
        echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        echo "1. Astro"
        echo "2. Elroy"
        echo "3. Orbitty"
        echo "4. Spacely (ASG006)"
        echo "5. Spacely (ASG026)"
        echo "6. Sprocket"
        echo "7. Rudi"
        echo "8. Cogswell"
        echo "9. Rosie"
        echo "10. Graphite VPX"
        echo "11. Quasar"
        echo "x. Exit"
    }

    astroMenu() {
        clear
        echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~" 
        echo "           Astro           "
        echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        echo "1. Revison J+"
        echo "2. Revison G to Revision I"
        echo "3. USB3.0 (Rev F prior)"
        echo "4. mPCIe (Rev F prior)"
        echo "5. Cancel (back to main menu)"
    }

    elroyMenu() {
        clear
        echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~"  
        echo "           Elroy           "
        echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        echo "1. Revison F+"
        echo "2. USB3.0 (Rev E prior)"
        echo "3. mPCIe (Rev E prior )"
        echo "4. Cancel (back to main menu)"
    }

    spacelyMenu() {
        clear
        echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~"  
        echo "    Spacely (ASG006)       "
        echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        echo "1. Base"
        echo "2. IMX274 3 Cameras"
        echo "3. IMX274 6 Cameras"
        echo "4. Cancel (back to main menu)"
    }

    spacelyRevjMenu() {
        clear
        echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~"  
        echo "    Spacely (ASG026)       "
        echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        echo "1. Base"
        echo "2. IMX274 3 Cameras"
        echo "3. IMX274 6 Cameras"
        echo "4. Cancel (back to main menu)"
    }

    rudiMenu() {
        clear
        echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~"  
        echo "           Rudi            "
        echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        echo "1. Revison C+"
        echo "2. USB3.0 (Rev B prior)"
        echo "3. mPCIe (Rev B prior )"
        echo "4. Cancel (back to main menu)"
    }

    sprocketMenu() {
        clear
        echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~"  
        echo "          Sprocket          "
        echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        echo "1. Base"    
        echo "2. IMX274"
        echo "3. Cancel (back to main menu)"
    }

    quasarMenu() {
        clear
        echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~"  
        echo "          Quasar           "
        echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        echo "1. Base"    
        echo "2. IMX274"
        echo "3. Cancel (back to main menu)"
    }

    vpxMenu() {
        clear
        echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~"  
        echo "            VPX            "
        echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        echo "1. Base"
        echo "2. IMX274-2CAM"
        echo "3. Cancel (back to main menu)"
    }

    tx2Menu() {
        clear
        echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~"  
        echo "        TX2 Version        "
        echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        echo "1. TX2"
        echo "2. TX2i"
        echo "3. TX2-4G"
        echo "4. Cancel (back to main menu)"
    }

    tx2Options(){
        tx2Menu
        local choice
        read -p "Enter choice:  " choice
        case $choice in
            1) flash $1 tx2;;    
            2) flash $1 tx2i;;
            3) flash $1 tx2-4G;;
            4) ;;
            *) echo -e "${RED}Invalid Choice...${STD}" && sleep 1
        esac
    }

    astroOptions(){
        astroMenu
        local choice
        read -p "Enter choice:  " choice
        case $choice in
            1) tx2Options revJ+;;
            2) tx2Options revG+;;    
            3) tx2Options usb3;;
            4) tx2Options mpcie;;
            5) ;;
            *) echo -e "${RED}Invalid Choice...${STD}" && sleep 1
        esac
    }

    elroyOptions(){
        elroyMenu
        local choice
        read -p "Enter choice:  " choice
        case $choice in
            1) tx2Options revF+;;    
            2) tx2Options usb3;;
            3) tx2Options mpcie;;
            4) ;;
            *) echo -e "${RED}Invalid Choice...${STD}" && sleep 1
        esac
    }

    spacelyOptions(){
        spacelyMenu
        local choice
        read -p "Enter choice:  " choice
        case $choice in
            1) tx2Options base;;    
            2) tx2Options li-imx274-3cam;;
            3) tx2Options li-imx274-6cam;;
            4) ;;
            *) echo -e "${RED}Invalid Choice...${STD}" && sleep 1
        esac
    }

    spacelyRevjOptions(){
        spacelyRevjMenu
        local choice
        read -p "Enter choice:  " choice
        case $choice in
            1) tx2Options base-revj+;;    
            2) tx2Options li-imx274-3cam-revj+;;
            3) tx2Options li-imx274-6cam-revj+;;
            4) ;;
            *) echo -e "${RED}Invalid Choice...${STD}" && sleep 1
        esac
    }
    quasarOptions(){
        quasarMenu
        local choice
        read -p "Enter choice:  " choice
        case $choice in
            1) tx2Options base;;    
            2) tx2Options li-imx274;;
            3) ;;
            *) echo -e "${RED}Invalid Choice...${STD}" && sleep 1
        esac
    }
    sprocketOptions(){
        sprocketMenu
        local choice
        read -p "Enter choice:  " choice
        case $choice in  
            1) tx2Options base;;
            2) tx2Options li-imx274;;
            3) ;;
            *) echo -e "${RED}Invalid Choice...${STD}" && sleep 1
        esac
    }

    rudiOptions(){
        rudiMenu
        local choice
        read -p "Enter choice:  " choice
        case $choice in
            1) tx2Options base;;    
            2) tx2Options usb3;;
            3) tx2Options mpcie;;
            4) ;;
            *) echo -e "${RED}Invalid Choice...${STD}" && sleep 1
        esac
    }

    vpxOptions(){
        vpxMenu
        local choice
        read -p "Enter choice:  " choice
        case $choice in  
            1) tx2Options base;;
            2) tx2Options li-imx274-2cam;;
            3) ;;
            *) echo -e "${RED}Invalid Choice...${STD}" && sleep 1
        esac
    }

    boardOptions(){
        local choice
        read -p "Enter choice:  " choice
        case $choice in
            1) BOARD_TYPE="astro"; astroOptions;;    
            2) BOARD_TYPE="elroy"; elroyOptions;;
            3) BOARD_TYPE="orbitty"; tx2Options base;;
            4) BOARD_TYPE="spacely"; spacelyOptions;;
            5) BOARD_TYPE="spacely"; spacelyRevjOptions;;
            6) BOARD_TYPE="sprocket"; sprocketOptions;;
            7) BOARD_TYPE="rudi"; rudiOptions;;
            8) BOARD_TYPE="cogswell"; tx2Options base;;
            9) BOARD_TYPE="rosie"; tx2Options base;;
            10) BOARD_TYPE="vpg003"; vpxOptions;; 
            11) BOARD_TYPE="quasar"; quasarOptions;;
            x) exit 0;;
            *) echo -e "${RED}Invalid Choice...${STD}" && sleep 1
        esac
    }

    trap ''
    dmesg -D

    while true
    do
        menu
        boardOptions
    done
    ```


Once flashing finishes, the Jetson TX2i will reboot. Log in and run `uname -a` on the target terminal. The output should display the real-time identifier:
`SMP PREEMPT RT and the RT patch results in the linux-tegra 4.9.337-rt197 patch, which is the latest corresponding RT patch we can apply to the reguler 4.9.337 Kernel.`

---

[← PREEMPT_RT Overview](index.md){ .md-button }
[Next: Yocto PREEMPT_RT Integration →](02-yocto-rt-integration.md){ .md-button .md-button--primary }
