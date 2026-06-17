---
title: "ConnectTech Flash Scripts"
---

# ConnectTech Flash Scripts

<span class="phase-label">Phase 2 · Page 4 of 6</span>

!!! info "Outline Page"
    This page is an outline only.

---

## Outline

### ConnectTech BSP Overview

- <!-- TODO: What the CTI BSP provides -->
- <!-- TODO: Supported carrier boards -->
- <!-- TODO: Repository / download location -->

### Directory Structure for Flashing

- <!-- TODO: Linux_for_Tegra directory layout -->
- <!-- TODO: bootloader/ directory contents -->
- <!-- TODO: Where system.img goes -->

### CTI Flash Script Configuration

- <!-- TODO: Script name and parameters -->
- <!-- TODO: Board identification flags -->
- <!-- TODO: Carrier board selection -->

### Modifying Scripts for Custom Image

- <!-- TODO: Replacing default system.img -->
- <!-- TODO: DTB and CFG file placement -->
- <!-- TODO: Any script modifications needed -->

---

## Flash Directory Structure

```mermaid
flowchart TD
    ROOT["Linux_for_Tegra/"] --> BL["bootloader/\nsystem.img goes here"]
    ROOT --> KERNEL["kernel/\nImage, dtb files"]
    ROOT --> ROOTFS["rootfs/\nRoot filesystem"]
    ROOT --> CTI["CTI-scripts/\nConnectTech utilities"]
    ROOT --> FLASH_SH["flash.sh"]

    BL --> SYS_IMG["system.img\nfrom mksparse"]
    BL --> CFG_FILES["*.cfg\nFlash configs"]
    KERNEL --> DTB_FILES["*.dtb\nDevice trees"]
```

---

[← Modifying Build Artifacts](03-build-artifact-modification.md){ .md-button }
[Next: Machine Configuration →](05-machine-configuration.md){ .md-button .md-button--primary }
