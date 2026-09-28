#!/bin/bash

# Deploy narendar-website Docker image on VM
# Run this script on the VM (192.168.4.121)
# Make sure narendar-website.tar is in /home/narendar77

set -e

echo "========================================="
echo "Deploying Narendar Website Docker Image"
echo "========================================="

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Please install Docker first."
    echo "You can use the install-docker.sh script in the parent directory."
    exit 1
fi

echo "[1/4] Loading Docker image from tar file..."
docker load -i narendar-website.tar

echo "[2/4] Removing existing container if it exists..."
docker rm -f narendar-website 2>/dev/null || true

echo "[3/4] Running the container..."
docker run -d \
    --name narendar-website \
    -p 80:80 \
    --restart unless-stopped \
    narendar-website:latest

echo "[4/4] Verifying the container is running..."
docker ps | grep narendar-website

echo ""
echo "========================================="
echo "Deployment Complete!"
echo "========================================="
echo ""
echo "Website is now available at:"
echo "  - http://192.168.4.121 (from your network)"
echo "  - http://localhost (from the VM itself)"
echo ""
echo "Note: If narendar-website.tar is in a different location,"
echo "      update the path in the 'docker load' command."
echo ""
echo "To view logs:"
echo "  docker logs -f narendar-website"
echo ""
echo "To stop the container:"
echo "  docker stop narendar-website"
echo ""
echo "To restart the container:"
echo "  docker restart narendar-website"
echo ""