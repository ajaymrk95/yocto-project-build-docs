# Research Papers Overview & Detailed Summary

<span class="phase-label">Phase 0 · Literature Review</span>

This page provides an extensive, detailed review of the three foundational research papers that form the theoretical basis of this project. These papers analyze the hardware, software, and radiation vulnerabilities encountered when running embedded Linux on commercial-grade hardware in space environments like Low Earth Orbit (LEO).

---

## 1. Introduction to Space Computing & COTS Hardware

### The Technological Gap in Aerospace
For decades, space missions relied on specialized, radiation-hardened microprocessors. These processors (such as the BAE RAD750) are physically modified during manufacturing to withstand the harsh space environment. This physical hardening involves:
*   **Silicon-on-Insulator (SOI)** substrates to reduce the active volume of silicon susceptible to particle strikes.
*   **Logical Redundancy** (such as latching gates with feedback loops or triple modular hardware redundancy) on the silicon die itself.
*   **Wider Transistor Features** (large gate widths) to ensure that the critical charge required to flip a gate is high.

However, this physical hardening process is extremely slow and expensive. Consequently, radiation-hardened chips are typically several generations behind commercial technology. They run at very slow speeds (often under 200 MHz) and lack the computational power required for modern algorithms like real-time computer vision, autonomous navigation, and artificial intelligence.

In satellite missions, the payload computer is responsible for handling raw data from sensors, such as high-resolution cameras, multispectral imagers, and radar. Downlinking this massive volume of raw data presents an increasingly expensive bottleneck that drastically reduces mission efficiency. If the satellite can process this data on board (edge computing) and only downlink the high-value results, the required downlink bandwidth drops by orders of magnitude. This requirement creates an urgent demand for high-performance processors on board.

### The Rise of COTS and NVIDIA Jetson
To bridge this gap, modern aerospace engineers are increasingly turning to Commercial Off-The-Shelf (COTS) hardware. These are standard, mass-produced commercial chips used in terrestrial industries, such as mobile phones, robotics, and self-driving cars. 

The **NVIDIA Jetson TX2i** is a prime example of a COTS module of interest for space missions:
*   **Processor Architecture**: It integrates a 64-bit ARMv8 multi-processor (dual-core Denver 2 and quad-core ARM Cortex-A57 CPU) with a 256-core CUDA-compatible NVIDIA Pascal architecture GPU.
*   **Shared Memory**: It features a shared memory space between the CPU and GPU (8GB LPDDR4 memory) which eliminates the latency and power draw of copying data over external buses (like PCIe).
*   **Industrial Grade Upgrades**: Unlike the standard Jetson TX2, the TX2i (industrial) includes upgrades such as ECC (Error-Correcting Code) memory support, a wider operational temperature range (-40°C to 85°C), a longer operating lifetime (10 years), and high vibration resistance, making it suitable for aerospace environments.

### The Trade-off: High Performance vs. High Susceptibility
While COTS devices offer unmatched computing performance, they are not designed for space. They are manufactured using tiny transistor geometries (typically 16nm or smaller for modern SoCs), making them highly sensitive to the space radiation environment. Protons, heavy ions, and galactic cosmic rays can easily pass through the thin silicon layers of these chips, causing electrical disturbances. Therefore, to fly a COTS module like the Jetson TX2i, we must implement a combination of external hardware supervisors and software-level fault-tolerance layers.

---

## 1.1 Deep Dive: NVIDIA Jetson Tegra SoC Architectures

To build a software mitigation framework, we must analyze the internal components of the Tegra SoC on the Jetson TX2i.

### The Denver 2 and Cortex-A57 Heterogeneous CPU Layout
The CPU subsystem on the Tegra Parker SoC consists of two distinct CPU clusters:
1.  **NVIDIA Denver 2 Cluster (Dual-Core)**: The Denver 2 is a custom, in-house NVIDIA design implementing the ARMv8-A instruction set. It uses an advanced technique called **Dynamic Code Optimization**. Instead of decoding ARM instructions directly in hardware, it reads ARM instructions, translates them into custom internal micro-operations (micro-ops), optimizes the micro-op sequence in software, and caches the optimized translation in system RAM (known as the Optimization Cache).
    *   *Radiation Susceptibility*: While Dynamic Code Optimization increases performance, it introduces a unique vulnerability. If a proton strikes the RAM region holding the Optimization Cache (causing an SEU), the translated micro-ops will contain corrupted instructions. This leads to silent data corruption or immediate processor lockups that bypass normal kernel fault handlers.
