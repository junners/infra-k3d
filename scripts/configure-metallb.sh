cluster_name=$(cat ./config.yaml | yq '.metadata.name')
cidr_block=$(docker network inspect k3d-$cluster_name | jq '.[0].IPAM.Config[0].Subnet' | tr -d '"')
cidr_base_addr=${cidr_block%???}
first_addr=$(echo $cidr_base_addr | awk -F'.' '{print $1,$2,255,0}' OFS='.')
ingress_range=$first_addr/24

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - $ingress_range
EOF

set kubeconfig to access the k8s context
export KUBECONFIG=$(k3d kubeconfig write $cluster_name)