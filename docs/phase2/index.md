---
title: "Phase 2 — Custom Hardware Adaptation"
description: "Adapting the Yocto build for the Jetson TX2i on the Connect Tech Elroy carrier board."
---

# Phase 2 — Custom Hardware Adaptation

<span class="phase-label">Hardware · Week 3–4</span>

!!! abstract "Goal"
    Transition the working Yocto build from the NVIDIA TX2i on the Development Kit to the Connect Tech Elroy carrier board — a minimal form-factor carrier designed for minimal peripherals and interfacing.

!!! danger "Dead End Documented"
    This phase also documents a dead-end approach using the older Warrior branch, which was abandoned in favor of continuing on Kirkstone. This is included to save future developers from repeating the same mistake.

---

## Why a custom carrier board?

- NVIDIA by default provides active support and troubleshooting for their Development Kit Boards. A DevKit board serves as a reference board/template to other carrier board manufacturers to design their own custom boards. 

- Devkits are primarily used for development or evaluation purpose. They include various debugging interfaces like serial debug ports, extra USB ports, HDMI ports etc. which are not necessary for the final deployment of the board. 

- Custom carrier boards considerably reduce the overall form factor (size) and modify the power consumption. The Board and System on Module (TX2i in our case) allow better integration for harsh/rugged field conditions, multi-sensor perception stacks, tight enclosures, and I/O-heavy autonomous systems, all of which make them better suited for Space Based Deployments.

---

## Adapting from the Yocto Perspective

- Adapting this directly from the Yocto Build System is theoretically feasible and Yocto is primarily suited for custom board bring up and setup. However, the challenge arises from the way NVIDIA structures its Board Support Package (BSP).

- The Kernel, Bootloader, and other board specific features are bundled into a single BSP package which needs to be extracted and modified to support a custom carrier board. As referred to in Yocto's guide - "Use existing BSP layers from silicon vendors when possible: Intel, TI, NXP and others have information on what BSP layers to use with their silicon. These layers have names such as “meta-intel” or “meta-ti”. Try not to build layers from scratch."

- There is a significant level of configuration, custom machine setup and hardware level architecture based setup to correctly modify the exisiting BSP layer for a custom hardware carrier board. This is an even more tedious task for the device - TX2i, since it requires specific files and setup at each phase of the boot process, right from the bootloaders till the final device tree files that the kernel uses to establish interfacing with available hardware and peripherals.

## Phase Process Overview

<pre class="mermaid">
flowchart TD
    START(["Start\nDevKit Build Complete"]) --> STUDY

    subgraph S1["Stage 1 — Hardware Differences"]
        STUDY["Compare Elroy vs DevKit\nPinout, Connectors, DTBs"]
        STUDY --> DTB["Study Device Tree\nBinaries"]
        DTB --> CFG["Study CFG Files\nFlash Configuration"]
    end

    subgraph S2["Stage 2 — Dead End"]
        direction TB
        WAR["Attempt Build on\nWarrior Branch"]
        WAR --> WAR_FAIL["Layer Incompatibilities\n& Deprecated APIs"]
        WAR_FAIL --> WAR_ABANDON["Documented for Reference"]
    end

    subgraph S3["Stage 3 — Modify Build Artifacts"]
        CFG --> EXTRACT["Extract ext4 from\nYocto Build Output"]
        EXTRACT --> MOUNT["Mount the ext4\nFilesystem"]
        MOUNT --> EDIT["Edit extlinux.conf\nHardcode Partition IDs"]
        EDIT --> UNMOUNT["Unmount"]
        UNMOUNT --> SPARSE["Convert to Sparse Image\nmksparse utility"]
    end

    subgraph S4["Stage 4 — ConnectTech Flash"]
        SPARSE --> COPY["Copy system.img to\nbootloader/ directory"]
        COPY --> SCRIPTS["Configure ConnectTech\nFlash Scripts"]
        SCRIPTS --> MACHINE_CONF["Set Machine Conf\nfrom ConnectTech instead of jetson-tx2i flag"]
        MACHINE_CONF --> FLASH["Flash to Elroy\nCarrier Board"]
    end

    subgraph S5["Stage 5 — Verification"]
        FLASH --> BOOT["Boot & Verify\non Elroy Hardware"]
        BOOT --> TEST["Test Peripherals\n& System"]
    end

    STUDY -.-> WAR
    WAR_ABANDON -.-> EXTRACT

    TEST --> DONE(["Phase 2 Complete"])
</pre>

---

## Pages

| # | Page | Description |
|---|---|---|
| 1 | [Device Trees, DTBs & Configuration Files](01-device-trees-and-configuration.md) | Understanding DTS/DTSI/DTB file formats, the P3489 DevKit default files, ConnectTech Elroy (ASG002) changes, and CFG files. |
| 2 | [Warrior Branch Dead-End & Custom Machine Setup](02-warrior-branch-dead-end.md) | A detailed review of the Warrior branch attempt, build errors, and the ideal Yocto machine setup configuration. |
| 3 | [Build Artifact Modification](03-build-artifact-modification.md) | Mounting the ext4 rootfs, editing extlinux.conf for the Elroy, and creating a sparse image. |
| 4 | [ConnectTech Flash Scripts](04-connecttech-flash-scripts.md) | Setting up the CTI BSP, understanding the Linux_for_Tegra directory, and configuring flash scripts. |
| 5 | [Machine Configuration & Flags](05-machine-configuration.md) | Machine conf files, jetson-tx2i vs Elroy target, and selecting the correct CFG files. |
| 6 | [Flashing & Verification](06-flashing-and-verification.md) | End-to-end flash procedure on Elroy hardware and post-flash system verification. |

---



[← Phase 1](../phase1/index.md){ .md-button }
[Next: Phase 3 →](../phase3/index.md){ .md-button .md-button--primary }
