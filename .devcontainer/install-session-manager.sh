#!/usr/bin/env bash

set -euo pipefail

if command -v session-manager-plugin >/dev/null 2>&1; then
    echo "Session Manager plugin already installed:"
    session-manager-plugin --version
    exit 0
fi

ARCH="$(dpkg --print-architecture)"

case "$ARCH" in
    amd64)
        URL="https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb"
        ;;
    arm64)
        URL="https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_arm64/session-manager-plugin.deb"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

echo "Installing AWS Session Manager plugin..."

curl -fsSL "$URL" -o /tmp/session-manager-plugin.deb

sudo dpkg -i /tmp/session-manager-plugin.deb

rm /tmp/session-manager-plugin.deb

echo "Installed:"
session-manager-plugin --version