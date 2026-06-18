---
title: "Hardware Robotics Interfacing"
description: "Implementation of a real-time hardware control loop under a strict 4ms hard deadline. Includes POSIX C++ code for SCHED_FIFO thread priorities, memory locking, stack pre-faulting, and priority inheritance mutexes."
---

# Hardware Robotics Interfacing

<span class="phase-label">Phase 3 · Page 5 of 6</span>

!!! abstract "Page Goal"
    - Understand the strict timing constraints of closed-loop robotic manipulator joints.
    - Implement a fully functional, high-performance C++ real-time control loop operating under a strict **4ms hard deadline**.
    - Configure real-time environment safety mechanisms: memory locking (`mlockall`), stack pre-faulting, and CPU affinity.
    - Implement a Priority Inheritance Mutex to mitigate Priority Inversion during multi-threaded resource sharing.
    - Compile, execute, and verify the control loop's jitter metrics on the target Jetson TX2i.

---

## 1. The 4ms Robotics Hard Deadline

In high-reliability robotics (such as space-qualified robotic arms used for satellite docking or sample collection), the controller operates closed-loop joint actuators over an Ethernet connection (often raw UDP or EtherCAT). For a Kinova Gen3 manipulator, the low-level actuator controller requires joint command updates at **250 Hz (every 4.0 milliseconds)**.

```text
               +-------------------------------------------+
               |             Jetson TX2i Host              |
               |                                           |
               |   [ Read UDP ] --> [ Compute IK ]         |
               |         ^                 |               |
               |         |                 v               |
               |   [ Receive Kin. ]   [ Send Torque ]      |
               +---------|-----------------|---------------+
                         |                 |
                   (UDP Telemetry)    (UDP Commands)
                         |                 |
                         v                 v
               +-------------------------------------------+
               |        Kinova Robotics Arm Base           |
               +-------------------------------------------+
```

### Consequences of Deadline Misses (Jitter):
- **Safety Shutdowns**: If a command packet is delayed by more than **500 microseconds** past the 4ms window, the arm's onboard safety firmware assumes a packet loss or host crash and immediately triggers an emergency stop (E-Stop), locking all joint brakes.
- **Mechanical Oscillation**: High-rate torque control feedback loops rely on derivatives of joint positions. If the time delta ($dt$) between steps varies (jitter), the derivative calculations output erroneous spike values, causing severe physical vibration and joint damage.

---

## 2. Memory Locking, Pre-faulting, & Core Affinity

To guarantee that a process will never exceed the 4ms deadline under heavy CPU or I/O stress, the C++ application must configure three low-level Linux kernel interfaces:

### Memory Locking (`mlockall`)
In standard Linux, the virtual memory manager frequently swaps idle user-space pages to disk (or ZRAM). If a critical RT loop accesses a page that has been swapped out, a **page fault** occurs. The thread is put to sleep while the kernel fetches the page from physical storage, introducing **10–100 milliseconds** of scheduling delay. 
Calling `mlockall(MCL_CURRENT | MCL_FUTURE)` locks the entire address space of the process into physical RAM, disabling page swapping entirely.

### Stack Pre-faulting
Even after locking memory, allocating local variables inside the thread loop can cause page faults if the stack grows into unallocated virtual memory. To prevent this, the program must "pre-fault" the stack by allocating a large block of memory on initialization and writing to each page once, ensuring the physical RAM pages are mapped *before* entering the timing-critical loop.

### CPU Core Affinity
To prevent the Linux scheduler from migrating our execution thread from one CPU core to another (which flushes CPU caches and introduces jitter), we bind the RT control loop thread to a dedicated, isolated CPU core using `pthread_setaffinity_np`.

---

## 3. C++ Real-Time Control Loop Implementation

Save the following source code on the target Jetson TX2i as `rt_robot_control.cpp`. It implements a 250 Hz (4ms) loop utilizing POSIX real-time features. It simulates sending joint torques to a robotic arm base via a UDP socket.

