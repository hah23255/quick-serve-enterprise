#!/bin/bash
#===============================================================================
# quick-serve-enterprise v0.3.2 Merge Validation Script
#
# Purpose: Automated validation of upstream v0.3.2 merge
# Created: 2025-11-12
# Merge Commit: f3efc38
# Branch: merge-upstream-v0.3.2
#
# Usage: bash scripts/validate-merge.sh
# Duration: ~2 hours
# Output: MERGE_VALIDATION_REPORT.md + test logs
#===============================================================================

set -e  # Exit on error (can be overridden for specific commands)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNINGS=0

#===============================================================================
# Helper Functions
#===============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
    ((PASSED_CHECKS++))
    ((TOTAL_CHECKS++))
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
    ((FAILED_CHECKS++))
    ((TOTAL_CHECKS++))
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
    ((WARNINGS++))
}

section_header() {
    echo ""
    echo "==============================================================================="
    echo " $1"
    echo "==============================================================================="
    echo ""
}

check_command() {
    if command -v $1 &> /dev/null; then
        log_success "$1 is available"
        return 0
    else
        log_error "$1 is NOT available"
        return 1
    fi
}

#===============================================================================
# Phase 1: Pre-Flight Checks
#===============================================================================

section_header "PHASE 1: Pre-Flight Checks"

# Check we're in the right directory
if [ ! -f "Cargo.toml" ]; then
    log_error "Not in project root directory (Cargo.toml not found)"
    exit 1
fi
log_success "In project root directory"

# Check we're on the right branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "merge-upstream-v0.3.2" ]; then
    log_warning "Not on merge-upstream-v0.3.2 branch (current: $CURRENT_BRANCH)"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    log_success "On correct branch: merge-upstream-v0.3.2"
fi

# Check Rust toolchain
check_command rustc || exit 1
check_command cargo || exit 1

RUST_VERSION=$(rustc --version | awk '{print $2}')
log_info "Rust version: $RUST_VERSION"

# Check git state
if [ -z "$(git status --porcelain)" ]; then
    log_success "Working tree is clean"
else
    log_warning "Working tree has uncommitted changes"
fi

# Check merge commit present
if git log --oneline -1 | grep -q "f3efc38\|merge: Integrate upstream v0.3.2"; then
    log_success "Merge commit present"
else
    log_warning "Merge commit not found (expected f3efc38)"
fi

# Check enterprise files
ENTERPRISE_FILES=(
    "assets/error-pages/403.html"
    "assets/error-pages/404.html"
    "assets/error-pages/500.html"
    "docs/DEPLOYMENT.md"
    "docs/MAINTENANCE.md"
    "CHANGELOG.md"
    "CONTRIBUTING.md"
)

for file in "${ENTERPRISE_FILES[@]}"; do
    if [ -f "$file" ]; then
        log_success "$file present"
    else
        log_error "$file MISSING"
    fi
done

echo ""
read -p "Pre-flight checks complete. Continue with validation? (Y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    exit 0
fi

#===============================================================================
# Phase 2: Compilation
#===============================================================================

section_header "PHASE 2: Compilation"

log_info "Cleaning previous build..."
cargo clean

log_info "Building release binary (this may take 5-10 minutes)..."
echo "Build started: $(date)" | tee build-headless.log

if time cargo build --release --no-default-features --bin quick-serve 2>&1 | tee -a build-headless.log; then
    log_success "Build completed successfully"
    echo "Build finished: $(date)" | tee -a build-headless.log
else
    log_error "Build FAILED (see build-headless.log)"
    exit 1
fi

# Verify binary
if [ -f "target/release/quick-serve" ]; then
    BINARY_SIZE=$(ls -lh target/release/quick-serve | awk '{print $5}')
    log_success "Binary created: $BINARY_SIZE"

    # Test version
    VERSION_OUTPUT=$(./target/release/quick-serve --version 2>&1 || echo "ERROR")
    if [[ $VERSION_OUTPUT == *"0.3.2"* ]] || [[ $VERSION_OUTPUT == *"quick-serve"* ]]; then
        log_success "Binary version check passed"
    else
        log_warning "Version output: $VERSION_OUTPUT"
    fi
else
    log_error "Binary not found at target/release/quick-serve"
    exit 1
fi

#===============================================================================
# Phase 3: Automated Tests
#===============================================================================

section_header "PHASE 3: Automated Tests"

log_info "Running unit tests..."
if cargo test --lib 2>&1 | tee test-unit.log; then
    UNIT_EXIT=0
    log_success "Unit tests passed"
else
    UNIT_EXIT=$?
    log_error "Unit tests FAILED (exit code: $UNIT_EXIT)"
