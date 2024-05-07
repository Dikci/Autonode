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
mkdir -p $HOME/entrypoint && cd entrypoint
wget -O entrypointd https://github.com/entrypoint-zone/testnets/releases/download/v1.3.0/entrypointd-1.3.0-linux-amd64
chmod +x entrypointd
cp entrypointd $HOME/go/bin/entrypointd

entrypointd config node tcp://localhost:${ENTRY_PORT}657
entrypointd config keyring-backend os
entrypointd config chain-id entrypoint-pubtest-2

echo -e Your Node Name
read MONIKER
entrypointd init "$MONIKER" --chain-id entrypoint-pubtest-2

wget -O $HOME/.entrypoint/config/genesis.json https://testnet-files.itrocket.net/entrypoint/genesis.json
wget -O $HOME/.entrypoint/config/addrbook.json https://testnet-files.itrocket.net/entrypoint/addrbook.json

SEEDS="e1b2eddac829b1006eb6e2ddbfc9199f212e505f@entrypoint-testnet-seed.itrocket.net:34656"
PEERS="7048ee28300ffa81103cd24b2af3d1af0c378def@entrypoint-testnet-peer.itrocket.net:34656,05419a6f8cc137c4bb2d717ed6c33590aaae022d@213.133.100.172:26878,f7af71e7f32516f005192b21f1a83ca3f4fef4da@142.132.202.92:32256,684bf9a7b05588932994e05f49786db39c36a3e9@[2a01:4f8:a0:5448::2]:14856,ba2648fe305c01c5276bf5bba2dffc2053e6bcb8@95.217.40.230:22226,a1583f1ba0f0f8b91bd163110b0bfd709604b266@65.108.206.118:61256,95aaf4a31bf4fafd65ecac658eb3170ce501b6ad@65.109.114.178:29656,81bf2ade773a30eccdfee58a041974461f1838d8@185.107.68.148:26656,b91b03c8e7089c265b14dba36c5a61da6ea40f4c@37.120.191.47:61056,cb3e84e80679b0f62cab4f93d33658ba7624b907@194.60.201.251:26656,6e38397e09a2755841e2f350ba1ff8883a66551a@[2a01:4f9:4a:2864::2]:11556"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.entrypoint/config/config.toml

sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.entrypoint/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.entrypoint/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.entrypoint/config/app.toml

sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0.01ibc/8A138BC76D0FB2665F8937EC2BF01B9F6A714F6127221A0E155106A45E09BCC5"|g' $HOME/.entrypoint/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.entrypoint/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.entrypoint/config/config.toml


entrypointd tendermint unsafe-reset-all --home $HOME/.entrypoint
if curl -s --head curl https://testnet-files.itrocket.net/entrypoint/snap_entrypoint.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
  curl https://testnet-files.itrocket.net/entrypoint/snap_entrypoint.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.entrypoint
    else
  echo no have snap
fi

sudo tee /etc/systemd/system/entrypointd.service > /dev/null <<EOF
[Unit]
Description=Entrypoint node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/.entrypoint
ExecStart=$(which entrypointd) start --home $HOME/.entrypoint
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl start entrypointd
