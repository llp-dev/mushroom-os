# CentOS Stream 10 + Negativo17 NVIDIA kmod Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate Mushroom OS from Fedora Silverblue 44 to CentOS Stream 10 bootc with Negativo17 pre-built NVIDIA kmod.

**Architecture:** CentOS Stream 10 bootc minimal base + Negativo17 epel-nvidia repo providing real binary kmod packages (KABI-tracked) + EPEL for extra user packages. No akmod compilation, no kernel-devel, no RPM Fusion.

**Tech Stack:** bootc, CentOS Stream 10, podman/buildah, Negativo17, EPEL, dnf4

---

### Task 1: Update Containerfile

**Files:**
- Modify: `Containerfile:6,20`

- [ ] **Step 1: Change base image tag**

```dockerfile
FROM quay.io/centos-bootc/centos-bootc:stream10
```

- [ ] **Step 2: Remove `bootc container lint` step**

Delete line 20:
```dockerfile
RUN bootc container lint
```

The `bootc` CLI is not available in CentOS bootc images — linting is a Fedora bootc feature.

- [ ] **Step 3: Verify the CentOS bootc image exists**

Run: `skopeo inspect docker://quay.io/centos-bootc/centos-bootc:stream10`
Expected: JSON manifest with image metadata, no error.

Alternative if skopeo unavailable:
```bash
curl -sI "https://quay.io/v2/centos-bootc/centos-bootc/manifests/stream10"
```
Expected: HTTP 200.

- [ ] **Step 4: Commit**

```bash
git add Containerfile
git commit -m "build: migrate base image to CentOS Stream 10 bootc"
```

---

### Task 2: Rewrite build.sh — repos and NVIDIA packages

**Files:**
- Modify: `build_files/build.sh` (significant rewrite)

- [ ] **Step 1: Fix Adoptium repo URL for RHEL/CentOS**

Change the Adoptium repo URL from `fedora` to `rhel`:

```bash
# Adoptium (Java)
cat <<'EOF' >/etc/yum.repos.d/adoptium.repo
[Adoptium]
name=Adoptium
baseurl=https://packages.adoptium.net/artifactory/rpm/rhel/$releasever/$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.adoptium.net/artifactory/api/gpg/key/public
EOF
```

- [ ] **Step 2: Replace RPM Fusion + COPR with Negativo17 + EPEL**

Remove the RPM Fusion block (lines 26-28) and COPR block (lines 30-31). Replace with:

```bash
# Negativo17 NVIDIA driver (pre-built kmod + userspace)
dnf config-manager --add-repo=https://negativo17.org/repos/epel-nvidia.repo

# EPEL (extra packages)
dnf install -y epel-release
```

Note: `sudo` is dropped — CentOS bootc builds run as root.

- [ ] **Step 3: Replace NVIDIA packages**

Replace `kernel-devel-matched`, `xorg-x11-drv-nvidia`, `xorg-x11-drv-nvidia-power` with Negativo17 equivalents:

```bash
dnf install -y kmod-nvidia \
  nvidia-driver \
  nvidia-driver-libs \
  nvidia-settings \
  nvidia-modprobe \
  nvidia-persistenced \
```

Place these at the top of the main `dnf install` block, before `1password`.

- [ ] **Step 4: Replace all `dnf5` with `dnf`**

CentOS Stream 10 uses dnf4. Replace remaining instances:

```bash
dnf install -y @virtualization
...
dnf clean all
```

- [ ] **Step 5: Remove `mise` package**

Delete the `mise \` line from the package list. Mise is COPR-only on Fedora.

- [ ] **Step 6: Verify Negativo17 repo and packages exist**

Run:
```bash
curl -sI "https://negativo17.org/repos/nvidia/epel-10/x86_64/repodata/repomd.xml"
```
Expected: HTTP 200.

Run:
```bash
for pkg in kmod-nvidia nvidia-driver nvidia-driver-libs nvidia-settings nvidia-modprobe nvidia-persistenced; do
  echo -n "$pkg: "
  curl -sL "https://negativo17.org/repos/nvidia/epel-10/x86_64/" | grep -c "$pkg-595"
