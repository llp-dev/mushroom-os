#!/bin/bash

set -eux

# 1. Capture base kernel NVRA + driver version (driver version is $1, set by Containerfile)
KVER=$(rpm -q --qf '%{VERSION}-%{RELEASE}.%{ARCH}' kernel-core)
NVIDIA_VERSION="${1:?NVIDIA driver version required as positional arg}"
mkdir -p /out
echo "$KVER" >/out/kver
echo "$NVIDIA_VERSION" >/out/nvidia-version

# 2. Toolchain pinned to the captured kernel.
# Note: kernel-headers is the userspace UAPI package (used by glibc) and is
# NOT version-locked to kernel-core. Only kernel-devel needs to match.
# gcc-c++ is needed because nvidia-modeset compiles dp_auxretry.cpp.
# rpm-build is needed for step 5 (packaging the .ko's into a real RPM).
dnf5 install -y --setopt=best=true \
	"kernel-devel-${KVER}" \
	gcc gcc-c++ make git rpm-build
rpm -q "kernel-devel-${KVER}" >/dev/null

# 3. Clone upstream NVIDIA at the pinned tag and build
git clone --depth=1 --branch "$NVIDIA_VERSION" \
	https://github.com/NVIDIA/open-gpu-kernel-modules.git /tmp/src
make -C /tmp/src modules SYSSRC="/usr/src/kernels/${KVER}" -j"$(nproc)"

# 4. Verify per-module vermagic and stage the .ko files
mkdir -p /tmp/staging/usr/lib/modules/"${KVER}"/extra/nvidia
for ko in nvidia.ko nvidia-drm.ko nvidia-modeset.ko nvidia-uvm.ko nvidia-peermem.ko; do
	src=$(find /tmp/src -name "$ko" -type f | head -1)
	[[ -f "$src" ]] || {
		echo "missing $ko"
		exit 1
	}
	vermagic=$(modinfo -F vermagic "$src")
	[[ "$vermagic" == "${KVER} "* ]] || {
		echo "vermagic mismatch on $ko: got [$vermagic], expected ${KVER} ..."
		exit 1
	}
	cp "$src" /tmp/staging/usr/lib/modules/"${KVER}"/extra/nvidia/
done

# 5. Package the .ko's into an RPM that Provides: nvidia-kmod, nvidia-kmod-common
# so RPM Fusion's xorg-x11-drv-nvidia userspace can satisfy its hard Requires
# without pulling in akmod-nvidia or kmod-nvidia siblings.
mkdir -p /tmp/rpmbuild/{SPECS,SOURCES,BUILD,BUILDROOT,RPMS,SRPMS}
cat >/tmp/rpmbuild/SPECS/mushroom-kmod-nvidia-open.spec <<EOF
Name:           mushroom-kmod-nvidia-open
Version:        ${NVIDIA_VERSION}
Release:        1.fc44
Summary:        NVIDIA open-source kernel modules built from upstream for ${KVER}
License:        MIT AND GPL-2.0-only
BuildArch:      x86_64

Epoch:          3
Provides:       nvidia-kmod = %{epoch}:%{version}
Provides:       nvidia-kmod-common = %{epoch}:%{version}
Provides:       kmod-nvidia-open = %{epoch}:%{version}-%{release}
Provides:       kmod-nvidia-open-${KVER} = %{epoch}:%{version}-%{release}

Requires:       kernel-core-uname-r = ${KVER}

%description
NVIDIA open-source kernel modules (nvidia, nvidia-drm, nvidia-modeset,
nvidia-uvm, nvidia-peermem) compiled from
https://github.com/NVIDIA/open-gpu-kernel-modules at tag %{version}
against the locked kernel ${KVER}. Built in the mushroom-os akmods
Containerfile stage; carries the Provides metadata that RPM Fusion's
xorg-x11-drv-nvidia userspace needs.

%install
cp -a /tmp/staging/* %{buildroot}/

%post
/usr/sbin/depmod -a ${KVER} || :

%postun
/usr/sbin/depmod -a ${KVER} || :

%files
/usr/lib/modules/${KVER}/extra/nvidia/nvidia.ko
/usr/lib/modules/${KVER}/extra/nvidia/nvidia-drm.ko
/usr/lib/modules/${KVER}/extra/nvidia/nvidia-modeset.ko
/usr/lib/modules/${KVER}/extra/nvidia/nvidia-uvm.ko
/usr/lib/modules/${KVER}/extra/nvidia/nvidia-peermem.ko
EOF

rpmbuild -bb --define "_topdir /tmp/rpmbuild" \
	/tmp/rpmbuild/SPECS/mushroom-kmod-nvidia-open.spec

mkdir -p /out/RPMS
cp /tmp/rpmbuild/RPMS/x86_64/mushroom-kmod-nvidia-open-*.rpm /out/RPMS/
ls -la /out/RPMS/

dnf5 clean all
