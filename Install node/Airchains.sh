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
echo "export AIRCHAIN_CHAIN_ID="junction"" >> $HOME/.bash_profile
echo "export AIRCHAIN_PORT="19"" >> $HOME/.bash_profile
source $HOME/.bash_profile

cd $HOME
wget -O junctiond https://github.com/airchains-network/junction/releases/download/v0.1.0/junctiond
chmod +x junctiond
mv junctiond $HOME/go/bin/

echo -e Your Node Name
read MONIKER
junctiond init "$MONIKER" --chain-id $AIRCHAIN_CHAIN_ID 
sed -i -e "s|^node *=.*|node = \"tcp://localhost:${AIRCHAIN_PORT}657\"|" $HOME/.junction//config/client.toml

wget -O $HOME/.junction/config/genesis.json https://testnet-files.itrocket.net/airchains/genesis.json
wget -O $HOME/.junction/config/addrbook.json https://testnet-files.itrocket.net/airchains/addrbook.json

SEEDS="04e2fdd6ec8f23729f24245171eaceae5219aa91@airchains-testnet-seed.itrocket.net:19656"
PEERS="47f61921b54a652ca5241e2a7fc4ed8663091e89@airchains-testnet-peer.itrocket.net:19656,aeaf101d54d47f6c99b4755983b64e8504f6132d@65.21.202.124:28656,df2a56a208821492bd3d04dd2e91672657c79325@158.220.126.137:27656,82af620ee9eeb2d2902ae66188eb4aa163ca8562@135.181.35.159:63656,f315edae9ff8543c50e764627a6495dfdaceb3bb@37.60.224.165:63656,c2e70f94ed3f7fa027ffad7f051c4d4688be1ee6@195.26.255.211:10056,264493e01774cccdb9baabee4af7146acbec67f2@65.21.193.80:63656,ed9e33a22fc8ee8254bb616c5ba71645345af9f0@207.180.241.242:63656,e78a440c57576f3743e6aa9db00438462980927e@5.161.199.115:26656,e3f6f7701541bd2ea183a34b061e33bfaf69ae3d@144.91.69.202:63656,613a65fe67918a5912f0cc22ef535ed1a8f0e824@65.109.112.148:4476"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.junction/config/config.toml
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.junction/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.junction/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.junction/config/app.toml
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0.001amf"|g' $HOME/.junction/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.junction/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.junction/config/config.toml

junctiond tendermint unsafe-reset-all --home $HOME/.junction
if curl -s --head curl https://testnet-files.itrocket.net/airchains/snap_airchains.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
  curl https://testnet-files.itrocket.net/airchains/snap_airchains.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.junction
    else
  echo no have snap
fi

sudo tee /etc/systemd/system/junctiond.service > /dev/null <<EOF
[Unit]
Description=Airchains node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/.junction
ExecStart=$(which junctiond) start --home $HOME/.junction
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable junctiond
sudo systemctl start junctiond
