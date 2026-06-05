---
title: "Phase 1 — Minimal Yocto Build"
description: "Building a minimal system image with Yocto for the Jetson TX2i on the TX2 Development Kit board."
---

# Phase 1 — Minimal Yocto Build

<span class="phase-label">Development · Week 2–3</span>

!!! abstract "Goal"
    Build a minimal system image (< 5 GB) using the Yocto Project (Kirkstone branch) for the Jetson TX2i on the TX2 Development Kit board. The image includes a minimal GUI, ROS core packages, and essential networking and system utilities.

---

## Phase Process Overview

```mermaid
flowchart TD
    START(["Start"]) --> ENV

    subgraph S1["Stage 1 — Environment Setup"]
        ENV["Install Host\nDependencies"] --> CLONE["Clone Poky\nKirkstone"]
    end

    subgraph S2["Stage 2 — Layer Configuration"]
        CLONE --> LAYERS["Add Required Layers"]
        LAYERS --> L1["meta-tegra"]
        LAYERS --> L2["meta-openembedded"]
        LAYERS --> L3["meta-ros and sublayers"]
        LAYERS --> L4["(sublayers of meta-openembedded:meta-python, meta-xfce and meta-networking)"]
        L1 --> BBLAYERS["Update\nbblayers.conf"]
        L2 --> BBLAYERS
        L3 --> BBLAYERS
        L4 --> BBLAYERS
    end

    subgraph S3["Stage 3 — Machine & Local Config"]
        BBLAYERS --> MACHINE["Select MACHINE\nfrom meta-tegra"]
        MACHINE --> LOCAL["Configure\nlocal.conf"]
        LOCAL --> PACKAGES["Define Target\nPackages"]
    end

    subgraph S4["Stage 4 — Build"]
        PACKAGES --> INIT["source oe-init-\nbuild-env"]
        INIT --> BITBAKE["bitbake\ncore-image"]
        BITBAKE --> ARTIFACTS["Build Artifacts\next4, dtb, kernel"]
    end

    subgraph S5["Stage 5 — Flash & Test"]
        ARTIFACTS --> SDK["NVIDIA SDK Manager\nor Flash Script"]
        SDK --> FLASH["Flash to TX2\nDevKit"]
        FLASH --> BOOT["First Boot\n& Verify"]
    end

    BOOT --> DONE(["Phase 1 Complete"])
```

---

## Important Links & Repos

!!! tip "Key References"
    These are the primary resources you will need throughout this phase.

| Resource | Link |
|---|---|
| Yocto Project | <!-- TODO: Add link --> |
| Yocto Project Quick Build Guide | <!-- TODO: Add link --> |
| Yocto Project Documentation (Kirkstone) | <!-- TODO: Add link --> |
| Open Embedded for Tegra (IMPORTANT) | <!-- TODO: Add link --> |
| Poky Repository (Kirkstone branch) | <!-- TODO: Add link --> |
| meta-tegra Layer | <!-- TODO: Add link --> |
| meta-openembedded | <!-- TODO: Add link --> |
| meta-ros (Melodic / Noetic) | <!-- TODO: Add link --> |
| Flashing Process| <!-- TODO: Add link --> |
| Yocto — Adding Layers Guide | <!-- TODO: Add link --> |
| Yocto — Adapting to Custom Hardware | <!-- TODO: Add link --> |

---

## Subpages

| Page | Description |
|---|---|
| [Environment Setup](environment-setup.md) | Host dependencies, directory structure, initial clone |
| [Yocto Quick Build](yocto-quick-build.md) | Running a reference build to validate the toolchain |
| [Custom Layers & BSP](custom-layers-bsp.md) | Adding meta-tegra, meta-ros, meta-cti and configuring bblayers.conf |
| [Machine & Local Configuration](machine-local-conf.md) | Choosing machine, setting packages, local.conf tweaks |
| [Build Process](build-process.md) | Running bitbake, build stages, expected outputs |
| [Flashing the DevKit](flashing-devkit.md) | Flash workflow, SDK Manager, first boot verification |
| [Naming Conventions & Gotchas](naming-gotchas.md) | Common errors, naming pitfalls, tips and screenshots |

---

[← Phase 0](../phase0/index.md){ .md-button }
[Next: Phase 2 →](../phase2/index.md){ .md-button .md-button--primary }
