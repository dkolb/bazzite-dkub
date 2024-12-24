#!/usr/bin/env bash
set -euo pipefail

SET_THEME="$(echo "$1" | jq -r 'try .["theme"]')"

# Install the plymouth-plugin-script package if not installed
if rpm -q plymouth-plugin-script &> /dev/null; then
  echo "The plymouth-plugin-script package is already installed."
else
  echo "Installing the plymouth-plugin-script package..."
  rpm-ostree install plymouth-plugin-script
fi



# Set the default plymouth theme
if [ "$SET_THEME" != "null" ]; then
  if [ -d "/usr/share/plymouth/themes/${SET_THEME}/" ]; then
    echo "Setting the default plymouth theme to ${SET_THEME}..."
    plymouth-set-default-theme "$SET_THEME"
    # plymouth-set-default-theme -R "$SET_THEME"
  else
    echo "The plymouth theme ${SET_THEME} does not exist."
    exit 1
  fi
else
  echo "theme input was not specified"
  exit 1
fi