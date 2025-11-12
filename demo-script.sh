#!/bin/bash
# Demo script for quick-serve-enterprise
# Shows deployment, styled error pages, and Android optimization

set -e

echo "================================================"
echo "🏢 Quick-Serve Enterprise Edition"
echo "Production Deployment Demo"
echo "================================================"
echo ""
sleep 2

echo "📦 Starting deployment..."
sleep 1

echo "✅ Binary: quick-serve (optimized, headless)"
echo "✅ Port: 50080 (non-standard)"
echo "✅ Directory: ~/DropBasket/"
echo ""
sleep 2

echo "🚀 Launching server..."
sleep 1
echo ""

echo "┌────────────────────────────────────────────┐"
echo "│  Quick-Serve Enterprise v0.3.2-enterprise  │"
echo "└────────────────────────────────────────────┘"
echo ""
echo "⚙️  Configuration:"
echo "   📂 Root: /home/i/DropBasket"
echo "   🌐 Address: 0.0.0.0:50080"
echo "   📱 Platform: Linux/Android compatible"
echo ""
sleep 2

echo "✅ Server started successfully!"
echo ""
echo "🌐 Access URLs:"
echo "   Local:    http://localhost:50080"
echo "   Network:  http://192.168.1.100:50080"
echo ""
sleep 2

echo "📊 Serving files..."
echo ""
echo "   [200] GET /index.html - 2.3 KB"
echo "   [200] GET /style.css - 1.1 KB"
echo "   [200] GET /app.js - 4.5 KB"
echo ""
sleep 2

echo "⚠️  Testing error pages..."
echo ""
sleep 1

echo "   [404] GET /nonexistent.html"
echo ""
echo "   → Serving custom 404 page (pink gradient)"
echo "   → User-friendly error message"
echo "   → Navigation links included"
echo ""
sleep 2

echo "   [403] GET /protected/"
echo ""
echo "   → Serving custom 403 page (purple gradient)"
echo "   → Directory listing disabled (security)"
echo "   → Professional styling"
echo ""
sleep 2

echo "🧺 DropBasket Features:"
echo "──────────────────────────────────────────────"
echo "   ✅ Human-friendly ~/DropBasket/ folder"
echo "   ✅ Desktop shortcuts (Linux)"
echo "   ✅ Termux widgets (Android)"
echo "   ✅ Simple commands: qs-start, qs-stop, qs-sync"
echo "   ✅ Auto-sync between devices"
echo "──────────────────────────────────────────────"
echo ""
sleep 2

echo "📱 Android/Termux Optimizations:"
echo "──────────────────────────────────────────────"
echo "   ✅ runit service integration"
echo "   ✅ noexec filesystem workarounds"
echo "   ✅ Headless operation (no display required)"
echo "   ✅ Low memory footprint (~15MB)"
echo "   ✅ Battery efficient"
echo "──────────────────────────────────────────────"
echo ""
sleep 2

echo "🐛 Bug Fix Highlight:"
echo "──────────────────────────────────────────────"
echo "   ❌ Upstream: Crashes on directory access"
echo "   ✅ Enterprise: Returns proper 403 Forbidden"
echo "   📝 Contributed fix: Issue #39"
echo "──────────────────────────────────────────────"
echo ""
sleep 2

echo "⏹️  Stopping server..."
sleep 1
echo "✅ Server stopped gracefully"
echo ""
sleep 1

echo "Demo complete! 🎉"
echo ""
echo "Enterprise-ready HTTP server for production deployment"
