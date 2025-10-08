# Static Files Directory

This directory contains static files that should be copied to the image during build.

## Structure

Files in this directory mirror the final filesystem structure. For example:

- `files/etc/skel/.local/bin/script.sh` → `/etc/skel/.local/bin/script.sh` in the image
- `files/etc/skel/.config/autostart/app.desktop` → `/etc/skel/.config/autostart/app.desktop` in the image

## How It Works

The `build.sh` script copies everything from this directory to the root filesystem at the beginning:

```bash
cp -r /ctx/files/* / || true
```

## Current Files

### GearLever Integration
- **`etc/skel/.local/bin/gearlever-integrate.sh`** - Script that integrates pre-installed AppImages with GearLever on first user login
- **`etc/skel/.config/autostart/gearlever-integrate-appimages.desktop`** - XDG autostart entry to run the integration script

### System Configuration
- **`usr/lib/sysusers.d/onepassword-cli.conf`** - systemd sysusers.d declaration for the onepassword-cli group (ensures proper immutable OS integration)
- **`etc/yum.repos.d/1password.repo`** - 1Password CLI repository configuration

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
