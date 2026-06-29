#!/usr/bin/env bash

set -Eeuo pipefail

FEDORA_RELEASE="$(rpm -E %fedora)"
NEXT_FEDORA_RELEASE=$((FEDORA_RELEASE + 1))
readonly FEDORA_RELEASE NEXT_FEDORA_RELEASE

readonly -a COPR_REPOS=(
  jdxcode/mise
  atim/starship
  atim/lazydocker
  dejan/lazygit
)

readonly -a SYSTEM_PACKAGES=(
  cascadia-code-nf-fonts
  cascadia-mono-nf-fonts
  clevis
  clevis-pin-pkcs11
  clevis-pin-tpm2
  clevis-pin-trustee
  clevis-systemd
  fuse
  fuse3
  fuse-libs
  glx-utils
  gnome-tweaks
  grub2-tools-extra
  openssh-askpass
  ptyxis
  rclone
  steam-devices
  xorriso
)

readonly -a CONTAINER_PACKAGES=(
  buildah
  podman
  podman-compose
  podman-docker
  skopeo
  toolbox
)

readonly -a VIRT_PACKAGES=(
  qemu-kvm
  vagrant
)

readonly -a MEDIA_PACKAGES=(
  ffmpeg
  gstreamer1-plugins-bad-free-extras
  gstreamer1-plugins-bad-freeworld
  gstreamer1-plugins-ugly
  gstreamer1-vaapi
  intel-media-driver
  vlc
  vlc-plugins-all
)

readonly -a CLI_PACKAGES=(
  1password
  1password-cli
  brave-browser
  7zip
  ansible-core
  bat
  btop
  copr-cli
  direnv
  emacs
  fd-find
  fzf
  gh
  git-delta
  google-chrome-stable
  hyperfine
  jq
  lazydocker
  lazygit
  markdown
  mise
  neovim
  opentofu
  pandoc
  ripgrep
  screen
  ShellCheck
  shfmt
  starship
  tidy
  tokei
  tree-sitter-cli
  wl-clipboard
  zip
  zsh
)

readonly -a C_PACKAGES=(
  autoconf
  automake
  bear
  binutils
  bison
  ccache
  cmake
  cscope
  ctags
  diffstat
  doxygen
  dtc
  elfutils
  flex
  gcc
  gcc-c++
  gdb
  gettext
  git
  glibc-devel
  indent
  libstdc++-devel
  libtool
  ltrace
  make
  meson
  ncurses-devel
  ninja-build
  openssl-devel
  patch
  patchutils
  perf
  pkgconf-pkg-config
  strace
  valgrind
)

readonly -a CPP_PACKAGES=(
  cairo-devel
  clang
  clang-analyzer
  clang-libs
  clang-resource-filesystem
  clang-tools-extra
  compiler-rt
  cppcheck
  dbus-devel
  fontconfig-devel
  freetype-devel
  glslang
  gtk3-devel
  libX11-devel
  libXcursor-devel
  libXext-devel
  libXfixes-devel
  libXft-devel
  libXinerama-devel
  libXrender-devel
  libdecor-devel
  libstdc++-static
  libxkbcommon-devel
  lld
  lldb
  mesa-libEGL-devel
  mesa-libGL-devel
  mesa-libGLES-devel
  mesa-libGLU-devel
  mesa-libgbm-devel
  mold
  pango-devel
  wayland-devel
  wayland-protocols-devel
)

readonly -a JAVA_PACKAGES=(
  temurin-25-jdk
)

readonly -a GO_PACKAGES=(
  delve
  golang
  golang-x-tools-goimports
  golangci-lint
  gopls
)

readonly -a LUA_PACKAGES=(
  compat-lua
  love
  lua
  luajit
  luarocks
)

readonly -a PYTHON_PACKAGES=(
  black
  python3-PyMuPDF
  python3-click
  python3-devel
  python3-fastmcp
  python3-isort
  python3-lsp-server
  python3-lxml
  python3-mypy
  python3-numpy
  python3-openapi-pydantic
  python3-openpyxl
  python3-pandas
  python3-pexpect
  python3-pip
  python3-pydantic-core
  python3-pydantic-extra-types
  python3-pydantic-settings
  python3-pyflakes
  python3-pytest
  python3-pyyaml
  python3-reportlab
  python3-requests
  python3-rich
  python3-tomlkit
  python3-tqdm
  ruff
  tox
  uv
)

readonly -a RUST_PACKAGES=()

install_repositories() {
  dnf5 install -y \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_RELEASE}.noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_RELEASE}.noarch.rpm"

  printf 'exclude=*.fc%s*\n' "$NEXT_FEDORA_RELEASE" >>/etc/dnf/dnf.conf

  install -Dm0644 /dev/stdin /etc/yum.repos.d/adoptium.repo <<'EOF'
[Adoptium]
name=Adoptium
baseurl=https://packages.adoptium.net/artifactory/rpm/fedora/$releasever/$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.adoptium.net/artifactory/api/gpg/key/public
EOF

  install -Dm0644 /dev/stdin /etc/yum.repos.d/1password.repo <<'EOF'
[1password]
name=1Password Stable Channel
baseurl=https://downloads.1password.com/linux/rpm/stable/$basearch
enabled=1
repo_gpgcheck=1
gpgcheck=1
gpgkey=https://downloads.1password.com/linux/keys/1password.asc
EOF

  install -Dm0644 /dev/stdin /etc/yum.repos.d/google-chrome.repo <<'EOF'
[google-chrome]
name=google-chrome
baseurl=https://dl.google.com/linux/chrome/rpm/stable/$basearch
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
EOF

  install -Dm0644 /dev/stdin /etc/yum.repos.d/brave-browser.repo <<'EOF'