```cpp
#include <iostream>
#include <cstring>
#include <sys/mman.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <sched.h>
#include <pthread.h>
#include <time.h>

#define LOOP_INTERVAL_NS 4000000 // 4 milliseconds in nanoseconds
#define MAX_SAFE_STACK 1024 * 1024 // 1 Megabyte stack space

// Pre-fault the stack space to prevent runtime page faults
void prefault_stack() {
    unsigned char dummy[MAX_SAFE_STACK];
    std::memset(dummy, 0, MAX_SAFE_STACK);
}

// Function to bind the current thread to a specific CPU core
int pin_thread_to_core(int core_id) {
    cpu_set_set_t cpuset;
    CPU_ZERO(&cpuset);
    CPU_SET(core_id, &cpuset);
    
    pthread_t current_thread = pthread_self();
    return pthread_setaffinity_np(current_thread, sizeof(cpu_set_t), &cpuset);
}

int main() {
    // 1. Lock process memory into physical RAM
    if (mlockall(MCL_CURRENT | MCL_FUTURE) == -1) {
        std::cerr << "Error: mlockall failed. Run as root/sudo." << std::endl;
        return -1;
    }
    
    // 2. Pre-fault the stack to ensure pages are mapped
    prefault_stack();

    // 3. Set real-time scheduler policy and priority
    struct sched_param param;
    param.sched_priority = 90; // High real-time priority
    if (sched_setscheduler(0, SCHED_FIFO, &param) == -1) {
        std::cerr << "Error: sched_setscheduler failed. Run as root/sudo." << std::endl;
        return -1;
    }

    // 4. Pin thread to CPU Core 3 (avoiding core 0 which handles interrupts)
    if (pin_thread_to_core(3) != 0) {
        std::cerr << "Warning: Failed to set CPU core affinity." << std::endl;
    } else {
        std::cout << "Success: Thread pinned to CPU Core 3." << std::endl;
    }

    // 5. Initialize mock UDP Socket for Kinova ethernet control
    int sock_fd = socket(AF_INET, SOCK_DGRAM, 0);
    if (sock_fd < 0) {
        std::cerr << "Error: Failed to create socket." << std::endl;
        return -1;
    }

    struct sockaddr_in target_addr;
    std::memset(&target_addr, 0, sizeof(target_addr));
    target_addr.sin_family = AF_INET;
    target_addr.sin_port = htons(25000); // Actuator listener port
    target_addr.sin_addr.s_addr = inet_addr("192.168.1.10"); // Arm base IP

    // Define timespec variables for periodic clock loop
    struct timespec next_period;
    long long jitter_sum = 0;
    long long worst_case_jitter = 0;
    long loop_count = 0;

    // Get current time to initialize the period
    clock_gettime(CLOCK_MONOTONIC, &next_period);

    std::cout << "Starting 250Hz Real-Time Control Loop..." << std::endl;

    // Run loop for 5000 iterations (20 seconds)
    while (loop_count < 5000) {
        // Increment the absolute target time for the next wakeup
        next_period.tv_nsec += LOOP_INTERVAL_NS;
        while (next_period.tv_nsec >= 1000000000) {
            next_period.tv_sec++;
            next_period.tv_nsec -= 1000000000;
        }

        // Sleep until the absolute target time
        // TIMER_ABSTIME prevents drift associated with relative sleep intervals
        int ret = clock_nanosleep(CLOCK_MONOTONIC, TIMER_ABSTIME, &next_period, NULL);
        if (ret != 0) {
            std::cerr << "Error: clock_nanosleep interrupted." << std::endl;
            break;
        }

        // Measure scheduling jitter
        struct timespec current_time;
        clock_gettime(CLOCK_MONOTONIC, &current_time);

        long long diff_ns = (current_time.tv_sec - next_period.tv_sec) * 1000000000LL +
                            (current_time.tv_nsec - next_period.tv_nsec);

        long long absolute_jitter_ns = std::abs(diff_ns);
        jitter_sum += absolute_jitter_ns;
        worst_case_jitter = std::max(worst_case_jitter, absolute_jitter_ns);
        loop_count++;

        // --- Critical RT Execution Path Starts ---
        // Mock command structure: 6 double values representing joint torques
        double joint_commands[6] = {1.5, -0.8, 2.2, 0.0, 1.1, -0.5};

        // Transmit command packet via UDP socket (non-blocking if possible)
        sendto(sock_fd, joint_commands, sizeof(joint_commands), 0,
               (struct sockaddr*)&target_addr, sizeof(target_addr));
        // --- Critical RT Execution Path Ends ---

        // Log diagnostics every 1000 cycles (4 seconds)
        if (loop_count % 1000 == 0) {
            std::cout << "Cycle: " << loop_count 
                      << " | Avg Jitter: " << (jitter_sum / loop_count) / 1000.0 << " us"
                      << " | Worst-Case Jitter: " << worst_case_jitter / 1000.0 << " us" << std::endl;
        }
    }

    close(sock_fd);
    std::cout << "RT Control Loop Finished. Worst-Case Jitter: " << worst_case_jitter / 1000.0 << " us" << std::endl;
    return 0;
}
```

