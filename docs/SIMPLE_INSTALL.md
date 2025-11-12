# Quick-Serve Enterprise - Simple Installation

## One-Command Install

### Linux / Ubuntu / Debian
```bash
curl -sSL https://raw.githubusercontent.com/hah23255/quick-serve-enterprise/main/install.sh | bash
```

### Android (Termux)
```bash
curl -sSL https://raw.githubusercontent.com/hah23255/quick-serve-enterprise/main/install-android.sh | bash
```

---

## Usage

### Start Server
```bash
~/qs-start
```

### Stop Server
```bash
~/qs-stop
```

### Sync with Another Device
```bash
~/qs-sync 192.168.1.120
```

---

## What Gets Installed

**Linux:**
- Binary: `~/.local/bin/quick-serve`
- Data: `~/quick-serve-data/`
- Port: 50080 (non-standard)

**Android:**
- Binary: `$PREFIX/bin/quick-serve`
- Data: `~/storage/shared/quick-serve/`
- Port: 50080 (non-standard)

---

## Auto-Sync Setup

### Between Two Devices

**Device 1 (192.168.1.120):**
```bash
~/qs-start
```

**Device 2 (192.168.1.122):**
```bash
~/qs-start
~/qs-sync 192.168.1.120  # Pull files from Device 1
```

Files automatically sync from Device 1 → Device 2.

### Continuous Sync (Optional)

Add to crontab for auto-sync every 5 minutes:
```bash
crontab -e
# Add this line:
*/5 * * * * $HOME/qs-sync 192.168.1.120 >/dev/null 2>&1
```

---

## Access from Browser

**From any device on same WiFi:**
```
http://192.168.1.120:50080
http://192.168.1.122:50080
```

**From Android to Linux:**
```
http://192.168.1.120:50080
```

**From Linux to Android:**
```
http://192.168.1.122:50080
```

---

## Requirements

**Linux:**
- curl
- git
- Internet connection (first install only)

**Android:**
- Termux app (from F-Droid)
- Storage permission
- WiFi connection

---

## Port Configuration

Default port: **50080** (non-standard, no conflicts)

Change port:
```bash
~/qs-start 51234  # Use custom port
```

---

## Firewall

**Linux:** Automatically opened (port 50080)

**Android:** No firewall by default

---

## Uninstall

**Linux:**
```bash
rm -rf ~/quick-serve-enterprise
rm ~/.local/bin/quick-serve
rm ~/qs-start ~/qs-stop ~/qs-sync
```

**Android:**
```bash
rm -rf ~/quick-serve-enterprise
rm $PREFIX/bin/quick-serve
rm $PREFIX/bin/qs-*
```

---

## Troubleshooting

**Can't connect?**
```bash
# Check server running
ps aux | grep quick-serve

# Check port
ss -tlnp | grep 50080
```

**Sync not working?**
```bash
# Install rsync
# Linux:
sudo apt install rsync

# Android:
pkg install rsync
```

**Firewall blocking?**
```bash
sudo ufw allow 50080/tcp
```

---

## Support

- GitHub: https://github.com/hah23255/quick-serve-enterprise
- Issues: https://github.com/hah23255/quick-serve-enterprise/issues
