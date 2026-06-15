---
title: "Warrior Branch — A Dead End"
---

# Warrior Branch — A Dead End

<span class="phase-label">Phase 2 · Page 3 of 7</span>

!!! danger "Dead End — Do Not Repeat"
    The approach documented on this page was abandoned due to fundamental incompatibilities. It is included here to prevent future developers from repeating this path.

---

## Outline

### Why Warrior Was Attempted

- <!-- TODO: Initial reasoning for choosing Warrior -->
- <!-- TODO: ConnectTech BSP availability on Warrior -->

### What Went Wrong

- <!-- TODO: Layer compatibility issues -->
- <!-- TODO: Deprecated APIs and recipes -->
- <!-- TODO: meta-tegra version mismatches -->

### Specific Errors Encountered

- <!-- TODO: Error logs and descriptions -->

### Lessons Learned

- <!-- TODO: Always verify layer branch compatibility first -->
- <!-- TODO: Kirkstone is the better supported target for this project -->

---

## Decision Flow

```mermaid
flowchart TD
    A["Need: Build for\nElroy Carrier"] --> B{"Which Yocto\nBranch?"}
    B -->|"Warrior\nolder"| C["Clone Warrior\nLayers"]
    B -->|"Kirkstone\ncurrent"| D["Continue with\nKirkstone"]
    C --> E["Layer Version\nMismatches"]
    E --> F["Deprecated\nAPIs"]
    F --> G["Build Failures"]
    G --> H["Abandoned"]
    H -->|"Switch to"| D
```

---

[← Device Trees & Configuration](02-device-trees-and-configuration.md){ .md-button }
[Next: Build Artifact Modification →](04-build-artifact-modification.md){ .md-button .md-button--primary }
