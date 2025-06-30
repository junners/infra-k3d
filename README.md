# Prerequisites

```bash
brew install kind
brew install helm
brew install istioctl
```

# Create Local Kubernetes

```bash
k3d cluster create --config config.yaml
```

# Delete Local kubernetes

```bash
k3d registry delete --all && k3d cluster delete --all
```

# Install Kubernetes Dashboard

```bash
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard
kubectl create serviceaccount -n kubernetes-dashboard admin-user
kubectl create clusterrolebinding -n kubernetes-dashboard admin-user --clusterrole cluster-admin --serviceaccount=kubernetes-dashboard:admin-user
token=$(kubectl -n kubernetes-dashboard create token admin-user)
echo $token
kubectl proxy
```

# Istio

```bash
#
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update
kubectl create namespace istio-system
helm upgrade --install istio-base istio/base -n istio-system --wait
helm upgrade --install istiod istio/istiod -n istio-system --wait
helm upgrade --install istio-cni istio/cni -n istio-system --set profile=ambient --set global.platform=k3d --wait

# Optional, gateway api should suffice
#helm upgrade --install istio-ingressgateway istio/gateway -n istio-system --wait

# Gateway API Custom Resource Definition to hook into gateway classes
kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
  kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/standard-install.yaml
```