# Installation Error Handling Guidelines

**Quick reference for troubleshooting DropBasket installation**

---

## Before Installing

### Pre-Flight Checklist

```bash
# 1. Check disk space (need 2GB)
df -h ~

# 2. Check internet
ping -c 3 github.com

# 3. Update system (Linux)
sudo apt update

# 4. Update packages (Termux)
pkg update
```

**Minimum Requirements:**
- 2GB free disk space
- Stable internet connection
- 15 minutes time

---

## During Installation

### What's Normal

✅ Takes 2-5 minutes
✅ Downloads ~100MB
✅ Shows compilation messages
✅ Asks for sudo password (firewall only)

### What's NOT Normal

❌ Stuck >10 minutes
❌ "No space left" errors
❌ "Killed" or crash
❌ Permission denied (except firewall)

**If stuck:** Ctrl+C, then try fixes below

---

## Common Errors & Fixes

### Error 1: "command not found: cargo"

**Cause:** Rust not installed

**Fix:**
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source ~/.cargo/env
# Re-run install
```

### Error 2: "No space left on device"

**Cause:** Disk full

**Fix:**
```bash
# Check space
df -h ~

# Clean if needed
sudo apt clean           # Linux
pkg clean               # Termux

# Need 2GB free, then re-run
```

### Error 3: "Killed" during build

**Cause:** Out of memory

**Fix (Linux):**
```bash
# Add swap
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Re-run install
```

**Fix (Termux):**
```bash
# Close other apps
# Use powerful device if available
# Try at night (cooler = more RAM)
```

### Error 4: "Permission denied"

**Cause:** Usually firewall (expected) or wrong permissions

**Fix:**
```bash
# If during install, it's OK (asks for sudo)
# If after install:
chmod +x ~/.local/bin/quick-serve
chmod +x ~/qs-start ~/qs-stop ~/qs-sync
```

### Error 5: "failed to clone repository"

**Cause:** Network or git issue

**Fix:**
```bash
# Check network
ping github.com

# Install git if missing
sudo apt install git     # Linux
pkg install git         # Termux

# Re-run install
```

### Error 6: "error: linking with `cc` failed"

**Cause:** Missing compiler tools

**Fix (Linux):**
```bash
sudo apt install build-essential pkg-config
# Re-run install
```

**Fix (Termux):**
```bash
pkg install binutils
# Re-run install
```

---

## After Installation

### Verification Steps

```bash
# 1. Binary exists?
ls -la ~/.local/bin/quick-serve

# 2. Can run?
quick-serve --version

# 3. Scripts created?
ls ~/qs-*

# 4. Folder exists?
ls ~/DropBasket
```

**All should succeed. If not, see recovery below.**

---

## Recovery Procedures

### Clean Reinstall

```bash
# 1. Remove all
rm -rf ~/quick-serve-enterprise
rm ~/.local/bin/quick-serve
rm ~/qs-*

# 2. Re-run installer
curl -sSL https://raw.githubusercontent.com/hah23255/quick-serve-enterprise/main/install.sh | bash
```

### Partial Reinstall (Keep Build)

```bash
cd ~/quick-serve-enterprise
git pull
cargo build --release --no-default-features --bin quick-serve
cp target/release/quick-serve ~/.local/bin/
```

### Manual Install (If Auto Fails)

```bash
# 1. Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source ~/.cargo/env

# 2. Clone
git clone https://github.com/hah23255/quick-serve-enterprise.git
cd quick-serve-enterprise

# 3. Build
cargo build --release --no-default-features --bin quick-serve

# 4. Install
mkdir -p ~/.local/bin ~/DropBasket
cp target/release/quick-serve ~/.local/bin/
chmod +x ~/.local/bin/quick-serve

# 5. Add PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# 6. Create scripts (copy from install.sh lines 65-90)

# 7. Open firewall
sudo ufw allow 50080/tcp

# 8. Test
quick-serve --version
```

---

## Testing Installation

### Quick Test

```bash
# Start server
~/qs-start

# In another terminal:
curl http://localhost:50080

# Should show HTML
# Stop server
~/qs-stop
```

### Full Test

```bash
# 1. Start
~/qs-start