done
```
Expected: Each returns non-zero (package exists with version 595.x).

- [ ] **Step 7: Commit**

```bash
git add build_files/build.sh
git commit -m "feat: switch to Negativo17 NVIDIA kmod and CentOS repos"
```

---

### Task 3: Rewrite build.sh — user packages and cleanup

**Files:**
- Modify: `build_files/build.sh` (remaining package list)

- [ ] **Step 1: Keep the 1Password repo block as-is**

No changes needed — the repo URL uses `$basearch` which resolves correctly on CentOS.

- [ ] **Step 2: Update the main package list**

The current package list after Task 2 should have `kmod-nvidia`, `nvidia-driver`, `nvidia-driver-libs`, `nvidia-settings`, `nvidia-modprobe`, `nvidia-persistenced` at the top.

The remaining packages stay mostly the same. Remove `mise`. Some EPEL package names may differ. The complete list:

```bash
dnf install -y kmod-nvidia \
  nvidia-driver \
  nvidia-driver-libs \
  nvidia-settings \
  nvidia-modprobe \
  nvidia-persistenced \
  1password \
  7zip \
  bat \
  black \
  btop \
  cargo \
  clang \
  clang-tools-extra \
  fd-find \
  fzf \
  gcc \
  git \
  golang \
  gopls \
  glslang \
  htop \
  jq \
  markdown \
  make \
  pandoc \
  podman-compose \
  podman-docker \
  python3-isort \
  python3-pip \
  python3-pyflakes \
  python3-pytest \
  ripgrep \
  rustc \
  screen \
  ShellCheck \
  stow \
  temurin-25-jdk \
  unzip \
  wl-clipboard \
  zip \
  zsh
```

Note: `python3-isort` may be named `python-isort` on EPEL — package resolution in CI will reveal this.

- [ ] **Step 3: Add GNOME desktop packages**

CentOS bootc is minimal. Add desktop packages after the main install block:

```bash
dnf groupinstall -y "Workstation"
```

If the group doesn't exist on CentOS 10, fall back to individual packages:
```bash
dnf install -y @base-x gnome-shell gnome-session gdm gnome-terminal gnome-control-center
```

- [ ] **Step 4: Run shellcheck on the modified script**

Run: `shellcheck build_files/build.sh`
Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add build_files/build.sh
git commit -m "feat: migrate user packages and add GNOME desktop for CentOS 10"
```

---

### Task 4: Update services and cleanup sections

**Files:**
- Modify: `build_files/build.sh:76-94`

- [ ] **Step 1: Update the Cleanup section**

Change `dnf5 clean all` to `dnf clean all`:

```bash
### Cleanup
dnf clean all
rm -rf /var/cache/dnf
```

- [ ] **Step 2: Update services block**

Remove `nvidia-powerd` (integrated into Negativo17's `nvidia-driver`, not a separate service). Keep the rest:

```bash
### Enable Services
systemctl enable podman.socket
systemctl enable libvirtd
systemctl enable nvidia-persistenced
```

Note: `nvidia-powerd` is enabled automatically by Negativo17's `nvidia-driver` package via systemd symlinks — no manual enable needed.

- [ ] **Step 3: Run shellcheck on final script**

Run: `shellcheck build_files/build.sh`
Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add build_files/build.sh
git commit -m "feat: finalize services and cleanup for CentOS 10"
```

---

### Task 5: Verify and adjust CI workflow

**Files:**
- Check: `.github/workflows/build.yml` (may need no changes)

- [ ] **Step 1: Review the GitHub Actions build workflow**

Read `.github/workflows/build.yml` and check if any Fedora-specific assumptions exist:
- The workflow uses `redhat-actions/buildah-build` which works for any Containerfile
- Image tags and labels are distribution-agnostic
- No dnf/dnf5 commands in the workflow itself (all in Containerfile)

- [ ] **Step 2: Update IMAGE_DESC if Fedora is referenced**

Current env: `IMAGE_DESC: "My Customized Universal Blue Image"`
Change to something CentOS-appropriate:
```yaml
IMAGE_DESC: "Mushroom OS — CentOS Stream 10 based Linux image"
```

- [ ] **Step 3: Commit any CI changes**

```bash
git add .github/workflows/build.yml
git commit -m "ci: update image description for CentOS Stream 10"
```
If no changes needed, skip this commit.
