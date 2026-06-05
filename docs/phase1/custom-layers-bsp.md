---
title: "Custom Layers & BSP"
---

# Custom Layers & BSP Configuration

<span class="phase-label">Phase 1 · Stage 3</span>

!!! info "Outline Page"
    This page is an outline only.

---

## Outline

### Understanding Yocto Layers

- <!-- TODO: What are layers and why they matter -->
- <!-- TODO: Layer priority and dependency -->

### Required Layers for This Project

- <!-- TODO: meta-tegra — NVIDIA Tegra BSP -->
- <!-- TODO: meta-openembedded — additional recipes -->
- <!-- TODO: meta-ros — ROS Melodic/Noetic recipes -->


### Cloning & Adding Layers

- <!-- TODO: Git clone commands for each layer (Kirkstone branches) -->
- <!-- TODO: Verifying branch compatibility -->

### Updating bblayers.conf

- <!-- TODO: Adding layer paths -->
- <!-- TODO: Layer dependency resolution -->
- <!-- TODO: Example bblayers.conf snippet -->

---

## Layer Dependency Diagram

```mermaid
flowchart BT
    POKY["poky\nKirkstone"] --> META["meta"]
    POKY --> META_POKY["meta-poky"]
    POKY --> META_YOCTO["meta-yocto-bsp"]

    META_TEGRA["meta-tegra"] --> META
    META_OE["meta-openembedded"] --> META
    META_ROS["meta-ros"] --> META_OE
    META_ROS --> META

    BUILD["Your Build\nbblayers.conf"] --> POKY
    BUILD --> META_TEGRA
    BUILD --> META_CTI
    BUILD --> META_OE
    BUILD --> META_ROS
```

---

[← Yocto Quick Build](yocto-quick-build.md){ .md-button }
[Machine & Local Config →](machine-local-conf.md){ .md-button .md-button--primary }
