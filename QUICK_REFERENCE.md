# Quick Reference Guide - v0.3.2 Merge Validation

**For the impatient:** Run `bash scripts/validate-merge.sh` and review the report.

---

## 📌 One-Liner Validation

```bash
cd /home/i/quick-serve-enterprise && bash scripts/validate-merge.sh
```

**Time:** ~2 hours
**Output:** MERGE_VALIDATION_REPORT.md

---

## 🚦 Quick Status Check

```bash
# Are you on the right branch?
git branch --show-current  # Should show: merge-upstream-v0.3.2

# Is the merge commit present?
git log --oneline -1  # Should show: f3efc38 merge: Integrate upstream v0.3.2

# Are enterprise files present?
ls assets/error-pages/  # Should show 403.html, 404.html, 500.html
ls docs/  # Should show 6 enterprise docs
```

---

## ⚡ Fast Track (Manual Steps)

### 1. Build (20 min)
```bash
cargo clean
cargo build --release --no-default-features --bin quick-serve
ls -lh target/release/quick-serve  # Should be ~3.7-4.0 MB
```

### 2. Test (30 min)
```bash
cargo test --release
# All tests should pass
```

### 3. Manual Test (15 min)
```bash
# Start server
./target/release/quick-serve --http 8080 -d /tmp/test-dir --headless &

# Test in another terminal:
curl http://localhost:8080/nonexistent  # Should return 404 with custom page
curl http://localhost:8080/../etc/passwd  # Should be BLOCKED (400)

# Stop server
killall quick-serve
```

### 4. Decision
- ✅ All pass → Proceed to PR
- ❌ Any fail → Fix and retry

---

## 📊 Success Criteria (Must Pass)

| Check | Command | Expected |
|-------|---------|----------|
| **Build** | `cargo build --release --no-default-features` | Exit 0, binary created |
| **Tests** | `cargo test --release` | All pass |
| **404 Page** | `curl http://localhost:8080/nonexistent` | 404 + custom HTML |
| **403 Page** | `curl http://localhost:8080/dir-without-index/` | 403 + custom HTML |
| **Path Traversal** | `curl http://localhost:8080/../../etc/passwd` | 400 (BLOCKED) |
| **Content-Type** | `curl -I http://localhost:8080/test.html` | text/html |

---

## 🔄 If Tests Fail

### Build Fails
```bash
cargo clean
cargo build --release 2>&1 | tee build.log
# Review build.log for errors
```

### Tests Fail
```bash
cargo test --lib -- --nocapture  # Run with output
cargo test --test '*' -- --nocapture
# Review test output
```

### Security Test Fails (CRITICAL)
```bash
# DO NOT PROCEED!
# Review: src/servers/http.rs
# Check: validate_file_path() is being called
# Consider: Rollback to backup-v0.3.1-enterprise-20251112-082324
```

---

## 📁 Important Files

### Documentation
- **VALIDATION_PLAYBOOK.md** - Complete step-by-step guide (detailed)
- **MERGE_VALIDATION_REPORT.md** - Generated after validation
- **ENTERPRISE_FEATURES_CHECKLIST.md** - Feature tracking
- **CHANGELOG.md** - Merge details

### Scripts
- **scripts/validate-merge.sh** - Automated validation (USE THIS)

### Logs (Generated)
- build-headless.log
- test-unit.log
- test-integration.log
- test-all.log
- clippy.log
- /tmp/qs-test/logs/* (manual tests)

---

## 🔙 Rollback Procedure

If critical issues found:

```bash
# Option 1: Switch to backup
git checkout backup-v0.3.1-enterprise-20251112-082324

# Option 2: Create hotfix branch
git checkout -b hotfix-rollback
# Fix issues
# Re-run validation
```

---

## 🎯 After Validation Passes

### Create Pull Request
```bash
gh pr create \
  --title "Merge upstream v0.3.2 into enterprise fork" \
  --body "See CHANGELOG.md for details. All tests passed."
```

### Merge to Main
```bash
git checkout main
git merge merge-upstream-v0.3.2 --no-ff
git push origin main
```

### Tag Release
```bash
git tag -a v0.3.2-enterprise -m "Release v0.3.2-enterprise"
git push origin v0.3.2-enterprise
```

---

## 📞 Need Help?

**Documentation:**
- Full details: VALIDATION_PLAYBOOK.md (read this!)
- Merge details: CHANGELOG.md

**Git References:**
- Merge Commit: f3efc38
- Merge Branch: merge-upstream-v0.3.2
- Backup Branch: backup-v0.3.1-enterprise-20251112-082324

**Repository:**
- https://github.com/hah23255/quick-serve-enterprise

---

## ⏱️ Time Estimates

| Phase | Time | Can Skip? |
|-------|------|-----------|
| Build | 20 min | NO |
| Auto Tests | 30 min | NO |
| Manual Tests | 45 min | NO (security critical) |
| Report | 15 min | Auto-generated |
| **Total** | **~2 hours** | - |

---

## ✅ Validation Checklist

Quick checklist to track progress:

- [ ] Environment setup (Rust installed, correct branch)
- [ ] Build succeeds (binary created ~3.7MB)
- [ ] All automated tests pass (21+ tests)
- [ ] Clippy passes
- [ ] Custom 404 page works
- [ ] Custom 403 page works
- [ ] Content-Type detection works
- [ ] Directory with index.html works
- [ ] Directory without index.html returns 403
- [ ] **PATH TRAVERSAL BLOCKED** (CRITICAL)
- [ ] File download integrity preserved
- [ ] Report generated
- [ ] Artifacts archived

**If ALL checked:** ✅ Ready for Pull Request

**If ANY unchecked:** ❌ Fix issues first

---

## 🚀 Quick Commands

```bash
# Full validation (recommended)
bash scripts/validate-merge.sh

# Quick build test
cargo build --release --no-default-features && echo "✅ Build OK"

# Quick test suite
cargo test --release && echo "✅ Tests OK"

# Manual quick test
./target/release/quick-serve --help && echo "✅ Binary OK"

# View report
cat MERGE_VALIDATION_REPORT.md

# Archive location
ls -lh ~/merge-validation-$(date +%Y%m%d).tar.gz
```

---

**Version:** 1.0
**Created:** 2025-11-12
**Updated:** 2025-11-12

**Remember:** Security test (path traversal) is CRITICAL. If it fails, STOP immediately.
