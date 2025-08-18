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

SUDO=
if [ "$(id -u)" -ne 0 ]; then
    # Running as root, no need for sudo
    if ! available sudo; then
        error "This script requires superuser permissions. Please re-run as root."
    fi

    SUDO="sudo"
fi

NEEDS=$(require curl awk grep sed tee xargs)
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

# Download URL
DOWNLOAD_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/download/${VERSION}/${BINARY_NAME}"

status "Downloading Nexus CLI for ${OS}-${ARCH}..."

curl --fail --show-error --location --progress-bar \
     -o "$TEMP_DIR/nexus" \
     "$DOWNLOAD_URL"

chmod +x "$TEMP_DIR/nexus"

for BINDIR in /usr/local/bin /usr/bin /bin; do
    echo $PATH | grep -q $BINDIR && break || continue
done

status "Installing nexus to $BINDIR..."
$SUDO install -o0 -g0 -m755 -d $BINDIR
$SUDO install -o0 -g0 -m755 $TEMP_DIR/nexus $BINDIR/nexus

install_success() { 
    status 'Installation complete! Use "nexus --help" to get started.'
}
trap install_success EXIT