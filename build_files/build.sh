#!/bin/bash

set -eux

dnf5 install -y 'dnf5-command(config-manager)'

# RPM Fusion
sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-43.noarch.rpm
sudo dnf install -y https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-43.noarch.rpm

# Mise (COPR)
curl -sL https://copr.fedorainfracloud.org/coprs/jdxcode/mise/repo/fedora-43/jdxcode-mise-fedora-43.repo \
     -o /etc/yum.repos.d/_copr_jdxcode-mise.repo

dnf5 config-manager addrepo --from-repofile=https://developer.download.nvidia.com/compute/cuda/repos/fedora43/x86_64/cuda-fedora43.repo

dnf5 clean expire-cache

### Default groups

dnf5 group install --assumeyes container-management 
dnf5 group install --assumeyes development-libs
dnf5 group install --assumeyes firefox
dnf5 group install --assumeyes fonts
dnf5 group install --assumeyes gnome-desktop
dnf5 group install --assumeyes virtualization-headless
dnf5 group install --assumeyes vlc
# dnf5 group install --assumeyes admin-tools
# dnf5 group install --assumeyes --with-optional c-development
# dnf5 group install --assumeyes cloud-management
# dnf5 group install --assumeyes java
# dnf5 group install --assumeyes --with-optional java-development 
# dnf5 group install --assumeyes --with-optional printing
# dnf5 group install --assumeyes system-tools

### nvidia-driver

dnf5 install --assumeyes --quiet kernel-devel kernel-headers
dnf5 install --assumeyes --quiet nvidia-driver kmod-nvidia-latest-dkms

### packages
xargs -a /ctx/packages.txt dnf5 install --assumeyes --quiet

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
