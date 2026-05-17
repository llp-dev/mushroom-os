#!/usr/bin/env bash

set -Eeuo pipefail

readonly K6_VERSION="${1:?k6 version required as positional arg}"
FEDORA_RELEASE="$(rpm -E %fedora)"
NEXT_FEDORA_RELEASE=$((FEDORA_RELEASE + 1))
readonly FEDORA_RELEASE NEXT_FEDORA_RELEASE

readonly K6_RPM_URL="https://github.com/grafana/k6/releases/download/v${K6_VERSION}/k6-v${K6_VERSION}-linux-amd64.rpm"

readonly -a COPR_REPOS=(
	jdxcode/mise
	atim/starship
	dejan/lazygit
)

readonly -a SYSTEM_PACKAGES=(
	clevis
	clevis-pin-pkcs11
	clevis-pin-tpm2
	clevis-pin-trustee
	clevis-systemd
	glx-utils
	gnome-tweaks
	grub2-tools-extra
	podman-compose
	podman-docker
	ptyxis
	rclone
	xorriso
)

readonly -a CLI_PACKAGES=(
	1password
	1password-cli
	7zip
	bat
	btop
	fd-find
	fzf
	gh
	git
	git-delta
	google-chrome-stable
	htop
	hyperfine
	jq
	lazygit
	markdown
	mise
	neovim
	pandoc
	ripgrep
	screen
	ShellCheck
	starship
	stow
	tokei
	unzip
	wl-clipboard
	zip
	zsh
)

readonly -a C_PACKAGES=(
	autoconf
	automake
	bear
	binutils
	ccache
	cmake
	gcc
	gdb
	ltrace
	make
	meson
	ninja-build
	perf
	pkgconf-pkg-config
	strace
	valgrind
)

readonly -a CPP_PACKAGES=(
	clang
	clang-tools-extra
	gcc-c++
	cppcheck
	fontconfig-devel
	glslang
	libX11-devel
	libXcursor-devel
	libXext-devel
	libXfixes-devel
	libXft-devel
	libXinerama-devel
	libXrender-devel
	libstdc++-docs
	libstdc++-static
	libtool
	lld
	lldb
	mold
)

readonly -a JAVA_PACKAGES=(
	temurin-25-jdk
)

readonly -a GO_PACKAGES=(
	golang
	gopls
	"${K6_RPM_URL}"
)

readonly -a LUA_PACKAGES=(
	compat-lua
	lua
	luajit
	luarocks
)

readonly -a PYTHON_PACKAGES=(
	black
	python3-isort
	python3-openpyxl
	python3-pip
	python3-pyflakes
	python3-pytest
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
	nvidia_kmod_rpms=(/akmods-out/RPMS/mushroom-kmod-nvidia-open-*.rpm)
	[[ -e "${nvidia_kmod_rpms[0]}" ]]

	dnf5 install -y \
		--setopt=install_weak_deps=False \
		--exclude='kmod-nvidia*' \
		--exclude='akmod-nvidia*' \
		@virtualization \
		"${SYSTEM_PACKAGES[@]}" \
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
		"xorg-x11-drv-nvidia-cuda-libs-${nvidia_version}-*" \
		"nvidia-modprobe-${nvidia_version}-*" \
		"nvidia-persistenced-${nvidia_version}-*" \
		"nvidia-settings-${nvidia_version}-*"

	rpm -q "mushroom-kmod-nvidia-open-${nvidia_version}" >/dev/null
	rpm -q "xorg-x11-drv-nvidia-${nvidia_version}" >/dev/null
}

configure_nvidia_boot() {
	install -Dm0644 /dev/stdin /etc/modprobe.d/nvidia.conf <<'EOF'
blacklist nouveau
options nvidia-drm modeset=1 fbdev=1
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
	systemctl enable libvirtd
	systemctl enable nvidia-powerd.service
	systemctl enable nvidia-persistenced.service
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
