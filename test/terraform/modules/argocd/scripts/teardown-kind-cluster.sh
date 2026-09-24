#!/bin/bash

set -euo pipefail

echo "🧹 Tearing down kind cluster..."

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

KIND_CLUSTER_NAME="argocd-test"

print_status() {
  printf "${GREEN}✓${NC} %s\n" "$1"
}

print_warning() {
  printf "${YELLOW}⚠${NC} %s\n" "$1"
}

print_error() {
  printf "${RED}✗${NC} %s\n" "$1"
}

print_info() {
  printf "${YELLOW}ℹ${NC} %s\n" "$1"
}

# Check if kind is installed
if ! command -v kind &> /dev/null; then
  print_error "kind is not installed, nothing to clean up"
  exit 0
fi

# Check if cluster exists
if ! kind get clusters 2>/dev/null | grep -q "^${KIND_CLUSTER_NAME}$"; then
  print_warning "Cluster ${KIND_CLUSTER_NAME} does not exist, nothing to delete"
  exit 0
fi

# Get current context
CURRENT_CONTEXT=$(kubectl config current-context 2>/dev/null || echo "")

# Delete the cluster
echo "Deleting kind cluster '${KIND_CLUSTER_NAME}'..."
if kind delete cluster --name "${KIND_CLUSTER_NAME}"; then
  print_status "Kind cluster '${KIND_CLUSTER_NAME}' deleted"
else
  print_error "Failed to delete cluster"
  exit 1
fi

# Clean up kubectl context if it was pointing to the deleted cluster
if [ "${CURRENT_CONTEXT}" = "kind-${KIND_CLUSTER_NAME}" ]; then
  print_info "Switching kubectl context away from deleted cluster..."
  
  # Try to switch to docker-desktop or minikube as fallback
  if kubectl config get-contexts -o name 2>/dev/null | grep -q "^docker-desktop$"; then
    kubectl config use-context docker-desktop &>/dev/null
    print_status "Switched to 'docker-desktop' context"
  elif kubectl config get-contexts -o name 2>/dev/null | grep -q "^minikube$"; then
    kubectl config use-context minikube &>/dev/null
    print_status "Switched to 'minikube' context"
  else
    print_warning "No fallback context available. Current context may be invalid."
    print_info "Available contexts:"
    kubectl config get-contexts -o name 2>/dev/null || true
  fi
fi

echo ""
print_status "Teardown completed"
echo ""
echo "To recreate the cluster, run: ./setup-kind-only.sh"
