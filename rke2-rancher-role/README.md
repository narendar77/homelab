# RKE2 Rancher Ansible Role

This Ansible role automates the installation of RKE2 1.31.9 and Rancher 2.12.3 on Rocky Linux 9, based on the manual installation guide.

## Prerequisites

- Rocky Linux 9 VMs (minimum 3 nodes: 1 master, 2 workers)
- Root SSH access to all nodes
- DNS record configured for `rancher.narendar.com` pointing to the master node IP
- Network ports open as documented in the original guide
- Ansible 2.9 or higher installed on the control node

## Variables

Key variables are defined in `vars/main.yml` and can be overridden:

- `rke2_version`: RKE2 version to install (default: `v1.31.9+rke2r1`)
- `rke2_master_node`: Master node hostname
- `rke2_master_ip`: Master node IP address
- `rke2_worker_nodes`: List of worker nodes with names and IPs
- `rancher_hostname`: Rancher FQDN (default: `rancher.narendar.com`)
- `rancher_chart_version`: Rancher Helm chart version (default: `2.12.3`)
- `helm_version`: Helm version to install (default: `v3.19.5`)

## Usage

1. **Create inventory file:**

```bash
cp inventory.example.ini inventory.ini
# Edit inventory.ini with your actual hostnames and IPs
```

2. **Run the playbook:**

```bash
ansible-playbook -i inventory.ini playbook.yml
```

3. **Run with specific tags:**

```bash
# Only prepare VMs
ansible-playbook -i inventory.ini playbook.yml --tags common_prep

# Only install RKE2
ansible-playbook -i inventory.ini playbook.yml --tags rke2_server,rke2_agent

# Only install Rancher
ansible-playbook -i inventory.ini playbook.yml --tags helm,tls,rancher
```

## What Gets Installed

1. **Common VM Preparation** (all nodes):
   - System packages and kernel modules
   - Chrony for time synchronization
   - Swap disabled
   - NetworkManager configured for Canal/CNI
   - Firewalld disabled
   - Kernel parameters configured
   - Hostnames set

2. **RKE2 Server** (master node):
   - RKE2 v1.31.9+rke2r1 installed
   - Service enabled and started
   - Packages version-locked

3. **RKE2 Agents** (worker nodes):
   - RKE2 v1.31.9+rke2r1 installed
   - Join to master using token
   - Service enabled and started
   - Packages version-locked

4. **Helm** (master node):
   - Helm v3.19.5 installed
   - Rancher stable repository added

5. **TLS Certificates** (master node):
   - Private CA created
   - Server certificate generated for Rancher
   - Kubernetes secrets created

6. **Rancher** (master node):
   - Rancher 2.12.3 installed via Helm
   - Configured with nginx ingress
   - Private CA enabled

7. **Verification & Backup** (master node):
   - Etcd snapshot created
   - Configuration backup created
   - Final verification performed

## Post-Installation

After the playbook completes:

1. **Retrieve the bootstrap password** (displayed at the end of the playbook)
2. **Download the CA certificate** from the master node:
   ```bash
   scp root@<master-ip>:/tmp/homelab-cacerts.pem .
   ```
3. **Import the CA certificate** into your browser's trust store
4. **Access Rancher** at `https://rancher.narendar.com`
5. **Login** with username `admin` and the bootstrap password
6. **Set a new password** for the admin user

## Backups

The playbook creates:
- Etcd snapshot: `initial-rancher-install`
- Configuration backup in `/root/rke2-backups/`

Copy these backups to a secure location off the master node.

## Troubleshooting

Check service status:
```bash
# On master
systemctl status rke2-server
journalctl -u rke2-server -n 100

# On workers
systemctl status rke2-agent
journalctl -u rke2-agent -n 100
```

Check cluster status from master:
```bash
source /root/rke2-env.sh
kubectl get nodes -o wide
kubectl get pods -A
```

## Notes

- SELinux is left enabled (per the original guide)
- This is a single-server control plane setup (not HA)
- The pinned versions are for a learning baseline
- Kubernetes 1.31 reached EOL in November 2025
- Plan to modernize Kubernetes, Rancher, and ingress together

## Upgrades

Do not use this playbook for upgrades. The original documentation includes a separate upgrade script that should be used instead. See the upgrade section in the original guide for details.

## License

MIT
