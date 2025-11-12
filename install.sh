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
    DATA_DIR="$HOME/storage/shared/DropBasket"
    PORT=50080
else
    PLATFORM="linux"
    INSTALL_DIR="$HOME/.local/bin"
    DATA_DIR="$HOME/DropBasket"
    PORT=50080
fi

echo "Platform: $PLATFORM"
echo "Port: $PORT (non-standard)"
echo "Share folder: $DATA_DIR"

# Install Rust if needed
if ! command -v cargo &> /dev/null; then
    echo "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
fi

# Install jq if needed (for cargo metadata parsing)
if ! command -v jq &> /dev/null; then
    echo "Installing jq (for build detection)..."
    if [ "$PLATFORM" = "linux" ]; then
        if command -v apt-get &> /dev/null; then
            sudo apt-get install -y jq 2>/dev/null || echo "Warning: Could not install jq, using fallback"
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y jq 2>/dev/null || echo "Warning: Could not install jq, using fallback"
        fi
    else
        pkg install -y jq 2>/dev/null || echo "Warning: Could not install jq, using fallback"
    fi
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

# Detect actual target directory (handles custom .cargo/config.toml)
echo "Detecting build location..."
if command -v jq &> /dev/null; then
    TARGET_DIR=$(cargo metadata --format-version 1 2>/dev/null | jq -r '.target_directory' || echo "target")
else
    # Fallback: check .cargo/config.toml
    if [ -f ".cargo/config.toml" ]; then
        TARGET_DIR=$(grep "target-dir" .cargo/config.toml | sed 's/.*"\(.*\)".*/\1/' | head -1)
        if [ -z "$TARGET_DIR" ]; then
            TARGET_DIR="target"
        fi
    else
        TARGET_DIR="target"
    fi
fi

echo "Build location: $TARGET_DIR"

# Install
mkdir -p "$INSTALL_DIR"
mkdir -p "$DATA_DIR"
cp "$TARGET_DIR/release/quick-serve" "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/quick-serve"

# Add to PATH
if [ "$PLATFORM" = "termux" ]; then
    if ! grep -q "PREFIX/bin" $HOME/.bashrc 2>/dev/null; then
        echo "export PATH=\"\$PREFIX/bin:\$PATH\"" >> $HOME/.bashrc
    fi
else
    if ! grep -q ".local/bin" $HOME/.bashrc 2>/dev/null; then
        echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> $HOME/.bashrc
    fi
fi

# Create start script
cat > $HOME/qs-start << 'EOF'
#!/bin/bash
PORT=${1:-50080}
DIR=${2:-$HOME/DropBasket}
INSTALL_DIR=$HOME/.local/bin
$INSTALL_DIR/quick-serve --headless --http=$PORT --serve-dir=$DIR --bind-ip=0.0.0.0 &
echo "✅ DropBasket server started"
echo "Port: $PORT"
echo "Access: http://$(hostname -I | awk '{print $1}'):$PORT"
echo "Files: $DIR"
EOF
chmod +x $HOME/qs-start

# Create stop script
cat > $HOME/qs-stop << 'EOF'
#!/bin/bash
pkill quick-serve && echo "✅ Server stopped" || echo "Server not running"
EOF
chmod +x $HOME/qs-stop

# Create sync script
cat > $HOME/qs-sync << 'EOF'
#!/bin/bash
if [ -z "$1" ]; then
    echo "Usage: qs-sync <remote-ip>"
    echo "Example: qs-sync 192.168.1.120"
    exit 1
fi
echo "🔄 Syncing DropBasket with $1:50080..."
wget -r -np -nH --cut-dirs=0 -P $HOME/DropBasket http://$1:50080/ 2>&1 | grep -E "saved|failed"
echo "✅ Sync complete"
EOF
chmod +x $HOME/qs-sync

# Create desktop shortcuts (Linux only)
if [ "$PLATFORM" = "linux" ] && [ -d "$HOME/Desktop" ]; then
    echo "Creating desktop shortcuts..."

    # Shortcut 1: Start DropBasket Server
    cat > $HOME/Desktop/start-dropbasket.desktop << 'STARTEOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Start DropBasket
