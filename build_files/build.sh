#!/bin/bash

set -eux

# 1Password
cat <<'EOF' >/etc/yum.repos.d/1password.repo
[1password]
name=1Password Stable Channel
baseurl=https://downloads.1password.com/linux/rpm/stable/$basearch
enabled=1
repo_gpgcheck=1
gpgcheck=1
gpgkey=https://downloads.1password.com/linux/keys/1password.asc
EOF

# Adoptium (Java)
cat <<'EOF' >/etc/yum.repos.d/adoptium.repo
[Adoptium]
name=Adoptium
baseurl=https://packages.adoptium.net/artifactory/rpm/fedora/$releasever/$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.adoptium.net/artifactory/api/gpg/key/public
EOF

# RPM Fusion
dnf5 install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-44.noarch.rpm
dnf5 install -y https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-44.noarch.rpm

# The rpmfusion release RPMs ship rawhide repo files enabled by default, which
# drags F45/rawhide ffmpeg-libs (needs glibc 2.44) into resolution and breaks
# every install on F44 stable. Force them off.
find /etc/yum.repos.d -name '*rawhide*.repo' -print -exec \
  sed -i 's/^enabled=1/enabled=0/' {} +

# Mise + starship (COPR) — fedora-bootc lacks the dnf5 copr subcommand by default
dnf5 install -y 'dnf5-command(copr)'
dnf5 copr enable -y jdxcode/mise
dnf5 copr enable -y atim/starship

# Virtualization (Silverbase already ships GNOME — @workstation-product-environment is redundant)
dnf5 install -y @virtualization

# NVIDIA proprietary stack (Optimus: Intel Iris Xe + GTX 1650 Mobile, Turing).
#
# Reality on F44 (verified 2026-05): there is no public source of pre-built
# kmod-nvidia for vanilla fedora-bootc:44. RPM Fusion's "kmod-nvidia" is a
# meta package that Requires: akmod-nvidia, and ublue-os/akmods stopped
# publishing artifacts after F42. So we run akmods ourselves *at image build
# time* against the kernel shipped in fedora-bootc:44, producing a real
# nvidia.ko baked into /usr/lib/modules/<KVER>/extra/nvidia/. First boot
# uses that prebuilt module — no boot-time compile, no 5-10 min wait.
#
# akmods exits 0 even when its kmod build silently fails. The ls assertion
# below is the only signal that a real artifact landed — do not remove it.
KVER=$(rpm -q kernel-core --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n')

dnf5 install -y \
  "kernel-devel-${KVER}" \
  akmod-nvidia \
  xorg-x11-drv-nvidia-power \
  libva-nvidia-driver \
  libva-utils \
  vdpauinfo

# Build nvidia.ko for the image's kernel.
akmods --force --kernels "${KVER}"

# Verify a real kmod artifact landed.
ls "/usr/lib/modules/${KVER}/extra/nvidia/nvidia.ko"* >/dev/null 2>&1 || {
  echo "FATAL: no nvidia.ko under /usr/lib/modules/${KVER}/extra/nvidia/" >&2
  exit 1
}

dnf5 install -y 1password \
  7zip \
  bat \
  black \
  btop \
  cargo \
  cascadia-code-nf-fonts \
  clang \
  clang-tools-extra \
  fd-find \
  fira-code-fonts \
  fzf \
  gcc \
  git \
  glslang \
  gnome-tweaks \
  golang \
  google-noto-emoji-fonts \
  gopls \
  htop \
  jq \
  make \
  markdown \
  mise \
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
  starship \
  stow \
  temurin-25-jdk \
  unzip \
  virt-manager \
  wl-clipboard \
  zip \
  zsh

### NVIDIA module options + runtime power management
# Vendor-supplied configs go in /usr/lib so they don't conflict with /etc overrides.
mkdir -p /usr/lib/modprobe.d /usr/lib/udev/rules.d

cat <<'EOF' >/usr/lib/modprobe.d/nvidia-power.conf
options nvidia NVreg_DynamicPowerManagement=0x02
options nvidia NVreg_PreserveVideoMemoryAllocations=1
options nvidia NVreg_TemporaryFilePath=/var/tmp
EOF

cat <<'EOF' >/usr/lib/udev/rules.d/80-nvidia-pm.rules
# Enable PCI runtime PM for NVIDIA dGPU on Turing+ (VGA + 3D controller classes)
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", TEST=="power/control", ATTR{power/control}="auto"
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", TEST=="power/control", ATTR{power/control}="auto"
EOF

### Kernel args (bootc-native: kargs.d travels with the image)
mkdir -p /usr/lib/bootc/kargs.d
cat <<'EOF' >/usr/lib/bootc/kargs.d/10-nvidia.toml
kargs = [
  "nvidia-drm.modeset=1",
  "nvidia-drm.fbdev=1",
  "nvidia.NVreg_PreserveVideoMemoryAllocations=1",
  "nvidia.NVreg_TemporaryFilePath=/var/tmp",
  "nvidia.NVreg_EnableGpuFirmware=1",
]
match-architectures = ["x86_64"]
EOF

### Flatpak: register Flathub as a system remote
flatpak remote-add --system --if-not-exists \
  flathub https://dl.flathub.org/repo/flathub.flatpakrepo

### Cleanup
dnf5 clean all
rm -rf /var/cache/dnf

### Config
cat <<'EOF' >/etc/profile.d/local-bin.sh
# Ensure /usr/local/bin is in the PATH for all users
case ":${PATH}:" in
    *:/usr/local/bin:*) ;;
    *) export PATH="/usr/local/bin:${PATH}" ;;
esac
EOF
chmod 644 /etc/profile.d/local-bin.sh

### Enable Services
systemctl enable podman.socket
systemctl enable libvirtd
systemctl enable gdm
systemctl set-default graphical.target

# NVIDIA VRAM save/restore across suspend (matches NixOS
# `hardware.nvidia.powerManagement.enable = true`). Without these, Optimus
# suspend on this hardware is the lottery the previous Fedora install was losing.
systemctl enable nvidia-suspend.service nvidia-resume.service

# Hibernate is intentionally disabled (silverblue-plan.md decision #4):
# not used today, and LUKS+hibernate on bootc/Atomic is fragile and unsupported.
# nvidia-hibernate.service is intentionally NOT enabled.
systemctl mask hibernate.target hybrid-sleep.target suspend-then-hibernate.target
