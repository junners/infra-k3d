cluster_name=$(cat ./config.yaml | yq '.metadata.name')
cidr_block=$(docker network inspect k3d-$cluster_name | jq '.[0].IPAM.Config[0].Subnet' | tr -d '"')
cidr_base_addr=${cidr_block%???}
ingress_first_addr=$(echo $cidr_base_addr | awk -F'.' '{print $1,$2,255,0}' OFS='.')
ingress_last_addr=$(echo $cidr_base_addr | awk -F'.' '{print $1,$2,255,255}' OFS='.')
ingress_range=$ingress_first_addr-$ingress_last_addr

cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: local-pool
  namespace: metallb-system
spec:
  addresses:
  - $ingress_range
EOF

cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: BGPAdvertisement
metadata:
  name: metal-lb-external
  namespace: metallb-system
spec:
  ipAddressPools:
  - local-pool
EOF

#set kubeconfig to access the k8s context
export KUBECONFIG=$(k3d kubeconfig write $cluster_name)