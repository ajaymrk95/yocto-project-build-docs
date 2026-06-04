---
title: "Software Redundancy Concepts"
---

# Software Redundancy Concepts

<span class="phase-label">Phase 0 · Research</span>

!!! info "Outline Page"
    This page is an outline only. Content will be populated with concepts, diagrams, and images.

---

## Outline

### A/B Partition Redundancy

- <!-- TODO: Concept explanation -->
- <!-- TODO: How boot fallback works -->
- <!-- TODO: Implementation in embedded Linux -->

### RAM-Based Filesystem (tmpfs / initramfs)

- <!-- TODO: Why RAM filesystems protect against flash corruption -->
- <!-- TODO: tmpfs vs initramfs tradeoffs -->
- <!-- TODO: Overlay filesystem strategies -->

### Filesystem Integrity & Checksums

- <!-- TODO: dm-verity, fs checksums -->
- <!-- TODO: Read-only root filesystem patterns -->

### Software Watchdog & Health Monitoring

- <!-- TODO: systemd watchdog integration -->
- <!-- TODO: Custom health check services -->

---

## A/B Partition Redundancy Flow

```mermaid
flowchart TD
    BOOT["Bootloader Start"] --> CHECK{"Check Active\nPartition Flag"}
    CHECK -->|"A"| BOOT_A["Boot Partition A"]
    CHECK -->|"B"| BOOT_B["Boot Partition B"]

    BOOT_A --> VERIFY_A{"Verify Integrity"}
    VERIFY_A -->|"Pass"| RUN_A["Run System from A"]
    VERIFY_A -->|"Fail"| FALLBACK_B["Fallback to B"]

    BOOT_B --> VERIFY_B{"Verify Integrity"}
    VERIFY_B -->|"Pass"| RUN_B["Run System from B"]
    VERIFY_B -->|"Fail"| FALLBACK_A["Fallback to A"]

    FALLBACK_B --> BOOT_B
    FALLBACK_A --> BOOT_A
```

---

## RAM-Based Filesystem Architecture

```mermaid
flowchart LR
    subgraph TRAD["Traditional — Flash"]
        F1["eMMC / Flash"] --> F2["ext4 rootfs"]
        F2 --> F3["Read/Write\nOperations"]
        F3 -->|"Radiation\nBit Flip"| F4["Corrupted Data"]
    end

    subgraph PROT["RAM-Based — Protected"]
        R1["eMMC / Flash\nRead Only"] --> R2["Load to RAM\ntmpfs"]
        R2 --> R3["Read/Write\nin RAM"]
        R3 -->|"Radiation\nBit Flip"| R4["ECC Corrects\nin RAM"]
    end
```

---

[← Hardware Redundancy](hardware-redundancy.md){ .md-button }
[Radiation Mitigation →](radiation-mitigation.md){ .md-button .md-button--primary }
