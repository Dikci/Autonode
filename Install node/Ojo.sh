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

cd && rm -rf ojo
git clone https://github.com/ojo-network/ojo
cd ojo
git checkout v0.1.2

make install

go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest

ojod config chain-id ojo-devnet
ojod config keyring-backend test
ojod config node tcp://localhost:21657

echo -e Your Node Name
read MONIKER
ojod init "$MONIKER" --chain-id ojo-devnet

curl -L https://snapshots-testnet.nodejumper.io/ojo-testnet/genesis.json > $HOME/.ojo/config/genesis.json
curl -L https://snapshots-testnet.nodejumper.io/ojo-testnet/addrbook.json > $HOME/.ojo/config/addrbook.json

sed -i -e 's|^seeds *=.*|seeds = "7186f24ace7f4f2606f56f750c2684d387dc39ac@ojo-testnet-seed.itrocket.net:12656"|' $HOME/.ojo/config/config.toml

sed -i.bak -e "s|^proxy_app = \\\"tcp://127.0.0.1:26658\\\"|proxy_app = \\\"tcp://127.0.0.1:$PROXY_APP_PORT\\\"|; s|^laddr = \\\"tcp://127.0.0.1:26657\\\"|laddr = \\\"tcp://127.0.0.1:$LADDR_PORT\\\"|; s|^pprof_laddr = \\\"localhost:6060\\\"|pprof_laddr = \\\"localhost:$LADDR_P2P_PORT\\\"|; s|^laddr = \\\"tcp://0.0.0.0:26656\\\"|laddr = \\\"tcp://0.0.0.0:$PPROF_LADDR_PORT\\\"|; s|^prometheus_listen_addr = \\\":26660\\\"|prometheus_listen_addr = \\\":$PROMETHEUS_PORT\\\"|" $HOME/.ojo/config/config.toml && sed -i.bak -e "s|^address = \\\"0.0.0.0:9090\\\"|address = \\\"0.0.0.0:$GRPC_PORT\\\"|; s|^address = \\\"0.0.0.0:9091\\\"|address = \\\"0.0.0.0:$GRPC_WEB_PORT\\\"|; s|^address = \\\"tcp://0.0.0.0:1317\\\"|address = \\\"tcp://0.0.0.0:$API_PORT\\\"|" $HOME/.ojo/config/app.toml
sed -i -e 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.01uojo"|' $HOME/.ojo/config/app.toml

sed -i \
  -e 's|^pruning *=.*|pruning = "custom"|' \
  -e 's|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|' \
  -e 's|^pruning-interval *=.*|pruning-interval = "17"|' \
  $HOME/.ojo/config/app.toml


curl "https://snapshots-testnet.nodejumper.io/ojo-testnet/ojo-testnet_latest.tar.lz4" | lz4 -dc - | tar -xf - -C "$HOME/.ojo"

sudo tee /etc/systemd/system/ojod.service > /dev/null << EOF
[Unit]
Description=Ojo node service
After=network-online.target
[Service]
User=$USER
ExecStart=$(which ojod) start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable ojod.service

sudo systemctl start ojod.service