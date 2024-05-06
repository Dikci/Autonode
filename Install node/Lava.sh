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

cd && rm -rf lava
git clone https://github.com/lavanet/lava
cd lava
git checkout v2.0.0

export LAVA_BINARY=lavad
make install

go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest

lavad config chain-id lava-testnet-2
lavad config keyring-backend test
lavad config node tcp://localhost:19957

echo -e Your Node Name
read MONIKER
lavad init "$MONIKER" --chain-id lava-testnet-2

curl -L https://snapshots-testnet.nodejumper.io/lava-testnet/genesis.json > $HOME/.lava/config/genesis.json
curl -L https://snapshots-testnet.nodejumper.io/lava-testnet/addrbook.json > $HOME/.lava/config/addrbook.json

sed -i -e 's|^seeds *=.*|seeds = "3a445bfdbe2d0c8ee82461633aa3af31bc2b4dc0@prod-pnet-seed-node.lavanet.xyz:26656,e593c7a9ca61f5616119d6beb5bd8ef5dd28d62d@prod-pnet-seed-node2.lavanet.xyz:26656,ade4d8bc8cbe014af6ebdf3cb7b1e9ad36f412c0@testnet-seeds.polkachu.com:19956"|' $HOME/.lava/config/config.toml

sed -i.bak -e "s|^proxy_app = \\\"tcp://127.0.0.1:26658\\\"|proxy_app = \\\"tcp://127.0.0.1:$PROXY_APP_PORT\\\"|; s|^laddr = \\\"tcp://127.0.0.1:26657\\\"|laddr = \\\"tcp://127.0.0.1:$LADDR_PORT\\\"|; s|^pprof_laddr = \\\"localhost:6060\\\"|pprof_laddr = \\\"localhost:$LADDR_P2P_PORT\\\"|; s|^laddr = \\\"tcp://0.0.0.0:26656\\\"|laddr = \\\"tcp://0.0.0.0:$PPROF_LADDR_PORT\\\"|; s|^prometheus_listen_addr = \\\":26660\\\"|prometheus_listen_addr = \\\":$PROMETHEUS_PORT\\\"|" $HOME/.lava/config/config.toml && sed -i.bak -e "s|^address = \\\"0.0.0.0:9090\\\"|address = \\\"0.0.0.0:$GRPC_PORT\\\"|; s|^address = \\\"0.0.0.0:9091\\\"|address = \\\"0.0.0.0:$GRPC_WEB_PORT\\\"|; s|^address = \\\"tcp://0.0.0.0:1317\\\"|address = \\\"tcp://0.0.0.0:$API_PORT\\\"|" $HOME/.lava/config/app.toml
sed -i -e 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.000001ulava"|' $HOME/.lava/config/app.toml

sed -i \
  -e 's|^pruning *=.*|pruning = "custom"|' \
  -e 's|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|' \
  -e 's|^pruning-interval *=.*|pruning-interval = "17"|' \
  $HOME/.lava/config/app.toml

curl "https://snapshots-testnet.nodejumper.io/lava-testnet/lava-testnet_latest.tar.lz4" | lz4 -dc - | tar -xf - -C "$HOME/.lava"

sudo tee /etc/systemd/system/lavad.service > /dev/null << EOF
[Unit]
Description=Lava node service
After=network-online.target
[Service]
User=$USER
ExecStart=$(which lavad) start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable lavad.service

sudo systemctl start lavad.service
