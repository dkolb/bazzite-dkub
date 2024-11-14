# bazzite-dkub &nbsp; [![build badge](https://github.com/dkolb/bazzite-dkub/actions/workflows/build.yml/badge.svg)](https://github.com/dkolb/bazzite-dkub/actions/workflows/build.yml)

AMD Bazzite Gnome image with modifications:

1. Firefox
2. Visual Studio Code
3. 1Password

## Installation

> **Warning**  
> [This is an experimental feature](https://www.fedoraproject.org/wiki/Changes/OstreeNativeContainerStable), try at your own discretion.

To rebase an existing atomic Fedora installation to the latest build:

- First rebase to the unsigned image, to get the proper signing keys and policies installed:
  ```
  rpm-ostree rebase ostree-unverified-registry:ghcr.io/dkolb/bazzite-dkub:latest
  ```
- Reboot to complete the rebase:
  ```
  systemctl reboot
  ```
- Then rebase to the signed image, like so:
  ```
  rpm-ostree rebase ostree-image-signed:docker://ghcr.io/dkolb/bazzite-dkub:latest
  ```
- Reboot again to complete the installation
  ```
  systemctl reboot
  ```

The `latest` tag will automatically point to the.