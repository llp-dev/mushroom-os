#!/bin/bash

set -ouex pipefail

### 1 Password
curl -LO https://downloads.1password.com/linux/rpm/stable/x86_64/1password-latest.rpm
dnf5 install -y ./1password-latest.rpm
rm 1password-latest.rpm

### C
dnf5 install -y clang \
                clang-tools-extra \
                glslang \
                make

### Emacs
dnf5 install -y emacs-pgtk

### Go
dnf5 install -y golang \
                gopls

### Java
cat <<'EOF' > /etc/yum.repos.d/adoptium.repo
[Adoptium]
name=Adoptium
baseurl=https://packages.adoptium.net/artifactory/rpm/fedora/\$releasever/\$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.adoptium.net/artifactory/api/gpg/key/public
EOF
dnf5 install -y temurin-25-jdk

### Python
dnf5 install -y black \
                python3-isort

### Rust
dnf5 install -y cargo \
                rust-analyzer \
                rustc

### Shell
dnf5 install -y ShellCheck \
                shfmt

### Tools
dnf5 install -y ansible \
                direnv \
                fd-find \
                kubectl \
                ripgrep \
                zsh

systemctl enable podman.socket
