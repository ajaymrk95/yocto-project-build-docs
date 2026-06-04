---
title: "Flashing the DevKit"
---

# Flashing the DevKit

<span class="phase-label">Phase 1 · Stage 6</span>

!!! info "Outline Page"
    This page is an outline only.

---

## Outline

### Prerequisites

- <!-- TODO: USB-C cable, recovery mode jumper -->
- <!-- TODO: Host machine requirements -->

### Entering Recovery Mode

- <!-- TODO: DevKit recovery mode procedure -->

### Flash Process

- <!-- TODO: Step-by-step flash instructions -->
- <!-- TODO: Using NVIDIA flash script vs SDK Manager -->

### First Boot Verification

- <!-- TODO: Serial console connection -->
- <!-- TODO: Login and basic system check -->
- <!-- TODO: Verifying ROS packages -->
- <!-- TODO: Verifying GUI -->

### Screenshots & Expected Output

- <!-- TODO: Add terminal screenshots -->
- <!-- TODO: Add boot log examples -->

---

## Flash Workflow

```mermaid
flowchart TD
    A["Build Complete"] --> B["Put DevKit in\nRecovery Mode"]
    B --> C["Connect USB-C\nto Host"]
    C --> D{"Flash Method?"}
    D -->|"SDK Manager"| E["Launch SDK Manager\n& Select Image"]
    D -->|"CLI Script"| F["Run flash.sh\nwith Parameters"]
    E --> G["Flash in Progress"]
    F --> G
    G --> H{"Flash\nSuccessful?"}
    H -->|"Yes"| I["Reboot DevKit"]
    H -->|"No"| J["Check USB Connection\n& Recovery Mode"]
    J --> B
    I --> K["Serial Console\nFirst Boot"]
    K --> L["Verify System\n& Packages"]
```

---

[← Build Process](build-process.md){ .md-button }
[Naming & Gotchas →](naming-gotchas.md){ .md-button .md-button--primary }
