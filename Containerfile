# Two ctx aggregator stages so editing build_files/dev/ does not bust the
# bind-mount cache on the base RUN. Stable layer = base, volatile layer = dev.
FROM scratch AS ctx-base
COPY build_files/base /

FROM scratch AS ctx-dev
COPY build_files/dev /

# Pre-step: compile kmod-nvidia-open against the base's exact kernel.
# NVIDIA driver version is the literal below; bump it here when upgrading.
FROM quay.io/fedora/fedora-silverblue:44 AS akmods
RUN --mount=type=bind,from=ctx-base,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/kmod-build.sh 595.58.03

# Base Image
FROM quay.io/fedora/fedora-silverblue:44


### [IM]MUTABLE /opt
RUN rm /opt && mkdir /opt

### STABLE LAYER (base toolchain, NVIDIA, services)
RUN --mount=type=bind,from=ctx-base,source=/,target=/ctx \
    --mount=type=bind,from=akmods,source=/out,target=/akmods-out,ro \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build-base.sh

### VOLATILE LAYER (personal dev tools, swappable)
RUN --mount=type=bind,from=ctx-dev,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build-dev.sh

### LINTING
RUN bootc container lint
