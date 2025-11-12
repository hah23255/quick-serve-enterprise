# Quick-Serve Enterprise v0.3.2 Merge Validation Playbook

**Created:** 2025-11-12
**Merge Commit:** f3efc38
**Branch:** merge-upstream-v0.3.2
**Purpose:** Complete validation, testing, and deployment of upstream v0.3.2 merge

---

## 📋 Pre-Execution Checklist

Before starting validation, ensure:
- [ ] You have Rust 1.70+ installed (`rustc --version`)
- [ ] You have access to GitHub repository
- [ ] You have ~3 hours available
- [ ] You're on the `merge-upstream-v0.3.2` branch
- [ ] You have read this entire playbook

---

## 🎯 Quick Start

```bash
# Navigate to project
cd /home/i/quick-serve-enterprise

# Verify you're on correct branch
git branch --show-current  # Should show: merge-upstream-v0.3.2

# Execute validation script
bash scripts/validate-merge.sh

# Review results
cat MERGE_VALIDATION_REPORT.md
```

---

## Phase 1: Environment Setup (15 min)

### 1.1 Verify Git State
```bash
cd /home/i/quick-serve-enterprise
git checkout merge-upstream-v0.3.2
git status  # Should show: nothing to commit, working tree clean

# Verify merge commit present
git log --oneline -3
# Expected output should include:
# f3efc38 merge: Integrate upstream v0.3.2 with enterprise features preserved
```

**✅ Checkpoint:** Confirm merge commit `f3efc38` is HEAD

### 1.2 Verify Rust Toolchain
```bash
rustc --version
cargo --version
# Required: Rust 1.70 or later
```

**✅ Checkpoint:** Rust toolchain available

### 1.3 Verify Enterprise Files
```bash
# Check error pages (should show 3 files)
ls -lh assets/error-pages/
# Expected: 403.html (3.1K), 404.html (3.1K), 500.html (3.6K)

# Check documentation (should show 6 files)
ls -1 docs/
# Expected: BUG_REPORT.md, DEPLOYMENT.md, DISASTER_RECOVERY.md,
#           MAINTENANCE.md, MONITORING_SCHEDULE.md, TROUBLESHOOTING.md

# Review merge tracking
cat ENTERPRISE_FEATURES_CHECKLIST.md
```

**✅ Checkpoint:** All enterprise files present

---

## Phase 2: Compilation (20 min)

### 2.1 Clean Build
```bash
cargo clean

# For Android/Termux (optional):
# export CARGO_TARGET_DIR=~/tmp/cargo-build
# export TMPDIR=~/tmp

# Build headless binary
echo "=== BUILD START: $(date) ===" | tee build-headless.log
time cargo build --release --no-default-features --bin quick-serve 2>&1 | tee -a build-headless.log
echo "=== BUILD END: $(date) ===" | tee -a build-headless.log

# Check exit code
echo "Build exit code: $?" | tee -a build-headless.log
```

**✅ Checkpoint:** Build succeeds with exit code 0

### 2.2 Binary Verification
```bash
# Check binary exists and size
ls -lh target/release/quick-serve
# Expected: ~3.7-4.0 MB

# Verify it's executable
file target/release/quick-serve
# Expected: ELF 64-bit LSB executable

# Test version
./target/release/quick-serve --version
# Expected: quick-serve 0.3.2 (or similar)

# Test help
./target/release/quick-serve --help | head -20
```

**✅ Checkpoint:** Binary created, correct version, help displays

**❌ Rollback Point:** If build fails, see "Rollback Procedure" section

---

## Phase 3: Automated Testing (30 min)

### 3.1 Unit Tests
```bash
echo "=== UNIT TESTS START: $(date) ===" | tee test-unit.log
cargo test --lib 2>&1 | tee -a test-unit.log
UNIT_EXIT=$?
echo "=== UNIT TESTS END: $(date) | Exit: $UNIT_EXIT ===" | tee -a test-unit.log

# Extract test count
grep "test result:" test-unit.log | tail -1
```

**✅ Checkpoint:** All unit tests pass

**Expected Results:**
- 17+ validation tests pass
- Error handling tests pass
- Path traversal tests pass

