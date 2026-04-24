#!/bin/bash

# WhiteSur Icons Installer - Gray Alternative Version
# This script installs WhiteSur icons theme in gray color variant
# Usage: ./install.sh [OPTIONS]

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default variables
REPO_URL="https://github.com/vinceliuice/WhiteSur-icon-theme.git"
TMP_DIR="${TMPDIR:-/tmp}/whitesur-icons-$$"
ICON_VARIANT="gray"
HELP=false

# Function to display help
show_help() {
    cat << EOF
${BLUE}WhiteSur Icons Installer - Gray Alternative Version${NC}

${GREEN}Usage:${NC}
    ./install.sh [OPTIONS]

${GREEN}Options:${NC}
    -h, --help          Show this help message
    -v, --variant       Icon variant (default: gray)
    -t, --theme         Theme name to use
    --no-cleanup        Keep temporary files after installation

${GREEN}Description:${NC}
    This script installs WhiteSur icon theme in gray alternative version.
    It clones the repository to a temporary folder and installs the icons.

${GREEN}Desktop Application Icons:${NC}
    For snap applications, copy the .desktop file from:
        /var/lib/snapd/desktop/applications/name-of-the-snap-application.desktop

    To: \$HOME/.local/share/applications/

    Then edit the Icon= line to point to the desired icon:
        Icon=name-of-the-icon.svg

${GREEN}Examples:${NC}
    ./install.sh --variant gray
    ./install.sh --help

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--variant)
            ICON_VARIANT="$2"
            shift 2
            ;;
        --no-cleanup)
            KEEP_TMP=true
            shift
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Function to cleanup
cleanup() {
    if [ -z "$KEEP_TMP" ] && [ -d "$TMP_DIR" ]; then
        echo -e "${YELLOW}Cleaning up temporary files...${NC}"
        rm -rf "$TMP_DIR"
    fi
}

# Trap to cleanup on exit
trap cleanup EXIT

# Main installation function
main() {
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  WhiteSur Icons - Gray Variant Install  ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo ""

    # Check if git is installed
    if ! command -v git &> /dev/null; then
        echo -e "${RED}Error: git is not installed. Please install git first.${NC}"
        exit 1
    fi

    # Create temporary directory
    echo -e "${YELLOW}Creating temporary directory: $TMP_DIR${NC}"
    mkdir -p "$TMP_DIR"

    # Clone the repository
    echo -e "${YELLOW}Cloning WhiteSur icon theme repository...${NC}"
    if ! git clone --depth 1 "$REPO_URL" "$TMP_DIR/whitesur"; then
        echo -e "${RED}Error: Failed to clone repository.${NC}"
        exit 1
    fi

    echo -e "${GREEN}✓ Repository cloned successfully${NC}"

    # Navigate to the cloned directory
    cd "$TMP_DIR/whitesur" || exit 1

    # Check if install script exists
    if [ ! -f "install.sh" ]; then
        echo -e "${RED}Error: install.sh not found in repository.${NC}"
        exit 1
    fi

    # Run the installation
    echo -e "${YELLOW}Installing WhiteSur icons (${ICON_VARIANT} variant)...${NC}"

    # Make install script executable
    chmod +x install.sh

    # Run install with gray variant
    if ./install.sh -t grey -a; then
        echo -e "${GREEN}✓ Installation completed successfully!${NC}"
        echo ""
        echo -e "${BLUE}Installation Summary:${NC}"
        echo -e "  Variant: ${YELLOW}${ICON_VARIANT}${NC}"
        echo -e "  Location: ${YELLOW}${HOME}/.local/share/icons/WhiteSur${NC}"
        echo ""
        echo -e "${BLUE}For Snap Application Icons:${NC}"
        echo -e "  1. Copy .desktop file from /var/lib/snapd/desktop/applications/ to:"
        echo -e "     ${YELLOW}\$HOME/.local/share/applications/${NC}"
        echo -e "  2. Edit the Icon= line to match the installed icon theme"
        echo ""
    else
        echo -e "${RED}Error: Installation failed.${NC}"
        exit 1
    fi
}

# Run main function
main
