---
title: "Phase 1 — Minimal Yocto Build"
description: "Building a minimal system image with Yocto for the Jetson TX2i on the TX2 Development Kit board."
---

# Phase 1 — Minimal Yocto Build

<span class="phase-label">Development · Week 2–3</span>

!!! abstract "Goal"
    Build a minimal system image (< 5 GB) using the Yocto Project (Kirkstone branch) for the Jetson TX2i on the TX2 Development Kit board. The image includes a minimal GUI, ROS core packages, and essential networking and system utilities.

!!! info "Flowcharts"
    Flowcharts are a representation of what each page does or contributes to the build in a high level, and will be useful to understand the overall build process. These are for quick explanations and a way to present a long build process in visual format.

---


## Flowchart

<pre class="mermaid">
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
        ARTIFACTS --> FLASH["Flash to TX2\nDevKit"]
        FLASH --> BOOT["First Boot\n& Verify"]
    end

    BOOT --> DONE(["Phase 1 Complete"])
</pre>
---

## Important Links & Repos

!!! tip "Key References"
    These are the primary resources used throughout Phase 1. Listed Again for a Sequential Flow of Reading, see **[Page 2 — Prerequisite Reading & Key Links](02-prerequisite-reading.md)**.

### Yocto Project Documentation

!!! warning "Yocto's Original Docs are Actively Updated "
    As of writing this documentation (June 2026), Yocto's original documentation for the branch used here is still up. All Documentation is available at [docs.yoctoproject.org](https://docs.yoctoproject.org/). However, be aware that the docs may be updated frequently, and you may need to adjust the links below:

    Google Search and Navigate to yoctoproject.org and there we have releases, check the left sidebar and navigate to release manuals. Select the corresponding branch for the documentation.

| Resource | Link |
|----------|------|
| Yocto Project on Kirkstone - The Roadmap uses this branch primarily | [yoctoproject.org](https://docs.yoctoproject.org/4.0.35/) |

!!! info "Use these links"
    The Current Links are still hosted and live, these will be checked and updated regularly.

| Resource | Link |
|----------|------|
| Yocto Project Overview | [yoctoproject.org](https://www.yoctoproject.org/) |
| Quick Build Guide (Kirkstone) - Must Read | [Quick Build](https://docs.yoctoproject.org/kirkstone/brief-yoctoprojectqs/index.html) |
| What I wished I know about Yocto - Must Read (Kirkstone) | [What to know](https://docs.yoctoproject.org/kirkstone/brief-yoctoprojectqs/index.html) |
| Reference Manual (Kirkstone) | [Major Reference Manual](https://docs.yoctoproject.org/kirkstone/ref-manual/index.html) |

### Github Project Repositories - (Links for Cloning - Specific Commands are also provided inline in the stages pages)
| Repository | Branch | Link |
|-----------|--------|------|
| Poky (BitBake + OE-Core) | `kirkstone` | [git.yoctoproject.org/poky]| (https://github.com/yoctoproject/poky/tree/kirkstone) |
| meta-tegra (OE4T) This is a Board Support Repo for the NVIDIA Jetson Devices, further stages in Phase 1 will explain this branch.| `kirkstone-l4t-32.7.x` | [github.com/OE4T/meta-tegra](https://github.com/OE4T/meta-tegra/tree/kirkstone-l4t-r32.7.x) |
| meta-openembedded  | `kirkstone` | [git.openembedded.org/meta-openembedded](https://git.openembedded.org/meta-openembedded) |
| meta-ros | `kirkstone` | [github.com/ros/meta-ros](https://github.com/ros/meta-ros/tree/kirkstone) |

### NVIDIA & Hardware Resources

| Resource | Link |
|----------|------|
| OE4T (Open Embedded for Tegra) Wiki (Single Most Important Reference ! ) | [oe4t-wiki](https://oe4t.github.io/master/) |


## Pages

| # | Page | Description |
|---|---|---|
| 1 | [What Is the Yocto Project?](01-what-is-yocto.md) | An introduction to the Yocto Project — what it is, how it works, and why it's the right tool for this build. |
| 2 | [Important Links](02-prerequisite-reading.md) | Essential links for the Yocto Project, NVIDIA Tegra BSP, and all repositories used. |
| 3 | [Host Environment Setup](03-host-setup.md) | Setting up your Linux host with all dependencies, disk space, and directory structure for a Yocto build. |
| 4 | [Yocto Quick Build](04-quick-build.md) | Run the official Yocto Quick Build for QEMU to validate your host setup before Tegra-specific builds. |
| 5 | [Cloning Poky & Branch Strategy](05-cloning-and-branching.md) | Clone all required repositories, align on the Kirkstone branch, and set up the project workspace. |
| 6 | [Adding Layers & Configuring bblayers.conf](06-adding-layers.md) | A detailed walkthrough of every Yocto layer used in this build, how to add them, and how to configure bblayers.conf. |
| 7 | [Deep Dive: local.conf](07-local-conf.md) | Complete guide to local.conf — MACHINE, DISTRO, IMAGE_INSTALL, build tuning, and a full annotated config. |
| 8 | [The Build Process Explained](08-build-process.md) | Pre-flight checklist, running bitbake, the task pipeline, shared state cache, build directory anatomy, and debugging. |
| 9 | [Build Output & Flashing](09-navigating-output-and-flashing.md) | Find your build artifacts, understand the tegraflash bundle, prepare the flash workspace, and flash the DevKit. |

---

[← Phase 0](../phase0/index.md){ .md-button }
[Next: Phase 2 →](../phase2/index.md){ .md-button .md-button--primary }
