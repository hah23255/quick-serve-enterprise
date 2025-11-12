#!/bin/bash
# Quick-Serve Enterprise - One-Command Installer
# Usage: curl -sSL https://raw.githubusercontent.com/hah23255/quick-serve-enterprise/main/install.sh | bash

set -e

echo "======================================"
echo "Quick-Serve Enterprise Installer"
echo "======================================"

# Detect platform
if [ -n "$PREFIX" ] && [ -d "$PREFIX" ]; then
    PLATFORM="termux"
    INSTALL_DIR="$PREFIX/bin"
    DATA_DIR="$HOME/storage/shared/quick-serve"
    PORT=50080
else
    PLATFORM="linux"
    INSTALL_DIR="$HOME/.local/bin"
    DATA_DIR="$HOME/quick-serve-data"
    PORT=50080
fi

echo "Platform: $PLATFORM"
echo "Port: $PORT (non-standard)"

# Install Rust if needed
if ! command -v cargo &> /dev/null; then
    echo "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
fi

# Clone or update repo
if [ -d "$HOME/quick-serve-enterprise" ]; then
    echo "Updating existing installation..."
    cd $HOME/quick-serve-enterprise
    git pull
else
    echo "Cloning repository..."
    git clone https://github.com/hah23255/quick-serve-enterprise.git $HOME/quick-serve-enterprise
    cd $HOME/quick-serve-enterprise
fi

# Build
echo "Building (takes 2-3 minutes)..."
cargo build --release --no-default-features --bin quick-serve

# Install
mkdir -p "$INSTALL_DIR"
mkdir -p "$DATA_DIR"
cp target/release/quick-serve "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/quick-serve"

# Add to PATH
if [ "$PLATFORM" = "termux" ]; then
    echo "export PATH=\"\$PREFIX/bin:\$PATH\"" >> $HOME/.bashrc
else
    if ! grep -q ".local/bin" $HOME/.bashrc; then
        echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> $HOME/.bashrc
    fi
fi

# Create start script
cat > $HOME/qs-start << EOF
#!/bin/bash
PORT=\${1:-$PORT}
DIR=\${2:-$DATA_DIR}
$INSTALL_DIR/quick-serve --headless --http=\$PORT --serve-dir=\$DIR --bind-ip=0.0.0.0 &
echo "Server started on port \$PORT"
echo "Access: http://\$(hostname -I | awk '{print \$1}'):\$PORT"
EOF
chmod +x $HOME/qs-start

# Create stop script
cat > $HOME/qs-stop << 'EOF'
#!/bin/bash
killall quick-serve 2>/dev/null && echo "Server stopped" || echo "Server not running"
EOF
chmod +x $HOME/qs-stop

# Create sync script
cat > $HOME/qs-sync << 'EOF'
#!/bin/bash
# Sync files between devices using rsync
REMOTE_IP=$1
REMOTE_PORT=${2:-50080}

if [ -z "$REMOTE_IP" ]; then
    echo "Usage: qs-sync <remote-ip> [port]"
    echo "Example: qs-sync 192.168.1.122"
    exit 1
fi

echo "Syncing with $REMOTE_IP..."
rsync -avz --progress ~/quick-serve-data/ $REMOTE_IP:~/quick-serve-data/
echo "Sync complete"
EOF
chmod +x $HOME/qs-sync

# Create index.html
cat > "$DATA_DIR/index.html" << 'HTMLEOF'
<!DOCTYPE html>
<html><head><meta charset="UTF-8"><title>Files</title>
<style>
body{font-family:Arial;padding:20px;background:#f5f5f5}
h1{color:#333}
ul{list-style:none;padding:0}
li{padding:15px;background:white;margin:10px 0;border-radius:8px;box-shadow:0 2px 4px rgba(0,0,0,0.1)}
a{text-decoration:none;color:#0066cc;font-size:18px;font-weight:500}
a:hover{text-decoration:underline}
.size{color:#666;margin-left:10px;font-size:14px}
</style></head><body>
<h1>Quick-Serve Enterprise</h1>
<p>Place files in the directory to share them</p>
<ul><li>Server is running</li></ul>
</body></html>
HTMLEOF

# Firewall (Linux only)
if [ "$PLATFORM" = "linux" ]; then
    if command -v ufw &> /dev/null; then
        echo "Opening firewall port $PORT..."
        sudo ufw allow $PORT/tcp 2>/dev/null || echo "Add firewall rule manually: sudo ufw allow $PORT/tcp"
    fi
fi

# Success message
echo ""
echo "======================================"
echo "✅ Installation Complete!"
echo "======================================"
echo ""
echo "Quick commands:"
echo "  Start:  ~/qs-start"
echo "  Stop:   ~/qs-stop"
echo "  Sync:   ~/qs-sync <remote-ip>"
echo ""
echo "Data directory: $DATA_DIR"
echo "Port: $PORT"
echo ""
echo "Start server now:"
echo "  ~/qs-start"
echo ""
