#!/bin/sh
set -oue
/usr/libexec/containerbuild/image-info &&
KERNEL_FLAVOR=bazzite /usr/libexec/containerbuild/build-initramfs

if ! grep -qE '^docker:' /etc/group; then
  grep -E '^docker:' /usr/lib/group >> /etc/group
fi