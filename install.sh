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
echo "✅ DropBasket server started"
echo "Port: \$PORT"
echo "Access: http://\$(hostname -I | awk '{print \$1}'):\$PORT"
echo "Files: \$DIR"