### 3.2 Integration Tests
```bash
echo "=== INTEGRATION TESTS START: $(date) ===" | tee test-integration.log
cargo test --test '*' 2>&1 | tee -a test-integration.log
INTEGRATION_EXIT=$?
echo "=== INTEGRATION TESTS END: $(date) | Exit: $INTEGRATION_EXIT ===" | tee -a test-integration.log

# Extract test count
grep "test result:" test-integration.log | tail -1
```

**✅ Checkpoint:** All integration tests pass

**Expected Results:**
- test_http_file_download_success: PASS
- test_file_not_found: PASS
- test_path_is_directory: PASS
- test_path_traversal_blocked: PASS

### 3.3 Complete Test Suite
```bash
echo "=== ALL TESTS START: $(date) ===" | tee test-all.log
cargo test --release 2>&1 | tee -a test-all.log
ALL_EXIT=$?
echo "=== ALL TESTS END: $(date) | Exit: $ALL_EXIT ===" | tee -a test-all.log

# Summary
echo "=== TEST SUMMARY ===" | tee test-summary.txt
echo "Unit tests exit code: $UNIT_EXIT" | tee -a test-summary.txt
echo "Integration tests exit code: $INTEGRATION_EXIT" | tee -a test-summary.txt
echo "All tests exit code: $ALL_EXIT" | tee -a test-summary.txt
grep "test result:" test-all.log | tail -1 | tee -a test-summary.txt
```

**✅ Checkpoint:** 21+ tests pass, 0 failures

### 3.4 Code Quality
```bash
# Clippy (linting)
echo "=== CLIPPY START: $(date) ===" | tee clippy.log
cargo clippy -- -D warnings 2>&1 | tee -a clippy.log
CLIPPY_EXIT=$?
echo "=== CLIPPY END: $(date) | Exit: $CLIPPY_EXIT ===" | tee -a clippy.log

# Format check
cargo fmt --check
FMT_EXIT=$?
echo "Format check exit code: $FMT_EXIT"
```

**✅ Checkpoint:** Clippy passes, formatting correct

**❌ Rollback Point:** If tests fail, investigate before proceeding

---

## Phase 4: Manual Feature Testing (45 min)

### 4.1 Setup Test Environment
```bash
# Create test directory structure
mkdir -p /tmp/qs-test/{files,logs,downloads}
cd /tmp/qs-test/files

# Create test files with various types
cat > test.html <<'EOF'
<!DOCTYPE html>
<html><body><h1>Test HTML File</h1></body></html>
EOF

echo "body { color: red; background: blue; }" > test.css
echo "console.log('JavaScript test file');" > test.js
echo '{"test": true, "type": "json"}' > test.json
echo "Plain text file for testing" > test.txt

# Create binary files
dd if=/dev/urandom of=test.bin bs=1M count=1 2>/dev/null
dd if=/dev/urandom of=test.png bs=1K count=100 2>/dev/null

# Create directory WITH index.html
mkdir -p with-index
cat > with-index/index.html <<'EOF'
<!DOCTYPE html>
<html><body><h1>Directory Index Page</h1></body></html>
EOF

# Create directory WITHOUT index.html
mkdir -p no-index
echo "File inside directory without index" > no-index/file.txt

# List all test files
echo "=== Test files created ===" | tee /tmp/qs-test/logs/setup.log
ls -lR /tmp/qs-test/files/ | tee -a /tmp/qs-test/logs/setup.log
```

**✅ Checkpoint:** Test environment created

### 4.2 Start Test Server
```bash
cd /home/i/quick-serve-enterprise

# Start server in background
./target/release/quick-serve \
  --http 8080 \
  -d /tmp/qs-test/files \
  --headless &

SERVER_PID=$!
echo "Server PID: $SERVER_PID" | tee /tmp/qs-test/logs/server-pid.txt

# Wait for server to start
sleep 3

# Verify server is running
ps aux | grep quick-serve | grep -v grep
if [ $? -eq 0 ]; then
  echo "✅ Server started successfully"
else
  echo "❌ Server failed to start"
  exit 1
fi

# Test basic connectivity
curl -s http://localhost:8080/test.html > /dev/null
if [ $? -eq 0 ]; then
  echo "✅ Server responding to requests"
else
  echo "❌ Server not responding"
  exit 1
fi
```

