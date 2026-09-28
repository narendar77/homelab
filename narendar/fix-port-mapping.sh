#!/bin/bash

# Fix port mapping for narendar-website container

echo "Stopping current container..."
docker stop narendar-website

echo "Removing current container..."
docker rm narendar-website

echo "Running container with correct port mapping..."
docker run -d \
    --name narendar-website \
    -p 80:80 \
    --restart unless-stopped \
    narendar-website:latest

echo "Verifying container is running with port mapping..."
docker ps | grep narendar-website

echo ""
echo "Container should now be accessible at http://192.168.4.121"