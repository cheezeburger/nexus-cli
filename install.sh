#!/bin/sh
set -e

# Configuration
REPO="cheezeburger/nexus-cli"
BINARY_NAME="nexus-cli"

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
            printf "${RED}Error: Unsupported OS: $os${NC}\n"
            exit 1
            ;;
    esac
    
    case $arch in
        x86_64) arch="x86_64" ;;
        arm64|aarch64) arch="arm64" ;;
        *) 
            printf "${RED}Error: Unsupported architecture: $arch${NC}\n"
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
        printf "${RED}Error: Could not fetch latest release${NC}\n"
        exit 1
    fi
    
    printf "${GREEN}Installing Nexus CLI ${version} for ${platform}...${NC}\n"
    
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
            printf "${RED}Error: Could not download binary${NC}\n"
            echo "Tried:"
            echo "  - https://github.com/$REPO/releases/download/$version/${BINARY_NAME}-${platform}"
            echo "  - https://github.com/$REPO/releases/download/$version/$BINARY_NAME"
            exit 1
        fi
    fi
    
    # Make executable
    chmod +x "$temp_file"
    
    # Find the best installation directory (like original script)
    for BINDIR in /usr/local/bin /usr/bin /bin; do
        echo $PATH | grep -q $BINDIR && break || continue
    done
    
    printf "Installing nexus-cli to $BINDIR...\n"
    
    # Install to system path or user local bin
    if [ -w "$BINDIR" ]; then
        mv "$temp_file" "$BINDIR/$BINARY_NAME"
    elif command -v sudo >/dev/null 2>&1; then
        printf "${YELLOW}Installing to $BINDIR requires sudo...${NC}\n"
        sudo mv "$temp_file" "$BINDIR/$BINARY_NAME"
    else
        # Fallback to user local bin
        USER_BIN_DIR="$HOME/.local/bin"
        mkdir -p "$USER_BIN_DIR"
        mv "$temp_file" "$USER_BIN_DIR/$BINARY_NAME"
        printf "${YELLOW}Installed to $USER_BIN_DIR (add to PATH if needed)${NC}\n"
        BINDIR="$USER_BIN_DIR"
    fi
    
    printf "${GREEN}✓ Nexus CLI installed successfully!${NC}\n"
    printf "${GREEN}✓ You can now run: nexus-cli --help${NC}\n"
}

# Main execution
main() {
    printf "${GREEN}Nexus CLI Installer${NC}\n"
    echo "Repository: $REPO"
    echo
    
    install_nexus_cli
}

# Run main function
main "$@"