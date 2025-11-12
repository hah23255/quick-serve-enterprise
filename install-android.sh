#!/data/data/com.termux/files/usr/bin/bash
# Quick-Serve Enterprise - Termux Installer
# Usage in Termux: curl -sSL https://raw.githubusercontent.com/hah23255/quick-serve-enterprise/main/install-android.sh | bash

set -e

echo "======================================"
echo "Quick-Serve Enterprise"
echo "Termux on Android Installer"
echo "======================================"

# Update packages
pkg update -y

# Install dependencies
pkg install -y rust git rsync

# Setup storage access
if [ ! -d "$HOME/storage" ]; then
    echo "Setting up storage access..."
    termux-setup-storage
    sleep 2
fi

# Clone repo
if [ -d "$HOME/quick-serve-enterprise" ]; then
    cd $HOME/quick-serve-enterprise
    git pull
else
    git clone https://github.com/hah23255/quick-serve-enterprise.git $HOME/quick-serve-enterprise
    cd $HOME/quick-serve-enterprise
fi

# Build
echo "Building (takes 3-5 minutes on mobile)..."
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
cp "$TARGET_DIR/release/quick-serve" $PREFIX/bin/
chmod +x $PREFIX/bin/quick-serve

# Create data directory
mkdir -p $HOME/storage/shared/DropBasket

# Create start script
cat > $PREFIX/bin/qs-start << 'STARTEOF'
#!/data/data/com.termux/files/usr/bin/bash
PORT=${1:-50080}
DIR=${2:-$HOME/storage/shared/DropBasket}
quick-serve --headless --http=$PORT --serve-dir=$DIR --bind-ip=0.0.0.0 &
IP=$(ip -4 addr show wlan0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
echo "✅ DropBasket server started"
echo "📁 Folder: $DIR"
echo "🌐 Port: $PORT"
echo "📱 Access: http://$IP:$PORT"
termux-notification --title "DropBasket Started" --content "Server running on port $PORT"
STARTEOF
chmod +x $PREFIX/bin/qs-start

# Create stop script
cat > $PREFIX/bin/qs-stop << 'STOPEOF'
#!/data/data/com.termux/files/usr/bin/bash
pkill quick-serve && echo "✅ Server stopped" || echo "Server not running"
termux-notification --title "DropBasket Stopped" --content "Server stopped"
STOPEOF
chmod +x $PREFIX/bin/qs-stop

# Create sync script
cat > $PREFIX/bin/qs-sync << 'SYNCEOF'
#!/data/data/com.termux/files/usr/bin/bash
if [ -z "$1" ]; then
    echo "Usage: qs-sync <remote-ip>"
    echo "Example: qs-sync 192.168.1.120"
    exit 1
fi
echo "🔄 Syncing DropBasket with $1..."
rsync -avz --progress $HOME/storage/shared/DropBasket/ $1:~/DropBasket/
echo "✅ Sync complete"
termux-notification --title "DropBasket Sync" --content "Synced with $1"
SYNCEOF
chmod +x $PREFIX/bin/qs-sync

# Create widget script for Termux:Widget
mkdir -p $HOME/.shortcuts
cat > $HOME/.shortcuts/DropBasket-Start << 'WIDGETEOF'
#!/data/data/com.termux/files/usr/bin/bash
qs-start
WIDGETEOF
chmod +x $HOME/.shortcuts/DropBasket-Start

cat > $HOME/.shortcuts/DropBasket-Stop << 'WIDGETEOF'
#!/data/data/com.termux/files/usr/bin/bash
qs-stop
WIDGETEOF
chmod +x $HOME/.shortcuts/DropBasket-Stop

# Create boot script
mkdir -p ~/.config/termux/boot
cat > ~/.config/termux/boot/dropbasket << 'BOOTEOF'
#!/data/data/com.termux/files/usr/bin/bash
sleep 10
qs-start
BOOTEOF
chmod +x ~/.config/termux/boot/dropbasket

# Create index page
cat > $HOME/storage/shared/DropBasket/index.html << 'HTMLEOF'
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
    <div class="subtitle">Termux File Sharing</div>
    <div class="badge">📱 Android Server Active</div>
    <div class="info">
      <strong>📁 Share:</strong> storage/shared/DropBasket/<br>
      <strong>🌐 Access:</strong> From any WiFi device<br>
      <strong>🔒 Secure:</strong> Local network only
    </div>
    <ul>
      <li>Drop files in DropBasket to share</li>
      <li>Use Termux Widget for quick start/stop</li>
    </ul>
  </div>
</div>
<div class="footer">Quick-Serve Enterprise • Termux Edition</div>
</body></html>
HTMLEOF

echo ""
echo "======================================"
echo "✅ Termux Installation Complete!"
echo "======================================"
echo ""
echo "📁 DropBasket: ~/storage/shared/DropBasket/"
echo "🌐 Port: 50080"
echo ""
echo "Commands:"
echo "  🚀 qs-start     - Start server"
echo "  ⏹️  qs-stop      - Stop server"
echo "  🔄 qs-sync IP   - Sync with device"
echo ""
echo "📱 Widgets: Install 'Termux:Widget' app"
echo "   Then add DropBasket shortcuts to home screen"
echo ""
echo "🚀 Start now: qs-start"
echo ""
