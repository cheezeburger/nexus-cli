#!/bin/sh
# This script installs Nexus on Linux and macOS.
# It detects the current operating system architecture and installs the appropriate version of Nexus.

set -eu

status() { echo ">>> $*" >&1; }
error() { echo "ERROR $*" >&2; exit 1; }
warning() { echo "WARNING: $*"; }

TEMP_DIR=$(mktemp -d)
cleanup() { rm -rf $TEMP_DIR; }
trap cleanup EXIT

available() { command -v $1 >/dev/null; }
require() {
    local MISSING=''
    for TOOL in $*; do
        if ! available $TOOL; then
            MISSING="$MISSING $TOOL"
        fi
    done

    echo $MISSING
}

[ "$(uname -s)" = "Linux" ] || [ "$(uname -s)" = "Darwin" ] || error 'This script is intended to run on Linux or macOS only.'

ARCH=$(uname -m)
case "$ARCH" in 
    x86_64) ARCH="x86_64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *) error "Unsupported architecture: $ARCH" ;;  
esac

UNAME=$(uname -s)
case "$UNAME" in
    Linux) OS="linux" ;;
    Darwin) OS="macos" ;;
    *) error "Unsupported operating system: $UNAME" ;;
esac

KERN=$(uname -r)
case "$KERN" in
    *icrosoft*WSL2 | *icrosoft*wsl2) ;;
    *icrosoft) error "Microsoft WSL1 is not currently supported. Please upgrade to WSL2 with 'wsl --set-version <distro> 2'" ;;
    *) ;;
esac

NEEDS=$(require curl)
if [ -n "$NEEDS" ]; then
    status "ERROR: The following tools are required but missing:"
    for NEED in $NEEDS; do
        echo "  - $NEED"
    done
    exit 1
fi

# GitHub release details
REPO_OWNER="cheezeburger"
REPO_NAME="nexus-cli"
VERSION="v0.10.8_cust"
BINARY_NAME="nexus-network-${OS}-${ARCH}"

status "Downloading Nexus for ${OS}-${ARCH}..."

DOWNLOAD_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/download/${VERSION}/${BINARY_NAME}"

curl --fail --show-error --location --progress-bar \
     -o "$TEMP_DIR/nexus" \
     "$DOWNLOAD_URL"

chmod +x "$TEMP_DIR/nexus"

# Install to user directory like official Nexus script
BINDIR="$HOME/.nexus/bin"
status "Installing nexus to $BINDIR..."
mkdir -p "$BINDIR"
cp "$TEMP_DIR/nexus" "$BINDIR/nexus"

# Add to PATH if not already there
if ! echo "$PATH" | grep -q "$BINDIR"; then
    for profile in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
        if [ -f "$profile" ]; then
            echo "export PATH=\"$BINDIR:\$PATH\"" >> "$profile"
            status "Added $BINDIR to PATH in $profile"
            break
        fi
    done
    
    # For current session
    export PATH="$BINDIR:$PATH"
    status "Added $BINDIR to PATH for current session"
fi

status 'Installation complete! Use "nexus --help" to get started.'
status 'Restart your terminal or run "source ~/.bashrc" (or your shell profile) to use nexus.'