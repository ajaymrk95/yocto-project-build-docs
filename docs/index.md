---
title: "Space Linux — Yocto Build for Jetson TX2i"
description: "Building a minimal, radiation-aware Linux system image for the NVIDIA Jetson TX2i on the Connect Tech Elroy carrier board using the Yocto Project."
---

# Space Operating Linux

A minimal memory foot-print operating system for edge computing devices, capable of operating in radiation prone environment.

This project adapts research from - [**E. Miller, C. Heistand and D. Mishra, "Space-operating Linux: An Operating System for Computer Vision on Commercial-Grade Equipment in LEO," *2023 IEEE Aerospace Conference*, Big Sky, MT, USA, 2023, pp. 1-12**](https://ieeexplore.ieee.org/document/10115703) and related literature on using commercial off the shelf hardware and compute with redundancy to build a flight-viable Linux system image targeting the **NVIDIA Jetson TX2i** system-on-module mounted on the **Connect Tech Elroy Carrier board**.

The build system uses the **Yocto Project** (Kirkstone branch), enabling us to produce a minimal image with a reduced software footprint, ROS core packages, and a PREEMPT_RT patched kernel for deterministic real-time scheduling — engineered for Low Earth Orbit missions.
Yocto is a Open Source Framework which helps create custom linux distros for embedded devices from the ground up.

[Start with the Roadmap](roadmap.md){ .md-button .md-button--primary }
[Phase 0 — Literature Review](phase0/index.md){ .md-button }

---

## Target Hardware

### NVIDIA Jetson TX2i

![NVIDIA Jetson TX2i module stacked on carrier](https://connecttech.com/wp-content/uploads/2018/03/TX2i_ASG002_Stack.jpg)

The **NVIDIA Jetson TX2i** is the industrial-grade variant of the Jetson TX2 system-on-module, designed for demanding embedded and edge AI applications. Its extended temperature range, vibration tolerance, and ECC-capable memory make it well-suited for space-adjacent deployments.

| Category | Specification |
|---|---|
| **GPU** | NVIDIA Pascal™ — 256 CUDA cores, 1.3 TFLOPS (FP16) |
| **CPU** | Dual-core Denver 2 64-bit + Quad-core ARM Cortex-A57 |
| **Memory** | 8 GB 128-bit LPDDR4 with ECC support @ 1600 MHz (51.2 GB/s) |
| **Storage** | 32 GB eMMC 5.1 |
| **Operating Temp** | −40 °C to +85 °C |
| **Storage Temp** | −40 °C to +85 °C |
| **Humidity** | 95 % RH, −10 °C to 65 °C (non-condensing) |
| **Vibration** | 5 G RMS, 10–500 Hz (random/sinusoidal) |
| **Shock** | 140 G, half-sine 2 ms |
| **Voltage Input** | 9 V – 19.6 V DC |
| **Module Power** | 10 W – 20 W |
| **Software** | NVIDIA Linux for Tegra® (L4T) driver package - We Will Build our own custom image though. |

*Source: [NVIDIA Jetson TX2i — NVIDIA Developer](https://developer.nvidia.com/embedded/jetson-tx2i)*

---

### Jetson TX2i System-on-Module (on TX2 DevKit)

![Jetson TX2 system-on-module mounted on the TX2 Development Kit carrier board](https://jetsonhacks.com/wp-content/uploads/2017/03/IMG_1956.jpg.webp)

The SoM (System-on-Module) plugs into a carrier board via a high-density connector. During **Phase 1**, the standard **TX2 Development Kit** carrier board was used for initial bring-up and validation of the Yocto build before moving to custom hardware.

---

### ConnectTech Elroy Carrier Board + Jetson TX2i

[![ConnectTech Elroy Carrier Board with Jetson TX2i](https://connecttech.com/wp-content/uploads/2023/06/Elroy_header_TX2_image.png)](https://connecttech.com/product-category/form-factors/nvidia-jetson-tx2-tx1/)

The **Connect Tech Elroy** is a compact, rugged carrier board designed specifically for the Jetson TX2/TX2i SoM. It is the target deployment hardware for this project, replacing the development kit in **Phase 2** onwards.

*Image © [Connect Tech Inc.](https://connecttech.com/product-category/form-factors/nvidia-jetson-tx2-tx1/) — used for reference only.*

---

## Project Goals

- [x] Reduced software footprint — target system image < 5 GB on the Jetson TX2i + Devkit.
- [x] ROS (Robot Operating System) — core packages for robotic payload control
- [x] Adapted the System Image for the Jetson TX2i + ConnectTech Elroy Carrier Board. 
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
    P0["Phase 0\nLiterature &\nRedundancy Initial Study and Understanding \nWeek 1-2"]
    P1["Phase 1\nMinimal Yocto\nBuild\nWeek 2-3"]
    P2["Phase 2\nCustom Hardware\nAdaptation\nWeek 3-4"]
    P3["Phase 3\nPREEMPT_RT\nPatch\nWeek 4"]
    CW["Current Work\nOngoing"]
    FW["Future Work\nPlanned"]

    P0 --> P1 --> P2 --> P3 --> CW --> FW
```

---