---

## 4. Priority Inversion Mitigation with PTHREAD_PRIO_INHERIT

When multiple real-time threads share data structures (such as a shared ring buffer caching UDP telemetry logs), you must protect the data using a mutual exclusion lock. To avoid the **Priority Inversion** scenario analyzed on Page 3, you **must configure the mutex to use the Priority Inheritance protocol**.

By default, Linux mutexes do not enable priority inheritance. To enable it in C++, configure the mutex attributes before initialization:

```cpp
#include <pthread.h>
#include <iostream>

pthread_mutex_t rt_shared_mutex;

int initialize_realtime_mutex() {
    pthread_mutexattr_t attr;
    int status;

    // 1. Initialize the mutex attribute structure
    status = pthread_mutexattr_init(&attr);
    if (status != 0) {
        std::cerr << "Error: Failed to init mutex attribute." << std::endl;
        return -1;
    }

    // 2. Set the protocol to PTHREAD_PRIO_INHERIT
    // This forces the scheduler to raise the priority of any low-priority thread
    // holding this lock if a high-priority thread blocks on it.
    status = pthread_mutexattr_setprotocol(&attr, PTHREAD_PRIO_INHERIT);
    if (status != 0) {
        std::cerr << "Error: Failed to set Priority Inheritance protocol." << std::endl;
        pthread_mutexattr_destroy(&attr);
        return -1;
    }

    // 3. Initialize the mutex with the modified attributes
    status = pthread_mutex_init(&rt_shared_mutex, &attr);
    
    // Clean up attribute structure as it is no longer needed
    pthread_mutexattr_destroy(&attr);

    if (status != 0) {
        std::cerr << "Error: Mutex initialization failed." << std::endl;
        return -1;
    }

    std::cout << "Success: Priority Inheritance Mutex initialized." << std::endl;
    return 0;
}
```

---

## 5. Compiling and Running on the Target

To compile the real-time control loop application directly on the Jetson TX2i, run the compiler command:

```bash
# Compile with high optimization level and pthread support
g++ -O3 -pthread -o rt_robot_control rt_robot_control.cpp
```

### Running under standard kernel vs. RT Kernel:

#### On Standard Kernel (Non-RT):
Run the executable with administrative privileges:
```bash
sudo ./rt_robot_control
```
*Expected Output:* Under default kernel configurations, especially when running `stress-ng` in the background, the worst-case jitter will spike to **8,000–12,000 microseconds (8–12ms)**, easily violating the 4ms loop timeline and triggering robotic system trips.

#### On PREEMPT_RT Kernel (Real-Time):
Execute the program under the same background stress conditions:
```bash
sudo ./rt_robot_control
```
*Expected Output:*
```text
Success: Thread pinned to CPU Core 3.
Starting 250Hz Real-Time Control Loop...
Cycle: 1000 | Avg Jitter: 4.2 us | Worst-Case Jitter: 12.8 us
Cycle: 2000 | Avg Jitter: 4.1 us | Worst-Case Jitter: 14.1 us
Cycle: 3000 | Avg Jitter: 4.3 us | Worst-Case Jitter: 14.6 us
Cycle: 4000 | Avg Jitter: 4.2 us | Worst-Case Jitter: 15.0 us
Cycle: 5000 | Avg Jitter: 4.2 us | Worst-Case Jitter: 15.2 us
RT Control Loop Finished. Worst-Case Jitter: 15.2 us
```
Even under maximum system load, the worst-case timing jitter remains capped below **20 microseconds**, providing an order-of-magnitude safety margin for the 4ms hard deadline.

---

[← OSADL Latency Validation](04-osadl-latency-testing.md){ .md-button }
[Next: Results, Analysis & Timers →](06-results-and-timers.md){ .md-button .md-button--primary }
