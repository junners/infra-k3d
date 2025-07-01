.PHONY: all clean sandbox brew cluster helm istio metallb prereq

all: cluster metallb istio

# one off
init: brew helm

brew:
	brew install helm || true
	brew install istioctl || true

helm:
	helm repo add istio https://istio-release.storage.googleapis.com/charts || true
	helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/ || true
	helm repo add metallb https://metallb.github.io/metallb || true
	helm repo update

clean:
	-k3d registry delete --all
	-k3d cluster delete --all
	echo y | docker image prune --all
	echo y | docker volume prune --all
	echo y | docker container prune
	echo y | docker network prune
	echo y | docker system prune --all

cluster:
	k3d cluster create --config config.yaml

istio:
# kubectl create namespace istio-system --dry-run=client -o yaml | kubectl apply -f -
# helm upgrade --install istio-cni istio/cni -n istio-system --set profile=ambient --set global.platform=k3d --wait
# helm upgrade --install istio-base istio/base -n istio-system --wait
# helm upgrade --install istiod istio/istiod -n istio-system --wait
# kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
# 	kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/standard-install.yaml
# v2
	helm upgrade --install istio-base istio/base -n istio-system --create-namespace --set profile=ambient --set global.platform=k3d --wait
	kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
		kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/standard-install.yaml
	helm upgrade --install istiod istio/istiod --namespace istio-system --set profile=ambient --set global.platform=k3d --set pilot.cni.enabled=true --wait
	helm upgrade --install istio-cni istio/cni --namespace istio-system --set profile=ambient --set global.platform=k3d --wait
# helm upgrade --install ztunnel istio/ztunnel --namespace istio-system --set global.platform=k3d

# istioctl install --set profile=ambient --set values.global.platform=k3d --skip-confirmation

metallb:
	kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.15.2/config/manifests/metallb-native.yaml
# helm upgrade --install metallb metallb/metallb
	@if [ -f scripts/configure-metallb.sh ]; then bash scripts/configure-metallb.sh; else echo "Missing script: scripts/configure-metallb.sh"; exit 1; fi

sandbox: clean all
