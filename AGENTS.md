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
- VS Code: Auto-updated to latest version (bypasses GPG check for compatibility)
- File Systems: Enhanced exFAT and DOS support via `dosfstools` and `exfatprogs`
- Container Signing: Automated with Cosign via GitHub Actions
- ShellCheck: Installed to provide shell script linting support

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

### Debug Commands
- **Check image contents**: `podman run --rm -it bazzite-dkub:latest /bin/bash`
- **Inspect build logs**: Check GitHub Actions logs for detailed error messages
- **Validate Justfile**: `just check` to verify syntax

## References

- [Bazzite-DX Base Image](https://github.com/ublue-os/bazzite-dx)
- [Universal Blue Community](https://universal-blue.discourse.group/)
- [bootc Documentation](https://github.com/bootc-dev/bootc/discussions)
- [just Command Runner](https://just.systems/)

---

**Note**: This is a personal productivity image, not a general template. Always maintain clear documentation of customizations for future reference.