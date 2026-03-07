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