fi

log_info "Running integration tests..."
if cargo test --test '*' 2>&1 | tee test-integration.log; then
    INTEGRATION_EXIT=0
    log_success "Integration tests passed"
else
    INTEGRATION_EXIT=$?
    log_error "Integration tests FAILED (exit code: $INTEGRATION_EXIT)"
fi

log_info "Running all tests..."
if cargo test --release 2>&1 | tee test-all.log; then
    ALL_EXIT=0
    log_success "All tests passed"
    TEST_SUMMARY=$(grep "test result:" test-all.log | tail -1)
    log_info "$TEST_SUMMARY"
else
    ALL_EXIT=$?
    log_error "Some tests FAILED (exit code: $ALL_EXIT)"
    TEST_SUMMARY=$(grep "test result:" test-all.log | tail -1)
    log_info "$TEST_SUMMARY"
fi

log_info "Running clippy..."
if cargo clippy -- -D warnings 2>&1 | tee clippy.log; then
    CLIPPY_EXIT=0
    log_success "Clippy passed with no warnings"
else
    CLIPPY_EXIT=$?
    log_warning "Clippy found issues (exit code: $CLIPPY_EXIT)"
fi

log_info "Checking code formatting..."
if cargo fmt --check; then
    FMT_EXIT=0
    log_success "Code formatting is correct"
else
    FMT_EXIT=$?
    log_warning "Code formatting needs adjustment"
fi

#===============================================================================
# Phase 4: Manual Feature Tests
#===============================================================================

section_header "PHASE 4: Manual Feature Tests"

log_info "Setting up test environment..."
mkdir -p /tmp/qs-test/{files,logs,downloads}
cd /tmp/qs-test/files

# Create test files
cat > test.html <<'EOF'
<!DOCTYPE html>
<html><body><h1>Test HTML</h1></body></html>
EOF
echo "body { color: red; }" > test.css
echo "console.log('test');" > test.js
echo '{"test": true}' > test.json
echo "plain text" > test.txt
dd if=/dev/urandom of=test.bin bs=1M count=1 2>/dev/null

# Create directories
mkdir -p with-index no-index
echo "<html><body>Index</body></html>" > with-index/index.html
echo "file" > no-index/file.txt

cd /home/i/quick-serve-enterprise
log_success "Test environment created"

# Start server
log_info "Starting test server on port 8080..."
./target/release/quick-serve --http 8080 -d /tmp/qs-test/files --headless > /tmp/qs-test/logs/server.log 2>&1 &
SERVER_PID=$!
echo $SERVER_PID > /tmp/qs-test/logs/server-pid.txt
sleep 3

# Verify server started
if ps -p $SERVER_PID > /dev/null; then
    log_success "Server started (PID: $SERVER_PID)"
else
    log_error "Server failed to start"
    cat /tmp/qs-test/logs/server.log
    exit 1
fi

# Test connectivity
if curl -s http://localhost:8080/test.html > /dev/null; then
    log_success "Server responding to requests"
else
    log_error "Server not responding"
    kill $SERVER_PID 2>/dev/null
    exit 1
fi

# Test 404 error page
log_info "Testing 404 error page..."
curl -v http://localhost:8080/nonexistent.html 2>&1 | tee /tmp/qs-test/logs/test-404.log > /dev/null
if grep -q "404" /tmp/qs-test/logs/test-404.log && grep -qi "not found" /tmp/qs-test/logs/test-404.log; then
    log_success "404 custom error page works"
else
    log_error "404 custom error page FAILED"
fi

# Test 403 for directory without index
log_info "Testing 403 for directory without index.html..."
curl -v http://localhost:8080/no-index/ 2>&1 | tee /tmp/qs-test/logs/test-403.log > /dev/null
if grep -q "403" /tmp/qs-test/logs/test-403.log; then
    log_success "403 Forbidden for directories works"
else
    log_error "403 for directories FAILED"
fi

# Test Content-Types
log_info "Testing Content-Type detection..."
CONTENT_TYPES_OK=true
curl -I http://localhost:8080/test.html 2>/dev/null | grep -i "content-type" | grep -q "text/html" || CONTENT_TYPES_OK=false
curl -I http://localhost:8080/test.css 2>/dev/null | grep -i "content-type" | grep -q "text/css" || CONTENT_TYPES_OK=false
curl -I http://localhost:8080/test.js 2>/dev/null | grep -i "content-type" | grep -q "javascript" || CONTENT_TYPES_OK=false
curl -I http://localhost:8080/test.json 2>/dev/null | grep -i "content-type" | grep -q "json" || CONTENT_TYPES_OK=false

