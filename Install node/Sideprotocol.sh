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
rm -rf side
git clone https://github.com/sideprotocol/side.git
cd side
git checkout v0.8.1

make build

mkdir -p $HOME/.side/cosmovisor/genesis/bin
mv build/sided $HOME/.side/cosmovisor/genesis/bin/
rm -rf build

sudo ln -s $HOME/.side/cosmovisor/genesis $HOME/.side/cosmovisor/current -f
sudo ln -s $HOME/.side/cosmovisor/current/bin/sided /usr/local/bin/sided -f

go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@v1.5.0

sided config chain-id S2-testnet-2
sided config keyring-backend test
sided config node tcp://localhost:17457

echo -e Your Node Name
read MONIKER
sided init "$MONIKER" --chain-id S2-testnet-2

curl -Ls https://snapshots.kjnodes.com/side-testnet/genesis.json > $HOME/.side/config/genesis.json
curl -Ls https://snapshots.kjnodes.com/side-testnet/addrbook.json > $HOME/.side/config/addrbook.json

sed -i -e "s|^seeds *=.*|seeds = \"3f472746f46493309650e5a033076689996c8881@side-testnet.rpc.kjnodes.com:17459\"|" $HOME/.side/config/config.toml

sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"0.005uside\"|" $HOME/.side/config/app.toml

sed -i \
  -e 's|^pruning *=.*|pruning = "custom"|' \
  -e 's|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|' \
  -e 's|^pruning-keep-every *=.*|pruning-keep-every = "0"|' \
  -e 's|^pruning-interval *=.*|pruning-interval = "19"|' \
  $HOME/.side/config/app.toml

curl -L https://snapshots.kjnodes.com/side-testnet/snapshot_latest.tar.lz4 | tar -Ilz4 -xf - -C $HOME/.side
[[ -f $HOME/.side/data/upgrade-info.json ]] && cp $HOME/.side/data/upgrade-info.json $HOME/.side/cosmovisor/genesis/upgrade-info.json

sudo tee /etc/systemd/system/side.service > /dev/null << EOF
[Unit]
Description=side node service
After=network-online.target

[Service]
User=$USER
ExecStart=$(which cosmovisor) run start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
Environment="DAEMON_HOME=$HOME/.side"
Environment="DAEMON_NAME=sided"
Environment="UNSAFE_SKIP_BACKUP=true"
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:$HOME/.side/cosmovisor/current/bin"

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable side.service

sudo systemctl start side.service
