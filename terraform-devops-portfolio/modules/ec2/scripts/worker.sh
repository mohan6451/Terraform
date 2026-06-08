#!/bin/bash
set -ex

REGION="${aws_region}"
ENV="${env}"
MASTER_IP="${master_private_ip}"

# Install dependencies
apt-get update -y
apt-get install -y curl unzip

# Install AWS CLI v2
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install

# Wait until master has written real token to SSM
echo "Waiting for K3s node-token in SSM..."
until TOKEN=$(aws ssm get-parameter --region "$REGION" --name "/$ENV/k3s/node-token" --with-decryption --query "Parameter.Value" --output text 2>/dev/null) && [ -n "$TOKEN" ] && [ "$TOKEN" != "placeholder" ]; do
  echo "Token not ready yet, retrying in 10s..."
  sleep 10
done

echo "Token received. Joining cluster..."

# Join the cluster
curl -sfL https://get.k3s.io | K3S_URL="https://$MASTER_IP:6443" K3S_TOKEN="$TOKEN" sh -

echo "Worker joined cluster successfully."
