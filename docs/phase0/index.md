---
title: "Phase 0 — Literature & Redundancy Concepts"
description: "Understanding the research foundations and redundancy mechanisms for space-viable Linux systems."
---

# Phase 0 — Literature & Redundancy Concepts

<span class="phase-label">Research · Week 1–2</span>

!!! warning "Continuous Learning Process"
    This is a continuous process and is still not 100% understood. The content presented here is adapted to the best of the author's ability based on the referenced research papers. This section will be updated as understanding deepens through ongoing testing and validation.

---


## Radiation Effects on Space-Operating Systems

Space environments, particularly Low Earth Orbit (LEO), expose computing systems to severe radiation. These radiation events affect both the physical hardware circuits and the software execution. The critical radiation effects of concern are:

1.  **Single Event Effects (SEEs)**: A broad category of individual errors caused by high-energy particles (like protons, heavy ions, or cosmic rays) striking the silicon substrate of a microchip. SEEs can be transient (temporary) or permanent.
2.  **Single Event Upsets (SEUs)**: A type of SEE where a particle strike flips a single bit of data (changing a binary 0 to 1 or vice versa) in a device's memory cells, registers, or processor caches. This causes software variables to change unexpectedly, leading to computation errors or crashes.
3.  **Single Event Latch-ups (SELs)**: A high-risk SEE where a particle strike triggers a parasitic short-circuit within a CMOS chip. This causes a massive, localized current surge. If left unchecked, the excess heat can permanently burn out the circuit. The only way to recover a device from an SEL is to perform a hard physical power cycle (turning the power completely off and back on).
4.  **Single Event Functional Interrupts (SEFIs)**: An SEE that corrupts the control logic of a device (like a memory controller or clock generator), causing the chip to freeze, restart, or stop communicating.
5.  **Total Ionizing Dose (TID)**: The cumulative, long-term radiation dose absorbed by a component over its mission life. Over time, TID causes gradual electronic parameter shifts, eventually leading to permanent hardware failure.


## Literature-Review Citations

Below are the citations for the three foundational papers as per the IEEE Plain Text Citation Format:

1. [**E. Miller, C. Heistand and D. Mishra, "Space-operating Linux: An Operating System for Computer Vision on Commercial-Grade Equipment in LEO," *2023 IEEE Aerospace Conference*, Big Sky, MT, USA, 2023, pp. 1-12**](https://ieeexplore.ieee.org/document/10115703)
2. [**C. Adams, A. Spain, J. Parker, M. Hevert, J. Roach and D. Cotten, "Towards an Integrated GPU Accelerated SoC as a Flight Computer for Small Satellites," 2019 IEEE Aerospace Conference, Big Sky, MT, USA, 2019, pp. 1-7, doi: 10.1109/AERO.2019.8741765.**](https://ieeexplore.ieee.org/document/8741765)
3. [**A. Bhattacharya et al., "Linux Boot Failures Under Proton Irradiation," 2025 IEEE Space Computing Conference (SCC), Los Angeles, CA, USA, 2025, pp. 35-45, doi: 10.1109/SCC66396.2025.00011.**](https://ieeexplore.ieee.org/document/11480247)

---

### Summary of How the Papers Address Radiation Events

| Paper | Focus Event(s) | Primary Countermeasure / Mitigation Strategy |
| :--- | :--- | :--- |
| **Adams et al. (2019)** | **SEL** & **SEFI** | **Hardware-Level Watchdog**: Uses a separate, highly radiation-tolerant FPGA SoC (Microsemi SmartFusion2) to monitor the NVIDIA Tegra TX2i's power draw. If the TX2i draws excessive current (>7.5W, indicating a latch-up) or freezes (SEFI), the FPGA physically cuts and restores power to reset the board. |
| **Miller et al. (2023)** | **SEU** & **eMMC/Flash Wear** | **Software-Level Redundancy & RAM Booting**: Protects critical boot files (kernel, device tree, rootfs) on the vulnerable eMMC flash by storing them in three identical sectors (Triple Modular Redundancy - TMR). At boot, the bootloader (U-Boot) checks MD5 hashes, performs bit-voting to reconstruct corrupted blocks, and extracts the operating system entirely into volatile RAM (tmpfs), eliminating eMMC reads/writes during flight. |
| **Bhattacharya et al. (2025)** | **Boot-Phase SEUs** & **Fault Cascades** | **Early ECC & External Power Monitoring**: Reveals that COTS systems are highly vulnerable during the boot phase because built-in protection (like RAM Error-Correcting Code - ECC) is disabled until user-space starts. Proposes enabling ECC as early as possible in the boot ROM / bootloader, suppressing reboots on double-bit faults to avoid reboot loops, and using external power signature analysis to detect lockups. |

---

## Detailed Literature Analysis

For an in-depth breakdown of each paper's system architecture, hardware watchdog schematics, Triple Modular Redundancy (TMR) boot loaders, and the boot-phase vulnerabilities discovered under radiation, please refer to the primary summary subpage:

<div class="grid cards" markdown>

-   [__Research Papers — Detailed Summary__](papers.md)
    
    Explore the complete breakdown of system architectures, watchdog schematics, and TMR boot loaders.

</div>

---

[← Back to Roadmap](../roadmap.md){ .md-button }
[Next: Research Papers Overview →](papers.md){ .md-button .md-button--primary }
