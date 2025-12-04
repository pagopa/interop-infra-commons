#!/bin/bash

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
  printf "${GREEN}✓${NC} %s\n" "$1"
}

print_warning() {
  printf "${YELLOW}⚠${NC} %s\n" "$1"
}

print_error() {
  printf "${RED}✗${NC} %s\n" "$1"
}

echo "🌱 Creating kind cluster (kind-only setup)..."

KIND_CLUSTER_NAME="argocd-test"

# Calculate the absolute path to the repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../../../" && pwd)"

# Check root location
if [[ ! -d "$REPO_ROOT/argocd/plugins/cronjobs" ]]; then
  print_error "Cannot find argocd/plugins directory at: $REPO_ROOT/argocd/plugins"
  echo "DEBUG: SCRIPT_DIR=$SCRIPT_DIR"
  echo "DEBUG: REPO_ROOT=$REPO_ROOT"
  echo "DEBUG: Expected path: $REPO_ROOT/argocd/plugins/cronjobs"
  exit 1
fi

echo "Checking prerequisites..."

if ! command -v docker &> /dev/null; then
  print_error "Docker is not installed"
  exit 1
fi
print_status "Docker found"

if ! command -v kubectl &> /dev/null; then
  print_error "kubectl is not installed"
  exit 1
fi
print_status "kubectl found"

if ! command -v kind &> /dev/null; then
  print_warning "kind not found, installing..."
  brew install kind || (print_error "Failed to install kind" && exit 1)
fi
print_status "kind found"

echo "Creating kind cluster..."
if kind get clusters | grep -q "^${KIND_CLUSTER_NAME}$"; then
  print_warning "Cluster ${KIND_CLUSTER_NAME} already exists, skipping creation"
else
  cat <<EOF | kind create cluster --name ${KIND_CLUSTER_NAME} --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
  - containerPort: 8080
    hostPort: 8080
    protocol: TCP
EOF
  print_status "Kind cluster created"
fi

kubectl config use-context "kind-${KIND_CLUSTER_NAME}"
print_status "Kubectl context set"

echo ""
echo "Building and loading plugin Docker images..."

# Build plugin images
echo "Building argocd-plugin-cronjobs..."
docker build -f "$REPO_ROOT/argocd/plugins/cronjobs/Dockerfile" \
  -t argocd-plugin-cronjobs:local "$REPO_ROOT" > /dev/null 2>&1 || \
  (print_error "Failed to build cronjobs plugin" && exit 1)
print_status "argocd-plugin-cronjobs:local built"

echo "Building argocd-plugin-microservices..."
docker build -f "$REPO_ROOT/argocd/plugins/microservices/Dockerfile" \
  -t argocd-plugin-microservices:local "$REPO_ROOT" > /dev/null 2>&1 || \
  (print_error "Failed to build microservices plugin" && exit 1)
print_status "argocd-plugin-microservices:local built"

# Load images into kind cluster
echo "Loading images into kind cluster..."
kind load docker-image argocd-plugin-cronjobs:local --name ${KIND_CLUSTER_NAME} || \
  (print_error "Failed to load cronjobs image" && exit 1)
print_status "argocd-plugin-cronjobs:local loaded"

kind load docker-image argocd-plugin-microservices:local --name ${KIND_CLUSTER_NAME} || \
  (print_error "Failed to load microservices image" && exit 1)
print_status "argocd-plugin-microservices:local loaded"

echo ""
echo "Kind cluster ready: context 'kind-${KIND_CLUSTER_NAME}'"
echo "You can verify with: kubectl cluster-info"
print_status "Setup (kind-only) completed"
