#!/bin/bash
sudo apt -q update
sudo apt -qy install curl git jq lz4 build-essential
sudo apt -qy upgrade
sudo apt install make clang pkg-config lz4 libssl-dev build-essential git jq ncdu bsdmainutils htop -y
sudo apt install curl -y

VERSION=1.21.6
wget -O go.tar.gz https://go.dev/dl/go$VERSION.linux-amd64.tar.gz
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go.tar.gz && rm go.tar.gz
echo 'export GOROOT=/usr/local/go' >> $HOME/.bash_profile
echo 'export GOPATH=$HOME/go' >> $HOME/.bash_profile
echo 'export GO111MODULE=on' >> $HOME/.bash_profile
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile && . $HOME/.bash_profile
go version

cd $HOME
curl -s https://github.com/entrypoint-zone/testnets/releases/download/v1.3.0/entrypointd-1.3.0-linux-amd64 > entrypointd
chmod +x entrypointd
mkdir -p $HOME/go/bin/
mv entrypointd $HOME/go/bin/

entrypointd config chain-id entrypoint-pubtest-2
entrypointd config keyring-backend test
entrypointd config node tcp://localhost:26657

echo -e Your Node Name
read MONIKER
entrypointd init "$MONIKER" --chain-id entrypoint-pubtest-2

curl -L https://snapshots-testnet.nodejumper.io/entrypoint-testnet/genesis.json > $HOME/.entrypoint/config/genesis.json
curl -L https://snapshots-testnet.nodejumper.io/entrypoint-testnet/addrbook.json > $HOME/.entrypoint/config/addrbook.json

sed -i -e 's|^seeds *=.*|seeds = "e1b2eddac829b1006eb6e2ddbfc9199f212e505f@entrypoint-testnet-seed.itrocket.net:34656,7048ee28300ffa81103cd24b2af3d1af0c378def@entrypoint-testnet-peer.itrocket.net:34656,05419a6f8cc137c4bb2d717ed6c33590aaae022d@213.133.100.172:26878,f7af71e7f32516f005192b21f1a83ca3f4fef4da@142.132.202.92:32256"|' $HOME/.entrypoint/config/config.toml

sed -i -e 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.01ibc/8A138BC76D0FB2665F8937EC2BF01B9F6A714F6127221A0E155106A45E09BCC5"|' $HOME/.entrypoint/config/app.toml

sed -i \
  -e 's|^pruning *=.*|pruning = "custom"|' \
  -e 's|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|' \
  -e 's|^pruning-interval *=.*|pruning-interval = "17"|' \
  $HOME/.entrypoint/config/app.toml

curl "https://snapshots-testnet.nodejumper.io/entrypoint-testnet/entrypoint-testnet_latest.tar.lz4" | lz4 -dc - | tar -xf - -C "$HOME/.entrypoint"

sudo tee /etc/systemd/system/entrypointd.service > /dev/null << EOF
[Unit]
Description=EntryPoint node service
After=network-online.target
[Service]
User=$USER
ExecStart=$(which entrypointd) start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable entrypointd.service

sudo systemctl start entrypointd.service
