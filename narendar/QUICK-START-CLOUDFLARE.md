# Quick Start: Cloudflare DNS for narendar.com

## Step-by-Step Summary

### 1. Get Your Public IP (on Mac)
```bash
curl ifconfig.me
```
Save this IP address.

### 2. Configure Cloudflare DNS
1. Go to https://dash.cloudflare.com
2. Select narendar.com
3. Go to DNS → Records
4. Add A record:
   - Type: A
   - Name: @ (for narendar.com)
   - IPv4: Your public IP from step 1
   - Proxy: Orange cloud (Proxied)
5. Add another A record for www:
   - Name: www
   - IPv4: Your public IP
   - Proxy: Orange cloud

### 3. Router Port Forwarding
1. Access your router (usually 192.168.1.1 or 192.168.0.1)
2. Find Port Forwarding / NAT settings
3. Add rule:
   - External Port: 80
   - Internal Port: 80
   - Internal IP: 192.168.4.121
   - Protocol: TCP

### 4. VM Firewall
```bash
sudo ufw allow 80/tcp
sudo ufw enable
```

### 5. Set Up Dynamic DNS (Optional but Recommended)
Transfer the cloudflare-ddns.sh script to your VM:
```bash
scp cloudflare-ddns.sh narendar77@192.168.4.121:/home/narendar77/
```

On the VM:
```bash
chmod +x cloudflare-ddns.sh
./cloudflare-ddns.sh
```

Follow the prompts to set up automatic DNS updates.

### 6. Test
```bash
# From your Mac
nslookup narendar.com
curl http://narendar.com
```

Then open http://narendar.com in your browser.

---

## Important Notes

- **DNS Propagation**: Takes 5-15 minutes, sometimes up to 24 hours
- **Dynamic IP**: Home IPs change, so DDNS is important
- **ISP Blocking**: Some ISPs block port 80 - try 8080 if needed
- **Security**: Keep Cloudflare proxy enabled (orange cloud)

---

## Alternative: Cloudflare Tunnel (No Port Forwarding)

If you want to avoid port forwarding, use Cloudflare Tunnel instead. See the full guide in CLOUDFLARE-DNS-GUIDE.md