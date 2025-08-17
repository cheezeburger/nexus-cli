#!/bin/sh
set -e

# Configuration
REPO="cheezeburger/nexus-cli"
BINARY_NAME="nexus-network"
INSTALL_DIR="/usr/local/bin"

# Detect OS and architecture
detect_platform() {
    os=$(uname -s | tr 'A-Z' 'a-z')
    arch=$(uname -m)
    
    case $os in
        darwin) os="macos" ;;
        linux) os="linux" ;;
        *) 
            echo "Error: Unsupported OS: $os"
            exit 1
            ;;
    esac
    
    case $arch in
        x86_64) arch="x86_64" ;;
        arm64|aarch64) arch="arm64" ;;
        *) 
            echo "Error: Unsupported architecture: $arch"
            exit 1
            ;;
    esac
    
    echo "${os}-${arch}"
}

# Get latest release info
get_latest_release() {
    curl -s "https://api.github.com/repos/$REPO/releases/latest" | \
        grep '"tag_name":' | \
        head -n 1 | \
        cut -d '"' -f 4
}

# Download and install
install_nexus_cli() {
    platform=$(detect_platform)
    version=$(get_latest_release)
    
    if [ -z "$version" ]; then
        echo "Error: Could not fetch latest release"
        exit 1
    fi
    
    echo "Installing Nexus CLI $version for $platform..."
    
    # Try different possible binary names
    binary_name="${BINARY_NAME}-${platform}"
    download_url="https://github.com/$REPO/releases/download/$version/$binary_name"
    temp_file="/tmp/nexus-cli"
    
    echo "Downloading from: $download_url"
    
    if ! curl -L "$download_url" -o "$temp_file" 2>/dev/null; then
        # Try without platform suffix
        download_url="https://github.com/$REPO/releases/download/$version/$BINARY_NAME"
        echo "Trying alternative URL: $download_url"
        
        if ! curl -L "$download_url" -o "$temp_file" 2>/dev/null; then
            echo "Error: Could not download binary"
            echo "Tried:"
            echo "  - https://github.com/$REPO/releases/download/$version/${BINARY_NAME}-${platform}"
            echo "  - https://github.com/$REPO/releases/download/$version/$BINARY_NAME"
            exit 1
        fi
    fi
    
    # Make executable
    chmod +x "$temp_file"
    
    # Install to system path with the correct name
    if [ -w "$INSTALL_DIR" ]; then
        mv "$temp_file" "$INSTALL_DIR/nexus-cli"
    else
        echo "Installing to $INSTALL_DIR requires sudo..."
        sudo mv "$temp_file" "$INSTALL_DIR/nexus-cli"
    fi
    
    echo "✓ Nexus CLI installed successfully!"
    echo "✓ You can now run: nexus-cli --help"
}

# Main execution
main() {
    echo "Nexus CLI Installer"
    echo "Repository: $REPO"
    echo
    
    install_nexus_cli
}

# Run the installer
main "$@"