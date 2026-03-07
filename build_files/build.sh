#!/bin/bash

set -ouex pipefail

### 1 Password
rpm --import https://downloads.1password.com/linux/keys/1password.asc
dnf5 config-manager addrepo --from-repofile=https://downloads.1password.com/linux/rpm/stable/1password.repo
dnf5 install -y 1password

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

### Rust
dnf5 install -y zsh

systemctl enable podman.socket