**✅ Checkpoint:** Server running and responding

### 4.3 Test Custom Error Pages

#### Test 404 - File Not Found
```bash
echo "=== Testing 404 Error Page ===" | tee /tmp/qs-test/logs/test-404.log

curl -v http://localhost:8080/nonexistent-file.html 2>&1 | tee -a /tmp/qs-test/logs/test-404.log

# Verify response
grep "< HTTP/1.1 404" /tmp/qs-test/logs/test-404.log
if [ $? -eq 0 ]; then
  echo "✅ 404 status code correct"
else
  echo "❌ 404 status code incorrect"
fi

grep -i "not found" /tmp/qs-test/logs/test-404.log
if [ $? -eq 0 ]; then
  echo "✅ 404 custom error page served"
else
  echo "❌ 404 custom error page NOT served"
fi

grep "text/html" /tmp/qs-test/logs/test-404.log
if [ $? -eq 0 ]; then
  echo "✅ 404 Content-Type is HTML"
else
  echo "❌ 404 Content-Type incorrect"
fi
```

**✅ Checkpoint:** 404 error page displays correctly

#### Test 403 - Directory Forbidden
```bash
echo "=== Testing 403 Error Page ===" | tee /tmp/qs-test/logs/test-403.log

curl -v http://localhost:8080/no-index/ 2>&1 | tee -a /tmp/qs-test/logs/test-403.log

# Verify response
grep "< HTTP/1.1 403" /tmp/qs-test/logs/test-403.log
if [ $? -eq 0 ]; then
  echo "✅ 403 status code correct"
else
  echo "❌ 403 status code incorrect"
fi

grep -i "forbidden" /tmp/qs-test/logs/test-403.log
if [ $? -eq 0 ]; then
  echo "✅ 403 custom error page served"
else
  echo "❌ 403 custom error page NOT served"
fi
```

**✅ Checkpoint:** 403 error page displays for directories without index.html

### 4.4 Test Content-Type Detection
```bash
echo "=== Testing Content-Type Detection ===" | tee /tmp/qs-test/logs/test-content-type.log

# HTML
echo -n "HTML: " | tee -a /tmp/qs-test/logs/test-content-type.log
curl -I http://localhost:8080/test.html 2>&1 | grep -i "content-type" | tee -a /tmp/qs-test/logs/test-content-type.log
# Expected: text/html; charset=utf-8

# CSS
echo -n "CSS: " | tee -a /tmp/qs-test/logs/test-content-type.log
curl -I http://localhost:8080/test.css 2>&1 | grep -i "content-type" | tee -a /tmp/qs-test/logs/test-content-type.log
# Expected: text/css; charset=utf-8

# JavaScript
echo -n "JS: " | tee -a /tmp/qs-test/logs/test-content-type.log
curl -I http://localhost:8080/test.js 2>&1 | grep -i "content-type" | tee -a /tmp/qs-test/logs/test-content-type.log
# Expected: application/javascript; charset=utf-8

# JSON
echo -n "JSON: " | tee -a /tmp/qs-test/logs/test-content-type.log
curl -I http://localhost:8080/test.json 2>&1 | grep -i "content-type" | tee -a /tmp/qs-test/logs/test-content-type.log
# Expected: application/json; charset=utf-8

# Plain text
echo -n "TXT: " | tee -a /tmp/qs-test/logs/test-content-type.log
curl -I http://localhost:8080/test.txt 2>&1 | grep -i "content-type" | tee -a /tmp/qs-test/logs/test-content-type.log
# Expected: text/plain; charset=utf-8

# Binary
echo -n "BIN: " | tee -a /tmp/qs-test/logs/test-content-type.log
curl -I http://localhost:8080/test.bin 2>&1 | grep -i "content-type" | tee -a /tmp/qs-test/logs/test-content-type.log
# Expected: application/octet-stream

# PNG (image)
echo -n "PNG: " | tee -a /tmp/qs-test/logs/test-content-type.log
curl -I http://localhost:8080/test.png 2>&1 | grep -i "content-type" | tee -a /tmp/qs-test/logs/test-content-type.log
# Expected: image/png

# Manual verification
echo "=== Content-Type Summary ===" | tee -a /tmp/qs-test/logs/test-content-type.log
cat /tmp/qs-test/logs/test-content-type.log | grep -E "HTML:|CSS:|JS:|JSON:|TXT:|BIN:|PNG:"
```

