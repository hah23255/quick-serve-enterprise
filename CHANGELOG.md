# Changelog - Quick-Serve Enterprise

All notable changes to the Enterprise edition.

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [0.3.2-enterprise] - 2025-11-12

### Merged from Upstream v0.3.2

This release integrates all improvements from [upstream v0.3.2](https://github.com/joaofl/quick-serve/releases/tag/v0.3.2) (19 commits, 17 files changed) while preserving all enterprise-specific features and enhancements.

#### Added from Upstream

**New Error Handling System:**
- Added `src/common/errors.rs` with comprehensive `QuickServeError` enum
  - Network errors (binding, connections)
  - Validation errors (invalid paths, IPs, ports)
  - Server lifecycle errors (start/stop failures)
  - IO errors (file operations)
- Type-safe error propagation with `QuickServeResult<T>` alias
- Helper functions for creating specific error types
- Comprehensive error tests (17 test cases)

**Enhanced Security Validation:**
- Added `validate_file_path()` function for path traversal protection
  - Blocks `..` (parent directory) attempts
  - Blocks double slashes `//`
  - Blocks absolute paths
  - Blocks null byte injection
  - Ensures resolved path stays within base directory
- Enhanced `validate_ip_port()` with better error messages
- Enhanced `validate_path()` with security checks

**Improved Testing:**
- Added 4 comprehensive HTTP server tests:
  - `test_http_file_download_success()`
  - `test_file_not_found()`
  - `test_path_is_directory()`
  - `test_path_traversal_blocked()`
- Enhanced validation test suite (17 tests total)
- Security attack scenario tests

**Better Logging & Error Handling:**
- Enhanced logging with `log::error` macro throughout
- Better error context in all server implementations
- Improved debugging information
- Categorized error messages

**Enhanced Documentation:**
- Added comprehensive doc comments to all public functions
- Enhanced inline documentation
- Better API documentation for error types
- Improved server lifecycle documentation

#### Changed from Upstream

**Error Handling Architecture:**
- All trait signatures now return `Result<Self, QuickServeError>`
- Replaced `.expect()` panics with proper `?` error propagation
- Replaced `Result<(), String>` with `QuickServeResult<()>`
- Server `start()` and `stop()` methods now return Results

**Protocol & Server Improvements:**
- Protocol enum now derives `Eq` and `Hash`
- Enhanced server lifecycle management
- Better error handling in `server_starter_receiver()`
- Improved shutdown signal handling

**Dependency Updates:**
- Updated eframe to v0.33 (from v0.32)
- Aligned with upstream dependency strategy

#### Maintained (All Enterprise Features Preserved)

**✅ Custom Error Pages:**
- `assets/error-pages/403.html` - Professional purple gradient
- `assets/error-pages/404.html` - Professional pink gradient
- `assets/error-pages/500.html` - Professional orange gradient
- `load_error_page()` function preserved and integrated

**✅ Enhanced HTTP Server:**
- Directory index.html automatic serving preserved
- 403 Forbidden for directories without index.html (not upstream's 400 BAD_REQUEST)
- Content-Type detection for 11+ file types preserved
- Custom error page serving fully integrated with upstream security

**✅ Enterprise Documentation Suite:**
- DEPLOYMENT.md - Complete
- MAINTENANCE.md - Complete
- DISASTER_RECOVERY.md - Complete
- TROUBLESHOOTING.md - Complete
- MONITORING_SCHEDULE.md - Complete
- BUG_REPORT.md - Complete
- CONTRIBUTING.md - Complete

**✅ Package Identity:**
- Package name: `quick-serve-enterprise`
- Maintainer attribution: Hristo Hristov
- Homepage: https://www.ccvs.tech
- Repository: https://github.com/hah23255/quick-serve-enterprise
- Custom description and keywords

**✅ Android/Termux Optimizations:**
- All build scripts and deployment procedures preserved
- Service management integration maintained

#### Integration Details

**Critical Files Manually Merged:**
- `src/servers/http.rs` - Combined upstream security + enterprise UX
  - Upstream's `validate_file_path()` for security
  - Enterprise's `load_error_page()` for UX
  - Enterprise's directory + index.html serving logic
  - Enterprise's Content-Type detection
  - Upstream's enhanced logging
  - Upstream's comprehensive test suite

**Files Updated from Upstream:**
- `src/common/errors.rs` - NEW FILE (119 lines)
- `src/common/mod.rs` - Added error exports
- `src/servers/server.rs` - Enhanced error handling & docs
- `src/servers/ftp.rs` - Updated trait & error handling
- `src/servers/tftp.rs` - Updated trait & error handling
- `src/servers/dhcp.rs` - Updated trait & error handling
- `src/utils/validation.rs` - Complete replacement with enhanced security

#### Security Improvements

**Path Traversal Protection:**
- Comprehensive validation now blocks all path traversal attempts
- Null byte injection protection
- Absolute path rejection
- Directory boundary enforcement

**Error Information Leakage:**
- Maintained enterprise custom error pages (no info leakage)
- Combined with upstream's detailed logging for debugging

#### Testing Status

**Automated Tests:** Pending compilation (requires Rust toolchain)
**Manual Verification:** All file structures and enterprise features confirmed present
**Expected Results:**
- All unit tests should pass
- All integration tests should pass
- All security tests should pass
- Custom error pages should load correctly
- Content-Type detection should work for all 11+ types

#### Migration Notes

**Breaking Changes:**
- Trait signatures changed to return `Result` types
- Error handling migrated from `String` to `QuickServeError`
- All `.expect()` calls replaced with `?` operator

**Compatibility:**
- Binary API unchanged (command-line interface identical)
- Network protocol unchanged
- Enterprise features fully compatible

#### Version Information

**Upstream Base:** [quick-serve v0.3.2](https://github.com/joaofl/quick-serve/compare/v0.3.1...v0.3.2)
**Merge Date:** 2025-11-12
**Merge Complexity:** High (manual merge of http.rs required)
**Files Changed:** 10 files
**Lines Added:** ~500 (upstream security + error system)
**Lines Preserved:** ~100 (enterprise features)

---

## [0.3.1-enterprise] - 2025-10-19

### Added
- **Custom professional error pages** for HTTP server
  - 403 Forbidden (purple gradient theme)
  - 404 Not Found (pink gradient theme)
  - 500 Internal Server Error (orange gradient theme)
- **Comprehensive enterprise documentation suite**
  - DEPLOYMENT.md - Production setup guide
  - MAINTENANCE.md - Operational procedures
  - DISASTER_RECOVERY.md - Emergency protocols
  - TROUBLESHOOTING.md - Problem resolution guide
  - MONITORING_SCHEDULE.md - Health check procedures
  - BUG_REPORT.md - Issue reporting template
- **Android/Termux production deployment scripts**
  - runit service integration
  - Automatic startup configuration
  - Convenience aliases (qs-start, qs-stop, qs-status, etc.)
  - Health check scripts
- **Build optimizations for Android**
  - noexec filesystem workarounds (V2 pattern)
  - Cross-compilation support
  - ARM64 optimized binaries

### Fixed
- **CRITICAL: HTTP server directory crash** (Issue #39 upstream)
  - Server previously crashed when accessing directories without index.html
  - Now returns proper 403 Forbidden response
  - Directory listing properly disabled
  - Content-Type detection improved (11+ file types)

### Changed
- Enhanced HTTP server with professional error handling
- Improved logging for production debugging
- Optimized binary size for mobile deployment (~3.7MB)

### Documentation
- Complete production deployment guide
- Weekly/monthly maintenance schedules
- Disaster recovery procedures
- Troubleshooting playbooks
- Service management documentation

### Security
- Directory listing disabled by default (403 unless index.html present)
- Non-standard port recommendations (30000-60000 range)
- Bind IP configuration guidance (0.0.0.0 vs 127.0.0.1)

---

## Upstream Base

**Based on:** [quick-serve v0.3.1](https://github.com/joaofl/quick-serve)
**Original Author:** João Loureiro
**Fork Maintainer:** Hristo Hristov (hah23255)

### Upstream Contributions
- **Issue #39** - Directory crash fix submitted to upstream
- Maintaining compatibility with upstream protocol implementations
- Bug fixes contributed back when applicable

---

## Future Roadmap

### Planned Enhancements
- [ ] Basic authentication support
- [ ] HTTPS/TLS support
- [ ] Styled directory listing (optional)
- [ ] Rate limiting
- [ ] Prometheus metrics endpoint
- [ ] Health check endpoint (/health)
- [ ] Access log rotation automation

### Under Consideration
- [ ] Web-based admin interface
- [ ] File upload support
- [ ] User management system
- [ ] API for remote management

---

**Versioning:** This project follows semantic versioning with `-enterprise` suffix to distinguish from upstream.

**Compatibility:** Aims to maintain protocol compatibility with upstream for easy migration.
