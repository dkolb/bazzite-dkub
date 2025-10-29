# bazzite-dkub

A customized [bootc](https://github.com/bootc-dev/bootc) image based on [Bazzite-DX](https://github.com/ublue-os/bazzite-dx) with personal productivity enhancements.

<!-- User Provided Input Never Edit -->
Yes, I experiment with Github Copilot in this repository. I'm trying not to die of capitalism and my job is neck deep in Github Copilot. Feel how you want about that, but it's a useful, lowstakes project to experiment on.
<!-- End User Provided Input -->

## Customizations

**Latest Updates:**
- **GearLever Integration** - AppImage manager with automatic first-login installation and GitHub-based update tracking
- **Pre-installed AppImages** - Popular applications (Pinokio, MediaElch, VeraCrypt, LM Studio) ready to use

This image extends Bazzite-DX with the following modifications:

### Build Optimizations
- **Rechunking**: OCI layer rechunking for 5-10x smaller system updates (200-400 MB vs. 2 GB for minor changes)
  - Automatically optimizes container layers during CI/CD builds
  - Uses incremental rechunking by default for faster builds
  - Fresh rechunking available on-demand for optimal chunk structure
  - Based on [hhd-dev/rechunk](https://github.com/hhd-dev/rechunk) v1.2.4

### Software Updates
- **VS Code**: Automatically updated to the latest version during build (bypasses GPG check for compatibility)
- **File System Tools**: Enhanced exFAT and DOS filesystem support via `dosfstools` and `exfatprogs`
- **ShellCheck**: Pre-installed for shell script linting in the image and CI

### Optional AppImages (via ujust)
Install popular AppImages on-demand using `ujust` commands:
- **All at once**: `ujust install-appimages` - installs all AppImages below
- **Individual installs**:
  - `ujust install-pinokio` - AI Browser for running local AI applications
  - `ujust install-mediaelch` - Media Manager for Kodi
  - `ujust install-veracrypt` - Disk encryption software
  - `ujust install-lmstudio` - Local AI model runner
- **AppImage Manager**: `ujust install-gearlever` - installs GearLever for managing AppImages with a GUI

  *Note: AppImages are installed to `~/AppImages` and can be managed with GearLever.*

### 1Password Integration
For users who need 1Password (GUI, CLI, and browser integration), the recommended approach is to use distrobox:
- **Setup**: `ujust setup-browsers-1password` - creates a Fedora distrobox with Google Chrome, Firefox, and 1Password
- **Why distrobox?**: This is the most reliable way to get full integration between 1Password desktop app, browser extensions, and the `op` CLI
- **What's included**: Google Chrome, Firefox, 1Password GUI, and 1Password CLI (`op` command) - all exported to host
- **Configuration**: `/etc/distrobox/browsers-1password.ini` contains the full setup
- **D-Bus Integration**: Container configured with system D-Bus access for 1Password CLI biometric/system authentication
- Using distrobox for browsers and 1Password keeps the base image clean while providing seamless desktop integration
- **Automatic setup**: A systemd user service creates the distrobox on first login (runs in the background, won't slow down login)
- **Recreate safe**: The `ujust` script automatically removes any existing container before recreation (workaround for distrobox issue #838)

> **📝 Note to Future David:** Yes, we use a systemd service instead of just running `distrobox assemble` directly in the hook. Before you think "why didn't I keep this simple ugh" and start ripping things out, remember: the systemd approach runs in the **background** so users don't sit there watching a terminal spin during their first login. It's also **restartable** if something goes wrong, and you can actually check its status with `systemctl --user status browsers-1password-setup.service`. Sure, it's a few more files, but it's a better UX. You thought this through. Trust Past David. He was onto something. 🧠✨

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

## Troubleshooting

### Rechunking

**Q: Why are my updates still large?**

The first rechunked build will not have a previous reference to compare against, so updates will be larger. Subsequent builds will use incremental rechunking for optimal delta compression.

**Q: How do I trigger fresh rechunking?**

Go to GitHub Actions → Build workflow → Run workflow, and check the "fresh-rechunk" box. This is recommended monthly or after major base image updates.

**Q: Where can I see rechunking statistics?**

Check the GitHub Actions workflow logs in the "Run Rechunker" step. It shows the number of chunks created and optimization metrics.

**Q: What if rechunking fails?**

The workflow is configured to fail-fast if rechunking encounters errors. Check the logs for BTRFS mount errors or rechunker action failures. The build will not publish a broken image.

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
- **Rechunking**: Integrated hhd-dev/rechunk v1.2.4 for 5-10x smaller updates
  - Automatic prev-ref generation via GHCR query (40-YYYYMMDD tag format)
  - Workflow dispatch input for fresh rechunking mode
  - BTRFS storage mount for efficient rechunking operations
- VS Code: Auto-updated to latest version (bypasses GPG check)
- File Systems: Added `dosfstools` and `exfatprogs` for better removable media support
- ShellCheck: Installed to support shell script linting during development
- **Custom ujust recipes**: Added `/usr/share/ublue-os/just/60-custom.just` for optional AppImage installation
  - Install all AppImages: `ujust install-appimages`
  - Install individual AppImages: `ujust install-pinokio`, `ujust install-mediaelch`, etc.
  - Install GearLever AppImage manager: `ujust install-gearlever`
- **GearLever AppImage Manager**: Flatpak installed per-user on first login for AppImage management
- **Pre-installed AppImages**: Common applications in `/etc/skel/AppImages` auto-integrated on first login
  - Pinokio (AI Browser), MediaElch (Kodi Media Manager), VeraCrypt (Encryption), LM Studio (Local AI)
- **1Password Integration**: Distrobox-based setup with `ujust setup-browsers-1password`
  - Includes Google Chrome, Firefox, 1Password GUI, and 1Password CLI (`op` command)
  - D-Bus system bus access configured for CLI biometric/system authentication
  - Auto-setup via systemd user service on first login (background)
  - Container recreation safe (auto-removes existing container, fixes distrobox issue #838)

*When adding new features, please update this section to maintain a clear record of customizations.*
