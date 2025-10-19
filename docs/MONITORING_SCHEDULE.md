# Quick-serve Monitoring Schedule

**Quick Reference for Regular Monitoring Tasks**

## Overview

This document provides a quick reference for monitoring quick-serve in production. For detailed maintenance procedures, see [MAINTENANCE.md](MAINTENANCE.md).

---

## Daily Tasks (Optional)

### Quick Health Check
```bash
qs-check
```
**Purpose**: Verify HTTP endpoint is responding
**Expected**: `200 - Service responding` or `403 - Service responding`
**Time**: < 5 seconds

### Service Status
```bash
qs
```
**Purpose**: Check service is running
**Expected**: `run: quick-serve: (pid XXXXX) XXs`
**Time**: < 1 second

---

## Weekly Tasks

### Comprehensive Health Check
```bash
qs-health
```
**Purpose**: Full diagnostic check (binary, service, network, HTTP, config, logs)
**Expected**: Exit code 0 (pass)
**Time**: 5-10 seconds
**Action**: If failed, review output and consult [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

### Error Log Review
```bash
qs-logs-error
```
**Purpose**: Check for errors in logs
**Expected**: No recent errors
**Time**: < 5 seconds
**Action**: If errors found, investigate using `qs-logs` for context

### Disk Space Check
```bash
du -sh /storage/emulated/0/Enterprise/projects/services/quick-serve
du -sh $PREFIX/var/service/quick-serve/log/main
```
**Purpose**: Monitor disk usage
**Expected**:
- Project: ~30-50MB
- Logs: < 100MB (svlogd rotates at 10MB × 10 files)
**Action**: If logs > 80MB, investigate excessive logging

---

## Monthly Tasks

### Full Status Dashboard
```bash
qs-dashboard
```
**Purpose**: Comprehensive real-time metrics
**Includes**: Service status, network, HTTP, binary, config, recent logs
**Time**: 10-15 seconds
**Action**: Review all sections for anomalies

### Dependency Updates
```bash
qs-cd
git pull
cargo update
npx pnpm run build:deploy
qs-restart
sleep 5
qs-health
```
**Purpose**: Update dependencies and rebuild
**Time**: 5-10 minutes (depending on changes)
**Action**: Verify health check passes after restart

### Log Rotation Verification
```bash
ls -lh $PREFIX/var/service/quick-serve/log/main/
```
**Purpose**: Verify svlogd is rotating logs properly
**Expected**: Multiple `@*.s` files, each ~10MB
**Action**: If single large file or no rotation, check svlogd configuration

### Binary Integrity Check
```bash
ls -lh ~/.local/bin/quick-serve-prod
ls -lh /storage/emulated/0/Enterprise/core/runtime/bin/quick-serve-prod
```
**Purpose**: Verify both copies exist and match
**Expected**: Both files 3-4MB, same size
**Action**: If mismatch, redeploy using `npx pnpm run deploy`

### Configuration Review
```bash
cat /storage/emulated/0/Enterprise/projects/services/quick-serve/config/production.env
```
**Purpose**: Verify configuration is correct
**Expected**: No unexpected changes
**Action**: If changed, review and commit to git if intentional

---

## Quarterly Tasks

### Auto-Recovery Test
```bash
# Simulate binary loss
mv ~/.local/bin/quick-serve-prod ~/.local/bin/quick-serve-prod.test

# Restart service (should auto-recover)
sv restart quick-serve
sleep 3

# Verify recovery
qs-health
ls -lh ~/.local/bin/quick-serve-prod

# Cleanup
rm ~/.local/bin/quick-serve-prod.test
```
**Purpose**: Verify auto-recovery mechanism works
**Expected**: Service restarts successfully, binary recovered from Enterprise master
**Time**: 1-2 minutes

### Security Audit
```bash
qs-cd

# Check for sensitive files
git status

# Review .gitignore
cat .gitignore

# Check file permissions
ls -la config/
ls -la /storage/emulated/0/.env.git
```
**Purpose**: Verify no credentials or secrets exposed
**Expected**: production.env gitignored, .env.git has 600 permissions
**Action**: If issues found, review [MAINTENANCE.md](MAINTENANCE.md) Security Audit section

### Backup Verification
```bash
ls -lh ~/backups/
```
**Purpose**: Verify backups exist
**Expected**: Recent archive(s) present
**Action**: If no recent backup, create one following [DISASTER_RECOVERY.md](DISASTER_RECOVERY.md)

---

## Ad-hoc Monitoring

### Real-time Log Monitoring
```bash
qs-logs
# or
qs-logs-follow
```
**Purpose**: Monitor logs in real-time
**Use case**: During deployment, debugging, or after configuration changes

### Network Access Test
```bash
qs-url
# Visit URL in browser or:
curl http://$(qs-url | sed 's|http://||;s|/$||')/
```
**Purpose**: Test external network access
**Expected**: HTTP 403 or directory listing (depending on config)

### Port Verification
```bash
qs-port
```
**Purpose**: Verify port 38080 is listening
**Expected**: Shows process listening on 38080

---

## Monitoring Aliases Quick Reference

| Alias | Command | Purpose |
|-------|---------|---------|
| `qs` | `sv status quick-serve` | Service status |
| `qs-health` | Health check script | Comprehensive diagnostics |
| `qs-dashboard` | Dashboard script | Real-time metrics |
| `qs-check` | HTTP endpoint check | Quick response test |
| `qs-logs` | Tail logs | Real-time log monitoring |
| `qs-logs-error` | Grep errors in logs | Error log review |
| `qs-port` | Check port 38080 | Port verification |
| `qs-url` | Show access URL | Get WiFi access URL |
| `qs-version` | Show binary version | Version check |

Full alias list: [DEPLOYMENT-PRIVATE.md](DEPLOYMENT-PRIVATE.md)

---

## Troubleshooting

If any monitoring task fails or shows unexpected results:

1. Check service status: `qs`
2. Run health check: `qs-health`
3. Review recent logs: `qs-logs-error`
4. Consult [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
5. If needed, restart service: `qs-restart`

---

## Next Steps

- **For detailed maintenance procedures**: See [MAINTENANCE.md](MAINTENANCE.md)
- **For troubleshooting issues**: See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- **For disaster recovery**: See [DISASTER_RECOVERY.md](DISASTER_RECOVERY.md)
- **For deployment info**: See [DEPLOYMENT-PRIVATE.md](DEPLOYMENT-PRIVATE.md)
