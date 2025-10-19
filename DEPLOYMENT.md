# Quick-serve Enterprise Deployment Guide

## Production Deployment

**Status**: ✅ Deployed and Running
**Version**: 0.3.1 (Enterprise Edition with custom error pages)
**Platform**: Android/Termux ARM64

---

## Service Management

### Quick Commands (Aliases)

```bash
qs-start      # Start the service
qs-stop       # Stop the service
qs-restart    # Restart the service
qs-status     # Check service status
qs-logs       # View live logs
qs-url        # Show network access URL
qs            # Quick status check
```

### Manual Commands

```bash
# Service control
sv up quick-serve          # Start
sv down quick-serve        # Stop
sv restart quick-serve     # Restart
sv status quick-serve      # Status

# View logs
tail -f $PREFIX/var/service/quick-serve/log/main/current
```

---

## Auto-Start Configuration

**Boot Script**: `~/.termux/boot/start-quick-serve.sh`

The service automatically starts when:
1. Termux app opens (via Termux:Boot if installed)
2. The boot script is manually executed
3. `sv up quick-serve` is run

**Requirements**:
- Termux:Boot app (optional, for true auto-start on device boot)
- `termux-wake-lock` to keep service running

---

## Network Access

### Local Access
```
http://127.0.0.1:<port>/
```

### Network Access
```
http://0.0.0.0:<port>/
http://<device-ip>:<port>/
```

**Find your device IP**:
```bash
qs-url
# or
ifconfig wlan0 | grep "inet "
```

---

## Directory Structure

```
<project-root>/
├── assets/
│   └── error-pages/
│       ├── 403.html          # Forbidden error page
│       ├── 404.html          # Not Found error page
│       └── 500.html          # Internal Server Error page
├── bin/
│   └── quick-serve           # Production binary (3.7MB)
├── config/
│   └── production.env        # Production configuration
├── src/
│   └── servers/
│       └── http.rs           # Fixed HTTP server (directory handling)
├── Cargo.toml
└── DEPLOYMENT.md             # This file
```

---

## Configuration

**File**: `config/production.env`

```bash
QS_BIND_IP="0.0.0.0"              # or "127.0.0.1" for local only
QS_HTTP_PORT=<your-port>          # Choose non-standard port
QS_SERVE_DIR="<path-to-serve>"    # Directory to serve
QS_HEADLESS=true
QS_VERBOSE=true
```

**To modify**:
1. Edit `config/production.env`
2. Restart service: `sv restart quick-serve`

---

## Enterprise Features

### Custom Error Pages
- **403 Forbidden**: Professional styled page with purple gradient
- **404 Not Found**: Professional styled page with pink gradient
- **500 Internal Server Error**: Professional styled page with orange gradient

### Content-Type Detection
Supports 11+ file types:
- HTML, CSS, JavaScript, JSON
- PNG, JPG, GIF, SVG
- Plain text
- Binary files (octet-stream)

### Directory Handling
- Automatically serves `index.html` if present
- Returns 403 Forbidden for directories without index.html
- No crashes on directory access

---

## Build Process (V2 Pattern)

**Android noexec workaround** - builds in exec-allowed location:

```bash
cd <project-root>
export CARGO_TARGET_DIR=~/tmp/cargo-build
export TMPDIR=~/tmp
cargo build --release --no-default-features --bin quick-serve
```

**Deploy to production**:
```bash
rm bin/quick-serve
cp ~/tmp/cargo-build/release/quick-serve bin/quick-serve
sv restart quick-serve
```

---

## Troubleshooting

### Service won't start
```bash
sv status quick-serve          # Check status
sv restart quick-serve         # Force restart
cat $PREFIX/var/service/quick-serve/log/main/current  # Check logs
```

### Port already in use
```bash
# Check what's using the port
lsof -i :<port>
# or
netstat -tulpn | grep <port>
```

### Error pages not loading
```bash
# Ensure assets directory exists
ls assets/error-pages/
# Service must run from project root (configured in service script)
```

### Can't access from network
```bash
# Check firewall/network settings
# Verify bind IP is 0.0.0.0 in config
grep QS_BIND_IP config/production.env
```

---

## Security Notes

- **Port**: Use non-standard port (recommended: 30000-60000 range)
- **Bind**: 0.0.0.0 (network accessible) - restrict to 127.0.0.1 if local only
- **No authentication**: Files are publicly accessible by default
- **Directory listing**: Disabled (403 unless index.html present)

**To restrict access**:
Change `QS_BIND_IP` to `127.0.0.1` in `production.env`

---

## Maintenance

### Update binary
```bash
cd <project-root>
# Make code changes
export CARGO_TARGET_DIR=~/tmp/cargo-build
cargo build --release --no-default-features --bin quick-serve
rm bin/quick-serve
cp ~/tmp/cargo-build/release/quick-serve bin/quick-serve
sv restart quick-serve
```

### View service logs
```bash
qs-logs
# or
sv log quick-serve
```

### Check service health
```bash
sv status quick-serve
curl -I http://127.0.0.1:<port>/
```

---

## Integration

**Git repository**: https://github.com/hah23255/quick-serve-enterprise
**Upstream**: https://github.com/joaofl/quick-serve
**Bug report**: Issue #39 (directory crash fix submitted)

---

## Future Enhancements

- [ ] Add authentication (basic auth)
- [ ] Enable HTTPS/TLS
- [ ] Directory listing with styled HTML
- [ ] Rate limiting
- [ ] Access logs rotation
- [ ] Prometheus metrics endpoint
- [ ] Health check endpoint

---

**Last Updated**: 2025-10-19
**Maintained By**: Enterprise Termux Deployment Team
