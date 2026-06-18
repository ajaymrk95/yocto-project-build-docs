---
title: "Real-Time Scheduling Concepts"
description: "Detailed analysis of Linux scheduling classes (SCHED_OTHER, SCHED_FIFO, SCHED_RR), priority inheritance, priority inversion, and coding real-time applications."
---

# Real-Time Scheduling Concepts

<span class="phase-label">Phase 3 · Page 3 of 6</span>

!!! abstract "Page Goal"
    - Introduce Linux scheduling classes and contrast timesharing (`SCHED_OTHER`) with real-time (`SCHED_FIFO`, `SCHED_RR`) policies.
    - Detail the mechanics of Priority Inversion and how the `PREEMPT_RT` kernel resolves it using Priority Inheritance.
    - Provide C++ code reference blocks showing how to configure real-time priorities natively.

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

---

## 2. Priority Inversion and Priority Inheritance

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

## 3. Programming Real-Time Applications in C/C++

To run a process under real-time scheduling constraints, you must configure the scheduling parameters using the POSIX library (`<sched.h>`).

### Example: Setting `SCHED_FIFO` and Priority 80
This C++ code block demonstrates how to elevate the current thread's priority:

```cpp
#include <iostream>
#include <sched.h>
#include <pthread.h>
#include <cstring>

int configure_realtime_priority(int priority) {
    struct sched_param param;
    std::memset(&param, 0, sizeof(param));
    
    // Set priority value (range 1 to 99)
    param.sched_priority = priority;

    // Apply FIFO scheduling policy to the current thread
    int result = pthread_setschedparam(pthread_self(), SCHED_FIFO, &param);
    if (result != 0) {
        std::cerr << "Error: Failed to set RT priority. Code: " << result << std::endl;
        std::cerr << "Note: Ensure the program is executed with root/sudo privileges." << std::endl;
        return -1;
    }

    std::cout << "Success: Thread configured under SCHED_FIFO at priority " << priority << std::endl;
    return 0;
}

int main() {
    // Elevate current thread priority to 80
    configure_realtime_priority(80);
    
    // Core application loop here...
    return 0;
}
```

!!! important "Root Privileges Required"
    Process scheduler overrides require administrative access. If you run the compiled binary as a standard user, `pthread_setschedparam` will fail with an `EPERM` (Operation not permitted) error. The binary must be run with `sudo`.

---

[← Yocto PREEMPT_RT Integration](02-yocto-rt-integration.md){ .md-button }
[Next: OSADL Latency Validation →](04-osadl-latency-testing.md){ .md-button .md-button--primary }
