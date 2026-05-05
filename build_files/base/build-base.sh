#!/bin/bash

set -eux

# RPM Fusion (free + nonfree) — needed for NVIDIA userspace and codecs.
dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-44.noarch.rpm
dnf install -y https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-44.noarch.rpm

# Exclude rawhide (fc45) packages globally. RPM Fusion mirrors sometimes
# surface fc45 builds via the F44 release-RPM's repos that require future
# glibc/libvpx; on a stable F44 image we never want them. The setting
# persists into the dev layer's dnf transactions.
echo "exclude=*.fc45*" >>/etc/dnf/dnf.conf

# Adoptium (Java)
cat <<'EOF' >/etc/yum.repos.d/adoptium.repo
[Adoptium]
name=Adoptium
baseurl=https://packages.adoptium.net/artifactory/rpm/fedora/$releasever/$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.adoptium.net/artifactory/api/gpg/key/public
EOF

dnf5 install -y @virtualization

# Foundational toolchain + language runtimes (LTS / rarely change).
dnf5 install -y \
  black \
  cargo \
  clang \
  clang-tools-extra \
  gcc \
  git \
  glx-utils \
  gnome-tweaks \
  golang \
  gopls \
  jq \
  make \
  podman-compose \
  podman-docker \
  ptyxis \
  python3-isort \
  python3-pip \
  python3-pyflakes \
  python3-pytest \
  rust-analyzer \
  rustc \
  temurin-25-jdk

### NVIDIA driver
NVIDIA_VERSION=$(< /akmods-out/nvidia-version)

# 1. Install our locally-built kmod RPM first. It Provides: nvidia-kmod,
#    nvidia-kmod-common, and ships the .ko files plus a depmod %post. The
#    kernel pin (Requires: kernel-core-uname-r) is enforced by the RPM.
dnf5 install -y /akmods-out/RPMS/mushroom-kmod-nvidia-open-*.rpm
rpm -q "mushroom-kmod-nvidia-open-${NVIDIA_VERSION}" >/dev/null

# 2. Userspace pinned to NVIDIA_VERSION. Excludes block RPM Fusion's
#    kmod-nvidia / akmod-nvidia siblings; our local RPM satisfies the
#    nvidia-kmod and nvidia-kmod-common deps that xorg-x11-drv-nvidia
#    et al. carry as hard Requires.
dnf5 install -y \
  --setopt=install_weak_deps=False \
  --exclude='kmod-nvidia*' --exclude='akmod-nvidia*' \
  "xorg-x11-drv-nvidia-${NVIDIA_VERSION}-*" \
  "xorg-x11-drv-nvidia-power-${NVIDIA_VERSION}-*" \
  "xorg-x11-drv-nvidia-cuda-libs-${NVIDIA_VERSION}-*" \
  "nvidia-modprobe-${NVIDIA_VERSION}-*" \
  "nvidia-persistenced-${NVIDIA_VERSION}-*" \
  "nvidia-settings-${NVIDIA_VERSION}-*"
rpm -q "xorg-x11-drv-nvidia-${NVIDIA_VERSION}" >/dev/null

# 3. Modprobe + dracut config (host regens initramfs at deploy time).
cat <<'EOF' >/etc/modprobe.d/nvidia.conf
blacklist nouveau
options nvidia-drm modeset=1 fbdev=1
EOF
cat <<'EOF' >/etc/dracut.conf.d/99-nvidia.conf
add_drivers+=" nvidia nvidia-drm nvidia-modeset nvidia-uvm "
force_drivers+=" nvidia nvidia-drm nvidia-modeset "
omit_drivers+=" nouveau "
EOF

# 4. Kernel cmdline kargs applied by bootc at deploy time. The modprobe.d
#    blacklist alone is insufficient: nouveau wins the PCI/udev probe race
#    in initramfs and binds the GPU before nvidia loads, leaving only
#    /dev/nvidiactl. rd.driver.blacklist covers initramfs;
#    modprobe.blacklist covers the real root.
mkdir -p /usr/lib/bootc/kargs.d
cat <<'EOF' >/usr/lib/bootc/kargs.d/10-nvidia.toml
kargs = [
  "rd.driver.blacklist=nouveau",
  "modprobe.blacklist=nouveau",
  "nvidia-drm.modeset=1",
]
EOF

### Config
cat <<'EOF' >/etc/profile.d/local-bin.sh
# Ensure /usr/local/bin is in the PATH for all users
case ":${PATH}:" in
    *:/usr/local/bin:*) ;;
    *) export PATH="/usr/local/bin:${PATH}" ;;
esac
EOF
chmod 644 /etc/profile.d/local-bin.sh

### Enable services
systemctl mask bootc-fetch-apply-updates.timer
systemctl enable podman.socket
systemctl enable libvirtd
systemctl enable nvidia-powerd.service
systemctl enable nvidia-persistenced.service

### Cleanup
dnf5 clean all
rm -rf /var/cache/dnf
