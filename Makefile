.PHONY: all clean sandbox brew cluster helm istio metallb prereq clean-docker clean-k3d vm-setup vm-up vm-down vm-cleanup kube-config install-helm install-istio istio-k3s

# all: cluster metallb istio

all: vm-setup

# lima setup
vm-setup:
	echo -e "\n" | limactl create --name=corecraft-lab ./lima.yaml 
	$(MAKE) vm-up

vm-up:
	limactl start corecraft-lab

vm-down: 
	limactl stop corecraft-lab

vm-clean:
	$(MAKE) vm-down
	limactl delete corecraft-lab
# limactl prune
	@rm -rf $(HOME)/.lima/corecraft-lab

vm-sandbox:
	$(MAKE) vm-clean
	$(MAKE) all

# one off
init: brew helm

brew:
	brew install helm || true
	brew install istioctl || true
	brew install lima || true

helm:
	helm repo add istio https://istio-release.storage.googleapis.com/charts || true
	helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/ || true
	helm repo add metallb https://metallb.github.io/metallb || true
	helm repo update

clean: 
	k3d registry delete --all
	k3d cluster delete --all
	$(MAKE) clean-docker

clean-docker:
	echo y | docker image prune --all
	echo y | docker volume prune --all
	echo y | docker container prune
	echo y | docker network prune
	echo y | docker system prune --all

cluster:
	k3d cluster create --config config.yaml

istio:
	istioctl install --set .values.global.platform=k3d --set .values.pilot.env.ENABLE_NATIVE_SIDECARS=true --set .values.pilot.env.PILOT_ENABLE_GATEWAY_API_GATEWAYCLASS_CONTROLLER=true --set profile=default --skip-confirmation
	$(MAKE) istio-config

istio-config:
	kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
		kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/standard-install.yaml
	kubectl label namespace default istio-injection=enabled

istio-ambient:
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
	helm upgrade --install metallb metallb/metallb --namespace metallb-system --create-namespace --wait
	@if [ -f scripts/configure-metallb.sh ]; then bash scripts/configure-metallb.sh; else echo "Missing script: scripts/configure-metallb.sh"; exit 1; fi

sandbox: clean all
