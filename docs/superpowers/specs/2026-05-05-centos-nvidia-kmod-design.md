# NVIDIA kmod Driver Support via CentOS Stream 10 + Negativo17

## Summary

Migrate Mushroom OS from Fedora Silverblue 44 to CentOS Stream 10 bootc, using
Negativo17's pre-built binary kmod-nvidia packages instead of RPM Fusion's
akmod-based approach. The CentOS KABI model provides pre-compiled kernel modules
that install without build-time compilation.

## Motivation

- RPM Fusion on Fedora 44 only provides akmod metapackages (12KB wrappers),
  not real pre-built kmods. The akmod `%post` scriptlet fails during the
  Containerfile build, making akmod unusable on atomic bootc.
- Negativo17 for CentOS provides **real binary kmods** (7.9MB pre-built `.ko`
  files) using KABI (Kernel ABI) symbol tracking. No compilation needed at
  install time — the module just copies into place.
- CentOS Stream guarantees KABI stability within a major version, so the kmod
  stays compatible across kernel updates without rebuilding.

## Files changed

### `Containerfile`

- Base image: `quay.io/fedora/fedora-silverblue:44` →
  `quay.io/centos-bootc/centos-bootc:stream10`
- Remove `bootc container lint` step (not available on CentOS bootc)

### `build_files/build.sh`

**Removed:**
- RPM Fusion free/nonfree repos (no longer needed)
- COPR repo for mise (not available on CentOS)
- `kernel-devel-matched` (no akmod compilation)
- `xorg-x11-drv-nvidia*` packages (replaced by Negativo17 equivalents)
- `mise` package (COPR-only, manual install if needed)

**Added:**
- Negativo17 `epel-nvidia.repo`
- EPEL release package
- `kmod-nvidia` — pre-built binary kernel module (KABI-tracked)
- `nvidia-driver` — userspace driver component
- `nvidia-driver-libs` — GL/EGL/Vulkan libraries
- `nvidia-settings` — control panel
- `nvidia-modprobe` — module loader utility
- `nvidia-persistenced` — persistence daemon

**Changed:**
- `dnf5` → `dnf` (CentOS 10 uses dnf4)
- `sudo dnf` → `dnf` (bootc builds run as root)
- Desktop packages need `@Workstation` or individual GNOME packages

## Package selection (Negativo17, CentOS 10)

| Package | Version | Purpose |
|---|---|---|
| `kmod-nvidia` | 595.71.05-1.el10 | Pre-built kernel module, KABI-tracked |
| `nvidia-driver` | 595.71.05-1.el10 | Userspace driver, Xorg/Wayland integration |
| `nvidia-driver-libs` | 595.71.05-1.el10 | GL/EGL/Vulkan libraries |
| `nvidia-settings` | 595.71.05-1.el10 | Control panel |
| `nvidia-modprobe` | 595.71.05-1.el10 | Kernel module loader |
| `nvidia-persistenced` | 595.71.05-1.el10 | Persistence daemon |

## Why this works

CentOS Stream uses KABI (Kernel ABI) whitelists. The kmod depends on specific
kernel symbol checksums (e.g., `kernel(__SCT__cond_resched) = 0xc07351b3`),
not a specific kernel version. As long as the running kernel exports the same
KABI symbols — which CentOS guarantees within a major version — the module
loads. No version-specific rebuilds, no akmod compilation.

## What does NOT change

- 1Password and Adoptium third-party repos remain
- Service enablement pattern remains (podman.socket, libvirtd, nvidia-persistenced)
- Most user-facing packages (zsh, git, emacs, dev tools) carry over via EPEL

## Migration notes

- `mise` is COPR-only and dropped. Manual install via `curl https://mise.run | sh` if needed.
- CentOS bootc is a minimal image — desktop packages must be added explicitly.
- Package names may differ slightly (e.g., `python3-isort` → `python-isort` on EPEL).
