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
curl -s https://snapshots-testnet.nodejumper.io/arkeonetwork-testnet/arkeod > arkeod
chmod +x arkeod
mkdir -p $HOME/go/bin/
mv arkeod $HOME/go/bin/

make install

go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest

arkeod config chain-id arkeo
arkeod config keyring-backend test
arkeod config node tcp://localhost:26657

echo -e Your Node Name
read MONIKER
arkeod init "$MONIKER" --chain-id arkeo

curl -L https://snapshots-testnet.nodejumper.io/arkeonetwork-testnet/genesis.json > $HOME/.arkeo/config/genesis.json
curl -L https://snapshots-testnet.nodejumper.io/arkeonetwork-testnet/addrbook.json > $HOME/.arkeo/config/addrbook.json

sed -i -e 's|^seeds *=.*|seeds = "20e1000e88125698264454a884812746c2eb4807@seeds.lavenderfive.com:22856"|' $HOME/.arkeo/config/config.toml

sed -i.bak -e "s%^proxy_app = \\"tcp://127.0.0.1:26658\\"%proxy_app = \\"tcp://127.0.0.1:$PROXY_APP_PORT\\"%; s%^laddr = \\"tcp://127.0.0.1:26657\\"%laddr = \\"tcp://127.0.0.1:$LADDR_PORT\\"%; s%^pprof_laddr = \\"localhost:6060\\"%pprof_laddr = \\"localhost:$LADDR_P2P_PORT\\"%; s%^laddr = \\"tcp://0.0.0.0:26656\\"%laddr = \\"tcp://0.0.0.0:$PPROF_LADDR_PORT\\"%; s%^prometheus_listen_addr = \\":26660\\"%prometheus_listen_addr = \\":$PROMETHEUS_PORT\\"%" $HOME/.arkeo/config/config.toml && sed -i.bak -e "s%^address = \\"0.0.0.0:9090\\"%address = \\"0.0.0.0:$GRPC_PORT\\"%; s%^address = \\"0.0.0.0:9091\\"%address = \\"0.0.0.0:$GRPC_WEB_PORT\\"%; s%^address = \\"tcp://0.0.0.0:1317\\"%address = \\"tcp://0.0.0.0:$API_PORT\\"%" $HOME/.arkeo/config/app.toml && sed -i.bak -e "s%^node = \\"tcp://localhost:26657\\"%node = \\"tcp://localhost:$LADDR_PORT\\"%" $HOME/.arkeo/config/client.toml

sed -i -e 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.01uarkeo"|' $HOME/.arkeo/config/app.toml

sed -i \
  -e 's|^pruning *=.*|pruning = "custom"|' \
  -e 's|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|' \
  -e 's|^pruning-interval *=.*|pruning-interval = "17"|' \
  $HOME/.arkeo/config/app.toml

curl "https://snapshots-testnet.nodejumper.io/arkeonetwork-testnet/arkeonetwork-testnet_latest.tar.lz4" | lz4 -dc - | tar -xf - -C "$HOME/.arkeo"

sudo tee /etc/systemd/system/arkeod.service > /dev/null << EOF
[Unit]
Description=Arkeo Network node service
After=network-online.target
[Service]
User=$USER
ExecStart=$(which arkeod) start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable arkeod.service

sudo systemctl start arkeod.service
