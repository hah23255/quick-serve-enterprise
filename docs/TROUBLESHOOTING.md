# Quick-serve Troubleshooting Guide

Enterprise Production Deployment

---

## Quick Diagnostics

**First Steps**:
```bash
qs-health           # Full 7-section diagnostics
qs-dashboard        # Real-time status
sv status quick-serve
qs-logs | tail -50
```

---

## Service Issues

### Won't Start

**Check**:
```bash
qs-health
ls -lh ~/.local/bin/quick-serve-prod
cat /storage/emulated/0/Enterprise/projects/services/quick-serve/config/production.env
```

**Fix**:
```bash
qs-recover          # If binary missing
qs-restart          # After config changes
```

### Crashes Immediately

**Common Causes**:
- Port 38080 already in use: `qs-port` → kill conflicting process or change port
- Serve directory missing: `mkdir -p /storage/emulated/0/Enterprise/projects`
- Corrupted binary: `qs-recover`

### Running But No HTTP Response

**Test**:
```bash
curl -v http://127.0.0.1:38080/
qs-port
```

**Common Issues**:
- Bind IP wrong (check `QS_BIND_IP` in config)
- Firewall blocking (test local first)
- Wrong port (check `QS_HTTP_PORT` in config)

---

## Binary Issues

### Binary Missing

**Symptoms**: Service fails with "binary not found"

**Auto-Recovery**: Service script attempts auto-recovery from Enterprise master

**Manual Recovery**:
```bash
qs-recover
# or
cp /storage/emulated/0/Enterprise/core/runtime/bin/quick-serve-prod \
   ~/.local/bin/quick-serve-prod
chmod +x ~/.local/bin/quick-serve-prod
qs-restart
```

### Binary Corrupted

**Test**:
```bash
~/.local/bin/quick-serve-prod --version
```

**Fix**:
```bash
qs-recover
qs-restart
```

### Master Copy Missing

**Critical**: Both copies missing

**Recovery**:
```bash
# Rebuild from source
qs-cd
qs-build
qs-deploy
```

---

## Network Issues

### Can't Access from Network

**Check bind IP**:
```bash
grep QS_BIND_IP /storage/emulated/0/Enterprise/projects/services/quick-serve/config/production.env
# Should be: QS_BIND_IP="0.0.0.0"
```

**Get WiFi IP**:
```bash
qs-url
```

**Test**:
```bash
# From another device:
curl http://<wifi-ip>:38080/
```

### Port Already in Use

**Check**:
```bash
qs-port
# or
lsof -i :38080
```

**Fix**:
- Kill conflicting process, OR
- Change `QS_HTTP_PORT` in config → restart

---

## Build Issues

### Cargo Build Fails - Permission Denied

**Cause**: Android noexec issue

**Verify Fix**:
```bash
cat /storage/emulated/0/Enterprise/projects/services/quick-serve/.cargo/config.toml
# Should have:
# [build]
# target-dir = "/data/data/com.termux/files/usr/tmp/cargo-build-quick-serve"
```

**If Missing**:
```bash
qs-cd
mkdir -p .cargo
cat > .cargo/config.toml << 'EOF'
[build]
target-dir = "/data/data/com.termux/files/usr/tmp/cargo-build-quick-serve"

[term]
verbose = false
color = 'auto'
EOF
```

### pnpm Command Not Found

**Use**:
```bash
npx pnpm run build
# Instead of:
pnpm run build
```

### Disk Space Issues

**Check**:
```bash
df -h /storage/emulated/0
df -h $PREFIX
```

**Clean**:
```bash
# Clean cargo build cache:
rm -rf $PREFIX/tmp/cargo-build-quick-serve/
# Rebuild:
qs-build
```

---

## Log Issues

### No Logs Appearing

**Check log directory**:
```bash
ls -la $PREFIX/var/service/quick-serve/log/main/
```

**Restart log service**:
```bash
sv restart quick-serve
sleep 5
ls -lh $PREFIX/var/service/quick-serve/log/main/current
```

### Logs Too Large

**Check size**:
```bash
ls -lh $PREFIX/var/service/quick-serve/log/main/
```

