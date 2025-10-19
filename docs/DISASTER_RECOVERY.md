# Quick-serve Disaster Recovery Guide

Enterprise Production Deployment

---

## Recovery Scenarios

1. [Termux Reinstall](#termux-reinstall-recovery) (Most Common)
2. [Binary Loss](#binary-recovery)
3. [Configuration Corruption](#configuration-recovery)
4. [Complete Service Failure](#complete-service-recovery)
5. [Enterprise Structure Damage](#enterprise-structure-recovery)
6. [Total System Rebuild](#total-system-rebuild)

---

## Termux Reinstall Recovery

**Scenario**: Termux app reinstalled, home directory wiped

**What's Preserved**:
- ✅ Enterprise structure (`/storage/emulated/0/Enterprise/`)
- ✅ Credentials (`/storage/emulated/0/.env.git`)
- ✅ Master binary (`/storage/emulated/0/Enterprise/core/runtime/bin/quick-serve-prod`)
- ✅ Git repository (`/storage/emulated/0/Enterprise/projects/services/quick-serve/`)

**What's Lost**:
- ✗ Executable binary (`~/.local/bin/quick-serve-prod`)
- ✗ Shell aliases (`~/.bashrc`)
- ✗ SSH keys (`~/.ssh/`)
- ✗ Service scripts (`$PREFIX/var/service/`)
- ✗ Boot scripts (`~/.termux/boot/`)

### Recovery Steps (15 min)

**1. Install termux-services** (5 min):
```bash
pkg install termux-services
sv-enable quick-serve
```

**2. Recover SSH keys** (2 min):
```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Recreate SSH key (or restore from backup if available)
ssh-keygen -t ed25519 -f ~/.ssh/github-quick-serve -C "quick-serve-deploy"
chmod 600 ~/.ssh/github-quick-serve

# Add to GitHub: cat ~/.ssh/github-quick-serve.pub

# Configure SSH
cat > ~/.ssh/config << 'EOF'
Host github.com-quick-serve
    HostName github.com
    User git
    IdentityFile ~/.ssh/github-quick-serve
    IdentitiesOnly yes
EOF
chmod 600 ~/.ssh/config
```

**3. Recreate service script** (3 min):
```bash
mkdir -p $PREFIX/var/service/quick-serve/log/main

# Service run script:
cat > $PREFIX/var/service/quick-serve/run << 'EOF'
#!/bin/sh
exec 2>&1

# Load production configuration
. /storage/emulated/0/Enterprise/projects/services/quick-serve/config/production.env

# Change to service directory
cd /storage/emulated/0/Enterprise/projects/services/quick-serve

# Pre-flight checks
if [ ! -f ~/.local/bin/quick-serve-prod ]; then
    echo "ERROR: Binary not found at ~/.local/bin/quick-serve-prod"
    echo "INFO: Attempting recovery from Enterprise master copy"
    if [ -f /storage/emulated/0/Enterprise/core/runtime/bin/quick-serve-prod ]; then
        mkdir -p ~/.local/bin
        cp /storage/emulated/0/Enterprise/core/runtime/bin/quick-serve-prod ~/.local/bin/quick-serve-prod
        chmod +x ~/.local/bin/quick-serve-prod
        echo "SUCCESS: Binary recovered from Enterprise"
    else
        echo "FATAL: No binary found in Enterprise either"
        sleep 5
        exit 1
    fi
fi

if [ ! -d "$QS_SERVE_DIR" ]; then
    echo "ERROR: Serve directory not found: $QS_SERVE_DIR"
    sleep 5
    exit 1
fi

# Start quick-serve
exec ~/.local/bin/quick-serve-prod \
    --headless \
    --bind-ip="$QS_BIND_IP" \
    --http="$QS_HTTP_PORT" \
    --serve-dir="$QS_SERVE_DIR" \
    --verbose
EOF

chmod +x $PREFIX/var/service/quick-serve/run

# Log run script:
cat > $PREFIX/var/service/quick-serve/log/run << 'EOF'
#!/bin/sh
exec svlogd -tt ./main
EOF

chmod +x $PREFIX/var/service/quick-serve/log/run

# Log config:
cat > $PREFIX/var/service/quick-serve/log/main/config << 'EOF'
s10000000
n10
N100000000
t
!
EOF
```

**4. Restore aliases** (2 min):
```bash
cat > ~/.bashrc << 'EOF'
# Quick-serve Enterprise Aliases
[ -f /storage/emulated/0/Enterprise/core/config/quick-serve/aliases.sh ] && \
    source /storage/emulated/0/Enterprise/core/config/quick-serve/aliases.sh
EOF

source ~/.bashrc
```

**5. Restore boot script** (if using Termux:Boot) (2 min):
```bash
mkdir -p ~/.termux/boot

cat > ~/.termux/boot/start-quick-serve.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/sh
# Quick-serve Enterprise auto-start

termux-wake-lock

ENTERPRISE_BIN="/storage/emulated/0/Enterprise/core/runtime/bin/quick-serve-prod"
EXEC_BIN="$HOME/.local/bin/quick-serve-prod"

# Auto-recovery
if [ ! -f "$EXEC_BIN" ]; then
    if [ -f "$ENTERPRISE_BIN" ]; then
        mkdir -p ~/.local/bin
        cp "$ENTERPRISE_BIN" "$EXEC_BIN"
        chmod +x "$EXEC_BIN"
    fi
fi

# Start service
if ! pgrep -x runsvdir; then
    sv-enable quick-serve
fi

sv up quick-serve
EOF

chmod +x ~/.termux/boot/start-quick-serve.sh
```

**6. Start service** (1 min):
```bash
sv up quick-serve
sleep 3
sv status quick-serve
```

**7. Verify** (1 min):
```bash
# Source aliases if not already:
source ~/.bashrc

# Run health check:
bash /storage/emulated/0/Enterprise/core/monitoring/quick-serve/health-check.sh
```

---

## Binary Recovery

**Scenario**: Executable binary missing or corrupted

**Quick Recovery**:
```bash
cp /storage/emulated/0/Enterprise/core/runtime/bin/quick-serve-prod \
   ~/.local/bin/quick-serve-prod
chmod +x ~/.local/bin/quick-serve-prod
sv restart quick-serve
```

**Using alias** (if available):
```bash
qs-recover
qs-restart
```

**If master also missing**, rebuild:
```bash
cd /storage/emulated/0/Enterprise/projects/services/quick-serve
npx pnpm run build
npx pnpm run deploy
sv restart quick-serve
```

---

## Configuration Recovery

**Scenario**: production.env corrupted or deleted

**From git** (if committed):
```bash
cd /storage/emulated/0/Enterprise/projects/services/quick-serve
git checkout config/production.env
```

**Manual recreation**:
```bash
cat > /storage/emulated/0/Enterprise/projects/services/quick-serve/config/production.env << 'EOF'
# Server Configuration
QS_BIND_IP="0.0.0.0"
QS_HTTP_PORT=38080
QS_SERVE_DIR="/storage/emulated/0/Enterprise/projects"

# Service Configuration
QS_HEADLESS=true
QS_VERBOSE=true
EOF

sv restart quick-serve
```

---

## Complete Service Recovery

**Scenario**: Service completely broken, won't start

**Steps**:

**1. Stop everything**:
```bash
sv down quick-serve 2>/dev/null || true
killall quick-serve-prod 2>/dev/null || true
```

**2. Verify Enterprise structure**:
```bash
ls -lh /storage/emulated/0/Enterprise/core/runtime/bin/quick-serve-prod
ls -lh /storage/emulated/0/Enterprise/projects/services/quick-serve/config/production.env
```

**3. Recover binary**:
```bash
mkdir -p ~/.local/bin
cp /storage/emulated/0/Enterprise/core/runtime/bin/quick-serve-prod \
   ~/.local/bin/quick-serve-prod
chmod +x ~/.local/bin/quick-serve-prod
```

**4. Verify configuration**:
```bash
cat /storage/emulated/0/Enterprise/projects/services/quick-serve/config/production.env
```

**5. Recreate service script** (see Termux Reinstall section above)

**6. Start and verify**:
```bash
sv up quick-serve
sleep 3
sv status quick-serve
curl -I http://127.0.0.1:38080/
```

---

## Enterprise Structure Recovery

**Scenario**: Parts of Enterprise structure damaged/deleted

**What can be recovered**:

**From Git Repository**:
- Source code
- Documentation
- Configuration (if committed)
- Build scripts

**Must Rebuild**:
- Binary (rebuild from source)
- Monitoring scripts (recreate)
- Aliases (recreate)

**Recovery**:

**1. Verify/restore git repository**:
```bash
cd /storage/emulated/0/Enterprise/projects/services
# If missing:
git clone git@github.com-quick-serve:hah23255/quick-serve-enterprise.git quick-serve
```

**2. Rebuild binary**:
```bash
cd /storage/emulated/0/Enterprise/projects/services/quick-serve
npx pnpm run build
```

**3. Deploy**:
```bash
mkdir -p /storage/emulated/0/Enterprise/core/runtime/bin
cp $PREFIX/tmp/cargo-build-quick-serve/release/quick-serve \
   /storage/emulated/0/Enterprise/core/runtime/bin/quick-serve-prod

mkdir -p ~/.local/bin
cp /storage/emulated/0/Enterprise/core/runtime/bin/quick-serve-prod \
   ~/.local/bin/quick-serve-prod
chmod +x ~/.local/bin/quick-serve-prod
```

**4. Recreate monitoring scripts**:
```bash
mkdir -p /storage/emulated/0/Enterprise/core/monitoring/quick-serve

# health-check.sh and status-dashboard.sh
# (Restore from git if committed, or recreate from documentation)
```

**5. Recreate aliases**:
```bash
mkdir -p /storage/emulated/0/Enterprise/core/config/quick-serve

# aliases.sh
# (Restore from git if committed, or recreate)
```

---

## Total System Rebuild

**Scenario**: Everything lost except Enterprise structure on /storage/emulated/0/

**Prerequisites**:
- Enterprise structure exists at `/storage/emulated/0/Enterprise/`
- Git repository exists
- Master binary exists

**Full Recovery Process** (30-60 min):

Follow Termux Reinstall Recovery steps above, then:

**Additional verification**:

**1. Test all functionality**:
```bash
# Health check
bash /storage/emulated/0/Enterprise/core/monitoring/quick-serve/health-check.sh

# Dashboard
bash /storage/emulated/0/Enterprise/core/monitoring/quick-serve/status-dashboard.sh

# HTTP
curl -I http://127.0.0.1:38080/

# All aliases
source ~/.bashrc
qs
qs-health
qs-version
```

**2. Document recovery**:
- Date/time of recovery
- What was lost
- What was recovered
- Any issues encountered
- Lessons learned

---

## Recovery Testing

**Recommended**: Test recovery procedures periodically

**Safe Test** (doesn't break production):

**1. Simulate binary loss**:
```bash
mv ~/.local/bin/quick-serve-prod ~/.local/bin/quick-serve-prod.backup
sv restart quick-serve
# Should auto-recover from Enterprise master
sleep 3
sv status quick-serve
# Cleanup:
rm ~/.local/bin/quick-serve-prod.backup
```

**2. Test alias recovery**:
```bash
# In new shell (won't affect current):
bash -c 'source ~/.bashrc && type qs'
```

**3. Test health check**:
```bash
bash /storage/emulated/0/Enterprise/core/monitoring/quick-serve/health-check.sh
```

---

## Prevention

**Best Practices to Minimize Recovery Need**:

**1. Regular commits**:
```bash
cd /storage/emulated/0/Enterprise/projects/services/quick-serve
git add .
git commit -m "Backup config/docs"
git push
```

**2. Document changes**:
- Keep `docs/` up to date
- Note configuration changes
- Record custom modifications

**3. Verify backups**:
- Enterprise structure preserved
- Credentials secured
- Git repository synced

**4. Test recovery**:
- Quarterly recovery test
- Document procedures
- Update this guide

---

## Emergency Contacts

**Documentation**:
- This file: `docs/DISASTER_RECOVERY.md`
- Deployment guide: `docs/DEPLOYMENT-PRIVATE.md`
- Troubleshooting: `docs/TROUBLESHOOTING.md`
- Maintenance: `docs/MAINTENANCE.md`

**Resources**:
- Git repository: `git@github.com-quick-serve:hah23255/quick-serve-enterprise.git`
- Upstream: `https://github.com/joaofl/quick-serve`

---

**Last Updated**: 2025-10-19 (Phase 11.4)
