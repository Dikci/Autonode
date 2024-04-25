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
rm -rf seda-chain
git clone https://github.com/sedaprotocol/seda-chain.git
cd seda-chain
git checkout v0.0.7

make build

mkdir -p $HOME/.sedad/cosmovisor/genesis/bin
mv build/sedad $HOME/.sedad/cosmovisor/genesis/bin/
rm -rf build

sudo ln -s $HOME/.sedad/cosmovisor/genesis $HOME/.sedad/cosmovisor/current -f
sudo ln -s $HOME/.sedad/cosmovisor/current/bin/sedad /usr/local/bin/sedad -f

go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest

sedad config chain-id seda-1-testnet
sedad config keyring-backend test
sedad config node tcp://localhost:17357

echo -e Your Node Name
read MONIKER
sedad init "$MONIKER" --chain-id seda-1-testnet

curl -Ls https://snapshots.kjnodes.com/seda-testnet/genesis.json > $HOME/.sedad/config/genesis.json
curl -Ls https://snapshots.kjnodes.com/seda-testnet/addrbook.json > $HOME/.sedad/config/addrbook.json

sed -i -e "s|^seeds *=.*|seeds = \"3f472746f46493309650e5a033076689996c8881@seda-testnet.rpc.kjnodes.com:17359\"|" $HOME/.sedad/config/config.toml

sed -i.bak -e "s|^proxy_app = \\\"tcp://127.0.0.1:26658\\\"|proxy_app = \\\"tcp://127.0.0.1:$PROXY_APP_PORT\\\"|; s|^laddr = \\\"tcp://127.0.0.1:26657\\\"|laddr = \\\"tcp://127.0.0.1:$LADDR_PORT\\\"|; s|^pprof_laddr = \\\"localhost:6060\\\"|pprof_laddr = \\\"localhost:$LADDR_P2P_PORT\\\"|; s|^laddr = \\\"tcp://0.0.0.0:26656\\\"|laddr = \\\"tcp://0.0.0.0:$PPROF_LADDR_PORT\\\"|; s|^prometheus_listen_addr = \\\":26660\\\"|prometheus_listen_addr = \\\":$PROMETHEUS_PORT\\\"|" $HOME/.arkeo/config/config.toml && sed -i.bak -e "s|^address = \\\"0.0.0.0:9090\\\"|address = \\\"0.0.0.0:$GRPC_PORT\\\"|; s|^address = \\\"0.0.0.0:9091\\\"|address = \\\"0.0.0.0:$GRPC_WEB_PORT\\\"|; s|^address = \\\"tcp://0.0.0.0:1317\\\"|address = \\\"tcp://0.0.0.0:$API_PORT\\\"|" $HOME/.arkeo/config/app.toml

sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"100000000000aseda\"|" $HOME/.sedad/config/app.toml

sed -i \
  -e 's|^pruning *=.*|pruning = "custom"|' \
  -e 's|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|' \
  -e 's|^pruning-keep-every *=.*|pruning-keep-every = "0"|' \
  -e 's|^pruning-interval *=.*|pruning-interval = "19"|' \
  $HOME/.sedad/config/app.toml


curl -L https://snapshots.kjnodes.com/seda-testnet/snapshot_latest.tar.lz4 | tar -Ilz4 -xf - -C $HOME/.sedad
[[ -f $HOME/.sedad/data/upgrade-info.json ]] && cp $HOME/.sedad/data/upgrade-info.json $HOME/.sedad/cosmovisor/genesis/upgrade-info.json

sudo tee /etc/systemd/system/seda.service > /dev/null << EOF
[Unit]
Description=seda node service
After=network-online.target

[Service]
User=$USER
ExecStart=$(which cosmovisor) run start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
Environment="DAEMON_HOME=$HOME/.sedad"
Environment="DAEMON_NAME=sedad"
Environment="UNSAFE_SKIP_BACKUP=true"
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:$HOME/.sedad/cosmovisor/current/bin"

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable seda.service

sudo systemctl start seda.service
