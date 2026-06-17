# Phase 2 — Editorial Guide & Content Brief

> A writer's blueprint for authoring every page in Phase 2.
> Each section below tells you **what to write**, **why it matters**, and **which Phase 1 pattern it mirrors**.

---

## The Phase 2 Story (Narrative Arc)

Before writing any page, internalize this arc — it's the backbone of Phase 2:

```
Phase 1 gave you a working image on a development board.
Phase 2 is about taking that image into the real world.

The DevKit is a lab tool. The Elroy is mission hardware.
The Yocto image doesn't change — the delivery pipeline does.
Along the way, you tried a shortcut (Warrior branch) and it failed.
That failure is documented honestly, because this is engineering, not marketing.
```

Every page should subtly reinforce this arc: **same image, different target, harder problem, honest documentation.**

---

## Phase 1 Patterns You Must Follow

Every Phase 2 page should include these structural elements, matching Phase 1 exactly:

| Element | Format | Example Reference |
|---|---|---|
| YAML front-matter | `title:` + `description:` | Every Phase 1 page |
| Phase label | `<span class="phase-label">Phase 2 · Page X of 7</span>` | [01-what-is-yocto.md](file:///c:/Users/LENOVO/OneDrive/Desktop/MKDocs/docs/phase1/01-what-is-yocto.md#L8) |
| Page Goal | `!!! abstract "Page Goal"` — one sentence, outcome-focused | [03-host-setup.md](file:///c:/Users/LENOVO/OneDrive/Desktop/MKDocs/docs/phase1/03-host-setup.md#L10-L11) |
| Page Process Overview | `mermaid flowchart LR` — 3–6 nodes, this page's steps only | [06-adding-layers.md](file:///c:/Users/LENOVO/OneDrive/Desktop/MKDocs/docs/phase1/06-adding-layers.md#L18-L24) |
| Concept before command | Explain *what* and *why* before showing *how* | [01-what-is-yocto.md](file:///c:/Users/LENOVO/OneDrive/Desktop/MKDocs/docs/phase1/01-what-is-yocto.md#L27-L31) |
| Tables for structured data | Components, comparisons, artifacts, errors | [08-build-process.md](file:///c:/Users/LENOVO/OneDrive/Desktop/MKDocs/docs/phase1/08-build-process.md#L75-L88) |
| Code blocks with `# comments` | Every command block has inline context | [03-host-setup.md](file:///c:/Users/LENOVO/OneDrive/Desktop/MKDocs/docs/phase1/03-host-setup.md#L68-L71) |
| Admonitions | `!!! note`, `!!! warning`, `!!! tip`, `!!! danger` | Used liberally across all Phase 1 pages |
| Directory trees | ` ```text ` fenced blocks | [09-navigating-output-and-flashing.md](file:///c:/Users/LENOVO/OneDrive/Desktop/MKDocs/docs/phase1/09-navigating-output-and-flashing.md#L47-L58) |
| Troubleshooting table | `Problem \| Likely Cause \| Fix` | [09-navigating-output-and-flashing.md](file:///c:/Users/LENOVO/OneDrive/Desktop/MKDocs/docs/phase1/09-navigating-output-and-flashing.md#L235-L241) |
| Navigation footer | `← Previous` + `Next →` buttons | Every Phase 1 page |

---

## Page-by-Page Content Brief

---

### `index.md` — Phase 2 Overview

**Role in the arc**: The landing page. Sets context, shows the big picture, links everything.
**Current state**: ~60% done. Flowchart and page table exist. Two sections are empty.
**Target length**: ~120–140 lines.

---

#### Section: "Why a custom carrier board?"

> **What to write**: Explain why you can't just ship the DevKit. The DevKit is a bench tool — large, fragile, full of debug headers and ports you don't need. The Elroy is a deployment-grade carrier designed for embedded/rugged/space applications. Smaller form factor, fewer but purpose-built interfaces, designed for the environment the system will actually operate in.
>
> **Tone**: Engineering rationale, not sales pitch. You're justifying a hardware decision to a fellow engineer.
>
> **Include**:
> - 2–3 bullet points on DevKit limitations for deployment
> - 2–3 bullet points on why the Elroy solves those
> - An `!!! info` admonition noting that the TX2i SoM itself doesn't change — only the carrier board

---

#### Section: "Adapting from the Yocto Perspective"

> **What to write**: A short conceptual bridge. Explain that at the Yocto layer, almost nothing changes — same recipes, same layers, same `bitbake` command, same image. What changes is the *post-build pipeline*: the DTB that describes the hardware, the CFG files that configure the flash layout, and the flash scripts that write to the board. This is the key insight of Phase 2.
>
> **Include**:
> - A small table: `What stays the same | What changes`
> - Keep this section tight — 8–12 lines max. It's a preview, not the detail.

---

#### Section: Important Links & Repos

> **What to write**: A reference table similar to Phase 1's link tables. List the ConnectTech BSP repo, ConnectTech product page for the Elroy, OE4T wiki section on carrier board adaptation, NVIDIA L4T documentation, and any other key references you used during Phase 2.
>
> **Format**: Use the same `| Resource | Link |` table format as [Phase 1 index.md](file:///c:/Users/LENOVO/OneDrive/Desktop/MKDocs/docs/phase1/index.md#L74-L100).

---

#### Section: Pages table

> **Fix**: Add the `#` numbering column to match Phase 1's format: `| # | Page | Description |`
> See [Phase 1 index.md lines 105–115](file:///c:/Users/LENOVO/OneDrive/Desktop/MKDocs/docs/phase1/index.md#L103-L115) for the exact format.

---

---

### `01-hardware-comparison.md` — Elroy vs DevKit

**Role in the arc**: Ground the reader in the physical reality. Before any Yocto work, understand *what's different about the hardware*.
**Current state**: Outline only (34 lines).
**Target length**: ~130–160 lines.

---

#### Section 1: TX2 Development Kit Overview

> **What to write**: Describe the DevKit as the reference/evaluation platform from NVIDIA. What comes in the box. Key connectors and interfaces (USB 3.0, HDMI, Ethernet, GPIO 40-pin header, recovery micro-USB, serial debug header). Physical dimensions and form factor. Mention that it's designed for desk use with active cooling fan.
>
> **Include**:
> - A bullet list of key connectors
> - An `!!! note` mentioning it is NVIDIA's reference design — all NVIDIA documentation assumes this carrier

---

#### Section 2: Connect Tech Elroy Carrier Board Overview

> **What to write**: Describe the Elroy. Form factor (compact, embedded-grade). Target environments (rugged, space, industrial). What interfaces it exposes vs what the DevKit has. Mention the reduced connector set — this is intentional, not a limitation. Link to the ConnectTech product page.
>
> **Include**:
> - A bullet list of key interfaces
> - An `!!! tip` noting ConnectTech's documentation and BSP support resources

---

#### Section 3: Side-by-Side Comparison

> **What to write**: A direct comparison table.
>
> **Format**:
> ```
> | Feature          | TX2 DevKit                  | Elroy Carrier              |
> |------------------|-----------------------------|----------------------------|
> | Form Factor      | ...                         | ...                        |
> | USB Ports        | ...                         | ...                        |
> | Display Output   | ...                         | ...                        |
> | Ethernet         | ...                         | ...                        |
> | Cooling          | ...                         | ...                        |
> | Target Use Case  | Development / Evaluation    | Deployment / Mission       |
> ```

---

#### Section 4: What Changes for the Build?

> **What to write**: The punchline of this page. The SoM is identical. The Yocto image is identical. What changes: the **DTB** (device tree — describes the carrier's peripherals), the **CFG files** (flash partition layout), and the **flash tooling** (ConnectTech scripts instead of NVIDIA's `doflash.sh`). This paragraph sets up Pages 2–7.
>
> **Include**:
> - An `!!! abstract` or `!!! info` admonition summarizing: "Same SoM + different carrier = different DTB, CFG, and flash pipeline."

---

---

### `02-device-trees-and-configuration.md` — DTBs & CFG Files

**Role in the arc**: The conceptual foundation. The reader needs to understand DTBs and CFG files before they can modify artifacts or configure flash scripts.
**Current state**: Outline only (54 lines). Has a good DTB flow diagram.
**Target length**: ~160–200 lines.

---

#### Section 1: What is a Device Tree?

> **What to write**: A clear, jargon-light explanation. The Linux kernel is built to be hardware-agnostic. It doesn't hardcode which pins are GPIO, which bus is I2C, or where the Ethernet controller sits in memory. Instead, a *Device Tree* is passed to the kernel at boot — a structured data file that says "here is your hardware." This makes the same kernel binary work on many different boards.
>
> **Tone**: Teach this like the reader has never seen a DTB. Phase 1 didn't cover this in depth, so this is new territory.

---

#### Section 2: DTS vs DTB vs DTSI

> **What to write**: Define the three file types clearly.
>
> **Format as a table**:
> ```
> | File Type | Extension | Description                                      |
> |-----------|-----------|--------------------------------------------------|
> | DTS       | .dts      | Device Tree Source — human-readable, editable     |
> | DTSI      | .dtsi     | Device Tree Include — shared fragments, imported  |
> | DTB       | .dtb      | Device Tree Binary — compiled, kernel-readable    |
> ```
>
> **Include**: A note that you edit `.dts`, compile with `dtc`, and the kernel loads `.dtb`.

---

#### Section 3: Why DTBs Matter for Custom Hardware

> **What to write**: Connect the concept to the Phase 2 problem. The DevKit carrier has certain peripherals wired to certain pins. The Elroy has different peripherals on different pins. The kernel is the same — but the DTB must describe the *carrier's* hardware. Wrong DTB = kernel can't find peripherals, or worse, drives pins incorrectly.
>
> **Include**:
> - An `!!! warning` about the consequences of using the wrong DTB (peripherals not working, potential hardware damage from incorrect pin configuration)

---

#### Section 4: CFG Files in the NVIDIA Flash Process

> **What to write**: Explain CFG files as the *flash-time* counterpart to DTBs. While DTBs describe hardware to the kernel at *boot*, CFG files describe the storage layout to the flash tool at *flash time*. They define partition tables, memory timings, and bootloader chain configuration. They live in the `Linux_for_Tegra/bootloader/` directory.
>
> **Include**:
> - A bullet list of what CFG files control (partition layout, memory config, bootloader binaries)
> - Note which CFG files are carrier-specific vs SoM-specific

---

#### Section 5: Finding the Right DTB for Elroy

> **What to write**: How you actually get the correct DTB. ConnectTech provides board-specific DTBs in their BSP package. You can also decompile and inspect a DTB using the `dtc` (Device Tree Compiler) tool to understand what it describes.
>
> **Include**:
> - The `dtc` decompile command: `dtc -I dtb -O dts -o output.dts input.dtb`
> - An `!!! tip` about using `dtc` to compare the DevKit DTB vs the Elroy DTB

---

#### Keep: DTB Flow Diagram

> The existing mermaid diagram (DTS → dtc compile → DTB → Bootloader → Kernel → Hardware) is solid. Keep it.

---

---

### `03-warrior-branch-dead-end.md` — The Wrong Turn

**Role in the arc**: The most honest page in the documentation. This is where you document a real failure — not to criticize, but to save the next person days of wasted work.
**Current state**: Outline only (56 lines). Has good decision flow diagram.
**Target length**: ~130–170 lines.

> [!TIP]
> This page is your most valuable contribution as a documentation author. Anyone can write "here's how to do X." Very few people document "here's how I failed at X and why." Write this with the reader you wish you had when you were stuck.

---

#### Section 1: Why Warrior Was Attempted

> **What to write**: The reasoning at the time. ConnectTech's BSP had a version targeting the Warrior branch. The initial assumption: matching the BSP's native branch would be the path of least resistance. It seemed logical — use the branch the vendor explicitly supports.
>
> **Tone**: No defensiveness. This was a reasonable decision with the information available at the time.

---

#### Section 2: What Went Wrong

> **What to write**: The specific technical failures. Layer version conflicts (meta-tegra Warrior vs meta-openembedded versions). Deprecated APIs in older OE-Core. Python 2 vs Python 3 recipe incompatibilities. Build failures that couldn't be fixed without rewriting vendor recipes.
>
> **Include**:
> - An `!!! danger` admonition at the top of this section reinforcing "Do Not Repeat"
> - A bullet list of the specific categories of failure

---

#### Section 3: Specific Errors Encountered

> **What to write**: Actual error messages (or faithful reconstructions). Show 2–3 representative build errors in code blocks. For each error, a 1–2 sentence explanation of what it means and why it's unfixable without changing branches.
>
> **Format**:
> ```bash
> ERROR: <actual error message>
> ```
> Followed by a brief explanation paragraph.
>
> **Include**: An `!!! note` that these errors may vary depending on exact layer versions, but the root cause (branch mismatch) is the same.

---

#### Section 4: Lessons Learned

> **What to write**: The takeaways, written as actionable rules for future work.
>
> **Format as an `!!! tip "Lessons Learned"` admonition with a numbered list**:
> 1. Always verify branch compatibility across *all* layers before committing to a branch
> 2. Prefer the most actively maintained and community-supported branch
> 3. Vendor BSP branch support ≠ full-stack compatibility
> 4. Document dead ends — they're as valuable as successes
>
> **Include**: A sentence connecting back to the arc: "This failure confirmed that Kirkstone was the correct foundation. The rest of Phase 2 proceeds on Kirkstone."

---

#### Keep: Decision Flow Diagram

> The existing mermaid diagram is good. Keep it.

---

---

### `04-build-artifact-modification.md` — Mount, Edit, Re-pack

**Role in the arc**: The first hands-on page of Phase 2. You're taking the Phase 1 build output and surgically modifying it for the new carrier.
**Current state**: Outline only (61 lines). Has good pipeline diagram.
**Target length**: ~160–200 lines.

---

#### Section 1: Locating Build Artifacts

> **What to write**: Where to find the ext4 rootfs from the Phase 1 build. Reference back to Phase 1 Page 9. Give the exact path: `build/tmp/deploy/images/jetson-tx2-devkit-tx2i/`. Identify the specific file you'll be modifying.
>
> **Include**: An `!!! note` referencing Phase 1 Page 9 for full artifact details.

---

#### Section 2: Mounting the ext4 Filesystem

> **What to write**: The mount command with explanation. Why `loop` mount. Where to mount it. How to verify the mount succeeded.
>
> **Include**:
> ```bash
> # Create a mount point
> sudo mkdir -p /mnt/yocto-rootfs
>
> # Mount the ext4 image
> sudo mount -o loop <image-name>.ext4 /mnt/yocto-rootfs
>
> # Verify contents
> ls /mnt/yocto-rootfs/
> ```
> - An `!!! warning` that you must use `sudo` and must unmount cleanly before creating the sparse image.

---

#### Section 3: Understanding extlinux.conf

> **What to write**: What `extlinux.conf` is — the bootloader configuration file that tells cboot which kernel image, which DTB, and which root partition to use. Where it lives inside the rootfs (`/boot/extlinux/extlinux.conf`). Show the default content as it appears after a Phase 1 build.
>
> **Include**: The full default `extlinux.conf` in a code block, with inline `# comments` explaining each line.

---

#### Section 4: Editing extlinux.conf for Elroy

> **What to write**: What specifically needs to change and why. The partition path or UUID that references the root filesystem may differ on the Elroy's storage layout. The DTB filename may change to the Elroy-specific DTB.
>
> **Include**:
> - A before/after diff block showing the exact changes
> - An `!!! warning` about getting the partition path exactly right — a wrong path means the kernel can't find the rootfs and you get a kernel panic

---

#### Section 5: Unmounting

> **What to write**: Clean unmount procedure. Emphasize that you must unmount before creating the sparse image or the image will be corrupted.
>
> **Include**:
> ```bash
> sudo umount /mnt/yocto-rootfs
> ```

---

#### Section 6: Creating the Sparse Image

> **What to write**: What a sparse image is (a compressed block-level representation of the ext4 filesystem, used for efficient eMMC writing). The `mksparse` utility. The full command. The output file name (`system.img`).
>
> **Include**:
> - The `mksparse` command in a code block
> - An `!!! info` explaining why sparse (saves flash time and reduces USB transfer size)
> - Note the output file name — it will be referenced in Pages 5 and 7

---

#### Keep: Artifact Modification Pipeline Diagram

> The existing mermaid diagram is good. Keep it.

---

---

### `05-connecttech-flash-scripts.md` — CTI BSP & Flash Environment

**Role in the arc**: Setting up the ConnectTech side of the tooling. This is the bridge between your Yocto image and the Elroy hardware.
**Current state**: Outline only (61 lines). Has good directory structure diagram.
**Target length**: ~150–180 lines.

---

#### Section 1: ConnectTech BSP Overview

> **What to write**: What ConnectTech provides in their BSP: carrier-specific DTBs, CFG files, flash scripts, and documentation. Which carrier boards are supported. Where to download it (repo URL or download page). Which version/release you used.
>
> **Include**:
> - Link to the ConnectTech BSP download/repo
> - An `!!! info` noting the BSP version and which L4T version it targets

---

#### Section 2: Installing the CTI BSP

> **What to write**: Step-by-step commands to download and install the BSP into your existing `Linux_for_Tegra` directory. Note any prerequisites (the NVIDIA L4T base must already be extracted).
>
> **Include**: Full command sequence in a code block with `# comments`.

---

#### Section 3: Linux_for_Tegra Directory Layout

> **What to write**: A directory tree showing the key directories after the CTI BSP is installed. Highlight where the CTI scripts, DTBs, CFG files, and `system.img` destination live.
>
> **Format**: Use a ` ```text ` fenced block, similar to [Phase 1 Page 9's artifact tree](file:///c:/Users/LENOVO/OneDrive/Desktop/MKDocs/docs/phase1/09-navigating-output-and-flashing.md#L47-L58) and [Phase 1 Page 8's build directory anatomy](file:///c:/Users/LENOVO/OneDrive/Desktop/MKDocs/docs/phase1/08-build-process.md#L99-L122).
>
> Use `← annotation` comments on key lines to call out important files.

---

#### Section 4: CTI Flash Script Configuration

> **What to write**: The script name, its key parameters, and how to select the Elroy carrier board. Board identification flags. Any environment variables or config files the script reads.
>
> **Include**:
> - The flash command with parameters in a code block
> - A table of key flags/parameters: `Flag | Purpose | Value for Elroy`

---

#### Section 5: Placing the Custom Image

> **What to write**: Copy `system.img` (from Page 4) into the correct directory (`bootloader/`). Place the Elroy-specific DTB and CFG files. Verify file placement.
>
> **Include**:
> - Copy commands in a code block
> - An `!!! warning` about overwriting the default `system.img` — suggest backing up the original first

---

#### Keep: Flash Directory Structure Diagram

> The existing mermaid diagram is good. Keep it.

---

---

### `06-machine-configuration.md` — Machine Conf & Flags

**Role in the arc**: The configuration decision point. Choosing the right machine target ties together the DTB, CFG, and flash script choices.
**Current state**: Outline only (55 lines). Has good decision flow diagram.
**Target length**: ~120–150 lines.

> [!IMPORTANT]
> Fix the phase label from `Phase 2 · Stage 4` → `Phase 2 · Page 6 of 7`

---

#### Section 1: Machine Configuration Files

> **What to write**: Where machine configs live (in `meta-tegra` and in NVIDIA's L4T package). What a machine `.conf` file contains: MACHINE name, kernel config, DTB filenames, partition layout references, bootloader settings. Show a snippet of a machine conf file with inline comments.
>
> **Include**: A short code block showing the structure of a `.conf` file with `# comments`.

---

#### Section 2: jetson-tx2i Flag vs Elroy Board Target

> **What to write**: Explain that `jetson-tx2i` is the NVIDIA-defined machine target for the TX2i SoM on the *DevKit* carrier. For the Elroy, ConnectTech provides either a different machine target or you override specific variables (DTB, CFG) while keeping the same base machine. Explain which approach you used and why.
>
> **Include**:
> - A comparison table: `Aspect | jetson-tx2i (DevKit) | Elroy Target`
> - An `!!! note` explaining which approach was taken in this project

---

#### Section 3: Getting the Correct CFG Files

> **What to write**: Where CFG files come from (ConnectTech BSP, NVIDIA L4T package). Which specific CFG files match the Elroy + TX2i combination. How to verify you have the right ones.
>
> **Include**: A table: `CFG File | Purpose | Source`

---

#### Section 4: Configuration Checklist

> **What to write**: A pre-flash configuration checklist. Fill this in with real items (replace the empty `<!-- TODO -->` checkboxes).
>
> **Format**:
> ```markdown
> !!! warning "Configuration Checklist"
>     - [ ] Correct machine target selected
>     - [ ] Elroy-specific DTB in place
>     - [ ] Matching CFG files configured
>     - [ ] extlinux.conf edited with correct partition path
>     - [ ] system.img placed in bootloader/
>     - [ ] CTI flash script configured for Elroy
> ```

---

#### Keep: Decision Flow Diagram

> The existing mermaid diagram is good. Keep it.

---

---

### `07-flashing-and-verification.md` — Flash & Verify on Elroy

**Role in the arc**: The payoff. Everything built across Phases 1 and 2 comes together here. The image boots on mission hardware.
**Current state**: Outline only (63 lines). Has good flash & verify pipeline diagram.
**Target length**: ~170–210 lines.

> [!IMPORTANT]
> Fix the phase label from `Phase 2 · Stage 5` → `Phase 2 · Page 7 of 7`

---

#### Section 1: Pre-Flash Checklist

> **What to write**: Expand the existing checklist into a proper `!!! warning` admonition. Add any items that are missing. This is the "are you sure you're ready?" gate.
>
> **Format**: Keep the checkbox list but wrap it in an admonition. Mirror [Phase 1 Page 9's flash preparation](file:///c:/Users/LENOVO/OneDrive/Desktop/MKDocs/docs/phase1/09-navigating-output-and-flashing.md#L108-L128).

---

#### Section 2: Entering Recovery Mode (Elroy)

> **What to write**: Step-by-step recovery mode procedure for the Elroy carrier board. Note any differences from the DevKit procedure documented in Phase 1 Page 9 (different button locations, different USB port, different physical setup). Include the `lsusb` verification command.
>
> **Include**:
> - Numbered step-by-step instructions
> - `lsusb | grep -i nvidia` verification
> - An `!!! note` calling out differences from the DevKit procedure if any exist

---

#### Section 3: Flash Procedure

> **What to write**: The full flash command sequence. What to expect in the terminal output. How long it takes. What a successful flash looks like.
>
> **Include**:
> - The flash command in a code block
> - A representative terminal output block showing key progress lines
> - Expected duration
> - The success message

---

#### Section 4: First Boot & Verification

> **What to write**: Serial console connection (reference Phase 1 Page 9 for minicom/screen setup). Login procedure. System verification commands.
>
> **Include a numbered checklist** (mirror [Phase 1 Page 9's first boot checklist](file:///c:/Users/LENOVO/OneDrive/Desktop/MKDocs/docs/phase1/09-navigating-output-and-flashing.md#L199-L230)):
> 1. Login (`root`)
> 2. `uname -a` — verify kernel
> 3. `df -h /` — verify image size
> 4. Network verification
> 5. Peripheral checks specific to Elroy

---

#### Section 5: Peripheral Verification

> **What to write**: For each peripheral relevant to the Elroy, document how to verify it works. USB, Ethernet, GPIO, and any other interfaces the Elroy exposes.
>
> **Format as a table**:
> ```
> | Peripheral | Verification Command / Method         | Expected Result |
> |------------|---------------------------------------|-----------------|
> | USB        | `lsusb`                               | ...             |
> | Ethernet   | `ip a` / `ping`                       | ...             |
> | GPIO       | ...                                   | ...             |
> ```

---

#### Section 6: Troubleshooting

> **What to write**: Elroy-specific flash and boot issues. Mirror [Phase 1 Page 9's troubleshooting table](file:///c:/Users/LENOVO/OneDrive/Desktop/MKDocs/docs/phase1/09-navigating-output-and-flashing.md#L235-L241).
>
> **Format**:
> ```
> | Problem | Likely Cause | Fix |
> ```
>
> **Include at least 4–5 rows** covering: recovery mode failures, flash timeouts, wrong DTB symptoms, kernel panic on boot, peripheral not detected.

---

#### Section 7: Phase 2 Complete

> **What to write**: A closing `!!! success "Phase 2 Complete!"` admonition. One sentence summarizing the achievement. One sentence previewing Phase 3 (PREEMPT_RT). Mirror [Phase 1's closing](file:///c:/Users/LENOVO/OneDrive/Desktop/MKDocs/docs/phase1/09-navigating-output-and-flashing.md#L245-L246).

---

#### Keep: Flash & Verify Pipeline Diagram

> The existing mermaid diagram is good. Keep it.

---

---

## Writing Checklist — Use Before Committing Each Page

Run through this for every page before you consider it done:

- [ ] YAML front-matter has both `title:` and `description:`
- [ ] Phase label reads `Phase 2 · Page X of 7`
- [ ] `!!! abstract "Page Goal"` is present and outcome-focused
- [ ] Page Process Overview flowchart (`mermaid flowchart LR`) is present
- [ ] Concepts are explained before commands are shown
- [ ] All code blocks have inline `# comments`
- [ ] Tables are used for structured comparisons, artifact lists, and troubleshooting
- [ ] At least one admonition (`note`, `warning`, `tip`, `info`, or `danger`) per page
- [ ] Existing mermaid diagrams are preserved
- [ ] Navigation footer has `← Previous` and `Next →` buttons
- [ ] Page length is in the 120–200 line range (not 34–63 like current outlines)
- [ ] No leftover `<!-- TODO -->` comments remain
- [ ] No `!!! info "Outline Page"` banner remains

---

## Suggested Writing Order

| Order | Page | Rationale |
|---|---|---|
| 1 | `index.md` | Sets the stage — finish the overview first so you have the narrative locked |
| 2 | `01-hardware-comparison.md` | Foundational context — everything else references this |
| 3 | `02-device-trees-and-configuration.md` | Conceptual prerequisite for Pages 4–7 |
| 4 | `03-warrior-branch-dead-end.md` | Standalone narrative — write it while the memory is fresh |
| 5 | `04-build-artifact-modification.md` | First hands-on page — starts the build pipeline |
| 6 | `05-connecttech-flash-scripts.md` | Continues the pipeline |
| 7 | `06-machine-configuration.md` | Configuration decisions — ties 4 and 5 together |
| 8 | `07-flashing-and-verification.md` | The finale — write last so you can reference all prior pages |
