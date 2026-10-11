# Cloudflare Tunnel Setup Guide for narendar.com

Complete guide to set up Cloudflare Tunnel (cloudflared) to expose your Docker container to the internet without port forwarding.

## Why Cloudflare Tunnel?

- ✅ No port forwarding required
- ✅ No ISP blocking issues
- ✅ More secure (outbound connection only)
- ✅ Works behind any NAT/firewall
- ✅ Free with Cloudflare account
- ✅ Automatic SSL/HTTPS

---

## Prerequisites

- Cloudflare account with narendar.com configured
- SSH access to VM (192.168.4.121)
- Docker container running on port 80

---

## Step 1: Install cloudflared on VM

SSH into your VM and run:

```bash
# Download cloudflared
wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb

# Install it
sudo dpkg -i cloudflared-linux-amd64.deb

# Verify installation
cloudflared --version
```

---

## Step 2: Authenticate with Cloudflare

```bash
# This will open a browser window to authenticate
cloudflared tunnel login
```

1. A browser window will open (or give you a URL)
2. Log in to your Cloudflare account
3. Select your domain (narendar.com)
4. Authorize the tunnel

---

## Step 3: Create the Tunnel

```bash
# Create a tunnel named narendar-tunnel
cloudflared tunnel create narendar-tunnel
```

This will output:
- Tunnel ID (save this!)
- Credentials file location

**Save the Tunnel ID** - you'll need it for configuration.

---

## Step 4: Configure the Tunnel

Create the configuration file:

```bash
# Create config directory
mkdir -p ~/.cloudflared

# Create config file
nano ~/.cloudflared/config.yml
```

Add this configuration:

```yaml
tunnel: <YOUR_TUNNEL_ID>
credentials-file: /home/narendar77/.cloudflared/<YOUR_TUNNEL_ID>.json

ingress:
  - hostname: narendar.com
    service: http://localhost:80
  - hostname: www.narendar.com
    service: http://localhost:80
  - service: http_status:404
```

Replace `<YOUR_TUNNEL_ID>` with the actual tunnel ID from Step 3.

---

## Step 5: Route DNS through Cloudflare

```bash
# Route narendar.com through the tunnel
cloudflared tunnel route dns narendar-tunnel narendar.com

# Route www.narendar.com through the tunnel
cloudflared tunnel route dns narendar-tunnel www.narendar.com
```

This will automatically update your Cloudflare DNS records to point to the tunnel.

---

## Step 6: Test the Tunnel

Run the tunnel in the foreground to test:

```bash
cloudflared tunnel run narendar-tunnel
```

Keep this running and try accessing:
- http://narendar.com
- http://www.narendar.com

If it works, press Ctrl+C to stop it and proceed to Step 7.

---

## Step 7: Run as a System Service

To make the tunnel run automatically in the background:

```bash
# Install as a service
sudo cloudflared service install

# Start the service
sudo systemctl start cloudflared

# Enable it to start on boot
sudo systemctl enable cloudflared

# Check status
sudo systemctl status cloudflared
```

---

## Step 8: Cleanup Old DNS Records

Since the tunnel now handles DNS, you can clean up:

1. Go to Cloudflare Dashboard → DNS → Records
2. Delete the old A record for narendar.com (if it still exists)
3. Keep the CNAME for www.narendar.com (it will now point to the tunnel)
4. Keep the tunnel records (they should be CNAMEs to your tunnel)

---

## Step 9: Enable HTTPS (Optional but Recommended)

Cloudflare Tunnel automatically handles SSL, but ensure:

1. Go to Cloudflare Dashboard → SSL/TLS → Overview
2. Set mode to **Full** or **Full (strict)**
3. Enable **Always Use HTTPS**

Your site will now be accessible at:
- https://narendar.com
- https://www.narendar.com

---

## Management Commands

```bash
# Check tunnel status
sudo systemctl status cloudflared

# View tunnel logs
sudo journalctl -u cloudflared -f

# Restart tunnel
sudo systemctl restart cloudflared

# Stop tunnel
sudo systemctl stop cloudflared

# Update cloudflared
sudo apt update
sudo apt install cloudflared
```

---

## Troubleshooting

### Tunnel won't start:
```bash
# Check logs
sudo journalctl -u cloudflared -n 50

# Verify config file
cat ~/.cloudflared/config.yml

# Test tunnel manually
cloudflared tunnel run narendar-tunnel
```

### DNS not updating:
```bash
# Manually update DNS routes
cloudflared tunnel route dns narendar-tunnel narendar.com
cloudflared tunnel route dns narendar-tunnel www.narendar.com
```

### Container not accessible:
```bash
# Check if Docker container is running
docker ps

# Check if container is listening on port 80
netstat -tlnp | grep :80

# Test local access
curl http://localhost
```

### Permission issues:
```bash
# Fix config file permissions
chmod 644 ~/.cloudflared/config.yml
chmod 600 ~/.cloudflared/*.json
```

---

## Multiple Docker Containers

If you want to host multiple sites/containers, update the config:

```yaml
tunnel: <YOUR_TUNNEL_ID>
credentials-file: /home/narendar77/.cloudflared/<YOUR_TUNNEL_ID>.json

ingress:
  - hostname: narendar.com
    service: http://localhost:80
  - hostname: app.narendar.com
    service: http://localhost:8080
  - hostname: api.narendar.com
    service: http://localhost:3000
  - service: http_status:404
```

Make sure your Docker containers are running on the specified ports.

---

## Security Best Practices

1. **Keep cloudflared updated**:
   ```bash
   sudo apt update && sudo apt install cloudflared
   ```

2. **Use Cloudflare Access** for additional authentication:
   - Go to Cloudflare Dashboard → Zero Trust → Access
   - Add authentication rules for sensitive endpoints

3. **Monitor tunnel logs**:
   ```bash
   sudo journalctl -u cloudflared -f
   ```

4. **Regular backup of config**:
   ```bash
   cp ~/.cloudflared/config.yml ~/.cloudflared/config.yml.backup
   ```

---

## Summary

With Cloudflare Tunnel:
- ✅ No port forwarding needed
- ✅ No ISP blocking issues
- ✅ Automatic SSL/HTTPS
- ✅ DDoS protection
- ✅ Works from anywhere
- ✅ Automatic failover

Your narendar.com website is now accessible worldwide without any router configuration!