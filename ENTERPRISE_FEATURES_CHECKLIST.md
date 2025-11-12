# Enterprise Features Preservation Checklist

## Critical Features to Preserve During Merge

### Custom Error Pages
- [ ] assets/error-pages/403.html (3.1KB)
- [ ] assets/error-pages/404.html (3.1KB)
- [ ] assets/error-pages/500.html (3.6KB)
- [ ] load_error_page() function in http.rs

### HTTP Server Enterprise Features
- [ ] Directory index.html serving (auto-serve index.html from directories)
- [ ] 403 Forbidden for directories without index.html (not 400 BAD_REQUEST)
- [ ] Content-Type detection for 11+ file types
- [ ] Custom error page loading and serving

### Enterprise Documentation
- [ ] docs/DEPLOYMENT.md
- [ ] docs/MAINTENANCE.md
- [ ] docs/DISASTER_RECOVERY.md
- [ ] docs/TROUBLESHOOTING.md
- [ ] docs/MONITORING_SCHEDULE.md
- [ ] docs/BUG_REPORT.md
- [ ] CHANGELOG.md
- [ ] CONTRIBUTING.md

### Package Metadata
- [ ] Package name: quick-serve-enterprise
- [ ] Authors: João Loureiro + Hristo Hristov
- [ ] Homepage: https://www.ccvs.tech
- [ ] Repository: https://github.com/hah23255/quick-serve-enterprise
- [ ] Description: Enterprise-specific description
- [ ] Keywords: android, http-server, ftp, tftp, file-server

### Critical Fixes to Preserve
- [ ] Directory crash fix (Issue #39 upstream)
- [ ] Proper 403 handling vs upstream's BAD_REQUEST

## Merge Verification Steps

### After http.rs Merge
- [ ] load_error_page() function present
- [ ] Directory handling logic preserved
- [ ] index.html serving logic preserved
- [ ] Content-Type detection present
- [ ] Custom error pages used (not generic messages)

### After Complete Merge
- [ ] All assets/ files present
- [ ] All docs/ files present
- [ ] CHANGELOG.md and CONTRIBUTING.md present
- [ ] Cargo.toml has enterprise metadata
- [ ] All tests passing
- [ ] Binary builds successfully

## Test Verification

### Manual Tests Required
- [ ] Test 403 error page loads (directory without index.html)
- [ ] Test 404 error page loads (non-existent file)
- [ ] Test 500 error page loads (simulated error)
- [ ] Test index.html served from directory
- [ ] Test Content-Type for HTML file
- [ ] Test Content-Type for CSS file
- [ ] Test Content-Type for JS file
- [ ] Test Content-Type for image files (PNG, JPG, etc.)

### Security Tests
- [ ] Path traversal blocked (../../etc/passwd)
- [ ] Null byte injection blocked
- [ ] Absolute path blocked
- [ ] Directory boundaries enforced

## Status: MERGE IN PROGRESS
Created: 2025-11-12
Branch: merge-upstream-v0.3.2
Backup: backup-v0.3.1-enterprise-20251112-082324
