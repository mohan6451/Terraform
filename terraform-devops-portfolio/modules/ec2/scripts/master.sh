#!/bin/bash
set -ex

REGION="${aws_region}"
ENV="${env}"

# Install dependencies
apt-get update -y
apt-get install -y curl unzip

# Install AWS CLI v2
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install

# Fetch public IP with retry
IMDS_TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" --retry 3 --retry-delay 2 --max-time 10)

PUBLIC_IP=$(curl -s -H "X-aws-ec2-metadata-token: $IMDS_TOKEN" --retry 3 --retry-delay 2 --max-time 10 http://169.254.169.254/latest/meta-data/public-ipv4)

[ -z "$PUBLIC_IP" ] && { echo "Failed to get public IP"; exit 1; }
echo "Public IP: $PUBLIC_IP"

# Install K3s server
curl -sfL https://get.k3s.io | sh -s - server --write-kubeconfig-mode 0644 --tls-san "$PUBLIC_IP"

# Wait for K3s to be ready with timeout
echo "Waiting for K3s to become ready..."
TIMEOUT=60
COUNT=0
until [ -f /var/lib/rancher/k3s/server/node-token ]; do
  sleep 5
  COUNT=$((COUNT + 1))
  [ $COUNT -ge $TIMEOUT ] && { echo "Timed out waiting for node-token"; exit 1; }
done

# Wait for K3s service to be fully active
systemctl is-active --quiet k3s || { echo "K3s service not active"; exit 1; }

# Store token in SSM
TOKEN=$(cat /var/lib/rancher/k3s/server/node-token)
echo "Storing node-token in SSM..."
aws ssm put-parameter --region "$REGION" --name "/$ENV/k3s/node-token" --value "$TOKEN" --type "SecureString" --overwrite

echo "Master setup complete. Token stored in SSM."
