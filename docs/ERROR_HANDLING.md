# Installation Error Handling & Critical Checkpoints

## Overview

DropBasket installer has robust error handling at every critical checkpoint.

---

## Critical Checkpoints

### 1. Platform Detection
**Location:** Lines 12-22
**Check:** Termux vs Linux
**Error:** None - defaults to Linux if unclear
**Impact:** Low - paths differ but both work

### 2. Rust Installation
**Location:** Lines 29-33
**Check:** `command -v cargo`
**Error:** Network failure, disk space
**Handling:**
```bash
if ! command -v cargo &> /dev/null; then
    echo "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
fi
```
**Mitigation:**
- `set -e` exits on error
- Shows clear "Installing Rust..." message
- Network errors visible immediately

**Manual recovery:**
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env
```

### 3. Repository Clone
**Location:** Lines 36-45
**Check:** Git access, GitHub availability
**Error:** Network failure, no git installed
**Handling:**
```bash
if [ -d "$HOME/quick-serve-enterprise" ]; then
    cd $HOME/quick-serve-enterprise
    git pull
else
    git clone https://github.com/hah23255/quick-serve-enterprise.git
    cd $HOME/quick-serve-enterprise
fi
```
**Mitigation:**
- Updates if exists (resume capability)
- Clones if new
- Clear error from git if fails

**Manual recovery:**
```bash
# If network issue, try again later
# If git missing:
sudo apt install git  # Linux
pkg install git       # Termux
```

### 4. Build Process
**Location:** Lines 48-49
**Check:** Rust compiler, dependencies, disk space
**Error:** Compilation failure, out of memory, disk full
**Handling:**
```bash
cargo build --release --no-default-features --bin quick-serve
```
**Mitigation:**
- `set -e` stops on build failure
- Shows cargo error output
- No-default-features reduces memory

**Common issues:**
- **Out of RAM:** Use swap file
- **Disk full:** Need 500MB free
- **Compile error:** Usually fixed by `cargo clean`

**Manual recovery:**
```bash
cd ~/quick-serve-enterprise
cargo clean
cargo build --release --no-default-features --bin quick-serve
```

### 5. Binary Installation
**Location:** Lines 52-55
**Check:** Write permissions, directory creation
**Error:** Permission denied
**Handling:**
```bash
mkdir -p "$INSTALL_DIR"
mkdir -p "$DATA_DIR"
cp target/release/quick-serve "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/quick-serve"
```
**Mitigation:**
- Creates directories if missing
- Uses user home (no sudo needed)
- Sets executable permission

**Manual recovery:**
```bash
mkdir -p ~/.local/bin ~/DropBasket
cp target/release/quick-serve ~/.local/bin/
chmod +x ~/.local/bin/quick-serve
```

### 6. PATH Configuration
**Location:** Lines 58-64
**Check:** Bash profile exists
**Error:** None - safe append
**Handling:**
```bash
if ! grep -q ".local/bin" $HOME/.bashrc; then
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> $HOME/.bashrc
fi
```
**Mitigation:**
- Checks if already exists (idempotent)
- Safe append (doesn't break existing PATH)
- Works immediately in current shell

### 7. Desktop Shortcut Creation
**Location:** Lines 122-153
**Check:** Desktop directory exists, GTK support
**Error:** No desktop environment, permission denied
**Handling:**
```bash
if [ "$PLATFORM" = "linux" ]; then
    mkdir -p $HOME/.local/share/applications
    mkdir -p $HOME/.local/share/icons
    # ... create files ...
    if [ -d "$HOME/Desktop" ]; then
        cp ... $HOME/Desktop/
    fi
fi
```
**Mitigation:**
- Only on Linux (skips Termux)
- Creates directories first
- Checks Desktop exists
- Non-fatal if fails

### 8. Firewall Configuration
**Location:** Lines 196-201
**Check:** UFW installed, sudo available
**Error:** No sudo password, firewall disabled
**Handling:**
```bash
if command -v ufw &> /dev/null; then
    echo "Opening firewall port $PORT..."
    sudo ufw allow $PORT/tcp 2>/dev/null || echo "⚠️  Add manually: sudo ufw allow $PORT/tcp"
