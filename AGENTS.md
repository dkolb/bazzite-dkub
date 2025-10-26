# AGENTS.md

## Project Overview

This is `bazzite-dkub`, a custom [bootc](https://github.com/bootc-dev/bootc) image based on Bazzite-DX with personal productivity enhancements. The image extends the base Bazzite-DX with updated VS Code, enhanced file system support, and automated container signing.

**Base Image**: `ghcr.io/ublue-os/bazzite-dx:stable`  
**Registry**: `ghcr.io/dkolb/bazzite-dkub`  
**Repository (HTTPS)**: <https://github.com/dkolb/bazzite-dkub>  
**Repository (SSH)**: `git@github.com:dkolb/bazzite-dkub.git`

## Setup Commands

- **Build container image**: `just build`
- **Test locally**: `just build && echo "Build successful"`
- **Build ISO image**: `just build-iso`
- **Build VM image**: `just build-qcow2`
- **Run VM for testing**: `just run-vm-qcow2`
- **Clean artifacts**: `just clean`

## Architecture

### Key Files
- **`Containerfile`** - Main image definition (Podman/Docker format)
- **`build_files/build.sh`** - Package installations and system customizations
- **`Justfile`** - Build commands and development workflows (image name: `bazzite-dkub`)
- **`.github/workflows/build.yml`** - CI/CD pipeline for automated builds
- **`disk_config/`** - TOML files for ISO/VM image generation

### Current Customizations
- **Rechunking**: Integrated hhd-dev/rechunk v1.2.4 for 5-10x smaller system updates
  - Automatic prev-ref generation via GHCR query (40-YYYYMMDD tag format)
  - Workflow dispatch input for fresh rechunking mode (recommended monthly)
  - BTRFS storage mount at `/var/tmp/rechunk-btrfs` (50GB) for rechunking operations
  - Incremental rechunking by default, fresh mode available on-demand
- VS Code: Auto-updated to latest version (bypasses GPG check for compatibility)
- File Systems: Enhanced exFAT and DOS support via `dosfstools` and `exfatprogs`
- Container Signing: Automated with Cosign via GitHub Actions
- ShellCheck: Installed to provide shell script linting support
- Custom ujust recipes: `/usr/share/ublue-os/just/60-custom.just` provides optional AppImage installation
  - `ujust install-appimages` - Install all common AppImages (Pinokio, MediaElch, VeraCrypt, LM Studio)
  - `ujust install-<name>` - Install individual AppImages on-demand
  - `ujust install-gearlever` - Install GearLever AppImage manager
  - AppImages are installed to `~/AppImages` directory per-user
- GearLever: Flatpak AppImage manager installed per-user on first login (avoids /var pollution in base image)
- Pre-installed AppImages in `/etc/skel/AppImages` (auto-integrated with GearLever on first login):
  - Pinokio (AI Browser) - `pinokio.appimage`
  - MediaElch (Media Manager for Kodi) - `mediaelch.appimage`
  - VeraCrypt (Disk Encryption) - `veracrypt.appimage`
  - LM Studio (Local AI) - `lm_studio.appimage`
- Autostart Integration: Desktop entry in `/etc/skel/.config/autostart/` automatically installs GearLever per-user and integrates AppImages on first user login, enabling GitHub-based update tracking
- **1Password Integration**: Distrobox-based setup for browsers and 1Password (keeps base image clean)
  - Configuration: `/etc/distrobox/browsers-1password.ini` - defines Fedora container with Chrome, Firefox, and 1Password
  - Systemd Service: `/etc/skel/.config/systemd/user/browsers-1password-setup.service` - creates distrobox on first login (background)
  - User Setup Hook: `/usr/share/ublue-os/user-setup.hooks.d/15-browsers-1password.sh` - copies service file and enables it for all users
  - Manual Setup: `ujust setup-browsers-1password` - creates distrobox immediately without waiting for login
  - Apps Exported: Google Chrome, Firefox, 1Password GUI, 1Password CLI (`op` command)


## Development Workflow

### Adding New Packages
1. **Edit `build_files/build.sh`** with installation commands:
   ```bash
   # Install new package
   dnf5 install -y package-name
   ```
2. **Test locally**: `just build`
3. **Update documentation** (see Documentation Requirements below)
4. **Commit both code and docs together**
5. **Push** - GitHub Actions builds and publishes automatically

### Testing
- **Local testing**: Always run `just build` before pushing
- **VM testing**: Use `just build-qcow2 && just run-vm-qcow2` for full system testing
- **Syntax checking**: `just lint` for shell scripts, `just check` for Justfile syntax

## Code Style

### Shell Scripts (`build_files/build.sh`)
- Use `set -ouex pipefail` at script start
- Prefer `dnf5` over `dnf` for package management
- Use `--nogpgcheck` flag for VS Code updates (known GPG signature issues)
- Comment why packages are being installed
- Group related installations together

### Containerfile
- Follow Podman/Docker best practices
- Use multi-stage builds with `FROM scratch AS ctx` for build files
- Keep modifications in `build_files/build.sh` rather than inline RUN commands

## Documentation Requirements

**CRITICAL**: When adding new packages or features, you MUST update documentation:

1. **Update `README.md`**:
   - Add to "Customizations" section at the top
   - Update "Current Customizations Log" in Technical Details section
   - Document any new commands or usage patterns

2. **Update this `AGENTS.md`**:
   - Add to "Current Customizations" section above
   - Document any new build commands or workflows

3. **Test documentation**: Ensure instructions are accurate by following them

## Security Considerations

- **Never commit `cosign.key`** - private signing keys stay in GitHub Secrets
- **GPG checks disabled for VS Code** - this is intentional due to Microsoft's signature format
- **Container signing** - all images are signed with Cosign automatically
- **Repository uses SSH** - `git@github.com:dkolb/bazzite-dkub.git`
- **Canonical Git URL** - <https://github.com/dkolb/bazzite-dkub>

## Build System Details

- **Container Engine**: Podman/Buildah
- **Image Builder**: bootc-image-builder for disk images
- **CI/CD**: GitHub Actions with automated testing and publishing
- **Architecture**: Multi-architecture support (amd64 primary)
- **Update Schedule**: Automatic builds on code changes

## Troubleshooting

### Common Issues
- **Permission denied in GHCR**: Ensure repository workflow permissions are set to "Read and write permissions"
- **VS Code GPG errors**: Use `--nogpgcheck` flag (this is expected and documented)
- **Build failures**: Check that base image `ghcr.io/ublue-os/bazzite-dx:stable` is accessible
- **Rechunking errors**: Check GitHub Actions logs for BTRFS mount failures or prev-ref query issues
- **Large update sizes**: First rechunked build has no prev-ref; subsequent builds will be optimized
- **Fresh rechunking**: Trigger via workflow dispatch with `fresh-rechunk: true` input (recommended monthly)
- **Unknown GID after rebase**: Fixed by using static GID allocation in `sysusers.d/*.conf` files
  - System groups MUST use fixed GIDs (not `-` for dynamic allocation)
  - GIDs are assigned in 990-993 range to avoid conflicts
  - `systemd-sysusers` runs BEFORE package installation to pre-create groups

### Debug Commands
- **Check image contents**: `podman run --rm -it bazzite-dkub:latest /bin/bash`
- **Inspect build logs**: Check GitHub Actions logs for detailed error messages
- **Validate Justfile**: `just check` to verify syntax
- **Verify rechunking metadata**: `skopeo inspect docker://ghcr.io/dkolb/bazzite-dkub:latest | jq '.Labels | select(.["rechunk.version"])'`
- **Check prev-ref generation**: Review GitHub Actions logs in "Generate Previous Reference" step

## References

- [Bazzite-DX Base Image](https://github.com/ublue-os/bazzite-dx)
- [Universal Blue Community](https://universal-blue.discourse.group/)
- [bootc Documentation](https://github.com/bootc-dev/bootc/discussions)
- [hhd-dev/rechunk](https://github.com/hhd-dev/rechunk) - OCI layer rechunking tool
- [just Command Runner](https://just.systems/)
- [just Command Runner](https://just.systems/)

---

**Note**: This is a personal productivity image, not a general template. Always maintain clear documentation of customizations for future reference.