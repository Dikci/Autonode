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

echo "export WALLET="wallet"" >> $HOME/.bash_profile
echo "export MONIKER="test"" >> $HOME/.bash_profile
echo "export OG_CHAIN_ID="zgtendermint_9000-1"" >> $HOME/.bash_profile
echo "export OG_PORT="47"" >> $HOME/.bash_profile
source $HOME/.bash_profile

cd $HOME
rm -rf 0g-evmos
git clone https://github.com/0glabs/0g-evmos.git
cd 0g-evmos
git checkout v1.0.0-testnet
make build
mv $HOME/0g-evmos/build/evmosd $HOME/go/bin/

evmosd config node tcp://localhost:${OG_PORT}657
evmosd config keyring-backend os
evmosd config chain-id zgtendermint_9000-1

echo -e Your Node Name
read MONIKER
evmosd init "$MONIKER" --chain-id zgtendermint_9000-1

wget -O $HOME/.evmosd/config/genesis.json https://testnet-files.itrocket.net/og/genesis.json
wget -O $HOME/.evmosd/config/addrbook.json https://testnet-files.itrocket.net/og/addrbook.json

SEEDS="c9b8e7e220178817c84c7268e186b231bc943671@og-testnet-seed.itrocket.net:47656"
PEERS=""
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.evmosd/config/config.toml
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.evmosd/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.evmosd/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.evmosd/config/app.toml
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0agnet"|g' $HOME/.evmosd/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.evmosd/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.evmosd/config/config.toml


evmosd tendermint unsafe-reset-all --home $HOME/.evmosd
if curl -s --head curl https://testnet-files.itrocket.net/og/snap_og.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
  curl https://testnet-files.itrocket.net/og/snap_og.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.evmosd
    else
  echo no have snap
fi

sudo tee /etc/systemd/system/evmosd.service > /dev/null <<EOF
[Unit]
Description=Og node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/.evmosd
ExecStart=$(which evmosd) start --home $HOME/.evmosd
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable evmosd
sudo systemctl start evmosd
