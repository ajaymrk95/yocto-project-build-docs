---
title: "Build Process"
---

# Build Process

<span class="phase-label">Phase 1 · Stage 5</span>

!!! info "Outline Page"
    This page is an outline only.

---

## Outline

### Initializing the Build

- <!-- TODO: source oe-init-build-env -->
- <!-- TODO: Build directory structure -->

### Running bitbake

- <!-- TODO: bitbake command for target image -->
- <!-- TODO: Expected build duration -->
- <!-- TODO: Monitoring build progress -->

### Build Stages Breakdown

- <!-- TODO: Fetching (do_fetch) -->
- <!-- TODO: Unpacking (do_unpack) -->
- <!-- TODO: Patching (do_patch) -->
- <!-- TODO: Configuring (do_configure) -->
- <!-- TODO: Compiling (do_compile) -->
- <!-- TODO: Installing (do_install) -->
- <!-- TODO: Packaging (do_package) -->
- <!-- TODO: Image creation (do_image) -->

### Build Artifacts

- <!-- TODO: Location: tmp/deploy/images/<MACHINE>/ -->
- <!-- TODO: Key files: ext4, dtb, kernel image, modules -->
- <!-- TODO: System image size validation (< 5 GB target) -->

---

## bitbake Build Pipeline

```mermaid
flowchart LR
    FETCH["do_fetch\nDownload Sources"] --> UNPACK["do_unpack"]
    UNPACK --> PATCH["do_patch"]
    PATCH --> CONFIG["do_configure"]
    CONFIG --> COMPILE["do_compile"]
    COMPILE --> INSTALL["do_install"]
    INSTALL --> PACKAGE["do_package"]
    PACKAGE --> IMAGE["do_image\nCreate rootfs"]
    IMAGE --> DEPLOY["do_deploy\nFinal Artifacts"]
```

---

[← Machine & Local Config](machine-local-conf.md){ .md-button }
[Flashing the DevKit →](flashing-devkit.md){ .md-button .md-button--primary }
