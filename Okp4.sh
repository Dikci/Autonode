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
rm -rf okp4d
git clone https://github.com/okp4/okp4d.git
cd okp4d
git checkout v7.0.0

make install

go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest

echo -e Your Node Name
read MONIKER
okp4d init "$MONIKER" --chain-id=okp4-nemeton-1

curl -Ls https://ss-t.okp4.nodestake.org/genesis.json > $HOME/.okp4d/config/genesis.json 
curl -Ls https://ss-t.okp4.nodestake.org/addrbook.json > $HOME/.okp4d/config/addrbook.json

seed="2098d88a57215e89b776179f66e369c453e90141@rpc-t.okp4.nodestake.org:666"
sed -i.bak -e "s/^seed *=.*/seed = \"$seed\"/" ~/.okp4d/config/config.toml
sed -i.bak -e "s%^proxy_app = \\"tcp://127.0.0.1:26658\\"%proxy_app = \\"tcp://127.0.0.1:$PROXY_APP_PORT\\"%; s%^laddr = \\"tcp://127.0.0.1:26657\\"%laddr = \\"tcp://127.0.0.1:$LADDR_PORT\\"%; s%^pprof_laddr = \\"localhost:6060\\"%pprof_laddr = \\"localhost:$LADDR_P2P_PORT\\"%; s%^laddr = \\"tcp://0.0.0.0:26656\\"%laddr = \\"tcp://0.0.0.0:$PPROF_LADDR_PORT\\"%; s%^prometheus_listen_addr = \\":26660\\"%prometheus_listen_addr = \\":$PROMETHEUS_PORT\\"%" $HOME/.okp4d/config/config.toml && sed -i.bak -e "s%^address = \\"0.0.0.0:9090\\"%address = \\"0.0.0.0:$GRPC_PORT\\"%; s%^address = \\"0.0.0.0:9091\\"%address = \\"0.0.0.0:$GRPC_WEB_PORT\\"%; s%^address = \\"tcp://0.0.0.0:1317\\"%address = \\"tcp://0.0.0.0:$API_PORT\\"%" $HOME/.okp4d/config/app.toml && sed -i.bak -e "s%^node = \\"tcp://localhost:26657\\"%node = \\"tcp://localhost:$LADDR_PORT\\"%" $HOME/.okp4d/config/client.toml


SNAP_NAME=$(curl -s https://ss-t.okp4.nodestake.org/ | egrep -o ">20.*\.tar.lz4" | tr -d ">")
curl -o - -L https://ss-t.okp4.nodestake.org/${SNAP_NAME}  | lz4 -c -d - | tar -x -C $HOME/.okp4d

sudo tee /etc/systemd/system/okp4d.service > /dev/null <<EOF
[Unit]
Description=okp4d Daemon
After=network-online.target
[Service]
User=$USER
ExecStart=$(which okp4d) start
Restart=always
RestartSec=3
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable okp4d

sudo systemctl start okp4d
