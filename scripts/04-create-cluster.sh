#!/bin/bash
# scripts/04-create-cluster.sh
# Creates the EKS cluster - takes 15-20 minutes
# Usage: ./04-create-cluster.sh

set -e
echo "=== Creating EKS Cluster ==="
echo ">>> This will take 15-20 minutes..."

export CLUSTER_NAME=three-tier-cluster
export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Create cluster with OIDC enabled (required for IRSA)
eksctl create cluster \
  --name ${CLUSTER_NAME} \
  --region ${AWS_DEFAULT_REGION} \
  --nodegroup-name three-tier-ng \
  --node-type t3.medium \
  --nodes 2 \
  --nodes-min 2 \
  --nodes-max 2 \
  --managed \
  --with-oidc \
  --full-ecr-access \
  --zones us-east-1a,us-east-1b

# Connect kubectl to the new cluster
echo ">>> Connecting kubectl to cluster..."
aws eks update-kubeconfig \
  --region ${AWS_DEFAULT_REGION} \
  --name ${CLUSTER_NAME}

# Verify nodes are Ready
echo ""
echo "=== Cluster Nodes ==="
kubectl get nodes -o wide
# Expect: 2 nodes in Ready state

echo ""
echo ">>> Next: Run 05-post-cluster-setup.sh"