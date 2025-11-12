# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 0.3.x-enterprise | :white_check_mark: |
| < 0.3   | :x:                |

## Reporting a Vulnerability

**IMPORTANT: Do NOT open public issues for security vulnerabilities.**

### How to Report

1. **Email**: security@ccvs.tech
2. **Subject**: "Quick-Serve Enterprise Security Vulnerability"
3. **Include**:
   - Vulnerability type (path traversal, DoS, etc.)
   - Steps to reproduce
   - Proof of concept (if safe to share)
   - Affected versions

### Response Timeline

- **Acknowledgment**: 24 hours
- **Assessment**: 72 hours
- **Fix Timeline**:
  - Critical (RCE, data exposure): 3-7 days
  - High (DoS, auth bypass): 7-14 days
  - Medium: 14-30 days

## Security Measures

### Path Traversal Prevention

- All file paths validated
- Symlinks handled safely
- Directory listing disabled by default
- Custom error pages prevent info disclosure

### Denial of Service Protection

- Request rate limiting (coming soon)
- File size limits enforced
- Connection timeouts configured
- Resource limits on Android/Termux

### Error Handling

- No stack traces in error pages
- No internal paths exposed
- Custom error pages (403/404/500)
- Minimal information disclosure

## Security Best Practices

### Deployment

```bash
# Bind to localhost only (for local development)
quick-serve --bind 127.0.0.1

# Use non-standard port (security through obscurity)
quick-serve -p 50080

# Restrict file permissions
chmod 755 ~/DropBasket/
chmod 644 ~/DropBasket/*
```

### Firewall Configuration

```bash
# Allow only specific IPs (Linux)
sudo ufw allow from 192.168.1.0/24 to any port 50080

# Block external access on Android/Termux
# (Termux apps are sandboxed by default)
```

### Production Deployment

1. **Never expose to internet** without reverse proxy
2. **Use HTTPS** via nginx/caddy in production
3. **Implement authentication** for sensitive files
4. **Monitor access logs**
5. **Regular security updates**

## Known Security Considerations

### Information Disclosure

- Server header reveals software version
- Custom error pages reveal server type
- Directory structure may be guessable

### Mitigation

```bash
# Use reverse proxy to hide server details
# Example nginx config:
server {
    location / {
        proxy_pass http://localhost:50080;
        proxy_set_header Server "web-server";
    }
}
```

### Android/Termux Specific

- App sandboxing provides isolation
- No root permissions required
- Storage access limited to Termux home
- Network access controlled by Android

## Vulnerability Disclosure

We follow responsible disclosure:
- 90-day disclosure timeline
- Coordination with upstream (joaofl/quick-serve)
- Security advisories on GitHub
- CVE assignment for critical issues

## Security Changelog

### v0.3.2-enterprise
- Fixed directory crash bug (CVE-TBD)
- Added custom error pages
- Improved path validation

## Contact

- **Email**: security@ccvs.tech
- **Website**: https://www.ccvs.tech
- **Response Time**: 24 hours maximum

## Acknowledgments

Security researchers who have helped:
- [Your name here - report vulnerabilities to be listed]

---

**Thank you for helping keep Quick-Serve Enterprise secure!** 🔒