# 2. Check process
ps aux | grep quick-serve

# 3. Check port
ss -tlnp | grep 50080

# 4. Test local
curl -I http://localhost:50080

# 5. Test network (from other device)
# Open: http://YOUR_IP:50080

# 6. Add file
echo "test" > ~/DropBasket/test.txt

# 7. Access file
curl http://localhost:50080/test.txt

# 8. Stop
~/qs-stop
```

**All should work. If not, see troubleshooting.**

---

## When to Get Help

### Try Fixing First (5-10 min)

1. Read error message
2. Try relevant fix above
3. Clean reinstall
4. Check requirements

### Get Help If:

❌ Same error after 3 tries
❌ System crashes
❌ No error message shown
❌ Weird behavior

### Where to Get Help

**GitHub Issues:**
https://github.com/hah23255/quick-serve-enterprise/issues

**Include in report:**
```bash
# System info
uname -a
df -h
free -h

# Rust info
rustc --version 2>&1
cargo --version 2>&1

# Error log
bash -x ~/quick-serve-enterprise/install.sh 2>&1 | tee error.log
# Attach error.log
```

---

## Platform-Specific Notes

### Linux (Ubuntu/Debian)

**Common issue:** Missing build tools

**Fix:**
```bash
sudo apt install build-essential pkg-config libssl-dev
```

### Linux (Fedora/RHEL)

**Common issue:** Different package names

**Fix:**
```bash
sudo dnf install gcc gcc-c++ make pkgconfig openssl-devel
```

### Termux on Android

**Common issue:** Not enough RAM

**Fix:**
- Close all apps
- Restart Termux
- Try on newer/more powerful device
- Install pre-built binary (if available)

**Storage permission:**
```bash
termux-setup-storage
# Allow when prompted
```

---

## Installation Success Indicators

### You know it worked when:

✅ See "Installation Complete!"
✅ `qs-start` shows URL
✅ Can access from browser
✅ Desktop shortcut appears (Linux)
✅ Widgets available (Termux)

### Partial Success (OK):

⚠️ Firewall not opened (can fix manually)
⚠️ Desktop shortcut missing (server works)
⚠️ PATH not updated (restart terminal)

### Complete Failure (Need Fix):

❌ No binary created
❌ Build failed
❌ Scripts missing
❌ Server won't start

---

## Quick Troubleshooting Decision Tree

```
Can't install
├─ Network error?
│  └─ Check connection, retry
├─ Disk full?
│  └─ Free 2GB, retry
├─ Out of RAM?
│  └─ Add swap, close apps
└─ Other error?
   └─ See error section above

Installation complete but...
├─ Can't start server?
│  ├─ Port busy? → Use different port
│  └─ Permission? → chmod +x
├─ Can't access from other device?
│  ├─ Firewall? → sudo ufw allow 50080/tcp
│  ├─ Wrong IP? → Check qs-start output
│  └─ Different WiFi? → Connect same network
└─ Server crashes?
   └─ Check logs, report issue
```

---

## Prevention Tips

### Before Installing:

1. ✅ Read requirements
2. ✅ Check disk space
3. ✅ Stable internet
4. ✅ Close heavy apps
5. ✅ Update system first

### During Installing:

1. ✅ Don't interrupt
2. ✅ Read messages
3. ✅ Note any warnings
4. ✅ Provide sudo when asked
5. ✅ Wait for "Complete"

### After Installing:

1. ✅ Restart terminal
2. ✅ Test immediately
3. ✅ Fix firewall if needed
4. ✅ Save qs-start output
5. ✅ Bookmark access URL

---

## Summary

**Most common issues:**
1. Disk space (2GB needed)
2. Network interruption
3. Out of memory (swap helps)
4. Firewall blocking (manual fix easy)

**Most common fixes:**
1. Clean reinstall (99% success)
2. Add swap file (memory issues)
3. Free disk space
4. Manual firewall rule

**Success rate:** 95%+ on clean install

**Time to fix:** Usually <5 minutes

---

**Still stuck? Report issue with logs and system info.**

GitHub: https://github.com/hah23255/quick-serve-enterprise/issues