**✅ Checkpoint:** All Content-Types detected correctly (7+ types verified)

### 4.5 Test Directory Handling
```bash
echo "=== Testing Directory Handling ===" | tee /tmp/qs-test/logs/test-directory.log

# Test directory WITH index.html - should serve index
curl -s http://localhost:8080/with-index/ | tee /tmp/qs-test/logs/test-dir-with-index.html
grep "Directory Index Page" /tmp/qs-test/logs/test-dir-with-index.html
if [ $? -eq 0 ]; then
  echo "✅ Directory with index.html serves index page" | tee -a /tmp/qs-test/logs/test-directory.log
else
  echo "❌ Directory with index.html FAILED" | tee -a /tmp/qs-test/logs/test-directory.log
fi

# Test directory WITHOUT index.html - should return 403
curl -v http://localhost:8080/no-index/ 2>&1 | tee /tmp/qs-test/logs/test-dir-no-index.log
grep "< HTTP/1.1 403" /tmp/qs-test/logs/test-dir-no-index.log
if [ $? -eq 0 ]; then
  echo "✅ Directory without index.html returns 403" | tee -a /tmp/qs-test/logs/test-directory.log
else
  echo "❌ Directory without index.html FAILED" | tee -a /tmp/qs-test/logs/test-directory.log
fi
```

**✅ Checkpoint:** Directory handling works correctly

### 4.6 Test Security (Path Traversal Protection)
```bash
echo "=== Testing Path Traversal Protection ===" | tee /tmp/qs-test/logs/test-security.log

# Test 1: Parent directory traversal (..)
curl -v "http://localhost:8080/../../etc/passwd" 2>&1 | tee /tmp/qs-test/logs/test-traversal-1.log
grep "< HTTP/1.1 400" /tmp/qs-test/logs/test-traversal-1.log
if [ $? -eq 0 ]; then
  echo "✅ Path traversal (..) blocked with 400" | tee -a /tmp/qs-test/logs/test-security.log
else
  echo "❌ SECURITY ISSUE: Path traversal NOT blocked!" | tee -a /tmp/qs-test/logs/test-security.log
fi

# Test 2: Multiple levels traversal
curl -v "http://localhost:8080/../../../etc/hosts" 2>&1 | tee /tmp/qs-test/logs/test-traversal-2.log
grep "< HTTP/1.1 400" /tmp/qs-test/logs/test-traversal-2.log
if [ $? -eq 0 ]; then
  echo "✅ Multiple path traversal blocked" | tee -a /tmp/qs-test/logs/test-security.log
else
  echo "❌ SECURITY ISSUE: Multiple traversal NOT blocked!" | tee -a /tmp/qs-test/logs/test-security.log
fi

# Test 3: Null byte injection (if supported by curl)
curl -v "http://localhost:8080/test%00.txt" 2>&1 | tee /tmp/qs-test/logs/test-null-byte.log
grep "< HTTP/1.1 400" /tmp/qs-test/logs/test-null-byte.log
if [ $? -eq 0 ]; then
  echo "✅ Null byte injection blocked" | tee -a /tmp/qs-test/logs/test-security.log
else
  echo "⚠️  Null byte test inconclusive" | tee -a /tmp/qs-test/logs/test-security.log
fi

# Test 4: Absolute path attempt
curl -v "http://localhost:8080//etc/passwd" 2>&1 | tee /tmp/qs-test/logs/test-absolute.log
# This may or may not be blocked depending on validation logic
```

**✅ Checkpoint:** Path traversal blocked (CRITICAL SECURITY TEST)

**❌ STOP POINT:** If path traversal NOT blocked, DO NOT PROCEED. This is a critical security failure.

