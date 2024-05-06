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

cd $HOME && mkdir -p $HOME/go/bin
curl -L https://github.com/crossfichain/crossfi-node/releases/download/v0.3.0-prebuild3/crossfi-node_0.3.0-prebuild3_linux_amd64.tar.gz > crossfi-node_0.3.0-prebuild3_linux_amd64.tar.gz
tar -xvzf crossfi-node_0.3.0-prebuild3_linux_amd64.tar.gz
chmod +x $HOME/bin/crossfid
mv $HOME/bin/crossfid $HOME/go/bin
rm -rf crossfi-node_0.3.0-prebuild3_linux_amd64.tar.gz readme.md $HOME/bin

go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest

crossfid config chain-id crossfi-evm-testnet-1
crossfid config keyring-backend test
crossfid config node tcp://localhost:26057

echo -e Your Node Name
read MONIKER
crossfid init "$MONIKER" --chain-id crossfi-evm-testnet-1

curl -L https://snapshots-testnet.nodejumper.io/crossfi-testnet/genesis.json > $HOME/.mineplex-chain/config/genesis.json
curl -L https://snapshots-testnet.nodejumper.io/crossfi-testnet/addrbook.json > $HOME/.mineplex-chain/config/addrbook.json

sed -i -e 's|^seeds *=.*|seeds = "89752fa7945a06e972d7d860222a5eeaeab5c357@128.140.70.97:26656,dd83e3c7c4e783f8a46dbb010ec8853135d29df0@crossfi-testnet-seed.itrocket.net:36656"|' $HOME/.mineplex-chain/config/config.toml

sed -i -e 's|^minimum-gas-prices *=.*|minimum-gas-prices = "5000000000mpx"|' $HOME/.mineplex-chain/config/app.toml

sed -i \
  -e 's|^pruning *=.*|pruning = "custom"|' \
  -e 's|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|' \
  -e 's|^pruning-interval *=.*|pruning-interval = "17"|' \
  $HOME/.mineplex-chain/config/app.toml

curl "https://snapshots-testnet.nodejumper.io/crossfi-testnet/crossfi-testnet_latest.tar.lz4" | lz4 -dc - | tar -xf - -C "$HOME/.mineplex-chain"

sudo tee /etc/systemd/system/crossfid.service > /dev/null << EOF
[Unit]
Description=CrossFi node service
After=network-online.target
[Service]
User=$USER
ExecStart=$(which crossfid) start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable crossfid.service

sudo systemctl start crossfid.service
