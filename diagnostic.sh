#!/bin/bash

# Ellenőrizzük, hogy root jogokkal futunk-e
if [ "$EUID" -eq 0 ]; then
    SUDO_MODE=true
    printf "Futás: %sroot jogokkal%s (teljes diagnosztika)\n" "$GREEN" "$NC"
else
    SUDO_MODE=false
    printf "Futás: %sfelhasználói jogokkal%s (korlátozott diagnosztika)\n" "$YELLOW" "$NC"
    printf "%sTipp:%s Futtasd 'sudo %s'-vel a teljes diagnosztikához\n\n" "$CYAN" "$NC" "$0"
fi

# Színek definiálása - printf használatával a kompatibilitás érdekében
RED=$(printf '\033[0;31m')
GREEN=$(printf '\033[0;32m')
YELLOW=$(printf '\033[1;33m')
BLUE=$(printf '\033[0;34m')
PURPLE=$(printf '\033[0;35m')
CYAN=$(printf '\033[0;36m')
NC=$(printf '\033[0m') # No Color

# Ellenőrizzük, hogy a terminál támogatja-e a színeket
if [ ! -t 1 ] || [ "$TERM" = "dumb" ]; then
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    PURPLE=""
    CYAN=""
    NC=""
fi

# Funkció a szekciók elválasztásához
print_section() {
    printf "\n%s================================%s\n" "$BLUE" "$NC"
    printf "%s%s%s\n" "$BLUE" "$1" "$NC"
    printf "%s================================%s\n" "$BLUE" "$NC"
}

# Funkció hibák színes kiemeléséhez
highlight_errors() {
    sed -E "s/.*(error|Error|ERROR|failed|Failed|FAILED|fatal|Fatal|FATAL|critical|Critical|CRITICAL).*/${RED}&${NC}/"
}

print_section "RENDSZER INFORMÁCIÓK"

# Disztribúció neve és verziója
printf "%sDisztribúció:%s\n" "$CYAN" "$NC"
if command -v lsb_release &> /dev/null; then
    lsb_release -a 2>/dev/null
