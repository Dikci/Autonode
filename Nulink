#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo -e "${YELLOW}This creak was written by Dikci${NC}"

apt install ufw -y

ufw allow ssh
ufw allow https
ufw allow http
ufw allow 9151
ufw enable

sudo apt-get update -q

sudo apt-get install -qy ca-certificates curl gnupg

sudo install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -q

sudo apt-get install -qy docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

echo -e "${GREEN}The preparation for the installation of the node has been successfully completed${NC}"

wget https://gethstore.blob.core.windows.net/builds/geth-linux-amd64-1.10.23-d901d853.tar.gz

tar -xvzf geth-linux-amd64-1.10.23-d901d853.tar.gz

cd geth-linux-amd64-1.10.23-d901d853/

./geth account new --keystore ./keystore

docker pull nulink/nulink:latest

cd /root

mkdir nulink

cp /root/geth-linux-amd64-1.10.23-d901d853/keystore/* /root/nulink

chmod -R 777 /root/nulink

echo -e "Come up with a password for the vault"
read PASSWORD_SAFE
export NULINK_KEYSTORE_PASSWORD="$PASSWORD_SAFE"

echo -e "Enter the worker password"
read PASSWORD_WORKER
export NULINK_OPERATOR_ETH_PASSWORD="$PASSWORD_WORKER"

echo -e "${RED}THE NAME OF YOUR UTC FILE IS PRIVATE${NC}"
read NAME_FILE_PRIVATE

echo -e "${RED}YOUR WORKER'S ADDRESS${NC}"
read WORKER_ADDRESS

docker run -it --rm \
-p 9151:9151 \
-v /root/nulink:/code \
-v /root/nulink:/home/circleci/.local/share/nulink \
-e NULINK_KEYSTORE_PASSWORD \
nulink/nulink nulink ursula init \
--signer keystore:///code/UTC--"$NAME_FILE_PRIVATE" \
--eth-provider https://bsc-testnet.publicnode.com \
--network horus \
--payment-provider https://bsc-testnet.publicnode.com \
--payment-network bsc_testnet \
--operator-address "$WORKER_ADDRESS" \
--max-gas-price 10000000000


docker run --restart on-failure -d \
--name ursula \
-p 9151:9151 \
-v /root/nulink:/code \
-v /root/nulink:/home/circleci/.local/share/nulink \
-e NULINK_KEYSTORE_PASSWORD \
-e NULINK_OPERATOR_ETH_PASSWORD \
nulink/nulink nulink ursula run --no-block-until-ready

docker logs -f ursula
