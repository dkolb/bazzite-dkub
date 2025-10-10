# bazzite-dkub

A customized [bootc](https://github.com/bootc-dev/bootc) image based on [Bazzite-DX](https://github.com/ublue-os/bazzite-dx) with personal productivity enhancements.

## Customizations

This image extends Bazzite-DX with the following modifications:

### Software Updates
- **VS Code**: Automatically updated to the latest version during build (bypasses GPG check for compatibility)
- **File System Tools**: Enhanced exFAT and DOS filesystem support via `dosfstools` and `exfatprogs`
- **ShellCheck**: Pre-installed for shell script linting in the image and CI
- **1Password**: Full GUI application and CLI installed for password and secret management
  - Includes `1password-flatpak-browser-integration` script for easy Flatpak browser setup
  - Run `1password-flatpak-browser-integration` to configure 1Password with your Flatpak browsers
- **GearLever**: Flatpak AppImage manager automatically installed on first user login for easy AppImage integration
- **Pre-installed AppImages** (auto-integrated with GearLever on first login):
  - **Pinokio** (v3.9.0): AI Browser for running local AI applications
  - **MediaElch** (v2.12.0): Media Manager for Kodi
  - **VeraCrypt** (v1.26.16): Disk encryption software
  - **LM Studio** (v0.3.29): Local AI model runner
  
  *Note: AppImages are automatically integrated with GearLever on first login, enabling update tracking and management.*

### Base Image
- Built on `ghcr.io/ublue-os/bazzite-dx:stable` - includes development tools, Docker, and other productivity software out of the box

### Build Features
- Automated container signing with Cosign
- Multi-architecture support ready
- Continuous integration via GitHub Actions

## Quick Start

If you want to use this image directly:

```bash
# Switch to this image (requires a bootc-compatible system)
sudo bootc switch ghcr.io/dkolb/bazzite-dkub:latest

# Reboot to apply changes
sudo systemctl reboot
```

## Development

### Prerequisites
- A bootc-compatible system (Bazzite, Bluefin, Aurora, or Fedora Atomic)
- Git and basic development tools
- [just](https://just.systems/) command runner (pre-installed on Universal Blue images)

### Local Development

1. **Clone the repository:**
   ```bash
   git clone git@github.com:dkolb/bazzite-dkub.git
   cd bazzite-dkub
   ```

2. **Build locally for testing:**
   ```bash
   just build
   ```

3. **Test in a VM (optional):**
   ```bash
   just build-qcow2
   just run-vm-qcow2
   ```

### Making Changes

1. **Add packages or customizations** in `build_files/build.sh`
2. **Test locally** with `just build`
3. **Commit and push** changes - GitHub Actions will automatically build and publish the image

## Repository Structure

### Key Files

- **[Containerfile](./Containerfile)** - Main image definition, follows Podman/Docker conventions
- **[build_files/build.sh](./build_files/build.sh)** - Custom package installations and system modifications
- **[build_files/files/](./build_files/files/)** - Static files copied to the image (mirrors filesystem structure)
- **[Justfile](./Justfile)** - Build commands and development workflows
- **[.github/workflows/build.yml](./.github/workflows/build.yml)** - Automated CI/CD pipeline
- **[disk_config/](./disk_config/)** - Configuration for generating ISO/VM images

### Adding New Software

To add new packages or customizations:

1. **Edit `build_files/build.sh`** to add your installation commands:
   ```bash
   # Example: Install additional packages
   dnf5 install -y neovim fish-shell
   
   # Example: Enable a systemd service
   systemctl enable my-custom-service
   ```

2. **Update this README** to document what you've added
3. **Test locally** with `just build`
4. **Commit and push** - the image will be automatically built and published

### Available Commands

- `just build` - Build the container image locally
- `just build-iso` - Create a bootable ISO image  
- `just build-qcow2` - Create a VM disk image
- `just run-vm-qcow2` - Test the image in a VM
- `just clean` - Clean up build artifacts
- `just lint` - Check shell script syntax
- `just format` - Format shell scripts

## Advanced Features

### Building Disk Images

Create bootable ISOs and VM images for installation or testing:

- **ISO Images**: `just build-iso` - Creates a bootable installation ISO
- **VM Images**: `just build-qcow2` - Creates QCOW2 images for virtualization
- **Raw Images**: `just build-raw` - Creates raw disk images

### Container Signing

All images are automatically signed with [Cosign](https://docs.sigstore.dev/cosign/overview/) for security verification. The signing happens automatically in GitHub Actions.

### Continuous Integration

Every push to `main` triggers:
1. Image build and test
2. Container signing
3. Publication to GitHub Container Registry
4. Optional disk image generation

## Community Resources

- [Universal Blue Forums](https://universal-blue.discourse.group/) - Community support and discussions
- [Universal Blue Discord](https://discord.gg/WEu6BdFEtp) - Real-time chat and help
- [bootc Documentation](https://github.com/bootc-dev/bootc/discussions) - Technical discussions about bootc

## Contributing

This is a personal image, but feel free to:
- Open issues for bugs or suggestions
- Submit pull requests for improvements
- Fork and create your own variant

## What's Included from Bazzite-DX

The base [Bazzite-DX](https://github.com/ublue-os/bazzite-dx) image includes:
- Full development environment with common tools
- Docker and container development support
- VS Code and development extensions
- Gaming capabilities from base Bazzite
- Hardware-optimized drivers

# Justfile Documentation

The `Justfile` contains various commands and configurations for building and managing container images and virtual machine images using Podman and other utilities.
To use it, you must have installed [just](https://just.systems/man/en/introduction.html) from your package manager or manually. It is available by default on all Universal Blue images.

## Environment Variables

- `image_name`: The name of the image (default: "image-template").
- `default_tag`: The default tag for the image (default: "latest").
- `bib_image`: The Bootc Image Builder (BIB) image (default: "quay.io/centos-bootc/bootc-image-builder:latest").

## Building The Image

### `just build`

Builds a container image using Podman.

```bash
just build $target_image $tag
```

Arguments:
- `$target_image`: The tag you want to apply to the image (default: `$image_name`).
- `$tag`: The tag for the image (default: `$default_tag`).

## Building and Running Virtual Machines and ISOs

The below commands all build QCOW2 images. To produce or use a different type of image, substitute in the command with that type in the place of `qcow2`. The available types are `qcow2`, `iso`, and `raw`.

### `just build-qcow2`

Builds a QCOW2 virtual machine image.

```bash
just build-qcow2 $target_image $tag
```

### `just rebuild-qcow2`

Rebuilds a QCOW2 virtual machine image.

```bash
just rebuild-vm $target_image $tag
```

### `just run-vm-qcow2`

Runs a virtual machine from a QCOW2 image.

```bash
just run-vm-qcow2 $target_image $tag
```

### `just spawn-vm`

Runs a virtual machine using systemd-vmspawn.

```bash
just spawn-vm rebuild="0" type="qcow2" ram="6G"
```

## File Management

### `just check`

Checks the syntax of all `.just` files and the `Justfile`.

### `just fix`

Fixes the syntax of all `.just` files and the `Justfile`.

### `just clean`

Cleans the repository by removing build artifacts.

### `just lint`

Runs shell check on all Bash scripts.

### `just format`

Runs shfmt on all Bash scripts.

## Community Examples

These are images derived from this template (or similar enough to this template). Reference them when building your image!

---

## Technical Details

### Image Information
- **Base Image**: `ghcr.io/ublue-os/bazzite-dx:stable`
- **Registry**: `ghcr.io/dkolb/bazzite-dkub`
- **Repository**: <https://github.com/dkolb/bazzite-dkub>
- **SSH Remote**: `git@github.com:dkolb/bazzite-dkub.git`
- **Architecture**: Multi-architecture support (amd64 primary)
- **Update Schedule**: Automatic builds on code changes and weekly base image updates

### Build System
- **Build Tool**: [just](https://just.systems/) command runner
- **Container Engine**: Podman/Buildah
- **Image Builder**: [bootc-image-builder](https://osbuild.org/docs/bootc/) for disk images
- **CI/CD**: GitHub Actions with automated testing and publishing

### Current Customizations Log
- VS Code: Auto-updated to latest version (bypasses GPG check)
- File Systems: Added `dosfstools` and `exfatprogs` for better removable media support
- ShellCheck: Installed to support shell script linting during development
- 1Password: Full GUI application and CLI installed for password and secret management
  - Includes Flatpak browser integration script in `/usr/bin/1password-flatpak-browser-integration`
- GearLever: Flatpak AppImage manager installed per-user at first login (avoiding /var pollution in base image)
- AppImages: Pre-installed Pinokio, MediaElch, VeraCrypt, and LM Studio in `/etc/skel/AppImages`
- First-run Integration: Autostart script automatically installs GearLever and integrates AppImages on first login

*When adding new features, please update this section to maintain a clear record of customizations.*
