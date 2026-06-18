---
title: "Results, Analysis & Timers"
description: "Comparison of latency profiling results, analysis of scheduler histograms, and technical analysis of High-Resolution Timers (HRTimers) and Dynamic Ticks (NO_HZ) under the PREEMPT_RT patch."
---

# Results, Analysis & Timers

<span class="phase-label">Phase 3 · Page 6 of 6</span>

!!! abstract "Page Goal"
    - Compare scheduling latency distributions under standard and PREEMPT_RT kernels.
    - Understand the mathematical differences between timesharing jitter and deterministic real-time latency bounds.
    - Deep-dive into the architectural mechanics of Linux High-Resolution Timers (HRTimers) and the Dynamic Tick (tickless system) framework.
    - Establish a production checklist for deploying and maintaining real-time performance on Jetson systems.

---

## 1. Latency Profile Results & Analysis

When running the OSADL benchmark specs detailed on Page 4 (using `cyclictest` and `stress-ng` concurrently for a long duration), we record scheduling latency values. The resulting latency curves display two radically different profiles.

### Latency Distribution Histogram (Comparative Analysis)
The histogram below represents the frequency of occurrence for specific latency measurements (in microseconds) under a heavy simulated workload:



### Explaining the Latency Tail:
- **Standard Kernel (Unbounded Tail)**: The long tail extending past 10,000 microseconds (10ms) is caused by **non-preemptible regions** in the standard Linux kernel. When a standard user-space thread triggers a system call, or when the kernel handles a hardware interrupt, preemption is disabled. If a critical RT thread wakes up during this window, it must wait for the kernel to finish its operation, causing unpredictable jitter.
- **PREEMPT_RT Kernel (Strictly Bounded)**: By replacing spinlocks with preemptible mutexes and executing interrupt handlers as kernel threads, the RT patch guarantees that the scheduler can interrupt the kernel at almost any point. The execution latency is bounded at a worst-case limit of **35–40 microseconds**, regardless of system stress.

---

## 2. High-Resolution Timers (HRTimers) Architecture

Standard Linux kernels track time using a periodic interrupt called the **System Timer Tick**.
- The timer tick occurs at a configured frequency (typically 100 Hz, 250 Hz, or 1000 Hz).
- At 250 Hz, the kernel checks for scheduled events once every **4 milliseconds** (the *jiffie* interval).
- If an application requests a sleep duration of 1 millisecond using `usleep(1000)` on a standard kernel, the sleep event cannot trigger until the next timer tick occurs, resulting in up to 4ms of delay. This is known as **Timer Quantization Jitter**.

```text
Standard Timer Tick (250 Hz):
Tick (0ms) ----------------------- Tick (4ms) ----------------------- Tick (8ms)
     |                                   |                                  |
     v                                   v                                  v
[ Sleep Request for 1ms ] ------------> [ Wakeup Event triggered at 4ms tick! ]
(Latency = 3ms due to timer quantization)
```

To resolve this limitation, the `PREEMPT_RT` patch leverages the **High-Resolution Timers (HRTimers)** framework (`CONFIG_HIGH_RES_TIMERS=y`):

### How HRTimers Function:
1. **Hardware Independence**: Instead of relying on a fixed-frequency periodic tick, HRTimers configure the hardware's local timer chip (such as the ARM Generic Timer block on the Jetson TX2i's Cortex-A57 cores) to fire on-demand.
2. **Nanosecond Resolution**: The timer chip is programmed to trigger a hardware interrupt at the **exact nanosecond** requested by the application.
3. **Queue Mechanism**: Timers are organized in a time-ordered black-black tree (RB-tree) structure. The kernel programs the hardware timer to fire interrupts matching the expiration time of the earliest timer node.

```text
High-Resolution Timer Tick (Dynamic):
Wakeup Request (1.00ms) --------------> Hardware Interrupt (fires exactly at 1.00ms)
                                        |
                                        v
                               [ Thread Wakes Up ]
(Timer Quantization Jitter = ~0us)
```

---

## 3. Dynamic Tick (Full Tickless Operations)

By combining HRTimers with dynamic ticks (`CONFIG_NO_HZ_FULL=y`), the real-time kernel can disable the periodic system tick completely on cores running critical RT applications.

When a CPU core runs a single `SCHED_FIFO` real-time thread, the kernel suspends the periodic scheduling tick on that specific core. This achieves:
- **Reduced Context Switches**: The core does not spend cycles saving and restoring state for scheduling evaluations.
- **Zero Interrupt Overhead**: The CPU core executes the RT task without being interrupted by periodic timer events, maximizing execution determinism.

---

## 4. Developer's Real-Time Safety Checklist

When deploying software on a real-time patched Jetson system, developers must adhere to strict programming and configuration guidelines to maintain determinism:

### System Configuration
- [ ] **Run Jetson Clocks**: Always run `sudo jetson_clocks` immediately after booting. This disables Dynamic Voltage and Frequency Scaling (DVFS), locking the CPU, GPU, and memory bus speeds at their maximum levels. Dynamic frequency scaling introduces severe latency variations as the processor adjusts clocks.
- [ ] **Isolate Real-Time CPU Cores**: Use the kernel boot argument `isolcpus=2,3` to prevent the standard Linux scheduler from placing normal processes on cores 2 and 3. Dedicate these cores exclusively to real-time threads.
- [ ] **Redirect Interrupts**: Configure `/proc/irq/` affinity masks to route non-critical hardware interrupts (such as USB, SATA, or Wi-Fi) to CPU Core 0, leaving RT cores free of interrupt noise.

### C/C++ Source Code
- [ ] **Zero Dynamic Allocations**: Never call `malloc`, `new`, `free`, `std::vector::push_back`, or allocate dynamic objects inside the timing-critical execution path. Memory allocation requires kernel memory locks which can introduce unbounded delays.
- [ ] **Avoid I/O Operations**: Do not write to console logs (`std::cout`, `printf`), files, or trace points inside the loop. Writing data triggers blocking block-device or character-device drivers. Settle for writing logs to a shared lockless ring-buffer, allowing a background low-priority thread to save them to disk.
- [ ] **Lock Process Memory**: Ensure `mlockall(MCL_CURRENT | MCL_FUTURE)` is called on application initialization.
- [ ] **Pre-fault Thread Stack**: Allocate local variables on initialization to map physical pages.
- [ ] **Use Priority Inheritance Mutexes**: Initialize all mutexes that are shared between real-time threads and normal threads with the `PTHREAD_PRIO_INHERIT` attribute.

---

[← Hardware Robotics Interfacing](05-hardware-robotics-interfacing.md){ .md-button }
[Roadmap →](../roadmap.md){ .md-button .md-button--primary }
