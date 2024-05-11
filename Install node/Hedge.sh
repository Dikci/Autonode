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

cd $HOME && mkdir $HOME/go/bin/
wget https://ss-t.hedge.nodestake.org/hedged
chmod +c hedged
mv hedged $HOME/go/bin/

hedged config chain-id berberis-1

echo -e Your Node Name
read MONIKER
hedged init "$MONIKER" --chain-id=berberis-1

curl -s  "https://raw.githubusercontent.com/111STAVR111/props/main/Hedge/genesis.json" > ~/.hedge/config/genesis.json
wget -O $HOME/.hedge/config/addrbook.json "https://raw.githubusercontent.com/111STAVR111/props/main/Hedge/addrbook.json"

sed -i.bak -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0uhedge\"/;" ~/.hedge/config/app.toml
external_address=$(wget -qO- eth0.me) 
sed -i.bak -e "s/^external_address *=.*/external_address = \"$external_address:26656\"/" $HOME/.hedge/config/config.toml
peers=""
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" $HOME/.hedge/config/config.toml
seeds=""
sed -i.bak -e "s/^seeds =.*/seeds = \"$seeds\"/" $HOME/.hedge/config/config.toml
sed -i 's/max_num_inbound_peers =.*/max_num_inbound_peers = 50/g' $HOME/.hedge/config/config.toml
sed -i 's/max_num_outbound_peers =.*/max_num_outbound_peers = 50/g' $HOME/.hedge/config/config.toml
pruning="custom"
pruning_keep_recent="1000"
pruning_keep_every="0"
pruning_interval="100"
sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" $HOME/.hedge/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" $HOME/.hedge/config/app.toml
sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"$pruning_keep_every\"/" $HOME/.hedge/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" $HOME/.hedge/config/app.toml
indexer="null" &&
sed -i -e "s/^indexer *=.*/indexer = \"$indexer\"/" $HOME/.hedge/config/config.toml


SNAP_NAME=$(curl -s https://ss-t.hedge.nodestake.org/ | egrep -o ">20.*\.tar.lz4" | tr -d ">")
curl -o - -L https://ss-t.hedge.nodestake.org/${SNAP_NAME}  | lz4 -c -d - | tar -x -C $HOME/.hedge
mv $HOME/.hedge/priv_validator_state.json.backup $HOME/.hedge/data/priv_validator_state.json

sudo tee /etc/systemd/system/hedged.service > /dev/null <<EOF
[Unit]
Description=hedged test
After=network-online.target

[Service]
User=$USER
ExecStart=$(which hedged) start
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable hedged
sudo systemctl start hedged