if [ "$CONTENT_TYPES_OK" = true ]; then
    log_success "Content-Type detection works"
else
    log_error "Content-Type detection FAILED"
fi

# Test directory with index.html
log_info "Testing directory with index.html..."
if curl -s http://localhost:8080/with-index/ | grep -q "Index"; then
    log_success "Directory with index.html serves index page"
else
    log_error "Directory with index.html FAILED"
fi

# CRITICAL: Test path traversal protection
log_info "CRITICAL: Testing path traversal protection..."
curl -v "http://localhost:8080/../../etc/passwd" 2>&1 | tee /tmp/qs-test/logs/test-security.log > /dev/null
if grep -q "400\|403" /tmp/qs-test/logs/test-security.log; then
    log_success "Path traversal BLOCKED (CRITICAL SECURITY CHECK PASSED)"
else
    log_error "⚠️  SECURITY ISSUE: Path traversal NOT blocked!"
    echo ""
    echo "=========================================="
    echo "CRITICAL SECURITY FAILURE DETECTED"
    echo "=========================================="
    echo "Path traversal attacks are NOT being blocked."
    echo "DO NOT PROCEED with this merge."
    echo "Review: src/servers/http.rs validate_file_path() integration"
    echo ""
    kill $SERVER_PID 2>/dev/null
    exit 1
fi

# Test file download integrity
log_info "Testing file download integrity..."
curl -s http://localhost:8080/test.html -o /tmp/qs-test/downloads/test.html
if diff /tmp/qs-test/files/test.html /tmp/qs-test/downloads/test.html > /dev/null; then
    log_success "File download integrity preserved"
else
    log_error "File download integrity FAILED"
fi

# Stop server
log_info "Stopping test server..."
kill $SERVER_PID 2>/dev/null
sleep 2
if ! ps -p $SERVER_PID > /dev/null 2>&1; then
    log_success "Server stopped cleanly"
else
    kill -9 $SERVER_PID 2>/dev/null
    log_warning "Server required force kill"
fi

#===============================================================================
# Phase 5: Generate Report
#===============================================================================

section_header "PHASE 5: Generating Validation Report"

log_info "Generating MERGE_VALIDATION_REPORT.md..."

cat > MERGE_VALIDATION_REPORT.md <<REPORT_EOF
# Merge Validation Report
## quick-serve-enterprise v0.3.2

**Validation Date:** $(date +"%Y-%m-%d %H:%M:%S")
**Validator:** $(whoami)@$(hostname)
**Merge Commit:** f3efc38
**Branch:** merge-upstream-v0.3.2

---

## Executive Summary

**Overall Status:** $(if [ $FAILED_CHECKS -eq 0 ] && [ $ALL_EXIT -eq 0 ]; then echo "✅ PASS"; else echo "❌ FAIL"; fi)

**Quick Stats:**
- Total Checks: $TOTAL_CHECKS
- Passed: $PASSED_CHECKS
- Failed: $FAILED_CHECKS
- Warnings: $WARNINGS

---

## 1. Build Results

**Compilation:**
- Status: $(grep -q "Finished \`release\`" build-headless.log && echo "✅ PASS" || echo "❌ FAIL")
- Binary Size: $(ls -lh target/release/quick-serve 2>/dev/null | awk '{print $5}' || echo "N/A")
- Binary Version: $(./target/release/quick-serve --version 2>/dev/null || echo "N/A")

**Code Quality:**
- Clippy: $([ $CLIPPY_EXIT -eq 0 ] && echo "✅ PASS" || echo "⚠️  WARNINGS")
- Formatting: $([ $FMT_EXIT -eq 0 ] && echo "✅ PASS" || echo "⚠️  NEEDS FIX")

---

## 2. Automated Test Results

**Unit Tests:**
$(grep "test result:" test-unit.log 2>/dev/null | tail -1 || echo "No results")
Exit Code: $UNIT_EXIT

**Integration Tests:**
$(grep "test result:" test-integration.log 2>/dev/null | tail -1 || echo "No results")
Exit Code: $INTEGRATION_EXIT

**All Tests:**
$(grep "test result:" test-all.log 2>/dev/null | tail -1 || echo "No results")
Exit Code: $ALL_EXIT

**Overall:** $([ $ALL_EXIT -eq 0 ] && echo "✅ ALL TESTS PASSED" || echo "❌ SOME TESTS FAILED")

---

## 3. Manual Feature Tests

$(grep "\[✓\]" /tmp/qs-test/logs/test-*.log 2>/dev/null | wc -l) manual tests passed
$(grep "\[✗\]" /tmp/qs-test/logs/test-*.log 2>/dev/null | wc -l) manual tests failed

