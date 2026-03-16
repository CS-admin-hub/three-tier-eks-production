#!/bin/bash
# scripts/cleanup.sh
# Tears down EVERYTHING - use after demo to avoid AWS costs
# Usage: ./cleanup.sh
# WARNING: This is irreversible - all data will be lost

set -e
echo "=== WARNING: This will delete ALL resources ==="
read -p "Are you sure? Type 'yes' to confirm: " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
  echo "Aborted."
  exit 1
fi

export CLUSTER_NAME=three-tier-cluster
export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Delete namespaces (removes all pods, services, configs inside)
echo ">>> Deleting Kubernetes namespaces..."
kubectl delete namespace workshop monitoring karpenter \
  external-secrets kyverno velero --ignore-not-found

# Delete EKS cluster (removes nodegroups, VPC, subnets, IGW, NAT GW)
echo ">>> Deleting EKS cluster (takes ~10 mins)..."
eksctl delete cluster --name ${CLUSTER_NAME} --region ${AWS_DEFAULT_REGION}

# Delete ECR repositories
echo ">>> Deleting ECR repositories..."
aws ecr delete-repository --repository-name three-tier-frontend \
  --force --region ${AWS_DEFAULT_REGION}
aws ecr delete-repository --repository-name three-tier-backend \
  --force --region ${AWS_DEFAULT_REGION}

# Delete Secrets Manager secret
echo ">>> Deleting Secrets Manager secret..."
aws secretsmanager delete-secret \
  --secret-id prod/three-tier/mongodb \
  --force-delete-without-recovery \
  --region ${AWS_DEFAULT_REGION}

# Delete S3 backup bucket
echo ">>> Deleting S3 backup bucket..."
aws s3 rb s3://three-tier-velero-backup-${AWS_ACCOUNT_ID} --force

# Delete CloudFormation stack (Karpenter IAM roles)
echo ">>> Deleting Karpenter CloudFormation stack..."
aws cloudformation delete-stack --stack-name KarpenterNodeRole

echo ""
echo "=== Cleanup Complete ==="
echo ">>> Remember to terminate the EC2 jumpbox from AWS Console"
echo ">>> Check AWS Cost Explorer tomorrow to confirm no lingering charges"