**Config** (automatic rotation at 10MB):
```bash
cat $PREFIX/var/service/quick-serve/log/main/config
```

**Manual cleanup** (if needed):
```bash
# Archives old logs:
sv restart quick-serve
```

---

## Alias Issues

### Aliases Not Working

**Load manually**:
```bash
source ~/.bashrc
# or
source /storage/emulated/0/Enterprise/core/config/quick-serve/aliases.sh
```

**Verify bashrc**:
```bash
grep "quick-serve/aliases.sh" ~/.bashrc
```

**Reinstall**:
```bash
cat >> ~/.bashrc << 'EOF'
# Quick-serve Enterprise Aliases
[ -f /storage/emulated/0/Enterprise/core/config/quick-serve/aliases.sh ] && \
    source /storage/emulated/0/Enterprise/core/config/quick-serve/aliases.sh
EOF
source ~/.bashrc
```

---

## Boot Issues

### Service Doesn't Auto-Start

**Check boot script**:
```bash
ls -lh ~/.termux/boot/start-quick-serve.sh
# Should be executable (-rwx)
```

**Test manually**:
```bash
bash ~/.termux/boot/start-quick-serve.sh
```

**Check Termux:Boot app**:
- Install if missing: Termux:Boot from F-Droid/Play Store
- Grant "Run on Boot" permission

---

## Git Issues

### SSH Key Permission Denied

**Check permissions**:
```bash
ls -l ~/.ssh/github-quick-serve
# Should be: -rw------- (600)
```

**Fix**:
```bash
chmod 600 ~/.ssh/github-quick-serve
```

**Test connection**:
```bash
ssh -T git@github.com-quick-serve
```

### Can't Pull/Push

**Check remote**:
```bash
qs-cd
git remote -v
# Should show: git@github.com-quick-serve:hah23255/quick-serve-enterprise.git
```

**Update remote** (if needed):
```bash
qs-cd
git remote set-url origin git@github.com-quick-serve:hah23255/quick-serve-enterprise.git
```

---

## Performance Issues

### High Memory Usage

**Check**:
```bash
qs-dashboard    # Shows memory
# or
ps aux | grep quick-serve-prod
```

**Normal**: ~4 MB RSS

**If excessive**: Restart service
```bash
qs-restart
```

### Slow Response Times

**Test**:
```bash
qs-health       # Shows response time
```

**Normal**: <5ms local, <50ms network

**Check**:
- Network congestion
- Device load
- Large file serving

---

## Emergency Recovery

### Complete Service Failure

**Nuclear option**:
```bash
# Stop service
sv down quick-serve

# Recover binary
qs-recover

# Verify config
cat /storage/emulated/0/Enterprise/projects/services/quick-serve/config/production.env

# Restart
sv up quick-serve

# Wait 3 seconds
sleep 3

# Check
qs-health
```

### Termux Reinstall Recovery

**After Termux reinstall**:
1. Enterprise structure preserved at `/storage/emulated/0/Enterprise/`
2. Credentials preserved at `/storage/emulated/0/.env.git`
3. Service will auto-recover binary from Enterprise master
4. Reload aliases: `source ~/.bashrc`
5. Verify: `qs-health`

### Everything Broken

**See**: `docs/DISASTER_RECOVERY.md`

**Last resort**: Re-run migration Phases 1-9

---

## Common Error Messages

### "Permission denied (os error 13)"

**During build**: Android noexec issue → check `.cargo/config.toml`  
**During run**: Binary not executable → `chmod +x ~/.local/bin/quick-serve-prod`

### "Address already in use"

Port 38080 occupied → `qs-port` → kill process or change port

### "No such file or directory"

Missing binary → `qs-recover`  
Missing config → check `/storage/emulated/0/Enterprise/projects/services/quick-serve/config/production.env`

### "unable to open supervise/ok: file does not exist"

**Normal warning** for new log service setup - ignore (auto-resolves)

---

## Getting Help

1. Run diagnostics: `qs-health`
2. Check logs: `qs-logs | tail -100`
3. Review this guide
4. Check `docs/DEPLOYMENT-PRIVATE.md`
5. Check `docs/MAINTENANCE.md`

---

**Last Updated**: 2025-10-19 (Phase 11.2)
