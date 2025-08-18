#!/bin/sh
# This script installs Nexus CLI on Linux and macOS.
# It detects the current operating system architecture and installs the appropriate version.

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
OS=$(uname -s)

# Map architecture names to match release assets
case "$ARCH" in 
    x86_64) ARCH="x86_64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *) error "Unsupported architecture: $ARCH" ;;  
esac

# Map OS names to match release assets
case "$OS" in
    Linux) OS="linux" ;;
    Darwin) OS="macos" ;;
    *) error "Unsupported operating system: $OS" ;;
esac

KERN=$(uname -r)
case "$KERN" in
    *icrosoft*WSL2 | *icrosoft*wsl2) ;;
    *icrosoft) error "Microsoft WSL1 is not currently supported. Please upgrade to WSL2 with 'wsl --set-version <distro> 2'" ;;
    *) ;;
esac

SUDO=
if [ "$(id -u)" -ne 0 ]; then
    # Running as root, no need for sudo
    if ! available sudo; then
        error "This script requires superuser permissions. Please re-run as root."
    fi

    SUDO="sudo"
fi

NEEDS=$(require curl)
if [ -n "$NEEDS" ]; then
    status "ERROR: The following tools are required but missing:"
    for NEED in $NEEDS; do
        echo "  - $NEED"
    done
    exit 1
fi

# GitHub repository details
REPO_OWNER="cheezeburger"
REPO_NAME="nexus-cli"
VERSION="v0.10.8_cust"

# Construct binary name based on OS and architecture
BINARY_NAME="nexus-network-${OS}-${ARCH}"
if [ "$OS" = "windows" ]; then
    BINARY_NAME="${BINARY_NAME}.exe"
fi

# Download URL
DOWNLOAD_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/download/${VERSION}/${BINARY_NAME}"

status "Downloading Nexus CLI for ${OS}-${ARCH}..."
status "Download URL: $DOWNLOAD_URL"

curl --fail --show-error --location --progress-bar \
     -o "$TEMP_DIR/nexus" \
     "$DOWNLOAD_URL"

chmod +x "$TEMP_DIR/nexus"

# Find installation directory - try user directories first
BINDIR=""
for dir in "$HOME/.local/bin" "$HOME/bin" /usr/local/bin /usr/bin /bin; do
    if echo $PATH | grep -q "$dir"; then
        BINDIR="$dir"
        break
    fi
done

if [ -z "$BINDIR" ]; then
    # Default to ~/.local/bin and add to PATH
    BINDIR="$HOME/.local/bin"
    status "Adding $BINDIR to PATH for this session..."
    export PATH="$BINDIR:$PATH"
fi

status "Installing nexus to $BINDIR..."

if [ "$BINDIR" = "$HOME/.local/bin" ] || [ "$BINDIR" = "$HOME/bin" ]; then
    # User directory - no sudo needed
    mkdir -p "$BINDIR"
    install -m755 $TEMP_DIR/nexus $BINDIR/nexus
else
    # System directory - needs sudo
    $SUDO install -o0 -g0 -m755 -d $BINDIR
    $SUDO install -o0 -g0 -m755 $TEMP_DIR/nexus $BINDIR/nexus
fi

if [ "$BINDIR" = "$HOME/.local/bin" ]; then
    status "Note: $BINDIR has been added to your PATH for this session."
    status "To make it permanent, add this line to your shell profile:"
    status "export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

status 'Installation complete! Use "nexus --help" to get started.'