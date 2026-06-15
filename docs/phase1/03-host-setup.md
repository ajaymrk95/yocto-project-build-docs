---
title: "Host Environment Setup"
description: "Setting up your Linux host machine with all the dependencies, disk space, and directory structure needed for a Yocto build."
---

# Host Environment Setup

<span class="phase-label">Phase 1 · Page 3 of 9</span>

!!! abstract "Page Goal"
    This short document steps you through the process for setting up your machine to configure and build a Yocto Image. This is almost exactly adapted as per Yocto's official setup guide.
---


!!! note 
    - Yocto Builds take several hours for the first time. Correctly identify the branch/release of yocto to work with, since that will need different host setup and requirements.
    - Docker based Approach can be used for older build systems, but they are phased out of long term support on Yocto.

!!! note "Native Linux System"

    - The examples in this paper assume you are using a native Linux system running a recent Ubuntu Linux distribution. If the machine you want to use Yocto Project on to build an image (Build Host) is not a native Linux system, you can still perform these steps by using CROss PlatformS (CROPS) and setting up a Poky container. Click on the link for the [Docker setup](https://docs.yoctoproject.org/kirkstone/dev-manual/start.html#setting-up-to-use-cross-platforms-crops){:target="_blank"}.

    - You may use version 2 of Windows Subsystem For Linux (WSL 2) to set up a build host using Windows 10 or later, Windows Server 2019 or later. Click on the link for the [WSL Setup](https://docs.yoctoproject.org/kirkstone/dev-manual/start.html#setting-up-to-use-windows-subsystem-for-linux-wsl-2){:target="_blank"}.

---

!!! note "Important Terms"

    | Term | Definition |
    |------|------------|
    | Build Host or Development Host | The Linux based machine where you setup the necessary configuration, write the bitbake code and then build the image. |
    | Target Device or Target Board | The actual hardware device for which you are building the image (e.g., NVIDIA Jetson TX2i, Raspberry Pi, Beaglebone, etc). |



## Hardware Requirements and Tested Setup

Make sure your Build Host meets the following requirements:

- At least 90 Gbytes of free disk space, though much more will help to run multiple builds and increase performance by reusing build artifacts.

- At least 8 Gbytes of RAM, though a modern build host with as much RAM and as many CPU cores as possible is strongly recommended to maximize build performance.

- Runs a supported Linux distribution (i.e. recent releases of Fedora, openSUSE, CentOS, Debian, or Ubuntu). For a list of Linux distributions that support the Yocto Project, see the Supported Linux Distributions section in the Yocto Project Reference Manual. For detailed information on preparing your build host, see the Preparing the Build Host section in the Yocto Project Development Tasks Manual.

- Ensure that the following utilities have these minimum version numbers:

- Git 1.8.3.1 or greater

- tar 1.28 or greater

- Python 3.6.0 or greater.

- gcc 7.5 or greater.

- GNU make 4.0 or greater

- The Tested Setup was a x86 based machine running Ubuntu 22.04 LTS, with a Core i7-13700K, 64GB of RAM and 1TB HDD. Having a high performance desktop machine as such is very helpful in speeding up the build process and having an SSD can further reduce the build time.

- Using VSCode with the Yocto Extension is helpful and helps understand the folder structure of the build more efficiently. 


---

## Installing Build Dependencies


```bash
sudo apt update
sudo apt install build-essential chrpath cpio debianutils diffstat file gawk gcc git iputils-ping libacl1 liblz4-tool locales python3 python3-git python3-jinja2 python3-pexpect python3-pip python3-subunit socat texinfo unzip wget xz-utils zstd
```

---

## Setting the Locale

Yocto requires a UTF-8 locale. 

```bash
sudo locale-gen en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
```

Add to `~/.bashrc` for persistence.

---


## Verify Setup

 CONTENT:
Quick verification commands:

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