2.  **ARM Cortex-A57 Cluster (Quad-Core)**: The Cortex-A57 is a standard, out-of-order execution processor cluster designed by ARM. It features dedicated L1 caches (48KB instruction, 32KB data per core) and a shared 2MB L2 cache.
    *   *ECC Protection*: The Cortex-A57 L2 cache features ECC protection, capable of correcting single-bit flips and detecting double-bit flips. However, the L1 caches only feature parity detection, which can detect errors but cannot correct them, relying on the kernel to abort or retry the operation.

### The Pascal GPU Architecture and Memory Hierarchy
The Jetson TX2i GPU consists of two Pascal Streaming Multiprocessors (SMs) containing a total of 256 CUDA cores.
*   **Memory Interfaces**: The CPU and GPU share a unified 128-bit LPDDR4 memory controller, providing up to 58.4 GB/s of bandwidth.
*   **ECC on System RAM**: On the TX2i, the LPDDR4 controller features inline ECC support. This is a critical upgrade over the standard TX2. The inline ECC detects and corrects single-bit flips in the system RAM in real-time, which is essential because the GPU libraries and neural network weights occupy large regions of memory.
*   **GPU Cache Vulnerability**: While system RAM is ECC-protected, the internal GPU register files, L1 caches, and shared memory structures inside the Streaming Multiprocessors do not have full ECC protection. A particle strike in the GPU register file during a neural network inference can alter a weight, causing incorrect object detection (silent data corruption) without triggering an OS crash.

---

## 2. Physics of Space Radiation & Silicon Hazards

To understand how software can protect hardware, we must first understand how radiation interacts with silicon microchips. When high-energy particles (protons, heavy ions, or cosmic rays) pass through a semiconductor, they lose energy and create electron-hole pairs along their track. This ionization path creates transient currents that disrupt circuit operations. The primary radiation hazards in space are categorized as follows:

```text
                                RADIATION HAZARDS
                                        │
           ┌────────────────────────────┴────────────────────────────┐
           ▼                                                         ▼
  Single Event Effects (SEEs)                               Total Ionizing Dose (TID)
  [Transient & Instantaneous]                               [Gradual & Cumulative]
           │
           ├───────────────┬───────────────┬───────────────┐
           ▼               ▼               ▼               ▼
         SEUs            SELs            SEFIs           SETs
      (Bit-Flips)    (Short Circuit)   (System Freezes) (Transient Spikes)
```

### 1. Single Event Effects (SEEs)
A Single Event Effect is an electrical anomaly caused when a single high-energy particle strikes a sensitive node in a microchip. SEEs are instantaneous and random. They include:

#### A. Single Event Upsets (SEUs)
An SEU is a soft error where a particle strike deposits enough charge to flip a memory cell from a binary `0` to a `1`, or vice versa. 
*   **Registers and Caches**: Bit-flips in processor registers or cache memory can corrupt active variables, causing the software to execute incorrect instructions or crash.
*   **RAM**: Bit-flips in system RAM corrupt data structures, memory pointers, or code segments.
*   **Flash Memory**: Bit-flips in non-volatile flash storage (like the eMMC) can permanently corrupt system files, rendering the device unbootable.
*   **Mechanism**: The charge deposited by the particle exceeds the critical charge ($Q_{crit}$) required to hold the logic state of the gate. This causes the feedback loop of the bistable latch to switch states.

#### B. Single Event Latch-ups (SELs)
An SEL is a highly dangerous hard error. Commercial microchips are built using CMOS technology, which contains parasitic structures that act like silicon-controlled rectifiers (thyristors). 
*   When a heavy ion or proton strikes these parasitic structures, it can trigger them into a conducting state, creating a direct short-circuit between the power rail and ground.
*   This causes a sudden, massive surge in current.
*   If the current is not cut off immediately, the excess heat will permanently melt the silicon, destroying the microchip.
*   **Recovery**: The only way to stop an SEL is to physically cut the power supply to the device and turn it back on (hard power cycle).

#### C. Single Event Functional Interrupts (SEFIs)
A SEFI is an event where a particle strike corrupts the control logic of a device rather than its data cells.
*   For example, if a particle strikes the register of a memory controller, the controller may stop responding to read/write requests.
*   This causes the entire processor to lock up, freeze, or enter an infinite reset loop, requiring a system reboot or power cycle to recover.

#### D. Single Event Transients (SETs)
An SET is a temporary voltage spike or glitch propagating through a combinational logic circuit. If this spike is sampled by a clock edge in a register, it can turn into an SEU.

