#!/bin/bash

set -ouex pipefail

### Copy static files from build_files/files to root
cp -r /ctx/files/* / || true

### Pre-create system groups with fixed GIDs before package installation
# This ensures consistent group ownership across rebases and different installations
# The groups are defined in /usr/lib/sysusers.d/bazzite-dkub.conf
systemd-sysusers

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a package from fedora repos
# dnf5 install -y tmux 

# Update VS Code to latest version (already installed in base image)
# Skip gpgcheck due to known issues with VS Code's GPG signature format
dnf5 update --nogpgcheck --enable-repo="vscode" -y code 

# Install dos programs becuase I use exFAT stuff a lot
dnf5 install -y dosfstools exfatprogs

# Install ShellCheck for shell script linting during development and CI
dnf5 install -y ShellCheck

# Install 1Password (GUI app and CLI tool)
# Repo file is installed via static files in /etc/yum.repos.d/1password.repo
# Use optfix pattern: packages install to /usr/lib/opt, symlinked to /var/opt at runtime
rpm --import https://downloads.1password.com/linux/keys/1password.asc

# Create the optfix symlink structure for 1Password
# This mimics BlueBuild's optfix approach for handling /opt installations
# Note: /opt -> /var/opt symlink already exists in base image
mkdir -p /var/opt

# Create directory in /usr/lib/opt (immutable location) and symlink from /var/opt
mkdir -p /usr/lib/opt/1Password
ln -sf /usr/lib/opt/1Password /var/opt/1Password

# Install 1Password packages - they will install to /opt/1Password which resolves correctly
dnf5 install -y 1password 1password-cli

# Fix 1Password-BrowserSupport permissions during build (can't fix at runtime due to immutable /usr)
# The binary must be owned by the onepassword group with setgid for browser integration
BROWSER_SUPPORT_PATH="/usr/lib/opt/1Password/1Password-BrowserSupport"
if [ -f "$BROWSER_SUPPORT_PATH" ]; then
  chgrp onepassword "$BROWSER_SUPPORT_PATH"
  chmod g+s "$BROWSER_SUPPORT_PATH"
  echo "Set correct permissions on 1Password-BrowserSupport during build"
fi

# Enable optfix service to recreate symlinks at boot if needed
systemctl enable optfix.service

# Install Google Chrome
# Repo file is installed via static files in /etc/yum.repos.d/google-chrome.repo
# Use optfix pattern for /opt/google installation
rpm --import https://dl.google.com/linux/linux_signing_key.pub

# Create directory in /usr/lib/opt (immutable location) and symlink from /var/opt
mkdir -p /usr/lib/opt/google
ln -sf /usr/lib/opt/google /var/opt/google

# Install Google Chrome - it will install to /opt/google/chrome which resolves correctly
dnf5 install -y google-chrome-stable

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

## Clean up
# Remove DNF cache and metadata to keep /var clean in immutable image
# DNF will recreate these directories at runtime if needed
dnf5 clean all --enablerepo="*"
rm -rf /var/lib/dnf
rm -rf /var/cache/dnf

#### Example for enabling a System Unit File

# systemctl enable podman.socket
