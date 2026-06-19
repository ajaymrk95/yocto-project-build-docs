---
title: "Roadmap"
description: "Complete development roadmap for the Space Linux Yocto build."
---

# Project Roadmap

This roadmap guides you through the entire development lifecycle of the Space Operating Linux build for the Jetson TX2i + Elroy Carrier Board. Each phase builds upon the previous, progressing from theoretical foundations to a fully functional, real-time capable system image.

!!! info "How to Use This Roadmap"
    Follow the phases sequentially. Each phase page contains process diagrams, key concepts, and step-by-step outlines. Links to relevant pages, repositories, and tools are provided inline.

---

## Progress Tracker

| Week | Phase | Activity | Status |
|:---:|---|---|:---:|
| 1–2 | Phase 0 | Literature review and redundancy concepts | Complete |
| 2–3 | Phase 1 | Minimal Yocto build for TX2i Device + TX2 DevKit Carrier Board | Complete |
| 3–4 | Phase 2 | Adaptation for TX2i + Elroy carrier board | Complete |
| 4   | Phase 3 | Applying the PREEMPT_RT kernel patch to Phase 2, RT testing | Complete |
| 4-5 | Phase 4 (Current) | A/B partitioning redundancy and bootloader failover config | In Progress |
| 5–6 | Phase 5 | TMR bootloader, RAM filesystem, image minimization | Planned |

---

## High-Level Development Flow

```mermaid
flowchart TD
    subgraph P0["Phase 0 — Research"]
        A0["Read Research Papers"] --> A1["Understand Redundancy\nMechanisms"] --> A2["Study Radiation Effects\non Linux"]
    end

    subgraph P1["Phase 1 — Minimal Build"]
        B0["Set Up Host\nEnvironment"] --> B1["Clone Poky &\nRequired Layers"] --> B2["Configure bblayers.conf\n& local.conf"] --> B3["Build Image\nvia bitbake"] --> B4["Flash TX2i + DevKit"]
    end

    subgraph P2["Phase 2 — Custom Hardware"]
        C0["Compare Elroy\nvs DevKit"] --> C1["Modify Build\nArtifacts"] --> C2["Edit extlinux.conf\n& Partition Table"] --> C3["Generate Sparse\nImage"] -->C4["Setup NVIDIA and Hardware Specific "] --> C4["Flash via\n Modified ConnectTech Scripts"]
    end

    subgraph P3["Phase 3 — PREEMPT_RT"]
        D0["Locate RT Patch"] --> D1["Integrate via\nYocto Recipe"] --> D2["Configure Kernel\nFlags"] --> D3["Build & Flash\nRT Image"] --> D4["Validate with\ncyclictest"]
    end

    subgraph P4["Phase 4 — A/B Redundancy"]
        E0["Modify smd_info.cfg"] --> E1["Set ROOTFS_AB=1"] --> E2["Flash target via cti-flash.sh"] --> E3["Trigger Kernel Panic"] --> E4["Verify Fallback"]
    end

    subgraph CW["Current & Future Work"]
        F1["Local apt Server"] --> F2["TMR Bootloader"] --> F3["RAM-Based\nFilesystem"] --> F4["Image\nMinimization"]
    end

    A2 --> B0
    B4 --> C0
    C4 --> D0
    D4 --> E0
    E4 --> F1
```

---

## Phase Overview

### Phase 0 — Literature & Redundancy Concepts

<span class="phase-label">Research · Week 1–2</span>

!!! warning "Living Document"
    This is a continuous process and is still not 100% understood. The content is adapted to the best of the author's ability and will be updated as understanding deepens.

A deep dive into the research papers that form the theoretical foundation of this project, and the hardware/software redundancy mechanisms that make Linux viable for Low Earth Orbit (LEO) missions.

**Key Topics:** Radiation effects, SEU/MBU mitigation, ECC memory, watchdog timers, partition redundancy, TMR, boot failure analysis.

→ [Enter Phase 0](phase0/index.md)

---

### Phase 1 — Minimal Yocto Build

<span class="phase-label">Development · Week 2–3</span>

Build a minimal system image using the Yocto Project for the Jetson TX2i, initially targeting the TX2 Development Kit board. This phase covers the complete build pipeline from host setup to flashing.

**Key Topics:** Poky, meta-tegra, meta-ros, bblayers.conf, local.conf, bitbake, Kirkstone branch.

→ [Enter Phase 1](phase1/index.md)

---

### Phase 2 — Custom Hardware Adaptation

<span class="phase-label">Hardware · Week 3–4</span>

Transition the build from the NVIDIA DevKit to the Connect Tech Elroy carrier board. This phase navigates device tree differences, flash script modifications, and a dead-end attempt with the Warrior branch.

**Key Topics:** DTB files, CFG files, extlinux.conf, mksparse, ConnectTech BSP scripts, Warrior vs Kirkstone.

→ [Enter Phase 2](phase2/index.md)

---

### Phase 3 — PREEMPT_RT Kernel Patch

<span class="phase-label">Kernel · Week 4</span>

Apply the PREEMPT_RT real-time patch to the Linux kernel through the Yocto build system, enabling deterministic scheduling required for time-critical space payload operations.

**Key Topics:** PREEMPT_RT patch series, kernel menuconfig, Yocto kernel recipes, cyclictest, latency profiling.

→ [Enter Phase 3](phase3/index.md)

---

### Phase 4 — A/B Partition Redundancy

<span class="phase-label">Redundancy · Weeks 4-5</span>

Configure A/B hardware and software redundancy on the Jetson TX2i, including bootloader-level failover parameters (`smd_info.cfg`), RootFS slot allocations (`ROOTFS_AB=1`), and serial boot console recovery validation.

**Key Topics:** Slot Metadata Database (SMD), RootFS partition switching, Connect Tech flashing wrappers, kernel panic fallback loop.

→ [Enter Phase 4](phase4/index.md)

---

### Current Work

Active development tasks including real-time validation, package management, and partition redundancy implementation.

---

### Future Work

Planned enhancements including TMR bootloader patching, RAM-based filesystem testing, and system image minimization.
