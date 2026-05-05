# NVIDIA kmod-open Driver Support for Mushroom OS

## Summary

Add NVIDIA GPU driver support to Mushroom OS using the open-source kernel
module (`kmod-nvidia-open`) from RPM Fusion, alongside a distribution upgrade
from Fedora 43 to Fedora 44.

## Motivation

- Target machine has a GTX 1650 Mobile (Turing TU117M), which is fully
  supported by NVIDIA's open-source GPU kernel module.
- akmod is incompatible with atomic bootc — it requires runtime kernel module
  compilation, which is impossible on an immutable root.
- kmod ships pre-built modules matched to the installed kernel, resolved by
  dnf in a single transaction. This is the correct approach for atomic bootc.
- CUDA is not required; desktop graphics and rendering only.

## Package selection (RPM Fusion nonfree, Fedora 44)

| Package | Version | Purpose |
|---|---|---|
| `kmod-nvidia-open` | 595.58.03-2.fc44 | Pre-built open-source kernel module, tracks latest kernel |
| `xorg-x11-drv-nvidia` | 595.58.03-1.fc44 | Userspace driver, libraries, Xorg integration |
| `xorg-x11-drv-nvidia-power` | 595.58.03-1.fc44 | Dynamic power management for laptop GPUs |

`xorg-x11-drv-nvidia` pulls `nvidia-modprobe` and `nvidia-persistenced` as
dependencies. No CUDA packages.

## Files changed

### `Containerfile`

- Bump base image: `fedora-silverblue:43` → `fedora-silverblue:44`

### `build_files/build.sh`

- Bump RPM Fusion release RPMs from `43` → `44`
- Add three NVIDIA packages to the `dnf5 install` block
- Enable `nvidia-powerd.service` and `nvidia-persistenced.service`

## Why this works on atomic bootc

The base image ships a specific kernel version. The RPM Fusion kmod packages
are built against that same kernel. When dnf runs the single `dnf5 install`
call, it resolves the kernel and the matching kmod together — they're always
in sync. No akmod runtime compilation needed.

## What does NOT change

- No additional `RUN` layers in the Containerfile
- No kernel version pinning
- No separate NVIDIA script or configuration file
- No CUDA or development packages
