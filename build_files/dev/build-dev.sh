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

# Google Chrome
cat <<'EOF' >/etc/yum.repos.d/google-chrome.repo
[google-chrome]
name=google-chrome
baseurl=https://dl.google.com/linux/chrome/rpm/stable/$basearch
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
EOF

# Mise (COPR)
dnf5 copr enable -y jdxcode/mise

# Starship (COPR)
dnf5 copr enable -y atim/starship

# Declare 1Password's system groups via sysusers.d so they're carried
# declaratively in the image (bootc lint flags raw /etc/group entries
# without a sysusers.d source) and re-materialized on the host by
# systemd-sysusers.service. Apply immediately so the groups exist before
# the dnf5 install — without that, the 1password RPM's %post chgrp can't
# resolve `onepassword` and the BrowserSupport helper ends up setgid'd
# to a fallback GID, breaking browser<->desktop IPC trust. Members of
# `onepassword-cli` are trusted by the desktop app for biometric `op`
# integration; add the host user with:
#   sudo usermod -a -G onepassword,onepassword-cli $USER
cat <<'EOF' >/usr/lib/sysusers.d/onepassword.conf
g onepassword - -
g onepassword-cli - -
EOF
systemd-sysusers

dnf5 install -y \
  1password \
  1password-cli \
  7zip \
  bat \
  btop \
  fd-find \
  fzf \
  gh \
  glslang \
  google-chrome-stable \
  htop \
  markdown \
  mise \
  neovim \
  pandoc \
  ripgrep \
  rustfmt \
  screen \
  ShellCheck \
  starship \
  stow \
  unzip \
  wl-clipboard \
  zip \
  zsh

# Belt-and-suspenders: re-apply the BrowserSupport setgid bit. The 1password
# RPM's %post should have done this once `onepassword` existed at install
# time, but redo it explicitly so a future RPM packaging change can't
# silently break browser<->desktop IPC. Verify the binary ended up owned
# by the right group.
chgrp onepassword /opt/1Password/1Password-BrowserSupport
chmod g+s /opt/1Password/1Password-BrowserSupport
[[ "$(stat -c '%G' /opt/1Password/1Password-BrowserSupport)" == "onepassword" ]]

dnf5 clean all
rm -rf /var/cache/dnf
