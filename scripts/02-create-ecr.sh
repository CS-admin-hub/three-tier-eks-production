#!/bin/bash
# scripts/02-create-ecr.sh
# Creates ECR repositories for frontend and backend
# Usage: ./02-create-ecr.sh

set -e
echo "=== Creating ECR Repositories ==="

export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "Account ID: ${AWS_ACCOUNT_ID}"
echo "Region: ${AWS_DEFAULT_REGION}"

# Create frontend repo with vulnerability scanning enabled
echo ">>> Creating frontend ECR repo..."
aws ecr create-repository \
  --repository-name three-tier-frontend \
  --region ${AWS_DEFAULT_REGION} \
  --image-scanning-configuration scanOnPush=true

# Create backend repo with vulnerability scanning enabled
echo ">>> Creating backend ECR repo..."
aws ecr create-repository \
  --repository-name three-tier-backend \
  --region ${AWS_DEFAULT_REGION} \
  --image-scanning-configuration scanOnPush=true

echo ""
echo "=== ECR Repos Created ==="
aws ecr describe-repositories --region ${AWS_DEFAULT_REGION} \
  --query 'repositories[*].[repositoryName,repositoryUri]' \
  --output table

echo ""
echo ">>> Next: Clone your repo and run 03-karpenter-iam.sh"