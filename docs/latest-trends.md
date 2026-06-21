---
title: "NVIDIA Yocto Support & Space Grade Linux"
description: "Overview of NVIDIA's official Yocto Project support from June 2026 and an exploration of open-source Space Grade Linux practices for embedded aeronautical applications."
---

# NVIDIA Yocto Support & Space Grade Linux

!!! info "Industry Trends Alignment"
    This page reviews the pivotal shift toward reproducible, production-hardened OS environments with NVIDIA's official Yocto support, alongside the emerging standards and redundancies defining open-source Linux for space and aeronautical applications.

---

## 1. NVIDIA Official Yocto Support (June 2026)

In June 2026, NVIDIA officially integrated Yocto Project support into Jetson platforms alongside the JetPack 7.2 release. For embedded developers, this encourages official NVIDIA support and QA testing of Operating System builds using the Yocto Framework for size controlled production level deployments on NVIDIA devices.

For more details on memory optimization and Agentic AI at the Edge in JetPack 7.2, see the official [NVIDIA Developer Blog: Deploy Agentic-Ready AI at the Edge with Memory Efficiency in NVIDIA JetPack 7.2](https://developer.nvidia.com/blog/deploy-agentic-ready-ai-at-the-edge-with-memory-efficiency-in-nvidia-jetpack-7-2/){:target="_blank"}.

### JetPack 7.2 Technical Walkthrough
Below is the official presentation detailing these edge optimizations:

<div class="video-container" style="position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden; max-width: 100%; margin-bottom: 2em;">
  <iframe src="https://www.youtube.com/embed/uVVOMLPLwPg" 
          title="YouTube video player" 
          frameborder="0" 
          allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" 
          referrerpolicy="strict-origin-when-cross-origin" 
          allowfullscreen 
          style="position: absolute; top: 0; left: 0; width: 100%; height: 100%;"></iframe>
</div>

---

## 2. Space Grade Linux 

 Initiatives like **Space Grade Linux (SGL)**—part of the Linux Foundation's ELISA Project—aim to build a reusable, safety-aware Linux foundation for spaceflight systems.


### Video Reference: Building Space Grade Linux
*A reproducible project that can be used as industry common standard OS for space applications, built using the Yocto Framework and kas workflows.*

This presentation details the goals of the Space Grade Linux project, exploring how open-source developers working in space domain solve problems and redundancy, how the project aims to provide an industry standard framework for space linux, reducing the need for one of a kind development.

The major contribution this work gives is a poll based on devices, operating system used, redundancies currently being used by developers in space applications.

<div class="video-container" style="position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden; max-width: 100%; margin-bottom: 2em;">
  <iframe src="https://www.youtube.com/embed/jfFPlaVtTDY" 
          title="YouTube video player" 
          frameborder="0" 
          allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" 
          referrerpolicy="strict-origin-when-cross-origin" 
          allowfullscreen 
          style="position: absolute; top: 0; left: 0; width: 100%; height: 100%;"></iframe>
</div>

---

[← Roadmap](roadmap.md){ .md-button }