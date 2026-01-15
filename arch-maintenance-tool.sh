#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# check for root privileges
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run with sudo.${NC}"
   exit 1
fi

# detect the real user
if [ -n "$SUDO_USER" ]; then
    REAL_USER=$SUDO_USER
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    echo -e "${RED}Please run this script via sudo (e.g., sudo ./script.sh)${NC}"
    exit 1
fi

get_size() {
    du -s "$1" 2>/dev/null | cut -f1 || echo "0"
}

format_size() {
    numfmt --to=iec --from-unit=1K "$1"
}

clear
echo -e "${BLUE}--- ARCH LINUX CLEANUP: ANALYSIS PHASE ---${NC}"

# --- PHASE 1: GATHERING DATA ---

echo "Analyzing system..."

# Pacman
SIZE_PAC_RAW=$(get_size /var/cache/pacman/pkg/)
SIZE_PAC_HUMAN=$(format_size $SIZE_PAC_RAW)

# AUR
AUR_DIR=""
AUR_HELPER="none"
SIZE_AUR_RAW=0
if [ -d "$USER_HOME/.cache/yay" ]; then
    AUR_DIR="$USER_HOME/.cache/yay"
    AUR_HELPER="yay"
elif [ -d "$USER_HOME/.cache/paru" ]; then
    AUR_DIR="$USER_HOME/.cache/paru"
    AUR_HELPER="paru"
fi

if [ "$AUR_HELPER" != "none" ]; then
    SIZE_AUR_RAW=$(get_size "$AUR_DIR")
fi
SIZE_AUR_HUMAN=$(format_size $SIZE_AUR_RAW)

# orphans
ORPHANS_LIST=$(pacman -Qtdq)
ORPHANS_COUNT=0
if [[ -n "$ORPHANS_LIST" ]]; then
    ORPHANS_COUNT=$(echo "$ORPHANS_LIST" | wc -w)
fi

# logs
LOGS_SIZE=$(journalctl --disk-usage | awk '{print $NF}')

# thumbnails cache
SIZE_CACHE_RAW=$(get_size "$USER_HOME/.cache/thumbnails")
SIZE_CACHE_HUMAN=$(format_size $SIZE_CACHE_RAW)


# --- PHASE 2: REPORT AND CONFIRMATION ---

echo ""
echo "========================================"
echo -e "      ${YELLOW}PROPOSED CLEANUP${NC}"
echo "========================================"
echo -e "1. Pacman cache:    ${RED}$SIZE_PAC_HUMAN${NC} (only 3 latest versions kept)"
echo -e "2. AUR cache:       ${RED}$SIZE_AUR_HUMAN${NC} (removes $AUR_HELPER build sources)"
echo -e "3. System logs:     ${RED}$LOGS_SIZE${NC} (will be vacuumed to 50MB)"
echo -e "4. Thumbnails:      ${RED}$SIZE_CACHE_HUMAN${NC} (will be fully removed)"
echo "----------------------------------------"
echo -e "5. Orphan Packages: ${RED}$ORPHANS_COUNT${NC}"

if [[ $ORPHANS_COUNT -gt 0 ]]; then
    echo -e "${YELLOW}Verify if these are safe to remove:${NC}"
    echo -e "$ORPHANS_LIST"
fi
echo "========================================"
echo ""

read -p "Do you want to proceed with cleanup? [y/N]: " decision
case "$decision" in
    [yY])
        echo ""
        echo -e "${GREEN}Starting cleanup...${NC}"
        ;;
    *)
        echo ""
        echo "Aborted. No changes were made."
        exit 0
        ;;
esac


# --- PHASE 3: EXECUTION ---

# Pacman
if ! command -v paccache &> /dev/null; then
    echo "Installing pacman-contrib..."
    pacman -S --noconfirm pacman-contrib &>/dev/null
fi
paccache -r &>/dev/null
paccache -ruk0 &>/dev/null

# AUR
if [ "$AUR_HELPER" == "yay" ]; then
    sudo -u "$REAL_USER" yay -Sc --noconfirm &>/dev/null
elif [ "$AUR_HELPER" == "paru" ]; then
    sudo -u "$REAL_USER" paru -Sc --noconfirm &>/dev/null
fi

# orphans
if [[ -n "$ORPHANS_LIST" ]]; then
    pacman -Rns $ORPHANS_LIST --noconfirm &>/dev/null
fi

# logs
journalctl --vacuum-size=50M &>/dev/null

# thumbnails cache
rm -rf "$USER_HOME/.cache/thumbnails/*" &>/dev/null


# --- PHASE 4: FINAL REPORT ---
# Calculate sizes after cleanup
SIZE_PAC_AFTER=$(get_size /var/cache/pacman/pkg/)
if [ "$AUR_HELPER" != "none" ]; then
    SIZE_AUR_AFTER=$(get_size "$AUR_DIR")
else
    SIZE_AUR_AFTER=0
fi
SIZE_CACHE_AFTER=$(get_size "$USER_HOME/.cache/thumbnails")

# Calculate freed space
FREED_PAC=$((SIZE_PAC_RAW - SIZE_PAC_AFTER))
FREED_AUR=$((SIZE_AUR_RAW - SIZE_AUR_AFTER))
FREED_CACHE=$((SIZE_CACHE_RAW - SIZE_CACHE_AFTER))
TOTAL_FREED=$((FREED_PAC + FREED_AUR + FREED_CACHE))

echo ""
echo "========================================"
echo -e "          ${BLUE}SUCCESS${NC}"
echo "========================================"
echo -e "Total space freed: ${GREEN}$(format_size $TOTAL_FREED)${NC}"
echo "System logs vacuumed."
if [[ $ORPHANS_COUNT -gt 0 ]]; then
    echo "Removed $ORPHANS_COUNT orphan packages."
fi
echo "========================================"
echo "Press Enter to exit..."
read
