# DropBasket User Manual 🧺

**Share files on your local network - Simple & Secure**

---

## What is DropBasket?

DropBasket turns your computer or phone into a file server. Drop files in, access from any device on WiFi.

**No cloud. No internet. No accounts. Just local sharing.**

---

## Quick Start

### 1. Install (One Command)

**Computer (Linux/Ubuntu):**
```bash
curl -sSL https://raw.githubusercontent.com/hah23255/quick-serve-enterprise/main/install.sh | bash
```

**Phone (Termux):**
```bash
curl -sSL https://raw.githubusercontent.com/hah23255/quick-serve-enterprise/main/install-android.sh | bash
```

Takes 2-5 minutes. Installs everything automatically.

### 2. Start

```bash
qs-start
```

Server starts. Shows your access URL.

### 3. Share Files

**Computer:** Drop files in `~/DropBasket/`
**Phone:** Drop files in `storage/shared/DropBasket/`

### 4. Access

Open browser on any device:
```
http://192.168.1.120:50080
```
(Use your actual IP shown after `qs-start`)

**Done!**

---

## Three Commands

```bash
qs-start    # Start server
qs-stop     # Stop server
qs-sync IP  # Sync with another device
```

That's it. Everything else is automatic.

---

## Sharing Files

### Computer
1. Open file manager
2. Go to `DropBasket` folder in home
3. Drag & drop files
4. Instantly available on network

### Phone (Termux)
1. Open file manager
2. Go to `Internal Storage/DropBasket/`
3. Copy files there
4. Instantly available on network

---

## Accessing Files

### From Browser
1. Connect to same WiFi
2. Open browser
3. Type: `http://192.168.1.120:50080`
4. Click file to download

### From Another Computer
```bash
# One-time sync
qs-sync 192.168.1.120

# Auto-sync every 5 minutes
crontab -e
# Add: */5 * * * * $HOME/qs-sync 192.168.1.120
```

---

## Desktop Shortcut (Computer)

**Icon:** 🧺 Purple basket on desktop

**Click:** Starts server instantly

**Drag files onto icon:** Opens DropBasket folder

---

## Phone Widgets (Termux)

**Install:** Termux:Widget from F-Droid

**Widgets:**
- DropBasket-Start (green) - Tap to start
- DropBasket-Stop (red) - Tap to stop

**Add to home:** Long-press → Widgets → Termux → DropBasket

---

## Security

**✅ Safe:**
- Only works on local WiFi
- Not accessible from internet
- No passwords needed (local trust)

**🔒 Private:**
- Files never leave your network
- No cloud upload
- No tracking

**⚠️ Note:**
- Anyone on your WiFi can access files
- Don't share sensitive data
- Use home WiFi, not public WiFi

---

## Troubleshooting

### Can't Connect from Other Device

**1. Check WiFi**
- Both devices on same WiFi?
- Not guest network?

**2. Check Server Running**
```bash
ps aux | grep quick-serve
# Should show running process
```

**3. Check Firewall**
```bash
sudo ufw allow 50080/tcp
```

**4. Try Different IP**
```bash
# Server shows: "Access: http://192.168.1.120:50080"
# Use that exact IP
```

### Server Won't Start

**1. Check Port Free**
```bash
ss -tlnp | grep 50080
# If occupied, use different port:
qs-start 51234
```

**2. Check Permissions**
```bash
ls -la ~/DropBasket
# Should be readable/writable
```

**3. Reinstall**
```bash
rm -rf ~/quick-serve-enterprise
# Run install command again
```

### Files Not Showing

**1. Refresh Browser**
Press F5 or reload page

**2. Check File Location**
```bash
ls ~/DropBasket
# Files should be listed
```

**3. Check File Permissions**
```bash
chmod 644 ~/DropBasket/*
```

---

## Advanced

### Change Port
```bash
qs-start 51234
```

### Change Folder
```bash
qs-start 50080 ~/Documents
```

### Auto-Start on Boot

**Computer:**
```bash
crontab -e
# Add: @reboot sleep 60 && $HOME/qs-start
```

**Termux:**
Already auto-starts with Termux:Boot app

### Multiple Devices Sync

**Device 1 → Device 2:**
```bash
# On Device 2:
qs-sync 192.168.1.120
```

**Device 1 ← Device 2:**
```bash
# On Device 1:
qs-sync 192.168.1.122
```

**Both ways (cron):**
```bash
# On both devices:
*/5 * * * * $HOME/qs-sync OTHER_IP
```

---

## Uninstall

**Computer:**
```bash
qs-stop
rm -rf ~/DropBasket ~/quick-serve-enterprise
rm ~/.local/bin/quick-serve ~/qs-*
```

**Termux:**
```bash
qs-stop
rm -rf ~/storage/shared/DropBasket ~/quick-serve-enterprise
pkg uninstall quick-serve
rm $PREFIX/bin/qs-*
```

---

## FAQ

**Q: Is it free?**
A: Yes, completely free and open source.

**Q: Do I need internet?**
A: Only for initial install. After that, works offline.

**Q: How many devices?**
A: Unlimited on same WiFi.

**Q: What file types?**
A: All types. PDFs, images, videos, documents, etc.

**Q: File size limit?**
A: No limit. Depends on your device storage.

**Q: Is it fast?**
A: Yes. Direct WiFi transfer, no cloud delay.

**Q: Can I use on mobile data?**
A: No. WiFi only (local network required).

**Q: Does it work with iPhone?**
A: Yes, iPhone can access files via browser. Server runs on computer/Android.

---

## Support

**Issues:** https://github.com/hah23255/quick-serve-enterprise/issues

**Docs:** https://github.com/hah23255/quick-serve-enterprise

---

**That's it! Simple file sharing, the way it should be.**

🧺 **DropBasket** - Drop it, share it, done.
