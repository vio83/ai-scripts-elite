#!/bin/bash
# VIO Super AI - Mac System Monitor Installation Script
# World Record Level Quality - Professional Installation

set -e

COLORS_RED='\033[0;31m'
COLORS_GREEN='\033[0;32m'
COLORS_YELLOW='\033[1;33m'
COLORS_BLUE='\033[0;34m'
COLORS_CYAN='\033[0;36m'
COLORS_NC='\033[0m' # No Color

echo -e "${COLORS_CYAN}╔═══════════════════════════════════════════════════════════════════════╗${COLORS_NC}"
echo -e "${COLORS_CYAN}║${COLORS_NC}  VIO Super AI - Mac System Monitor Installation              ${COLORS_CYAN}║${COLORS_NC}"
echo -e "${COLORS_CYAN}╚═══════════════════════════════════════════════════════════════════════╝${COLORS_NC}"
echo ""

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${COLORS_RED}Error: This tool is designed for macOS only.${COLORS_NC}"
    exit 1
fi

echo -e "${COLORS_BLUE}→${COLORS_NC} Checking Python installation..."
if ! command -v python3 &> /dev/null; then
    echo -e "${COLORS_RED}✗ Python 3 is not installed. Please install Python 3 first.${COLORS_NC}"
    exit 1
fi
echo -e "${COLORS_GREEN}✓ Python 3 found${COLORS_NC}"

echo -e "${COLORS_BLUE}→${COLORS_NC} Checking pip installation..."
if ! command -v pip3 &> /dev/null; then
    echo -e "${COLORS_RED}✗ pip3 is not installed. Please install pip3 first.${COLORS_NC}"
    exit 1
fi
echo -e "${COLORS_GREEN}✓ pip3 found${COLORS_NC}"

echo -e "${COLORS_BLUE}→${COLORS_NC} Installing required dependencies..."
pip3 install --user psutil || {
    echo -e "${COLORS_YELLOW}! Using sudo to install psutil...${COLORS_NC}"
    sudo pip3 install psutil
}
echo -e "${COLORS_GREEN}✓ psutil installed${COLORS_NC}"

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
MONITOR_SCRIPT="$SCRIPT_DIR/mac_system_monitor.py"

# Make the monitor script executable
chmod +x "$MONITOR_SCRIPT"
echo -e "${COLORS_GREEN}✓ Made monitor script executable${COLORS_NC}"

# Create a symlink in /usr/local/bin for easy access (optional)
echo ""
echo -e "${COLORS_YELLOW}Do you want to create a symlink in /usr/local/bin? (y/n)${COLORS_NC}"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    sudo ln -sf "$MONITOR_SCRIPT" /usr/local/bin/vio-monitor
    echo -e "${COLORS_GREEN}✓ Symlink created: vio-monitor${COLORS_NC}"
    echo -e "${COLORS_CYAN}  You can now run the monitor with: vio-monitor${COLORS_NC}"
fi

# Auto-launch setup
echo ""
echo -e "${COLORS_YELLOW}Do you want to auto-launch the monitor on Terminal startup? (y/n)${COLORS_NC}"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    SHELL_RC=""
    
    # Detect shell
    if [[ "$SHELL" == *"zsh"* ]]; then
        SHELL_RC="$HOME/.zshrc"
    elif [[ "$SHELL" == *"bash"* ]]; then
        SHELL_RC="$HOME/.bashrc"
    fi
    
    if [[ -n "$SHELL_RC" ]]; then
        # Check if already added
        if grep -q "vio-monitor" "$SHELL_RC" 2>/dev/null; then
            echo -e "${COLORS_YELLOW}! Auto-launch already configured in $SHELL_RC${COLORS_NC}"
        else
            echo "" >> "$SHELL_RC"
            echo "# VIO Super AI - Mac System Monitor Auto-Launch" >> "$SHELL_RC"
            echo "# Uncomment the line below to auto-start the monitor" >> "$SHELL_RC"
            echo "# python3 \"$MONITOR_SCRIPT\"" >> "$SHELL_RC"
            echo -e "${COLORS_GREEN}✓ Auto-launch configuration added to $SHELL_RC${COLORS_NC}"
            echo -e "${COLORS_CYAN}  Edit $SHELL_RC and uncomment the last line to enable auto-start${COLORS_NC}"
        fi
    else
        echo -e "${COLORS_YELLOW}! Could not detect shell configuration file${COLORS_NC}"
    fi
fi

echo ""
echo -e "${COLORS_GREEN}╔═══════════════════════════════════════════════════════════════════════╗${COLORS_NC}"
echo -e "${COLORS_GREEN}║${COLORS_NC}  Installation Complete!                                       ${COLORS_GREEN}║${COLORS_NC}"
echo -e "${COLORS_GREEN}╚═══════════════════════════════════════════════════════════════════════╝${COLORS_NC}"
echo ""
echo -e "${COLORS_CYAN}To start the monitor, run:${COLORS_NC}"
echo -e "  ${COLORS_YELLOW}python3 $MONITOR_SCRIPT${COLORS_NC}"
if command -v vio-monitor &> /dev/null; then
    echo -e "  ${COLORS_YELLOW}or simply: vio-monitor${COLORS_NC}"
fi
echo ""
echo -e "${COLORS_CYAN}Configuration:${COLORS_NC}"
echo -e "  Edit the CONFIG dictionary in $MONITOR_SCRIPT to customize thresholds"
echo ""
