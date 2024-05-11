#!/bin/bash

sudo apt -q update
sudo apt -qy install curl git jq lz4 build-essential
sudo apt -qy upgrade
sudo apt install make clang pkg-config lz4 libssl-dev build-essential git jq ncdu bsdmainutils htop -y
sudo apt install curl -y

sudo rm -rf /usr/local/go
curl -Ls https://go.dev/dl/go1.22.3.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
eval $(echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee /etc/profile.d/golang.sh)
eval $(echo 'export PATH=$PATH:$HOME/go/bin' | tee -a $HOME/.profile)

mkdir -p $HOME/.swisstronik/cosmovisor/genesis/bin
wget -O $HOME/.swisstronik/cosmovisor/genesis/bin/swisstronikd https://snapshots.kjnodes.com/swisstronik-testnet/swisstronikd_1.0.1-updated-binaries_amd64
chmod +x $HOME/.swisstronik/cosmovisor/genesis/bin/swisstronikd

sudo ln -s $HOME/.swisstronik/cosmovisor/genesis $HOME/.swisstronik/cosmovisor/current -f
sudo ln -s $HOME/.swisstronik/cosmovisor/current/bin/swisstronikd /usr/local/bin/swisstronikd -f

go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@v1.5.0

swisstronikd config chain-id swisstronik_1291-1
swisstronikd config keyring-backend test
swisstronikd config node tcp://localhost:17557

echo -e Your Node Name
read MONIKER
swisstronikd init "$MONIKER" --chain-id swisstronik_1291-1

curl -Ls https://snapshots.kjnodes.com/swisstronik-testnet/genesis.json > $HOME/.swisstronik/config/genesis.json
curl -Ls https://snapshots.kjnodes.com/swisstronik-testnet/addrbook.json > $HOME/.swisstronik/config/addrbook.json

sed -i -e "s|^seeds *=.*|seeds = \"3f472746f46493309650e5a033076689996c8881@swisstronik-testnet.rpc.kjnodes.com:17559\"|" $HOME/.swisstronik/config/config.toml
sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"7uswtr\"|" $HOME/.swisstronik/config/app.toml
sed -i \
  -e 's|^pruning *=.*|pruning = "custom"|' \
  -e 's|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|' \
  -e 's|^pruning-keep-every *=.*|pruning-keep-every = "0"|' \
  -e 's|^pruning-interval *=.*|pruning-interval = "19"|' \
  $HOME/.swisstronik/config/app.toml


curl -L https://snapshots.kjnodes.com/swisstronik-testnet/snapshot_latest.tar.lz4 | tar -Ilz4 -xf - -C $HOME/.swisstronik
[[ -f $HOME/.swisstronik/data/upgrade-info.json ]] && cp $HOME/.swisstronik/data/upgrade-info.json $HOME/.swisstronik/cosmovisor/genesis/upgrade-info.json

sudo tee /etc/systemd/system/swisstronik.service > /dev/null << EOF
[Unit]
Description=swisstronik node service
After=network-online.target

[Service]
User=$USER
ExecStart=$(which cosmovisor) run start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
Environment="DAEMON_HOME=$HOME/.swisstronik"
Environment="DAEMON_NAME=swisstronikd"
Environment="UNSAFE_SKIP_BACKUP=true"
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:$HOME/.swisstronik/cosmovisor/current/bin"

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable swisstronik.service
sudo systemctl start swisstronik.service
