#!/usr/bin/env bash

set -Eeuo pipefail

KERNEL_RELEASE="$(rpm -q --qf '%{VERSION}-%{RELEASE}.%{ARCH}' kernel-core)"
FEDORA_RELEASE="$(rpm -E %fedora)"
readonly KERNEL_RELEASE FEDORA_RELEASE

readonly OUT_DIR=/out

# akmods drives kmodtool to build the Broadcom wl module against our exact
# kernel-devel tree, the same prebuilt-kmod approach used for NVIDIA. On a
# bootc image akmod-wl cannot rebuild on kernel updates, so the module must be
# baked in as a versioned kmod-wl RPM instead.
readonly -a BUILD_PACKAGES=(
	"kernel-devel-${KERNEL_RELEASE}"
	akmods
	gcc
	make
	rpm-build
)

write_build_metadata() {
	mkdir -p "$OUT_DIR"
	printf '%s\n' "$KERNEL_RELEASE" >"${OUT_DIR}/wl-kver"
}

install_repositories() {
	dnf5 install -y \
		"https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_RELEASE}.noarch.rpm" \
		"https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_RELEASE}.noarch.rpm"
}

install_build_dependencies() {
	dnf5 install -y --setopt=install_weak_deps=False "${BUILD_PACKAGES[@]}"
	rpm -q "kernel-devel-${KERNEL_RELEASE}" >/dev/null

	# akmod-wl's %post fails (it refuses to build as root); the package still
	# installs and we rebuild it via akmods below, so tolerate the exit code.
	dnf5 install -y --setopt=install_weak_deps=False akmod-wl || true
	rpm -q akmod-wl >/dev/null
}

build_module() {
	akmods --force --kernels "${KERNEL_RELEASE}" --kmod wl

	# Confirm the built module is tagged for our exact kernel before staging.
	local ko
	ko="$(find "/usr/lib/modules/${KERNEL_RELEASE}" -name 'wl.ko*' -print -quit || true)"
	[[ -n "$ko" ]] || {
		printf 'wl.ko not produced for %s\n' "$KERNEL_RELEASE" >&2
		exit 1
	}
}

stage_rpm() {
	local rpm
	rpm="$(find /var/cache/akmods -name "kmod-wl-${KERNEL_RELEASE}-*.rpm" -print -quit)"
	[[ -n "$rpm" && -f "$rpm" ]] || {
		printf 'kmod-wl rpm not found for %s\n' "$KERNEL_RELEASE" >&2
		find /var/cache/akmods -name '*.rpm' >&2 || true
		exit 1
	}

	mkdir -p "${OUT_DIR}/RPMS"
	cp "$rpm" "${OUT_DIR}/RPMS/"
	ls -la "${OUT_DIR}/RPMS/"
}

cleanup() {
	dnf5 clean all
}

main() {
	write_build_metadata
	install_repositories
	install_build_dependencies
	build_module
	stage_rpm
	cleanup
}

main "$@"
