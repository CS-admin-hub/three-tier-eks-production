#!/bin/bash
# scripts/06-install-controllers.sh
# Installs all cluster controllers: Karpenter, ALB, Metrics Server, ESO, Kyverno
# Usage: ./06-install-controllers.sh

set -e
echo "=== Installing Cluster Controllers ==="

export CLUSTER_NAME=three-tier-cluster
export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export KARPENTER_VERSION=v0.37.0

# --- 1. Karpenter ---
echo ">>> Installing Karpenter ${KARPENTER_VERSION}..."
eksctl create iamserviceaccount \
  --cluster ${CLUSTER_NAME} \
  --namespace karpenter \
  --name karpenter \
  --role-name KarpenterControllerRole-${CLUSTER_NAME} \
  --attach-policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/KarpenterControllerPolicy-${CLUSTER_NAME} \
  --approve --region ${AWS_DEFAULT_REGION}

helm repo add karpenter https://charts.karpenter.sh/
helm repo update

helm install karpenter oci://public.ecr.aws/karpenter/karpenter \
  --version ${KARPENTER_VERSION} \
  --namespace karpenter --create-namespace \
  --set settings.clusterName=${CLUSTER_NAME} \
  --set settings.interruptionQueue=${CLUSTER_NAME} \
  --set controller.resources.requests.cpu=1 \
  --set controller.resources.requests.memory=1Gi \
  --set controller.resources.limits.cpu=1 \
  --set controller.resources.limits.memory=1Gi \
  --wait

kubectl get pods -n karpenter
echo "  Karpenter installed"

# Apply NodePool and EC2NodeClass
kubectl apply -f karpenter/ec2nodeclass.yaml
kubectl apply -f karpenter/nodepool.yaml
kubectl get nodepool
echo "  NodePool applied"

# --- 2. Metrics Server ---
echo ">>> Installing Metrics Server..."
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
sleep 30
kubectl top nodes
echo "  Metrics Server installed"

# --- 3. ALB Ingress Controller ---
echo ">>> Installing ALB Ingress Controller..."
eksctl create iamserviceaccount \
  --cluster=${CLUSTER_NAME} \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess \
  --approve

helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=${CLUSTER_NAME} \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller

kubectl get deployment -n kube-system aws-load-balancer-controller
echo "  ALB Controller installed"

# --- 4. External Secrets Operator ---
echo ">>> Installing External Secrets Operator..."
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

helm install external-secrets external-secrets/external-secrets \
  -n external-secrets --create-namespace \
  --set installCRDs=true

kubectl get pods -n external-secrets
echo "  External Secrets Operator installed"

# --- 5. Kyverno ---
echo ">>> Installing Kyverno..."
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update

helm install kyverno kyverno/kyverno \
  -n kyverno --create-namespace

kubectl get pods -n kyverno
echo "  Kyverno installed"

echo ""
echo "=== All Controllers Installed ==="
echo ""
echo "NEXT STEPS (do these manually):"
echo "  1. AWS Console → ACM → Request Certificate for your domain"
echo "  2. AWS Console → WAF → Create Web ACL → copy ARN"
echo "  3. Update k8s_manifests/ingress/full_stack_lb.yml with cert + WAF ARNs"
echo "  4. Update k8s_manifests/security/service-accounts.yaml with Account ID"
echo "  5. Store secret: aws secretsmanager create-secret --name prod/three-tier/mongodb ..."
echo "  6. Then run: kubectl apply -f k8s_manifests/ (in order)"