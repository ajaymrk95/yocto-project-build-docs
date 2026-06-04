---
title: "Space Linux — Yocto Build for Jetson TX2i"
description: "Building a minimal, radiation-aware Linux system image for the NVIDIA Jetson TX2i on the Connect Tech Elroy carrier board using the Yocto Project."
---

# Space Operating Linux

A minimal Yocto-based system image for the Jetson TX2i + Elroy Carrier Board.

This project adapts research from the **Space Operating Linux** paper (University of Georgia, 2023) and related radiation-hardening literature to build a flight-viable Linux system image targeting the **NVIDIA Jetson TX2i** system-on-module mounted on the **Connect Tech Elroy carrier board**.

The build system is the **Yocto Project** (Kirkstone branch), producing a minimal image with a reduced software footprint, ROS core packages, and a PREEMPT_RT patched kernel for deterministic real-time scheduling — engineered for Low Earth Orbit missions.

[Start with the Roadmap](roadmap.md){ .md-button .md-button--primary }
[Phase 0 — Literature Review](phase0/index.md){ .md-button }

---

## Project Goals

- [x] Reduced software footprint — target system image < 5 GB
- [x] ROS (Robot Operating System) — core packages for robotic payload control
- [x] PREEMPT_RT kernel patch — deterministic real-time scheduling
- [ ] A/B partition redundancy — graceful recovery from boot failures
- [ ] RAM-based filesystem — protection against flash corruption under radiation
- [ ] Triple Modular Redundancy (TMR) — bootloader-level fault tolerance

---

## Project Milestones

### Milestone 1 — Minimal Yocto Build ✓

Adapted a minimal system image via Yocto for the Jetson TX2i on the TX2 Development Kit board. Established the base layer configuration, package selection, and initial flash workflow.

→ [Phase 1 Details](phase1/index.md)

### Milestone 2 — Custom Hardware ✓

Improved the build to run on minimal form-factor hardware — Jetson TX2i + Connect Tech Elroy Carrier Board. Resolved device tree, configuration, and flash script differences.

→ [Phase 2 Details](phase2/index.md)

### Milestone 3 — PREEMPT_RT Kernel ✓

Added the PREEMPT_RT patch to the Linux kernel via the Yocto build system, enabling deterministic real-time capabilities required for time-critical space payloads.

→ [Phase 3 Details](phase3/index.md)

---

## Current Work in Progress

| Task | Status | Details |
|---|---|---|
| Testing real-time capabilities of the patched kernel | In Progress | Latency benchmarks, cyclictest validation |
| Adapting `apt` support via local update servers | In Progress | Offline package management for field updates |
| Enabling A/B partition redundancy | In Progress | Graceful boot fallback on corruption |

---

## Future Work

| Task | Description |
|---|---|
| Minimizing the system image | Further reducing packages and footprint |
| Patching the bootloader for TMR | Triple Modular Redundancy at the bootloader level |
| Testing RAM-based filesystem | tmpfs / initramfs for radiation-safe operation |

---

## Documentation Roadmap

This documentation follows a phased approach. Each phase builds on the previous one, mirroring the actual development timeline of the project.

```mermaid
graph LR
    P0["Phase 0\nLiterature &\nRedundancy\nWeek 1-2"]
    P1["Phase 1\nMinimal Yocto\nBuild\nWeek 2-3"]
    P2["Phase 2\nCustom Hardware\nAdaptation\nWeek 3-4"]
    P3["Phase 3\nPREEMPT_RT\nPatch\nWeek 4"]
    CW["Current Work\nOngoing"]
    FW["Future Work\nPlanned"]

    P0 --> P1 --> P2 --> P3 --> CW --> FW
```

---

## Target Hardware

| Component | Specification |
|---|---|
| **SoM** | NVIDIA Jetson TX2i (Industrial) |
| **Carrier Board** | Connect Tech Elroy (CTI) |
| **CPU** | Dual Denver 2 + Quad ARM Cortex-A57 |
| **GPU** | NVIDIA Pascal, 256 CUDA cores |
| **RAM** | 8 GB LPDDR4 |
| **Storage** | 32 GB eMMC |
| **Build System** | Yocto Project — Kirkstone Branch |
| **Target Orbit** | Low Earth Orbit (LEO) |
