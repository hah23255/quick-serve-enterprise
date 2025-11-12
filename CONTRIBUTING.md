# Contributing to Quick-Serve Enterprise

Thank you for considering contributing to the Enterprise edition of quick-serve!

---

## 🏢 About This Fork

This is a **production deployment fork** focused on enterprise readiness, not general feature development.

### Scope of This Fork

**✅ In Scope:**
- Android/Termux deployment optimizations
- Production operational features
- Bug fixes (especially crashes and data loss)
- Enterprise documentation improvements
- Service management enhancements
- Monitoring and observability tools
- Performance optimizations for embedded devices
- Security hardening

**❌ Out of Scope:**
- New protocol implementations (contribute to upstream)
- Major architectural changes (propose to upstream)
- GUI improvements (upstream focus)
- General feature requests (upstream focus)

---

## 🐛 Reporting Bugs

### Enterprise-Specific Bugs

Use our **[Bug Report Template](docs/BUG_REPORT.md)** for issues related to:
- Enterprise documentation
- Production deployment scripts
- Service management
- Android/Termux specific issues
- Custom error pages

**Submit via:** [GitHub Issues](https://github.com/hah23255/quick-serve-enterprise/issues)

### Upstream Bugs

If the bug affects the **core protocol implementations** (HTTP, FTP, TFTP, DHCP):
1. Report to [upstream](https://github.com/joaofl/quick-serve/issues) first
2. Reference the upstream issue in our repo if it affects enterprise deployments

**Example:** Our directory crash fix was submitted as [upstream Issue #39](https://github.com/joaofl/quick-serve/issues/39).

---

## 💡 Suggesting Enhancements

### For Enterprise Features

Open a GitHub issue with:
- **Title:** `[Enhancement] Your suggestion`
- **Description:** What operational problem does this solve?
- **Use Case:** How does this improve production deployments?
- **Scope:** Is this Android/Termux specific or general?

**Examples of good enterprise enhancements:**
- "Add Prometheus metrics endpoint for monitoring"
- "Implement graceful shutdown for service restarts"
- "Add health check endpoint for load balancers"

### For General Features

Please direct **general feature requests** to the [upstream project](https://github.com/joaofl/quick-serve/issues).

---

## 🔧 Contributing Code

### Getting Started

1. **Fork** the repository
2. **Clone** your fork:
   ```bash
   git clone https://github.com/YOUR-USERNAME/quick-serve-enterprise.git
   cd quick-serve-enterprise
   ```
3. **Create a branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```

### Development Guidelines

**Code Style:**
- Follow existing Rust conventions
- Run `cargo fmt` before committing
- Ensure `cargo clippy` passes with no warnings
- Keep functions focused and modular

**Testing:**
```bash
# Run all tests
cargo test

# Check formatting
cargo fmt --check

# Run clippy
cargo clippy -- -D warnings
```

**Documentation:**
- Update relevant documentation files
- Add inline comments for complex logic
- Update CHANGELOG.md with your changes

### Commit Messages

Follow conventional commits:
```
type(scope): short description

Longer explanation if needed.

Fixes #123
```

**Types:** `fix`, `feat`, `docs`, `refactor`, `test`, `chore`

**Examples:**
```
fix(http): prevent crash on directory access without index.html

feat(monitoring): add health check endpoint
docs(deployment): update runit configuration steps
```

### Pull Request Process

1. **Update documentation** if your change affects:
   - Installation procedures
   - Configuration options
   - API behavior
   - Operational procedures

2. **Update CHANGELOG.md** under "Unreleased" section

3. **Test on Android/Termux** if your change affects:
   - Build process
   - File system operations
   - Service management

4. **Submit PR** with:
   - Clear title and description
   - Reference to related issues
   - Test results (if applicable)
   - Screenshots (for UI changes)

5. **PR Review:**
   - Maintainer will review within 3-5 business days
   - Address feedback promptly
   - Keep commits clean and focused

---

## 📚 Documentation Contributions

**Documentation improvements are HIGHLY valued!**

### Types of Documentation Contributions

**Operational Guides:**
- Deployment scenarios
- Troubleshooting procedures
- Monitoring best practices
- Performance tuning guides

**Platform-Specific Guides:**
- Android device variations
- Different Termux setups
- Cross-compilation tips
- ARM architecture specifics

**Examples and Tutorials:**
- Real-world deployment stories
- Integration with other services
- Advanced configurations

### Documentation Style

- **Clear and concise** - operational focus
- **Step-by-step** - commands copy-pasteable
- **Production-ready** - no "TODO" or incomplete sections
- **Tested** - verify all commands work

---

## 🌍 Platforms

### Primary Platform: Android/Termux ARM64

All changes must work on:
- Android 10+
- Termux (latest stable)
- ARM64 architecture

### Secondary Platforms: Linux x86_64

Should work on standard Linux, but Android/Termux is priority.

### Testing

If you can't test on Android:
- Clearly state this in PR
- Maintainer will test before merge

---

## ⚖️ License

By contributing, you agree that your contributions will be licensed under the MIT License.

You retain copyright of your contributions, but grant permission for use under MIT License.

---

## 🙋 Questions?

**Contact Maintainer:**
- **GitHub:** [@hah23255](https://github.com/hah23255)
- **LinkedIn:** [Hristo Hristov](https://www.linkedin.com/in/hristo-hristov-93868648)
- **Website:** [www.ccvs.tech](https://www.ccvs.tech)

**For Quick Questions:**
- Open a GitHub Discussion
- Comment on related issues

---

## 🙏 Thank You!

Every contribution makes this project better for production deployments!

**Special thanks to:**
- João Loureiro for the excellent upstream project
- All contributors who improve enterprise features
- Users who report bugs and suggest improvements

---

**Happy Contributing!** 🚀
