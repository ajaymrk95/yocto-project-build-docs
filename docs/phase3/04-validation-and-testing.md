---
title: "Validation & Testing"
---

# Validation & Testing

<span class="phase-label">Phase 3 · Stage 5</span>

!!! info "Outline Page"
    This page is an outline only.

---

## Outline

### Verifying RT Kernel is Running

- <!-- TODO: uname -a output showing PREEMPT_RT -->
- <!-- TODO: /proc/version check -->

### cyclictest — Latency Benchmarking

- <!-- TODO: Installing cyclictest -->
- <!-- TODO: Running cyclictest with appropriate parameters -->
- <!-- TODO: Interpreting results (min/avg/max latency) -->
- <!-- TODO: Acceptable thresholds for space applications -->

### Stress Testing

- <!-- TODO: Running under load (stress-ng) -->
- <!-- TODO: Measuring latency degradation under stress -->

### Results & Screenshots

- <!-- TODO: Add cyclictest output -->
- <!-- TODO: Add latency histogram -->

---

## Validation Pipeline

```mermaid
flowchart TD
    A["Boot RT Kernel"] --> B["Verify:\nuname -a"]
    B --> C{"Shows\nPREEMPT_RT?"}
    C -->|"Yes"| D["Run cyclictest\nIdle system"]
    C -->|"No"| E["Check Kernel Config\n& Rebuild"]
    E --> A
    D --> F["Record\nmin/avg/max latency"]
    F --> G["Run cyclictest\nUnder stress-ng load"]
    G --> H["Record Stressed\nLatency"]
    H --> I{"Latency\nAcceptable?"}
    I -->|"Yes"| J(["RT Validation Complete"])
    I -->|"No"| K["Tune Kernel Config\n& Retest"]
    K --> A
```

---

[← Kernel Configuration](03-kernel-configuration.md){ .md-button }
[Current Work →](../roadmap.md){ .md-button .md-button--primary }
