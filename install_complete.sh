#!/bin/bash
# VIO Super AI - Complete Setup with iPhone & Email Support
# Professional Installation Script

set -e

COLORS_RED='\033[0;31m'
COLORS_GREEN='\033[0;32m'
COLORS_YELLOW='\033[1;33m'
COLORS_BLUE='\033[0;34m'
COLORS_CYAN='\033[0;36m'
COLORS_NC='\033[0m' # No Color

echo -e "${COLORS_CYAN}╔═══════════════════════════════════════════════════════════════════════╗${COLORS_NC}"
echo -e "${COLORS_CYAN}║${COLORS_NC}  VIO Super AI - Complete Installation with iPhone Support     ${COLORS_CYAN}║${COLORS_NC}"
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
pip3 install --user psutil Flask || {
    echo -e "${COLORS_YELLOW}! Using sudo to install dependencies...${COLORS_NC}"
    sudo pip3 install psutil Flask
}
echo -e "${COLORS_GREEN}✓ Dependencies installed (psutil, Flask)${COLORS_NC}"

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Make scripts executable
chmod +x "$SCRIPT_DIR/mac_system_monitor.py" 2>/dev/null || true
chmod +x "$SCRIPT_DIR/mac_system_monitor_elite.py" 2>/dev/null || true
chmod +x "$SCRIPT_DIR/web_dashboard.py" 2>/dev/null || true
chmod +x "$SCRIPT_DIR/email_notifier.py" 2>/dev/null || true
echo -e "${COLORS_GREEN}✓ Scripts made executable${COLORS_NC}"

echo ""
echo -e "${COLORS_CYAN}╔═══════════════════════════════════════════════════════════════════════╗${COLORS_NC}"
echo -e "${COLORS_CYAN}║${COLORS_NC}  Configuration Options                                            ${COLORS_CYAN}║${COLORS_NC}"
echo -e "${COLORS_CYAN}╚═══════════════════════════════════════════════════════════════════════╝${COLORS_NC}"
echo ""

# Setup email notifications
echo -e "${COLORS_YELLOW}Do you want to configure email notifications? (y/n)${COLORS_NC}"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    python3 "$SCRIPT_DIR/email_notifier.py"
    echo ""
    echo -e "${COLORS_CYAN}Email config created at: ~/.vio_super_ai/email_config.json${COLORS_NC}"
    echo -e "${COLORS_YELLOW}Please edit this file with your email credentials${COLORS_NC}"
    echo ""
fi

# Display Mac IP address
echo ""
echo -e "${COLORS_CYAN}╔═══════════════════════════════════════════════════════════════════════╗${COLORS_NC}"
echo -e "${COLORS_CYAN}║${COLORS_NC}  Your Mac IP Address for iPhone Access                           ${COLORS_CYAN}║${COLORS_NC}"
echo -e "${COLORS_CYAN}╚═══════════════════════════════════════════════════════════════════════╝${COLORS_NC}"
echo ""
MAC_IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1)
if [ -n "$MAC_IP" ]; then
    echo -e "${COLORS_GREEN}Your Mac IP: ${COLORS_BOLD}${MAC_IP}${COLORS_NC}"
    echo -e "${COLORS_CYAN}Access from iPhone: ${COLORS_BOLD}http://${MAC_IP}:5000${COLORS_NC}"
else
    echo -e "${COLORS_YELLOW}Could not detect IP. Find it with: ifconfig${COLORS_NC}"
fi
echo ""

# Create symlink option
echo -e "${COLORS_YELLOW}Do you want to create easy-access commands? (y/n)${COLORS_NC}"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    sudo ln -sf "$SCRIPT_DIR/mac_system_monitor.py" /usr/local/bin/vio-monitor
    sudo ln -sf "$SCRIPT_DIR/mac_system_monitor_elite.py" /usr/local/bin/vio-monitor-elite
    sudo ln -sf "$SCRIPT_DIR/web_dashboard.py" /usr/local/bin/vio-dashboard
    echo -e "${COLORS_GREEN}✓ Commands created:${COLORS_NC}"
    echo -e "  ${COLORS_CYAN}vio-monitor${COLORS_NC}       - MINIMALIST version"
    echo -e "  ${COLORS_CYAN}vio-monitor-elite${COLORS_NC} - ELITE version"
    echo -e "  ${COLORS_CYAN}vio-dashboard${COLORS_NC}     - Web dashboard for iPhone"
fi

echo ""
echo -e "${COLORS_GREEN}╔═══════════════════════════════════════════════════════════════════════╗${COLORS_NC}"
echo -e "${COLORS_GREEN}║${COLORS_NC}  Installation Complete! 🎉                                        ${COLORS_GREEN}║${COLORS_NC}"
echo -e "${COLORS_GREEN}╚═══════════════════════════════════════════════════════════════════════╝${COLORS_NC}"
echo ""
echo -e "${COLORS_CYAN}📱 To use on iPhone:${COLORS_NC}"
echo -e "  1. Start web dashboard: ${COLORS_YELLOW}python3 web_dashboard.py${COLORS_NC}"
if [ -n "$MAC_IP" ]; then
    echo -e "  2. Open Safari on iPhone and go to: ${COLORS_YELLOW}http://${MAC_IP}:5000${COLORS_NC}"
else
    echo -e "  2. Open Safari on iPhone and go to: ${COLORS_YELLOW}http://YOUR_MAC_IP:5000${COLORS_NC}"
fi
echo -e "  3. Add to Home Screen for quick access"
echo ""
echo -e "${COLORS_CYAN}📧 Email Notifications:${COLORS_NC}"
echo -e "  Edit: ${COLORS_YELLOW}~/.vio_super_ai/email_config.json${COLORS_NC}"
echo -e "  See: ${COLORS_YELLOW}IPHONE_GUIDE.md${COLORS_NC} for complete setup"
echo ""
echo -e "${COLORS_CYAN}💻 To run monitors:${COLORS_NC}"
echo -e "  MINIMALIST: ${COLORS_YELLOW}python3 mac_system_monitor.py${COLORS_NC}"
echo -e "  ELITE:      ${COLORS_YELLOW}python3 mac_system_monitor_elite.py${COLORS_NC}"
echo ""
echo -e "${COLORS_CYAN}📖 Complete iPhone Guide: ${COLORS_YELLOW}IPHONE_GUIDE.md${COLORS_NC}"
echo ""