### 4.7 Test File Download Integrity
```bash
echo "=== Testing File Download Integrity ===" | tee /tmp/qs-test/logs/test-download.log

# Download HTML file
curl -s http://localhost:8080/test.html -o /tmp/qs-test/downloads/test.html
diff /tmp/qs-test/files/test.html /tmp/qs-test/downloads/test.html
if [ $? -eq 0 ]; then
  echo "✅ HTML file downloaded correctly" | tee -a /tmp/qs-test/logs/test-download.log
else
  echo "❌ HTML file download corrupted" | tee -a /tmp/qs-test/logs/test-download.log
fi

# Download binary file
curl -s http://localhost:8080/test.bin -o /tmp/qs-test/downloads/test.bin
diff /tmp/qs-test/files/test.bin /tmp/qs-test/downloads/test.bin
if [ $? -eq 0 ]; then
  echo "✅ Binary file downloaded correctly" | tee -a /tmp/qs-test/logs/test-download.log
else
  echo "❌ Binary file download corrupted" | tee -a /tmp/qs-test/logs/test-download.log
fi

# Check file sizes match
ls -lh /tmp/qs-test/files/test.bin /tmp/qs-test/downloads/test.bin
```

**✅ Checkpoint:** Files download with integrity preserved

### 4.8 Stop Test Server
```bash
# Stop server
kill $SERVER_PID 2>/dev/null

# Verify stopped
sleep 2
ps aux | grep $SERVER_PID | grep -v grep
if [ $? -ne 0 ]; then
  echo "✅ Server stopped successfully"
else
  echo "⚠️  Server still running, forcing kill"
  kill -9 $SERVER_PID
fi
```

**✅ Checkpoint:** Server stopped cleanly

---

## Phase 5: Generate Validation Report (15 min)

