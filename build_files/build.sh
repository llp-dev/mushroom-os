#!/bin/bash

set -eux

# 1Password
cat <<'EOF' > /etc/yum.repos.d/1password.repo
[1password]
name=1Password Stable Channel
baseurl=https://downloads.1password.com/linux/rpm/stable/$basearch
enabled=1
repo_gpgcheck=1
gpgcheck=1
gpgkey=https://downloads.1password.com/linux/keys/1password.asc
EOF

# Adoptium (Java)
cat <<'EOF' > /etc/yum.repos.d/adoptium.repo
[Adoptium]
name=Adoptium
baseurl=https://packages.adoptium.net/artifactory/rpm/fedora/$releasever/$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.adoptium.net/artifactory/api/gpg/key/public
EOF

# HashiCorp (Terraform)
dnf5 config-manager addrepo --from-repofile=https://rpm.releases.hashicorp.com/fedora/hashicorp.repo

# Lazygit (COPR)
dnf5 copr enable -y dejan/lazygit

dnf5 install -y 1password \
                7zip \
                ansible \
                bat \
                black \
                btop \
                cargo \
                clang \
                clang-tools-extra \
                direnv \
                fd-find \
                fzf \
                gcc \
                git \
                golang \
                gopls \
                glslang \
                helm \
                htop \
                jq \
                k9s \
                kubectl \
                lazygit \
                markdown \
                make \
                neovim \
                pandoc \
                podman-compose \
                podman-docker \
                pipx \
                poetry \
                python3-isort \
                python3-pip \
                python3-pyflakes \
                python3-pytest \
                ripgrep \
                rust-analyzer \
                rustc \
                screen \
                ShellCheck \
                shfmt \
                temurin-25-jdk \
                terraform \
                unzip \
                wl-clipboard \
                zip \
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
