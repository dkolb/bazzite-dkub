ARG BASE_IMAGE_NAME
ARG BASE_IMAGE_REGISTRY
ARG BASE_IMAGE_TAG
ARG FEDORA_VERSION

FROM scratch AS scripts
COPY files/scripts /scripts

FROM ${BASE_IMAGE_REGISTRY}/${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG}

ARG BASE_IMAGE_FLAVOR
ARG BASE_IMAGE_NAME
ARG BASE_IMAGE_TAG
ARG BASE_IMAGE_VERSION
ARG FEDORA_VERSION
ARG GIT_REPO
ARG IMAGE_BRANCH
ARG IMAGE_NAME
ARG IMAGE_NAME
ARG IMAGE_REGISTRY
ARG IMAGE_VENDOR
ARG SHA_HEAD_SHORT
ARG VERSION_PRETTY
ARG VERSION_TAG

COPY files/system /

RUN --mount=type=cache,dst=/var/cache/rpm-ostree,id=rpm-ostree-cache,sharing=locked \
  rpm-ostree install \
    code \
    hardinfo2 \
    firefox \
    && \
  ostree container commit

RUN --mount=type=bind,from=scripts,src=/scripts,dst=/tmp/scripts,rw \
    --mount=type=cache,dst=/var/cache/rpm-ostree,id=rpm-ostree-cache,sharing=locked \
  bash /tmp/scripts/install_1password.sh && \
  bash /tmp/scripts/justfiles.sh && \
  bash /tmp/scripts/image_info.sh && \
  bash /tmp/scripts/container_policy.sh