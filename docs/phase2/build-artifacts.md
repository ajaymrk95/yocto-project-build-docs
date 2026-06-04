---
title: "Build Artifact Modification"
---

# Build Artifact Modification

<span class="phase-label">Phase 2 · Stage 3</span>

!!! info "Outline Page"
    This page is an outline only.

---

## Outline

### Locating Build Artifacts

- <!-- TODO: Path to ext4 rootfs from Yocto build -->
- <!-- TODO: Key files to identify -->

### Mounting the ext4 Filesystem

- <!-- TODO: Mount command -->
- <!-- TODO: Verifying mount contents -->

### Editing extlinux.conf

- <!-- TODO: Location: /boot/extlinux/extlinux.conf -->
- <!-- TODO: What needs to be hardcoded (partition UUID/path) -->
- <!-- TODO: Why this is necessary for Elroy -->

### Unmounting

- <!-- TODO: Clean unmount procedure -->

### Creating the Sparse Image

- <!-- TODO: What is a sparse image and why it's needed -->
- <!-- TODO: mksparse utility usage -->
- <!-- TODO: Output file: system.img -->

---

## Artifact Modification Pipeline

```mermaid
flowchart TD
    A["Yocto Build Output\next4 rootfs"] --> B["Mount ext4\nmount -o loop"]
    B --> C["Navigate to\n/boot/extlinux/"]
    C --> D["Edit extlinux.conf\nHardcode partition path"]
    D --> E["Verify Changes"]
    E --> F["Unmount"]
    F --> G["Convert to Sparse\nmksparse"]
    G --> H["system.img\nReady for Flash"]
```

---

[← Warrior Dead End](warrior-dead-end.md){ .md-button }
[ConnectTech Scripts →](connecttech-scripts.md){ .md-button .md-button--primary }
