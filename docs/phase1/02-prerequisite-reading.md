---
title: "Important Links"
description: "Essential links for the Yocto Project, NVIDIA Tegra BSP, and all repositories used in this build."
---

# Important Links

<span class="phase-label">Phase 1 · Page 2 of 10</span>

!!! abstract "Page Goal"
    This is a reference page. Every official doc, repository, and external resource used in this build is linked here. References contain information or subpages which help enable additional functionality and are often referenced throughout the build.


!!! note "Recommended Reading"
    | Resource | Link |
    |----------|------|
    | Yocto Project Overview | [Yocto - Technical Overview ](https://www.yoctoproject.org/development/technical-overview/) |
    | What I wished I know about Yocto - Must Read (Kirkstone) | [What to know](https://docs.yoctoproject.org/kirkstone/brief-yoctoprojectqs/index.html) |



---

## Important Links & Repos


### Yocto Project Documentation

!!! warning "Yocto's Original Docs are Actively Updated "
    As of writing this documentation (June 2026), Yocto's original documentation for the branch used here is still up. All Documentation is available at [docs.yoctoproject.org](https://docs.yoctoproject.org/). However, be aware that the docs may be updated frequently, and you may need to adjust the links below:

    Google Search and Navigate to yoctoproject.org and there we have releases, check the left sidebar and navigate to release manuals. Select the corresponding branch for the documentation.

| Resource | Link |
|----------|------|
| Yocto Project on Kirkstone - The Roadmap uses this branch primarily | [yoctoproject.org](https://docs.yoctoproject.org/4.0.35/) |

!!! info "Use these links"
    The Current Links are still hosted and live, these will be checked and updated regularly.

| Resource | Link |
|----------|------|
| Yocto Project Overview | [yoctoproject.org](https://www.yoctoproject.org/) |
| Quick Build Guide (Kirkstone) - Must Read | [Quick Build](https://docs.yoctoproject.org/kirkstone/brief-yoctoprojectqs/index.html) |
| What I wished I know about Yocto - Must Read (Kirkstone) | [What to know](https://docs.yoctoproject.org/kirkstone/brief-yoctoprojectqs/index.html) |
| Reference Manual (Kirkstone) | [Major Reference Manual](https://docs.yoctoproject.org/kirkstone/ref-manual/index.html) |

### Github Project Repositories - (Links for Cloning - Specific Commands are also provided inline in the stages pages)
| Repository | Branch | Link |
|-----------|--------|------|
| Poky (BitBake + OE-Core) | `kirkstone` | [git.yoctoproject.org/poky]| (https://github.com/yoctoproject/poky/tree/kirkstone) |
| meta-tegra (OE4T) This is a Board Support Repo for the NVIDIA Jetson Devices, further stages in Phase 1 will explain this branch.| `kirkstone-l4t-32.7.x` | [github.com/OE4T/meta-tegra](https://github.com/OE4T/meta-tegra/tree/kirkstone-l4t-r32.7.x) |
| meta-openembedded  | `kirkstone` | [git.openembedded.org/meta-openembedded](https://git.openembedded.org/meta-openembedded) |
| meta-ros | `kirkstone` | [github.com/ros/meta-ros](https://github.com/ros/meta-ros/tree/kirkstone) |

### NVIDIA & Hardware Resources

| Resource | Link |
|----------|------|
| OE4T (Open Embedded for Tegra) Wiki (Single Most Important Reference ! ) | [oe4t-wiki](https://oe4t.github.io/master/) |


[← What Is Yocto?](01-what-is-yocto.md){ .md-button }
[Next: Host Setup →](03-host-setup.md){ .md-button .md-button--primary }
