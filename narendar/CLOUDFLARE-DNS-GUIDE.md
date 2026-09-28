# Cloudflare DNS to Home Network Setup Guide

Complete step-by-step guide to point narendar.com to your homelab (192.168.4.121)

## Prerequisites

- Domain name (narendar.com) registered and added to Cloudflare
- Access to your home router's admin panel
- Cloudflare account (free tier works)

---

## Step 1: Find Your Public IP Address

Your home network has a private IP (192.168.4.121), but Cloudflare needs your **public IP**.

### On your Mac:
```bash
curl ifconfig.me
# or
curl ipinfo.io/ip
```

Save this IP address - you'll need it for Cloudflare.

**Note:** Home public IPs change periodically (dynamic IP). We'll address this in Step 5.

---

## Step 2: Configure Cloudflare DNS

1. **Log in to Cloudflare Dashboard**
   - Go to https://dash.cloudflare.com
   - Select your domain (narendar.com)

2. **Add DNS Record**
   - Go to **DNS** → **Records**
   - Click **Add Record**
   - Configure as follows:
     - **Type:** A
     - **Name:** `@` (for root domain) or `www` (for www.narendar.com)
     - **IPv4 address:** Your public IP from Step 1
     - **Proxy status:** Orange cloud (Proxied) OR Gray cloud (DNS only)
     - **TTL:** Auto

3. **Create both records** (recommended):
   - Record 1: `@` → Your public IP (for narendar.com)
   - Record 2: `www` → Your public IP (for www.narendar.com)

4. **Save the records**

---

## Step 3: Configure Router Port Forwarding

Your router needs to forward external traffic to your VM (192.168.4.121).

### Access Your Router:
1. Find your router's gateway IP:
   ```bash
   netstat -nr | grep default
   # or
   route -n get default
   ```

2. Open web browser and go to the gateway IP (usually 192.168.1.1 or 192.168.0.1)

3. Log in with router credentials

### Set Up Port Forwarding:
1. Look for **Port Forwarding**, **NAT**, or **Virtual Server** settings
2. Add a new rule:
   - **External Port:** 80 (HTTP)
   - **Internal Port:** 80
   - **Internal IP:** 192.168.4.121 (your VM)
   - **Protocol:** TCP
   - **Enable:** Yes

3. **Save and apply changes**

### Optional: Forward Port 443 (for HTTPS)
- **External Port:** 443
- **Internal Port:** 443
- **Internal IP:** 192.168.4.121
- **Protocol:** TCP

---

## Step 4: Configure Firewall on VM

Ensure your VM's firewall allows incoming HTTP traffic.

### On Ubuntu VM:
```bash
# Check if UFW is installed
sudo ufw status

# Allow HTTP traffic
sudo ufw allow 80/tcp

# Allow HTTPS if you set it up
sudo ufw allow 443/tcp

# Enable firewall if not already enabled
sudo ufw enable
```

### Test locally:
```bash
# From VM itself
curl http://localhost

# From another device on your network
curl http://192.168.4.121
```

---

## Step 5: Handle Dynamic IP (Critical for Home Networks)

Home public IPs change, so you need Dynamic DNS. Here are two approaches:

### Option A: Cloudflare Dynamic DNS (DDNS) Script

1. **Get Cloudflare API Token:**
   - Go to Cloudflare Dashboard → My Profile → API Tokens
   - Create token with permissions:
     - Zone - DNS - Edit
     - Zone - Zone - Read
   - Save the token

2. **Install DDNS script on VM:**
   ```bash
   # Install dependencies
   sudo apt update
   sudo apt install -y curl jq

   # Create DDNS script
   nano ~/update-cloudflare-ddns.sh
   ```

3. **Add this script content:**
   ```bash
   #!/bin/bash

   # Configuration
   CF_API_TOKEN="your_api_token_here"
   CF_ZONE_ID="your_zone_id_here"
   CF_RECORD_ID="your_record_id_here"
   CF_RECORD_NAME="narendar.com"

   # Get current public IP
   CURRENT_IP=$(curl -s https://api.ipify.org)

   # Update Cloudflare DNS
   curl -X PUT "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records/$CF_RECORD_ID" \
     -H "Authorization: Bearer $CF_API_TOKEN" \
     -H "Content-Type: application/json" \
     --data "{\"type\":\"A\",\"name\":\"$CF_RECORD_NAME\",\"content\":\"$CURRENT_IP\",\"ttl\":1,\"proxied\":true}"

   echo "Updated DNS to $CURRENT_IP"
   ```

4. **Get your Zone ID and Record ID:**
   ```bash
   # List zones to get Zone ID
   curl -X GET "https://api.cloudflare.com/client/v4/zones" \
     -H "Authorization: Bearer $CF_API_TOKEN" \
     -H "Content-Type: application/json"

   # List DNS records to get Record ID
   curl -X GET "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records" \
     -H "Authorization: Bearer $CF_API_TOKEN" \
     -H "Content-Type: application/json"
   ```

5. **Set up cron job to run automatically:**
   ```bash
   # Make script executable
   chmod +x ~/update-cloudflare-ddns.sh

   # Add to cron (runs every 5 minutes)
   (crontab -l 2>/dev/null; echo "*/5 * * * * ~/update-cloudflare-ddns.sh") | crontab -
   ```

