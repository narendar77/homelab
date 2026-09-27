#!/bin/bash

set -e

echo "========================================="
echo "Docker Installation for Ubuntu 24.04"
echo "========================================="

# Remove old versions
echo "[1/8] Removing old Docker packages..."

for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
    sudo apt-get remove -y $pkg 2>/dev/null || true
done

# Update packages
echo "[2/8] Updating package repositories..."
sudo apt update

# Install prerequisites
echo "[3/8] Installing prerequisites..."
sudo apt install -y ca-certificates curl gnupg

# Add Docker GPG Key
echo "[4/8] Adding Docker GPG key..."
sudo install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker Repository
echo "[5/8] Adding Docker repository..."

echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
echo "[6/8] Installing Docker Engine..."

sudo apt update

sudo apt install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

# Enable Service
echo "[7/8] Enabling Docker service..."

sudo systemctl enable docker
sudo systemctl start docker

# Docker Group
echo "[8/8] Adding user to docker group..."

if ! getent group docker >/dev/null; then
    sudo groupadd docker
fi

sudo usermod -aG docker $USER

echo ""
echo "========================================="
echo "Installation Complete"
echo "========================================="
echo ""

docker --version
docker compose version
docker buildx version

echo ""
echo "Docker Service Status:"
sudo systemctl --no-pager --full status docker | head -15

echo ""
echo "Run the following command after logout/login:"
echo ""
echo "    docker run hello-world"
echo ""
echo "OR apply group changes immediately with:"
echo ""
echo "    newgrp docker"
echo ""