#!/usr/bin/env bash

set -Eeuo pipefail

readonly NVIDIA_VERSION="${1:?NVIDIA driver version required as positional arg}"
KERNEL_RELEASE="$(rpm -q --qf '%{VERSION}-%{RELEASE}.%{ARCH}' kernel-core)"
FEDORA_RELEASE="$(rpm -E %fedora)"
readonly KERNEL_RELEASE FEDORA_RELEASE

readonly SRC_DIR=/tmp/open-gpu-kernel-modules
readonly STAGING_DIR=/tmp/staging
readonly RPMBUILD_DIR=/tmp/rpmbuild
readonly OUT_DIR=/out

readonly -a BUILD_PACKAGES=(
	"kernel-devel-${KERNEL_RELEASE}"
	gcc
	gcc-c++
	git
	make
	rpm-build
)

readonly -a NVIDIA_MODULES=(
	nvidia.ko
	nvidia-drm.ko
	nvidia-modeset.ko
	nvidia-uvm.ko
	nvidia-peermem.ko
)

write_build_metadata() {
	mkdir -p "$OUT_DIR"
	printf '%s\n' "$KERNEL_RELEASE" >"${OUT_DIR}/kver"
	printf '%s\n' "$NVIDIA_VERSION" >"${OUT_DIR}/nvidia-version"
}

install_build_dependencies() {
	dnf5 install -y --setopt=best=true "${BUILD_PACKAGES[@]}"
	rpm -q "kernel-devel-${KERNEL_RELEASE}" >/dev/null
}

build_modules() {
	git clone --depth=1 --branch "$NVIDIA_VERSION" \
		https://github.com/NVIDIA/open-gpu-kernel-modules.git "$SRC_DIR"

	make -C "$SRC_DIR" modules \
		SYSSRC="/usr/src/kernels/${KERNEL_RELEASE}" \
		-j"$(nproc)"
}

stage_modules() {
	local module src vermagic
	local module_dir="${STAGING_DIR}/usr/lib/modules/${KERNEL_RELEASE}/extra/nvidia"

	mkdir -p "$module_dir"

	for module in "${NVIDIA_MODULES[@]}"; do
		src="$(find "$SRC_DIR" -name "$module" -type f -print -quit)"
		[[ -n "$src" && -f "$src" ]] || {
			printf 'missing %s\n' "$module" >&2
			exit 1
		}

		vermagic="$(modinfo -F vermagic "$src")"
		[[ "$vermagic" == "${KERNEL_RELEASE} "* ]] || {
			printf 'vermagic mismatch on %s: got [%s], expected %s ...\n' \
				"$module" "$vermagic" "$KERNEL_RELEASE" >&2
			exit 1
		}

		cp "$src" "$module_dir/"
	done
}

write_rpm_spec() {
	mkdir -p \
		"${RPMBUILD_DIR}/SPECS" \
		"${RPMBUILD_DIR}/SOURCES" \
		"${RPMBUILD_DIR}/BUILD" \
		"${RPMBUILD_DIR}/BUILDROOT" \
		"${RPMBUILD_DIR}/RPMS" \
		"${RPMBUILD_DIR}/SRPMS"

	install -Dm0644 /dev/stdin "${RPMBUILD_DIR}/SPECS/mushroom-kmod-nvidia-open.spec" <<EOF
Name:           mushroom-kmod-nvidia-open
Version:        ${NVIDIA_VERSION}
Release:        1.fc${FEDORA_RELEASE}
Summary:        NVIDIA open-source kernel modules built from upstream for ${KERNEL_RELEASE}
License:        MIT AND GPL-2.0-only
BuildArch:      x86_64

Epoch:          3
Provides:       nvidia-kmod = %{epoch}:%{version}
Provides:       nvidia-kmod-common = %{epoch}:%{version}
Provides:       kmod-nvidia-open = %{epoch}:%{version}-%{release}
Provides:       kmod-nvidia-open-${KERNEL_RELEASE} = %{epoch}:%{version}-%{release}

Requires:       kernel-core-uname-r = ${KERNEL_RELEASE}

%description
NVIDIA open-source kernel modules built from upstream tag %{version}
against ${KERNEL_RELEASE}. The package provides the kmod capabilities
required by RPM Fusion's NVIDIA userspace RPMs.

%install
cp -a ${STAGING_DIR}/* %{buildroot}/

%post
/usr/sbin/depmod -a ${KERNEL_RELEASE} || :

%postun
/usr/sbin/depmod -a ${KERNEL_RELEASE} || :

%files
/usr/lib/modules/${KERNEL_RELEASE}/extra/nvidia/nvidia.ko
/usr/lib/modules/${KERNEL_RELEASE}/extra/nvidia/nvidia-drm.ko
/usr/lib/modules/${KERNEL_RELEASE}/extra/nvidia/nvidia-modeset.ko
/usr/lib/modules/${KERNEL_RELEASE}/extra/nvidia/nvidia-uvm.ko
/usr/lib/modules/${KERNEL_RELEASE}/extra/nvidia/nvidia-peermem.ko
EOF
}

package_modules() {
	rpmbuild -bb --define "_topdir ${RPMBUILD_DIR}" \
		"${RPMBUILD_DIR}/SPECS/mushroom-kmod-nvidia-open.spec"

	mkdir -p "${OUT_DIR}/RPMS"
	cp "${RPMBUILD_DIR}"/RPMS/x86_64/mushroom-kmod-nvidia-open-*.rpm "${OUT_DIR}/RPMS/"
	ls -la "${OUT_DIR}/RPMS/"
}

cleanup() {
	dnf5 clean all
}

main() {
	write_build_metadata
	install_build_dependencies
	build_modules
	stage_modules
	write_rpm_spec
	package_modules
	cleanup
}

main "$@"
