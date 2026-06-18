---
title: "OSADL Latency Validation"
description: "How to run standardized real-time latency benchmarks using cyclictest and stress-ng according to OSADL testing specifications on the Jetson TX2i."
---

# OSADL Latency Validation

<span class="phase-label">Phase 3 · Page 4 of 6</span>

!!! abstract "Page Goal"
    - Introduce the Open Source Automation Development Lab (OSADL) real-time benchmarking standards.
    - Walk through configuring and executing `cyclictest` and `stress-ng` to measure worst-case latency under extreme load.
    - Analyze the expected metrics for both standard and real-time kernels.

---

## 1. The OSADL Benchmarking Standard

The **Open Source Automation Development Lab (OSADL)** is the leading industry cooperative promoting real-time Linux in industrial automation and safety systems. OSADL maintains strict benchmarks to qualify real-time kernels.

A valid real-time test cannot measure latency on an idle system. In space flight, cpu spikes, flash write cycles, and telemetry processing occur concurrently. Therefore, the OSADL benchmark standard requires running latency checks (**`cyclictest`**) for a long duration while simulating severe system stress (**`stress-ng`**).

```text
Host Stressors (stress-ng)
  ├── CPU Stress (Matrix calculations)
  ├── I/O Stress (Flash write loops)         =================>  Measure Jitter (cyclictest)
  └── Memory Stress (VM malloc loops)
```

---

## 2. Setting Up the Testing Tools

Install the benchmark utility packages on the Jetson target module:

```bash
# Install latency testing and system stress utilities
sudo apt-get update
sudo apt-get install -y rt-tests stress-ng
```

---

## 3. Simulating Load with `stress-ng`

We use `stress-ng` to generate heavy background workload on the CPU cores, RAM, and virtual memory systems. Run this command in a background terminal session on the target:

```bash
# Run VM, CPU, and I/O stressors on all cores for 1 hour
stress-ng --cpu $(nproc) --io 4 --vm 2 --vm-bytes 128M --timeout 3600
```

#### What the Flags Mean:
- `--cpu $(nproc)`: Spawns CPU stressors matching the total number of hardware execution cores, running complex arithmetic calculations.
- `--io 4`: Spawns 4 workers writing and sync'ing files, simulating flash access.
- `--vm 2 --vm-bytes 128M`: Spawns 2 virtual memory workers allocating and freeing chunks of RAM.

---

## 4. Running the Latency Benchmark (`cyclictest`)

While the host is under stress, execute `cyclictest` to measure scheduling delays:

```bash
# Execute cyclictest with high priority on all cores
sudo cyclictest -a -t -n -p 80 -i 1000 -h 10000 -q
```

#### Detailed Flag Explanations:
- **`-a`**: Thread affinity. Binds each testing thread to a specific CPU core.
- **`-t`**: Thread per core. Spawns one testing thread per hardware CPU core.
- **`-n`**: Nanosecond sleep. Instructs threads to sleep using high-resolution POSIX clock nanosecond timers (`clock_nanosleep`).
- **`-p 80`**: Priority. Configures the test threads to run under `SCHED_FIFO` real-time policy at priority `80`.
- **`-i 1000`**: Interval. Sets the thread wake-up loop interval to 1000 microseconds (1 millisecond).
- **`-h 10000`**: Histogram. Tracks wake-up delays in a histogram up to 10,000 microseconds (10ms) in 1us resolution buckets.
- **`-q`**: Quiet mode. Suppresses intermediate line output, printing a clean summary table on exit (after pressing `Ctrl+C`).

---

## 5. Analyzing the Metrics: Standard vs. Real-Time

When `cyclictest` completes, it outputs a summary containing the minimum, average, and maximum latency values recorded in microseconds:

### Expected Output Structure:
```text
T: 0 ( 3241) P:80 I:1000 C: 60000 Min:      4 Act:    9 Avg:   12 Max:     34
T: 1 ( 3242) P:80 I:1000 C: 60000 Min:      3 Act:    7 Avg:   11 Max:     29
...
```

### Comparative Latency Table

| Metric | Standard Kernel (Non-RT) | PREEMPT_RT Kernel (Real-Time) | Space Impact |
| :--- | :--- | :--- | :--- |
| **Minimum Latency** | ~3–5 microseconds | ~2–4 microseconds | Best-case response time. |
| **Average Latency** | ~15–30 microseconds | ~8–12 microseconds | Normal operational cycle overhead. |
| **Worst-Case Latency (Max)** | **> 12,000 microseconds (12+ ms)** | **< 40 microseconds** | **Deterministic Safety Bound.** If max latency exceeds 1ms, high-frequency control loops will fail. |

With the standard kernel, the maximum latency under load can reach **tens of milliseconds** due to blocked locks in the virtual filesystem and device drivers. In contrast, the `PREEMPT_RT` patch bounds the worst-case delay below **40 microseconds**, meeting strict real-time criteria.

---

[← Real-Time Scheduling Concepts](03-real-time-scheduling.md){ .md-button }
[Next: Hardware Robotics Interfacing →](05-hardware-robotics-interfacing.md){ .md-button .md-button--primary }
