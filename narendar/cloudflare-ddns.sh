#!/bin/bash

# Cloudflare Dynamic DNS Update Script
# This script automatically updates your Cloudflare DNS when your public IP changes

set -e

echo "========================================="
echo "Cloudflare DDNS Setup Helper"
echo "========================================="

# Check if curl and jq are installed
if ! command -v curl &> /dev/null; then
    echo "Installing curl..."
    sudo apt update
    sudo apt install -y curl
fi

if ! command -v jq &> /dev/null; then
    echo "Installing jq..."
    sudo apt update
    sudo apt install -y jq
fi

echo ""
echo "Step 1: Get your Cloudflare API Token"
echo "-------------------------------------"
echo "1. Go to https://dash.cloudflare.com/profile/api-tokens"
echo "2. Click 'Create Token'"
echo "3. Use template 'Edit zone DNS'"
echo "4. Configure permissions:"
echo "   - Zone - DNS - Edit"
echo "   - Zone - Zone - Read"
echo "5. Set 'Zone Resources' to include your domain (narendar.com)"
echo "6. Create token and copy it"
echo ""

read -p "Enter your Cloudflare API Token: " CF_API_TOKEN

echo ""
echo "Step 2: Get your Zone ID"
echo "------------------------"
ZONE_RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones" \
    -H "Authorization: Bearer $CF_API_TOKEN" \
    -H "Content-Type: application/json")

echo "Your zones:"
echo "$ZONE_RESPONSE" | jq -r '.result[] | "\(.name): \(.id)"'

read -p "Enter your Zone ID for narendar.com: " CF_ZONE_ID

echo ""
echo "Step 3: Get your DNS Record ID"
echo "------------------------------"
DNS_RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records" \
    -H "Authorization: Bearer $CF_API_TOKEN" \
    -H "Content-Type: application/json")

echo "Your DNS records:"
echo "$DNS_RESPONSE" | jq -r '.result[] | "\(.name) (\(.type)): \(.id)"'

read -p "Enter your Record ID for narendar.com: " CF_RECORD_ID

read -p "Enter your record name (e.g., narendar.com or www.narendar.com): " CF_RECORD_NAME

echo ""
echo "Step 4: Create DDNS update script"
echo "----------------------------------"

cat > ~/update-cloudflare-dns.sh <<EOF
#!/bin/bash

CF_API_TOKEN="$CF_API_TOKEN"
CF_ZONE_ID="$CF_ZONE_ID"
CF_RECORD_ID="$CF_RECORD_ID"
CF_RECORD_NAME="$CF_RECORD_NAME"

# Get current public IP
CURRENT_IP=\$(curl -s https://api.ipify.org)

echo "Current public IP: \$CURRENT_IP"

# Update Cloudflare DNS
RESPONSE=\$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/\$CF_ZONE_ID/dns_records/\$CF_RECORD_ID" \
    -H "Authorization: Bearer \$CF_API_TOKEN" \
    -H "Content-Type: application/json" \
    --data "{\"type\":\"A\",\"name\":\"\$CF_RECORD_NAME\",\"content\":\"\$CURRENT_IP\",\"ttl\":1,\"proxied\":true}")

echo "DNS update response:"
echo "\$RESPONSE" | jq .

if echo "\$RESPONSE" | jq -e '.success' > /dev/null; then
    echo "✅ DNS updated successfully to \$CURRENT_IP"
else
    echo "❌ DNS update failed"
    exit 1
fi
EOF

chmod +x ~/update-cloudflare-dns.sh

echo ""
echo "Step 5: Test the DDNS script"
echo "----------------------------"
~/update-cloudflare-dns.sh

echo ""
echo "Step 6: Set up automatic updates (cron)"
echo "----------------------------------------"
read -p "Add to cron to run every 5 minutes? (y/n): " ADD_CRON

if [ "$ADD_CRON" = "y" ]; then
    (crontab -l 2>/dev/null; echo "*/5 * * * * ~/update-cloudflare-dns.sh >> ~/cloudflare-ddns.log 2>&1") | crontab -
    echo "✅ Added to cron. Logs will be saved to ~/cloudflare-ddns.log"
fi

echo ""
echo "========================================="
echo "Setup Complete!"
echo "========================================="
echo ""
echo "Your DDNS script is ready at: ~/update-cloudflare-dns.sh"
echo ""
echo "To manually update DNS:"
echo "  ~/update-cloudflare-dns.sh"
echo ""
echo "To view logs:"
echo "  tail -f ~/cloudflare-ddns.log"
echo ""
echo "To edit cron:"
echo "  crontab -e"
echo ""