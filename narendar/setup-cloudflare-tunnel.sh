#!/bin/bash

# Cloudflare Tunnel Setup Script for narendar.com
# This script automates the setup of Cloudflare Tunnel

set -e

echo "========================================="
echo "Cloudflare Tunnel Setup for narendar.com"
echo "========================================="

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    echo "Please run as a regular user, not root"
    exit 1
fi

# Step 1: Install cloudflared
echo "[1/7] Installing cloudflared..."
if ! command -v cloudflared &> /dev/null; then
    wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
    sudo dpkg -i cloudflared-linux-amd64.deb
    rm cloudflared-linux-amd64.deb
    echo "✅ cloudflared installed"
else
    echo "✅ cloudflared already installed"
fi

cloudflared --version

# Step 2: Authenticate
echo ""
echo "[2/7] Authenticating with Cloudflare..."
echo "This will open a browser window. Please:"
echo "1. Log in to your Cloudflare account"
echo "2. Select narendar.com"
echo "3. Authorize the tunnel"
echo ""
read -p "Press Enter to continue with authentication..."
cloudflared tunnel login

# Step 3: Create tunnel
echo ""
echo "[3/7] Creating tunnel..."
TUNNEL_NAME="narendar-tunnel"
cloudflared tunnel create $TUNNEL_NAME

# Get tunnel ID
TUNNEL_ID=$(cloudflared tunnel list | grep $TUNNEL_NAME | awk '{print $2}')
echo "✅ Tunnel created with ID: $TUNNEL_ID"

# Step 4: Configure tunnel
echo ""
echo "[4/7] Configuring tunnel..."
mkdir -p ~/.cloudflared

cat > ~/.cloudflared/config.yml <<EOF
tunnel: $TUNNEL_ID
credentials-file: /home/narendar77/.cloudflared/$TUNNEL_ID.json

ingress:
  - hostname: narendar.com
    service: http://localhost:80
  - hostname: www.narendar.com
    service: http://localhost:80
  - service: http_status:404
EOF

echo "✅ Configuration file created"

# Step 5: Route DNS
echo ""
echo "[5/7] Routing DNS through tunnel..."
cloudflared tunnel route dns $TUNNEL_NAME narendar.com
cloudflared tunnel route dns $TUNNEL_NAME www.narendar.com
echo "✅ DNS routes configured"

# Step 6: Test tunnel
echo ""
echo "[6/7] Testing tunnel..."
echo "Starting tunnel in foreground for testing..."
echo "Press Ctrl+C to stop the test"
echo ""
read -p "Press Enter to start tunnel test..."
cloudflared tunnel run $TUNNEL_NAME

# Step 7: Install as service
echo ""
echo "[7/7] Installing tunnel as system service..."
sudo cloudflared service install
sudo systemctl start cloudflared
sudo systemctl enable cloudflared

echo ""
echo "========================================="
echo "Cloudflare Tunnel Setup Complete!"
echo "========================================="
echo ""
echo "Your website should now be accessible at:"
echo "  - http://narendar.com"
echo "  - http://www.narendar.com"
echo ""
echo "Management commands:"
echo "  sudo systemctl status cloudflared"
echo "  sudo systemctl restart cloudflared"
echo "  sudo journalctl -u cloudflared -f"
echo ""
echo "Note: You can now remove port forwarding from your router"
echo "      since the tunnel doesn't require it."
echo ""