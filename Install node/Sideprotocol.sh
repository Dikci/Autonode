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

cd && rm -rf sidechain
git clone https://github.com/sideprotocol/sidechain.git
cd sidechain
git checkout v0.7.0-rc2

make install

go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest

sided config chain-id side-testnet-3
sided config keyring-backend test
sided config node tcp://localhost:26357

echo -e Your Node Name
read MONIKER
babylond init "$MONIKER" --chain-id bbn-test-3

curl -L https://snapshots-testnet.nodejumper.io/side-testnet/genesis.json > $HOME/.side/config/genesis.json
curl -L https://snapshots-testnet.nodejumper.io/side-testnet/addrbook.json > $HOME/.side/config/addrbook.json

sed -i -e 's|^seeds *=.*|seeds = "6decdc5565bf5232cdf5597a7784bfe828c32277@158.220.126.137:11656,e9ee4fb923d5aab89207df36ce660ff1b882fc72@136.243.33.177:21656,9c14080752bdfa33f4624f83cd155e2d3976e303@side-testnet-seed.itrocket.net:45656"|' $HOME/.side/config/config.toml

sed -i.bak -e "s|^proxy_app = \\\"tcp://127.0.0.1:26658\\\"|proxy_app = \\\"tcp://127.0.0.1:$PROXY_APP_PORT\\\"|; s|^laddr = \\\"tcp://127.0.0.1:26657\\\"|laddr = \\\"tcp://127.0.0.1:$LADDR_PORT\\\"|; s|^pprof_laddr = \\\"localhost:6060\\\"|pprof_laddr = \\\"localhost:$LADDR_P2P_PORT\\\"|; s|^laddr = \\\"tcp://0.0.0.0:26656\\\"|laddr = \\\"tcp://0.0.0.0:$PPROF_LADDR_PORT\\\"|; s|^prometheus_listen_addr = \\\":26660\\\"|prometheus_listen_addr = \\\":$PROMETHEUS_PORT\\\"|" $HOME/.side/config/config.toml && sed -i.bak -e "s|^address = \\\"0.0.0.0:9090\\\"|address = \\\"0.0.0.0:$GRPC_PORT\\\"|; s|^address = \\\"0.0.0.0:9091\\\"|address = \\\"0.0.0.0:$GRPC_WEB_PORT\\\"|; s|^address = \\\"tcp://0.0.0.0:1317\\\"|address = \\\"tcp://0.0.0.0:$API_PORT\\\"|" $HOME/.side/config/app.toml
sed -i -e 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.005uside"|' $HOME/.side/config/app.toml

sed -i \
  -e 's|^pruning *=.*|pruning = "custom"|' \
  -e 's|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|' \
  -e 's|^pruning-interval *=.*|pruning-interval = "17"|' \
  $HOME/.side/config/app.toml

curl "https://snapshots-testnet.nodejumper.io/side-testnet/side-testnet_latest.tar.lz4" | lz4 -dc - | tar -xf - -C "$HOME/.side"

sudo tee /etc/systemd/system/sided.service > /dev/null << EOF
[Unit]
Description=Side node service
After=network-online.target
[Service]
User=$USER
ExecStart=$(which sided) start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable sided.service

sudo systemctl start sided.service