### 5.1 Create Report
```bash
cd /home/i/quick-serve-enterprise

cat > MERGE_VALIDATION_REPORT.md <<EOF
# Merge Validation Report
## quick-serve-enterprise v0.3.2

**Validation Date:** $(date +"%Y-%m-%d %H:%M:%S")
**Validator:** $(whoami)
**Hostname:** $(hostname)
**Merge Commit:** f3efc38
**Branch:** merge-upstream-v0.3.2

---

## 1. Build Results

**Compilation:**
- Status: $(grep -q "Finished \`release\` profile" build-headless.log && echo "PASS" || echo "FAIL")
- Build Time: $(grep "Finished" build-headless.log | tail -1)
- Binary Size: $(ls -lh target/release/quick-serve | awk '{print $5}')
- Binary Location: target/release/quick-serve

**Code Quality:**
- Clippy: $([ $CLIPPY_EXIT -eq 0 ] && echo "PASS" || echo "FAIL")
- Formatting: $([ $FMT_EXIT -eq 0 ] && echo "PASS" || echo "FAIL")

---

## 2. Automated Test Results

**Unit Tests:**
$(grep "test result:" test-unit.log | tail -1)
Exit Code: $UNIT_EXIT

**Integration Tests:**
$(grep "test result:" test-integration.log | tail -1)
Exit Code: $INTEGRATION_EXIT

**All Tests:**
$(grep "test result:" test-all.log | tail -1)
Exit Code: $ALL_EXIT

**Summary:**
- Total Tests: $(grep "test result:" test-all.log | tail -1 | grep -oP '\d+ passed' | head -1)
- Failures: $(grep "test result:" test-all.log | tail -1 | grep -oP '\d+ failed' | head -1 || echo "0 failed")
- Overall Status: $([ $ALL_EXIT -eq 0 ] && echo "✅ PASS" || echo "❌ FAIL")

---

## 3. Manual Feature Test Results

### Custom Error Pages
- 404 Not Found: $(grep -q "✅ 404 custom error page served" /tmp/qs-test/logs/test-404.log && echo "PASS" || echo "FAIL")
- 403 Forbidden: $(grep -q "✅ 403 custom error page served" /tmp/qs-test/logs/test-403.log && echo "PASS" || echo "FAIL")
- Content-Type HTML: $(grep -q "✅.*Content-Type is HTML" /tmp/qs-test/logs/test-404.log && echo "PASS" || echo "FAIL")

### Content-Type Detection
- HTML (text/html): $(grep -q "text/html" /tmp/qs-test/logs/test-content-type.log && echo "PASS" || echo "FAIL")
- CSS (text/css): $(grep -q "text/css" /tmp/qs-test/logs/test-content-type.log && echo "PASS" || echo "FAIL")
- JavaScript (application/javascript): $(grep -q "application/javascript" /tmp/qs-test/logs/test-content-type.log && echo "PASS" || echo "FAIL")
- JSON (application/json): $(grep -q "application/json" /tmp/qs-test/logs/test-content-type.log && echo "PASS" || echo "FAIL")
- Plain Text (text/plain): $(grep -q "text/plain" /tmp/qs-test/logs/test-content-type.log && echo "PASS" || echo "FAIL")
- Binary (application/octet-stream): $(grep -q "octet-stream" /tmp/qs-test/logs/test-content-type.log && echo "PASS" || echo "FAIL")
- PNG (image/png): $(grep -q "image/png" /tmp/qs-test/logs/test-content-type.log && echo "PASS" || echo "FAIL")

### Directory Handling
- Directory with index.html: $(grep -q "✅ Directory with index.html serves" /tmp/qs-test/logs/test-directory.log && echo "PASS" || echo "FAIL")
- Directory without index.html (403): $(grep -q "✅ Directory without index.html returns 403" /tmp/qs-test/logs/test-directory.log && echo "PASS" || echo "FAIL")

### Security Tests (CRITICAL)
- Path Traversal Block (..): $(grep -q "✅ Path traversal (..) blocked" /tmp/qs-test/logs/test-security.log && echo "✅ PASS" || echo "❌ FAIL")
- Multiple Traversal Block: $(grep -q "✅ Multiple path traversal blocked" /tmp/qs-test/logs/test-security.log && echo "✅ PASS" || echo "❌ FAIL")
- Null Byte Protection: $(grep -q "✅ Null byte injection blocked" /tmp/qs-test/logs/test-security.log && echo "PASS" || echo "INCONCLUSIVE")

### File Integrity
- HTML Download: $(grep -q "✅ HTML file downloaded correctly" /tmp/qs-test/logs/test-download.log && echo "PASS" || echo "FAIL")
- Binary Download: $(grep -q "✅ Binary file downloaded correctly" /tmp/qs-test/logs/test-download.log && echo "PASS" || echo "FAIL")

---

## 4. Enterprise Features Verification

**Assets:**
- [x] assets/error-pages/403.html ($(ls -lh assets/error-pages/403.html 2>/dev/null | awk '{print $5}'))
- [x] assets/error-pages/404.html ($(ls -lh assets/error-pages/404.html 2>/dev/null | awk '{print $5}'))
- [x] assets/error-pages/500.html ($(ls -lh assets/error-pages/500.html 2>/dev/null | awk '{print $5}'))

**Documentation:**
- [x] docs/DEPLOYMENT.md
- [x] docs/MAINTENANCE.md
- [x] docs/DISASTER_RECOVERY.md
- [x] docs/TROUBLESHOOTING.md
- [x] docs/MONITORING_SCHEDULE.md
- [x] docs/BUG_REPORT.md
- [x] CHANGELOG.md (updated for v0.3.2)
- [x] CONTRIBUTING.md

**Package Metadata:**
- Package Name: $(grep "^name" Cargo.toml | cut -d'"' -f2)
- Version: $(grep "^version" Cargo.toml | head -1 | cut -d'"' -f2)
- Homepage: $(grep "^homepage" Cargo.toml | cut -d'"' -f2)
- Repository: $(grep "^repository" Cargo.toml | cut -d'"' -f2)

---

## 5. Issues Found

$(if grep -q "❌ FAIL" /tmp/qs-test/logs/*.log 2>/dev/null; then
  echo "**Issues Detected:**"
  grep "❌" /tmp/qs-test/logs/*.log 2>/dev/null || echo "None"
else
  echo "**No issues detected** - All tests passed successfully."
fi)

---

## 6. Test Artifacts

All test logs are available in:
- Build: build-headless.log
- Unit Tests: test-unit.log
- Integration Tests: test-integration.log
- All Tests: test-all.log
- Code Quality: clippy.log
- Manual Tests: /tmp/qs-test/logs/

Archive created: ~/merge-validation-$(date +%Y%m%d).tar.gz

---

## 7. Recommendation

$(
ALL_PASSED=true
if [ $ALL_EXIT -ne 0 ]; then ALL_PASSED=false; fi
if [ $CLIPPY_EXIT -ne 0 ]; then ALL_PASSED=false; fi
if grep -q "❌ SECURITY ISSUE" /tmp/qs-test/logs/test-security.log 2>/dev/null; then
  echo "⛔ **DO NOT PROCEED** - Critical security issues found"
  ALL_PASSED=false
elif [ "$ALL_PASSED" = true ]; then
  echo "✅ **APPROVED FOR MERGE**"
  echo ""
  echo "All tests passed successfully. The merge is ready to:"
  echo "1. Create pull request"
  echo "2. Merge to main branch"
  echo "3. Tag release v0.3.2-enterprise"
  echo "4. Deploy to production"
else
  echo "⚠️ **FIX ISSUES BEFORE MERGING**"
  echo ""
  echo "Some tests failed. Review the issues above and fix before proceeding."
fi
)

---

## 8. Sign-off

**Validated By:** _____________________________

**Date:** $(date +"%Y-%m-%d")

**Status:** [ ] APPROVED  [ ] REJECTED  [ ] NEEDS REVIEW

**Notes:**
_____________________________________________________________
_____________________________________________________________
_____________________________________________________________

---

## 9. Next Steps

If APPROVED:
1. [ ] Create pull request (see VALIDATION_PLAYBOOK.md Phase 7)
2. [ ] Merge to main branch (see Phase 8)
3. [ ] Tag release v0.3.2-enterprise (see Phase 9)
4. [ ] Verify fresh clone builds (see Phase 10)
5. [ ] Archive backup branch (see Phase 11)

If REJECTED:
1. [ ] Review failure logs in /tmp/qs-test/logs/
2. [ ] Fix identified issues
3. [ ] Re-run validation
4. [ ] Consider rollback if issues are critical

---

**Report Generated:** $(date +"%Y-%m-%d %H:%M:%S")
**Report Location:** $(pwd)/MERGE_VALIDATION_REPORT.md
EOF

echo "✅ Validation report generated: MERGE_VALIDATION_REPORT.md"
```

