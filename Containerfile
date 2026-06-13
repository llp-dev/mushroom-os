ARG FEDORA_VERSION=44
ARG NVIDIA_VERSION=595.58.03

FROM scratch AS ctx-base
COPY build_files /

FROM quay.io/fedora/fedora-silverblue:${FEDORA_VERSION} AS akmods
ARG NVIDIA_VERSION
RUN --mount=type=bind,from=ctx-base,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build-kmod.sh "${NVIDIA_VERSION}"

FROM quay.io/fedora/fedora-silverblue:${FEDORA_VERSION} AS akmods-wl
RUN --mount=type=bind,from=ctx-base,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build-wl.sh

FROM quay.io/fedora/fedora-silverblue:${FEDORA_VERSION}

RUN rm /opt && mkdir /opt

RUN --mount=type=bind,from=ctx-base,source=/,target=/ctx \
    --mount=type=bind,from=akmods,source=/out,target=/akmods-out,ro \
    --mount=type=bind,from=akmods-wl,source=/out,target=/akmods-wl-out,ro \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build-base.sh

RUN bootc container lint
