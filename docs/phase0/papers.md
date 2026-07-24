# Research Papers Overview & Detailed Summary

<span class="phase-label">Phase 0 · Literature Review</span>

This page provides an in-depth review of the three foundational research papers that form the theoretical basis of this project. The review is structured to follow the logical progression of the research: first, how a software-hardened Linux operating system was built using Yocto for space (**Paper 1 — SOL**); second, how the hardware supervisor platform that hosts it was designed and validated (**Paper 2 — AFC/CORGI**); and third, what critical boot-phase vulnerabilities remain unsolved and were only recently discovered under live proton irradiation (**Paper 3 — Boot Failures**).

---

## 1. Space-Operating Linux (SOL) — A Yocto-Based OS for LEO

### Citation
[**E. Miller, C. Heistand and D. Mishra, "Space-operating Linux: An Operating System for Computer Vision on Commercial-Grade Equipment in LEO," *2023 IEEE Aerospace Conference*, Big Sky, MT, USA, 2023, pp. 1-12**](https://ieeexplore.ieee.org/document/10115703)

### Core Contribution
The authors designed **Space Operating Linux (SOL)**, a minimized, radiation-resilient Linux operating system purpose-built to run on the **NVIDIA Jetson TX2i** module aboard LEO CubeSat missions. SOL is the primary software artifact that this project aims to reproduce and extend. It addresses the central challenge of flying commercial hardware in space: how do you keep a non-radiation-hardened processor running reliably when high-energy particles are constantly striking the silicon?

SOL answers this with three interlocking software strategies, all implemented within the **Yocto Project** build system:

1.  **Software Triple Modular Redundancy (TMR)** for boot-critical files on flash storage.
2.  **A volatile RAM-based root filesystem (`tmpfs`)** that eliminates runtime flash access.
3.  **A `PREEMPT_RT` real-time kernel** that provides deterministic scheduling for hardware control loops.

---

### 1.1 Why COTS Hardware and Why the Jetson TX2i?

For decades, space missions relied on specialized, radiation-hardened microprocessors such as the BAE RAD750. These chips are physically modified during manufacturing — using Silicon-on-Insulator (SOI) substrates, logical redundancy on the die, and intentionally wide transistor geometries — to withstand the space radiation environment. However, this physical hardening is extremely slow and expensive. Radiation-hardened chips typically run several generations behind commercial technology (often under 200 MHz) and lack the computational power required for modern algorithms like real-time computer vision, autonomous navigation, and on-board AI inference.

The demand for on-board edge computing is growing rapidly. If a satellite can process raw sensor data on-board and only downlink the high-value results, the required downlink bandwidth drops by orders of magnitude, dramatically improving mission efficiency.

To bridge this gap, the authors turned to **Commercial Off-The-Shelf (COTS)** hardware. The **NVIDIA Jetson TX2i** was selected for its combination of high performance and industrial-grade features:

*   **Processor Architecture**: A 64-bit ARMv8 heterogeneous multi-processor (dual-core NVIDIA Denver 2 + quad-core ARM Cortex-A57 CPU) paired with a 256-core CUDA-compatible NVIDIA Pascal GPU.
*   **Shared Memory**: 8GB LPDDR4 unified memory shared between CPU and GPU, eliminating the latency and power draw of copying data over external buses.
*   **Industrial Grade (TX2i) Upgrades**: Unlike the standard Jetson TX2, the TX2i includes **inline ECC memory support**, a wider operational temperature range (-40°C to 85°C), a 10-year operating lifetime, and high vibration resistance — features that make it viable for aerospace environments.

The critical trade-off is that COTS chips are manufactured using tiny transistor geometries (16nm for the Tegra Parker SoC), making them highly sensitive to space radiation. Protons, heavy ions, and galactic cosmic rays can easily cause electrical disturbances in the thin silicon layers. SOL exists to mitigate these disturbances entirely in software.

---

### 1.2 Building SOL with the Yocto Project

#### OS Minimization via a Custom Yocto Layer

The authors built SOL using the **Yocto Project**, an industry-standard framework for creating custom embedded Linux distributions. Yocto allows developers to define exactly which packages, drivers, and libraries are included in the final system image, producing a minimal, purpose-built OS with no unnecessary components.

The SOL build system is structured as a custom Yocto layer named **`meta-sol`**, built on top of NVIDIA's board support package layer **`meta-tegra`**. Key minimization decisions included:

*   **BusyBox**: All standard core UNIX utilities (`ls`, `cp`, `cat`, `grep`, etc.) were replaced with **BusyBox**, which combines tiny versions of many common utilities into a single, highly optimized executable. This dramatically reduces the filesystem footprint.
*   **Stripped Packages**: All desktop utilities, graphical environments, documentation, and unnecessary kernel modules were removed from the image recipe. Only the packages strictly required for the mission payload (CUDA, TensorRT, OpenCV for GPU inference) and system operation were retained.
*   **Custom Image Recipe**: The Yocto image recipe defines the exact package set, filesystem layout, and boot configuration, ensuring reproducible builds.

#### PREEMPT_RT Kernel Integration

In space systems, software tasks must execute within strict, deterministic time constraints. A background OS task that interrupts a critical attitude-control loop or sensor query can cause system instability or missed deadlines. SOL integrates the **`PREEMPT_RT`** patch set into the Linux kernel, converting it into a fully preemptible, real-time operating system.

The `PREEMPT_RT` patch was applied within the Yocto build system by modifying the kernel recipe in `meta-sol` to fetch, apply, and compile the RT patch against the NVIDIA L4T kernel source. The key features of the RT-patched kernel are:

*   **Priority Inheritance**: In standard Linux, a phenomenon called *Priority Inversion* can occur — a low-priority task holding a mutex lock gets preempted by a medium-priority task, causing a high-priority task waiting for that lock to be blocked indefinitely. The RT patch implements **Priority Inheritance**, which temporarily boosts the low-priority lock-holder's priority to match the highest-priority waiter, ensuring the lock is released promptly.
*   **Threaded Interrupt Handlers**: The RT patch converts hardware Interrupt Service Routines (ISRs) into schedulable kernel threads. This allows the scheduler to prioritize critical payload control loops over incoming Ethernet packets, disk I/O, or other interrupts that would otherwise preempt all running code.

---

### 1.3 Software Triple Modular Redundancy (TMR)

#### The Radiation Problem for Storage

The primary non-volatile storage on the Jetson TX2i is an **eMMC (embedded MultiMediaCard)** flash chip soldered to the module. In the space radiation environment, high-energy particles can cause **Single Event Upsets (SEUs)** — bit-flips that change a `0` to a `1` or vice versa — in the flash memory cells. A single bit-flip in a critical boot file (the kernel image, the device tree, or the root filesystem archive) can render the entire system unbootable.

#### The TMR Scheme

To protect against this, SOL implements a **Software Triple Modular Redundancy (TMR)** scheme on the eMMC storage. Instead of storing a single copy of each boot-critical asset, the eMMC storage is partitioned to hold **three identical copies** of each asset along with their corresponding **MD5 hash checksums**.

#### The Checksum and Bit-Voting Boot Flow

During startup, the custom U-Boot bootloader environment validates these copies before proceeding:

```text
               [Power On / Startup]
                        │
                        ▼
             [Read Triplicated BLOBs]
             (Copy A, Copy B, Copy C)
                        │
                        ▼
           [Calculate MD5 Checksums]
                        │
         ┌──────────────┴──────────────┐
         ▼                             ▼
   [Hash Match?]                [All Hashes Fail!]
   Yes: Load Copy                      │
   No: Try Next Copy                   ▼
                               [Execute Bit-Voting]
                         (Bit-by-Bit Majority Election)
                                       │
                                       ▼
                             [Reconstruct in RAM]
                                       │
                                       ▼
                                 [Boot Kernel]
```

1.  **Read and Checksum**: The bootloader reads each of the three copies and calculates their MD5 checksums.
2.  **Validation**: If any copy's calculated hash matches its pre-stored checksum, that copy is known-good and is loaded into RAM for booting.
3.  **Bit-Voting Fallback**: If *all three* copies are corrupted (none match their stored checksums), the bootloader falls back to a **bit-by-bit majority voting algorithm**. It loads all three copies into volatile RAM and reconstructs a corrected version:
    *   Let the three corrupted copies be byte arrays $A$, $B$, and $C$ of size $N$ bytes.
    *   The reconstructed array $O$ is computed using fast bitwise majority logic:
        `O[i] = (A[i] & B[i]) | (B[i] & C[i]) | (C[i] & A[i])`
    *   This single bitwise operation computes the majority vote for all 8 bits of each byte simultaneously, keeping bootloader overhead minimal. As long as no more than one copy has a bit-flip at the same position, the correct value is recovered.

---

### 1.4 Volatile RAM-Based Root Filesystem (`tmpfs`)

#### The Problem: Runtime Flash Vulnerability

Even after a successful TMR-validated boot, running the active OS directly from the eMMC disk during orbital operations is a major hazard. Continuous file reads (library loading, logging, temporary files) keep the eMMC controller active, raising the probability that a radiation strike will corrupt a live block while it is being read or written.

#### The Solution: Extract to RAM and Silence the Disk

SOL uses a **RAM-based filesystem** strategy to isolate the eMMC after boot:

1.  **Boot into `initramfs`**: The kernel boots into a minimal initial RAM disk (`initramfs`) — a small, self-contained filesystem loaded entirely in RAM.
2.  **Validate and Extract**: A startup script within the `initramfs` locates the compressed root filesystem archive on the eMMC, validates its integrity (using the TMR checksums), and extracts it into a virtual RAM drive (`tmpfs`).
3.  **Pivot Root (`switch_root`)**: The system pivots its root filesystem into the RAM-based `tmpfs`, making all subsequent file operations happen entirely in volatile memory.
4.  **Operational Isolation**: Once the pivot is complete, the eMMC disk is effectively silenced. All runtime file reads, library accesses, and log writes happen in ECC-protected RAM, not on the vulnerable flash storage.

#### Write-Back Partitions

For data that must persist across reboots (telemetry, captured images), SOL mounts small, dedicated eMMC partitions for quick, controlled write operations. These writes are minimized and batched to keep the flash exposure window as short as possible.

#### Memory Constraints

The primary trade-off of running the entire OS in RAM is memory consumption:

*   The Jetson TX2i has **8GB** of LPDDR4 memory.
*   The proprietary NVIDIA CUDA, TensorRT, and OpenCV libraries required for GPU-accelerated inference are very large.
*   Including these libraries produces a root filesystem exceeding **1 Gigabyte** in size.
*   This consumes a static **~15%** of the available RAM before any payload applications are started. Developers must keep their application footprint small and carefully manage memory allocation.

---

### 1.5 Proton Irradiation Testing at TRIUMF

The authors validated their SOL-loaded Jetson TX2i modules under active proton radiation to measure real-world error rates and board survivability.

#### Testing Environment & Parameters

*   **Facility**: TRIUMF's Proton Irradiation Facility, Vancouver, BC.
*   **Beam Line**: Line 2C.
*   **Proton Energy Levels**: 63 MeV and 105 MeV.
*   **Devices Under Test (DUTs)**: Four TX2i modules:
    *   DUT 1 and DUT 2 — loaded with SOL (brand-new condition).
    *   DUT 3 and DUT 5 — loaded with standard L4T (controls).
    *   DUT 3 had been previously irradiated to 50 kRad during JHU APL testing.
*   **Stress Workloads**: General CPU stress (`stress-ng`), GPU memory sorting and bandwidth tests, and memory stressors (`memtester`). Telemetry was logged over Ethernet to an external laptop running InfluxDB.

#### Key Findings

*   **No Permanent Failures**: Unlike prior tests conducted by the Johns Hopkins Applied Physics Lab (APL) — which saw permanent board failures after an average of four runs under proton radiation — the TRIUMF runs resulted in **zero permanent failures** across all devices.
*   **The Collimator Beam Disparity**: The authors traced this difference to the beam collimator size. The TRIUMF test used a narrow **1cm × 1cm** square collimator targeting the Tegra SoC die directly, shielding the surrounding board components. The JHU APL test used a wider beam that exposed the peripheral eMMC flash memory and power management controllers.
*   **Flash Memory Is the Weak Link**: This confirmed a critical finding — **the off-chip peripheral flash memory (eMMC) and power management chips, not the primary Tegra SoC, are the primary contributors to permanent hardware failure on the Jetson under radiation**. This directly validates SOL's design decision to extract the filesystem into RAM and silence the eMMC during operation.

#### Error Log Characterization

The irradiation logs recorded multiple error categories under radiation, which the authors categorized as follows:

*   **Primary Failures**: CPU memory faults, processor check errors (`ROC:CCE`), GPU power management controller freezes (`GPU PMU`), and GPU queue errors (`GPU FIFO`).
*   **Watchdog Events**: In run 4 of the L4T-3 control, the board experienced a watchdog reset after a CPU memory crash.
*   **SOL Resilience**: While SOL rebooted more frequently (because the `PREEMPT_RT` patch detected faults early and triggered clean shutdowns), it had a much lower rate of *uncorrectable* errors, preventing the permanent system locks observed in standard L4T.

---

## 2. The Accelerated Flight Computer — Hardware Watchdog & Supervisor (AFC/CORGI)

### Citation
[**C. Adams, A. Spain, J. Parker, M. Hevert, J. Roach and D. Cotten, "Towards an Integrated GPU Accelerated SoC as a Flight Computer for Small Satellites," 2019 IEEE Aerospace Conference, Big Sky, MT, USA, 2019, pp. 1-7, doi: 10.1109/AERO.2019.8741765.**](https://ieeexplore.ieee.org/document/8741765)

### Core Contribution

This paper, published four years before SOL, documents the design of the **Accelerated Flight Computer (AFC)** and its precursor board, the **CORGI (Core GPU Interface)**, developed by the University of Georgia's Small Satellite Research Laboratory (UGA SSRL). It provides the **hardware-level supervisor and watchdog architecture** that protects the commercial NVIDIA Jetson module from destructive radiation effects — specifically, the latch-ups and system freezes that no amount of software can recover from.

While SOL (Paper 1) provides the software resilience layer, the AFC provides the physical infrastructure that keeps the Jetson alive. Together, they form the complete system architecture: the AFC powers and monitors the Jetson, while SOL runs on it.

---

### 2.1 The Need for a Hardware Supervisor

The NVIDIA Jetson TX2i is a COTS device. It cannot be trusted to run core satellite flight controls on its own. Two classes of radiation effects demand hardware-level intervention:

1.  **Single Event Latch-ups (SELs)**: A high-energy particle strikes a parasitic thyristor structure within the CMOS silicon, triggering a direct short-circuit between the power rail and ground. This causes a massive, sudden surge in current. If the current is not physically cut within milliseconds, the excess heat will permanently melt the silicon, destroying the chip. **No software running on the affected chip can recover from this — the power must be physically disconnected.**
2.  **Single Event Functional Interrupts (SEFIs)**: A particle corrupts the control logic of the processor itself (e.g., the memory controller or clock generator), causing the chip to freeze, hang, or enter an infinite reset loop. The Jetson remains powered but stops executing code. Again, a physical power cycle is the only recovery mechanism.

If the Jetson freezes due to a SEFI, the satellite loses its payload computer. If it experiences an unchecked SEL, it loses the hardware permanently. The AFC solves both problems with a heterogeneous dual-processor architecture.

---

### 2.2 Heterogeneous System Architecture

The AFC divides responsibilities between two fundamentally different processors:

```text
     +--------------------------------------------------------+
     |             ACCELERATED FLIGHT COMPUTER (AFC)          |
     |                                                        |
     |  +-----------------------+      +-------------------+  |
     |  |    SmartFusion2       |      |    NVIDIA Tegra   |  |
     |  |   (Rad-Tolerant)      |      |       TX2i        |  |
     |  |                       |      | (Commercial GPU)  |  |
     |  |  [ARM Cortex-M3]      |      |                   |  |
     |  |  [FPGA Watchdog]      |      |  - GPU Workloads  |  |
     |  +-----------#-----------+      +---------#---------+  |
     |              │                            │            |
     |              └──────────────┬─────────────┘            |
     |                             │                          |
     |                     [Level Shifters]                   |
     |                      (1.8V <-> 3.3V)                   |
     |                             │                          |
     |                             ▼                          |
     |                   [Hardware SPI MUX]                   |
     |                             │                          |
     |                             ▼                          |
     |                 [Cypress SPI NOR Flash]                |
     |                                                        |
     +--------------------------------------------------------+
```

#### 1. The SmartFusion2 (SF2) — Radiation-Tolerant Supervisor

The core flight controller is the **Microsemi SmartFusion2 SoC (M2S150T)**, a mixed-signal FPGA with an embedded ARM Cortex-M3 microcontroller:

*   **Radiation Tolerance**: The SmartFusion2 uses flash-based FPGA fabric (not SRAM-based), making it inherently resistant to SEU-induced configuration bit-flips. Its embedded SRAM and DDR memory bridges are protected against SEUs at the hardware level.
*   **Ultra-Low Power**: It operates at a static power draw of only **7mW**, making it viable for always-on satellite operation where power budgets are extremely tight.
*   **Role**: The SF2 handles satellite I/O, health monitoring, attitude control telemetry, and acts as the master node. It only enables the power supply to the Jetson TX2i when high-performance GPU computation (like image processing or neural network inference) is required.

#### 2. The NVIDIA Jetson TX2i — High-Performance Payload Co-Processor

The Jetson TX2i acts strictly as a **co-processor**. It does not run flight-critical control loops. It receives compute tasks from the SmartFusion2, processes them using CUDA-accelerated code, and writes results back. If the Jetson crashes, the satellite continues operating on the SF2 alone.

#### 3. Signal Level Shifters

Because the Jetson TX2i operates on modern 1.8V CMOS logic and the SmartFusion2 operates on robust 3.3V LVTTL logic, they cannot be connected directly. The AFC incorporates **bidirectional logic level shifters** to convert voltage levels on all SPI, I2C, UART, and GPIO lines between the two processors.

---

### 2.3 Watchdog Timer & Latch-Up Protection

#### Latch-Up Protection Loop (Current Sensing)

The SF2 implements a dedicated **current-monitoring circuit** on the power rail of the Jetson TX2i:

*   **Current Sensing**: A sense resistor or current monitor IC measures the real-time power draw of the Jetson.
*   **Threshold Trigger**: If the current draw spikes above **7.5 Watts** (indicating a latch-up short-circuit), the SF2 registers an SEL event.
*   **Physical Power Cut**: The SF2 FPGA fabric immediately drives a GPIO control line low. This line is connected to a physical **Field-Effect Transistor (FET) switch** on the power supply line of the Jetson. Driving the gate low opens the FET, cutting all power to the Jetson instantly — preventing thermal destruction and clearing the latch-up state.

#### Heartbeat Watchdog State Machine

To detect software-level freezes (SEFIs) where the Jetson remains powered but stops executing, the FPGA implements a **watchdog state machine**:

*   The Linux software running on the Jetson must regularly toggle a dedicated GPIO pin, producing a square-wave "heartbeat" signal that the SF2 FPGA monitors.
*   The watchdog operates through four states:

```text
               +----------------------------------+
               |             IDLE                 |
               |       (Jetson Powered Off)       |
               +----------------┬-----------------+
                                │
                        Start Command
                                │
                                ▼
               +----------------------------------+
               |            STARTUP               |
               |      (Boot Timer Running)        |
               +----------------┬-----------------+
                                │
                         Boot Successful
                                │
                                ▼
               +----------------------------------+
               |           MONITORING             |
               |       (Active Watchdog)          |
               +----------------┬-----------------+
                                │
                      Timeout / Power Surge
                                │
                                ▼
               +----------------------------------+
               |              RESET               |
               |       (Power Cut for 5s)         |
               +----------------------------------+
```

1.  **IDLE**: The Jetson is powered off. The SF2 operates alone.
2.  **STARTUP**: The Jetson is powered on. A boot timer runs, allowing up to **120 seconds** for the OS to boot and begin sending heartbeats.
3.  **MONITORING**: The FPGA actively monitors the heartbeat signal. If a pulse is received within the watchdog window (typically **100 milliseconds**), the timer resets. Normal operation continues.
4.  **RESET**: If the timer expires (no heartbeat received) *or* the current sensor detects a latch-up surge, the FPGA drives the power control FET off, cutting power for **5 seconds**. It then transitions back to **STARTUP** to attempt a clean reboot.

---

### 2.4 Shared SPI Flash Memory & Hardware Multiplexer (MUX)

To prevent data corruption during a Jetson crash, the two processors do not share a direct memory bus. Instead, they share access to a radiation-hardened **Cypress SPI NOR Flash memory chip** (CYRS16B256) through a physical hardware multiplexer:

*   The SPI bus lines of the NOR flash are routed through a hardware **Multiplexer (MUX)**.
*   The MUX select lines are wired directly to GPIO pins on the radiation-tolerant SmartFusion2.
*   **Mediated Access Protocol**:
    1.  The SF2 writes a task (e.g., an image to process) to the NOR flash.
    2.  It toggles the MUX select line to route the SPI bus to the Jetson.
    3.  The Jetson reads the data, processes it on the GPU, and writes the output back to the NOR flash.
    4.  The Jetson signals completion. The SF2 toggles the MUX to reclaim the bus.
*   **Physical Isolation Guarantee**: If the Jetson undergoes a radiation-induced crash or write latch-up while connected to the flash, the SF2 can simply toggle the MUX to disconnect it. This guarantees that a crashing Jetson cannot write garbage data to the shared flash or corrupt the flight computer's critical files.

---

## 3. Linux Boot Failures Under Proton Irradiation — The Most Vulnerable Phase

### Citation
[**A. Bhattacharya et al., "Linux Boot Failures Under Proton Irradiation," 2025 IEEE Space Computing Conference (SCC), Los Angeles, CA, USA, 2025, pp. 35-45, doi: 10.1109/SCC66396.2025.00011.**](https://ieeexplore.ieee.org/document/11480247)

### Core Contribution

This paper, published in 2025, presents a critical finding that challenges the assumptions of the previous two papers. While SOL (Paper 1) assumes that protecting files on disk via TMR and running from RAM is sufficient, and the AFC (Paper 2) assumes that a hardware watchdog can reset the system after any failure, this study proves that **the boot sequence itself is the most vulnerable phase of operation under radiation** — a phase where neither TMR nor the watchdog can help, because the system has not yet finished initializing.

The authors conducted proton beam irradiation tests on an **NXP i.MX8M Plus** compute module (four ARM Cortex-A53 cores at 1.6 GHz, one ARM Cortex-M7 core at 800 MHz) at the **AIC-144 cyclotron facility** of the Henryk Niewodniczański Institute of Nuclear Physics (IFJ PAN) in Krakow, Poland. Their findings expose several software and hardware vulnerabilities that had been missed by previous research.

---

### 3.1 The ECC Memory Initialization Gap (The "ECC Blind Window")

Industrial SoMs like the Jetson TX2i and the i.MX8M Plus support **inline Error-Correcting Code (ECC)** RAM. ECC is highly effective at correcting single-bit flips (SEUs) in memory — when it is enabled.

*   **The Flaw**: In default Linux Board Support Packages (BSPs), the DDR ECC controller is initialized **late** in the startup sequence — typically during the transition from kernel space to user-space.
*   **The Blind Window**: During the entire early kernel boot phase — when the kernel decompresses itself into RAM, parses the Device Tree Blob (DTB), and initializes basic memory maps — **ECC is disabled**. The hardware protection that everyone assumes is active simply is not running yet.
*   **The Consequence**: Any radiation-induced bit-flip in RAM during this early window will go undetected and uncorrected, causing an immediate kernel panic and boot failure.
*   **The Mitigation**: The ECC controller must be initialized at the **earliest possible stage** — ideally within the primary bootloader (U-Boot's SPL or the SoC's boot ROM) — before the Linux kernel is even loaded into memory.

!!! warning "Critical Implication"
    The assumption that "ECC RAM protects the system from memory errors during boot" is **false** under default BSP configurations. Software must be explicitly configured to enable ECC before the kernel starts.

---

### 3.2 eMMC Controller Driver Failures

Previous papers (including SOL) assumed that file-level TMR on the eMMC flash disk solves storage corruption. This paper reveals a deeper problem: the physical **host memory controller chip** on the eMMC drive itself is highly vulnerable to radiation.

*   **The Mechanism**: Protons striking the eMMC's internal control logic cause the drive to lock up entirely. This is not a data corruption issue — it is a **controller hardware freeze**.
*   **The Symptoms**: The Linux MMC host driver (`drivers/mmc/host/sdhci.c`) reports communication timeouts:
    *   `mmc2: cache flush error -110` — a write timeout indicating the controller is not responding.
    *   `blk_update_request: I/O error` — a read failure indicating the block device is inaccessible.
*   **The Impact**: The kernel loses access to the entire storage device. The EXT4 filesystem driver forces a read-only remount to prevent further corruption.

!!! note "Why This Matters for SOL"
    SOL's TMR scheme protects against bit-flips *in the stored data*. But if the eMMC controller itself freezes, the bootloader cannot read *any* of the three copies — TMR becomes useless. This validates SOL's decision to extract to RAM as quickly as possible, but also highlights that the boot phase (before extraction is complete) remains critically exposed.

---


### 3.3 Fault Cascades and "Fault Bleeding"

The most insidious discovery in this paper is **fault bleeding** — a cascading failure path where a silent, undetected bit-flip early in boot propagates through multiple system layers, eventually crashing high-level services long after the "successful" boot completes.

The authors define four escalation levels:

```text
[Proton Strike] → SEU in RAM → Driver Misconfigures → Service Timeout → Daemon Crash → Boot Aborted
```

*   **Level 0 — Unobserved**: A bit-flip corrupts a non-essential driver configuration (e.g., a clock divisor in the Device Tree) in RAM during early boot. The kernel continues booting without error because the corrupted value is still syntactically valid.
*   **Level 1 — Device Driver Failure**: The affected driver initializes with wrong parameters (e.g., an I2C bus running at 1.2 MHz instead of 400 kHz). The driver itself reports no error.
*   **Level 2 — Hardware Communication Degradation**: Sensors or peripherals on the misconfigured bus fail to respond, producing timeouts and empty data arrays.
*   **Level 3 — User-Space Service Crash**: High-level daemons (telemetry, containerd, Docker) attempt to use the degraded hardware interface. They receive empty or corrupt data, encounter unhandled exceptions, and crash. Systemd attempts restarts, which fail repeatedly, potentially triggering an infinite reboot loop.

!!! danger "Why Fault Bleeding Is So Dangerous"
    The system appears to boot successfully. Kernel logs show no errors. But the satellite's payload services fail to start, and the root cause — a single bit-flip that occurred seconds into boot — is invisible in the boot log. This makes diagnosis from ground extremely difficult.

#### Concrete Walkthrough

1.  A proton strikes the RAM region holding the decompressed Device Tree Blob. It flips a bit in the register offset of the I2C-1 host bus interface.
2.  The I2C driver initializes without error, but drives the SCL clock line at 1.2 MHz instead of 400 kHz.
3.  The telemetry daemon starts and queries IMU/thermal sensors over I2C-1. The sensors cannot keep up with the excessive clock speed and fail to respond.
4.  The telemetry daemon receives empty buffers, lacks error handling for this case, and segfaults. Systemd restarts it repeatedly. After N failures, the system triggers an automated reboot — entering an infinite loop.

---

### 3.4 Power Signature Analysis for External Boot Diagnostics

The authors proved that an external supervisor (like the AFC's SmartFusion2) can diagnose SoC boot health by measuring the **power current draw profile** during startup:

| Boot Outcome | Power Signature |
| :--- | :--- |
| **Successful Cold Start** | Smooth, distinct power peaks (2.8W–3.0W) as modules initialize, settling into a stable plateau |
| **Successful Soft Reboot** | Moderate draw (1.5W–2.0W), fewer peaks |
| **Failed Bootloader Loop** | Continuous, erratic power oscillations that never stabilize |
| **Failed Kernel (Freeze)** | Power spikes high and remains flat indefinitely — frozen processor |

This finding directly informs the design of the AFC's watchdog: by monitoring current draw patterns (not just heartbeat presence), the supervisor FPGA can distinguish between a healthy boot, a boot loop, and a hard freeze — enabling smarter recovery decisions.

---

### 3.5 Boot Failure Log Examples

The following error traces illustrate actual kernel logs obtained during proton irradiation:

```text
# Storage Controller Timeout
[   41.685291] blk_update_request: I/O error, dev mmcblk2, sector 8192 op 0x1:(WRITE) flags 0x23800
[   41.696197] Buffer I/O error on dev mmcblk2p1, logical block 0, lost sync page write
[   41.774248] EXT4-fs (mmcblk2p1): Remounting filesystem read-only

# Journal Superblock Corruption
[   39.561741] JBD2: Error -5 detected when updating journal superblock for mmcblk2p1-8.
[   41.738854] EXT4-fs error (device mmcblk2p1): ext4_journal_check_start:83: comm systemd: Detected aborted journal

# User-Space Service Failure (Fault Bleeding)
[   49.244343] systemd[1]: Failed to start container runtime (containerd.service)
[   49.255812] systemd[1]: Dependency failed for Docker Application Container Engine (docker.service)
```

---

### 3.7 Storage Host Controller Register Failure — Deep Dive

The `mmc2: cache flush error -110` failure is a detailed illustration of how radiation disrupts hardware controller registers at the MMIO level.

When the Linux kernel writes dirty pages to the eMMC, it invokes the MMC host controller driver (`drivers/mmc/host/sdhci.c`). The driver communicates with the SDHCI host interface through Memory-Mapped I/O (MMIO) registers:

1.  The driver prepares a command packet and writes to the `SDHCI_COMMAND` register (offset `0x0E`).
2.  It writes the command argument to the `SDHCI_ARGUMENT` register (offset `0x08`).
3.  It polls the `SDHCI_PRESENT_STATE` register (offset `0x24`), checking the `Command Inhibit (CMD)` bit and waiting for the command to complete.
4.  **Under radiation**: A proton strikes the `SDHCI_PRESENT_STATE` register or the internal command-state logic of the host controller. The register locks up, showing the `Command Inhibit` bit as permanently high.
5.  **The Timeout**: The driver timeout expires after 250ms. The function `sdhci_send_command()` fails. The kernel aborts the active write, producing the `blk_update_request: I/O error` log, and the EXT4 driver forces a read-only remount to prevent further storage corruption.

---

## 4. Synthesis — Combined System Design Recommendations

Drawing from all three papers, a robust Space Linux system on the NVIDIA Jetson TX2i requires the following combined strategy:

| Recommendation | Source Paper | Rationale |
| :--- | :--- | :--- |
| **Extract root filesystem to RAM (`tmpfs`) at boot** | SOL (Paper 1) | Prevents eMMC controller timeouts and write errors during operation by silencing the flash after boot |
| **Build a minimal OS image with Yocto + BusyBox** | SOL (Paper 1) | Reduces RAM footprint of the in-memory rootfs, leaving maximum memory for payload applications |
| **Apply `PREEMPT_RT` kernel patch** | SOL (Paper 1) | Provides deterministic scheduling for hardware control loops, preventing priority inversion |
| **Implement TMR with bit-voting on boot assets** | SOL (Paper 1) | Protects kernel, DTB, and rootfs archive against SEU-induced bit-flips on flash storage |
| **Use an external radiation-tolerant supervisor (SmartFusion2)** | AFC (Paper 2) | Provides physical power-cycle capability for SEL recovery and heartbeat-based SEFI detection |
| **Monitor Jetson current draw; cut power above 7.5W** | AFC (Paper 2) | Prevents thermal destruction from latch-up short-circuits |
| **Isolate shared storage via hardware MUX** | AFC (Paper 2) | Prevents a crashing Jetson from corrupting the flight computer's data |
| **Enable ECC in U-Boot before kernel load** | Boot Failures (Paper 3) | Closes the "ECC blind window" during early kernel decompression |
| **Suppress infinite boot loops (halt after N failures)** | Boot Failures (Paper 3) | Prevents the system from wasting power and time on unrecoverable boot attempts |
| **Use power signature analysis for boot diagnostics** | Boot Failures (Paper 3) | Enables the supervisor FPGA to distinguish healthy boots from boot loops and freezes |

---

## 5. Appendix: Technical Reference Glossary

To assist non-CS aerospace and mechanical engineers in navigating this documentation, the following glossary defines the core hardware and software terminology used in this literature review:

*   **COTS (Commercial Off-The-Shelf)**: Standard, mass-produced electronics designed for terrestrial consumers (e.g., cell phones or automotive controllers). They offer high processing speeds at low cost but lack physical radiation hardening.
*   **eMMC (embedded MultiMediaCard)**: A non-volatile storage chip soldered directly onto the system board, acting as the system's hard drive. Under radiation, its internal control circuit is highly vulnerable to transient lockups.
*   **EDAC (Error Detection and Correction)**: Circuitry or software that detects memory data corruption (such as bit-flips) and automatically restores the correct data.
*   **Inline ECC (Error-Correcting Code)**: A hardware memory feature that calculates and stores parity bits next to data bytes. In system RAM, inline ECC can automatically correct single-bit flips and detect double-bit flips in real-time.
*   **PREEMPT_RT**: A patch set that converts the standard monolithic Linux kernel into a deterministic, real-time operating system. It guarantees that high-priority tasks are executed within precise time constraints.
*   **SEE (Single Event Effect)**: An electrical anomaly caused by a single high-energy particle striking a sensitive node in a microchip. Includes SEUs, SELs, SEFIs, and SETs.
*   **SEU (Single Event Upset)**: A soft error where a particle strike flips a memory bit from 0 to 1 or vice versa.
*   **SEL (Single Event Latch-up)**: A hard error where a particle triggers a parasitic short-circuit in CMOS silicon, causing destructive overcurrent.
*   **SEFI (Single Event Functional Interrupt)**: A particle strike that corrupts device control logic, causing freezes or lockups.
*   **TID (Total Ionizing Dose)**: The cumulative radiation dose absorbed over a mission's lifetime, causing gradual parameter shifts and eventual failure.
*   **TMR (Triple Modular Redundancy)**: A redundancy scheme where a process or memory block is triplicated, and a voting circuit or script determines the true output based on a majority vote.
*   **tmpfs**: A Linux kernel driver that creates a virtual storage partition directly within volatile RAM. Accessing files in `tmpfs` is extremely fast and generates zero physical storage write cycles.
*   **U-Boot**: An open-source bootloader responsible for initializing hardware registers and booting the Linux kernel from persistent storage.

---

[← Phase 0 Overview](index.md){ .md-button }
[Next: Phase 1 — Minimal Build →](../phase1/index.md){ .md-button .md-button--primary }
