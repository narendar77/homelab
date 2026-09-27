#!/bin/bash
set -e

echo "=== Rocky Linux Kubernetes Gold Template Setup ==="

### VARIABLES ###
USERNAME="narendar77"
BANNER_FILE="/etc/issue"
MOTD_FILE="/etc/motd"

### 1. SYSTEM UPDATE ###
dnf update -y

### 2. CREATE USER ###
if ! id "$USERNAME" &>/dev/null; then
  useradd -m "$USERNAME"
  echo "User $USERNAME created"
fi

usermod -aG wheel "$USERNAME"

### 3. PASSWORDLESS SUDO ###
SUDO_FILE="/etc/sudoers.d/$USERNAME"
if [ ! -f "$SUDO_FILE" ]; then
  echo "$USERNAME ALL=(ALL) NOPASSWD: ALL" > "$SUDO_FILE"
  chmod 440 "$SUDO_FILE"
fi

### 4. ESSENTIAL PACKAGES ###
sudo dnf config-manager --set-enabled crb
sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
sudo dnf install -y epel-release
dnf install -y \
  vim nano curl wget git net-tools bash-completion \
  iproute iptables iputils bind-utils traceroute \
  tcpdump lsof telnet socat conntrack conntrack-tools \
  nfs-utils rsync jq chrony firewalld \
  figlet cloud-init

systemctl enable chrony --now

### 5. DISABLE SWAP ###
swapoff -a
sed -i '/swap/d' /etc/fstab

### 6. SELINUX PERMISSIVE ###
setenforce 0 || true
sed -i 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config

### 7. CONTAINERD INSTALL ###
dnf install -y containerd
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl enable --now containerd

### 8. KERNEL & SYSCTL ###
cat <<EOF >/etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

cat <<EOF >/etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system

### 9. KUBERNETES TOOLS ###
cat <<EOF >/etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.31/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.31/rpm/repodata/repomd.xml.key
EOF

dnf install -y kubelet kubeadm kubectl
systemctl enable kubelet

### 10. LOGIN BANNER & LOGO ###


sudo dnf install -y figlet
figlet Narendar > "$BANNER_FILE"

cat <<'EOF' >> /etc/issue

###############################################################
#                AUTHORIZED ACCESS ONLY                       #
#                                                             #
# This system is the property of Narendar Systems.            #
# Access is restricted to authorized users only.              #
# All activities are monitored, logged, and audited.          #
# Unauthorized use may result in disciplinary action and/or   #
# legal prosecution.                                          #
###############################################################
EOF

cat <<'EOF' > "$MOTD"
Welcome to Narendar Kubernetes Node

Authorized access only.
All actions on this system are monitored and logged.
Disconnect immediately if you are not an authorized user.
EOF

### 11. SSH BANNER ###
sed -i 's|^#Banner none|Banner /etc/issue|' /etc/ssh/sshd_config
sed -i 's|^#PrintMotd yes|PrintMotd yes|' /etc/ssh/sshd_config
systemctl restart sshd

### 12. CLEAN TEMPLATE ARTIFACTS ###
truncate -s 0 /etc/machine-id
rm -f /var/lib/dbus/machine-id
ln -s /etc/machine-id /var/lib/dbus/machine-id

rm -rf /tmp/* /var/tmp/*
history -c || true

echo "=== TEMPLATE SETUP COMPLETE ==="
echo "Shutdown the VM and convert it to a Proxmox template."