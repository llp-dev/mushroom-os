ARG FEDORA_VERSION=44
ARG NVIDIA_VERSION=595.58.03
ARG K6_VERSION=1.7.1

FROM scratch AS ctx-base
COPY build_files /

FROM quay.io/fedora/fedora-silverblue:${FEDORA_VERSION} AS akmods
ARG NVIDIA_VERSION
RUN --mount=type=bind,from=ctx-base,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build-kmod.sh "${NVIDIA_VERSION}"

FROM quay.io/fedora/fedora-silverblue:${FEDORA_VERSION}
ARG K6_VERSION

RUN rm /opt && mkdir /opt

RUN --mount=type=bind,from=ctx-base,source=/,target=/ctx \
    --mount=type=bind,from=akmods,source=/out,target=/akmods-out,ro \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build-base.sh "${K6_VERSION}"

RUN bootc container lint
