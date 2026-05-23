#!/usr/bin/env bash
# playSom installer
# Usage: curl -fsSL https://raw.githubusercontent.com/FlintBeastwood/playSom/main/install.sh | bash

set -euo pipefail

REPO="FlintBeastwood/playSom"
APP_NAME="playSom"
INSTALL_DIR="/Applications"
TMP_DIR="$(mktemp -d)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}  📻 playSom Installer${NC}"
echo -e "${BLUE}  ─────────────────────${NC}"
echo ""

# Check macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo -e "${RED}  ✗ playSom requires macOS.${NC}"
    exit 1
fi

# Check macOS version (minimum 13.0 Ventura)
OS_VERSION=$(sw_vers -productVersion | cut -d. -f1)
if [[ "$OS_VERSION" -lt 13 ]]; then
    echo -e "${RED}  ✗ playSom requires macOS 13 (Ventura) or later.${NC}"
    echo -e "    Your version: $(sw_vers -productVersion)"
    exit 1
fi

echo -e "  ${BLUE}→${NC} Fetching latest release..."

# Get latest release download URL
DOWNLOAD_URL=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" \
    | grep '"browser_download_url"' \
    | grep '\.zip"' \
    | head -1 \
    | sed 's/.*"browser_download_url": *"\([^"]*\)".*/\1/')

if [[ -z "$DOWNLOAD_URL" ]]; then
    echo -e "${RED}  ✗ Could not find a release to download.${NC}"
    echo -e "    Check: https://github.com/${REPO}/releases"
    exit 1
fi

VERSION=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" \
    | grep '"tag_name"' \
    | head -1 \
    | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')

echo -e "  ${BLUE}→${NC} Downloading ${APP_NAME} ${VERSION}..."
curl -fsSL --progress-bar "$DOWNLOAD_URL" -o "${TMP_DIR}/${APP_NAME}.zip"

echo -e "  ${BLUE}→${NC} Extracting..."
unzip -q "${TMP_DIR}/${APP_NAME}.zip" -d "$TMP_DIR"

# Find the .app bundle
APP_BUNDLE=$(find "$TMP_DIR" -name "*.app" -maxdepth 2 | head -1)
if [[ -z "$APP_BUNDLE" ]]; then
    echo -e "${RED}  ✗ Could not find .app bundle in archive.${NC}"
    rm -rf "$TMP_DIR"
    exit 1
fi

# Remove old version if exists
if [[ -d "${INSTALL_DIR}/${APP_NAME}.app" ]]; then
    echo -e "  ${YELLOW}→${NC} Removing previous version..."
    rm -rf "${INSTALL_DIR}/${APP_NAME}.app"
fi

echo -e "  ${BLUE}→${NC} Installing to ${INSTALL_DIR}..."
cp -r "$APP_BUNDLE" "${INSTALL_DIR}/"

# Remove quarantine attribute (required for unsigned apps)
echo -e "  ${BLUE}→${NC} Removing macOS quarantine flag..."
xattr -rd com.apple.quarantine "${INSTALL_DIR}/${APP_NAME}.app" 2>/dev/null || true

# Cleanup
rm -rf "$TMP_DIR"

echo ""
echo -e "  ${GREEN}✓ ${APP_NAME} ${VERSION} installed successfully!${NC}"
echo ""
echo -e "  ${YELLOW}ℹ️  First launch:${NC}"
echo -e "  Since playSom is not signed with an Apple Developer certificate,"
echo -e "  macOS will show a warning the first time."
echo ""
echo -e "  To open it:"
echo -e "  1. Go to ${INSTALL_DIR}/${APP_NAME}.app"
echo -e "  2. Right-click → Open"
echo -e "  3. Click 'Open' in the dialog"
echo ""
echo -e "  Or run: ${BLUE}open \"${INSTALL_DIR}/${APP_NAME}.app\"${NC}"
echo ""
