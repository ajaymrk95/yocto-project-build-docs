---
title: "Phase 4 — A/B Partition Redundancy"
description: "Introduction to dual partition redundancy, boot failover, system watchdogs, and target package management under Phase 4."
---

# Phase 4 — A/B Partition Redundancy

<span class="phase-label">Redundancy · Weeks 4-5</span>

!!! info "Phase Goal"
    Configure A/B hardware and software redundancy on the Jetson TX2i. This phase covers enabling bootloader-level failover, setting up RootFS A/B slot redundancy using custom carrier board flash scripts, and configuring system watchdog daemons.

---

## 1. Phase Overview

For mission-critical payloads, software single-point failures must be prevented. If an over-the-air update fails or a filesystem partition becomes corrupted due to single-event upsets (SEU), the bootloader must automatically fall back to a secondary, known-good boot partition.

To achieve this level of reliability, we configured:
- **Bootloader A/B Redundancy**: Enabled the Slot Metadata Database (SMD) on the Nvidia Jetson TX2i, allowing the Tegra bootloader to count boot retries and switch boot slots.
- **RootFS A/B Redundancy**: Modified the custom Connect Tech Inc. (CTI) carrier board flashing utilities (introduced in [Phase 2 page 5](../phase2/05-connecttech-flash-scripts.md)) to support dual root filesystems via the `ROOTFS_AB=1` flashing variable.

---

## 2. Phase Structure

This phase is organized into the following sections:

1. **[Bootloader & RootFS Redundancy](01-bootloader-rootfs-redundancy.md)**
   Detailed configuration of `smd_info.cfg`, customized CTI flash scripts, failover testing via simulated kernel panics, and serial boot log analysis.
2. **[Yocto Integration Outline & Phase Conclusion](02-yocto-integration-outline.md)**
   Overview of ongoing Yocto-level RootFS integration steps, bootloader-level validation in Yocto, and a phase-wide conclusion.

---

[← Phase 3 Overview](../phase3/index.md){ .md-button }
