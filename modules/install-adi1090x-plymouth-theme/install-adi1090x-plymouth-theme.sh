#!/usr/bin/env bash
set -euo pipefail

get_json_array THEMES 'try .["themes"][]' "$1"

# Get the latest release tag from GitHub API
LATEST_RELEASE=$(curl -s https://api.github.com/repos/adi1090x/plymouth-themes/releases/latest | jq -r .tag_name)

echo "Downloading and installing plymouth themes from adi1090x/plymouth-themes@${LATEST_RELEASE}..."

for theme in "${THEMES[@]}"; do
  # Construct the download URL
  DOWNLOAD_URL="https://github.com/adi1090x/plymouth-themes/releases/download/${LATEST_RELEASE}/${theme}.tar.gz"

  echo "Downloading ${theme} from ${DOWNLOAD_URL}..."
  
  # Download the file
  curl -L -o "/tmp/${theme}.tgz" "$DOWNLOAD_URL"

  echo "Extracting ${theme} to /usr/share/plymouth/themes..."
  
  # Extract the file to /usr/share/plymouth/themes
  tar -xzvf "/tmp/${theme}.tgz" -C /usr/share/plymouth/themes
  
  # Clean up the file in /tmp
  rm -v "/tmp/${theme}.tgz"
done
