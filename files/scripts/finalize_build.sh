#!/bin/sh
set -oue
mv /usr/share/ublue-os/image-info.json /usr/share/ublue-os/bazzite-image-info.json
/usr/libexec/containerbuild/image-info
KERNEL_FLAVOR=bazzite /usr/libexec/containerbuild/build-initramfs

if ! grep -qE '^docker:' /etc/group; then
  # There may not be a docker group to copy to /etc, so 
  # || true hides the failed status.
  grep -E '^docker:' /usr/lib/group >> /etc/group || true 
fi

exit 0