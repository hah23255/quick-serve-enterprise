#!/data/data/com.termux/files/usr/bin/bash
# Quick-Serve Enterprise - Android/Termux Installer
# Usage in Termux: curl -sSL https://raw.githubusercontent.com/hah23255/quick-serve-enterprise/main/install-android.sh | bash

set -e

echo "======================================"
echo "Quick-Serve Enterprise"
echo "Android/Termux Installer"
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

# Install
cp target/release/quick-serve $PREFIX/bin/
chmod +x $PREFIX/bin/quick-serve

# Create data directory
mkdir -p $HOME/storage/shared/quick-serve

# Create start script
cat > $PREFIX/bin/qs-start << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
PORT=${1:-50080}
DIR=${2:-$HOME/storage/shared/quick-serve}
quick-serve --headless --http=$PORT --serve-dir=$DIR --bind-ip=0.0.0.0 &
IP=$(ip -4 addr show wlan0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
echo "✅ Server started"
echo "Port: $PORT"
echo "Access: http://$IP:$PORT"
EOF
chmod +x $PREFIX/bin/qs-start

# Create stop script
cat > $PREFIX/bin/qs-stop << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
pkill quick-serve && echo "✅ Server stopped" || echo "Server not running"
EOF
chmod +x $PREFIX/bin/qs-stop

# Create sync script
cat > $PREFIX/bin/qs-sync << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
if [ -z "$1" ]; then
    echo "Usage: qs-sync <remote-ip>"
    echo "Example: qs-sync 192.168.1.120"
    exit 1
fi
echo "Syncing with $1..."
rsync -avz --progress $HOME/storage/shared/quick-serve/ $1:~/quick-serve-data/
echo "✅ Sync complete"
EOF
chmod +x $PREFIX/bin/qs-sync

# Create auto-sync service
mkdir -p ~/.config/termux
cat > ~/.config/termux/boot/qs-server << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
sleep 10
qs-start
EOF
chmod +x ~/.config/termux/boot/qs-server

# Create index page
cat > $HOME/storage/shared/quick-serve/index.html << 'HTMLEOF'
<!DOCTYPE html>
<html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Quick-Serve</title>
<style>
body{font-family:Arial;padding:20px;background:#f5f5f5;margin:0}
h1{color:#333;font-size:24px}
p{color:#666;font-size:16px}
ul{list-style:none;padding:0}
li{padding:15px;background:white;margin:10px 0;border-radius:8px;box-shadow:0 2px 4px rgba(0,0,0,0.1)}
a{text-decoration:none;color:#0066cc;font-size:18px;font-weight:500;display:block}
.status{background:#4CAF50;color:white;padding:10px;border-radius:8px;text-align:center;margin-bottom:20px}
</style></head><body>
<div class="status">✅ Android Server Running</div>
<h1>Quick-Serve Enterprise</h1>
<p>Share files from your Android device</p>
<ul><li>Place files in: storage/shared/quick-serve/</li></ul>
</body></html>
HTMLEOF

echo ""
echo "======================================"
echo "✅ Android Installation Complete!"
echo "======================================"
echo ""
echo "Commands:"
echo "  qs-start     - Start server"
echo "  qs-stop      - Stop server"
echo "  qs-sync IP   - Sync with another device"
echo ""
echo "Files: ~/storage/shared/quick-serve/"
echo "Port: 50080"
echo ""
echo "Start now: qs-start"
echo ""
