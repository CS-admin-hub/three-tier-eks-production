#!/bin/bash
# scripts/01-setup-jumpbox.sh
# Run this FIRST after SSH-ing into the EC2 jumpbox
# Usage: chmod +x 01-setup-jumpbox.sh && ./01-setup-jumpbox.sh

set -e  # Exit immediately if any command fails
echo "=== Starting Jumpbox Setup ==="

# kubectl - matches EKS 1.29
echo ">>> Installing kubectl..."
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.29.0/2024-01-04/bin/linux/amd64/kubectl
chmod +x kubectl && sudo mv kubectl /usr/local/bin/
kubectl version --client

# eksctl
echo ">>> Installing eksctl..."
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_Linux_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin/
eksctl version

# AWS CLI v2
echo ">>> Installing AWS CLI..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip
unzip awscliv2.zip && sudo ./aws/install
aws --version

# Docker
echo ">>> Installing Docker..."
sudo yum update -y && sudo yum install docker -y
sudo systemctl start docker && sudo systemctl enable docker
sudo usermod -aG docker ec2-user

# Helm
echo ">>> Installing Helm..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version

# git
echo ">>> Installing git..."
sudo yum install git -y
git --version

# Velero CLI
echo ">>> Installing Velero CLI..."
curl -fsSL -o velero.tar.gz https://github.com/vmware-tanzu/velero/releases/latest/download/velero-v1.13.0-linux-amd64.tar.gz
tar -xvf velero.tar.gz
sudo mv velero-v1.13.0-linux-amd64/velero /usr/local/bin/
velero version --client-only

echo ""
echo "=== All tools installed! ==="
echo ">>> IMPORTANT: Log out and back in for Docker group to take effect"
echo ">>> Then verify identity with: aws sts get-caller-identity"