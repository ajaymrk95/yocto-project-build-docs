---
title: "Phase 4 — A/B Partition Redundancy"
description: "Introduction to dual partition redundancy, boot failover, system watchdogs, and target package management under Phase 4."
---

# Phase 4 — A/B Partition Redundancy

<span class="phase-label">Redundancy · Weeks 6–7</span>

!!! warning "Planned Phase"
    The detailed step-by-step guides for Phase 4 are currently planned and under development. Below is a high-level overview of the topics that will be covered.

---

## 1. High-Level Overview

For aerospace and mission-critical payloads, software single-point failures must be prevented. If an over-the-air update fails or a filesystem partition becomes corrupted due to single-event upsets (SEU), the bootloader must automatically fall back to a secondary, known-good boot partition.

Phase 4 will document:
- **A/B Partition Layout**: Setting up secondary root filesystem partitions (`APP_b`) and secondary device tree/kernel partitions.
- **Failover Logic (Tegra Bootloader)**: Configuring the bootloader parameters (scratch registers) to count boot attempts and switch partitions if a threshold is exceeded.
- **System Watchdogs**: Implementing kernel and user-space hardware watchdogs that force system reboots if critical service daemons fail to check in.
- **Remote Package Repositories**: Setting up a local, secured `apt` server to distribute binary packages to target modules.

---

[← Phase 3 Overview](../phase3/index.md){ .md-button }
