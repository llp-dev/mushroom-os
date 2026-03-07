#!/bin/bash

set -ouex pipefail

### 1 Password
cat <<'EOF' > /etc/yum.repos.d/1password.repo
[1password]
name=1Password Stable Channel
baseurl=https://downloads.1password.com/linux/rpm/stable/\$basearch
enabled=1
repo_gpgcheck=1
gpgcheck=1
gpgkey=https://downloads.1password.com/linux/keys/1password.asc
EOF
dnf5 install -y 1password

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
                pipx \
                poetry \
                python3-isort \
                python3-pip \
                python3-pyflakes \
                python3-pytest
                
### Rust
dnf5 install -y cargo \
                rust-analyzer \
                rustc

### Shell
dnf5 install -y ShellCheck \
                shfmt

### Tools
dnf5 config-manager addrepo --from-repofile=https://rpm.releases.hashicorp.com/fedora/hashicorp.repo

dnf5 install -y ansible \
                direnv \
                fd-find \
                kubectl \
                markdown \
                pandoc \
                ripgrep \
                terraform \
                zsh

### Cleanup
dnf5 clean all
rm -rf /var/cache/dnf

### Config
cat <<'EOF' > /etc/profile.d/local-bin.sh
# Ensure /usr/local/bin is in the PATH for all users
case ":${PATH}:" in
    *:/usr/local/bin:*) ;;
    *) export PATH="/usr/local/bin:${PATH}" ;;
esac
EOF
chmod 644 /etc/profile.d/local-bin.sh

systemctl enable podman.socket
