---
title: "Hardware Redundancy Concepts"
---

# Hardware Redundancy Concepts

<span class="phase-label">Phase 0 · Research</span>

!!! info "Outline Page"
    This page is an outline only. Content will be populated with concepts, diagrams, and images.

---

## Outline

### ECC (Error-Correcting Code) Memory

- <!-- TODO: What is ECC and why it matters in space -->
- <!-- TODO: TX2i ECC support details -->

### Watchdog Timers

- <!-- TODO: Hardware watchdog concepts -->
- <!-- TODO: Role in boot recovery -->

### Triple Modular Redundancy (TMR)

- <!-- TODO: TMR architecture overview -->
- <!-- TODO: Voting mechanisms -->
- <!-- TODO: Application at bootloader level -->

### Radiation-Hardened vs Radiation-Tolerant Components

- <!-- TODO: TX2i's position on this spectrum -->
- <!-- TODO: COTS vs rad-hard tradeoffs -->

---

## Hardware Redundancy Architecture

```mermaid
flowchart LR
    subgraph TMR["TMR Voting"]
        M1["Module A"] --> V{"Voter"}
        M2["Module B"] --> V
        M3["Module C"] --> V
        V --> OUT["Correct Output"]
    end

    subgraph ECC["ECC Memory"]
        DATA["Data Word"] --> ENC["ECC Encode"]
        ENC --> MEM["Memory + Parity"]
        MEM --> DEC["ECC Decode"]
        DEC --> CORR["Corrected Data"]
    end

    subgraph WDT["Watchdog"]
        CPU["CPU"] -->|"Kick"| WDTIMER["Watchdog Timer"]
        WDTIMER -->|"Timeout"| RST["System Reset"]
    end
```

---

[← Research Papers](papers.md){ .md-button }
[Software Redundancy →](software-redundancy.md){ .md-button .md-button--primary }
