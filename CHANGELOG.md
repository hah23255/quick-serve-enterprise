# Changelog - Quick-Serve Enterprise

All notable changes to the Enterprise edition.

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

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
