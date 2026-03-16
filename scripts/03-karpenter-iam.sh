#!/bin/bash
# scripts/03-karpenter-iam.sh
# Creates Karpenter IAM roles via CloudFormation
# Must run BEFORE creating the EKS cluster
# Usage: ./03-karpenter-iam.sh

set -e
echo "=== Setting Up Karpenter IAM Roles ==="

export CLUSTER_NAME=three-tier-cluster
export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "Cluster: ${CLUSTER_NAME}"
echo "Account: ${AWS_ACCOUNT_ID}"

# Download Karpenter CloudFormation template
echo ">>> Downloading Karpenter CloudFormation template..."
curl -fsSL \
  https://raw.githubusercontent.com/aws/karpenter-provider-aws/v0.37.0/website/content/en/preview/getting-started/getting-started-with-karpenter/cloudformation.yaml \
  > karpenter-cf.yaml

# Deploy CloudFormation stack
echo ">>> Deploying CloudFormation stack (creates KarpenterNodeRole + KarpenterControllerPolicy)..."
aws cloudformation deploy \
  --stack-name KarpenterNodeRole \
  --template-file karpenter-cf.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides ClusterName=${CLUSTER_NAME}

# Verify
echo ""
echo "=== Karpenter IAM Stack Status ==="
aws cloudformation describe-stacks \
  --stack-name KarpenterNodeRole \
  --query 'Stacks[0].StackStatus' \
  --output text
# Should print: CREATE_COMPLETE

echo ""
echo ">>> Next: Run 04-create-cluster.sh"