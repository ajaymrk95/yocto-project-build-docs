---
title: "Phase 3 — PREEMPT_RT Kernel Patch"
description: "Adding the PREEMPT_RT real-time patch to the Linux kernel via the Yocto build system."
---

# Phase 3 — PREEMPT_RT Kernel Patch

<span class="phase-label">Kernel · Week 4</span>

!!! abstract "Goal"
    Apply the PREEMPT_RT patch to the Linux kernel through the Yocto build system, enabling fully preemptible (deterministic) real-time scheduling. This is critical for time-sensitive space payload operations where worst-case latency must be bounded.

---

## Phase Process Overview

```mermaid
flowchart TD
    START(["Start\nElroy Build Working"]) --> FIND

    subgraph S1["Stage 1 — Identify the Patch"]
        FIND["Identify Kernel Version\nin Current Build"]
        FIND --> LOCATE["Locate Matching\nPREEMPT_RT Patch"]
        LOCATE --> DOWNLOAD["Download Patch\nfrom kernel.org"]
    end

    subgraph S2["Stage 2 — Integrate via Yocto"]
        DOWNLOAD --> RECIPE["Create/Modify Kernel\nRecipe .bbappend"]
        RECIPE --> SRC_URI["Add Patch to\nSRC_URI"]
        SRC_URI --> DEFCONFIG["Update Kernel\ndefconfig"]
    end

    subgraph S3["Stage 3 — Configure Kernel"]
        DEFCONFIG --> MENUCONFIG["menuconfig\nSet PREEMPT_RT"]
        MENUCONFIG --> FLAGS["Set Kernel Config\nFlags"]
        FLAGS --> VERIFY_CFG["Verify Configuration"]
    end

    subgraph S4["Stage 4 — Build & Flash"]
        VERIFY_CFG --> BUILD["bitbake\nRT-Patched Image"]
        BUILD --> FLASH["Flash to Elroy"]
    end

    subgraph S5["Stage 5 — Validate"]
        FLASH --> BOOT["Boot RT Kernel"]
        BOOT --> UNAME["Verify with\nuname -a"]
        UNAME --> CYCLICTEST["Run cyclictest\nLatency Validation"]
    end

    CYCLICTEST --> DONE(["Phase 3 Complete"])
```

---

## Important Links

| Resource | Link |
|---|---|
| PREEMPT_RT Patch Archive | <!-- TODO: https://wiki.linuxfoundation.org/realtime/ --> |
| Kernel.org RT Patches | <!-- TODO: Add link --> |
| Yocto Kernel Dev Manual | <!-- TODO: Add link --> |
| cyclictest Documentation | <!-- TODO: Add link --> |

---

## Subpages

| Page | Description |
|---|---|
| [Understanding PREEMPT_RT](01-understanding-preempt-rt.md) | What PREEMPT_RT is and why it matters for space |
| [Applying the Patch via Yocto](02-applying-the-patch.md) | Kernel recipe modification, SRC_URI, bbappend |
| [Kernel Configuration](03-kernel-configuration.md) | menuconfig, defconfig, RT-specific flags |
| [Validation & Testing](04-validation-and-testing.md) | cyclictest, latency profiling, verification |

---

[← Phase 2](../phase2/index.md){ .md-button }
[Current Work →](../roadmap.md){ .md-button .md-button--primary }
