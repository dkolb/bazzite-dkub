# Static Files Directory

This directory contains static files that should be copied to the image during build.

## Structure

Files in this directory mirror the final filesystem structure. For example:

- `files/usr/share/ublue-os/just/60-custom.just` → `/usr/share/ublue-os/just/60-custom.just` in the image
- `files/etc/yum.repos.d/1password.repo` → `/etc/yum.repos.d/1password.repo` in the image

## How It Works

The `build.sh` script copies everything from this directory to the root filesystem at the beginning:

```bash
cp -r /ctx/files/* / || true
```

## Current Files

### Custom ujust Recipes
- **`usr/share/ublue-os/just/60-custom.just`** - Custom just recipes for optional AppImage installation
  - `ujust install-appimages` - Install all common AppImages
  - `ujust install-pinokio`, `ujust install-mediaelch`, etc. - Install individual AppImages
  - `ujust install-gearlever` - Install GearLever AppImage manager

### System Configuration
- **`usr/lib/sysusers.d/onepassword-cli.conf`** - systemd sysusers.d declaration for the onepassword-cli group (ensures proper immutable OS integration)
- **`usr/lib/sysusers.d/bazzite-dkub.conf`** - systemd sysusers.d declaration for bazzite-dkub-specific groups
- **`etc/yum.repos.d/1password.repo`** - 1Password repository configuration
- **`etc/yum.repos.d/google-chrome.repo`** - Google Chrome repository configuration

### 1Password Optfix
- **`usr/lib/systemd/system/optfix.service`** - Systemd service for optfix
- **`usr/libexec/optfix.sh`** - Script to fix /opt symlinks on boot
- **`usr/lib/tmpfiles.d/optfix.conf`** - Tmpfiles.d configuration for optfix

## Adding New Static Files

To add new static files to the image:

1. Create the directory structure under `files/` matching where it should go in the image
2. Place your file(s) in the appropriate location
3. They will be automatically copied during the build process

Example:
```bash
# To add a systemd service
mkdir -p files/etc/systemd/system/
cp my-service.service files/etc/systemd/system/

# To add a config file to /etc
mkdir -p files/etc/myapp/
cp myconfig.conf files/etc/myapp/
```
