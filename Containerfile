# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /

# Pre-step: compile kmod-nvidia-open against the base's exact kernel.
# NVIDIA driver version is the literal below; bump it here when upgrading.
FROM quay.io/fedora/fedora-silverblue:44 AS akmods
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/kmod-build.sh 595.58.03

# Base Image
FROM quay.io/fedora/fedora-silverblue:44


### [IM]MUTABLE /opt
RUN rm /opt && mkdir /opt

### MODIFICATIONS
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=bind,from=akmods,source=/out,target=/akmods-out,ro \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh
    
### LINTING
RUN bootc container lint
