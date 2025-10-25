# Custom recipes for bazzite-dkub
# These commands are available via 'ujust <command>'

# Install common AppImages to ~/AppImages directory
install-appimages:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Installing AppImages to ~/AppImages..."
    mkdir -p ~/AppImages
    
    # Download Pinokio AppImage (AI Browser)
    echo "Downloading Pinokio..."
    curl -L "https://github.com/pinokiocomputer/pinokio/releases/latest/download/Pinokio-linux-x86_64.AppImage" \
      -o ~/AppImages/pinokio.appimage
    chmod +x ~/AppImages/pinokio.appimage
    
    # Download MediaElch AppImage (Media Manager for Kodi)
    echo "Downloading MediaElch..."
    curl -L "https://github.com/Komet/MediaElch/releases/latest/download/MediaElch_linux_x86_64.AppImage" \
      -o ~/AppImages/mediaelch.appimage
    chmod +x ~/AppImages/mediaelch.appimage
    
    # Download VeraCrypt AppImage (Disk Encryption)
    echo "Downloading VeraCrypt..."
    curl -L "https://github.com/veracrypt/VeraCrypt/releases/latest/download/VeraCrypt-1.26.16-x86_64.AppImage" \
      -o ~/AppImages/veracrypt.appimage
    chmod +x ~/AppImages/veracrypt.appimage
    
    # Download LM Studio AppImage (Local AI)
    echo "Downloading LM Studio..."
    curl -L "https://installers.lmstudio.ai/linux/x64/0.3.29-1/LM-Studio-0.3.29-1-x64.AppImage" \
      -o ~/AppImages/lm_studio.appimage
    chmod +x ~/AppImages/lm_studio.appimage
    
    echo "Integrating all AppImages with GearLever..."
    # Integrate with custom update URLs for GitHub projects
    flatpak run it.mijorus.gearlever --integrate ~/AppImages/pinokio.appimage --yes \
      --update-url 'https://github.com/pinokiocomputer/pinokio/releases/download/*/Pinokio-*.AppImage'
    flatpak run it.mijorus.gearlever --integrate ~/AppImages/mediaelch.appimage --yes \
      --update-url 'https://github.com/Komet/MediaElch/releases/download/*/MediaElch_linux_*.AppImage'
    flatpak run it.mijorus.gearlever --integrate ~/AppImages/veracrypt.appimage --yes \
      --update-url 'https://github.com/veracrypt/VeraCrypt/releases/download/*/VeraCrypt-*-x86_64.AppImage'
    flatpak run it.mijorus.gearlever --integrate ~/AppImages/lm_studio.appimage --yes
    
    # Add --appimage-extract-and-run argument to VeraCrypt desktop file
    echo "Configuring VeraCrypt desktop entry..."
    DESKTOP_FILE="$HOME/.local/share/applications/veracrypt.desktop"
    if [ -f "$DESKTOP_FILE" ]; then
        sed -i 's|^\(Exec=.*veracrypt\.appimage\)\( %U\)\?$|\1 --appimage-extract-and-run\2|' "$DESKTOP_FILE"
        echo "✅ Added --appimage-extract-and-run argument to VeraCrypt"
    fi
    
    echo "✅ All AppImages installed and integrated with GearLever"

# Install individual AppImages
install-pinokio:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Installing Pinokio AppImage..."
    mkdir -p ~/AppImages
    curl -L "https://github.com/pinokiocomputer/pinokio/releases/latest/download/Pinokio-linux-x86_64.AppImage" \
      -o ~/AppImages/pinokio.appimage
    chmod +x ~/AppImages/pinokio.appimage
    echo "Integrating with GearLever..."
    flatpak run it.mijorus.gearlever --integrate ~/AppImages/pinokio.appimage --yes \
      --update-url 'https://github.com/pinokiocomputer/pinokio/releases/download/*/Pinokio-*.AppImage'
    echo "✅ Pinokio installed and integrated with GearLever"

install-mediaelch:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Installing MediaElch AppImage..."
    mkdir -p ~/AppImages
    curl -L "https://github.com/Komet/MediaElch/releases/latest/download/MediaElch_linux_x86_64.AppImage" \
      -o ~/AppImages/mediaelch.appimage
    chmod +x ~/AppImages/mediaelch.appimage
    echo "Integrating with GearLever..."
    flatpak run it.mijorus.gearlever --integrate ~/AppImages/mediaelch.appimage --yes \
      --update-url 'https://github.com/Komet/MediaElch/releases/download/*/MediaElch_linux_*.AppImage'
    echo "✅ MediaElch installed and integrated with GearLever"

install-veracrypt:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Installing VeraCrypt AppImage..."
    mkdir -p ~/AppImages
    curl -L "https://github.com/veracrypt/VeraCrypt/releases/latest/download/VeraCrypt-1.26.16-x86_64.AppImage" \
      -o ~/AppImages/veracrypt.appimage
    chmod +x ~/AppImages/veracrypt.appimage
    echo "Integrating with GearLever..."
    flatpak run it.mijorus.gearlever --integrate ~/AppImages/veracrypt.appimage --yes \
      --update-url 'https://github.com/veracrypt/VeraCrypt/releases/download/*/VeraCrypt-*-x86_64.AppImage'
    
    # Add --appimage-extract-and-run argument to desktop file
    echo "Configuring VeraCrypt desktop entry..."
    DESKTOP_FILE="$HOME/.local/share/applications/veracrypt.desktop"
    if [ -f "$DESKTOP_FILE" ]; then
        sed -i 's|^\(Exec=.*veracrypt\.appimage\)\( %U\)\?$|\1 --appimage-extract-and-run\2|' "$DESKTOP_FILE"
        echo "✅ Added --appimage-extract-and-run argument to VeraCrypt"
    fi
    
    echo "✅ VeraCrypt installed and integrated with GearLever"

install-lmstudio:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Installing LM Studio AppImage..."
    mkdir -p ~/AppImages
    curl -L "https://installers.lmstudio.ai/linux/x64/0.3.29-1/LM-Studio-0.3.29-1-x64.AppImage" \
      -o ~/AppImages/lm_studio.appimage
    chmod +x ~/AppImages/lm_studio.appimage
    echo "Integrating with GearLever..."
    flatpak run it.mijorus.gearlever --integrate ~/AppImages/lm_studio.appimage --yes
    echo "✅ LM Studio installed and integrated with GearLever"

# Install GearLever for managing AppImages
install-gearlever:
    flatpak install -y --user flathub it.mijorus.gearlever
    echo "✅ GearLever installed - use it to manage your AppImages"
