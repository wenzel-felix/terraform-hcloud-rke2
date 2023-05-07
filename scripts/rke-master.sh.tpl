#! /bin/bash

NODE_IP=""

while [[ "$NODE_IP" = "" ]]
do
  NODE_IP=$(curl -s http://169.254.169.254/hetzner/v1/metadata/private-networks | grep "ip:" | cut -f 3 -d" ")
done

mkdir -p /etc/rancher/rke2
cat <<EOF > /etc/rancher/rke2/config.yaml
%{ if INITIAL_MASTER }
token: ${RKE_TOKEN}
%{ else }
server: https://${SERVER_ADDRESS}:9345
token: ${RKE_TOKEN}
%{ endif }
tls-san:
  - ${SERVER_ADDRESS}
cloud-provider-name: external
node-ip: $NODE_IP
%{ if EXPOSE_METRICS }
etcd-expose-metrics: true
kube-controller-manager-arg:
  - "bind-address=0.0.0.0"
kube-scheduler-arg:
  - "bind-address=0.0.0.0"
kube-proxy:
  - "bind-address=0.0.0.0"
%{ endif }
EOF

sudo curl -sfL https://get.rke2.io | INSTALL_RKE2_VERSION="${INSTALL_RKE2_VERSION}" sh -
sudo systemctl enable rke2-server.service
sudo systemctl start rke2-server.service