# Quick-serve Maintenance Guide

Enterprise Production Deployment

---

## Maintenance Schedule

### Daily (Automated)
- Log rotation (svlogd, automatic)
- Service monitoring (if monitoring tools configured)

### Weekly (Manual)
- Health check review
- Error log review
- Service status verification

### Monthly (Manual)
- Dependency updates
- Disk space review
- Log rotation verification
- Performance review

### Quarterly (Manual)
- Security audit
- Configuration review
- Documentation updates
- Backup verification

---

## Weekly Maintenance

### Health Check (5 min)

```bash
qs-health
```

**Review output**:
- ✓ All sections should pass
- ⚠ Warnings acceptable if explained
- ✗ Errors require investigation

### Error Log Review (5 min)

```bash
qs-logs-error
```

**Look for**:
- Repeated errors
- New error patterns
- Performance issues

**Action**: Investigate any concerning patterns

### Service Status (2 min)

```bash
qs-dashboard
```

**Verify**:
- Service running
- Uptime reasonable (not frequent restarts)
- Memory usage normal (~4 MB)
- HTTP responding

---

## Monthly Maintenance

### 1. Update Dependencies (15 min)

**Rust dependencies**:
```bash
qs-cd
cargo update
cargo check
```

**If check passes**:
```bash
qs-build
qs-deploy
qs-restart
sleep 3
qs-health
```

**pnpm dependencies** (if using):
```bash
qs-cd
npx pnpm update
```

### 2. Disk Space Review (5 min)

**Check storage**:
```bash
df -h /storage/emulated/0
df -h $PREFIX
```

**Review**:
- `/storage/emulated/0`: Should have >1GB free
- `$PREFIX`: Should have >500MB free

**Clean if needed**:
```bash
# Clean cargo cache:
rm -rf $PREFIX/tmp/cargo-build-quick-serve/

# Review logs:
ls -lh $PREFIX/var/service/quick-serve/log/main/
# Old logs (.s files) can be deleted if space needed
```

### 3. Log Rotation Verification (5 min)

**Check config**:
```bash
cat $PREFIX/var/service/quick-serve/log/main/config
```

**Verify rotation working**:
```bash
ls -lh $PREFIX/var/service/quick-serve/log/main/
# Should see current + rotated (.s) files
# No file should exceed 10MB
```

**Check log count**:
```bash
ls $PREFIX/var/service/quick-serve/log/main/*.s 2>/dev/null | wc -l
# Should be ≤10 (per config)
```

### 4. Performance Review (10 min)

**Current metrics**:
```bash
qs-dashboard
```

**Record**:
- Memory usage
- Response time
- Uptime

**Compare to baseline**:
- Memory: ~4 MB normal
- Response: <5ms local
- Uptime: Should be steady (not frequent restarts)

**Trends to watch**:
- Increasing memory
- Slower response times
- Frequent restarts

---

## Quarterly Maintenance

### 1. Security Audit (30 min)

**Review configuration**:
```bash
cat /storage/emulated/0/Enterprise/projects/services/quick-serve/config/production.env
```

**Check**:
- [ ] Bind IP appropriate (0.0.0.0 for network, 127.0.0.1 for local-only)
- [ ] Port appropriate (38080 standard)
- [ ] Serve directory correct
- [ ] No sensitive data in served directory

**Review credentials**:
```bash
ls -l /storage/emulated/0/.env.git
ls -l ~/.ssh/github-quick-serve
# Both should be 600 (rw-------)
```

**Check for unauthorized files**:
```bash
qs-cd
git status
# Should show no unexpected files
```

### 2. Configuration Review (15 min)

**Verify all configs current**:
```bash
# Service script
cat $PREFIX/var/service/quick-serve/run

# Log config
cat $PREFIX/var/service/quick-serve/log/main/config

# Production config
cat /storage/emulated/0/Enterprise/projects/services/quick-serve/config/production.env

# Cargo config
cat /storage/emulated/0/Enterprise/projects/services/quick-serve/.cargo/config.toml
```

**Compare to documentation**:
- Check `docs/DEPLOYMENT-PRIVATE.md`
- Verify no drift from documented setup

### 3. Documentation Updates (20 min)

**Review accuracy**:
- `docs/DEPLOYMENT-PRIVATE.md`
- `docs/TROUBLESHOOTING.md`
- `docs/MAINTENANCE.md` (this file)
- `docs/DISASTER_RECOVERY.md`