Comment=Start DropBasket file sharing server
Exec=bash -c '$HOME/qs-start; read -p "Press Enter to close..."'
Icon=media-playback-start
Terminal=true
Categories=Network;FileTransfer;
STARTEOF
    chmod +x $HOME/Desktop/start-dropbasket.desktop

    # Shortcut 2: Open DropBasket Folder
    cat > $HOME/Desktop/dropbasket-folder.desktop << 'FOLDEREOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=DropBasket Folder
Comment=Open DropBasket folder to drop files for sharing
Exec=xdg-open $HOME/DropBasket
Icon=folder-drag-accept
Terminal=false
Categories=Network;FileTransfer;Utility;
FOLDEREOF
    chmod +x $HOME/Desktop/dropbasket-folder.desktop

    # Install to applications menu
    mkdir -p $HOME/.local/share/applications
    cp $HOME/Desktop/start-dropbasket.desktop $HOME/.local/share/applications/
    cp $HOME/Desktop/dropbasket-folder.desktop $HOME/.local/share/applications/
fi

# Open firewall (Linux only)
if [ "$PLATFORM" = "linux" ]; then
    if command -v ufw &> /dev/null; then
        echo "Opening firewall port $PORT..."
        sudo ufw allow $PORT/tcp 2>/dev/null || echo "Firewall config skipped (manual setup may be needed)"
    fi
fi

# Create welcome page
cat > "$DATA_DIR/index.html" << 'HTMLEOF'
<!DOCTYPE html>
<html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>DropBasket</title>
<style>
body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Arial,sans-serif;
     padding:0;margin:0;background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);
     min-height:100vh}
.container{padding:20px;max-width:600px;margin:0 auto}
.card{background:white;border-radius:16px;padding:25px;box-shadow:0 10px 40px rgba(0,0,0,0.2);margin-bottom:20px}
h1{color:#667eea;font-size:28px;margin:0 0 5px 0}
h1:before{content:'🧺';margin-right:10px}
.subtitle{color:#666;margin-bottom:20px;font-size:14px}
.badge{background:#4CAF50;color:white;padding:8px 16px;border-radius:20px;
       display:inline-block;font-size:14px;margin-bottom:20px}
.info{background:#f5f5f5;padding:15px;border-radius:8px;margin:15px 0;font-size:14px}
.info strong{color:#667eea}
ul{list-style:none;padding:0;margin:15px 0}
li{padding:12px;background:#f9f9f9;margin:8px 0;border-radius:8px;
   border-left:4px solid #667eea;font-size:14px}
.footer{text-align:center;color:rgba(255,255,255,0.8);padding:20px;font-size:12px}
</style></head><body>
<div class="container">
  <div class="card">
    <h1>DropBasket</h1>
    <div class="subtitle">Enterprise File Sharing</div>
    <div class="badge">🖥️ Linux Server Active</div>
    <div class="info">
      <strong>📁 Share:</strong> ~/DropBasket/<br>
      <strong>🌐 Access:</strong> From any WiFi device<br>
      <strong>🔒 Secure:</strong> Local network only
    </div>
    <ul>
      <li>Drop files in ~/DropBasket/ to share</li>
      <li>Use qs-start/qs-stop to control server</li>
    </ul>
  </div>
</div>
<div class="footer">Quick-Serve Enterprise • Linux Edition</div>
</body></html>
HTMLEOF

echo ""
echo "======================================"
echo "✅ Installation Complete!"
echo "======================================"
echo ""
echo "📁 DropBasket: $DATA_DIR"
echo "🌐 Port: $PORT"
echo ""
echo "Commands:"
echo "  🚀 qs-start     - Start server"
echo "  ⏹️  qs-stop      - Stop server"
echo "  🔄 qs-sync IP   - Sync with device"
echo ""
if [ "$PLATFORM" = "linux" ] && [ -d "$HOME/Desktop" ]; then
    echo "🖥️  Desktop shortcuts created!"
    echo "   • Start DropBasket - Launch the server"
    echo "   • DropBasket Folder - Open folder to drop files"
    echo ""
fi
echo "🚀 Start now: qs-start"
echo "   Then visit: http://$(hostname -I | awk '{print $1}'):$PORT"
echo ""
