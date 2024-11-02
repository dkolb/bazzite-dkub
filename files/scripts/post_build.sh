#!/bin/sh
/usr/libexec/containerbuild/image-info

if ! grep -qE '^docker:' /etc/group; then
  grep -E '^docker:' /usr/lib/group >> /etc/group
fi