#!/usr/bin/bash

source /usr/lib/ublue/setup-services/libsetup.sh

version-script browsers-1password-setup user 1 || exit 0

# Copy systemd unit from skel if it doesn't exist
SERVICE_DIR="${HOME}/.config/systemd/user"
SERVICE_FILE="${SERVICE_DIR}/browsers-1password-setup.service"
SKEL_SERVICE="/etc/skel/.config/systemd/user/browsers-1password-setup.service"

if [[ ! -f "${SERVICE_FILE}" && -f "${SKEL_SERVICE}" ]]; then
    echo "Installing browsers-1password-setup.service for user"
    mkdir -p "${SERVICE_DIR}"
    cp "${SKEL_SERVICE}" "${SERVICE_FILE}"
fi

# Enable the browsers-1password-setup service for this user
# This will create the distrobox if it doesn't exist on first login
systemctl --user enable browsers-1password-setup.service || true
