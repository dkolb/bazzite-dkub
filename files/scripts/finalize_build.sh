#!/bin/sh
set -oue
if ! grep -qE '^docker:' /etc/group; then
  grep -E '^docker:' /usr/lib/group >> /etc/group
fi

exit 0