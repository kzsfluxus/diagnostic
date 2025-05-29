# Linux rendszer-diagnosztikai szkript

## 📋 Áttekintés

Ez egy átfogó Linux rendszer-diagnosztikai szkript, amely részletes információkat gyűjt a rendszer állapotáról, teljesítményéről és potenciális problémáiról. A szkript magyar nyelven íródott és színes, könnyen olvasható kimenetet biztosít.

## ✨ Funkciók

### 🖥️ Rendszer Információk
- Disztribúció neve és verziója
- Kernel információk és architektúra
- CPU részletek (modell, magok száma)
- Memória és swap használat

### 🎮 Display Rendszer
- Automatikus X11/Wayland detektálás
- Session információk (XDG változók)
- GPU információk és 3D gyorsítás ellenőrzés
- Wayland compositor felismerés

### 📊 Log Elemzés
- Systemd journal hibák elemzése
- Display manager hibák (GDM, SDDM, LightDM)
- Xorg logok elemzése (X11 esetén)
- Wayland specifikus hibák
- Kernel hibák (dmesg)
- Syslog elemzés

### 🌐 Hálózat
- Hálózati interfészek állapota
- DNS beállítások ellenőrzése

### ⚙️ Szolgáltatások
- Kritikus rendszerszolgáltatások állapota
- NetworkManager, systemd-resolved, bluetooth, CUPS

### 📈 Teljesítmény
- Rendszerterhelés (load average)
- Lemezhasználat elemzése
- Top 10 CPU-igényes folyamat

### 📝 Összefoglaló
- Gyors egészségügyi ellenőrzés
- Kritikus problémák kiemelése
- Színkódolt állapotjelzők

## 🚀 Használat

### Alapvető futtatás
```bash
./diagnostic_script.sh
```

### Root jogokkal (teljes diagnosztika)
```bash
sudo ./diagnostic_script.sh
```

### Kimenet mentése fájlba
```bash
./diagnostic_script.sh > diagnostic_$(date +%Y%m%d_%H%M%S).log
```

## 📋 Előfeltételek

### Alapvető követelmények
- Linux rendszer
- Bash shell
- Standard Unix eszközök (ps, df, free, uname)

### Opcionális eszközök (jobb funkcionalitásért)
- `systemd` és `journalctl` (modern disztribúciókban standard)
- `lspci` (GPU információkhoz)
- `glxinfo` (3D gyorsítás ellenőrzéséhez X11-ben)
- `lsb_release` (disztribúció információkhoz)

### Telepítés Ubuntu/Debian-on
```bash
sudo apt update
sudo apt install pciutils mesa-utils lsb-release
```

### Telepítés RHEL/CentOS/Fedora-n
```bash
sudo dnf install pciutils mesa-dri-drivers redhat-lsb-core
# vagy CentOS 7/RHEL 7-en:
sudo yum install pciutils mesa-dri-drivers redhat-lsb-core
```

## 🎨 Kimeneti Példa

```
================================
RENDSZER INFORMÁCIÓK
================================
Disztribúció:
Ubuntu 22.04.3 LTS

Kernel információk:
   Verzió: 5.19.0-46-generic
   Architektúra: x86_64

================================
DISPLAY RENDSZER
================================
Aktív display rendszer:
   Wayland aktív (WAYLAND_DISPLAY: wayland-0)

================================
ÖSSZEFOGLALÓ
================================
Gyors egészségügyi ellenőrzés:
   Display: Wayland fut
   Memória: OK (45%)
   Lemez (/): OK (67%)
```

## 🔧 Jogosultságok

### Felhasználói mód
- Alapvető rendszer információk
- Grafikus környezet állapota
- Felhasználói session logok
- Hálózati interfészek
- Lemezhasználat

### Root mód (sudo)
- Minden felhasználói funkció
- Rendszer logok teljes hozzáférése
- Kernel üzenetek (dmesg)
- Rendszerszolgáltatások részletes állapota
- Syslog hozzáférés

## 🎯 Támogatott Rendszerek

### Tesztelt disztribúciók
- Ubuntu 20.04+
- Debian 11+
- Fedora 35+
- CentOS 8+
- openSUSE Leap 15+

### Desktop környezetek
- GNOME (X11/Wayland)
- KDE Plasma (X11/Wayland)
- Sway (Wayland)
- XFCE (X11)
- i3/i3-gaps (X11)

## 🔍 Hibaelhárítás

### "Command not found" hibák
Telepítsd a hiányzó csomagokat:
```bash
# Ubuntu/Debian
sudo apt install pciutils mesa-utils

# Fedora
sudo dnf install pciutils mesa-dri-drivers
```

### Színek nem jelennek meg
A script automatikusan érzékeli a terminál képességeit. Ha mégis problémád van:
```bash
export TERM=xterm-256color
./diagnostic_script.sh
```

### Jogosultsági hibák
```bash
# Teljes diagnosztikához
sudo ./diagnostic_script.sh

# Vagy adj végrehajtási jogot
chmod +x diagnostic_script.sh
```

## 📁 Kimenet Mentése

### Automatikus fájlnév időbélyeggel
```bash
./diagnostic_script.sh > diagnostic_$(date +%Y%m%d_%H%M%S).log
```

### Hibák is a fájlba
```bash
./diagnostic_script.sh > diagnostic.log 2>&1
```

### Színkódok eltávolítása mentéskor
```bash
./diagnostic_script.sh | sed 's/\x1b\[[0-9;]*m//g' > diagnostic_clean.log
```

## 📋 Changelog

### v1.0.0
- Kezdeti kiadás
- Alapvető rendszer diagnosztika
- X11/Wayland támogatás
- Színes kimenet
- Magyar lokalizáció

---

**Készítette:** [kzsfluxus]  
**Utolsó frissítés:** 2025-05-29