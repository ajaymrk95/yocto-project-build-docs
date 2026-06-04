---
title: "Radiation Effects & Mitigation"
---

# Radiation Effects & Mitigation

<span class="phase-label">Phase 0 · Research</span>

!!! info "Outline Page"
    This page is an outline only. Content will be populated with concepts, diagrams, and images.

---

## Outline

### The LEO Radiation Environment

- <!-- TODO: Types of radiation in LEO -->
- <!-- TODO: South Atlantic Anomaly -->
- <!-- TODO: Solar particle events -->

### Single Event Effects (SEE)

- <!-- TODO: Single Event Upset (SEU) -->
- <!-- TODO: Multi-Bit Upset (MBU) -->
- <!-- TODO: Single Event Latchup (SEL) -->
- <!-- TODO: Single Event Functional Interrupt (SEFI) -->

### Total Ionizing Dose (TID)

- <!-- TODO: Cumulative radiation damage -->
- <!-- TODO: TX2i TID tolerance -->

### Mitigation Strategies Summary

- <!-- TODO: Hardware mitigations (ECC, TMR, watchdog) -->
- <!-- TODO: Software mitigations (A/B partition, RAM FS, checksums) -->
- <!-- TODO: System-level mitigations (power cycling, safe mode) -->

---

## Radiation Effect Classification

```mermaid
flowchart TD
    RAD["Radiation Event"] --> SEE{"Single Event\nEffect"}
    RAD --> TID["Total Ionizing\nDose"]

    SEE --> SEU["SEU\nBit Flip in Memory"]
    SEE --> MBU["MBU\nMulti-Bit Upset"]
    SEE --> SEL["SEL\nLatchup — HW Damage"]
    SEE --> SEFI["SEFI\nFunctional Interrupt"]

    SEU --> MIT_ECC["Mitigation: ECC"]
    MBU --> MIT_TMR["Mitigation: TMR"]
    SEL --> MIT_WDT["Mitigation: Power Cycle"]
    SEFI --> MIT_RST["Mitigation: Watchdog Reset"]

    TID --> MIT_SHIELD["Mitigation: Shielding"]
    TID --> MIT_DERATING["Mitigation: Component Derating"]
```

---

[← Software Redundancy](software-redundancy.md){ .md-button }
[Phase 1 — Minimal Build →](../phase1/index.md){ .md-button .md-button--primary }
