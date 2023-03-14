#! /bin/bash

sudo apt-get remove -y docker docker-engine docker.io containerd runc
sudo apt-get update
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

docker run -d --restart=unless-stopped \
  -p 80:80 -p 443:443 \
  -e CATTLE_BOOTSTRAP_PASSWORD=${RANCHER_PASSWORD} \
  -v /root/rancher:/var/lib/rancher \
  --privileged \
  --name rancher-server \
  rancher/rancher:latest \
  --acme-domain ${RANCHER_DOMAIN}