[brave-browser]
name=Brave Browser
baseurl=https://brave-browser-rpm-release.s3.brave.com/$basearch/
enabled=1
gpgcheck=1
gpgkey=https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
EOF

  local repo
  for repo in "${COPR_REPOS[@]}"; do
    dnf5 copr enable -y "$repo"
  done
}

configure_onepassword_groups() {
  # bootc wants image groups declared through sysusers.d, and the RPM's
  # BrowserSupport helper needs the group available during install.
  install -Dm0644 /dev/stdin /usr/lib/sysusers.d/onepassword.conf <<'EOF'
g onepassword - -
g onepassword-cli - -
EOF
  systemd-sysusers
}

install_packages() {
  local nvidia_version
  local -a nvidia_kmod_rpms
  nvidia_version="$(</akmods-out/nvidia-version)"
  nvidia_kmod_rpms=(/akmods-out/RPMS/mushroom-kmod-nvidia-*.rpm)
  [[ -e "${nvidia_kmod_rpms[0]}" ]]

  # Prebuilt Broadcom wl module from the akmods-wl stage. broadcom-wl pulls in
  # the firmware and the in-tree-driver blacklist; the kmod-wl RPM satisfies
  # its module dependency so akmod-wl never has to rebuild on the live system.
  local wl_kver
  local -a wl_kmod_rpms
  wl_kver="$(</akmods-wl-out/wl-kver)"
  wl_kmod_rpms=(/akmods-wl-out/RPMS/kmod-wl-*.rpm)
  [[ -e "${wl_kmod_rpms[0]}" ]]

  dnf5 install -y \
    --setopt=install_weak_deps=False \
    --allowerasing \
    --exclude='kmod-nvidia*' \
    --exclude='akmod-nvidia*' \
    --exclude='akmod-wl' \
    "${SYSTEM_PACKAGES[@]}" \
    "${CONTAINER_PACKAGES[@]}" \
    "${VIRT_PACKAGES[@]}" \
    "${MEDIA_PACKAGES[@]}" \
    "${CLI_PACKAGES[@]}" \
    "${C_PACKAGES[@]}" \
    "${CPP_PACKAGES[@]}" \
    "${JAVA_PACKAGES[@]}" \
    "${GO_PACKAGES[@]}" \
    "${LUA_PACKAGES[@]}" \
    "${PYTHON_PACKAGES[@]}" \
    "${RUST_PACKAGES[@]}" \
    "${nvidia_kmod_rpms[@]}" \
    "xorg-x11-drv-nvidia-${nvidia_version}-*" \
    "xorg-x11-drv-nvidia-power-${nvidia_version}-*" \
    "nvidia-modprobe-${nvidia_version}-*" \
    "nvidia-persistenced-${nvidia_version}-*" \
    "nvidia-settings-${nvidia_version}-*" \
    "${wl_kmod_rpms[@]}" \
    broadcom-wl

  rpm -q "mushroom-kmod-nvidia-${nvidia_version}" >/dev/null
  rpm -q "xorg-x11-drv-nvidia-${nvidia_version}" >/dev/null
  rpm -q "kmod-wl-${wl_kver}" >/dev/null
}

configure_nvidia_boot() {
  install -Dm0644 /dev/stdin /etc/modprobe.d/nvidia.conf <<'EOF'
blacklist nouveau
options nvidia-drm modeset=1 fbdev=1
# Keep the dGPU powered instead of dropping to D3cold runtime suspend. On
# laptops the external display outputs are wired to the dGPU; waking it from
# D3cold on hotplug hard-freezes the NVIDIA kernel modules under Wayland.
options nvidia NVreg_DynamicPowerManagement=0x00
EOF

  install -Dm0644 /dev/stdin /etc/dracut.conf.d/99-nvidia.conf <<'EOF'
add_drivers+=" nvidia nvidia-drm nvidia-modeset nvidia-uvm "
force_drivers+=" nvidia nvidia-drm nvidia-modeset "
omit_drivers+=" nouveau "
EOF

  # bootc applies these kargs at deploy time; nouveau must be blocked in
  # initramfs before it can claim the GPU.
  install -Dm0644 /dev/stdin /usr/lib/bootc/kargs.d/10-nvidia.toml <<'EOF'
kargs = [
  "rd.driver.blacklist=nouveau",
  "modprobe.blacklist=nouveau",
  "nvidia-drm.modeset=1",
]
EOF
}

configure_shell_path() {
  install -Dm0644 /dev/stdin /etc/profile.d/local-bin.sh <<'EOF'
case ":${PATH}:" in
    *:/usr/local/bin:*) ;;
    *) export PATH="/usr/local/bin:${PATH}" ;;
esac
EOF
}

configure_services() {
  systemctl mask bootc-fetch-apply-updates.timer
  systemctl enable podman.socket
  systemctl enable nvidia-powerd.service
  systemctl enable nvidia-persistenced.service
  # From xorg-x11-drv-nvidia-power: preserve video memory across power
  # transitions so suspend/resume and GPU power changes don't corrupt state.
  systemctl enable nvidia-suspend.service
  systemctl enable nvidia-resume.service
  systemctl enable nvidia-hibernate.service
}

verify_onepassword_browser_support() {
  chgrp onepassword /opt/1Password/1Password-BrowserSupport
  chmod g+s /opt/1Password/1Password-BrowserSupport
  [[ "$(stat -c '%G' /opt/1Password/1Password-BrowserSupport)" == "onepassword" ]]
}

cleanup() {
  dnf5 clean all
  rm -rf /var/cache/dnf
}

main() {
  install_repositories
  configure_onepassword_groups
  install_packages
  configure_nvidia_boot
  configure_shell_path
  configure_services
  verify_onepassword_browser_support
  cleanup
}

main "$@"
