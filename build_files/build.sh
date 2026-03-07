#!/bin/bash

set -ouex pipefail

dnf5 install -y tmux 

dnf5 install -y emacs \
                tmux \
                zsh

systemctl enable podman.socket
