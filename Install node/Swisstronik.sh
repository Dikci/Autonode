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
rm -rf swisstronik-chain
git clone https://github.com/SigmaGmbH/swisstronik-chain swisstronik
cd swisstronik
git submodule update --init --recursive
make build
make install

go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest

swisstronikd config node tcp://localhost:${SWISS_PORT}657
swisstronikd config keyring-backend os
swisstronikd config chain-id swisstronik_1291-1

echo -e Your Node Name
read MONIKER
swisstronikd init "$MONIKER" --chain-id swisstronik_1291-1

wget -O $HOME/.swisstronik/config/genesis.json https://testnet-files.itrocket.net/swisstronik/genesis.json
wget -O $HOME/.swisstronik/config/addrbook.json https://testnet-files.itrocket.net/swisstronik/addrbook.json

SEEDS=""
PEERS="f05c4343d2df801ba05a5ec7bd9954d8728fdb36@swisstronik-testnet-peer.itrocket.net:26656,3c5d5d40f6855050d79e50f7dc408733a040553d@148.113.8.139:26656,b368e2232e4cdec602c96b77505401f94a643847@148.113.1.150:17156,da7875803737641f5c8c0b691cf97d9de06f0ede@148.113.20.157:26656,0c2d883d0259f2992b10b3238e96fdd406ebd0c3@148.113.9.30:20656,2eaea00f234e85b1a157781a69126ab64e85ffc2@148.113.1.87:26656,c5dbced5fef3a5b14d3c3f4613a901d54455da43@141.95.169.103:26656,e147b3723835758bbef2fb7a14349dcdc6290223@148.113.1.198:26656,18963a5fbdc7a1be9eb32436f769ad8796748816@37.59.18.38:26656,c0fa6abe9805a5ddf520aa06384b2ece65a8cb6a@148.113.17.34:26656,0b69dcc4363f30747584579a961b5cacb1c2481e@57.128.202.10:26656"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.swisstronik/config/config.toml

sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.swisstronik/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.swisstronik/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.swisstronik/config/app.toml

sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "7uswtr"|g' $HOME/.swisstronik/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.swisstronik/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.swisstronik/config/config.toml


swisstronikd tendermint unsafe-reset-all --home $HOME/.swisstronik
if curl -s --head curl https://testnet-files.itrocket.net/swisstronik/snap_swisstronik.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
  curl https://testnet-files.itrocket.net/swisstronik/snap_swisstronik.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.swisstronik
    else
  echo no have snap
fi

sudo tee /etc/systemd/system/swisstronikd.service > /dev/null <<EOF
[Unit]
Description=Swisstronik node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/.swisstronik
ExecStart=$(which swisstronikd) start --home $HOME/.swisstronik
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable swisstronikd
sudo systemctl start swisstronikd
