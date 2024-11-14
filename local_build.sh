#!/usr/bin/env bash
buildah build \
  --build-arg BASE_IMAGE_FLAVOR="main" \
  --build-arg BASE_IMAGE_NAME="bazzite-gnome" \
  --build-arg BASE_IMAGE_REGISTRY='ghcr.io/ublue-os' \
  --build-arg BASE_IMAGE_TAG='stable' \
  --build-arg BASE_IMAGE_VERSION="41.20241101.0" \
  --build-arg FEDORA_VERSION="41" \
  --build-arg GIT_REPO="https://github.com/dkolb/bazzite-dkub" \
  --build-arg IMAGE_BRANCH="local" \
  --build-arg IMAGE_NAME='bazzite-dkub' \
  --build-arg IMAGE_REGISTRY='ghcr.io/dkolb' \
  --build-arg IMAGE_VENDOR="dkolb" \
  --build-arg SHA_HEAD_SHORT="abcdef1" \
  --build-arg VERSION_PRETTY="Local Build (41.20241101)" \
  --build-arg VERSION_TAG="20241101" \
  -t localhost/bazzite-dkub:local \
  .