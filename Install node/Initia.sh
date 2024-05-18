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

cd && rm -rf initia
git clone https://github.com/initia-labs/initia
cd initia
git checkout v0.2.14
make install


echo -e Your Node Name
read MONIKER
initiad init "$MONIKER" --chain-id initiation-1

curl -L https://snapshots-testnet.nodejumper.io/initia-testnet/genesis.json > $HOME/.initia/config/genesis.json
curl -L https://snapshots-testnet.nodejumper.io/initia-testnet/addrbook.json > $HOME/.initia/config/addrbook.json

SEEDS="cd69bcb00a6ecc1ba2b4a3465de4d4dd3e0a3db1@initia-testnet-seed.itrocket.net:51656"
PEERS="aee7083ab11910ba3f1b8126d1b3728f13f54943@initia-testnet-peer.itrocket.net:11656,a8f3e2d4197b34c11228809d0f785a952905b262@43.131.12.180:26656,429f7db154bb139ab3f8f2a8760914e255337a0f@150.109.235.74:26656,767fdcfdb0998209834b929c59a2b57d474cc496@207.148.114.112:26656,9c0417a610846b3a7fd27ac3afbf3b52b527807c@43.157.82.7:26656,633775ca828f8fc7f5c689a8c950664e7f198223@184.174.32.188:26656,9f0ae0790fae9a2d327d8d6fe767b73eb8aa5c48@176.126.87.65:22656,7317b8c930c52a8183590166a7b5c3599f40d4db@185.187.170.186:26656,35e4b461b38107751450af25e03f5a61e7aa0189@43.133.229.136:26656,6a64518146b8c902ef5930dfba00fe61a15ec176@43.133.44.152:26656,a45314423c15f024ff850fad7bd031168d937931@162.62.219.188:26656"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.initia/config/config.toml
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.initia/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.initia/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.initia/config/app.toml
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0.15uinit,0.01uusdc"|g' $HOME/.initia/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.initia/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.initia/config/config.toml


initiad tendermint unsafe-reset-all --home $HOME/.initia
if curl -s --head curl https://testnet-files.itrocket.net/initia/snap_initia.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
  curl https://testnet-files.itrocket.net/initia/snap_initia.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.initia
    else
  echo no have snap
fi

sudo tee /etc/systemd/system/initiad.service > /dev/null <<EOF
[Unit]
Description=Initia node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/.initia
ExecStart=$(which initiad) start --home $HOME/.initia
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable initiad

sudo systemctl start initiad
