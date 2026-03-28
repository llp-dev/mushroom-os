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
sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-43.noarch.rpm
sudo dnf install -y https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-43.noarch.rpm

# Mise (COPR)
dnf5 copr enable -y jdxcode/mise

dnf5 install -y @virtualization

dnf5 install -y 1password \
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
  zip \
  zsh

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