### 2. Total Ionizing Dose (TID)
Unlike SEEs, which are caused by single particle strikes, TID is a cumulative effect. It represents the gradual accumulation of ionizing radiation damage (primarily trapped holes in the oxide layers) over the course of a mission. TID causes threshold voltage shifts, increased leakage current, and eventual functional failure. Physical shielding (like aluminum enclosures) can reduce TID, but software-level mitigation is required to handle the sudden, unpredictable SEEs.

---

## 2.1 The Space Radiation Environment

Developing a robust software strategy requires understanding the specific orbits and environmental conditions where the satellite operates.

### Low Earth Orbit (LEO) Characteristics
Low Earth Orbit ranges from 160 km to 2,000 km above Earth's surface. While LEO is partially protected by Earth's magnetosphere, it is still exposed to high-energy particle radiation:
1.  **Galactic Cosmic Rays (GCRs)**: High-energy charged particles (mostly protons and alpha particles, with a small fraction of heavy ions) originating outside our solar system. GCRs have extreme energy levels, allowing them to easily penetrate typical aluminum shielding.
2.  **Solar Energetic Particles (SEPs)**: High-energy protons ejected by the sun during solar flares and coronal mass ejections (CMEs). The flux of SEPs is highly dependent on the 11-year solar cycle.

### The Van Allen Belts and the South Atlantic Anomaly (SAA)
The Earth's magnetic field captures charged particles, creating two concentric rings of radiation known as the Van Allen Belts.
*   **Inner Belt**: Composed of high-energy protons (exceeding 100 MeV) trapped by the geomagnetic field, ranging from 1,000 km to 6,000 km.
*   **The South Atlantic Anomaly (SAA)**: Due to the tilt and offset of Earth's magnetic dipole axis, the inner radiation belt dips down to an altitude of about 200 km over South America and the South Atlantic Ocean. 
    *   *The Hazard*: Satellites in LEO cross this SAA region multiple times a day. During an SAA crossing, the proton flux spikes by several orders of magnitude. The probability of experiencing an SEU, SEL, or SEFI increases dramatically during these crossings.
    *   *Mitigation*: Software running on the satellite must be designed to handle this localized high-stress environment, potentially executing proactive memory scrubbing or entering a low-power, high-reliability state when entering the SAA.

---

## 3. Detailed Analysis of Space-Operating Linux (SOL)

