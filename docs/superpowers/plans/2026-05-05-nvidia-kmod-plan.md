# NVIDIA kmod-open Driver Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add NVIDIA open-source GPU kernel module (kmod-nvidia-open) to Mushroom OS and bump the base image from Fedora 43 to 44.

**Architecture:** Three packages added to the existing `dnf5 install` block in `build.sh` — the kernel and kmod resolve together in one transaction. Two NVIDIA services enabled alongside existing systemd units. Base image tag bumped in the Containerfile.

**Tech Stack:** bootc, podman/buildah, Fedora Silverblue, RPM Fusion, dnf5

---

### Task 1: Bump Fedora base image to 44

**Files:**
- Modify: `Containerfile:6`

- [ ] **Step 1: Change the base image tag**

```dockerfile
FROM quay.io/fedora/fedora-silverblue:44
```

- [ ] **Step 2: Verify the image tag exists**

Run: `skopeo inspect docker://quay.io/fedora/fedora-silverblue:44`
Expected: JSON manifest with image metadata, no error.

- [ ] **Step 3: Commit**

```bash
git add Containerfile
git commit -m "build: bump base image to Fedora Silverblue 44"
```

---

### Task 2: Add NVIDIA kmod-open packages and services

**Files:**
- Modify: `build_files/build.sh:27-28` (RPM Fusion release versions)
- Modify: `build_files/build.sh:33-71` (dnf5 install block)
- Modify: `build_files/build.sh:87-89` (systemctl enable block)

- [ ] **Step 1: Bump RPM Fusion release RPM versions**

Change lines 27-28 from `43` to `44`:

```bash
sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-44.noarch.rpm
sudo dnf install -y https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-44.noarch.rpm
```

- [ ] **Step 2: Add NVIDIA packages to the dnf5 install block**

Add three packages to the existing `dnf5 install -y` list (alphabetical order, before `1password`):

```bash
  kmod-nvidia-open \
  xorg-x11-drv-nvidia \
  xorg-x11-drv-nvidia-power \
```

- [ ] **Step 3: Enable NVIDIA services**

Append to the existing `systemctl enable` block:

```bash
systemctl enable nvidia-powerd
systemctl enable nvidia-persistenced
```

- [ ] **Step 4: Run shellcheck on the modified script**

Run: `shellcheck build_files/build.sh`
Expected: No errors or warnings.

- [ ] **Step 5: Verify RPM Fusion package availability**

Run:
```bash
curl -sL "https://ftp-stud.hs-esslingen.de/pub/Mirrors/rpmfusion.org/nonfree/fedora/releases/44/Everything/x86_64/os/repoview/kmod-nvidia-open.html" | grep -c "595.58.03"
curl -sL "https://ftp-stud.hs-esslingen.de/pub/Mirrors/rpmfusion.org/nonfree/fedora/releases/44/Everything/x86_64/os/repoview/xorg-x11-drv-nvidia.html" | grep -c "595.58.03"
curl -sL "https://ftp-stud.hs-esslingen.de/pub/Mirrors/rpmfusion.org/nonfree/fedora/releases/44/Everything/x86_64/os/repoview/xorg-x11-drv-nvidia-power.html" | grep -c "595.58.03"
```
Expected: Each returns a non-zero count (package page exists with expected version).

- [ ] **Step 6: Commit**

```bash
git add build_files/build.sh
git commit -m "feat: add NVIDIA kmod-open driver support

Add kmod-nvidia-open, xorg-x11-drv-nvidia, and xorg-x11-drv-nvidia-power
packages from RPM Fusion nonfree. Enable nvidia-powerd and
nvidia-persistenced services. Bump RPM Fusion release to 44."
```