**Update**:
- Current version numbers
- Current paths
- Recent changes
- New issues discovered

### 4. Backup Verification (10 min)

**Verify Enterprise structure intact**:
```bash
ls -lR /storage/emulated/0/Enterprise/core/runtime/bin/
ls -lR /storage/emulated/0/Enterprise/core/config/quick-serve/
ls -lR /storage/emulated/0/Enterprise/core/monitoring/quick-serve/
```

**Verify credentials**:
```bash
ls -l /storage/emulated/0/.env.git
ls -l ~/.ssh/github-quick-serve
```

**Test recovery**:
```bash
# Simulate binary loss:
mv ~/.local/bin/quick-serve-prod ~/.local/bin/quick-serve-prod.test
qs-recover
qs-health
# Cleanup:
rm ~/.local/bin/quick-serve-prod.test
```

---

## Common Maintenance Tasks

### Update Binary

**After code changes**:
```bash
qs-cd
git pull                # If pulling from remote
qs-build
qs-deploy
qs-restart
sleep 3
qs-health
```

### Change Configuration

**Edit config**:
```bash
nano /storage/emulated/0/Enterprise/projects/services/quick-serve/config/production.env
```

**Apply**:
```bash
qs-restart
qs-health
```

### Rotate Logs Manually

**Force rotation** (if needed):
```bash
sv restart quick-serve
```

### Clean Build Cache

**If low on space**:
```bash
rm -rf $PREFIX/tmp/cargo-build-quick-serve/
# Next build will recreate
```

### Update Aliases

**Edit**:
```bash
nano /storage/emulated/0/Enterprise/core/config/quick-serve/aliases.sh
```

**Reload**:
```bash
source ~/.bashrc
```

---

## Monitoring Best Practices

### Regular Checks

**Weekly**: `qs-health`, `qs-logs-error`  
**Daily** (if critical): `qs-dashboard`  
**After changes**: `qs-health`

### What to Monitor

**Service health**:
- Process running
- HTTP responding
- No repeated errors in logs

**Resource usage**:
- Memory stable (~4 MB)
- Disk space adequate
- No log overflow

**Performance**:
- Response time acceptable
- No degradation over time
- Uptime stable

### When to Take Action

**Immediate**:
- Service down
- HTTP not responding
- Critical errors in logs

**Soon** (within 24h):
- High memory usage
- Slow response times
- Disk space low

**Scheduled**:
- Dependency updates
- Configuration tweaks
- Performance optimization

---

## Upgrade Procedures

### Minor Version Updates

**Process**:
1. Review changelog
2. Test in dev if available
3. Backup current binary: `cp ~/.local/bin/quick-serve-prod ~/tmp/quick-serve-prod.backup`
4. Build new version: `qs-build`
5. Deploy: `qs-deploy`
6. Restart: `qs-restart`
7. Verify: `qs-health`
8. Monitor for 24h
9. Remove backup if stable

### Major Version Updates

**Additional steps**:
1. Review breaking changes
2. Update configuration if needed
3. Update documentation
4. Plan maintenance window
5. Notify users (if applicable)
6. Follow minor update process
7. Extended monitoring (1 week)

### Rollback Procedure

**If update fails**:
```bash
# Stop service
sv down quick-serve

# Restore backup
cp ~/tmp/quick-serve-prod.backup ~/.local/bin/quick-serve-prod
cp ~/tmp/quick-serve-prod.backup /storage/emulated/0/Enterprise/core/runtime/bin/quick-serve-prod

# Restart
sv up quick-serve
sleep 3
qs-health
```

---

## Record Keeping

### Maintenance Log

**Keep record of**:
- Date of maintenance
- Tasks performed
- Issues found
- Actions taken
- Results

**Example format**:
```
2025-10-19: Monthly maintenance
- Updated cargo dependencies
- Reviewed logs: no issues
- Disk space: 2.5GB free
- Performance: normal (4MB mem, 2ms response)
- Actions: none needed
```

### Version Tracking

**Track**:
- Binary version: `qs-version`
- Dependency versions: `cat Cargo.lock | grep "^name =" | head`
- Configuration changes
- Documentation updates

---

## Troubleshooting Maintenance Issues

**See**: `docs/TROUBLESHOOTING.md`

**Common during maintenance**:
- Build fails → Check disk space, verify .cargo/config.toml
- Deploy fails → Check permissions, verify paths
- Restart fails → Check logs, verify binary

---

**Last Updated**: 2025-10-19 (Phase 11.3)
