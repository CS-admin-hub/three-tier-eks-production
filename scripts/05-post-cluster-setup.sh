#!/bin/bash
# scripts/05-post-cluster-setup.sh
# Post-cluster tasks: tag subnets/SGs, create IRSA roles, create StorageClass
# Usage: ./05-post-cluster-setup.sh

set -e
echo "=== Post Cluster Setup ==="

export CLUSTER_NAME=three-tier-cluster
export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Get OIDC URL for IRSA trust policies
OIDC_URL=$(aws eks describe-cluster --name ${CLUSTER_NAME} \
  --query 'cluster.identity.oidc.issuer' --output text | sed 's|https://||')
echo "OIDC URL: ${OIDC_URL}"

# --- Tag subnets for Karpenter discovery ---
echo ">>> Tagging subnets for Karpenter..."
for SUBNET in $(aws eks describe-cluster --name ${CLUSTER_NAME} \
  --query 'cluster.resourcesVpcConfig.subnetIds' --output text); do
  aws ec2 create-tags --resources ${SUBNET} \
    --tags Key=karpenter.sh/discovery,Value=${CLUSTER_NAME}
  echo "  Tagged subnet: ${SUBNET}"
done

# --- Tag security groups for Karpenter discovery ---
echo ">>> Tagging security groups for Karpenter..."
for SG in $(aws eks describe-cluster --name ${CLUSTER_NAME} \
  --query 'cluster.resourcesVpcConfig.clusterSecurityGroupId' --output text); do
  aws ec2 create-tags --resources ${SG} \
    --tags Key=karpenter.sh/discovery,Value=${CLUSTER_NAME}
  echo "  Tagged SG: ${SG}"
done

# --- Create IRSA roles using trust policy files from iam/ folder ---
echo ">>> Creating IRSA roles..."

# Replace placeholders in trust policies
sed "s|<ACCOUNT_ID>|${AWS_ACCOUNT_ID}|g; s|<OIDC_URL>|${OIDC_URL}|g" \
  iam/backend-trust-policy.json > /tmp/backend-trust.json

sed "s|<ACCOUNT_ID>|${AWS_ACCOUNT_ID}|g; s|<OIDC_URL>|${OIDC_URL}|g" \
  iam/external-secrets-trust-policy.json > /tmp/ext-secrets-trust.json

sed "s|<ACCOUNT_ID>|${AWS_ACCOUNT_ID}|g; s|<OIDC_URL>|${OIDC_URL}|g" \
  iam/fluentbit-trust-policy.json > /tmp/fluentbit-trust.json

sed "s|<ACCOUNT_ID>|${AWS_ACCOUNT_ID}|g; s|<OIDC_URL>|${OIDC_URL}|g" \
  iam/velero-trust-policy.json > /tmp/velero-trust.json

# Backend IRSA Role
aws iam create-role --role-name BackendIRSARole \
  --assume-role-policy-document file:///tmp/backend-trust.json
aws iam attach-role-policy --role-name BackendIRSARole \
  --policy-arn arn:aws:iam::aws:policy/SecretsManagerReadWrite
echo "  Created: BackendIRSARole"

# External Secrets IRSA Role
aws iam create-role --role-name ExternalSecretsRole \
  --assume-role-policy-document file:///tmp/ext-secrets-trust.json
aws iam attach-role-policy --role-name ExternalSecretsRole \
  --policy-arn arn:aws:iam::aws:policy/SecretsManagerReadOnly
echo "  Created: ExternalSecretsRole"

# FluentBit IRSA Role
aws iam create-role --role-name FluentBitRole \
  --assume-role-policy-document file:///tmp/fluentbit-trust.json
aws iam attach-role-policy --role-name FluentBitRole \
  --policy-arn arn:aws:iam::aws:policy/CloudWatchLogsFullAccess
echo "  Created: FluentBitRole"

# Velero IRSA Role
aws iam create-role --role-name VeleroRole \
  --assume-role-policy-document file:///tmp/velero-trust.json
aws iam attach-role-policy --role-name VeleroRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
echo "  Created: VeleroRole"

# --- Create gp3 StorageClass ---
echo ">>> Creating gp3 StorageClass..."
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp3
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  encrypted: "true"
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Retain
EOF

echo ""
echo "=== Post Cluster Setup Complete ==="
kubectl get storageclass
echo ""
echo ">>> Next: Run 06-install-controllers.sh"