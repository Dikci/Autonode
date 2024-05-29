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
rm -rf elys
git clone https://github.com/elys-network/elys.git
cd elys
git checkout v0.32.0
make install

elysd config node tcp://localhost:${ELYS_PORT}657
elysd config keyring-backend os
elysd config chain-id elystestnet-1

echo -e Your Node Name
read MONIKER
elysd init "$MONIKER" --chain-id elystestnet-1

wget -O $HOME/.elys/config/genesis.json https://testnet-files.itrocket.net/elys/genesis.json
wget -O $HOME/.elys/config/addrbook.json https://testnet-files.itrocket.net/elys/addrbook.json

SEEDS="ae7191b2b922c6a59456588c3a262df518b0d130@elys-testnet-seed.itrocket.net:54656"
PEERS="0977dd5475e303c99b66eaacab53c8cc28e49b05@elys-testnet-peer.itrocket.net:38656,4d056b4c51d331078b258195a199bba8f6299483@185.169.252.221:26656,b499374d940d049cee2ab7400690f4663977b637@213.199.41.82:22056,247d4e5c98d7debc566ff1f03df2cffe4934c4c8@75.119.149.23:26656,38bd0be88352b8bc63c06b34541e7b10b2937f10@109.199.106.37:22056,4569f9f05e10deff7a8ab0a9a30bd33f1e2248dc@152.53.2.133:22056,60939e5760138c1db7cd3c587780ab6a643638e1@65.109.104.111:56102,ae22b82b1dc34fa0b1a64854168692310f562136@147.135.104.10:26656,bbf8ef70a32c3248a30ab10b2bff399e73c6e03c@65.21.198.100:21256,cdf9ae8529aa00e6e6703b28f3dcfdd37e07b27c@147.135.9.107:26656,a97a52a34101fcd7d3186fa5cbcff32b12e6332e@15.235.204.150:28856"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.elys/config/config.toml

sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.elys/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.elys/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.elys/config/app.toml

sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0.0018ibc/2180E84E20F5679FCC760D8C165B60F42065DEF7F46A72B447CFF1B7DC6C0A65,0.00025ibc/E2D2F6ADCC68AA3384B2F5DFACCA437923D137C14E86FB8A10207CF3BED0C8D4,0.00025uelys"|g' $HOME/.elys/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.elys/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.elys/config/config.toml


elysd tendermint unsafe-reset-all --home $HOME/.elys
if curl -s --head curl https://testnet-files.itrocket.net/elys/snap_elys.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
  curl https://testnet-files.itrocket.net/elys/snap_elys.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.elys
    else
  echo no have snap
fi

sudo tee /etc/systemd/system/elysd.service > /dev/null <<EOF
[Unit]
Description=Elys node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/.elys
ExecStart=$(which elysd) start --minimum-gas-prices="0.0018ibc/2180E84E20F5679FCC760D8C165B60F42065DEF7F46A72B447CFF1B7DC6C0A65,0.00025ibc/E2D2F6ADCC68AA3384B2F5DFACCA437923D137C14E86FB8A10207CF3BED0C8D4,0.00025uelys" --home $HOME/.elys
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable elysd
sudo systemctl start elysd
