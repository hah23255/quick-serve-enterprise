# DropBasket - Simple Installation

## One-Command Install

### Linux / Ubuntu / Debian
```bash
curl -sSL https://raw.githubusercontent.com/hah23255/quick-serve-enterprise/main/install.sh | bash
```

### Termux on Android
```bash
curl -sSL https://raw.githubusercontent.com/hah23255/quick-serve-enterprise/main/install-android.sh | bash
```

---

## Usage

### Start Server
```bash
qs-start
```

### Stop Server
```bash
qs-stop
```

### Sync with Another Device
```bash
qs-sync 192.168.1.120
```

---

## What Gets Installed

**Linux:**
- Binary: `~/.local/bin/quick-serve`
- Share folder: **`~/DropBasket/`** 🧺
- Desktop shortcut: DropBasket icon on desktop
- Port: 50080 (non-standard)

**Termux on Android:**
- Binary: `$PREFIX/bin/quick-serve`
- Share folder: **`~/storage/shared/DropBasket/`** 🧺
- Widgets: DropBasket-Start, DropBasket-Stop
- Port: 50080 (non-standard)

---

## Share Files

**Linux:**
```bash
# Copy files to DropBasket
cp /path/to/file.pdf ~/DropBasket/

# Or drag & drop into ~/DropBasket folder
```

**Termux:**
```bash
# Files in Android downloads automatically accessible
cp ~/storage/downloads/file.pdf ~/storage/shared/DropBasket/
```

---

## Auto-Sync Setup

### Between Two Devices

**Device 1 (Linux - 192.168.1.120):**
```bash
qs-start
```

**Device 2 (Termux - 192.168.1.122):**
```bash
qs-start
qs-sync 192.168.1.120  # Pull files from Device 1
```

Files in Linux DropBasket now sync to Android DropBasket.

### Continuous Sync (Optional)

**Linux - Auto-sync every 5 minutes:**
```bash
crontab -e
# Add: */5 * * * * $HOME/qs-sync 192.168.1.120
```

**Termux - Auto-sync with Termux:Task:**
```bash
# Install Termux:Task from F-Droid
# Schedule: qs-sync 192.168.1.120
```

---

## Access from Browser

**From any device on WiFi:**
```
http://192.168.1.120:50080  (Linux)
http://192.168.1.122:50080  (Termux)
```

**Beautiful landing page shows:**
- 🧺 DropBasket branding
- 📁 Available files
- 🔄 Sync status

---

## Desktop Shortcut (Linux)

**Location:** Desktop/DropBasket

**Icon:** Purple gradient basket (SVG)

**Click to:** Start server instantly

**Right-click options:**
- Start Server
- Stop Server
- Open DropBasket Folder

---

## Termux Widget (Android)

**Install:** Termux:Widget from F-Droid

**Widgets created:**
- DropBasket-Start (green)
- DropBasket-Stop (red)

**Add to home screen:** Long-press → Widgets → Termux → DropBasket

**Tap to:** Start/stop server instantly

---

## Requirements

**Linux:**
- curl, git
- Internet (first install only)

**Termux on Android:**
- Termux app (F-Droid, not Play Store)
- Storage permission
- WiFi

---

## Port Configuration

**Default:** 50080 (non-standard, no conflicts)

**Change:**
```bash
qs-start 51234  # Custom port
```

---

## Firewall

**Linux:** Auto-opened (port 50080)

**Termux:** No firewall needed

---

## Uninstall

**Linux:**
```bash
rm -rf ~/quick-serve-enterprise ~/DropBasket
rm ~/.local/bin/quick-serve
rm ~/qs-start ~/qs-stop ~/qs-sync
rm ~/Desktop/dropbasket.desktop
rm ~/.local/share/applications/dropbasket.desktop
```

**Termux:**
```bash
rm -rf ~/quick-serve-enterprise ~/storage/shared/DropBasket
rm $PREFIX/bin/quick-serve $PREFIX/bin/qs-*
rm ~/.shortcuts/DropBasket-*
```

---

## Features

✅ Human-friendly folder name (DropBasket)  
✅ Beautiful desktop shortcut with icon  
✅ Termux widgets for Android  
✅ One-command installation  
✅ Auto-configuration  
✅ Device synchronization  
✅ Non-standard ports only  
✅ Simple 3-command interface  

---

## Support

- GitHub: https://github.com/hah23255/quick-serve-enterprise
- Issues: https://github.com/hah23255/quick-serve-enterprise/issues
