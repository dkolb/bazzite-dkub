#!/bin/bash

set -ouex pipefail

### Copy static files from build_files/files to root
cp -r /ctx/files/* / || true

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

# Enable optfix service to recreate symlinks at boot if needed
systemctl enable optfix.service

# Install AppImages to ~/AppImages directory
mkdir -p /etc/skel/AppImages

# Download Pinokio AppImage (AI Browser)
curl -L "https://github.com/pinokiocomputer/pinokio/releases/latest/download/Pinokio-linux-x86_64.AppImage" \
  -o /etc/skel/AppImages/pinokio.appimage
chmod +x /etc/skel/AppImages/pinokio.appimage

# Download MediaElch AppImage (Media Manager for Kodi)
curl -L "https://github.com/Komet/MediaElch/releases/latest/download/MediaElch_linux_x86_64.AppImage" \
  -o /etc/skel/AppImages/mediaelch.appimage
chmod +x /etc/skel/AppImages/mediaelch.appimage

# Download VeraCrypt AppImage (Disk Encryption)
curl -L "https://github.com/veracrypt/VeraCrypt/releases/latest/download/VeraCrypt-1.26.16-x86_64.AppImage" \
  -o /etc/skel/AppImages/veracrypt.appimage
chmod +x /etc/skel/AppImages/veracrypt.appimage

# Download LM Studio AppImage (Local AI)
curl -L "https://installers.lmstudio.ai/linux/x64/0.3.29-1/LM-Studio-0.3.29-1-x64.AppImage" \
  -o /etc/skel/AppImages/lm_studio.appimage
chmod +x /etc/skel/AppImages/lm_studio.appimage

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
