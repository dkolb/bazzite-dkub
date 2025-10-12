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
    
    echo "✅ AppImages installed to ~/AppImages"
    echo "You may want to run 'ujust install-gearlever' to manage them with a GUI"

# Install individual AppImages
install-pinokio:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Installing Pinokio AppImage..."
    mkdir -p ~/AppImages
    curl -L "https://github.com/pinokiocomputer/pinokio/releases/latest/download/Pinokio-linux-x86_64.AppImage" \
      -o ~/AppImages/pinokio.appimage
    chmod +x ~/AppImages/pinokio.appimage
    echo "✅ Pinokio installed to ~/AppImages/pinokio.appimage"

install-mediaelch:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Installing MediaElch AppImage..."
    mkdir -p ~/AppImages
    curl -L "https://github.com/Komet/MediaElch/releases/latest/download/MediaElch_linux_x86_64.AppImage" \
      -o ~/AppImages/mediaelch.appimage
    chmod +x ~/AppImages/mediaelch.appimage
    echo "✅ MediaElch installed to ~/AppImages/mediaelch.appimage"

install-veracrypt:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Installing VeraCrypt AppImage..."
    mkdir -p ~/AppImages
    curl -L "https://github.com/veracrypt/VeraCrypt/releases/latest/download/VeraCrypt-1.26.16-x86_64.AppImage" \
      -o ~/AppImages/veracrypt.appimage
    chmod +x ~/AppImages/veracrypt.appimage
    echo "✅ VeraCrypt installed to ~/AppImages/veracrypt.appimage"

install-lmstudio:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Installing LM Studio AppImage..."
    mkdir -p ~/AppImages
    curl -L "https://installers.lmstudio.ai/linux/x64/0.3.29-1/LM-Studio-0.3.29-1-x64.AppImage" \
      -o ~/AppImages/lm_studio.appimage
    chmod +x ~/AppImages/lm_studio.appimage
    echo "✅ LM Studio installed to ~/AppImages/lm_studio.appimage"

# Install GearLever for managing AppImages
install-gearlever:
    flatpak install -y --user flathub it.mijorus.gearlever
    echo "✅ GearLever installed - use it to manage your AppImages"