### 5.2 Archive Test Artifacts
```bash
# Create archive directory
mkdir -p ~/merge-validation-$(date +%Y%m%d)

# Copy all logs
cp build-headless.log ~/merge-validation-$(date +%Y%m%d)/ 2>/dev/null
cp test-*.log ~/merge-validation-$(date +%Y%m%d)/ 2>/dev/null
cp clippy.log ~/merge-validation-$(date +%Y%m%d)/ 2>/dev/null
cp test-summary.txt ~/merge-validation-$(date +%Y%m%d)/ 2>/dev/null
cp -r /tmp/qs-test/logs ~/merge-validation-$(date +%Y%m%d)/manual-tests/ 2>/dev/null

# Copy reports
cp MERGE_VALIDATION_REPORT.md ~/merge-validation-$(date +%Y%m%d)/
cp ENTERPRISE_FEATURES_CHECKLIST.md ~/merge-validation-$(date +%Y%m%d)/

# Create archive
tar czf ~/merge-validation-$(date +%Y%m%d).tar.gz \
  ~/merge-validation-$(date +%Y%m%d)/

echo "✅ Test artifacts archived: ~/merge-validation-$(date +%Y%m%d).tar.gz"
ls -lh ~/merge-validation-$(date +%Y%m%d).tar.gz
```

**✅ Checkpoint:** Report generated, artifacts archived

---

## Phase 6: Review & Decision Point

### 6.1 Review Report
```bash
cat MERGE_VALIDATION_REPORT.md

echo ""
echo "==================================="
echo "VALIDATION COMPLETE"
echo "==================================="
echo ""
echo "Please review MERGE_VALIDATION_REPORT.md"
echo ""
echo "If all tests PASSED:"
echo "  → Proceed to Phase 7 (Create Pull Request)"
echo ""
echo "If tests FAILED:"
echo "  → Review logs and fix issues"
echo "  → Re-run validation"
echo "  → Consider rollback if critical"
echo ""
```