else
    cat /etc/*-release 2>/dev/null | head -10
fi

# Kernel verzió és architektúra
printf "\n%sKernel információk:%s\n" "$CYAN" "$NC"
printf "   Verzió: %s\n" "$(uname -r)"
printf "   Architektúra: %s\n" "$(uname -m)"
printf "   Rendszer: %s\n" "$(uname -s)"

# Memória és Swap
printf "\n%sMemória és swap:%s\n" "$CYAN" "$NC"
free -h

# CPU információk
printf "\n%sCPU információk:%s\n" "$CYAN" "$NC"
printf "   Modell: %s\n" "$(grep 'model name' /proc/cpuinfo | head -1 | cut -d':' -f2 | xargs)"
printf "   Magok száma: %s\n" "$(nproc)"
printf "   Architektúra: %s\n" "$(lscpu | grep Architecture | cut -d':' -f2 | xargs)"

print_section "DISPLAY RENDSZER"

# Grafikus rendszer (X11/Wayland) detektálása
printf "%sAktív display rendszer:%s\n" "$CYAN" "$NC"
if [ -n "$WAYLAND_DISPLAY" ]; then
    printf "   %sWayland aktív%s (WAYLAND_DISPLAY: %s)\n" "$GREEN" "$NC" "$WAYLAND_DISPLAY"
    DISPLAY_SERVER="wayland"
elif [ -n "$DISPLAY" ]; then
    printf "   %sX11 aktív%s (DISPLAY: %s)\n" "$GREEN" "$NC" "$DISPLAY"
    DISPLAY_SERVER="x11"
else
    printf "   %sGrafikus környezet nem észlelhető%s\n" "$YELLOW" "$NC"
    DISPLAY_SERVER="unknown"
fi

# Session információk
printf "\n%sSession információk:%s\n" "$CYAN" "$NC"
printf "   XDG_SESSION_TYPE: %s\n" "${XDG_SESSION_TYPE:-nincs beállítva}"
printf "   XDG_SESSION_DESKTOP: %s\n" "${XDG_SESSION_DESKTOP:-nincs beállítva}"
printf "   XDG_CURRENT_DESKTOP: %s\n" "${XDG_CURRENT_DESKTOP:-nincs beállítva}"
printf "   DESKTOP_SESSION: %s\n" "${DESKTOP_SESSION:-nincs beállítva}"

# Wayland compositor információk
if [ "$DISPLAY_SERVER" = "wayland" ]; then
    printf "\n%sWayland compositor:%s\n" "$CYAN" "$NC"
    if command -v loginctl &> /dev/null; then
        SESSION_ID=$(loginctl show-user $USER -p Display --value 2>/dev/null)
        if [ -n "$SESSION_ID" ]; then
            printf "   Session ID: %s\n" "$SESSION_ID"
        fi
    fi
    
    # Népszerű Wayland compositorok keresése
    for compositor in sway gnome-shell kwin_wayland weston mutter; do
        if pgrep -x "$compositor" > /dev/null; then
            printf "   %sFutó compositor: %s%s\n" "$GREEN" "$compositor" "$NC"
        fi
    done
fi

# GPU információk
printf "\n%sGPU információk:%s\n" "$CYAN" "$NC"
if command -v lspci &> /dev/null; then
    lspci | grep -i vga | while read line; do
        printf "   %s\n" "$line"
    done
    # 3D gyorsítás ellenőrzése
    if command -v glxinfo &> /dev/null && [ "$DISPLAY_SERVER" = "x11" ]; then
        printf "   3D gyorsítás (X11): %s\n" "$(glxinfo | grep "direct rendering" | cut -d':' -f2 | xargs)"
    fi
fi

print_section "LOGOK ELLENŐRZÉSE"

# Systemd journal (prioritás)
printf "%sSystemd journal hibák (utolsó 50 bejegyzés):%s\n" "$CYAN" "$NC"
if command -v journalctl &> /dev/null; then
    journalctl -p err -n 50 --no-pager 2>/dev/null | highlight_errors
    
    printf "\n%sGrafikus szolgáltatások hibái:%s\n" "$CYAN" "$NC"
    # Display manager hibák
    for dm in gdm gdm3 sddm lightdm xdm; do
        if systemctl is-active --quiet $dm 2>/dev/null; then
            printf "\n   %s%s hibák:%s\n" "$YELLOW" "$dm" "$NC"
            journalctl -u $dm -p warning -n 10 --no-pager 2>/dev/null | highlight_errors
        fi
    done
    
    # Wayland/compositor hibák
    if [ "$DISPLAY_SERVER" = "wayland" ]; then
        printf "\n   %sWayland/compositor hibák:%s\n" "$YELLOW" "$NC"
        journalctl --user -p warning -n 20 --no-pager 2>/dev/null | grep -i -E "(wayland|compositor|gnome-shell|sway|kwin)" | highlight_errors
    fi
else
    printf "   journalctl nem elérhető\n"
fi

# Xorg logok (ha X11)
if [ "$DISPLAY_SERVER" = "x11" ]; then
    printf "\n%sXorg logok:%s\n" "$CYAN" "$NC"
    XORG_LOG=""
    for log_path in "/var/log/Xorg.0.log" "$HOME/.local/share/xorg/Xorg.0.log" "/var/log/X11/Xorg.0.log"; do
        if [ -f "$log_path" ]; then
            XORG_LOG="$log_path"
            break
        fi
    done
    
    if [ -n "$XORG_LOG" ]; then
        printf "   Log fájl: %s\n" "$XORG_LOG"
        grep -E "\\(WW\\)|\\(EE\\)|\\(II\\) Loading.*failed" "$XORG_LOG" 2>/dev/null | tail -20 | highlight_errors
    else
        printf "   %sXorg log nem található%s\n" "$YELLOW" "$NC"
    fi
fi

# Wayland hibák keresése
if [ "$DISPLAY_SERVER" = "wayland" ]; then
    printf "\n%sWayland specifikus hibák:%s\n" "$CYAN" "$NC"
    
    # Wayland környezeti változók ellenőrzése
    printf "   Környezeti változók:\n"
    printf "     WAYLAND_DISPLAY: %s\n" "${WAYLAND_DISPLAY:-nincs beállítva}"
    printf "     XDG_RUNTIME_DIR: %s\n" "${XDG_RUNTIME_DIR:-nincs beállítva}"
    
    # Wayland socket ellenőrzése
    if [ -n "$XDG_RUNTIME_DIR" ] && [ -n "$WAYLAND_DISPLAY" ]; then
        WAYLAND_SOCKET="$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY"
        if [ -S "$WAYLAND_SOCKET" ]; then
            printf "     %sWayland socket OK: %s%s\n" "$GREEN" "$WAYLAND_SOCKET" "$NC"
        else
            printf "     %sWayland socket hiányzik: %s%s\n" "$RED" "$WAYLAND_SOCKET" "$NC"
        fi
    fi
    
    # User session hibák
    printf "\n   User session hibák:\n"
    journalctl --user -p err -n 10 --no-pager 2>/dev/null | highlight_errors
fi

# Syslog (ha létezik és olvasható)
printf "\n%sSyslog hibák:%s\n" "$CYAN" "$NC"
if [ -f /var/log/syslog ]; then
    if [ "$SUDO_MODE" = true ] || [ -r /var/log/syslog ]; then
        grep -i -E "(error|failed|critical)" /var/log/syslog 2>/dev/null | tail -10 | highlight_errors
    else
        printf "   %sSyslog olvasásához sudo jogok szükségesek%s\n" "$YELLOW" "$NC"
    fi
else
    printf "   Syslog nem található\n"
fi

# dmesg hibák
printf "\n%sKernel hibák (dmesg):%s\n" "$CYAN" "$NC"
if [ "$SUDO_MODE" = true ]; then
    dmesg --level=err,warn 2>/dev/null | tail -15 | highlight_errors
else
    # Felhasználói módban próbáljuk meg, de lehet korlátozva lesz
    if dmesg --level=err,warn 2>/dev/null | head -1 >/dev/null 2>&1; then
        dmesg --level=err,warn 2>/dev/null | tail -15 | highlight_errors
    else
        printf "   %sdmesg olvasásához sudo jogok szükségesek%s\n" "$YELLOW" "$NC"
    fi
fi

print_section "HÁLÓZAT"

# Hálózati interfészek
printf "%sHálózati interfészek:%s\n" "$CYAN" "$NC"
if command -v ip &> /dev/null; then
    ip -brief addr show
else
    ifconfig 2>/dev/null | grep -E "(^[a-zA-Z]|inet )"
fi

# DNS beállítások
printf "\n%sDNS beállítások:%s\n" "$CYAN" "$NC"
if [ -f /etc/resolv.conf ]; then
    grep nameserver /etc/resolv.conf 2>/dev/null
else
    printf "   /etc/resolv.conf nem található\n"
fi

print_section "SZOLGÁLTATÁSOK"

# Fontos szolgáltatások állapota
printf "%sKritikus szolgáltatások:%s\n" "$CYAN" "$NC"
services=("NetworkManager" "systemd-resolved" "bluetooth" "cups")

for service in "${services[@]}"; do
    if systemctl list-unit-files | grep -q "^$service"; then
        status=$(systemctl is-active $service 2>/dev/null)
        if [ "$status" = "active" ]; then
            printf "   %s%s: aktív%s\n" "$GREEN" "$service" "$NC"
        else
            printf "   %s%s: %s%s\n" "$RED" "$service" "$status" "$NC"
        fi
    fi
done

print_section "TELJESÍTMÉNY"

# Load average
printf "%sRendszerterhelés:%s\n" "$CYAN" "$NC"
uptime

# Lemezhasználat
printf "\n%sLemezhasználat:%s\n" "$CYAN" "$NC"
# Összes csatolt fájlrendszer megjelenítése, duplikátumok kiszűrésével
df -h -x tmpfs -x devtmpfs -x squashfs 2>/dev/null | awk '
NR==1 {print; next}  # Header sor megtartása
!seen[$1]++ {print}  # Csak az első előfordulást tartjuk meg minden eszközből
' | grep -v "^udev\|^tmpfs"

# Futó processzek (top 10 CPU használat szerint)
printf "\n%sTop 10 CPU-igényes folyamat:%s\n" "$CYAN" "$NC"
ps auxf --sort=-%cpu | head -11

print_section "ÖSSZEFOGLALÓ"

# Kritikus problémák összefoglalása
printf "%sGyors egészségügyi ellenőrzés:%s\n" "$CYAN" "$NC"

# Display rendszer
if [ "$DISPLAY_SERVER" = "wayland" ]; then
    printf "   Display: %sWayland fut%s\n" "$GREEN" "$NC"
elif [ "$DISPLAY_SERVER" = "x11" ]; then
    printf "   Display: %sX11 fut%s\n" "$GREEN" "$NC"
else
    printf "   Display: %sGrafikus környezet nem észlelhető%s\n" "$RED" "$NC"
fi

# Memória használat
MEM_USAGE=$(free | grep Mem | awk '{printf("%.0f", $3/$2 * 100)}')
if [ "$MEM_USAGE" -gt 90 ]; then
    printf "   Memória: %sKritikus (%s%%)%s\n" "$RED" "$MEM_USAGE" "$NC"
elif [ "$MEM_USAGE" -gt 80 ]; then
    printf "   Memória: %sMagas (%s%%)%s\n" "$YELLOW" "$MEM_USAGE" "$NC"
else
    printf "   Memória: %sOK (%s%%)%s\n" "$GREEN" "$MEM_USAGE" "$NC"
fi

# Lemezhasználat az összefoglalóban - legfontosabb partíció
DISK_USAGE=$(df / 2>/dev/null | awk 'NR==2 {print $5}' | sed 's/%//')
if [ -n "$DISK_USAGE" ]; then
    if [ "$DISK_USAGE" -gt 90 ]; then
        printf "   Lemez (/): %sKritikus (%s%%)%s\n" "$RED" "$DISK_USAGE" "$NC"
    elif [ "$DISK_USAGE" -gt 80 ]; then
        printf "   Lemez (/): %sMagas (%s%%)%s\n" "$YELLOW" "$DISK_USAGE" "$NC"
    else
        printf "   Lemez (/): %sOK (%s%%)%s\n" "$GREEN" "$DISK_USAGE" "$NC"
    fi
else
    printf "   Lemez: %sNem sikerült ellenőrizni%s\n" "$YELLOW" "$NC"
fi

printf "\n%sDiagnosztika befejezve!%s\n" "$GREEN" "$NC"
echo -e "${YELLOW}Tipp: A script kimenetét fájlba mentheted:${NC} $0 > diagnostic_\$(date +%Y%m%d_%H%M%S).log"