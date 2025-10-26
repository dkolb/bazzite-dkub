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

# Install 1Password CLI using the official repository (per YUM instructions)
rpm --import https://downloads.1password.com/linux/keys/1password.asc
dnf5 install -y 1password-cli

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