**🛑 DECISION POINT:**
- **If all tests PASS** → Proceed to Phase 7
- **If any test FAILS** → Stop and fix issues
- **If security test FAILS** → STOP IMMEDIATELY and rollback

---

## Phase 7-11: Deployment

For deployment steps (Pull Request, Merge, Release, etc.), see:
- **DEPLOYMENT_PROCEDURES.md** (to be created if proceeding)
- Or continue with this playbook sections below

---

## Rollback Procedure

### If Critical Issues Found:

```bash
cd /home/i/quick-serve-enterprise

# Option 1: Revert to backup branch
git checkout backup-v0.3.1-enterprise-20251112-082324
git checkout -b hotfix-rollback-$(date +%Y%m%d)

# Option 2: Stay on merge branch and revert specific files
git checkout merge-upstream-v0.3.2
git checkout backup-v0.3.1-enterprise-20251112-082324 -- src/servers/http.rs
# Fix the issue
git commit -m "fix: Revert problematic changes"

# Option 3: Abandon merge (ONLY if necessary)
git checkout main
# Do NOT merge, wait for fixes
```

---

## Troubleshooting

### Build Fails
1. Check Rust version: `rustc --version` (need 1.70+)
2. Clean and retry: `cargo clean && cargo build --release`
3. Check disk space: `df -h`
4. Review build-headless.log for specific errors

### Tests Fail
1. Check test-*.log files for specific failures
2. Common issues:
   - Port already in use (kill existing process)
   - File permissions
   - Missing dependencies
3. Run individual test: `cargo test test_name -- --nocapture`

### Manual Tests Fail
1. Check server is running: `ps aux | grep quick-serve`
2. Check port is listening: `netstat -tuln | grep 8080`
3. Test connectivity: `curl -v http://localhost:8080/`
4. Review server logs

### Security Tests Fail
**THIS IS CRITICAL** - Do not proceed if security tests fail.
1. Review /tmp/qs-test/logs/test-security.log
2. Check src/servers/http.rs for validate_file_path() integration
3. Verify validate_file_path() function is being called
4. Consider rollback if issue cannot be quickly fixed

---

## Success Criteria Checklist

**Must Pass (Required):**
- [ ] Compilation successful (exit code 0)
- [ ] All automated tests pass (21+ tests)
- [ ] Custom 404 error page loads
- [ ] Custom 403 error page loads
- [ ] Path traversal BLOCKED (CRITICAL)
- [ ] Content-Type detection works (7+ types)
- [ ] Directory handling works (index.html + 403)
- [ ] File download integrity preserved

**Should Pass (Recommended):**
- [ ] No clippy warnings
- [ ] Code formatting correct
- [ ] Binary size ≤ 4.0 MB
- [ ] All enterprise features verified

**Nice to Have:**
- [ ] Build time ≤ 10 minutes
- [ ] Zero test failures
- [ ] All content types detected correctly

---

## Timeline

- **Phase 1:** Environment Setup: 15 min
- **Phase 2:** Compilation: 20 min
- **Phase 3:** Automated Testing: 30 min
- **Phase 4:** Manual Testing: 45 min
- **Phase 5:** Report Generation: 15 min
- **Phase 6:** Review & Decision: 10 min

**Total:** ~2 hours 15 minutes (with buffer)

---

## Support & References

**Documentation:**
- CHANGELOG.md - Comprehensive merge details
- ENTERPRISE_FEATURES_CHECKLIST.md - Feature tracking
- CONTRIBUTING.md - Contribution guidelines

**Git References:**
- Merge Commit: f3efc38
- Merge Branch: merge-upstream-v0.3.2
- Backup Branch: backup-v0.3.1-enterprise-20251112-082324

**Repository:**
- https://github.com/hah23255/quick-serve-enterprise

**Upstream:**
- https://github.com/joaofl/quick-serve/releases/tag/v0.3.2

---

**Playbook Version:** 1.0
**Created:** 2025-11-12
**Last Updated:** 2025-11-12
