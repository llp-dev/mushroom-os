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

# Declare 1Password's system groups via sysusers.d so they're carried
# declaratively in the image (bootc lint flags raw /etc/group entries
# without a sysusers.d source) and re-materialized on the host by
# systemd-sysusers.service. Apply immediately so the groups exist before
# the dnf5 install — without that, the 1password RPM's %post chgrp can't
# resolve `onepassword` and the BrowserSupport helper ends up setgid'd
# to a fallback GID, breaking browser<->desktop IPC trust. Members of
# `onepassword-cli` are trusted by the desktop app for biometric `op`
# integration; add the host user with:
#   sudo usermod -a -G onepassword,onepassword-cli $USER
cat <<'EOF' >/usr/lib/sysusers.d/onepassword.conf
g onepassword - -
g onepassword-cli - -
EOF
systemd-sysusers

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
dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-44.noarch.rpm
dnf install -y https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-44.noarch.rpm

# Exclude rawhide (fc45) packages globally. RPM Fusion mirrors sometimes
# surface fc45 builds via the F44 release-RPM's repos that require future
# glibc/libvpx; on a stable F44 image we never want them.
echo "exclude=*.fc45*" >>/etc/dnf/dnf.conf

# Mise (COPR)
dnf5 copr enable -y jdxcode/mise

dnf5 install -y @virtualization

dnf5 install -y 1password \
  1password-cli \
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
  gnome-tweaks \
  htop \
  jq \
  markdown \
  make \
  mise \
  pandoc \
  podman-compose \
  podman-docker \
  ptyxis \
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

# Belt-and-suspenders: re-apply the BrowserSupport setgid bit. The 1password
# RPM's %post should have done this once `onepassword` existed at install time,
# but redo it explicitly so a future RPM packaging change can't silently break
# browser<->desktop IPC. Verify the binary ended up owned by the right group.
chgrp onepassword /opt/1Password/1Password-BrowserSupport
chmod g+s /opt/1Password/1Password-BrowserSupport
[[ "$(stat -c '%G' /opt/1Password/1Password-BrowserSupport)" == "onepassword" ]]

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

# 3. Modprobe + dracut config (host regens initramfs at deploy time)
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
#    in initramfs and binds the GPU before nvidia loads, producing
#    "NVRM: GPU 0000:01:00.0 is already bound to nouveau / No NVIDIA
#    devices probed" and leaving only /dev/nvidiactl. rd.driver.blacklist
#    covers initramfs; modprobe.blacklist covers the real root.
mkdir -p /usr/lib/bootc/kargs.d
cat <<'EOF' >/usr/lib/bootc/kargs.d/10-nvidia.toml
kargs = [
  "rd.driver.blacklist=nouveau",
  "modprobe.blacklist=nouveau",
  "nvidia-drm.modeset=1",
]
EOF

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
systemctl mask bootc-fetch-apply-updates.timer
systemctl enable podman.socket
systemctl enable libvirtd
systemctl enable nvidia-powerd.service
systemctl enable nvidia-persistenced.service
