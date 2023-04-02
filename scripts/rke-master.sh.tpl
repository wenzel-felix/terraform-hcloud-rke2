#! /bin/bash

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
EOF

sudo curl -sfL https://get.rke2.io | INSTALL_RKE2_VERSION="${INSTALL_RKE2_VERSION}" sh -
sudo systemctl enable rke2-server.service
sudo systemctl start rke2-server.service