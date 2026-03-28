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

# RPM Fusion
sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-43.noarch.rpm
sudo dnf install -y https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-43.noarch.rpm

# Mise (COPR)
dnf5 copr enable -y jdxcode/mise

dnf5 group install --assumeyes admin-tools
dnf5 group install --assumeyes --with-optional c-development
dnf5 group install --assumeyes cloud-management
dnf5 group install --assumeyes --with-optional container-management 
dnf5 group install --assumeyes --with-optional development-libs
dnf5 group install --assumeyes firefox
dnf5 group install --assumeyes fonts
dnf5 group install --assumeyes java
dnf5 group install --assumeyes --with-optional java-development 
dnf5 group install --assumeyes --with-optional printing
dnf5 group install --assumeyes system-tools
dnf5 group install --assumeyes --with-optional virtualization-headless
dnf5 group install --assumeyes vlc

dnf5 install --assumeyes \
  7zip \
  akmod-nvidia \
  bat \
  black \
  cargo \
  fd-find \
  fzf \
  git \
  golang \
  gopls \
  glslang \
  jq \
  kernel-devel \
  kernel-headers \
  markdown \
  mise \
  pandoc \
  python3-isort \
  python3-pip \
  python3-pyflakes \
  python3-pytest \
  ripgrep \
  rustc \
  ShellCheck \
  stow \
  unzip \
  wl-clipboard \
  xorg-x11-drv-nvidia-cuda \
  zip \
  zsh

### akmod-nvidia
KVER=$(rpm -q kernel-devel --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}\n' | head -n 1)
akmods --force --kernels "$KVER"

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
