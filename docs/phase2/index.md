---
title: "Phase 2 — Custom Hardware Adaptation"
description: "Adapting the Yocto build for the Jetson TX2i on the Connect Tech Elroy carrier board."
---

# Phase 2 — Custom Hardware Adaptation

<span class="phase-label">Hardware · Week 3–4</span>

!!! abstract "Goal"
    Transition the working Yocto build from the NVIDIA TX2 Development Kit to the Connect Tech Elroy carrier board — a minimal form-factor carrier designed for embedded and space applications.

!!! danger "Dead End Documented"
    This phase also documents a dead-end approach using the older Warrior branch, which was abandoned in favor of continuing on Kirkstone. This is included to save future developers from repeating the same mistake.

---

## Why a custom carrier board?

- 

---

## Adapting from the Yocto Perspective


## Phase Process Overview

```mermaid
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
        WAR_FAIL --> WAR_ABANDON["Abandoned\nDocumented for Reference"]
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
    WAR_ABANDON -.->|"Lesson Learned"| EXTRACT

    TEST --> DONE(["Phase 2 Complete"])
```
---

## Subpages

| Page | Description |
|---|---|
| [Elroy vs DevKit](01-hardware-comparison.md) | Hardware comparison, form factor, connector differences |
| [DTBs & CFG Files](02-device-trees-and-configuration.md) | Device tree binaries and flash configuration concepts |
| [Dead End — Warrior Branch](03-warrior-branch-dead-end.md) | Why the Warrior branch failed and lessons learned |
| [Build Artifact Modification](04-build-artifact-modification.md) | Mounting ext4, editing extlinux.conf, creating sparse image |
| [ConnectTech Flash Scripts](05-connecttech-flash-scripts.md) | CTI BSP scripts, directory setup, flash configuration |
| [Machine Conf & Flags](06-machine-configuration.md) | jetson-tx2i flag, Elroy board cfg, machine configuration |
| [Flashing & Testing](07-flashing-and-verification.md) | Flash procedure and verification on Elroy hardware |

---



[← Phase 1](../phase1/index.md){ .md-button }
[Next: Phase 3 →](../phase3/index.md){ .md-button .md-button--primary }
