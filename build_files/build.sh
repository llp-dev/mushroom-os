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

# NVIDIA
dnf5 config-manager addrepo --from-repofile=https://developer.download.nvidia.com/compute/cuda/repos/fedora43/x86_64/cuda-fedora43.repo
sudo dnf config-manager setopt cuda-fedora43-$(uname -m).exclude=nvidia-driver,nvidia-modprobe,nvidia-persistenced,nvidia-settings,nvidia-libXNVCtrl,nvidia-xconfig

# Mise (COPR)
dnf5 copr enable -y jdxcode/mise

dnf5 clean expire-cache

dnf5 install -y @virtualization

dnf5 install -y 1password \
  7zip \
  bat \
  black \
  btop \
  cargo \
  clang \
  clang-tools-extra \
  cuda-toolkit \
  fd-find \
  fzf \
  gcc \
  git \
  golang \
  gopls \
  glslang \
  htop \
  jq \
  kernel-devel \
  kernel-headers \
  markdown \
  make \
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
  stow \
  temurin-25-jdk \
  unzip \
  wl-clipboard \
  xorg-x11-drv-nvidia-cuda \
  zip \
  zsh

dkms autoinstall -k "$(rpm -q kernel --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}')"

### Cleanup
dnf5 clean all
rm -rf /var/cache/dnf

### Config
tee /etc/profile.d/local-bin.sh <<'EOF'
# Ensure /usr/local/bin is in the PATH for all users
case ":${PATH}:" in
    *:/usr/local/bin:*) ;;
    *) export PATH="/usr/local/bin:${PATH}" ;;
esac
EOF
chmod 644 /etc/profile.d/local-bin.sh

tee /usr/lib/bootc/kargs.d/00-nvidia.toml <<'EOF'
kargs = ["rd.driver.blacklist=nouveau", "modprobe.blacklist=nouveau", "nvidia-drm.modeset=1", "initcall_blacklist=simpledrm_platform_driver_init"]
EOF

### Enable Services
systemctl enable podman.socket
systemctl enable libvirtd
