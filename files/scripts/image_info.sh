#!/usr/bin/env bash
set -ueo pipefail

echo Recreating image info

mv /usr/share/ublue-os/image-info.json /usr/share/ublue-os/bazzite-image-info.json
/usr/libexec/containerbuild/image-info
