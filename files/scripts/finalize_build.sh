#!/bin/sh
set -oue

if ! grep -qE '^docker:' /etc/group; then
  # There may not be a docker group to copy to /etc, so 
  # || true hides the failed status.
  grep -E '^docker:' /usr/lib/group >> /etc/group || true 
fi

exit 0