### Citation
[**E. Miller, C. Heistand and D. Mishra, "Space-operating Linux: An Operating System for Computer Vision on Commercial-Grade Equipment in LEO," *2023 IEEE Aerospace Conference*, Big Sky, MT, USA, 2023, pp. 1-12**](https://ieeexplore.ieee.org/document/10115703)

### Core Contribution
The authors designed **Space Operating Linux (SOL)**, a minimized, Yocto-based operating system designed to run on the **NVIDIA Jetson TX2i** module for LEO CubeSat missions. SOL provides a robust software-level defense against radiation-induced storage and memory corruption.

---

### Software Triple Modular Redundancy (TMR)

#### Conceptual Redundancy Scheme
To protect critical boot files, SOL implements a Software Triple Modular Redundancy (TMR) scheme. Instead of storing a single copy of the boot assets (kernel, device tree, and root filesystem archive), the storage is partitioned to hold three identical copies of each asset along with their corresponding MD5 hash checksums.

#### The Checksum and Bit-Voting Flow
During startup, the custom bootloader environment validates these copies to ensure a reliable boot:

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

1.  **Read and Checksum**: The bootloader attempts to read and calculate the MD5 checksum of each copy (Copy A, B, and C).
2.  **Validation**: If any copy matches its pre-calculated hash, it is loaded into memory, and the boot sequence continues.
3.  **Bit-Voting**: If all three copies are corrupted (meaning none match their stored checksums), the bootloader falls back to a bit-voting algorithm. It performs a bit-by-bit majority election in volatile RAM to reconstruct the file.
4.  **Bit-Voting Logic**:
    *   Let the three corrupted copies in memory be represented as byte arrays $A$, $B$, and $C$, each of size $N$ bytes.
    *   The reconstructed file array $O$ is computed using fast bitwise majority voting logic: `O[i] = (A[i] & B[i]) | (B[i] & C[i]) | (C[i] & A[i])`. This bitwise operation computes the majority vote for all 8 bits of a byte simultaneously, keeping bootloader overhead minimal.

---

### Volatile RAM-based Filesystem (`tmpfs`)

#### Bypassing eMMC Write Wear
Even if the system boots successfully, running the active OS off the eMMC disk during orbit is a major hazard. Continuous logging, temporary files, and library accesses force the eMMC controller to write and read from flash cells constantly, raising the probability of a radiation strike corrupting a live block.

To address this, SOL utilizes a RAM-based filesystem approach:
*   **Extraction to RAM**: During the boot sequence, the kernel loads into an initial RAM disk (`initramfs`). A startup routine locates the compressed root filesystem on the eMMC, validates its integrity, mounts a virtual RAM drive (`tmpfs`), extracts the root filesystem into this RAM drive, and pivots the root filesystem (`switch_root`) into the RAM disk.
*   **Operational Isolation**: Once extracted, the system runs entirely from volatile RAM. Any runtime file reads, library accesses, or log writes happen in memory, isolating and silencing the physical eMMC disk during operation to minimize radiation vulnerability.
*   **Write-Back Partitions**: For persistent storage of telemetry or images, the paper mounts small dedicated partitions on the eMMC for quick, controlled write operations, minimizing the write window on physical storage.

#### Memory Constraints
The major drawback of running the entire OS in RAM is memory usage:
*   The Jetson TX2i has 8GB of LPDDR4 memory.
*   The proprietary NVIDIA CUDA, TensorRT, and OpenCV libraries required for GPU computing are massive.
*   Including these libraries in the RAM-based filesystem creates a root filesystem that exceeds **1 Gigabyte** in size.
*   This uses up a static **15%** of the available RAM before any payload applications are even started. Thus, developers must keep their application footprint small to avoid running out of memory.

---

### Real-Time Patches & Minimization

#### OS Minimization via Yocto
To fit the filesystem inside the RAM, the OS must be stripped of all desktop utilities, packages, and unneeded drivers. The authors built SOL using the **Yocto Project**, creating a custom layer named `meta-sol` on top of the NVIDIA board support package layer `meta-tegra`. They replaced standard core UNIX utilities with **BusyBox**, which combines tiny versions of many common UNIX utilities into a single, highly optimized executable.

#### PREEMPT_RT Integration
In space systems, software tasks must run deterministically. If a background operating system task interrupts a critical control loop or sensor query, it can cause system instability. SOL includes the **PREEMPT_RT** patch, which modifies the Linux kernel to make it fully preemptible.
*   **Priority Inheritance**: In standard Linux, a low-priority task holding a lock can be preempted by a medium-priority task, leaving a high-priority task waiting for the lock blocked indefinitely (Priority Inversion). The RT patch implements Priority Inheritance, temporarily boosting the low-priority task's priority to match the waiting high-priority task.
*   **Threaded Interrupt Handlers**: The RT patch converts hardware interrupt service routines (ISRs) into kernel threads. This allows the scheduler to prioritize critical control loops over incoming Ethernet packets or disk I/O.

In latency tests using `rt-migrate-test` (which schedules parallel real-time tasks to test scheduler response), the results were highly favorable:
*   **SOL (PREEMPT_RT)**: Priority 6 tasks maintained a highly consistent latency ranging between **14 and 63 microseconds**, even under heavy CPU stress.
*   **Stock L4T (Standard Kernel)**: The same tasks suffered massive scheduling jitter, with latency spikes ranging from **23 to 31,268 microseconds** (31 milliseconds). This jitter would instantly violate a strict 4ms hardware control loop deadline.

---

### Proton Irradiation Testing at TRIUMF

The authors validated the SOL-loaded Jetson TX2i under active proton radiation to measure error rates and board survivability:

#### Testing Environment & Parameters
*   **Facility**: TRIUMF's Proton Irradiation Facility in Vancouver, BC.
*   **Beam Line**: Line 2C.
*   **Energy Levels**: Proton energies of 63 MeV and 105 MeV.
*   **Devices Under Test (DUTs)**: Four TX2i modules:
    *   DUT 1 and DUT 2 were loaded with SOL (in brand-new condition).
    *   DUT 3 and DUT 5 were loaded with standard L4T (controls).
    *   DUT 3 had been previously irradiated to 50 kRad during JHU APL testing.
*   **Stress Workloads**: Runs included general CPU stress (`stress-ng`), GPU memory sorting and bandwidth tests, and memory stressors (`memtester`). Telemetry was logged over Ethernet to an external laptop running InfluxDB.

#### Experimental Findings
*   **No Permanent Failures**: Unlike prior tests conducted by the Johns Hopkins Applied Physics Lab (APL), which saw permanent board failures after an average of four runs under proton radiation, the TRIUMF runs resulted in **zero permanent failures** across all devices.
*   **The Collimator Beam Disparity**: The authors traced this difference to the beam collimator size. The TRIUMF test used a narrow 1cm x 1cm square collimator that targeted the Tegra SoC die directly, shielding the surrounding board components. The JHU APL test used a wider beam that exposed the peripheral eMMC flash memory and power controllers.
*   **Flash Memory Vulnerability**: This confirmed that **the off-chip peripheral flash memory (eMMC) and power management chips, rather than the primary Tegra silicon SoC, are the primary contributors to critical, permanent hardware failure on the Jetson under radiation**.
*   **Error Logs & Characterization**: 
    The logs recorded multiple types of errors under radiation. The authors categorized them in Table 2:
    *   *Primary Failures*: CPU memory faults, processor check errors (`ROC:CCE`), GPU power management controller freezes (`GPU PMU`), and GPU queue errors (`GPU FIFO`).
    *   *Watchdog Events*: In run 4 of L4T-3, the board experienced a watchdog reset after a CPU memory crash.
    *   *SOL Resilience*: While SOL rebooted more frequently due to the PREEMPT_RT patch detecting faults early, it had a much lower rate of uncorrectable errors, preventing the permanent system locks observed in standard L4T.

---

## 4. UGA SSRL's Hardware Supervisor & Watchdog (AFC/CORGI)

### Citation
https://ieeexplore.ieee.org/document/8741765 C. Adams, A. Spain, J. Parker, M. Hevert, J. Roach and D. Cotten, "Towards an Integrated GPU Accelerated SoC as a Flight Computer for Small Satellites," 2019 IEEE Aerospace Conference, Big Sky, MT, USA, 2019, pp. 1-7, doi: 10.1109/AERO.2019.8741765.

### Core Contribution
This paper documents the design of the **Accelerated Flight Computer (AFC)** and its precursor, the **CORGI (Core GPU Interface)** board. It provides the hardware-level supervisor and watchdog architecture necessary to protect the commercial NVIDIA Jetson module from destructive latch-ups and system freezes in space.

---

### Heterogeneous System Architecture

The AFC is built around a heterogeneous (mixed-processor) architecture to combine reliability with performance. Because the NVIDIA Jetson TX2i is a COTS device, it cannot be trusted to run core satellite flight controls on its own. If a latch-up freezes the Jetson, the satellite would lose attitude control and communication.

Therefore, the AFC divides responsibilities between two components:

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

#### 1. The SmartFusion2 (SF2) Supervisor Node
The core flight controller of the AFC is the **Microsemi SmartFusion2 SoC (M2S150T)**. 
*   It contains an ARM Cortex-M3 microcontroller and a flash-based FPGA fabric.
*   The SmartFusion2 is highly radiation-tolerant. Its embedded SRAM (eSRAM) and DDR memory bridges are protected against Single Event Upsets (SEUs) at the hardware level.
*   It operates at a very low static power draw of only **7mW**, making it highly efficient.
*   The SF2 is responsible for handling I/O, monitoring satellite health, and acting as the master node. It only enables the power supply to the NVIDIA Jetson TX2i when high-performance computation (like image processing) is required.

#### 2. The NVIDIA Jetson TX2i Payload Node
The Jetson TX2i acts strictly as a co-processor. It receives tasks from the SmartFusion2, processes them using GPU-accelerated code (CUDA), and writes results back.

#### 3. Signal Logic level shifters
Because the Jetson TX2i operates on a modern 1.8V CMOS logic level, and the SmartFusion2 operates on a robust 3.3V LVTTL logic level, they cannot be connected directly. The AFC incorporates **bidirectional logic level shifters** to convert voltage levels on all SPI, I2C, UART, and GPIO lines, ensuring clean and safe communication between the chips.

---

### Watchdog Timer & Power-Cycling Schematics

#### Latch-up Protection Loop
Under heavy ion bombardment in space, the Jetson TX2i is vulnerable to **Single Event Latch-ups (SELs)**. An SEL causes a parasitic short-circuit inside the silicon, leading to an immediate spike in current. If the current is not cut, the chip will burn out.
*   **Current Sensing**: The SmartFusion2 contains a dedicated current-monitoring circuit connected to the power rail of the Jetson TX2i.
*   **Threshold Trigger**: If the current draw of the Jetson spikes above **7.5 Watts**, the SF2 registers a latch-up event.
*   **Power Cut**: The SF2 FPGA fabric immediately drives a GPIO control line low. This line is connected to a physical **Field-Effect Transistor (FET) switch** on the power supply line of the Jetson. This cuts all power to the Jetson instantly, preventing thermal destruction and clearing the latch-up state.

#### Heartbeat Watchdog State Machine
To handle software-level freezes or logic lockups (SEFIs) where the Jetson remains powered but stops executing code, the FPGA implements a state machine:
*   The Jetson TX2i must regularly toggle a dedicated GPIO pin (sending a square wave "heartbeat" signal) to the SF2 FPGA.
*   The watchdog logic in the FPGA operates as a state machine:

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

1.  **IDLE State**: The Jetson is powered off.
2.  **STARTUP State**: The Jetson is powered on; a boot timer runs (allowing up to 120 seconds for boot).
3.  **MONITORING State**: The FPGA waits for the heartbeat pulse. If a pulse is received within the watchdog window (typically 100 milliseconds), the timer resets.
4.  **RESET State**: If the timer expires (no pulse received) or the current sensor detects a surge, the FPGA drives the power control line low, cutting power for 5 seconds. It then transitions back to the STARTUP state.
*   Upon detecting a heartbeat failure, the SF2 watchdog initiates a **physical hard power cycle** via the FET switch, cutting power for a brief period before restarting the Jetson to force a clean boot.

---

### Shared SPI Flash Memory & Multiplexer (MUX)

To prevent data corruption during a Jetson crash, the two processors do not share a direct database. Instead, they share access to a radiation-hardened **Cypress SPI NOR Flash memory chip** (CYRS16B256) through a physical multiplexer:
*   The SPI bus lines of the NOR flash are routed through a hardware **Multiplexer (MUX)**.
*   The MUX select lines are wired directly to the GPIO pins of the radiation-tolerant SmartFusion2.
*   **Mediated Access**: The SF2 acts as the gatekeeper. When it wants to transfer a task to the Jetson, it writes the data to the NOR flash, then toggles the MUX select line to route the SPI bus to the Jetson. The Jetson reads the data, processes it, writes the output back to the NOR flash, and signals completion. The SF2 then toggles the MUX to isolate the flash bus.
*   This physical isolation guarantees that if the Jetson undergoes a radiation-induced crash or write latch-up, it cannot write garbage data to the shared flash or corrupt the flight computer's files.

---

## 5. paper 3

### Citation
[**A. Bhattacharya et al., "Linux Boot Failures Under Proton Irradiation," 2025 IEEE Space Computing Conference (SCC), Los Angeles, CA, USA, 2025, pp. 35-45, doi: 10.1109/SCC66396.2025.00011.**](https://ieeexplore.ieee.org/document/11480247)

### Core Contribution
This paper presents a critical, state-of-the-art analysis of Linux-based operating systems booting under proton radiation. While the previous two papers assume that protecting the files on disk (via TMR) and using a hardware watchdog is sufficient, this study proves that **the boot sequence is the most vulnerable phase of operation under radiation**, exposing several software and hardware flaws missed by previous research.

---

### Discovered Boot Vulnerabilities (Skipped in Previous Papers)

The authors conducted proton beam radiation tests on an NXP i.MX8M Plus compute module (four ARM Cortex-A53 cores running at 1.6 GHz and an ARM Cortex-M7 core running at 800 MHz) at the **AIC-144 cyclotron facility** of the Henryk Niewodniczański Institute of Nuclear Physics (IFJ PAN) in Krakow, Poland. They discovered the following vulnerabilities:

#### 1. The ECC Memory Initialization Gap (The "ECC Blind Window")
Industrial SoMs like the Jetson TX2i and the i.MX8M Plus support inline Error-Correcting Code (ECC) RAM. ECC is highly effective at correcting single-bit flips (SEUs) in memory.
*   **The Flaw**: In default Linux BSPs (Board Support Packages), the DDR ECC controller is initialized late in the startup sequence, typically during the transition to user-space.
*   **The Vulnerability**: During the entire early kernel boot phase (where the kernel decompresses itself into RAM, parses the Device Tree, and initializes basic memory maps), **ECC is disabled**. Any radiation-induced bit-flip in RAM during this window will cause an immediate kernel panic and boot failure.
*   **The Impact**: The assumption that ECC RAM protects the system from boot-time memory errors is false. Software must be configured to initialize the ECC controller at the earliest possible stage (in the primary bootloader, U-Boot) before loading the Linux kernel.

#### 2. eMMC Controller Driver Failures
Previous papers assumed that file-level TMR (Triple Modular Redundancy) on the eMMC flash disk solves storage errors. However, this paper found that the physical **host memory controller chip** on the eMMC drive itself is highly vulnerable to radiation.
*   **The Failures**: Protons strike the eMMC's control logic, causing the drive to lock up. This triggers driver communication timeouts, logging `mmc2: cache flush error -110` (write timeout) and `blk_update_request: I/O error` (read failure) in the Linux storage driver (`sdhci.c`).
*   **The Impact**: The kernel loses access to the storage drive entirely, forcing the filesystem to mount as read-only.

#### 3. Filesystem Journal Metadata Corruption
Monolithic operating systems like Linux rely on a filesystem journaling layer (JBD2) to maintain consistency.
*   **The Failure**: Bit-flips in RAM corrupt active filesystem journal buffers during boot, leading to the error `JBD2: Error -5 detected when updating journal superblock`.
*   **The Impact**: The filesystem mounts as read-only or panics. While Linux runs disk check utilities (`fsck`) automatically to correct this, running `fsck` while memory bit-flips are actively occurring frequently triggers immediate kernel panics.

#### 4. Fault Cascades and "Bleeding"
The authors identified a critical failure path called **fault bleeding**:
*   **Level 0 (Unobserved)**: A bit-flip corrupts a non-essential driver configuration in the Device Tree or memory map early in the boot sequence. The system continues booting without an error.
*   **Level 1 (Device driver fail)**: The host interface fails to talk to the flash memory correctly.
*   **Level 2 (Filesystem fail)**: The root filesystem enters a corrupted state and remounts as read-only.
*   **Level 3 (Failure)**: Much later, during user-space handoff, high-level services (such as Docker, Containerd, or disk management utilities) attempt to start. When they invoke the corrupted driver, the services crash. The satellite fails to initialize its payload despite a "successful" boot log.

#### 5. Power Signature Analysis for Boot Diagnostics
The authors proved that SoC boot health can be monitored externally by measuring the power current draw curves:
*   *Successful Cold Start*: Smooth, distinct power peaks (2.8W to 3.0W) as modules initialize, settling into a stable plateau.
*   *Successful Soft Reboot*: Moderate power draw (1.5W to 2.0W) with fewer peaks.
*   *Failed Bootloader Loop*: Continuous, erratic power oscillations that never stabilize.
*   *Failed Kernel (Freeze)*: Power spikes to a high level and remains flat indefinitely, indicating a frozen processor.

#### Boot Failure Log Examples
The following error traces illustrate the actual logs obtained from the boot failures:

```text
# Example 1: Storage Controller Timeout
[   41.685291] blk_update_request: I/O error, dev mmcblk2, sector 8192 op 0x1:(WRITE) flags 0x23800
[   41.696197] Buffer I/O error on dev mmcblk2p1, logical block 0, lost sync page write
[   41.774248] EXT4-fs (mmcblk2p1): Remounting filesystem read-only

# Example 2: Journal Superblock Corruption
[   39.561741] JBD2: Error -5 detected when updating journal superblock for mmcblk2p1-8.
[   41.738854] EXT4-fs error (device mmcblk2p1): ext4_journal_check_start:83: comm systemd: Detected aborted journal

# Example 3: User-space Service Failure (Fault Bleeding)
[   49.244343] systemd[1]: Failed to start container runtime (containerd.service)
[   49.255812] systemd[1]: Dependency failed for Docker Application Container Engine (docker.service)
```

---

## 5.1 In-Depth Cascading Failure Scenario (Fault Bleeding Walkthrough)

To understand how Level 0 faults bleed into Level 3 system services, we follow a concrete example:

```text
[Proton Strike] -> SEU in DTB Node (RAM) -> Driver Misconfigures Clock -> Telemetry Timeout -> Daemon Crashes -> Boot Aborted
```

1.  **Level 0 (DTB Node Corruption)**: A proton strikes the region of RAM where the system decompressed the Device Tree Blob (DTB). It flips a bit in the configuration register offset of the I2C-1 host bus interface. The kernel finishes booting and initializes the I2C driver without showing an error because the driver registers load successfully (even with the wrong clock speed configuration).
2.  **Level 1 (Device driver registers affected)**: The I2C-1 driver operates, but due to the corrupted register clock divisor, it drives the SCL clock line at 1.2 MHz instead of the targeted 400 kHz.
3.  **Level 2 (Hardware bus communications degrade)**: When the satellite enters orbit, the telemetry daemon starts. It attempts to read data from the IMU and thermal sensors over the I2C-1 bus. Due to the excessive clock speed, the sensors fail to respond, leading to bus timeouts and empty data arrays.
4.  **Level 3 (High-level service crashes)**: The telemetry daemon receives empty data. Because it lacks error-handling for empty buffers, it encounters a segmentation fault and crashes. Systemd attempts to restart the daemon, which fails repeatedly. The startup script triggers an automated reboot, causing the system to enter an infinite loop.

---

## 5.2 Storage Host Controller Register Failure Analysis

The `mmc2: cache flush error -110` error log is highly illustrative of host controller upsets.

When the Linux kernel writes dirty pages to the eMMC disk, it invokes the MMC host controller driver (`drivers/mmc/host/sdhci.c`). The driver writes command commands to the MMIO (Memory-Mapped I/O) registers of the SDHCI host interface:

1.  The driver prepares an command packet and writes to the `SDHCI_COMMAND` register (offset `0x0E`).
2.  It writes the command argument to the `SDHCI_ARGUMENT` register (offset `0x08`).
3.  It polls the `SDHCI_PRESENT_STATE` register (offset `0x24`) to check the `Command Inhibit (CMD)` bit, waiting for the command to complete.
4.  *Under radiation*: A proton strikes the `SDHCI_PRESENT_STATE` register or the internal command-state registers of the host controller. The logic locks up, showing the `Command Inhibit` bit as permanently high.
5.  *The Timeout*: The driver timeout expires after 250ms, causing the driver function `sdhci_send_command()` to fail. The kernel aborts the active write, resulting in the block I/O error (`blk_update_request: I/O error`) and forcing the EXT4 driver to mount the filesystem as read-only to prevent storage corruption.

---

## 6. Combined System Design Recommendations

To build a robust Space Linux system on the NVIDIA Jetson TX2i, we must synthesize the lessons from these three papers:

1.  **Extract Filesystem to RAM (from SOL)**: To prevent eMMC controller timeouts (`mmc2: cache flush error -110`) and write errors, the root filesystem must be extracted into a volatile RAM drive (`tmpfs`) at boot, keeping the physical flash unmounted.
2.  **Enable ECC in U-Boot (from Boot Failures Paper)**: We must patch the primary bootloader (U-Boot) to enable the RAM ECC controller at the very first boot instruction, protecting kernel decompression from early memory bit-flips.
3.  **Implement Supervisor Power Control (from Allen GPU Paper)**: The software must interface with an external supervisor FPGA (SmartFusion2). If the Jetson's power exceeds **7.5 Watts** (latch-up) or the heartbeat fails, the FPGA must execute a physical hard reset.
4.  **Suppress Bootloops (from Boot Failures Paper)**: If U-Boot detects three consecutive boot failures, it must halt and signal the supervisor FPGA to execute a hard power cycle, rather than entering an infinite boot loop.

---



---

## 7. Appendix: Technical Reference Glossary

To assist non-CS aerospace and mechanical engineers in navigating this documentation, the following glossary defines the core hardware and software terminology used in this literature review:

*   **COTS (Commercial Off-The-Shelf)**: Standard, mass-produced electronics designed for terrestrial consumers (e.g., cell phones or automotive controllers). They offer high processing speeds at low cost but lack physical radiation hardening.
*   **eMMC (embedded MultiMediaCard)**: A non-volatile storage chip soldered directly onto the system board, acting as the system's hard drive. Under radiation, its internal control circuit is highly vulnerable to transient lockups.
*   **EDAC (Error Detection and Correction)**: Circuitry or software that detects memory data corruption (such as bit-flips) and automatically restores the correct data.
*   **Inline ECC (Error-Correcting Code)**: A hardware memory feature that calculates and stores parity bits next to data bytes. In system RAM, inline ECC can automatically correct single-bit flips and detect double-bit flips in real-time.
*   **PREEMPT_RT**: A patch set that converts the standard monolithic Linux kernel into a deterministic, real-time operating system. It guarantees that high-priority tasks are executed within precise time constraints.
*   **TMR (Triple Modular Redundancy)**: A redundancy scheme where a process or memory block is triplicated, and a voting circuit or script determines the true output based on a majority vote.
*   **tmpfs**: A Linux kernel driver that creates a virtual storage partition directly within volatile RAM. Accessing files in `tmpfs` is extremely fast and generates zero physical storage write cycles.
*   **U-Boot**: An open-source bootloader responsible for initializing hardware registers and booting the Linux kernel from persistent storage.

---

[← Phase 0 Overview](index.md){ .md-button }
[Next: Phase 1 — Minimal Build →](../phase1/index.md){ .md-button .md-button--primary }
