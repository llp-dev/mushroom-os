#!/bin/bash

set -ouex pipefail

### 1 Password
curl -LO https://downloads.1password.com/linux/rpm/stable/x86_64/1password-latest.rpm
dnf5 install -y ./1password-latest.rpm
rm 1password-latest.rpm

### C
dnf5 install -y clang \
                clang-tools-extra \
                make

### Emacs
dnf5 install -y emacs-pgtk

### Go
dnf5 install -y golang \
                gopls

### Rust
dnf5 install -y cargo \
                rustc

### Tools
dnf5 install -y fd-find \
                ripgrep \
                zsh

systemctl enable podman.socket
