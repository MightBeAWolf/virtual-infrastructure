#!/bin/bash

# Temporary directory for downloading and extracting fonts
TMP_DIR=$(mktemp -d -t starship-install-XXXXXXXXXX)

# Font installation directory
FONT_DIR="/etc/skel/.local/share/fonts"

# Font zip file name
FONT_ZIP="FiraCode.zip"
FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/FiraCode.zip"

# Cleanup function to remove temporary directory
cleanup() {
    echo "Cleaning up temporary files..."
    rm -rf "$TMP_DIR"
}

# Trap for cleanup on exit or interruption
trap cleanup EXIT INT TERM

# Check for existing FiraCode font
font_exists=$( [[ -d "${FONT_DIR}" ]] && find "$FONT_DIR" -type f -name 'Fira Code Regular Nerd Font Complete.ttf' | head -n 1)

# Download and install fonts if they aren't already installed
if [ -z "$font_exists" ]; then
    # Check for curl and unzip
    if ! command -v curl &> /dev/null; then
        echo "Error: curl is not installed." >&2
        exit 1
    fi

    if ! command -v unzip &> /dev/null; then
        echo "Error: unzip is not installed." >&2
        exit 1
    fi

    # Download FiraCode Nerd Font
    echo "Downloading FiraCode Nerd Font..."
    if curl -L -o "$TMP_DIR/$FONT_ZIP" "$FONT_URL"; then
        # Unzip and install the font
        echo "Installing FiraCode Nerd Font..."
        mkdir -p "$FONT_DIR"
        unzip -o -q "$TMP_DIR/$FONT_ZIP" -d "$FONT_DIR"
        rm -f "$TMP_DIR/$FONT_ZIP" # Remove the zip file after extracting

        # Rebuild font cache
        if command -v fc-cache &> /dev/null; then
            fc-cache -fv
        fi
    else
        echo "Error: Failed to download FiraCode.zip" >&2
        exit 1
    fi
else
    echo "FiraCode Nerd Font is already installed."
fi

echo "Downloading Starship Installer"
if ! curl -fsSL https://starship.rs/install.sh > "${TMP_DIR}/installer.sh"; then
    echo "Error: Starship installer failed to download." >&2
    exit 1
fi
chmod +x "${TMP_DIR}/installer.sh"

# Install Starship
echo "Installing Starship terminal prompt..."
if ! "${TMP_DIR}/installer.sh" -y -b "/usr/local/bin"; then
    echo "Error: Starship installation failed." >&2
    exit 1
fi

cat >> /etc/skel/.bashrc << HEREDOC

# Enable the Starship prompt
eval "\$(/usr/local/bin/starship init bash)"
HEREDOC

