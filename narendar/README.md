# Narendar.com Website

A Docker containerized website with beautiful scrolling image gallery.

## Features

- Responsive scrolling image gallery
- Smooth CSS animations
- Gradient backgrounds
- Hover effects on images
- Mobile-friendly design

## Project Structure

```
narendar/
├── Dockerfile
├── docker-compose.yml
├── index.html
├── images/
│   ├── image1.svg
│   ├── image2.svg
│   ├── image3.svg
│   ├── image4.svg
│   ├── image5.svg
│   └── image6.svg
└── README.md
```

## Deployment Instructions

### 1. Copy files to VM

Copy the entire `narendar` directory to your VM at `192.168.4.121`:

```bash
scp -r narendar/ user@192.168.4.121:/path/to/destination/
```

### 2. SSH into the VM

```bash
ssh user@192.168.4.121
```

### 3. Navigate to the project directory

```bash
cd /path/to/narendar
```

### 4. Build and run with Docker Compose

```bash
docker compose up -d --build
```

### 5. Verify the container is running

```bash
docker ps
```

### 6. Access the website

The website will be available at:
- `http://192.168.4.121` (from your local network)
- `http://localhost` (from the VM itself)

## DNS Configuration

To point `narendar.com` to your homelab:

1. **Option A: DNS A Record**
   - Go to your domain registrar (e.g., Namecheap, GoDaddy, Cloudflare)
   - Add an A record: `narendar.com` → `192.168.4.121`
   - Note: This only works if 192.168.4.121 is a public IP

2. **Option B: Dynamic DNS (Recommended for home labs)**
   - Use a service like DuckDNS, No-IP, or Cloudflare Tunnel
   - This will work with your home network's dynamic IP

3. **Option C: Local DNS**
   - Add to your local network's DNS server or `/etc/hosts` file:
     ```
     192.168.4.121 narendar.com
     ```

## Managing the Container

### View logs
```bash
docker compose logs -f
```

### Stop the container
```bash
docker compose down
```

### Restart the container
```bash
docker compose restart
```

### Update the website
1. Make changes to the files
2. Rebuild and restart:
   ```bash
   docker compose up -d --build
   ```

## Customizing Images

Replace the SVG files in the `images/` directory with your own images (JPG, PNG, etc.). Update the `index.html` file to reference your new image files.

## Security Notes

- Consider using a reverse proxy (nginx, Traefik) with SSL/TLS for production
- Implement firewall rules to restrict access
- Keep the Docker image updated regularly
- Use environment variables for sensitive configuration

## License

MIT License