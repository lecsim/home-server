#!/bin/bash
# Complete IaC Test: Destroy and Rebuild Everything
# This script tests if all infrastructure can be rebuilt from scratch

set -e

echo "=== Testing Complete IaC Setup ==="
echo

# Step 1: Destroy all containers
echo "[1/4] Destroying all containers..."
cd terraform
terraform destroy -auto-approve

# Step 2: Recreate infrastructure
echo "[2/4] Creating infrastructure..."
terraform apply -auto-approve

# Step 3: Wait for containers to start
echo "[3/4] Waiting for containers to boot (30s)..."
sleep 30

# Step 4: Run setup script ON Proxmox host
echo "[4/4] Installing software on Proxmox..."
cd ..
cat scripts/setup-from-proxmox.sh | ssh root@192.168.0.228 'cat > /tmp/setup.sh && bash /tmp/setup.sh'

echo
echo "=== IaC Test Complete ==="
echo
echo "Services should be available at:"
echo "  - Home Assistant: http://192.168.0.10:8123 (wait ~60s after script)"
echo "  - Prometheus: http://192.168.0.12:9090"
echo "  - Grafana: http://192.168.0.13:3000"
echo "  - PiHole: http://192.168.0.11/admin"
