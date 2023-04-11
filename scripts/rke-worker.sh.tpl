#! /bin/bash

NODE_IP=""

while [[ "$NODE_IP" = "" ]]
do
  NODE_IP=$(curl -s http://169.254.169.254/hetzner/v1/metadata/private-networks | grep "ip:" | cut -f 3 -d" ")
done

mkdir -p /etc/rancher/rke2
cat <<EOF > /etc/rancher/rke2/config.yaml
server: https://${SERVER_ADDRESS}:9345
token: ${RKE_TOKEN}
cloud-provider-name: external
node-ip: $NODE_IP
EOF

sudo curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE="agent" INSTALL_RKE2_VERSION="${INSTALL_RKE2_VERSION}" sh -
sudo systemctl enable rke2-agent.service
sudo systemctl start rke2-agent.service