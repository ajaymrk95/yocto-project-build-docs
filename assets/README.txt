Data Logs Explained:All testing done on a RT patched Kernel 4.9.337-rt197


Logs 642-647 were not done properly - day1 to study the process (June 3 2026)

June 4 2026:

Logs		Code-Type	Scheduler	Flags			Stress
actuatorlog648	Non-RT (v2)	SCHED_OTHER	Default			None 
actuatorlog649	Non-RT (v2)	SCHED_OTHER	nice -n -20 chrt-o	None
actuatorlog650	Non-RT (v2)	SCHED_FIFO	chrt -f 49		None
actuatorlog652	Non-RT (v2)	SCHED_OTHER	nice -n -20 chrt -o	Active
actuatorlog653	Non-RT (v2)	SCHED_FIFO	chrt -f 49		Active
actuatorlog654	RT-Friendly	SCHED_FIFO	Limit: 3ms		(Failed due to tight 0.38ms window)
actuatorlog655	RT-Friendly	SCHED_OTHER	nice -n 20		None
actuatorlog656	RT-Friendly	SCHED_OTHER	nice -n -20 chrt -o	Active
actuatorlog657	RT-Friendly	SCHED_FIFO	chrt -f 49 		Active


actuatorlog648 - run script ( non rt) no flags

actuatorlog649 - No RT Code , Normal Nice Value Priority Setting and No System Loads(no stress-ng running).

actuatorlog650 - No RT Code , RT Priority Setting (SCHED_FIFO) and No System Loads(no stress-ng running).

actuator651 - Reran 650 - no change as 650

actuatorlog652 - No RT Code , Normal Nice Value Priority Setting (SCHED_OTHER) and Stress-NG System Loads as specified in process.

actuatorlog653 - No RT Code , RT Priority Setting (SCHED_FIFO)  and Stress-NG System Loads as specified in process.

actuatorlog654 - RT Friendly Code but set time limit as 3ms - Ethernet Speeds took 2.62 ms so 0.38ms window was too tight to finish all communications. needed to copy the logs to copy to the global buffer.

actuatorlog655 - RT Friendly Code +  Normal Nice Value Priority Setting and No System Loads(no stress-ng running).

actuatorlog655 - RT Friendly Code +  Normal Nice Value Priority Setting and No System Loads(no stress-ng running).

actuatorlog656 - RT Friendly Code +  Normal Nice Value Priority Setting and SCHED_OTHER + and Stress-NG System Loads as specified in process.

actuatorlog657 - RT Friendly Code +  RT Priority 49 -f -  Setting (SCHED_FIFO) and Stress-NG System Loads as specified in process.





Testing Process and Theory Behind Tests:
Stage 1
1.The Script was NOT MODIFIED apart from changing the Manual IPs and Actuator ID.
We configured first IP in the code to 192.168.100.10/24 - The Jetson TX2i IP via nmcli
Configured the Actuator IP to 192.168.100.11/24.
g++ -o eth main_eth_v2.cpp -ldl -std=c++11 - compiling the code.

Run jetson_clocks so we dont face any throttle downs or power losses. ( AI Suggested ) 

Use Nice Values - Maximize the User Space Priorities.
#Test 1 - Match the last Configuration - Run EthV2 Tool with the nice flags and as usually run on jetson ( Run with the nice values to get better timing)

command used earlier : 
sudo nice -n -20  su -c ./eth jetson 

Replaced this with : sudo nice -n -20 ./eth ( Reasons : We dont have other users on the System) - actuator649

#Test 3 - Mention the RT Patch - Priority and work

Most System Priorities use Nice Values :

-20 to 19 so value is calcualted as 120+ nice value to give net values of 100-139

Most Realtime Tasks are from 0-99 and priority numbers from 99 and high priorities tasks like watchdogs are set at 90-99

Most Hardware Drivers and Ethernet and Network Packets are high level Kernel Tasks and are assigned a priority of 50

We will assume 49 as a priority value to run the scripts and test the code without affecting a hardware task but still strong enough to have higher precedence than any user space stresstests.

command to be Tested:

chrt -f 49 ./eth - actuatorlog 650

Tested again to see if we can speed up with a higher priority : 
chrt -f 80 ./eth - high prio but still not as much as the watchdogs.

All Tests are set with an actuator Rotations Input Value of 2 - Provides nearly 80K Logs.




Stage 2
Now this is not indicative directly of the benefit of RT.

To really get an understanding of that we need to run stress tests in parallel to the Realtime Task to Simulate the Environment of a Priority Task having competing tasks for CPU, this serves to check if our RT (Realtime) Task gets Priority or not.

Open 2 parallel Terminals - Run the Stress Test Mechanism first and in other Term Run the Code.

stress-ng --cpu 2 --vm 2 --vm-bytes 128M --hdd1 --sock 1 --switch 2 --timeout 10m  ( Required Package of stress-ng which is an actively maintained stress test package which puts the system on loads as specified via flags)
We Checked htop and all six cores were at 100%.