**Enterprise Features:**
- Custom 404 Page: $(grep -q "404" /tmp/qs-test/logs/test-404.log && echo "✅ PASS" || echo "❌ FAIL")
- Custom 403 Page: $(grep -q "403" /tmp/qs-test/logs/test-403.log && echo "✅ PASS" || echo "❌ FAIL")
- Content-Type Detection: $([ "$CONTENT_TYPES_OK" = true ] && echo "✅ PASS" || echo "❌ FAIL")
- Directory Handling: $(curl -s http://localhost:8080/with-index/ 2>/dev/null | grep -q "Index" && echo "✅ PASS" || echo "See logs")

**Security (CRITICAL):**
- Path Traversal Protection: $(grep -q "400\|403" /tmp/qs-test/logs/test-security.log && echo "✅ PASS" || echo "❌ FAIL")

---

## 4. Test Artifacts

All test logs available in:
- Build: build-headless.log
- Tests: test-unit.log, test-integration.log, test-all.log
- Quality: clippy.log
- Manual: /tmp/qs-test/logs/

---

## 5. Issues Found

$(if [ $FAILED_CHECKS -gt 0 ] || [ $ALL_EXIT -ne 0 ]; then
    echo "**Issues Detected:**"
    grep "\[✗\]" /tmp/qs-test/logs/*.log 2>/dev/null || echo "See test logs for details"
else
    echo "**No critical issues detected.**"
fi)

---

## 6. Recommendation

$(
if grep -q "SECURITY ISSUE" /tmp/qs-test/logs/test-security.log 2>/dev/null; then
    echo "⛔ **DO NOT PROCEED** - Critical security vulnerability detected"
elif [ $FAILED_CHECKS -eq 0 ] && [ $ALL_EXIT -eq 0 ]; then
    echo "✅ **APPROVED FOR MERGE**"
    echo ""
    echo "All critical tests passed. Ready to:"
    echo "1. Create pull request"
    echo "2. Merge to main branch"
    echo "3. Tag release v0.3.2-enterprise"
else
    echo "⚠️ **FIX ISSUES BEFORE MERGING**"
    echo ""
    echo "Review failed tests and fix before proceeding."
fi
)

---

## 7. Next Steps

**If APPROVED:**
1. Create pull request: \`gh pr create ...\`
2. Merge to main
3. Tag release v0.3.2-enterprise
4. Verify fresh clone builds

**If REJECTED:**
1. Review failure logs
2. Fix identified issues
3. Re-run validation: \`bash scripts/validate-merge.sh\`

---

**Report Generated:** $(date +"%Y-%m-%d %H:%M:%S")
**Script Version:** 1.0
**Playbook:** VALIDATION_PLAYBOOK.md
REPORT_EOF

log_success "Report generated: MERGE_VALIDATION_REPORT.md"

# Archive artifacts
log_info "Archiving test artifacts..."
mkdir -p ~/merge-validation-$(date +%Y%m%d)
cp *.log ~/merge-validation-$(date +%Y%m%d)/ 2>/dev/null || true
cp MERGE_VALIDATION_REPORT.md ~/merge-validation-$(date +%Y%m%d)/
cp -r /tmp/qs-test/logs ~/merge-validation-$(date +%Y%m%d)/manual-tests 2>/dev/null || true

if tar czf ~/merge-validation-$(date +%Y%m%d).tar.gz ~/merge-validation-$(date +%Y%m%d)/ 2>/dev/null; then
    log_success "Artifacts archived: ~/merge-validation-$(date +%Y%m%d).tar.gz"
else
    log_warning "Failed to create archive"
fi

#===============================================================================
# Final Summary
#===============================================================================

section_header "VALIDATION COMPLETE"

echo "Total Checks: $TOTAL_CHECKS"
echo "Passed: $PASSED_CHECKS"
echo "Failed: $FAILED_CHECKS"
echo "Warnings: $WARNINGS"
echo ""

if [ $FAILED_CHECKS -eq 0 ] && [ $ALL_EXIT -eq 0 ]; then
    echo -e "${GREEN}✅ VALIDATION PASSED${NC}"
    echo ""
    echo "Next step: Review MERGE_VALIDATION_REPORT.md"
    echo "Then proceed with: Phase 7 (Pull Request)"
    exit 0
else
    echo -e "${RED}❌ VALIDATION FAILED${NC}"
    echo ""
    echo "Review MERGE_VALIDATION_REPORT.md for details"
    echo "Fix issues and re-run validation"
    exit 1
fi
