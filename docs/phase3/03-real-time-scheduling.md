---
title: "Real-Time Scheduling Concepts"
description: "Detailed analysis of Linux scheduling classes (SCHED_OTHER, SCHED_FIFO, SCHED_RR), priority inheritance, priority inversion, and coding real-time applications."
---

# Real-Time Scheduling Concepts

<span class="phase-label">Phase 3 · Page 3 of 5</span>

!!! abstract "Page Goal"
    - Introduce Linux scheduling classes and contrast timesharing (`SCHED_OTHER`) with real-time (`SCHED_FIFO`, `SCHED_RR`) policies.
    - Detail the mechanics of Priority Inversion and how the `PREEMPT_RT` kernel resolves it using Priority Inheritance..

---

## 1. Linux Scheduling Policies

In standard Linux, CPU time is shared fairly among all running processes using the Completely Fair Scheduler (CFS). While this is optimal for desktop systems, real-time control requires strict prioritization. Linux provides three main scheduling policies:

### `SCHED_OTHER` (Standard Timesharing)
- The default scheduler policy for normal processes.
- Shares CPU resources fairly using dynamic priorities (modified by `nice` values).
- No guarantees on execution timing or latency bounds.

### `SCHED_FIFO` (First-In, First-Out Real-Time)
- A high-priority, real-time scheduling policy.
- Processes scheduled under `SCHED_FIFO` run until they block (e.g. waiting for I/O), yield the CPU, or are preempted by a higher-priority real-time process.
- **There is no timeslicing**. If a `SCHED_FIFO` process enters an infinite loop, it will lock the core, blocking all lower-priority processes.

### `SCHED_RR` (Round-Robin Real-Time)
- Similar to `SCHED_FIFO` but includes a time quantum (timeslice).
- When a process exceeds its time quantum, it is placed at the end of the priority queue, letting other processes of the same priority run.

### Real-Time Priority Range
Standard processes use nice values ranging from `-20` (highest) to `19` (lowest). Real-time scheduling policies use a distinct priority scale from **1 (lowest RT priority)** to **99 (highest RT priority)**.

```text
[ Nice Values: 19 ... -20 ] ----> [ RT Priority: 1 (Low) ... 99 (High) ]
   (SCHED_OTHER / CFS)                 (SCHED_FIFO / SCHED_RR)
```

## 2. How the Linux Kernel Manages Task Priorities Internally

While user-space interfaces like `nice` and POSIX scheduling configurations present simple scales, the Linux kernel manages task priorities internally using multiple variables within the `task_struct` structure. Understanding this internal mapping is crucial for real-time developers debugging scheduling behavior.

### Internal Priority Variables

The kernel evaluates priority using four key variables:
1. **`static_prio`**: The base priority of a non-real-time task, derived from its nice value. It is calculated as:
   `static_prio = 120 + nice`
   Since nice values range from `-20` to `19`, the internal `static_prio` range is **100 to 139** (with 100 being the highest priority).
2. **`rt_priority`**: The real-time priority configured by user-space applications (ranging from `1` to `99`).
3. **`normal_prio`**: The standard priority a task is expected to have based on its scheduling class, before any temporary runtime boosts:
   * For **real-time tasks**, it maps user-space priority to the kernel scale:
     `normal_prio = MAX_RT_PRIO - 1 - rt_priority`
     Where `MAX_RT_PRIO = 100`. Thus, a user-space RT priority of `99` (highest) maps to an internal `normal_prio` of `0`, and an RT priority of `1` (lowest) maps to `98`.
   * For **normal tasks**, it is simply equal to `static_prio` (range 100 to 139).
4. **`prio`**: The **effective priority** used by the scheduler to select the next running task. It is typically equal to `normal_prio`. However, if the task is temporarily boosted (for instance, via Priority Inheritance when a high-priority thread blocks on a lock it holds), `prio` is set to the higher priority of the waiting task without modifying the task's base `normal_prio` or `static_prio` values.

```text
Kernel Internal Priority Scale (0 to 139):
┌───────────────────────────────┬───────────────────────────────┐
│     Real-Time (0 - 99)        │       Normal (100 - 139)      │
├───────────────┬───────────────┼───────────────┬───────────────┤
│ User RT: 99   │ User RT: 1    │ Nice: -20     │ Nice: 19      │
│ Kernel: 0     │ Kernel: 98    │ Kernel: 100   │ Kernel: 139   │
└───────────────┴───────────────┴───────────────┴───────────────┘
  ▲                                                           ▲
  Highest Priority                                            Lowest Priority
```

### User-Space Visualization: `top` and `ps`

When using tools like `top` or `ps`, the priority columns do not display internal kernel variables directly. Instead, they transform them for readability:
* **In `top` (`PR` column)**:
  * For **normal processes**, `PR` is calculated as `prio - 100`, displaying values from `0` (high) to `39` (low) with `20` as the default.
  * For **real-time processes**, `PR` is displayed as `rt` or as a negative number (e.g., `-2` to `-100`), representing the high scheduling urgency below internal value 100.
* **In `ps` (`PRI` column)**:
  Depending on the command flags, `ps` displays priorities using custom offsets to prevent negative numbers or to align standard priority scales.

!!! info "Further Reading & Reference"
   For more details on how Linux manages kernel-space scheduling priorities and handles user-space reporting offsets, refer to the official Oracle Linux Blog guide: [Understanding process/thread priorities in Linux](https://blogs.oracle.com/linux/post/task-priority){:target="_blank"}.

---

## 3. Priority Inversion and Priority Inheritance

In real-time systems, shared resources (like hardware busses, buffers, or files) must be protected using mutual exclusion locks (mutexes). This can lead to a critical scheduling bug known as **Priority Inversion**.

### The Priority Inversion Scenario:
1. **Low Priority Thread (Task_L)** acquires a mutex to write to the CAN Bus controller.
2. **High Priority Thread (Task_H)** wakes up and attempts to write to the CAN Bus, blocking because Task_L holds the mutex.
3. **Medium Priority Thread (Task_M)** wakes up. Since Task_M does not need the CAN Bus, it preempts Task_L (as Task_M's priority is higher than Task_L's).
4. **Result**: Task_L is preempted and cannot finish its work to release the mutex. Task_H is blocked waiting for Task_L, which is blocked by Task_M. Task_H is indirectly preempted by Task_M, violating scheduling priorities.

```text
Time Line:
1. Task_L runs and locks Mutex
2. Task_H preempts Task_L and blocks on Mutex (starts waiting)
3. Task_M preempts Task_L (Task_M has higher priority than Task_L)
4. Task_H is blocked indefinitely by Task_M!
```

### The Solution: Priority Inheritance
The `PREEMPT_RT` patch resolves this by converting standard spinlocks and mutexes into **Priority Inheritance Mutexes**.

When a high-priority thread blocks waiting for a lock held by a low-priority thread, the kernel **temporarily raises the priority of the lock-holder** to match the priority of the waiting thread.
- In our scenario, Task_L's priority is raised to match Task_H.
- Task_L runs, preventing Task_M from preempting it.
- Once Task_L releases the mutex, its priority drops back to normal.
- Task_H immediately acquires the lock and runs, ensuring determinism.

---


[← Yocto PREEMPT_RT Integration](02-yocto-rt-integration.md){ .md-button }
[Next: OSADL Latency Validation →](04-osadl-latency-testing.md){ .md-button .md-button--primary }