fi
```
**Mitigation:**
- Checks UFW exists
- Tries sudo, continues if fails
- Shows manual command if needed
- Non-fatal error

**Manual fix:**
```bash
sudo ufw allow 50080/tcp
```

---

## Error Recovery Matrix

| Checkpoint | Error Type | Severity | Auto-Recover | Manual Fix |
|-----------|-----------|----------|--------------|------------|
| Platform detect | Wrong platform | Low | Yes | N/A |
| Rust install | Network fail | High | No | Retry install |
| Rust install | Disk full | Critical | No | Free 2GB space |
| Git clone | Network fail | High | No | Retry install |
| Git clone | No git | High | No | Install git |
| Build | Out of RAM | High | No | Add swap |
| Build | Disk full | Critical | No | Free 500MB |
| Build | Compile error | Medium | No | cargo clean |
| Binary install | Permission | Medium | No | Fix permissions |
| PATH setup | None | N/A | Yes | N/A |
| Desktop shortcut | No desktop | Low | Yes | Skip |
| Firewall | No sudo | Low | Yes | Manual command |

---

## Exit Points

**Success:** All checkpoints passed
```
====================================
✅ Installation Complete!
====================================
```

**Partial Success:** Built but firewall failed
```
⚠️  Add firewall rule manually: sudo ufw allow 50080/tcp
====================================
✅ Installation Complete!
====================================
```

**Critical Failure:** Build failed
```
error: could not compile `quick-serve-enterprise`
# Script exits with error code 1
```

---

## Idempotency

**Safe to re-run:** Yes, completely safe

**Re-run behavior:**
1. Skips Rust if installed
2. Updates repo instead of clone
3. Rebuilds binary (overwrites old)
4. Skips PATH if exists
5. Overwrites scripts
6. Updates desktop shortcut

**Resume after failure:**
- Network back: Just re-run
- Disk freed: Just re-run
- RAM added: Just re-run

---

## Monitoring & Debugging

### Check Installation Status
```bash
# Binary installed?
which quick-serve

# Can execute?
quick-serve --version

# PATH correct?
echo $PATH | grep .local/bin

# Desktop shortcut?
ls ~/.local/share/applications/dropbasket.desktop

# Firewall open?
sudo ufw status | grep 50080
```

### Debug Build Issues
```bash
# Check Rust
rustc --version
cargo --version

# Check disk space
df -h ~

# Check memory
free -h

# Clean and retry
cd ~/quick-serve-enterprise
cargo clean
cargo build --release --no-default-features --bin quick-serve
```

### Installation Logs
```bash
# Run with verbose output
bash -x install.sh 2>&1 | tee install.log

# Check last error
echo $?

# Review log
less install.log
```

---

## Critical Dependencies

### Linux
- **curl** - Network downloads (critical)
- **git** - Repository clone (critical)
- **gcc** - Rust compiler backend (critical)
- **make** - Build system (critical)
- **pkg-config** - Dependency detection (critical)

**Pre-install check:**
```bash
sudo apt install -y curl git build-essential pkg-config
```

### Termux
- **curl** - Network downloads (critical)
- **git** - Repository clone (critical)
- **rust** - Auto-installed by installer
- **binutils** - Linker (auto-installed with rust)

**Pre-install check:**
```bash
pkg update && pkg upgrade
pkg install curl git
```

---

## Failure Modes

### Network Failures
**Symptoms:** Timeout, connection refused
**Impact:** Cannot download Rust or clone repo
**Recovery:** Wait, retry with good connection

### Disk Space Failures
**Symptoms:** "No space left", write errors
**Impact:** Cannot build or install
**Recovery:** Free 2GB space, re-run

### Memory Failures
**Symptoms:** "Killed", segfault during build
**Impact:** Build incomplete
**Recovery:** Add swap file, retry
```bash
# Add 2GB swap
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

### Permission Failures
**Symptoms:** Permission denied
**Impact:** Cannot install binary
**Recovery:** Usually doesn't happen (uses ~/); check file permissions

---

## Success Criteria

**Installation successful when:**
1. ✅ Binary exists: `~/.local/bin/quick-serve`
2. ✅ Executable: `quick-serve --version` works
3. ✅ Scripts created: `~/qs-start`, `~/qs-stop`, `~/qs-sync`
4. ✅ Folder created: `~/DropBasket/`
5. ✅ Can start: `qs-start` shows URL

**Partial success acceptable when:**
- Desktop shortcut failed (not critical)
- Firewall unchanged (can fix manually)

**Complete failure when:**
- Binary not created
- Build failed
- No scripts generated

---

## Recommendations

**Before install:**
1. Check network stable
2. Check 2GB free disk
3. Close heavy apps (free RAM)
4. Use good WiFi (not mobile data)

**During install:**
- Don't interrupt
- Wait for "Installation Complete"
- Read any warnings

**After install:**
1. Restart terminal (PATH)
2. Test: `qs-start`
3. Check firewall if blocked
4. Access from browser

---

## Contact Support

**If installation fails:**
1. Check error message
2. Try manual recovery steps
3. Report issue with log:
   ```bash
   bash -x install.sh 2>&1 | tee install-error.log
   ```
4. GitHub: https://github.com/hah23255/quick-serve-enterprise/issues
