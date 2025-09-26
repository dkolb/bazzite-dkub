# Copilot Instructions for bazzite-dkub

This repository is a template for building custom [bootc](https://github.com/bootc-dev/bootc) images, especially for Universal Blue Project derivatives. AI agents should follow these guidelines for effective contributions:

## Architecture Overview
- **Containerfile**: Main entrypoint for customizing the base image. Follows Podman Containerfile conventions. All image changes start here.
- **build_files/build.sh**: Invoked from `Containerfile`. Place package installs and system customizations here. Use provided examples as reference.
- **Justfile**: Defines build, test, and VM/ISO management commands. All developer workflows are managed via `just` commands.
- **disk_config/**: Contains TOML files for disk image builds. Update these to point to your custom container image for ISO/qcow/raw generation.
- **artifacthub-repo.yml**: Used for Artifacthub indexing and publisher verification.

## Developer Workflows
- **Build Container Image**: `just build [target_image] [tag]` (defaults: image name and tag from Justfile)
- **Build Disk Images**: Use `just build-qcow2`, `just build-iso`, or `just build-raw` for VM/ISO builds. Update `disk_config/iso.toml` as needed.
- **Run VM**: `just run-vm-qcow2 [target_image] [tag]` or `just spawn-vm rebuild="0" type="qcow2" ram="6G"`
- **Clean Artifacts**: `just clean`
- **Lint/Format Bash**: `just lint`, `just format`
- **Check/Fix Justfile Syntax**: `just check`, `just fix`

## Project-Specific Patterns
- **Base Image Selection**: Change the `FROM` line in `Containerfile` to set your base. Use images from Universal Blue or Fedora Atomic.
- **Image Naming**: Set the first line in `Justfile` to your image's name. Keep naming consistent across files.
- **Container Signing**: Use [cosign](https://edu.chainguard.dev/open-source/sigstore/cosign/how-to-install-cosign/#installing-cosign-with-the-cosign-binary) to generate keys. Store `cosign.key` as a GitHub secret named `SIGNING_SECRET`. Never commit private keys.
- **Disk Image Uploads**: S3 uploads are configured via GitHub Action secrets (`S3_PROVIDER`, `S3_BUCKET_NAME`, etc.) and managed in workflow files.

## Integration Points
- **GitHub Actions**: `.github/workflows/build.yml` and `.github/workflows/build-disk.yml` automate image and disk builds, publishing to GHCR and optionally S3.
- **Artifacthub**: Use `artifacthub-repo.yml` for indexing and publisher verification.

## Key Files & Directories
- `Containerfile`, `Justfile`, `build_files/build.sh`, `disk_config/`, `.github/workflows/`, `artifacthub-repo.yml`

## Example: Adding a Package
1. Edit `build_files/build.sh` to install your package.
2. Rebuild the image: `just build`
3. Push changes and verify via GitHub Actions.

## References
- [Universal Blue Forums](https://universal-blue.discourse.group/)
- [Universal Blue Discord](https://discord.gg/WEu6BdFEtp)
- [bootc discussion forums](https://github.com/bootc-dev/bootc/discussions)

---
If any section is unclear or missing, please provide feedback for further refinement.