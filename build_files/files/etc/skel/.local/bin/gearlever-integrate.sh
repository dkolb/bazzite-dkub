#!/bin/bash
# GearLever AppImage Integration Script
# Automatically installs GearLever and integrates pre-installed AppImages on first login

set -euo pipefail

# Marker file to track if integration has been completed
MARKER_FILE="$HOME/.config/gearlever-integrated"

# Check if already integrated
if [ -f "$MARKER_FILE" ]; then
    exit 0
fi

# Check if AppImages directory exists
if [ ! -d "$HOME/AppImages" ]; then
    exit 0
fi

# Wait for desktop environment to fully load
sleep 5

# Install GearLever if not already installed
if ! flatpak list | grep -q "it.mijorus.gearlever"; then
    echo "Installing GearLever flatpak..."
    flatpak install -y --user flathub it.mijorus.gearlever
fi

# Array of AppImages to integrate
APPIMAGES=(
    "$HOME/AppImages/pinokio.appimage"
    "$HOME/AppImages/mediaelch.appimage"
    "$HOME/AppImages/veracrypt.appimage"
    "$HOME/AppImages/lm_studio.appimage"
)

# Integrate each AppImage with GearLever
for appimage in "${APPIMAGES[@]}"; do
    if [ -f "$appimage" ]; then
        echo "Integrating $appimage with GearLever..."
        flatpak run --user it.mijorus.gearlever --integrate "$appimage" --yes || true
    fi
done

# Create marker file to prevent re-running
touch "$MARKER_FILE"

echo "GearLever integration complete!"
