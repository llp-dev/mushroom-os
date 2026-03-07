#!/bin/bash

set -ouex pipefail

dnf5 install -y emacs \
                firefox \
                tmux \
                zsh

systemctl enable podman.socket