### Option B: Use DDNS Service (Easier)

1. **Use DuckDNS (free):**
   - Sign up at https://www.duckdns.org
   - Create a subdomain (e.g., narendar.duckdns.org)
   - Install their update script on your VM
   - Point Cloudflare CNAME to your DuckDNS subdomain

2. **Or use Cloudflare Tunnel (Recommended):**
   - More secure, no port forwarding needed
   - See separate guide below

---

## Step 6: Test the Setup

1. **Wait for DNS propagation** (5-15 minutes)

2. **Test from your Mac:**
   ```bash
   # Check DNS resolution
   nslookup narendar.com
   # or
   dig narendar.com

   # Test HTTP access
   curl http://narendar.com
   ```

3. **Test in browser:**
   - Open http://narendar.com in your browser
   - You should see your scrolling image gallery

---

## Step 7: Set Up HTTPS (Recommended)

### Option A: Cloudflare SSL (Easy)

1. In Cloudflare Dashboard:
   - Go to **SSL/TLS** → **Overview**
   - Set mode to **Flexible** (easiest) or **Full** (if you have SSL on VM)

2. Enable **Always Use HTTPS**
   - Go to **SSL/TLS** → **Edge Certificates**
   - Turn on **Always Use HTTPS**

3. Your site will now be accessible at https://narendar.com

### Option B: Let's Encrypt on VM (More Control)

1. **Install Certbot on VM:**
   ```bash
   sudo apt update
   sudo apt install -y certbot python3-certbot-nginx
   ```

2. **Obtain SSL certificate:**
   ```bash
   sudo certbot --nginx -d narendar.com -d www.narendar.com
   ```

3. **Set up auto-renewal:**
   ```bash
   sudo certbot renew --dry-run
   ```

---

## Alternative: Cloudflare Tunnel (No Port Forwarding)

If you want to avoid port forwarding entirely, use Cloudflare Tunnel:

### Prerequisites:
- Cloudflare account
- `cloudflared` installed on VM

### Setup Steps:

1. **Install cloudflared on VM:**
   ```bash
   # Add Cloudflare GPG key
   wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
   sudo dpkg -i cloudflared-linux-amd64.deb
   ```

2. **Authenticate:**
   ```bash
   cloudflared tunnel login
   ```

3. **Create tunnel:**
   ```bash
   cloudflared tunnel create narendar-tunnel
   ```

4. **Configure tunnel:**
   ```bash
   # Create config file
   nano ~/.cloudflared/config.yml
   ```

   Add this content:
   ```yaml
   tunnel: <your-tunnel-id>
   credentials-file: /home/narendar77/.cloudflared/<your-tunnel-id>.json

   ingress:
     - hostname: narendar.com
       service: http://localhost:80
     - hostname: www.narendar.com
       service: http://localhost:80
     - service: http_status:404
   ```

5. **Route DNS:**
   ```bash
   cloudflared tunnel route dns narendar-tunnel narendar.com
   cloudflared tunnel route dns narendar-tunnel www.narendar.com
   ```

6. **Run as service:**
   ```bash
   sudo cloudflared service install
   sudo systemctl start cloudflared
   sudo systemctl enable cloudflared
   ```

---

## Security Considerations

1. **Use Cloudflare Proxy (Orange Cloud):**
   - Hides your real IP
   - Provides DDoS protection
   - Offers free SSL

2. **Limit Access:**
   - Consider using Cloudflare Access for additional authentication
   - Set up firewall rules to restrict by country if needed

3. **Keep Software Updated:**
   - Regularly update your VM and Docker containers
   - Monitor for security vulnerabilities

4. **Monitor Logs:**
   ```bash
   # Check Docker logs
   docker logs -f narendar-website

   # Check Cloudflare analytics in dashboard
   ```

---

## Troubleshooting

### Site not loading:
1. Check if container is running: `docker ps`
2. Check port forwarding on router
3. Check firewall on VM: `sudo ufw status`
4. Verify Cloudflare DNS records
5. Check if public IP changed

### DNS not resolving:
1. Wait for propagation (up to 24 hours)
2. Check Cloudflare DNS status
3. Verify your domain's nameservers point to Cloudflare

### Port forwarding not working:
1. Verify router settings
2. Check if ISP blocks port 80 (some do)
3. Try different external port (e.g., 8080)

---

## Quick Reference Commands

```bash
# Check current public IP
curl ifconfig.me

# Test DNS resolution
nslookup narendar.com
dig narendar.com

# Test HTTP access
curl -v http://narendar.com

# Check Docker container
docker ps
docker logs narendar-website

# Restart container
docker restart narendar-website

# Check firewall
sudo ufw status
```

---

## Summary

1. ✅ Get your public IP
2. ✅ Configure Cloudflare DNS A records
3. ✅ Set up router port forwarding (80 → 192.168.4.121)
4. ✅ Configure VM firewall
5. ✅ Set up Dynamic DNS for IP changes
6. ✅ Test the setup
7. ✅ Enable HTTPS with Cloudflare SSL

Your narendar.com will then be accessible from anywhere in the world!