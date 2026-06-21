---
title: "Build System and Requirements Setup"
description: "Setting up your Linux host machine with all the dependencies, disk space, and directory structure needed for a Yocto build."
---

# Build Computer Setup

<span class="phase-label">Phase 1 · Page 3 of 9</span>

!!! abstract "Page Goal"
    This page walks you through preparing your computer (the "build host") so it has all the software tools, disk space, and settings needed to run a Yocto build. These steps closely follow the official Yocto setup guide.
---


!!! note 
    - The very first Yocto build can take **several hours** (sometimes 4–8 hours depending on your hardware). Subsequent builds are much faster because Yocto caches previous work.
    - Make sure you pick the correct Yocto release branch before starting — different branches may need different host tools.
    - Docker-based builds exist for Yocto versions, allowing us to use one Computer for builds based on releases from different branches.


!!! note "Important Terms"

    | Term | Definition |
    |------|------------|
    | Build Host or Development Host | The Linux based machine where you setup the necessary configuration, write the bitbake code and then build the image. |
    | Target Device or Target Board | The actual hardware device for which you are building the image (e.g., NVIDIA Jetson TX2i, Raspberry Pi, Beaglebone, etc). |

!!! note "Native Linux System"

    - This guide assumes you are using a computer running **Ubuntu Linux**. If your computer runs Windows or macOS instead, you have two options:
        - **Docker container**: Run a Linux environment inside a container. See the [Docker setup guide](https://docs.yoctoproject.org/kirkstone/dev-manual/start.html#setting-up-to-use-cross-platforms-crops){:target="_blank"}.
        - **WSL 2 (Windows only)**: Windows 10 and later can run Linux directly inside Windows using WSL 2 (Windows Subsystem for Linux). See the [WSL setup guide](https://docs.yoctoproject.org/kirkstone/dev-manual/start.html#setting-up-to-use-windows-subsystem-for-linux-wsl-2){:target="_blank"}.

---


## Hardware Requirements and Tested Setup

Make sure your computer (Build Host) meets these minimum requirements:

- **Disk space**: At least 90 GB free. Yocto downloads a lot of source code and generates large temporary files during the build. 500 GB+ is recommended if you plan to do multiple builds.

- **RAM**: At least 8 GB. More RAM and more CPU cores means faster builds — the build process runs many compilation tasks in parallel.

- **Operating system**: A recent Linux distribution (Ubuntu, Fedora, Debian, CentOS, or openSUSE). We tested with **Ubuntu 22.04 LTS**, which is the recommended choice.

- Ensure that the following utilities have these minimum version numbers:

- Git 1.8.3.1 or greater

- tar 1.28 or greater

- Python 3.6.0 or greater.

- gcc 7.5 or greater.

- GNU make 4.0 or greater

- The Tested Setup was a x86 based machine running Ubuntu 22.04 LTS, with a Core i7-13700K, 64GB of RAM and 1TB HDD. Having a high performance desktop machine as such is very helpful in speeding up the build process and having an SSD can further reduce the build time.

- Using VSCode with the Yocto Extension is helpful and helps in understanding the folder structure of the building process. 


---

## Installing Build Dependencies

Yocto needs a set of standard Linux development tools installed on your system before it can compile anything. The command below installs all required packages/dependencies in one go:


```bash
sudo apt update
sudo apt install build-essential chrpath cpio debianutils diffstat file gawk gcc git iputils-ping libacl1 liblz4-tool locales python3 python3-git python3-jinja2 python3-pexpect python3-pip python3-subunit socat texinfo unzip wget xz-utils zstd
```

---

## Setting the Locale

A "locale" tells Linux how to handle text encoding (character sets, date formats, etc.). Yocto requires the **UTF-8** locale to be set, otherwise certain build scripts may fail with encoding errors.

```bash
sudo locale-gen en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
```

Add these two `export` lines to your `~/.bashrc` file so they are applied automatically every time you open a new terminal.

---


## Verify Setup

Before moving on, run these quick checks to confirm everything is installed correctly:

```bash
# Check Ubuntu version
lsb_release -a

# Check disk space
df -h ~

# Check GCC
gcc --version

# Check Python
python3 --version

# Check Git
git --version

# Check locale
locale
```
Move on to the Quick Build.


---

[← Prerequisite Reading](02-prerequisite-reading.md){ .md-button }
[Next: Quick Build →](04-quick-build.md){ .md-button .md-button--primary }
