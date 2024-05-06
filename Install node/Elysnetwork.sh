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

cd && rm -rf elys
git clone https://github.com/elys-network/elys
cd elys
git checkout v0.30.0

ROCKSDB=1 LD_LIBRARY_PATH=/usr/local/lib make install

go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest

elysd config chain-id elystestnet-1
elysd config keyring-backend test
elysd config node tcp://localhost:22057

echo -e Your Node Name
read MONIKER
elysd init "$MONIKER" --chain-id elystestnet-1

curl -L https://snapshots-testnet.nodejumper.io/elys-testnet/genesis.json > $HOME/.elys/config/genesis.json
curl -L https://snapshots-testnet.nodejumper.io/elys-testnet/addrbook.json > $HOME/.elys/config/addrbook.json

sed -i -e 's|^seeds *=.*|seeds = "cdf9ae8529aa00e6e6703b28f3dcfdd37e07b27c@37.187.154.66:26656,86987eeff225699e67a6543de3622b8a986cce28@91.183.62.162:26656,ae22b82b1dc34fa0b1a64854168692310f562136@198.27.74.140:26656,61284a4d71cd3a33771640b42f40b2afda389a1e@5.101.138.254:26656,ae7191b2b922c6a59456588c3a262df518b0d130@elys-testnet-seed.itrocket.net:54656,609c64cc50fb4ebbe7cae3347545d3950ea2c018@65.108.195.29:23656,0977dd5475e303c99b66eaacab53c8cc28e49b05@elys-testnet-peer.itrocket.net:38656"|' $HOME/.elys/config/config.toml

sed -i -e 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.01uelys,0.01ibc/2180E84E20F5679FCC760D8C165B60F42065DEF7F46A72B447CFF1B7DC6C0A65,0.01ibc/E2D2F6ADCC68AA3384B2F5DFACCA437923D137C14E86FB8A10207CF3BED0C8D4"|' $HOME/.elys/config/app.toml

sed -i \
  -e 's|^pruning *=.*|pruning = "custom"|' \
  -e 's|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|' \
  -e 's|^pruning-interval *=.*|pruning-interval = "17"|' \
  $HOME/.elys/config/app.toml

sed -i 's|^network *=.*|network = "signet"|g' $HOME/.babylond/config/app.toml


curl "https://snapshots-testnet.nodejumper.io/elys-testnet/elys-testnet_latest.tar.lz4" | lz4 -dc - | tar -xf - -C "$HOME/.elys"

sudo tee /etc/systemd/system/elysd.service > /dev/null << EOF
[Unit]
Description=Elys Network node service
After=network-online.target
[Service]
User=$USER
ExecStart=$(which elysd) start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable elysd.service

sudo systemctl start elysd.service
