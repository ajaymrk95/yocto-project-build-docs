---
title: "Applying the Patch via Yocto"
---

# Applying the PREEMPT_RT Patch via Yocto

<span class="phase-label">Phase 3 · Stage 2</span>

!!! info "Outline Page"
    This page is an outline only.

---

## Outline

### Identifying the Kernel Version

- <!-- TODO: How to find current kernel version in your build -->
- <!-- TODO: Matching patch version to kernel version -->

### Downloading the RT Patch

- <!-- TODO: Source: kernel.org/pub/linux/kernel/projects/rt/ -->
- <!-- TODO: Patch naming convention -->

### Creating a Kernel bbappend

- <!-- TODO: File location and naming -->
- <!-- TODO: Adding patch to SRC_URI -->
- <!-- TODO: Recipe structure -->

### Verifying Patch Application

- <!-- TODO: bitbake -c patch verification -->
- <!-- TODO: Checking patch logs -->

---

```mermaid
flowchart TD
    A["Check Kernel Version\nin meta-tegra"] --> B["Find Matching RT Patch\non kernel.org"]
    B --> C["Download .patch.xz"]
    C --> D["Create .bbappend\nin your layer"]
    D --> E["Add Patch to\nSRC_URI"]
    E --> F["bitbake -c patch\nVerify application"]
    F --> G{"Patch\nApplied?"}
    G -->|"Yes"| H["Proceed to\nKernel Config"]
    G -->|"No"| I["Debug Conflicts"]
    I --> D
```

---

[← Understanding PREEMPT_RT](01-understanding-preempt-rt.md){ .md-button }
[Kernel Configuration →](03-kernel-configuration.md){ .md-button .md-button--primary }