Stress Test is to simulate multiple possible loads, we have 2 CPU workers, 2 Virtual Memory and RAM Stresses with 128MB , a Hard Disk EMMC Stressor, One Network Socket Stresser ( Our code uses the Ethernet so as to try to conflict with that.) 2 Context Switch Workers to simulate processes preempting in normal CPU actions and a Safety Timeout of 10 mins.

1. Run the Script with a nice value SCHED_OTHER to simulate a user space process
sudo nice -n -20 chrt -o 0 ./eth

2.Testing the Priority of 49 with SCHED_FIFO Scheduling.

sudo chrt -f 49 ./eth

This had given surprising results as both RT and NON RT Code observed Large Time Spikes, needing to further verify if there was a patch issue or code issue.

PATCH - This Employs the Linux 4.9.337-rt197 lts patch - verified via uname -a giving SMP PREEMPT RT showing patch was correct.
Code was verified and had multiple file writes and prints within the realtime loop, which causes buffer lock errors since a lower priority process may still lock up a kernel level resource like the Memory Buffer ( in an RT Kernel all kernel level tasks uses mutex locks so resource competition to lock up).

The RT kernel boosts the priority of the Kernel Lock Holder to 99 to prevent Priority Inversion.

Priority inversion is a scheduling bug in Real-Time Operating Systems (RTOS) where a high-priority task is blocked from executing by a lower-priority task. This happens when a low-priority task holds a shared resource (like a mutex a printf buffer write) needed by the high-priority task, while a medium-priority task interrupts the low-priority task.
Priority inversion typically involves three tasks with differing priorities: Low (L), Medium (M), and High (H)

Lock Acquisition: Task (L) locks a shared resource (e.g., a hardware peripheral or a data structure).

Preemption: While Task (L) is still holding the lock, Task (H) becomes ready, preempts (L), and attempts to use the same resource. Since the resource is locked, Task (H) blocks.

Inversion Occurs: Task (L) resumes execution to finish its task and release the lock. However, Task \(M\) (which does not even use the resource) becomes ready and preempts Task (L) because (M) outranks (L).

Unbounded Delay: Task (M) continues running for an unpredictable amount of time, preventing Task (L) from finishing its work, which means Task (H) remains blocked indefinitely. This can lead to missed deadlines or system failure.

Correction Mechanism which can cause delays - Priority Inheritance Protocol (PIP)If a low-priority task blocks a higher-priority task, the RTOS temporarily elevates the low-priority task's priority to match the highest-priority task waiting for the resource. Once the low-priority task finishes its critical section and releases the lock, its priority reverts to its original setting.



Stage 3: Modify the Original Code ( AI Assisted + Manual Code Reviewed to check original Actuator Spin Logic remains unchanged and is safe.)

Code 1 - main_eth_rt.cpp
Code 2  - main_eth_v2.cpp

1. Memory Locking vs. Page FaultsCode 1 (RT): Uses mlockall(MCL_CURRENT | MCL_FUTURE). This forces the operating system to lock the entire program into physical RAM. It guarantees the CPU will never freeze mid-loop due to a page fault or memory swap to disk.
Code 2 (Non-RT): Lacks memory locking. The OS can page out your code to the swap space at any moment, creating random millisecond-level stalls.

2. Clock Synchronization vs. Loose Sleeping 
Code 1 (RT): Uses clock_nanosleep(CLOCK_MONOTONIC, TIMER_ABSTIME, ...). It tracks a mathematically absolute deadline anchor. If a loop iteration runs slightly late, the next sleep window is automatically compressed to catch back up.
Code 2 (Non-RT): Uses sequential usleep(2800) and usleep(200). These are relative sleep statements. The total loop time equals 2800 mus + 200mus.

Every microsecond of execution jitter drifts the clock forward permanently, destroying the exact sampling interval.

3. RAM Logging Buffers vs. File I/O ChokingCode 1 (RT): Pre-allocates memory using global_log_buffer.reserve() before the real-time loops start. During the fast cycles, it only pushes data to RAM (.push_back()). It saves the actual text file to disk only after all communication loops are completely finished.Code 2 (Non-RT): Directly calls fprintf(fp_log, ...) inside the active loop. Writing to a physical disk or console buffer involves heavy kernel context switches and wait states. This introduces massive, unpredictable timing jitter that easily blows past your loop deadline.



Stage 4 Testing after the RTCODE:

g++ -o eth main_eth_rt.cpp -ldl -lrt -std=c++11 - compiling the code. (compile with realtime libs)

Open 2 parallel Terminals - Run the Stress Test Mechanism first and in other Term Run the Code.

stress-ng --cpu 2 --vm 2 --vm-bytes 128M --hdd1 --sock 1 --switch 2 --timeout 10m as before.
sudo nice -n -20 chrt -o 0 ./ethrt - actuator log 656

Testing the Prio with SCHED_FIFO

sudo chrt -f 49 ./ethrt - actuator log 657

Graphs verify hypothesis, as correctly scheduled RT Code gave very minimal spikes with majority of the sample having 4ms strict time. Other scheduled on Scheduled Other had a 6 ms and 7 ms spikes.



