#!/bin/bash
set -e

# Configuration
REPO="cheezeburger/nexus-cli"
BINARY_NAME="nexus-cli"
INSTALL_DIR="/usr/local/bin"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Detect OS and architecture
detect_platform() {
    local os=$(uname -s | tr '[:upper:]' '[:lower:]')
    local arch=$(uname -m)
    
    case $os in
        darwin) os="macos" ;;
        linux) os="linux" ;;
        *) 
            echo -e "${RED}Error: Unsupported OS: $os${NC}"
            exit 1
            ;;
    esac
    
    case $arch in
        x86_64) arch="x86_64" ;;
        arm64|aarch64) arch="arm64" ;;
        *) 
            echo -e "${RED}Error: Unsupported architecture: $arch${NC}"
            exit 1
            ;;
    esac
    
    echo "${os}-${arch}"
}

# Get latest release info
get_latest_release() {
    curl -s "https://api.github.com/repos/$REPO/releases/latest" | \
        grep '"tag_name":' | \
        sed -E 's/.*"([^"]+)".*/\1/'
}

# Download and install
install_nexus_cli() {
    local platform=$(detect_platform)
    local version=$(get_latest_release)
    
    if [ -z "$version" ]; then
        echo -e "${RED}Error: Could not fetch latest release${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Installing Nexus CLI ${version} for ${platform}...${NC}"
    
    # Construct download URL - adjust this based on your actual binary naming
    local binary_name="${BINARY_NAME}-${platform}"
    local download_url="https://github.com/$REPO/releases/download/$version/$binary_name"
    
    # Try different possible binary names if the first fails
    local temp_file="/tmp/nexus-cli"
    
    echo "Downloading from: $download_url"
    
    if ! curl -L "$download_url" -o "$temp_file" 2>/dev/null; then
        # Try without platform suffix
        download_url="https://github.com/$REPO/releases/download/$version/$BINARY_NAME"
        echo "Trying alternative URL: $download_url"
        
        if ! curl -L "$download_url" -o "$temp_file" 2>/dev/null; then
            echo -e "${RED}Error: Could not download binary${NC}"
            echo "Tried:"
            echo "  - https://github.com/$REPO/releases/download/$version/${BINARY_NAME}-${platform}"
            echo "  - https://github.com/$REPO/releases/download/$version/$BINARY_NAME"
            exit 1
        fi
    fi
    
    # Make executable
    chmod +x "$temp_file"
    
    # Install to system path
    if [ -w "$INSTALL_DIR" ]; then
        mv "$temp_file" "$INSTALL_DIR/$BINARY_NAME"
    else
        echo -e "${YELLOW}Installing to $INSTALL_DIR requires sudo...${NC}"
        sudo mv "$temp_file" "$INSTALL_DIR/$BINARY_NAME"
    fi
    
    echo -e "${GREEN}✓ Nexus CLI installed successfully!${NC}"
    echo -e "${GREEN}✓ You can now run: nexus-cli --help${NC}"
}

# Main execution
main() {
    echo -e "${GREEN}Nexus CLI Installer${NC}"
    echo "Repository: $REPO"
    echo
    
    install_nexus_cli
}

# Run if executed directly
if [ "${0##*/}" = "install.sh" ] || [ "$0" = "sh" ] || [ "$0" = "/bin/sh" ]; then
    main "$@"
fi