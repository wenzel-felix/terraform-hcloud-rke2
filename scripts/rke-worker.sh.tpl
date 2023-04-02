#! /bin/bash

mkdir -p /etc/rancher/rke2
cat <<EOF > /etc/rancher/rke2/config.yaml
server: https://${SERVER_ADDRESS}:9345
token: ${RKE_TOKEN}
EOF

sudo curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE="agent" sh -
sudo systemctl enable rke2-agent.service
sudo systemctl start rke2-agent.service